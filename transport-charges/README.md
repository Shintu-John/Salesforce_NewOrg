# Transport Charges - NewOrg Migration Plan

**Migration Date**: TBD
**Scenario**: Transport Charges Bug Fixes (Issues 1 & 3)
**OldOrg Fix Dates**: October 14-15, 2025
**Migration Status**: 📋 Ready for Review
**Priority**: 🔴 CRITICAL
**Estimated Time**: 3-4 hours (includes deployment + optional data analysis)

---

## Executive Summary

**What's Being Migrated**: Critical bug fixes for transport charge creation and calculation from OldOrg (deployed Oct 14-15, 2025) to NewOrg (currently has pre-fix code with both bugs active).

**Components**:
- ✅ **rlcsJobServiceTest.cls** (84,118 lines) - **NEW** - Provides test coverage (MUST deploy first)
- ✅ **rlcsJobService.cls** (41,558 lines) - **REPLACE** outdated version (currently 28,853 lines, missing 30%)
- ✅ **RLCSChargeService.cls** (4,849 lines) - **UPDATE** to latest version (currently 3,517 lines)
- ✅ **Transport_Only_One_Method validation rule** - **NEW** - Prevents invalid OrderItem flag states

**Why This Migration is Critical**:

NewOrg currently has **pre-Oct 14 code** with two critical bugs active:

**Issue 1 (Missing Charges Bug)**:
- Jobs created without transport charges (53% failure rate)
- Root cause: Map reassignment missing at line 277
- Impact: Revenue loss (charges not created = not invoiced)

**Issue 3 (Calculation Bug)**:
- Charges calculated using wrong source (Job flags instead of OrderItem flags)
- Root cause: Hybrid calculation reading rate from OrderItem but flags from Job
- Impact: Massive overcharges when flags out of sync (£13,600 instead of £340)
- OldOrg Impact: £870K+ in potential overcharges

**Financial Risk**: Without migration, NewOrg could repeat £1.79M impact experienced in OldOrg (£919K from missing charges + £870K from incorrect calculations)

**Data at Risk**: 12,644 Jobs in NewOrg created before Oct 14 fix date - potentially affected by both bugs

**Expected Benefits**:
1. ✅ All Jobs receive transport charges correctly (Issue 1 fixed)
2. ✅ Charges calculate using OrderItem as single source of truth (Issue 3 fixed)
3. ✅ Validation prevents invalid OrderItem flag states
4. ✅ Prevents repeating £1.79M financial impact
5. ✅ Test coverage ensures code quality (75%+ coverage)

---

## Gap Analysis Summary

### Critical Components (🚨 Deployment Blockers)

| Component | OldOrg Status | NewOrg Status | Gap | Impact |
|-----------|--------------|---------------|-----|--------|
| rlcsJobServiceTest.cls | 84,118 lines | 🚨 **MISSING** | Entire test class missing | Cannot deploy rlcsJobService |
| rlcsJobService.cls | 41,558 lines | 28,853 lines | **Missing 12,705 lines (30%)** | Both bugs active |

### High Priority Components (⚠️ Data Quality)

| Component | OldOrg Status | NewOrg Status | Gap | Impact |
|-----------|--------------|---------------|-----|--------|
| RLCSChargeService.cls | 4,849 lines | 3,517 lines | **Missing 1,332 lines (27%)** | CS Invoicing features missing |
| Transport_Only_One_Method | ✅ Active | 🚨 **MISSING** | Validation rule not created | Invalid flag states allowed |

### Data at Risk

| Category | Count | Risk Level | Notes |
|----------|-------|------------|-------|
| Jobs created before Oct 14 | 12,644 Jobs | 🚨 HIGH | Potentially missing charges or incorrect amounts |
| OrderItems with invalid flags | Unknown | 🟡 MEDIUM | Must query and fix before deploying validation |

---

## Migration Strategy

### Deployment Approach

**Selected Strategy**: **Deploy All Fixes + Optional Data Analysis**

**Rationale**:
1. NewOrg has pre-Oct 14 code with both bugs active (confirmed)
2. Fixes are critical for preventing ongoing revenue loss
3. Test class completely missing - must deploy for coverage
4. Existing 12,644 Jobs may require analysis/correction (optional Phase 5)

**What Will Be Deployed**:
- **Deploy**: rlcsJobServiceTest.cls (NEW - provides 75%+ coverage)
- **Replace**: rlcsJobService.cls (fixes both bugs)
- **Update**: RLCSChargeService.cls (latest version for consistency)
- **Create**: Transport_Only_One_Method validation rule

**Deployment Phases** (4 required + 1 optional):
1. Phase 0: Pre-Deployment Checks
2. Phase 1: Test Class (MUST BE FIRST)
3. Phase 2: Service Classes (Core Fixes)
4. Phase 3: Validation Rule (Data Quality)
5. Phase 4: Post-Deployment Verification
6. **Phase 5 (OPTIONAL): Existing Data Analysis & Correction**

---

### Deployment Order

Components must be deployed in this specific order:

```
Phase 0: Pre-Deployment Checks
    ↓
Phase 1: Test Class (CRITICAL FIRST)
    rlcsJobServiceTest.cls
    ↓
Phase 2: Service Classes (Core Fixes)
    rlcsJobService.cls + RLCSChargeService.cls
    ↓
Phase 3: Validation Rule (Data Quality)
    Fix invalid OrderItem states → Deploy Transport_Only_One_Method
    ↓
Phase 4: Post-Deployment Verification
    Run all tests, verify fixes work
    ↓
Phase 5 (OPTIONAL): Data Analysis
    Analyze 12,644 existing Jobs → Backfill/correct as needed
```

**Why This Order**:
- Test class FIRST: Provides coverage for rlcsJobService deployment (Salesforce 75% requirement)
- Service classes SECOND: Fixes both bugs
- Validation rule THIRD: Must fix existing invalid states before enforcing rule
- Data analysis LAST: Deploy fixes first to prevent new issues, then clean up old data

---

## Pre-Deployment Checklist

**Before starting deployment, verify**:

### 1. Org Access ✅
```bash
# Verify connection to NewOrg
sf org display --target-org NewOrg

# Expected: Status shows "Connected", username displayed
```

