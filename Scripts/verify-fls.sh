#!/bin/bash

# ============================================================================
# FLS Verification Script
# ============================================================================
# Purpose: Verify that deployed custom fields have Field-Level Security set
# Usage: ./Scripts/verify-fls.sh <scenario-name> <object-name>
# Example: ./Scripts/verify-fls.sh secondary-transport OrderItem
#
# This script:
# 1. Retrieves Profile metadata from NewOrg
# 2. Checks if custom fields are readable and editable
# 3. Reports any fields with missing or incorrect FLS
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <scenario-name> <object-name>"
    echo "Example: $0 secondary-transport OrderItem"
    exit 1
fi

SCENARIO=$1
OBJECT=$2
WORK_DIR=$(pwd)
FLS_CHECK_DIR="$WORK_DIR/fls-verify-$SCENARIO"

echo "=========================================="
echo "FLS Verification for $SCENARIO"
echo "Object: $OBJECT"
echo "=========================================="

# Step 1: Create manifest
echo -e "\n${YELLOW}Step 1: Creating manifest...${NC}"
mkdir -p manifest
cat > manifest/package-fls-verify.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>$OBJECT</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Admin</members>
        <name>Profile</name>
    </types>
    <version>62.0</version>
</Package>
EOF
echo -e "${GREEN}✓ Manifest created${NC}"

# Step 2: Retrieve metadata
echo -e "\n${YELLOW}Step 2: Retrieving metadata from NewOrg...${NC}"
rm -rf "$FLS_CHECK_DIR"
sf project retrieve start \
  --manifest manifest/package-fls-verify.xml \
  --target-org NewOrg \
  --output-dir "$FLS_CHECK_DIR" \
  > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Metadata retrieved${NC}"
else
    echo -e "${RED}✗ Failed to retrieve metadata${NC}"
    exit 1
fi

# Step 3: Find custom fields for the object
echo -e "\n${YELLOW}Step 3: Finding custom fields for $OBJECT...${NC}"
FIELDS_DIR="$FLS_CHECK_DIR/objects/$OBJECT/fields"

if [ ! -d "$FIELDS_DIR" ]; then
    echo -e "${RED}✗ No fields directory found for $OBJECT${NC}"
    exit 1
fi

CUSTOM_FIELDS=$(ls "$FIELDS_DIR" | grep -E "__c\.field-meta\.xml$" | sed 's/.field-meta.xml//')
FIELD_COUNT=$(echo "$CUSTOM_FIELDS" | wc -w)
echo -e "${GREEN}✓ Found $FIELD_COUNT custom fields${NC}"

# Step 4: Check FLS for each field
echo -e "\n${YELLOW}Step 4: Checking FLS in Admin profile...${NC}"
PROFILE_FILE="$FLS_CHECK_DIR/profiles/Admin.profile-meta.xml"

if [ ! -f "$PROFILE_FILE" ]; then
    echo -e "${RED}✗ Admin profile not found${NC}"
    exit 1
fi

echo ""
echo "| Field API Name | Readable | Editable | Status |"
echo "|----------------|----------|----------|--------|"

ERRORS=0
WARNINGS=0
SUCCESS=0

for FIELD in $CUSTOM_FIELDS; do
    # Extract FLS settings from profile
    FLS_BLOCK=$(grep -A 2 "<field>$OBJECT\.$FIELD</field>" "$PROFILE_FILE" 2>/dev/null)

    if [ -z "$FLS_BLOCK" ]; then
        echo "| $FIELD | ❌ No | ❌ No | ${RED}❌ NO FLS SET${NC} |"
        ((ERRORS++))
        continue
    fi

    READABLE=$(echo "$FLS_BLOCK" | grep "<readable>" | sed 's/.*<readable>\(.*\)<\/readable>.*/\1/' | tr -d ' ')
    EDITABLE=$(echo "$FLS_BLOCK" | grep "<editable>" | sed 's/.*<editable>\(.*\)<\/editable>.*/\1/' | tr -d ' ')

    if [ "$READABLE" == "true" ] && [ "$EDITABLE" == "true" ]; then
        echo "| $FIELD | ✅ Yes | ✅ Yes | ${GREEN}✅ CORRECT${NC} |"
        ((SUCCESS++))
    elif [ "$READABLE" == "true" ] && [ "$EDITABLE" == "false" ]; then
        echo "| $FIELD | ✅ Yes | ⚠️  No | ${YELLOW}⚠️  READ-ONLY${NC} |"
        ((WARNINGS++))
    elif [ "$READABLE" == "false" ]; then
        echo "| $FIELD | ❌ No | ❌ No | ${RED}❌ NOT VISIBLE${NC} |"
        ((ERRORS++))
    else
        echo "| $FIELD | ? | ? | ${RED}❌ UNKNOWN${NC} |"
        ((ERRORS++))
    fi
done

# Step 5: Summary
echo ""
echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo -e "${GREEN}✅ Correct FLS:${NC} $SUCCESS fields"
echo -e "${YELLOW}⚠️  Read-Only:${NC} $WARNINGS fields"
echo -e "${RED}❌ Errors:${NC} $ERRORS fields"
echo "Total Fields: $FIELD_COUNT"

# Step 6: Recommendations
if [ $WARNINGS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  ACTION REQUIRED:${NC}"
    echo "Fields marked as Read-Only need to be made editable:"
    echo "1. Navigate to: Setup → Object Manager → $OBJECT → Fields"
    echo "2. For each Read-Only field, click 'Set Field-Level Security'"
    echo "3. For Admin profile, ensure 'Visible' is checked and 'Read-Only' is UNCHECKED"
    echo "4. Save and re-run this script to verify"
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ CRITICAL:${NC}"
    echo "Fields with no FLS or not visible need immediate attention:"
    echo "1. Navigate to: Setup → Object Manager → $OBJECT → Fields"
    echo "2. For each field, click 'Set Field-Level Security'"
    echo "3. For Admin profile, check 'Visible' and UNCHECK 'Read-Only'"
    echo "4. Save and re-run this script to verify"
fi

# Clean up
rm -rf "$FLS_CHECK_DIR"
rm -f manifest/package-fls-verify.xml

# Exit with appropriate code
if [ $ERRORS -gt 0 ]; then
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    exit 2
else
    echo -e "\n${GREEN}✅ All fields have correct FLS!${NC}"
    exit 0
fi
