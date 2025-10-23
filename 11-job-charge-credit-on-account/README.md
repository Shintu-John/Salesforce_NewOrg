# Job Charge Credit on Account Fix - NewOrg Migration Package

**Created**: October 23, 2025
**Target Org**: NewOrg (Recycling Lives Group)
**Migration Status**: Ready for Deployment
**Estimated Deployment Time**: 30-45 minutes

---

## Executive Summary

This package deploys the **Critical Data Integrity Fix** for Job Charge Credit on Account charges from OldOrg to NewOrg.

**What's Being Migrated**:
- Updated `Job_Charge_Minimum_20_Gross_on_Rebate` Flow (v6) with bugfix that removes "Credit on Account" from entry criteria

**Why This Matters**:
- NewOrg currently has the BUGGY version (Oct 19, 2025) with "Credit on Account" still in filter criteria
- NewOrg flow is currently DEACTIVATED (IsActive = false), which means the bug isn't active yet
- Must deploy fixed version BEFORE activating the flow to prevent data corruption

**Business Impact**:
- Prevents Cost__c field corruption on Credit on Account Job Charges (263 charges exist in NewOrg)
- Maintains data integrity for financial records
- Zero impact on existing Rebate charge functionality

---

## Related Documentation

### OldOrg State Documentation
- [OldOrg Implementation Details](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/job-charge-credit-on-account) - Complete verification, code analysis, and deployment history from OldOrg

### Source Documentation
- [JOB_CHARGE_CREDIT_ON_ACCOUNT_FIX.md](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/job-charge-credit-on-account/source-docs/JOB_CHARGE_CREDIT_ON_ACCOUNT_FIX.md) - Original detailed documentation with field structure analysis and complete examples

---

## Gap Analysis

### Current State Comparison

| Component | OldOrg Status | NewOrg Status | Gap | Action Required |
|-----------|---------------|---------------|-----|-----------------|
| **Flow: Job_Charge_Minimum_20_Gross_on_Rebate** | ✅ Fixed (v6, Oct 22) | ❌ Buggy (v5, Oct 19) | **OUTDATED** | ✅ **Deploy fixed version** |
| Flow Status | Active | **Inactive** | Safer deployment | ⚠️ Keep inactive until tested |
| filterLogic | `1 AND 2 AND 3 AND 4 AND 5` | `1 AND (2 OR 3)` | **BUG PRESENT** | ✅ Update filter logic |
| Charge_Type Filter | "Rebate" only | "Rebate" OR "Credit on Account" | **BUG PRESENT** | ✅ Remove "Credit on Account" |
| Account IDs (JLP) | 0012400000UtGrjAAF | 001Sq00000XxQyXIAV | **DIFFERENT** | ✅ Update Account ID |
| Account IDs (BT) | 0012400000kFifTAAS | 001Sq00000XxNZMIA3 | **DIFFERENT** | ✅ Update Account ID |
| Account IDs (British Gas) | 0012400000RIw4FAAT | 001Sq00000XxOpNIAV | **DIFFERENT** | ✅ Update Account ID |
| Job_Charge__c Fields | ✅ All exist | ✅ All exist | No gap | ✅ No action |
| Job__c Fields | ✅ All exist | ✅ All exist | No gap | ✅ No action |
| Account Fields | ✅ All exist | ✅ All exist | No gap | ✅ No action |
| Credit on Account Charges | 305 charges | 263 charges | Different volume | ℹ️ Expected (different orgs) |

### Critical Findings

#### 🚨 Critical - Flow Has Bug
**Issue**: NewOrg has the OLD BUGGY version (Oct 19) that still includes "Credit on Account" in entry criteria
**Risk**: If activated without fix, will corrupt Cost__c values on Credit on Account charges
**Mitigation**: Deploy fixed version BEFORE activating flow

#### ✅ Advantage - Flow Already Inactive
**Status**: NewOrg flow is currently deactivated (IsActive = false)
**Benefit**: Bug is NOT active, so no data corruption has occurred yet
**Strategy**: Deploy fix while inactive, test thoroughly, then activate