### 2. Code Repository Access ✅
```bash
# Verify code files exist in NewOrg working directory
ls -la /home/john/Projects/Salesforce/force-app/main/default/classes/ | grep -E "rlcsJobService|RLCSChargeService"

# Expected:
# - rlcsJobService.cls (current version)
# - rlcsJobService.cls-meta.xml
# - rlcsJobServiceTest.cls
# - rlcsJobServiceTest.cls-meta.xml
# - RLCSChargeService.cls
# - RLCSChargeService.cls-meta.xml
```

### 3. Deployment Tools ✅
```bash
# Verify Salesforce CLI installed and updated
sf version

# Expected: sf version 2.x.x or later
```

### 4. Backup Preparation ✅
```bash
# Create backup directory
mkdir -p /tmp/Salesforce_NewOrg_Backup/transport-charges/$(date +%Y-%m-%d)

# Note: Will retrieve existing components in Phase 0
```

---

## Phase 0: Pre-Deployment Setup

### Step 0.1: Backup NewOrg Current State

**Purpose**: Create rollback point before deployment

```bash
# Create backup directory with timestamp
BACKUP_DIR="/tmp/Salesforce_NewOrg_Backup/transport-charges/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

# Retrieve existing rlcsJobService.cls (current buggy version)
sf project retrieve start \
  --metadata "ApexClass:rlcsJobService" \
  --target-org NewOrg \
  --output-dir "$BACKUP_DIR"

# Retrieve existing RLCSChargeService.cls (current outdated version)
sf project retrieve start \
  --metadata "ApexClass:RLCSChargeService" \
  --target-org NewOrg \
  --output-dir "$BACKUP_DIR"

# Note: rlcsJobServiceTest.cls doesn't exist in NewOrg, so nothing to back up
```

**Expected Output**:
```
Retrieved Source:
  ApexClass  rlcsJobService
  ApexClass  RLCSChargeService
```

---

### Step 0.2: Verify Current State (Confirm Bugs Active)

**Purpose**: Confirm NewOrg has buggy code before deploying fixes

```bash
# Query current rlcsJobService.cls size
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api

# Expected: LengthWithoutComments = 28853 (smaller than OldOrg's 41558)
```

**Sample Output**:
```
Name             LastModifiedDate        LengthWithoutComments
rlcsJobService   2025-10-10T12:59:04Z   28853
```

**Interpretation**:
- ✅ Last modified Oct 10 (4 days before Oct 14 fix) - confirms pre-fix version
- ✅ 28,853 lines (vs OldOrg 41,558) - confirms missing fixes

---

### Step 0.3: Check for Existing Invalid OrderItem States

**Purpose**: Find OrderItems with both flags = true (must fix before deploying validation)

```bash
# Query OrderItems with invalid flag states
sf data query --query "SELECT Id, Product2.Name, Transport__c, Transport_Per_Tonne__c, Transport_Per_Unit__c FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg

# Expected: 0-10 records (OldOrg had 3, NewOrg may have similar)
```

**If Records Found**:
```bash
# Save IDs to file for fixing in Phase 3
sf data query --query "SELECT Id FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg --result-format csv > /tmp/invalid_orderitems.csv

# Count how many need fixing
wc -l /tmp/invalid_orderitems.csv
```

**Note**: We'll fix these in Phase 3 before deploying validation rule

---

### Step 0.4: Analyze Existing Jobs (Optional - For Phase 5 Planning)

**Purpose**: Understand scope of potential data issues (helps decide if Phase 5 needed)

```bash
# Count Jobs created before Oct 14 fix (potentially affected)
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate < 2025-10-14T18:37:00Z" --target-org NewOrg

# Expected: ~12,644 Jobs (confirmed in gap analysis)
```

**Sample Analysis Queries** (optional, for planning):

```bash
# Count Jobs with Material_Weight_Tonnes (could be affected by Issue 3)
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate < 2025-10-14T18:37:00Z AND Material_Weight_Tonnes__c > 0" --target-org NewOrg

# Count Jobs with Unit_Count (could be affected by Issue 3)
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate < 2025-10-14T18:37:00Z AND Unit_Count__c > 0" --target-org NewOrg

# Count transport charges created before Oct 14
sf data query --query "SELECT COUNT() FROM RLCS_Charge__c WHERE CreatedDate < 2025-10-14T18:37:00Z AND Charge_Type__c = 'Transport'" --target-org NewOrg
```

**Decision Point**: Based on counts, decide if Phase 5 (data analysis) is needed after deployment

---

## Phase 1: Test Class Deployment (CRITICAL FIRST)

**Purpose**: Deploy test class BEFORE service class to provide required 75% code coverage

### Step 1.1: Prepare Test Class

**Why This is First**: Salesforce requires 75% code coverage for production deployments. Without rlcsJobServiceTest.cls, the rlcsJobService.cls deployment will **FAIL**.

```bash
# Verify test class file exists
ls -la /home/john/Projects/Salesforce/force-app/main/default/classes/rlcsJobServiceTest.*

# Expected:
# -rw-r--r-- rlcsJobServiceTest.cls
# -rw-r--r-- rlcsJobServiceTest.cls-meta.xml
```

**File Size Check**:
```bash
wc -l /home/john/Projects/Salesforce/force-app/main/default/classes/rlcsJobServiceTest.cls

# Expected: ~90,000+ lines (84,118 without comments + comments)
```

---

### Step 1.2: Deploy Test Class

**CRITICAL**: This deployment may **take several minutes** due to test class size (84K lines).

```bash
# Deploy test class to NewOrg
sf project deploy start \
  --source-dir "force-app/main/default/classes" \
  --metadata "ApexClass:rlcsJobServiceTest" \
  --target-org NewOrg \
  --wait 15 \
  --verbose

# Note: --wait 15 allows up to 15 minutes for deployment
# Test class deployment doesn't run tests yet (compilation only)
```

**Expected Output**:
```
Deploying...
Status: Succeeded
Component Deployed: ApexClass:rlcsJobServiceTest
Deploy ID: [17-character ID]
Duration: 3-5 minutes
```

**If Deployment Fails**:

**Common Error 1**: "Cannot find rlcsJobService.cls"
- **Cause**: Test class references rlcsJobService, but NewOrg version is outdated
- **Solution**: This is expected - test class will compile but tests will fail until Phase 2

**Common Error 2**: "Compilation error"
- **Cause**: Test class references methods/fields not in current NewOrg rlcsJobService
- **Solution**: Deploy rlcsJobService.cls in Phase 2 to resolve

**Note**: Test compilation errors are acceptable at this stage. Tests will pass after Phase 2 deployment.

---

### Step 1.3: Verify Test Class Deployment

```bash
# Query test class in NewOrg
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobServiceTest'" --target-org NewOrg --use-tooling-api

# Expected:
# Name: rlcsJobServiceTest
# LengthWithoutComments: 84118
# LastModifiedDate: [Today's date]
```

**Success Criteria**: ✅ Test class exists in NewOrg with 84,118 lines

---

## Phase 2: Service Classes Deployment (Core Fixes)

**Purpose**: Deploy rlcsJobService.cls and RLCSChargeService.cls with bug fixes

### Step 2.1: Prepare Service Classes

```bash
# Verify both service class files exist
ls -la /home/john/Projects/Salesforce/force-app/main/default/classes/ | grep -E "rlcsJobService.cls|RLCSChargeService.cls"

# Expected:
# -rw-r--r-- rlcsJobService.cls
# -rw-r--r-- rlcsJobService.cls-meta.xml
# -rw-r--r-- RLCSChargeService.cls
# -rw-r--r-- RLCSChargeService.cls-meta.xml
```

---

### Step 2.2: Deploy Service Classes with Test Execution

**CRITICAL**: This deployment will **run all 65 test methods** and may take 10-15 minutes.

```bash
# Deploy both service classes together with full test run
sf project deploy start \
  --source-dir "force-app/main/default/classes" \
  --metadata "ApexClass:rlcsJobService" \
  --metadata "ApexClass:RLCSChargeService" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "rlcsJobServiceTest" \
  --wait 15 \
  --verbose

# This will:
# 1. Deploy rlcsJobService.cls (41,558 lines - fixes both bugs)
# 2. Deploy RLCSChargeService.cls (4,849 lines - latest version)
# 3. Run all 65 test methods in rlcsJobServiceTest.cls
# 4. Calculate code coverage (must be ≥75%)
```

**Expected Output**:
```
Deploying...
Running Specified Tests...

Test Results:
  rlcsJobServiceTest.testCreateJobWithTransportPerTonne - Pass
  rlcsJobServiceTest.testCreateJobWithTransportPerUnit - Pass
  rlcsJobServiceTest.testCreateJobWithTransportPerLoad - Pass
  ... (62 more tests)

Test Summary:
  Pass: 65
  Fail: 0
  Total: 65

Code Coverage:
  rlcsJobService: 85%
  RLCSChargeService: 78%

Status: Succeeded
Components Deployed:
  ApexClass:rlcsJobService
  ApexClass:RLCSChargeService
Deploy ID: [17-character ID]
Duration: 10-15 minutes
```

**If Tests Fail**:

**Common Error 1**: "Assertion Failed: Expected charge amount £50 but got £0"
- **Cause**: Issue 1 bug still active (map reassignment not working)
- **Solution**: Check deployment actually replaced rlcsJobService.cls, not just added code

**Common Error 2**: "Assertion Failed: Expected charge per tonne but got per unit calculation"
- **Cause**: Issue 3 bug still active (Job flags still being read)
- **Solution**: Verify rlcsJobService.cls lines 393-450 use OrderItem flags

**Common Error 3**: "Code coverage below 75%"
- **Cause**: Test class not covering new code sections
- **Solution**: This shouldn't happen with OldOrg code - contact support if occurs

---

### Step 2.3: Verify Service Class Deployments

```bash
# Verify rlcsJobService.cls deployed
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api

# Expected:
# LengthWithoutComments: 41558 (increased from 28853)
# LastModifiedDate: [Today's date]

# Verify RLCSChargeService.cls deployed
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'RLCSChargeService'" --target-org NewOrg --use-tooling-api

# Expected:
# LengthWithoutComments: 4849 (increased from 3517)
# LastModifiedDate: [Today's date]
```

**Success Criteria**:
- ✅ rlcsJobService.cls: 41,558 lines (up from 28,853)
- ✅ RLCSChargeService.cls: 4,849 lines (up from 3,517)
- ✅ All 65 tests passing (100%)
- ✅ Code coverage ≥75%

---

## Phase 3: Validation Rule Deployment (Data Quality)

**Purpose**: Deploy validation rule to prevent future invalid OrderItem flag states

### Step 3.1: Fix Existing Invalid OrderItem States

**CRITICAL**: Must fix existing invalid states BEFORE deploying validation rule (or deployment will prevent fixing them)

**Check if any OrderItems need fixing** (from Step 0.3):

```bash
# Count invalid OrderItems
sf data query --query "SELECT COUNT() FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg

# If count > 0, get the records
sf data query --query "SELECT Id, Product2.Name, Transport__c, Transport_Per_Tonne__c, Transport_Per_Unit__c FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg
```

**If invalid OrderItems found, fix each one**:

**Decision Logic** (for each OrderItem):
1. Check associated Jobs to understand usage pattern
2. Determine which flag is correct (per tonne or per unit)
3. Update OrderItem to have only one flag = true

**Example Fix** (manual - update one at a time):

```bash
# Query Jobs using this OrderItem to determine correct flag
sf data query --query "SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c FROM RLCS_Job__c WHERE Order_Product__c = '[OrderItem ID]' LIMIT 10" --target-org NewOrg

# Based on Job usage, update OrderItem:

# Option A: Should be per tonne
sf data update record --sobject OrderItem --record-id "[OrderItem ID]" --values "Transport_Per_Unit__c=false" --target-org NewOrg

# Option B: Should be per unit
sf data update record --sobject OrderItem --record-id "[OrderItem ID]" --values "Transport_Per_Tonne__c=false" --target-org NewOrg
```

**Verification**:
```bash
# Verify all invalid states fixed
sf data query --query "SELECT COUNT() FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg

# Expected: 0 records
```

