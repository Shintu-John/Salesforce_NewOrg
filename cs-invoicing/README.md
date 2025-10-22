# CS Invoicing - NewOrg Migration Plan

**Scenario**: CS Invoicing Improvements - Date & Description Fields Auto-Population
**Migration Date**: October 22, 2025
**Source**: OldOrg (October 10-15, 2025 deployments)
**Target**: NewOrg
**Migration Status**: 🔴 **READY FOR DEPLOYMENT**

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Overview](#migration-overview)
3. [Gap Analysis Summary](#gap-analysis-summary)
4. [Pre-Deployment Checklist](#pre-deployment-checklist)
5. [Deployment Phases](#deployment-phases)
6. [Testing and Validation](#testing-and-validation)
7. [Rollback Procedures](#rollback-procedures)
8. [Post-Deployment Monitoring](#post-deployment-monitoring)
9. [Known Issues and Limitations](#known-issues-and-limitations)
10. [Success Criteria](#success-criteria)

---

## Executive Summary

### Business Problem

**Current State (NewOrg)**:
- Date__c and Description__c fields exist but may not be auto-populated correctly
- Collection_Date__c field completely missing
- CS Invoicing team must manually enter charge details
- Invoice dates may not reflect actual collection dates

**Target State (Post-Migration)**:
- Date__c auto-populated from Job's collected date (for invoice filtering)
- Description__c auto-populated from Job's waste type, product, and EWC code
- Collection_Date__c auto-populated from Job's collected date (for PDF display)
- Zero manual data entry required
- Improved invoice accuracy and tracking

### Migration Scope

**Components to Deploy**:
- **6 Apex classes** (3 production + 3 test)
- **1 custom field** (Collection_Date__c)
- **13 permission sets** (Field-Level Security)
- **1 Lightning page** (Record page layout)

**Deployment Method**: Salesforce CLI (sf project deploy)
**Estimated Time**: 3-4 hours deployment + 24 hours monitoring
**Risk Level**: 🟡 **MEDIUM** (Core charge creation logic changes)

---

## Migration Overview

### What Changed Between OldOrg and NewOrg

| Component | OldOrg (Oct 10-15, 2025) | NewOrg Current | Action |
|-----------|--------------------------|----------------|--------|
| **RLCSChargeService.cls** | ✅ 4,849 lines (V2 with Collection_Date__c) | ⚠️ 3,517 lines (partial V1) | Replace |
| **rlcsJobService.cls** | ✅ 41,558 lines (Oct 15) | ⚠️ 28,853 lines (Oct 10) | Replace |
| **RLCSCreditInvoiceAction.cls** | ✅ 6,206 lines (Oct 10) | ⚠️ 6,059 lines (Sep 18) | Replace |
| **RLCSChargeServiceTest.cls** | ✅ 18,681 lines | ⚠️ 18,598 lines | Replace |
| **rlcsJobServiceTest.cls** | ✅ 84,118 lines | ❌ Missing | Deploy |
| **RLCSCreditInvoiceActionTest.cls** | ✅ 10,025 lines | ⚠️ 9,869 lines | Replace |
| **Collection_Date__c** | ✅ Exists | ❌ Missing | Create |
| **FLS (13 permission sets)** | ✅ Configured | ❌ Missing | Configure |
| **Lightning Record Page** | ✅ Has Collection_Date__c | ❌ Missing | Update |

### Implementation Summary

**V1 (Date__c + Description__c)**:
- Modified RLCSChargeService to accept full Job object instead of just ID
- Added buildChargeDescription() helper method
- Updated rlcsJobService SOQL query to include 4 new fields
- Updated 12 method calls to pass full Job object
- Added 14 test methods for coverage

**V2 (Collection_Date__c)**:
- Created new Collection_Date__c field
- Added Collection_Date__c population in RLCSChargeService
- Configured FLS for 13 permission sets
- Added field to Lightning Record Page

**Key Benefits**:
- 100% automatic field population
- Formatted descriptions: "Waste Type: X, Product: Y, EWC: Z"
- Separate date fields for filtering vs display
- Backward compatible - existing charges unaffected

---

## Gap Analysis Summary

### Critical Findings

**Gap Severity**: 🟡 **MEDIUM-HIGH** - Partial implementation exists, complete deployment required

**Key Gaps**:
1. **rlcsJobServiceTest.cls**: ❌ MISSING (deployment blocker)
2. **rlcsJobService.cls**: ⚠️ OUTDATED (12,705 lines missing - 30%)
3. **Collection_Date__c**: ❌ MISSING (entire V2 feature absent)
4. **RLCSChargeService.cls**: ⚠️ OUTDATED (1,332 lines missing)
5. **RLCSCreditInvoiceAction.cls**: ⚠️ OUTDATED (pre-dates Oct 10 changes)

**Business Impact**:
- CS Invoicing improvements not available to users
- Manual data entry still required
- Invoice tracking suboptimal

**Full Gap Analysis**: See [GAP_ANALYSIS.md](./GAP_ANALYSIS.md)

---

## Pre-Deployment Checklist

### Prerequisites Verification

**Before starting deployment, verify the following in NewOrg**:

#### 1. RLCS Job Fields Exist

```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'RLCS_Job__c' AND QualifiedApiName IN ('Collected_Date__c', 'Product_Name__c', 'Waste_Type__c', 'EWC__c')" --target-org NewOrg
```

**Expected Result**: 4 fields exist
- Collected_Date__c (Date)
- Product_Name__c (Text)
- Waste_Type__c (Text)
- EWC__c (Text)

**Status**: ✅ ⬜ (Check one)

---

#### 2. RLCS_Charge__c Object and Date/Description Fields Exist

```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'RLCS_Charge__c' AND QualifiedApiName IN ('Date__c', 'Description__c')" --target-org NewOrg
```

**Expected Result**: 2 fields exist
- Date__c (Date)
- Description__c (Text Area)

**Status**: ✅ ⬜ (Check one)

---

#### 3. Test Data Availability

```bash
# Check if Jobs exist with required fields populated
sf data query --query "SELECT COUNT(Id) FROM RLCS_Job__c WHERE Collected_Date__c != null AND (Product_Name__c != null OR Waste_Type__c != null OR EWC__c != null)" --target-org NewOrg
```

**Expected Result**: Some Jobs exist (>0)

**Actual Count**: _______ Jobs

**Status**: ✅ ⬜ (Check one)

---

#### 4. Backup Current State

```bash
# Backup current Apex classes (in case rollback needed)
mkdir -p /tmp/Salesforce_NewOrg/cs-invoicing/backups

# Backup RLCSChargeService
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSChargeService'" --target-org NewOrg --use-tooling-api --json > /tmp/Salesforce_NewOrg/cs-invoicing/backups/RLCSChargeService_PreMigration.json

# Backup rlcsJobService
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api --json > /tmp/Salesforce_NewOrg/cs-invoicing/backups/rlcsJobService_PreMigration.json

# Backup RLCSCreditInvoiceAction
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSCreditInvoiceAction'" --target-org NewOrg --use-tooling-api --json > /tmp/Salesforce_NewOrg/cs-invoicing/backups/RLCSCreditInvoiceAction_PreMigration.json

# Verify backups created
ls -lh /tmp/Salesforce_NewOrg/cs-invoicing/backups/
```

**Status**: ✅ ⬜ (Check one)

---

### Pre-Deployment Checklist Summary

| Item | Status | Notes |
|------|--------|-------|
| 1. RLCS Job Fields Verified | ⬜ | |
| 2. RLCS_Charge Fields Verified | ⬜ | |
| 3. Test Data Available | ⬜ | |
| 4. Current State Backed Up | ⬜ | |

**Proceed to Deployment**: ⬜ YES (All items checked) / ⬜ NO (Issues to resolve)

---

## Deployment Phases

### Phase 1: Retrieve Source Code from OldOrg

**Objective**: Get October 10-15, 2025 versions of all components

**Commands**:

```bash
# Create deployment directory
mkdir -p /tmp/cs-invoicing-deployment/force-app/main/default/classes
mkdir -p /tmp/cs-invoicing-deployment/force-app/main/default/objects/RLCS_Charge__c/fields
mkdir -p /tmp/cs-invoicing-deployment/force-app/main/default/permissionsets
mkdir -p /tmp/cs-invoicing-deployment/force-app/main/default/flexipages

# Retrieve production Apex classes
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSChargeService'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/RLCSChargeService.cls

sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/rlcsJobService.cls

sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSCreditInvoiceAction'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/RLCSCreditInvoiceAction.cls

# Retrieve test Apex classes
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSChargeServiceTest'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/RLCSChargeServiceTest.cls

sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'rlcsJobServiceTest'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/rlcsJobServiceTest.cls

sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'RLCSCreditInvoiceActionTest'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/cs-invoicing-deployment/force-app/main/default/classes/RLCSCreditInvoiceActionTest.cls

# Create metadata files for Apex classes
for cls in RLCSChargeService rlcsJobService RLCSCreditInvoiceAction RLCSChargeServiceTest rlcsJobServiceTest RLCSCreditInvoiceActionTest; do
  if [[ $cls == "rlcs"* ]]; then
    api_version="62.0"
  else
    api_version="64.0"
  fi
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ApexClass xmlns=\"http://soap.sforce.com/2006/04/metadata\">
    <apiVersion>$api_version</apiVersion>
    <status>Active</status>
</ApexClass>" > /tmp/cs-invoicing-deployment/force-app/main/default/classes/${cls}.cls-meta.xml
done

# Retrieve Collection_Date__c field metadata
sf project retrieve start --metadata CustomField:RLCS_Charge__c.Collection_Date__c --target-org OldOrg --output-dir /tmp/cs-invoicing-deployment

# Retrieve 13 permission sets with Collection_Date__c FLS
# (List from OldOrg verification)
sf project retrieve start --metadata PermissionSet:RLCS_Job_Create_Orders_Order_Products_Sites_RLCS_Job,PermissionSet:Odaseva_Service_User_Permissions,PermissionSet:MuleSoft_RLC_Access,PermissionSet:RLCS_Job_RLC_Access,PermissionSet:PO_Invoices,PermissionSet:Admin,PermissionSet:PO_Admin,PermissionSet:RLCS_Site,PermissionSet:Freight_Forwarder_Permission_Set,PermissionSet:RLCS_Job_Approve_RLC,PermissionSet:Accounts,PermissionSet:RLCS_View_Payments,PermissionSet:Users_Access --target-org OldOrg --output-dir /tmp/cs-invoicing-deployment

# Retrieve Lightning Record Page
sf project retrieve start --metadata FlexiPage:RLCS_Charge_Record_Page --target-org OldOrg --output-dir /tmp/cs-invoicing-deployment

# Create sfdx-project.json
echo '{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "64.0"
}' > /tmp/cs-invoicing-deployment/sfdx-project.json

# Verify files retrieved
echo "=== Apex Classes ==="
ls -lh /tmp/cs-invoicing-deployment/force-app/main/default/classes/

echo "=== Custom Fields ==="
ls -lh /tmp/cs-invoicing-deployment/force-app/main/default/objects/RLCS_Charge__c/fields/

echo "=== Permission Sets ==="
ls -lh /tmp/cs-invoicing-deployment/force-app/main/default/permissionsets/

echo "=== FlexiPages ==="
ls -lh /tmp/cs-invoicing-deployment/force-app/main/default/flexipages/
```

**Expected Result**: All components retrieved successfully

**Status**: ⬜ COMPLETE

---

### Phase 2: Deploy Test Classes First

**Objective**: Deploy test classes to meet code coverage requirements

**Why Test Classes First**: Salesforce requires 75% code coverage. Deploying tests first ensures we can validate production classes during deployment.

**Commands**:

```bash
cd /tmp/cs-invoicing-deployment

# Deploy ONLY test classes
sf project deploy start \
  --source-dir force-app/main/default/classes/RLCSChargeServiceTest.cls \
  --source-dir force-app/main/default/classes/rlcsJobServiceTest.cls \
  --source-dir force-app/main/default/classes/RLCSCreditInvoiceActionTest.cls \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 15 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 3
  - RLCSChargeServiceTest.cls
  - rlcsJobServiceTest.cls (NEW)
  - RLCSCreditInvoiceActionTest.cls
```

**Troubleshooting**:
- **Error: "Invalid dependencies"**: Tests reference production classes. Skip to Phase 3 (deploy all together).
- **Error: "Unknown custom field"**: Tests reference Collection_Date__c. Skip to Phase 3.

**Status**: ⬜ COMPLETE (or ⬜ SKIPPED - deploying all together)

---

### Phase 3: Deploy Collection_Date__c Field

**Objective**: Create Collection_Date__c field before deploying Apex that references it

**Commands**:

```bash
cd /tmp/cs-invoicing-deployment

# Deploy Collection_Date__c field metadata
sf project deploy start \
  --source-dir force-app/main/default/objects/RLCS_Charge__c/fields/Collection_Date__c.field-meta.xml \
  --target-org NewOrg \
  --wait 5 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 1
  - RLCS_Charge__c.Collection_Date__c
```

**Verification**:
```bash
# Verify field created
sf data query --query "SELECT QualifiedApiName, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'RLCS_Charge__c' AND QualifiedApiName = 'Collection_Date__c'" --target-org NewOrg
```

**Expected**: Field exists with Label = "Collection Date"

**Status**: ⬜ COMPLETE

---

### Phase 4: Deploy Production Apex Classes

**Objective**: Deploy/update main Apex classes with all CS Invoicing logic

**Commands**:

```bash
cd /tmp/cs-invoicing-deployment

# Deploy production Apex classes with RunSpecifiedTests
sf project deploy start \
  --source-dir force-app/main/default/classes/RLCSChargeService.cls \
  --source-dir force-app/main/default/classes/rlcsJobService.cls \
  --source-dir force-app/main/default/classes/RLCSCreditInvoiceAction.cls \
  --source-dir force-app/main/default/classes/RLCSChargeServiceTest.cls \
  --source-dir force-app/main/default/classes/rlcsJobServiceTest.cls \
  --source-dir force-app/main/default/classes/RLCSCreditInvoiceActionTest.cls \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests RLCSChargeServiceTest rlcsJobServiceTest RLCSCreditInvoiceActionTest \
  --wait 20 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 6
  - RLCSChargeService.cls
  - rlcsJobService.cls
  - RLCSCreditInvoiceAction.cls
  - RLCSChargeServiceTest.cls
  - rlcsJobServiceTest.cls
  - RLCSCreditInvoiceActionTest.cls

Test Results:
  - Total Tests: 87+
  - Passing: 87+ (100%)
  - Failing: 0

Code Coverage:
  - RLCSChargeService: 100%
  - rlcsJobService: 79.77%+
  - RLCSCreditInvoiceAction: 100%
```

**Troubleshooting**:
- **Test Failures**: Review test error messages - may indicate NewOrg data differences
- **Coverage < 75%**: Verify test classes deployed correctly
- **Deployment Timeout**: Increase `--wait` to 30 minutes

**Status**: ⬜ COMPLETE

**Deployment ID**: _________________ (Record for rollback)

---

### Phase 5: Verify Apex Deployment

**Objective**: Confirm all classes deployed with correct versions

**Commands**:

```bash
# Verify all 6 classes exist in NewOrg
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name, LengthWithoutComments FROM ApexClass WHERE Name IN ('RLCSChargeService', 'rlcsJobService', 'RLCSCreditInvoiceAction', 'RLCSChargeServiceTest', 'rlcsJobServiceTest', 'RLCSCreditInvoiceActionTest') ORDER BY Name" --target-org NewOrg --use-tooling-api

# Verify test execution
sf apex run test --class-names RLCSChargeServiceTest rlcsJobServiceTest RLCSCreditInvoiceActionTest --result-format human --target-org NewOrg
```

**Expected Result**:

| Class Name | Expected Lines | Last Modified | Modified By |
|------------|----------------|---------------|-------------|
| RLCSChargeService | 4,849 | TODAY | Your Name |
| RLCSChargeServiceTest | 18,681 | TODAY | Your Name |
| RLCSCreditInvoiceAction | 6,206 | TODAY | Your Name |
| RLCSCreditInvoiceActionTest | 10,025 | TODAY | Your Name |
| rlcsJobService | 41,558 | TODAY | Your Name |
| rlcsJobServiceTest | 84,118 | TODAY | Your Name |

**Actual Results**:
- RLCSChargeService: _______ lines, Date: _____________
- RLCSChargeServiceTest: _______ lines, Date: _____________
- RLCSCreditInvoiceAction: _______ lines, Date: _____________
- RLCSCreditInvoiceActionTest: _______ lines, Date: _____________
- rlcsJobService: _______ lines, Date: _____________
- rlcsJobServiceTest: _______ lines, Date: _____________

**Test Results**: ⬜ ALL PASS / ⬜ FAILURES (describe: _________________)

**Status**: ⬜ COMPLETE

---

### Phase 6: Deploy Field-Level Security

**Objective**: Configure Collection_Date__c FLS for 13 permission sets

**Commands**:

```bash
cd /tmp/cs-invoicing-deployment

# Deploy 13 permission sets with Collection_Date__c FLS
sf project deploy start \
  --source-dir force-app/main/default/permissionsets \
  --target-org NewOrg \
  --wait 10 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 13 permission sets
  - RLCS_Job_Create_Orders_Order_Products_Sites_RLCS_Job
  - Odaseva_Service_User_Permissions
  - MuleSoft_RLC_Access
  - RLCS_Job_RLC_Access
  - PO_Invoices
  - Admin
  - PO_Admin
  - RLCS_Site
  - Freight_Forwarder_Permission_Set
  - RLCS_Job_Approve_RLC
  - Accounts
  - RLCS_View_Payments
  - Users_Access
```

**Verification**:
```bash
# Verify FLS configured (example for one permission set)
sf data query --query "SELECT Parent.Name, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Field = 'RLCS_Charge__c.Collection_Date__c' AND Parent.Name = 'Admin'" --target-org NewOrg
```

**Expected**: PermissionsRead = true, PermissionsEdit = true

**Status**: ⬜ COMPLETE

---

### Phase 7: Deploy Lightning Record Page

**Objective**: Add Collection_Date__c to RLCS Charge record page

**Commands**:

```bash
cd /tmp/cs-invoicing-deployment

# Deploy Lightning Record Page
sf project deploy start \
  --source-dir force-app/main/default/flexipages/RLCS_Charge_Record_Page.flexipage-meta.xml \
  --target-org NewOrg \
  --wait 5 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 1
  - RLCS_Charge_Record_Page
```

**Verification**:
```bash
# Open a charge record in NewOrg and verify Collection_Date__c field visible
# Manual verification required
```

**Status**: ⬜ COMPLETE

---

### Phase 8: Functional Testing

**Objective**: Create test Job and verify charges have populated fields

**Commands**:

```bash
# Query recent charges to verify field population
sf data query --query "SELECT Id, Name, Date__c, Description__c, Collection_Date__c, RLCS_Job__r.Collected_Date__c, RLCS_Job__r.Waste_Type__c, RLCS_Job__r.Product_Name__c, RLCS_Job__r.EWC__c, CreatedDate FROM RLCS_Charge__c WHERE CreatedDate > YESTERDAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg
```

**Expected Result**:
- Date__c = Job's Collected_Date__c
- Description__c = "Waste Type: X, Product: Y, EWC: Z" format
- Collection_Date__c = Job's Collected_Date__c

**Manual Test** (Recommended):
1. Open NewOrg
2. Create or update an RLCS Job to "Completed" status
3. Ensure Job has:
   - Collected_Date__c populated
   - Product_Name__c populated (e.g., "Scrap Metal")
   - Waste_Type__c populated (e.g., "Metal")
   - EWC__c populated (e.g., "17 04 07")
4. Verify charges created automatically
5. Open a charge record
6. Verify:
   - Date__c = Job's Collected_Date__c ✅
   - Description__c = "Waste Type: Metal, Product: Scrap Metal, EWC: 17 04 07" ✅
   - Collection_Date__c = Job's Collected_Date__c ✅

**Test Results**:
- ⬜ Date__c populated correctly
- ⬜ Description__c formatted correctly
- ⬜ Collection_Date__c populated correctly

**Status**: ⬜ COMPLETE

---

### Deployment Phases Summary

| Phase | Status | Completion Time | Notes |
|-------|--------|-----------------|-------|
| 1. Retrieve Source Code | ⬜ | _____________ | |
| 2. Deploy Test Classes | ⬜ | _____________ | |
| 3. Deploy Collection_Date__c Field | ⬜ | _____________ | |
| 4. Deploy Production Apex | ⬜ | _____________ | Deployment ID: _______ |
| 5. Verify Apex Deployment | ⬜ | _____________ | |
| 6. Deploy FLS | ⬜ | _____________ | 13 permission sets |
| 7. Deploy Lightning Page | ⬜ | _____________ | |
| 8. Functional Testing | ⬜ | _____________ | |

**Overall Deployment Status**: ⬜ SUCCESS / ⬜ PARTIAL / ⬜ FAILED

---

## Testing and Validation

### Unit Testing (Automated)

**Already Completed During Deployment** (Phase 4 - RunSpecifiedTests)

**Test Classes**:
1. RLCSChargeServiceTest (14 test methods)
2. rlcsJobServiceTest
3. RLCSCreditInvoiceActionTest

**Test Coverage**:
- RLCSChargeService: 100%
- rlcsJobService: 79.77%+
- RLCSCreditInvoiceAction: 100%

**Test Results**: ⬜ ALL PASS / ⬜ FAILURES

---

### Integration Testing (Manual)

#### Test Scenario 1: Variable Pricing Job

**Objective**: Verify Date/Description population for variable pricing method

**Steps**:
1. Create Job with Pricing Method = "Variable"
2. Set Collected_Date__c = Today
3. Set Product_Name__c = "8 Yard Skip"
4. Set Waste_Type__c = "Mixed Waste"
5. Set EWC__c = "20 03 01"
6. Complete Job

**Expected Result**:
- Job Charge created with:
  - Date__c = Today
  - Description__c = "Waste Type: Mixed Waste, Product: 8 Yard Skip, EWC: 20 03 01"
  - Collection_Date__c = Today

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 2: Rebate Pricing Job

**Objective**: Verify Date/Description for rebate charges

**Steps**:
1. Create Job with Pricing Method = "Rebate"
2. Set Collected_Date__c = Yesterday
3. Set Product_Name__c = "Scrap Metal"
4. Set Waste_Type__c = "Ferrous Metal"
5. Set EWC__c = "17 04 05"
6. Complete Job

**Expected Result**:
- Rebate Charge created with:
  - Date__c = Yesterday
  - Description__c = "Waste Type: Ferrous Metal, Product: Scrap Metal, EWC: 17 04 05"
  - Collection_Date__c = Yesterday

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 3: Job with Partial Fields

**Objective**: Verify graceful handling when some fields are blank

**Steps**:
1. Create Job with Pricing Method = "Variable"
2. Set Collected_Date__c = Today
3. Set Product_Name__c = "Cardboard Baling"
4. Leave Waste_Type__c BLANK
5. Leave EWC__c BLANK
6. Complete Job

**Expected Result**:
- Charge created with:
  - Date__c = Today
  - Description__c = "Product: Cardboard Baling" (only populated field)
  - Collection_Date__c = Today

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 4: Invoice Filtering with Date__c

**Objective**: Verify Date__c still works for "Raised Between" invoice filtering

**Steps**:
1. Create multiple charges with different Date__c values
2. Go to Invoice generation
3. Use "Raised Between" filter with date range
4. Verify only charges within range are included

**Expected Result**: Date__c filtering continues to work as before

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 5: Collection_Date__c Field Visibility

**Objective**: Verify Collection_Date__c visible in UI

**Steps**:
1. Open any RLCS Charge record
2. Scroll to Collection_Date__c field section
3. Verify field is visible and editable

**Expected Result**: Collection_Date__c field visible on record page

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

### User Acceptance Testing (UAT)

**Stakeholders**: CS Invoicing team

**UAT Checklist**:

| Test Case | Expected Result | Actual Result | Status |
|-----------|-----------------|---------------|--------|
| Create Job and verify charge Date__c matches Collected_Date__c | Date__c = Collected_Date__c | | ⬜ |
| Verify Description__c contains waste type, product, EWC | Formatted string appears | | ⬜ |
| Verify Collection_Date__c populated | Collection_Date__c = Collected_Date__c | | ⬜ |
| Check invoice "Raised Between" filtering | Date__c filtering works | | ⬜ |
| View Collection_Date__c in charge record | Field visible in UI | | ⬜ |
| Verify existing charges unaffected | Old charges unchanged | | ⬜ |

**UAT Sign-Off**: ⬜ APPROVED / ⬜ ISSUES FOUND (Describe: _________________)

---

## Rollback Procedures

### When to Rollback

**Trigger rollback if**:
- ❌ Charge creation fails completely
- ❌ Invoice generation breaks
- ❌ Test failures > 25%
- ❌ SOQL errors in charge creation
- ❌ Date__c invoice filtering stops working

**Do NOT rollback for**:
- ⚠️ Description format tweaks needed (cosmetic)
- ⚠️ Collection_Date__c not in PDF yet (known limitation - template update pending)

---

### Rollback Steps

#### Step 1: Restore Production Apex Classes

```bash
# Deploy pre-migration versions from backup
cd /tmp/Salesforce_NewOrg/cs-invoicing/backups

# Extract Apex code from backup JSON files
jq -r '.result.records[0].Body' RLCSChargeService_PreMigration.json > RLCSChargeService.cls
jq -r '.result.records[0].Body' rlcsJobService_PreMigration.json > rlcsJobService.cls
jq -r '.result.records[0].Body' RLCSCreditInvoiceAction_PreMigration.json > RLCSCreditInvoiceAction.cls

# Create metadata files
for cls in RLCSChargeService rlcsJobService RLCSCreditInvoiceAction; do
  if [[ $cls == "rlcs"* ]]; then
    api_version="62.0"
  else
    api_version="64.0"
  fi
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<ApexClass xmlns=\"http://soap.sforce.com/2006/04/metadata\">
    <apiVersion>$api_version</apiVersion>
    <status>Active</status>
</ApexClass>" > ${cls}.cls-meta.xml
done

# Deploy rollback versions
sf project deploy start \
  --source-dir . \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 20
```

**Note**: Cannot roll back rlcsJobServiceTest (didn't exist before) or Collection_Date__c field (cannot delete with data)

**Status**: ⬜ COMPLETE

---

#### Step 2: Verify Rollback Success

```bash
# Verify charge creation still works
sf data query --query "SELECT Id, Name, CreatedDate FROM RLCS_Charge__c ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**Expected**: Charges still creating (even if Date/Description not auto-populated)

**Status**: ⬜ COMPLETE

---

#### Step 3: Notify Stakeholders

**Communication**:
- Subject: "CS Invoicing Deployment Rollback"
- Recipients: CS Invoicing team, Tech Lead
- Content: Explain rollback reason, timeline for re-deployment

**Status**: ⬜ COMPLETE

---

### Rollback Decision Log

| Date | Issue | Decision | Executed By | Result |
|------|-------|----------|-------------|--------|
| | | ⬜ ROLLBACK / ⬜ KEEP | | |

---

## Post-Deployment Monitoring

### First 24 Hours (Critical Monitoring)

**Monitoring Schedule**:

| Time | Event | Action | Status |
|------|-------|--------|--------|
| Deployment + 1 hour | Initial check | Verify charges creating | ⬜ |
| Deployment + 4 hours | Mid-day check | Check field population | ⬜ |
| Deployment + 8 hours | End-of-day check | Review error logs | ⬜ |
| Deployment + 24 hours | Daily review | Comprehensive validation | ⬜ |

---

### Monitoring Queries

#### Query 1: Charge Creation Rate

```bash
sf data query --query "SELECT COUNT(Id) TotalCharges, COUNT(Date__c) WithDate, COUNT(Description__c) WithDescription, COUNT(Collection_Date__c) WithCollectionDate FROM RLCS_Charge__c WHERE CreatedDate = TODAY" --target-org NewOrg
```

**Run Frequency**: Every 4 hours for first 24 hours

**Expected Result**: All counts roughly equal (some variance OK if Jobs have null source fields)

---

#### Query 2: Description Format Quality

```bash
sf data query --query "SELECT Description__c, RLCS_Job__r.Waste_Type__c, RLCS_Job__r.Product_Name__c, RLCS_Job__r.EWC__c FROM RLCS_Charge__c WHERE CreatedDate = TODAY AND Description__c != null ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg
```

**Run Frequency**: Daily

**Expected Result**: Descriptions formatted as "Waste Type: X, Product: Y, EWC: Z"

---

#### Query 3: Date Accuracy

```bash
sf data query --query "SELECT Id, Name, Date__c, Collection_Date__c, RLCS_Job__r.Collected_Date__c FROM RLCS_Charge__c WHERE CreatedDate = TODAY AND Date__c != RLCS_Job__r.Collected_Date__c LIMIT 5" --target-org NewOrg
```

**Run Frequency**: Daily

**Expected Result**: 0 records (Date__c and Collection_Date__c should match Job's Collected_Date__c)

---

#### Query 4: Error Logs

```bash
sf data query --query "SELECT Id, Operation, ErrorMessage, CreatedDate FROM ApexLog WHERE CreatedDate = TODAY AND Operation LIKE '%RLCSCharge%' ORDER BY CreatedDate DESC LIMIT 20" --target-org NewOrg --use-tooling-api
```

**Run Frequency**: As needed if issues reported

**Expected Result**: No errors related to charge creation

---

### First Week Monitoring Checklist

| Day | Charges Created | Fields Populated | Errors | User Feedback | Notes |
|-----|-----------------|------------------|--------|---------------|-------|
| Day 1 | ⬜ | ⬜ | ⬜ | ⬜ | Deployment day |
| Day 2 | ⬜ | ⬜ | ⬜ | ⬜ | |
| Day 3 | ⬜ | ⬜ | ⬜ | ⬜ | |
| Day 4 | ⬜ | ⬜ | ⬜ | ⬜ | |
| Day 5 | ⬜ | ⬜ | ⬜ | ⬜ | |
| Day 6 | ⬜ | ⬜ | ⬜ | ⬜ | |
| Day 7 | ⬜ | ⬜ | ⬜ | ⬜ | End of week review |

**First Week Status**: ⬜ SUCCESS / ⬜ ISSUES FOUND (Describe: _________________)

---

## Known Issues and Limitations

### Known Issue 1: PDF Template Not Updated

**Issue**: Collection_Date__c field does NOT appear in invoice PDF
**Root Cause**: RS Doc Google Doc template lacks `<<Collection_Date__c>>` merge field
**Impact**: Collection_Date__c visible in Salesforce UI but not in printed invoices
**Workaround**: CS team can view Collection_Date__c in Salesforce UI (charge record page)
**Resolution**: Separate task requiring template owner to edit Google Doc (GDT-000049)
**Priority**: MEDIUM (Salesforce deployment complete, template update independent)

---

### Limitation 1: No Configuration Options

**Description**: Description format is hardcoded ("Waste Type: X, Product: Y, EWC: Z")
**Impact**: Cannot customize format without code changes
**Future Enhancement**: Custom Metadata Type for description templates

---

### Limitation 2: Single Date Source

**Description**: Both Date__c and Collection_Date__c use same source (Job.Collected_Date__c)
**Impact**: Cannot have different dates for filtering vs display
**Rationale**: Current business requirement is same date for both purposes
**Future Enhancement**: Separate date fields if business needs diverge

---

### Limitation 3: Historical Charges Not Updated

**Description**: Only NEW charges get auto-populated fields
**Impact**: Existing charges retain empty Date__c/Description__c/Collection_Date__c
**Workaround**: Update historical charges manually if needed (one-time data fix)
**Future Enhancement**: Backfill script to populate existing charges

---

## Success Criteria

### Deployment Success
- ✅ All 6 Apex classes deployed without errors
- ✅ All test classes pass (87+ tests, 100%)
- ✅ Collection_Date__c field created
- ✅ FLS configured for 13 permission sets
- ✅ Lightning Record Page updated
- ✅ Code coverage > 75%

### Field Population Success
- ✅ Date__c populated automatically on new charges
- ✅ Description__c contains formatted string
- ✅ Collection_Date__c populated automatically on new charges
- ✅ No null pointer exceptions
- ✅ Charges created successfully

### User Adoption
- ✅ CS Invoicing team verifies Date__c appears correctly
- ✅ CS Invoicing team verifies Description__c format meets expectations
- ✅ No disruption to existing workflows
- ✅ Field visible in Salesforce UI
- ⚠️ PDF template update pending (separate task)

---

### Final Sign-Off

| Stakeholder | Role | Sign-Off Date | Status |
|-------------|------|---------------|--------|
| CS Invoicing Team | End User | | ⬜ APPROVED / ⬜ PENDING |
| Technical Lead | Implementation | | ⬜ APPROVED / ⬜ PENDING |

**Overall Migration Status**: ⬜ SUCCESS / ⬜ PARTIAL SUCCESS / ⬜ FAILED

---

## Appendix

### A. Deployment Checklist Summary

**Pre-Deployment**:
- ⬜ RLCS Job fields verified
- ⬜ RLCS_Charge fields verified
- ⬜ Test data available
- ⬜ Current state backed up

**Deployment**:
- ⬜ Source code retrieved from OldOrg
- ⬜ Test classes deployed
- ⬜ Collection_Date__c field created
- ⬜ Production Apex deployed
- ⬜ Deployment verified
- ⬜ FLS configured
- ⬜ Lightning page updated
- ⬜ Functional testing complete

**Post-Deployment**:
- ⬜ Integration testing complete
- ⬜ UAT complete
- ⬜ First 24 hours monitoring complete
- ⬜ First week monitoring complete
- ⬜ Stakeholder sign-off obtained

---

### B. Key Contacts

| Role | Name | Responsibility |
|------|------|----------------|
| CS Invoicing Team | [Team Lead Name] | End users, UAT, feedback |
| Technical Lead | [Your Name] | Deployment execution |
| RS Doc Administrator | [Template Owner] | PDF template update (separate task) |

---

### C. Reference Documentation

- **OldOrg State README**: `/tmp/Salesforce_OldOrg_State/cs-invoicing/README.md`
- **NewOrg Gap Analysis**: `/tmp/Salesforce_NewOrg/cs-invoicing/GAP_ANALYSIS.md`
- **Source Documentation**: `/tmp/Salesforce_OldOrg_State/cs-invoicing/source-docs/CS_INVOICING_DATE_DESCRIPTION_FIELDS.md`

---

### D. Component Summary

**Apex Classes (Production)**:
- RLCSChargeService.cls (4,849 lines)
- rlcsJobService.cls (41,558 lines)
- RLCSCreditInvoiceAction.cls (6,206 lines)

**Apex Classes (Test)**:
- RLCSChargeServiceTest.cls (18,681 lines)
- rlcsJobServiceTest.cls (84,118 lines)
- RLCSCreditInvoiceActionTest.cls (10,025 lines)

**Custom Fields**:
- RLCS_Charge__c.Collection_Date__c (NEW)

**Permission Sets** (13 total):
- RLCS_Job_Create_Orders_Order_Products_Sites_RLCS_Job
- Odaseva_Service_User_Permissions
- MuleSoft_RLC_Access
- RLCS_Job_RLC_Access
- PO_Invoices
- Admin
- PO_Admin
- RLCS_Site
- Freight_Forwarder_Permission_Set
- RLCS_Job_Approve_RLC
- Accounts
- RLCS_View_Payments
- Users_Access

**FlexiPage**:
- RLCS_Charge_Record_Page.flexipage-meta.xml

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| Oct 22, 2025 | 1.0 | Initial migration plan created | Claude (Automated) |

---

**END OF MIGRATION PLAN**

**Ready for Deployment**: ✅ YES
**Next Action**: Begin Pre-Deployment Checklist