#### ⚠️ Account ID Differences
**Issue**: The 3 excluded vendor Account IDs are different in NewOrg vs OldOrg
**Resolution**: Updated Account IDs in deployment package to match NewOrg values

| Account Name | OldOrg ID | NewOrg ID |
|--------------|-----------|-----------|
| John Lewis Partnership | 0012400000UtGrjAAF | 001Sq00000XxQyXIAV |
| BT GROUP PLC | 0012400000kFifTAAS | 001Sq00000XxNZMIA3 |
| British Gas | 0012400000RIw4FAAT | 001Sq00000XxOpNIAV |

---

## Pre-Deployment Environment Verification

### STEP 1: Verify Dependencies Exist ✅ CLI Step

Run these queries to confirm all required fields and records exist in NewOrg:

**1. Verify Job_Charge__c Fields**:
```bash
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Job_Charge__c' AND QualifiedApiName IN ('Charge_Type__c', 'Vendor_Account__c', 'Sales_Account__c', 'Don_t_Apply_Auto_Margin__c', 'Job__c', 'Cost__c') ORDER BY QualifiedApiName" --target-org NewOrg
```

**Expected**: 6 fields returned
- Charge_Type__c (Picklist)
- Cost__c (Currency)
- Don_t_Apply_Auto_Margin__c (Checkbox)
- Job__c (Master-Detail)
- Sales_Account__c (Lookup)
- Vendor_Account__c (Lookup)

**2. Verify Job__c Fields**:
```bash
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Job__c' AND QualifiedApiName IN ('Supplier_Price__c', 'Sales_Price__c', 'Weight__c') ORDER BY QualifiedApiName" --target-org NewOrg
```

**Expected**: 3 fields returned
- Sales_Price__c (Currency)
- Supplier_Price__c (Currency)
- Weight__c (Number)

**3. Verify Account Fields**:
```bash
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Account' AND QualifiedApiName IN ('Account_Uses_Ratecard__c', 'Don_t_Apply_Rebate_Margin__c') ORDER BY QualifiedApiName" --target-org NewOrg
```

**Expected**: 2 fields returned
- Account_Uses_Ratecard__c (Checkbox)
- Don_t_Apply_Rebate_Margin__c (Checkbox)

**4. Verify Excluded Vendor Accounts**:
```bash
sf data query --query "SELECT Id, Name FROM Account WHERE Name IN ('John Lewis Partnership', 'BT GROUP PLC', 'British Gas') ORDER BY Name" --target-org NewOrg
```

**Expected**: 3 accounts returned
- British Gas (001Sq00000XxOpNIAV)
- BT GROUP PLC (001Sq00000XxNZMIA3)
- John Lewis Partnership (001Sq00000XxQyXIAV)

**5. Verify Current Flow Status**:
```bash
sf data query --query "SELECT ApiName, Label, LastModifiedDate, IsActive FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate'" --target-org NewOrg
```

**Expected**:
- LastModifiedDate: 2025-10-19 (pre-fix version)
- IsActive: false (deactivated)

**If ANY verification fails**: Stop deployment and investigate missing dependencies.

---

## Deployment Steps

### Phase 1: Backup Current State ⚠️ Manual UI Step

**Purpose**: Create backup before making changes

**Steps**:
1. Navigate to Setup > Flows in NewOrg
2. Search for "Job Charge: Minimum 20% Gross on Rebate"
3. Click the flow name
4. Note current version number (likely v5 or earlier)
5. Click "View All Versions"
6. Document: Current Active Version, Last Modified Date
7. **DO NOT activate** - keep flow inactive during deployment

**Verification**:
```bash
sf data query --query "SELECT VersionNumber, Status, LastModifiedDate FROM FlowVersionView WHERE FlowDefinitionViewId IN (SELECT DurableId FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate') ORDER BY VersionNumber DESC LIMIT 3" --target-org NewOrg
```