---

### Step 3.2: Deploy Validation Rule

**Now safe to deploy validation rule** (all invalid states fixed):

```bash
# Deploy validation rule
sf project deploy start \
  --source-dir "force-app/main/default/objects/OrderItem/validationRules" \
  --metadata "ValidationRule:OrderItem.Transport_Only_One_Method" \
  --target-org NewOrg \
  --wait 10 \
  --verbose

# Note: Validation rules don't require test execution
```

**Expected Output**:
```
Status: Succeeded
Component Deployed: ValidationRule:OrderItem.Transport_Only_One_Method
Deploy ID: [17-character ID]
Duration: 10-20 seconds
```

**If Deployment Fails**:

**Error**: "Existing records violate validation rule"
- **Cause**: Still have OrderItems with both flags = true
- **Solution**: Go back to Step 3.1, fix those records, then retry deployment

---

### Step 3.3: Verify Validation Rule Deployment

```bash
# Query validation rule in NewOrg
sf data query --query "SELECT FullName, Active, ValidationName, ErrorMessage FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'OrderItem' AND ValidationName = 'Transport_Only_One_Method'" --target-org NewOrg --use-tooling-api

# Expected:
# FullName: Transport_Only_One_Method
# Active: true
# ErrorMessage: "You cannot select both 'Per Tonne' and 'Per Unit' for transport..."
```

---

### Step 3.4: Test Validation Rule

**Purpose**: Verify validation rule prevents invalid states

```bash
# Create test: Try to set both flags = true (should fail)
# This will intentionally fail to prove validation works

sf data create record --sobject OrderItem \
  --values "OrderId=[Test Order ID] PricebookEntryId=[Test Entry ID] Quantity=1 UnitPrice=10 Transport__c=10 Transport_Per_Tonne__c=true Transport_Per_Unit__c=true" \
  --target-org NewOrg

# Expected: ERROR with message "You cannot select both 'Per Tonne' and 'Per Unit' for transport..."
```

**Success Criteria**: ✅ Validation error appears (proves rule is working)

---

## Phase 4: Post-Deployment Verification

**Purpose**: Confirm all fixes deployed correctly and are working

### Step 4.1: Verify All Components Deployed

```bash
# Run comprehensive verification query
cat << 'EOF' > /tmp/verify_deployment.sh
#!/bin/bash

echo "=== Transport Charges Migration Verification ==="
echo "Date: $(date)"
echo ""

echo "1. rlcsJobService.cls:"
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api
echo ""

echo "2. rlcsJobServiceTest.cls:"
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobServiceTest'" --target-org NewOrg --use-tooling-api
echo ""

echo "3. RLCSChargeService.cls:"
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'RLCSChargeService'" --target-org NewOrg --use-tooling-api
echo ""

echo "4. Validation Rule:"
sf data query --query "SELECT FullName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'OrderItem' AND ValidationName = 'Transport_Only_One_Method'" --target-org NewOrg --use-tooling-api
echo ""

echo "=== Verification Complete ==="
EOF

chmod +x /tmp/verify_deployment.sh
/tmp/verify_deployment.sh
```

**Expected Output**:
```
=== Transport Charges Migration Verification ===

1. rlcsJobService.cls:
   LengthWithoutComments: 41558 ✅

2. rlcsJobServiceTest.cls:
   LengthWithoutComments: 84118 ✅

3. RLCSChargeService.cls:
   LengthWithoutComments: 4849 ✅

4. Validation Rule:
   FullName: Transport_Only_One_Method
   Active: true ✅

=== Verification Complete ===
```

---

### Step 4.2: Run Full Test Suite Again

**Purpose**: Confirm all tests still pass after complete deployment

```bash
# Run all 65 tests
sf apex run test --tests "rlcsJobServiceTest" --target-org NewOrg --result-format human --code-coverage --wait 10

# Expected: 65/65 passing, 75%+ coverage
```

**Success Criteria**:
- ✅ All 65 tests pass
- ✅ Code coverage ≥75%
- ✅ No errors in test output

---

### Step 4.3: Create Test Job to Verify Fixes

**Purpose**: Real-world test to confirm both bugs are fixed

**Test Scenario 1: Verify Issue 1 Fix (Map Reassignment)**

```bash
# Create test OrderItem with transport rate
# (Assumes test Order and PricebookEntry exist)

sf data create record --sobject OrderItem \
  --values "OrderId=[Test Order ID] PricebookEntryId=[Test Entry ID] Quantity=1 UnitPrice=100 Transport__c=10 Transport_Per_Tonne__c=true" \
  --target-org NewOrg --json

# Save OrderItem ID from output

# Create test Job with this OrderItem
sf data create record --sobject RLCS_Job__c \
  --values "Order_Product__c=[OrderItem ID] Material_Weight_Tonnes__c=5 Status__c='In Progress'" \
  --target-org NewOrg --json

# Save Job ID from output

# Check if transport charge was created
sf data query --query "SELECT Id, Cost__c, Charge_Type__c FROM RLCS_Charge__c WHERE RLCS_Job__c = '[Job ID]' AND Charge_Type__c = 'Transport'" --target-org NewOrg

# Expected: 1 charge record with Cost__c = 50 (5 tonnes × £10)
```

**Success Criteria**: ✅ Transport charge created automatically (Issue 1 FIXED)

**Test Scenario 2: Verify Issue 3 Fix (OrderItem Source of Truth)**

```bash
# Create OrderItem with per tonne flag
sf data create record --sobject OrderItem \
  --values "OrderId=[Test Order ID] PricebookEntryId=[Test Entry ID] Quantity=1 UnitPrice=100 Transport__c=10 Transport_Per_Tonne__c=true Transport_Per_Unit__c=false" \
  --target-org NewOrg --json

# Create Job with MISMATCHED flag (per unit) to test if code uses OrderItem flag
sf data create record --sobject RLCS_Job__c \
  --values "Order_Product__c=[OrderItem ID] Material_Weight_Tonnes__c=5 Unit_Count__c=100 Transport_Per_Unit__c=true Transport_Per_Tonne__c=false Status__c='In Progress'" \
  --target-org NewOrg --json

# Check charge amount - should use OrderItem flag (per tonne), NOT Job flag (per unit)
sf data query --query "SELECT Id, Cost__c FROM RLCS_Charge__c WHERE RLCS_Job__c = '[Job ID]' AND Charge_Type__c = 'Transport'" --target-org NewOrg

# Expected: Cost__c = 50 (5 tonnes × £10) NOT 1000 (100 units × £10)
```

