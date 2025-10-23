#!/bin/bash

# ============================================================================
# Generate Deployment Summary Script
# ============================================================================
# Purpose: Auto-generate a deployment summary from DEPLOYMENT_HISTORY.md
# Usage: ./Scripts/generate-deployment-summary.sh <scenario-name>
# Example: ./Scripts/generate-deployment-summary.sh secondary-transport
#
# This script extracts key information from DEPLOYMENT_HISTORY.md and
# generates a concise summary suitable for status reports or README updates
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <scenario-name>"
    echo "Example: $0 secondary-transport"
    exit 1
fi

SCENARIO=$1
HISTORY_FILE="$SCENARIO/DEPLOYMENT_HISTORY.md"

if [ ! -f "$HISTORY_FILE" ]; then
    echo "Error: $HISTORY_FILE not found"
    exit 1
fi

echo -e "${YELLOW}Generating deployment summary for $SCENARIO...${NC}\n"

# Extract key information
DEPLOY_DATE=$(grep "Deployment Date:" "$HISTORY_FILE" | head -1 | sed 's/.*: //')
DEPLOY_ID=$(grep "Deploy ID:" "$HISTORY_FILE" | head -1 | sed 's/.*: //')
STATUS=$(grep "Status:" "$HISTORY_FILE" | head -1 | sed 's/.*: //')
TESTS=$(grep "Tests Run:" "$HISTORY_FILE" | head -1 | sed 's/.*: //')
FUNCTIONAL_TESTS=$(grep "Functional Tests:" "$HISTORY_FILE" | head -1 | sed 's/.*: //')

# Count components
APEX_CLASSES=$(grep -c "\.cls" "$HISTORY_FILE" | head -1 || echo "0")
FIELDS=$(grep -c "Field__c" "$HISTORY_FILE" | head -1 || echo "0")

# Generate summary
cat << EOF
========================================
DEPLOYMENT SUMMARY: $SCENARIO
========================================

Date: $DEPLOY_DATE
Deploy ID: $DEPLOY_ID
Status: $STATUS

Components:
- Apex Classes: ~$APEX_CLASSES
- Custom Fields: ~$FIELDS

Testing:
- Unit Tests: $TESTS
- Functional Tests: $FUNCTIONAL_TESTS

Documentation:
- DEPLOYMENT_HISTORY.md: ✓
- FUNCTIONAL_TEST_RESULTS.md: $([ -f "$SCENARIO/FUNCTIONAL_TEST_RESULTS.md" ] && echo "✓" || echo "⚠")
- README.md: $([ -f "$SCENARIO/README.md" ] && echo "✓" || echo "⚠")

========================================
EOF

echo -e "\n${GREEN}✓ Summary generated${NC}"
echo -e "\nTo add to README.md, use format:"
echo ""
echo "**$SCENARIO** ($DEPLOY_DATE) - Deploy ID: $DEPLOY_ID"
echo "- Status: $STATUS"
echo "- Tests: $TESTS"
echo "- Functional: $FUNCTIONAL_TESTS"
echo ""