**Expected**: List of versions with status (Active/Draft/Obsolete)

---

### Phase 2: Deploy Fixed Flow ✅ CLI Step

**Purpose**: Deploy the corrected flow version with Account ID updates

**Command**:
```bash
sf project deploy start \
  -d /tmp/Salesforce_NewOrg/job-charge-credit-on-account/code/flows \
  --target-org NewOrg \
  --dry-run
```

**First run with --dry-run to verify**:
- Flow metadata is valid
- No deployment errors
- Dependencies are satisfied

**If dry-run succeeds, deploy for real**:
```bash
sf project deploy start \
  -d /tmp/Salesforce_NewOrg/job-charge-credit-on-account/code/flows \
  --target-org NewOrg
```

**Expected Output**:
```
Component Type: Flow
Component Name: Job_Charge_Minimum_20_Gross_on_Rebate
Status: Changed
```

**Verification**:
```bash
sf data query --query "SELECT ApiName, LastModifiedDate, IsActive FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate'" --target-org NewOrg
```

**Expected**:
- LastModifiedDate: TODAY (October 23, 2025)
- IsActive: false (still inactive - we'll activate after testing)

---

### Phase 3: Verify Fix in Flow Builder ⚠️ Manual UI Step

**Purpose**: Visually confirm the fix in Flow Builder before activating

**Steps**:
1. Navigate to Setup > Flows
2. Open "Job Charge: Minimum 20% Gross on Rebate"
3. Click "View Properties & Versions"
4. Check description: Should show "22/10/2025: Removed Credit on Account from filter"
5. Click "Open" on latest version (draft)
6. Verify "Start" element:
   - filterLogic: `1 AND 2 AND 3 AND 4 AND 5` (NO parentheses!)
   - Filter 1: CreatedDate > Jan 15, 2025
   - Filter 2: Charge_Type = "Rebate" ONLY (no "Credit on Account"!)
   - Filters 3-5: Vendor_Account exclusions with NEW Account IDs:
     - 001Sq00000XxQyXIAV (John Lewis Partnership)
     - 001Sq00000XxNZMIA3 (BT GROUP PLC)
     - 001Sq00000XxOpNIAV (British Gas)

**✅ If all verified**: Proceed to Phase 4
**❌ If issues found**: Stop and investigate

---

### Phase 4: Create Test Credit on Account Charge ⚠️ Manual UI Step

**Purpose**: Test that flow does NOT execute on Credit on Account charges

**Prerequisites**:
- Flow must still be INACTIVE
- Need a test Job with margin < 20%

**Test Steps**:
1. Find or create a test Job with:
   - Supplier_Price > Sales_Price (margin < 20%)
   - Example: Supplier_Price = 100, Sales_Price = 80 → 20% margin (borderline)
2. Create a related Rebate Job Charge with:
   - Cost = -100
   - Sales_Price = -80
3. Create a Credit on Account Job Charge with:
   - Cost = -80
   - Sales_Price = -100
4. Click Save
5. **Verify**: Cost remains -80 (NOT changed to calculated value)
6. **Verify**: Sales_Price remains -100

**Verification Query**:
```bash
sf data query --query "SELECT Id, Name, Charge_Type__c, Cost__c, Sales_Price__c FROM Job_Charge__c WHERE Id = '<CHARGE_ID>'" --target-org NewOrg
```

**Expected**: Values match what you entered (no automated changes)

---

### Phase 5: Activate Fixed Flow (OPTIONAL - Consult First) ⚠️ Manual UI Step

**⚠️ IMPORTANT**: This flow is currently deactivated in NewOrg for a reason. Check with stakeholders before activating!

**If activation is approved**:

**Steps**:
1. Navigate to Setup > Flows
2. Open "Job Charge: Minimum 20% Gross on Rebate"
3. Click "Activate" on the latest fixed version
4. Confirm activation

**Verification**:
```bash
sf data query --query "SELECT ApiName, IsActive, LastModifiedDate FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate'" --target-org NewOrg
```

**Expected**:
- IsActive: true
- LastModifiedDate: Today

---

### Phase 6: Test Rebate Charges Still Work ⚠️ Manual UI Step

**Purpose**: Confirm Rebate margin enforcement still functions

**Test Steps**:
1. Create a Rebate Job Charge on a Job with margin < 20%
2. Enter Cost and Sales Price values
3. Save
4. **Verify**: Flow executed and adjusted Cost__c appropriately
5. **Verify**: Parent Job's Sales_Price__c was updated

**Verification Query**:
```bash
sf data query --query "SELECT Id, Name, Charge_Type__c, Cost__c, Sales_Price__c, Job__r.Sales_Price__c FROM Job_Charge__c WHERE Id = '<REBATE_CHARGE_ID>'" --target-org NewOrg
```

**Expected**: Cost__c shows calculated value (not user-entered value)

---

### Phase 7: Monitor for Issues ⚠️ Manual UI Step

**Duration**: 24-48 hours after activation

**Monitor**:
1. Debug logs for flow executions
2. Field history on Job_Charge__c.Cost__c
3. User reports of unexpected Cost values

**Verification Queries**:

**Count new Credit on Account charges**:
```bash
sf data query --query "SELECT COUNT() FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND CreatedDate >= TODAY" --target-org NewOrg
```

**Check for any negative Cost values that became positive** (indication of bug):
```bash
sf data query --query "SELECT Id, Name, Cost__c, Sales_Price__c, CreatedDate FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND Cost__c > 0 AND CreatedDate >= TODAY LIMIT 10" --target-org NewOrg
```

**Expected**: No records (all Credit on Account charges should have negative Cost)

---

## Code Files Reference

### Deployment Package Contents

**Total Files**: 1

**flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml** (198 lines)
- Fixed Flow version from OldOrg (v6)
- Account IDs updated for NewOrg environment
- Description: "22/10/2025: Removed Credit on Account from filter - should only run on Rebate charges"
- filterLogic: `1 AND 2 AND 3 AND 4 AND 5` (Credit on Account filter removed)
- Status: Active (in file, but deployment will initially be Draft)

---

## Post-Deployment Validation

### Validation Checklist

After deployment, verify each item:

- [ ] **Flow deployed successfully** - Check deployment results for "Succeeded"
- [ ] **Flow version incremented** - New version created (check version number)
- [ ] **Flow description updated** - Shows "22/10/2025: Removed Credit on Account from filter"
- [ ] **filterLogic corrected** - Shows `1 AND 2 AND 3 AND 4 AND 5` (no OR)
- [ ] **Credit on Account filter removed** - Only "Rebate" in Charge_Type filter
- [ ] **Account IDs updated** - Shows NewOrg Account IDs (001Sq...) not OldOrg (00124...)
- [ ] **Test charge preserved values** - Credit on Account test charge Cost__c unchanged
- [ ] **Flow activation (if activated)** - IsActive = true
- [ ] **Rebate charges still work** - Margin enforcement executes on Rebate charges
- [ ] **No error reports** - No user complaints about incorrect Cost values

### Validation Queries

**1. Verify Flow Metadata**:
```bash
sf data query --query "SELECT ApiName, Label, LastModifiedDate, IsActive FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate'" --target-org NewOrg
```

**2. Verify No Broken Credit on Account Charges**:
```bash
sf data query --query "SELECT COUNT() FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND Cost__c > 0 AND CreatedDate >= 2025-10-23T00:00:00Z" --target-org NewOrg
```
**Expected**: 0 (no positive Cost values on Credit on Account charges)

**3. Verify Flow Execution Count** (if activated):
```bash
sf data query --query "SELECT COUNT() FROM FlowInterview WHERE FlowVersionViewId IN (SELECT Id FROM FlowVersionView WHERE FlowDefinitionViewId IN (SELECT DurableId FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate')) AND CreatedDate >= 2025-10-23T00:00:00Z" --target-org NewOrg
```
**Expected**: Count of flow executions (should only be on Rebate charges, not Credit on Account)

---

## Rollback Procedures

### Immediate Rollback (If Issues Discovered Within 1 Hour)

**Scenario**: Flow causes data corruption or unexpected behavior

**Steps**:
1. **Deactivate Flow Immediately**:
   - Setup > Flows > Job Charge: Minimum 20% Gross on Rebate
   - Click "Deactivate"
   - Confirm deactivation

2. **Verify Deactivation**:
```bash
sf data query --query "SELECT ApiName, IsActive FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate'" --target-org NewOrg
```
**Expected**: IsActive = false

3. **Assess Damage**:
```bash
sf data query --query "SELECT Id, Name, Cost__c, Sales_Price__c, LastModifiedDate FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND LastModifiedDate >= LAST_N_HOURS:1 ORDER BY LastModifiedDate DESC" --target-org NewOrg
```

4. **Fix Affected Records** (if any found with incorrect Cost__c):
   - Use Data Loader or manual edit to correct Cost__c values
   - Reference original user-entered values from Field History

### Partial Rollback (Revert to Previous Version)

**Scenario**: Need to revert to pre-deployment flow version

**Steps**:
1. Navigate to Setup > Flows
2. Open "Job Charge: Minimum 20% Gross on Rebate"
3. Click "View All Versions"
4. Find previous version (likely v5 or earlier from Oct 19)
5. Click "Activate" on previous version
6. **Note**: This restores the BUG! Use only as temporary measure while investigating issues.

**Verification**:
```bash
sf data query --query "SELECT VersionNumber, Status, LastModifiedDate FROM FlowVersionView WHERE FlowDefinitionViewId IN (SELECT DurableId FROM FlowDefinitionView WHERE ApiName = 'Job_Charge_Minimum_20_Gross_on_Rebate') AND Status = 'Active'" --target-org NewOrg
```

### Full Rollback (Re-deploy Old Version)

**Scenario**: Need to completely remove fix and restore original

**Not Recommended**: The original version has the BUG. Only use if absolutely necessary.

**Steps**:
1. Retrieve old flow version from NewOrg backup
2. Deploy using CLI:
```bash
sf project deploy start \
  -d /path/to/backup/flows \
  --target-org NewOrg
```

---

## Testing Plan

### Unit Testing

**Not Applicable**: Flows do not have unit test requirements

### Integration Testing

**Test Scenario 1: Credit on Account - Low Margin Job**
- **Setup**: Job with 15% margin (Supplier_Price = 100, Sales_Price = 85)
- **Action**: Create Credit on Account charge (Cost = -100, Sales_Price = -85)
- **Expected**: Values remain unchanged (flow does NOT execute)
- **Status**: Ready for testing post-deployment

**Test Scenario 2: Rebate - Low Margin Job**
- **Setup**: Same Job (15% margin)
- **Action**: Create Rebate charge
- **Expected**: Flow executes, Cost__c recalculated, Job Sales_Price__c updated
- **Status**: Ready for testing post-deployment

**Test Scenario 3: Credit on Account - High Margin Job**
- **Setup**: Job with 25% margin (Supplier_Price = 100, Sales_Price = 75)
- **Action**: Create Credit on Account charge
- **Expected**: Values remain unchanged (flow does NOT execute - margin too high)
- **Status**: Ready for testing post-deployment

**Test Scenario 4: Excluded Vendor**
- **Setup**: Job with vendor = John Lewis Partnership
- **Action**: Create Rebate charge with low margin
- **Expected**: Flow does NOT execute (vendor excluded)
- **Status**: Ready for testing post-deployment

### User Acceptance Testing (UAT)

**UAT Plan**:
1. **Finance Team**: Create 3-5 Credit on Account charges in production
2. **Duration**: 3-5 business days
3. **Success Criteria**: All Cost__c values remain as entered (no automated changes)
4. **Sign-off**: Finance Manager approval required before full rollout

---

## Known Risks & Mitigation

### Risk 1: Account ID Mismatch 🟡 MEDIUM

**Risk**: Hard-coded Account IDs in flow may not match NewOrg Account IDs

**Likelihood**: LOW (verified during gap analysis)

**Impact**: HIGH (excluded vendors would not be excluded, causing incorrect margin enforcement)

**Mitigation**:
- ✅ Pre-deployment verification confirmed Account IDs (see Gap Analysis)
- ✅ Deployment package uses correct NewOrg Account IDs
- ✅ Post-deployment testing with John Lewis Partnership, BT, and British Gas

### Risk 2: Flow Activation Timing ⚠️ LOW

**Risk**: Flow could be accidentally activated before testing complete

**Likelihood**: LOW (clear documentation to keep inactive)

**Impact**: MEDIUM (untested flow running in production)

**Mitigation**:
- ✅ Documentation explicitly states: Keep flow INACTIVE until tested
- ✅ Deployment file has status="Active" but NewOrg will keep it inactive initially
- ✅ Activation is separate manual step (Phase 5)

### Risk 3: Existing Broken Records in NewOrg 🟡 MEDIUM

**Risk**: NewOrg may already have broken Credit on Account charges (if flow was active before Oct 19)

**Likelihood**: MEDIUM (flow exists since Jan 15, 2025 but currently inactive)

**Impact**: LOW (historical data, doesn't affect new charges)

**Mitigation**:
- ✅ Query for existing broken records:
```bash
sf data query --query "SELECT Id, Name, Cost__c, Sales_Price__c FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND Cost__c > 0 AND CreatedDate BETWEEN 2025-01-15T00:00:00Z AND 2025-10-19T00:00:00Z LIMIT 10" --target-org NewOrg
```
- ✅ If found, create data cleanup script to fix historical records

### Risk 4: Dependencies Missing 🟢 LOW

**Risk**: Required fields or objects don't exist in NewOrg

**Likelihood**: VERY LOW (verified in pre-deployment checks)

**Impact**: HIGH (deployment would fail)

**Mitigation**:
- ✅ Comprehensive pre-deployment verification (Phase 1)
- ✅ All 11 fields verified in gap analysis
- ✅ Dry-run deployment before actual deployment

---

## Deployment Metadata

**Package Name**: job-charge-credit-on-account-fix
**Version**: 1.0
**Target Org**: NewOrg (Recycling Lives Group)
**Source Org**: OldOrg (recyclinglives.my.salesforce.com)
**Deployment Date**: TBD (Ready for deployment October 23, 2025)
**Deployed By**: TBD
**Estimated Time**: 30-45 minutes (including verification)
**Rollback Time**: 5-10 minutes (deactivate flow)

---

## Summary

This migration package deploys a critical data integrity fix from OldOrg to NewOrg. The fix removes an incorrect filter condition in the `Job_Charge_Minimum_20_Gross_on_Rebate` Flow that allowed margin enforcement logic (designed for Rebate charges) to execute on Credit on Account charges, causing Cost__c field corruption.

**Key Points**:
- ✅ NewOrg flow is currently INACTIVE (bug not causing issues yet)
- ✅ Deploy fix BEFORE activating flow
- ✅ Account IDs updated for NewOrg environment
- ✅ All dependencies verified
- ✅ Comprehensive testing plan included
- ✅ Rollback procedures documented

**Deployment Strategy**:
1. Deploy flow while inactive
2. Test thoroughly
3. Consult stakeholders before activating
4. Monitor for 24-48 hours after activation

**Risk Level**: 🟢 LOW (flow currently inactive, comprehensive testing plan, quick rollback available)

---

**Documentation Version**: 1.0
**Last Updated**: October 23, 2025
**Next Review**: After NewOrg deployment