**Success Criteria**: ✅ Charge calculated using OrderItem flag, ignoring Job flag (Issue 3 FIXED)

---

## Phase 5 (OPTIONAL): Existing Data Analysis & Correction

**Purpose**: Analyze and correct 12,644 existing Jobs created before Oct 14 fix deployment

**Decision Point**: Skip this phase if:
- NewOrg is new/test org with no production data
- 12,644 Jobs are test data
- Business accepts cleaning data over time rather than immediate fix

**Proceed with this phase if**:
- NewOrg has production data
- Jobs represent real customer transactions
- Missing/incorrect charges impact invoicing

---

### Step 5.1: Analyze Jobs for Missing Charges (Issue 1)

**Purpose**: Find Jobs missing transport charges due to Issue 1 bug

**Query Jobs Created Oct 10-14** (when bug was active):

```bash
# Count Jobs created during Issue 1 bug period
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate >= 2025-10-10T11:00:00Z AND CreatedDate < 2025-10-14T18:37:00Z" --target-org NewOrg

# Get detailed list
sf data query --query "SELECT Id, Name, CreatedDate, Order_Product__c, Material_Weight_Tonnes__c, Unit_Count__c, Transport__c FROM RLCS_Job__c WHERE CreatedDate >= 2025-10-10T11:00:00Z AND CreatedDate < 2025-10-14T18:37:00Z AND Order_Product__r.Transport__c != null ORDER BY CreatedDate" --target-org NewOrg --result-format csv > /tmp/issue1_period_jobs.csv

# Count how many Jobs in this period
wc -l /tmp/issue1_period_jobs.csv
```

**For each Job, check if transport charge exists**:

```bash
# This query is complex - may be easier with script
# Pseudocode:
# For each Job in /tmp/issue1_period_jobs.csv:
#   Query: SELECT COUNT() FROM RLCS_Charge__c WHERE RLCS_Job__c = [Job ID] AND Charge_Type__c = 'Transport'
#   If count = 0: Job is missing charge (add to backfill list)
```

**Create backfill list**:

```bash
# Save Jobs missing charges to CSV
# Format: Job ID, OrderItem ID, Material_Weight_Tonnes, Unit_Count, Transport Rate, Calculation Method
# This CSV will be used for backfill script
```

---

### Step 5.2: Analyze Jobs for Incorrect Charges (Issue 3)

**Purpose**: Find Jobs with charges calculated using wrong flags

**This is complex** - requires comparing:
1. OrderItem flags (source of truth)
2. Job flags (wrong source - used by buggy code)
3. Actual charge amount
4. Expected charge amount (if OrderItem flags were used)

**Query Jobs with Flag Mismatches**:

```bash
# Find Jobs where OrderItem flag != Job flag
sf data query --query "SELECT Id, Name, Material_Weight_Tonnes__c, Unit_Count__c, Transport_Per_Tonne__c, Transport_Per_Unit__c, Order_Product__r.Transport__c, Order_Product__r.Transport_Per_Tonne__c, Order_Product__r.Transport_Per_Unit__c FROM RLCS_Job__c WHERE CreatedDate < 2025-10-15T11:18:00Z AND ((Transport_Per_Tonne__c = true AND Order_Product__r.Transport_Per_Tonne__c = false) OR (Transport_Per_Unit__c = true AND Order_Product__r.Transport_Per_Unit__c = false)) LIMIT 1000" --target-org NewOrg --result-format csv > /tmp/flag_mismatches.csv

# Count mismatches
wc -l /tmp/flag_mismatches.csv
```

**For each mismatch, calculate correct vs actual amount**:

This requires complex script similar to OldOrg Issue 3 Phase 3. Due to complexity, **recommended approach**:

1. **Option A (Comprehensive)**: Adapt OldOrg Phase 3 scripts for NewOrg
   - Query OrderItemHistory to understand flag changes
   - Calculate expected amounts using OrderItem flags
   - Compare with actual charge amounts
   - Generate correction CSV
   - Execute bulk updates

2. **Option B (Targeted)**: Focus on high-value mismatches
   - Query Jobs with Material_Weight_Tonnes > 5 OR Unit_Count > 100 (larger Jobs)
   - Manually review sample of 10-20 Jobs
   - Estimate financial impact
   - Decide if comprehensive correction warranted

3. **Option C (Monitor)**: Skip historical correction, monitor going forward
   - Deploy fixes (prevent future issues)
   - Add dashboard to monitor new charges
   - Correct issues as discovered by users
   - Accept historical data may have discrepancies

**Recommendation**: Start with **Option B** to assess scope, then decide if Option A needed

---

### Step 5.3: Backfill Missing Charges (If Needed)

**If Step 5.1 identified missing charges**, create backfill script:

**Backfill Script Template** (adapt from OldOrg Issue 1):

```apex
// backfill_transport_charges.apex (Anonymous Apex)

// Query Jobs missing charges (from Step 5.1 analysis)
List<RLCS_Job__c> jobsMissingCharges = [
    SELECT Id, Order_Product__c, Material_Weight_Tonnes__c, Unit_Count__c,
           Order_Product__r.Transport__c,
           Order_Product__r.Transport_Per_Tonne__c,
           Order_Product__r.Transport_Per_Unit__c,
           Order_Product__r.Haulier__c,
           Customer_Account__c, VAT__c
    FROM RLCS_Job__c
    WHERE Id IN :jobIdsFromAnalysis
];

List<RLCS_Charge__c> chargesToCreate = new List<RLCS_Charge__c>();

for (RLCS_Job__c job : jobsMissingCharges) {
    if (job.Order_Product__r.Transport__c == null) continue;

    // Calculate amount using OrderItem flags (correct source)
    Decimal multiplier = job.Order_Product__r.Transport_Per_Tonne__c ?
        (job.Material_Weight_Tonnes__c ?? 0) :
        job.Order_Product__r.Transport_Per_Unit__c ?
        (job.Unit_Count__c ?? 0) : 1;

    Decimal chargeAmount = multiplier * job.Order_Product__r.Transport__c;

    // Create charge
    RLCS_Charge__c charge = new RLCS_Charge__c(
        RLCS_Job__c = job.Id,
        Charge_Type__c = 'Transport',
        Cost__c = chargeAmount,
        Vendor__c = job.Order_Product__r.Haulier__c,
        Account__c = job.Customer_Account__c,
        VAT__c = job.VAT__c
    );

    chargesToCreate.add(charge);
}

// Insert charges
insert chargesToCreate;

System.debug('Backfilled ' + chargesToCreate.size() + ' transport charges');
```

**Execute**:
```bash
# Save script to file
cat > /tmp/backfill.apex << 'EOF'
[Script content above]
EOF

# Execute anonymous Apex
sf apex run --file /tmp/backfill.apex --target-org NewOrg

# Check results in debug log
```

---

### Step 5.4: Correct Incorrect Charges (If Needed)

**If Step 5.2 identified incorrect charges**, correct them:

**For Unlocked Charges** (not invoiced):
```bash
# Bulk update Cost__c field with correct amounts
# Create CSV: Charge ID, Correct Cost
# Use sf data update bulk

sf data update bulk --sobject RLCS_Charge__c --file /tmp/charge_corrections.csv --wait 10 --target-org NewOrg
```

**For Locked Charges** (already invoiced):
- **Option A**: Accept as-is (invoice is final)
- **Option B**: Update OrderItem to match invoice (same as OldOrg locked charges approach)
- **Recommendation**: Option A unless discrepancies are significant

---

### Step 5.5: Document Data Corrections

**Create summary report**:

```
Transport Charges Data Correction Summary
Date: [Today's Date]
NewOrg: [Org Name]

Jobs Analyzed: 12,644
Period: Before 2025-10-14T18:37:00Z

Issue 1 (Missing Charges):
- Jobs affected: [Count]
- Charges backfilled: [Count]
- Total value backfilled: £[Amount]

Issue 3 (Incorrect Charges):
- Jobs with flag mismatches: [Count]
- Charges corrected: [Count]
- Total value corrected: £[Amount]
- Charges left as-is (invoiced): [Count]

Total Financial Impact: £[Total]
Status: Complete
```

---

## Post-Deployment Verification Summary

**Run all checks after deployment complete**:

### Verification Checklist

```bash
# 1. Verify all Apex classes deployed
sf data query --query "SELECT Name, LengthWithoutComments FROM ApexClass WHERE Name IN ('rlcsJobService', 'rlcsJobServiceTest', 'RLCSChargeService') ORDER BY Name" --target-org NewOrg --use-tooling-api
# ✅ Expected:
#    rlcsJobService: 41558
#    rlcsJobServiceTest: 84118
#    RLCSChargeService: 4849

# 2. Verify validation rule deployed
sf data query --query "SELECT FullName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'OrderItem' AND ValidationName = 'Transport_Only_One_Method'" --target-org NewOrg --use-tooling-api
# ✅ Expected: 1 record, Active = true

# 3. Verify test coverage
sf apex run test --tests "rlcsJobServiceTest" --target-org NewOrg --code-coverage --result-format human --wait 10
# ✅ Expected: 65/65 passing, 75%+ coverage

# 4. Verify no invalid OrderItem flag states
sf data query --query "SELECT COUNT() FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg
# ✅ Expected: 0 records

# 5. Test Issue 1 fix (create Job with OrderItem, verify charge created)
# (Manual test from Step 4.3)

# 6. Test Issue 3 fix (create Job with mismatched flags, verify charge uses OrderItem flag)
# (Manual test from Step 4.3)

# 7. Test validation rule (try to set both flags true, verify error)
# (Manual test from Step 3.4)
```

**All checks passing** = ✅ Deployment successful, both bugs fixed

---

## Rollback Plan

### Rollback Scenarios

**When to Rollback**:
- Test class deployment causes critical errors
- Service class deployment fails tests
- Validation rule deployment fails
- Post-deployment tests reveal regressions
- Critical production issues after deployment

---

### Immediate Rollback (5 minutes) - Restore Backup

**Use when**: Critical issues, need to restore pre-deployment state

```bash
# Navigate to backup directory
cd /tmp/Salesforce_NewOrg_Backup/transport-charges/[timestamp]

# Deploy backed-up classes (pre-fix versions)
sf project deploy start \
  --source-dir "force-app/main/default/classes" \
  --metadata "ApexClass:rlcsJobService" \
  --metadata "ApexClass:RLCSChargeService" \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 15

# Delete test class (didn't exist before)
sf project delete source \
  --metadata "ApexClass:rlcsJobServiceTest" \
  --target-org NewOrg \
  --no-prompt

# Delete validation rule (didn't exist before)
sf project delete source \
  --metadata "ValidationRule:OrderItem.Transport_Only_One_Method" \
  --target-org NewOrg \
  --no-prompt

# Verify rollback
sf data query --query "SELECT Name, LengthWithoutComments FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api
# Expected: LengthWithoutComments = 28853 (pre-fix version)
```

**Impact**: System returns to pre-deployment state with both bugs active (same as before migration)

---

### Partial Rollback (2 minutes) - Delete Validation Rule Only

**Use when**: Validation rule causing issues, but fixes are working

```bash
# Delete validation rule only
sf project delete source \
  --metadata "ValidationRule:OrderItem.Transport_Only_One_Method" \
  --target-org NewOrg \
  --no-prompt
```

**Impact**: Bugs still fixed, but invalid flag states allowed again

---

## Known Issues & Limitations

### Known Limitations

1. **Historical Data**: Phase 5 (data correction) is optional but recommended
   - **Impact**: Existing 12,644 Jobs may have missing/incorrect charges
   - **Mitigation**: Run Phase 5 analysis after deployment, correct as needed

2. **Test Class Size**: rlcsJobServiceTest.cls is 84K lines (large deployment)
   - **Impact**: Deployment may take 5-10 minutes
   - **Mitigation**: Use --wait 15 to allow enough time

3. **Issue 2 Not Addressed**: Missing Material Category Breakdown is user process issue
   - **Impact**: User training needed, not fixed by code migration
   - **Mitigation**: Separate user training/process improvement initiative

4. **OrderItem Field History**: May need Field History for Issue 3 analysis (Phase 5.2)
   - **Impact**: Without history, can't determine when flags changed
   - **Mitigation**: Enable OrderItemHistory tracking if not already enabled

---

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Test class deployment fails | Low | High | Verify file exists, retry deployment |
| Service class tests fail | Low | High | Verify OldOrg code deployed, check for NewOrg customizations |
| Validation deployment blocks existing records | Medium | Medium | Fix invalid states BEFORE deploying validation (Step 3.1) |
| Phase 5 reveals extensive data issues | Medium | Medium | Start with Option B (targeted analysis), assess scope |
| Rollback needed | Low | High | Backup created in Phase 0, tested rollback procedure |

---

## Success Criteria

**Deployment considered successful when**:

### Technical Criteria
- ✅ rlcsJobServiceTest.cls deployed (84,118 lines)
- ✅ rlcsJobService.cls deployed (41,558 lines)
- ✅ RLCSChargeService.cls deployed (4,849 lines)
- ✅ Transport_Only_One_Method validation rule active
- ✅ All 65 tests passing (100%)
- ✅ Code coverage ≥75%

### Functional Criteria
- ✅ New Jobs receive transport charges automatically (Issue 1 FIXED)
- ✅ Charges calculate using OrderItem flags, not Job flags (Issue 3 FIXED)
- ✅ Validation prevents setting both flags true (Issue 3 Validation)
- ✅ No invalid OrderItem flag states exist

### Business Criteria
- ✅ No revenue loss from missing charges
- ✅ No overcharges from incorrect calculations
- ✅ Data quality improved (invalid states prevented)
- ✅ Code consistent with OldOrg (easier support)

---

## Migration Timeline

**Estimated Total Time**: 3-4 hours (excluding Phase 5 if skipped)

| Phase | Task | Estimated Time | Dependencies |
|-------|------|---------------|--------------|
| 0 | Pre-Deployment Setup | 30 min | Org access |
| 1 | Test Class Deployment | 30 min | None |
| 2 | Service Classes Deployment | 45 min | Phase 1 complete |
| 3 | Validation Rule Deployment | 30 min | Fix invalid states first |
| 4 | Post-Deployment Verification | 45 min | Phases 1-3 complete |
| 5 (Optional) | Data Analysis & Correction | 2-4 hours | Phase 4 complete |

**Total (Phases 0-4)**: 3 hours
**Total (Including Phase 5)**: 5-7 hours

---

## Deployment Checklist

**Before Deployment**:
- [ ] Read OldOrg State README
- [ ] Read Gap Analysis
- [ ] Read this Migration Plan completely
- [ ] Verify NewOrg access
- [ ] Backup current NewOrg state (Phase 0)
- [ ] Notify stakeholders of deployment window

**During Deployment**:
- [ ] Phase 0: Pre-Deployment Setup complete
- [ ] Phase 1: Test class deployed, verified (84,118 lines)
- [ ] Phase 2: Service classes deployed, all 65 tests passing
- [ ] Phase 3: Invalid OrderItems fixed, validation rule deployed
- [ ] Phase 4: All verification checks passing
- [ ] Phase 5 (Optional): Data analysis complete, corrections applied

**After Deployment**:
- [ ] All verification checks passing
- [ ] Test Jobs created successfully with correct charges
- [ ] Validation rule preventing invalid states
- [ ] User notification sent
- [ ] Documentation updated with Deploy IDs
- [ ] 24-hour monitoring scheduled

---

## Post-Deployment Monitoring

### First 24 Hours (Check every 2-3 hours)

```bash
# Monitor script - run every 2-3 hours
#!/bin/bash

echo "=== Transport Charges Monitoring ==="
echo "Date: $(date)"
echo ""

echo "1. Jobs created since deployment:"
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate > [Deployment Timestamp]" --target-org NewOrg
echo ""

echo "2. Transport charges created since deployment:"
sf data query --query "SELECT COUNT() FROM RLCS_Charge__c WHERE CreatedDate > [Deployment Timestamp] AND Charge_Type__c = 'Transport'" --target-org NewOrg
echo ""

echo "3. Jobs without transport charges (should be 0):"
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate > [Deployment Timestamp] AND Order_Product__r.Transport__c != null AND Id NOT IN (SELECT RLCS_Job__c FROM RLCS_Charge__c WHERE Charge_Type__c = 'Transport')" --target-org NewOrg
echo ""

echo "4. Recent Apex errors:"
sf data query --query "SELECT COUNT() FROM ApexLog WHERE Operation LIKE '%rlcsJob%' AND Status != 'Success' AND StartTime = TODAY" --target-org NewOrg --use-tooling-api
echo ""

echo "5. Invalid OrderItem attempts (validation rule blocks):"
# Check setup audit trail for validation errors
echo ""

echo "=== Monitoring Complete ==="
```

### First Week (Daily checks)

- Review debug logs for errors
- Check charge creation rate (should be ~95-100%, not 47% like Issue 1 period)
- Verify no charge calculation anomalies
- Gather user feedback
- Monitor validation rule blocks (users trying to set both flags)

### First Month (Weekly reviews)

- Analyze charge amounts for patterns
- Review any user-reported issues
- Verify fixes remain stable
- Update documentation with lessons learned
- Assess if Phase 5 (data correction) is needed

---

## Related Scenarios

**Dependencies**:
- Secondary Transport Implementation (Oct 7-8, 2025) - Adds dual transport capability
- CS Invoicing (Oct 10, 2025) - RLCSChargeService.cls updated same day

**Related Implementations**:
- CS Invoicing Date/Description Fields (Oct 10, 2025)
- Secondary Transport Charges (Oct 7-8, 2025)

**Integration Points**:
- RLCS_Job__c object (trigger target)
- OrderItem object (source of truth for rates and flags)
- RLCS_Charge__c object (charge records created)
- rlcsJobService.cls calls RLCSChargeService.cls

---

## Documentation Updates

**After successful deployment, update**:

1. **This README**:
   - Migration Status: 📋 Ready for Review → 🚀 Deployed
   - Deployment Date: [Actual date]
   - Deploy IDs: [Salesforce Deploy IDs from each phase]

2. **MIGRATION_PROGRESS.md** (main project):
   - Mark Transport Charges as "Deployed"
   - Update Batch 2 progress

3. **OldOrg State README** (reference):
   - Add note: "Deployed to NewOrg on [date]"

4. **Gap Analysis** (reference):
   - Add note: "Gaps addressed on [date]"

---

## Support Information

**Migration Owner**: John Shintu
**Deployment Team**: Technical Team
**Business Stakeholders**: Finance, Operations, CS Team

**For Issues During Deployment**:
- Check rollback plan (this document)
- Review debug logs
- Contact: [Contact Info]

**For Post-Deployment Issues**:
- Monitor Jobs not receiving charges
- Check charge calculation accuracy
- Review error logs
- Contact: [Contact Info]

---

## Appendices

### Appendix A: Bug Fix Details

**Issue 1 Fix (Map Reassignment)**:

```apex
// Line 277 in rlcsJobService.cls

// BEFORE (BUGGY):
if (jobsToProcessById.size() > 0) {
    Map<Id, RLCS_Job__c> jobsWithOrderProductMap = new Map<Id, RLCS_Job__c>([...]);
    // MISSING: jobsToProcessById = jobsWithOrderProductMap;
}

// AFTER (FIXED):
if (jobsToProcessById.size() > 0) {
    Map<Id, RLCS_Job__c> jobsWithOrderProductMap = new Map<Id, RLCS_Job__c>([...]);
    jobsToProcessById = jobsWithOrderProductMap; // ✅ ADDED
}
```

**Issue 3 Fix (OrderItem Source of Truth)**:

```apex
// Lines 393-396 in rlcsJobService.cls

// BEFORE (BUGGY):
Decimal primaryTransportAmount =
    (job.Transport_Per_Tonne__c ?              // ❌ Job flag
        (job.Material_Weight_Tonnes__c ?? 0) :
     job.Transport_Per_Unit__c ?               // ❌ Job flag
        (job.Unit_Count__c ?? 0) :
        1) *
    primaryTransportRate;

// AFTER (FIXED):
Decimal primaryTransportAmount =
    (job.Order_Product__r?.Transport_Per_Tonne__c ?  // ✅ OrderItem flag
        (job.Material_Weight_Tonnes__c ?? 0) :
     job.Order_Product__r?.Transport_Per_Unit__c ?   // ✅ OrderItem flag
        (job.Unit_Count__c ?? 0) :
        1) *
    primaryTransportRate;
```

---

### Appendix B: Verification Queries Reference

```bash
# All Apex classes
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name IN ('rlcsJobService', 'rlcsJobServiceTest', 'RLCSChargeService') ORDER BY Name" --target-org NewOrg --use-tooling-api

# Validation rule
sf data query --query "SELECT FullName, Active, ErrorMessage FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'OrderItem' AND ValidationName = 'Transport_Only_One_Method'" --target-org NewOrg --use-tooling-api

# Test coverage
sf apex run test --tests "rlcsJobServiceTest" --target-org NewOrg --code-coverage --result-format human --wait 10

# Invalid OrderItems
sf data query --query "SELECT Id, Product2.Name, Transport__c, Transport_Per_Tonne__c, Transport_Per_Unit__c FROM OrderItem WHERE Transport_Per_Tonne__c = true AND Transport_Per_Unit__c = true" --target-org NewOrg

# Jobs before fix date
sf data query --query "SELECT COUNT() FROM RLCS_Job__c WHERE CreatedDate < 2025-10-14T18:37:00Z" --target-org NewOrg

# Recent Jobs with charges
sf data query --query "SELECT Id, Name, (SELECT Id, Cost__c, Charge_Type__c FROM RLCS_Charges__r WHERE Charge_Type__c = 'Transport') FROM RLCS_Job__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg

# Apex errors
sf data query --query "SELECT Id, Operation, Status, StartTime FROM ApexLog WHERE Operation LIKE '%rlcsJob%' AND Status != 'Success' AND StartTime = TODAY ORDER BY StartTime DESC" --target-org NewOrg --use-tooling-api
```

---

### Appendix C: Component Dependencies

```
Transport_Only_One_Method (VALIDATION)
    ↓
    Validates: OrderItem.Transport_Per_Tonne__c, OrderItem.Transport_Per_Unit__c
    ↓
    Prevents: Both flags = true (invalid state)

rlcsJobServiceTest.cls (TEST CLASS)
    ↓
    Tests: rlcsJobService.cls
    ↓
    Provides: 75%+ code coverage for deployment

rlcsJobService.cls (CORE SERVICE)
    ↓
    Reads: OrderItem.Transport__c, Transport_Per_Tonne__c, Transport_Per_Unit__c (FIX: OrderItem, not Job)
    ↓
    Calls: RLCSChargeService.createAutoJobCharge()
    ↓
    Creates: RLCS_Charge__c records

RLCSChargeService.cls (CHARGE CREATION)
    ↓
    Called by: rlcsJobService.cls
    ↓
    Creates: RLCS_Charge__c records with calculated amounts
```

---

## Quick Links

- [OldOrg State Documentation](/tmp/Salesforce_OldOrg_State/transport-charges/README.md)
- [Gap Analysis](/tmp/Salesforce_OldOrg_State/transport-charges/GAP_ANALYSIS.md)
- [Original Source Documentation](/tmp/Salesforce_OldOrg_State/transport-charges/source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md)

---

**Migration Plan Status**: 📋 Ready for Review
**Last Updated**: October 22, 2025
**Next Steps**:
1. Review this migration plan
2. Decide on Phase 5 approach (data analysis)
3. Schedule deployment window
4. Execute deployment phases in order
5. Complete post-deployment verification
6. Monitor for 24-48 hours

**Ready for Deployment** ✅
