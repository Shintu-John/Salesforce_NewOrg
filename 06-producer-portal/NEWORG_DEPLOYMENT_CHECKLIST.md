# NewOrg Producer Portal Deployment Checklist

**Date**: October 27, 2025
**Status**: PARTIAL DEPLOYMENT - Critical gaps identified
**Target**: NewOrg (shintu.john@recyclinglives-services.com)

---

## Executive Summary

**Good News**: Most components exist in NewOrg
**Bad News**: Critical components are OUTDATED or INACTIVE

### Critical Issues Found:
1. ❌ **SignatureLwcHelper** - Missing Is_Record_Signed__c fix (causes infinite loop)
2. ❌ **All Sharing Triggers** - Status = Inactive (sharing not working!)
3. ✅ **Already deployed SignatureLwcHelper fix** - Deploy ID: 0AfSq000003onDVKAY (needs verification)

---

## 1. Foundation Components Status

### ✅ Licenses (READY)
| License Type | Total | Used | Available |
|--------------|-------|------|-----------|
| Customer Community Plus | 80 | 0 | 80 |
| Customer Community Plus Login | 2000 | 1 | 1999 |

### ✅ Profiles (EXIST)
- Producer Director User (Customer Community Plus)
- Producer Director User Login (Customer Community Plus Login) ✅
- Producer Standard User (Customer Community Plus)
- Producer Standard User Login (Customer Community Plus Login) ✅
- RLCC - RLCS Producer Director
- RLCC - RLCS Producer Standard

### ✅ Permission Set (EXISTS)
- Customer_Community_Plus ✅

### ❌ Portal Users (NONE ACTIVE)
- **No active producer portal users found** (except Guest user)
- **No permission set assignments found**
- **Action**: Users need to be created/activated when ready for testing

---

## 2. Code Component Comparison

### Component 1: SignatureLwcHelper.cls

**Status**: ❌ **OUTDATED in NewOrg** → ✅ **DEPLOYED Oct 27** (needs verification)

| Attribute | NewOrg (Before) | OldOrg (Current) | NewOrg (After Deploy) |
|-----------|---------|----------|----------|
| Last Modified | Sept 16, 2025 (Glen Bagshaw) | Oct 27, 2025 | Oct 27, 2025 |
| Length | 826 characters | ~900 characters | Should match OldOrg |
| Has Is_Record_Signed__c fix | ❌ NO | ✅ YES | ✅ YES (if deploy succeeded) |

**Critical Code Difference**:
```apex
// MISSING in old NewOrg version (causes infinite loop):
if(sObjectType == Schema.Producer_Placed_on_Market__c.SObjectType){
    record.put('Is_Record_Signed__c', true);
}
```

**Deploy Status**: ✅ Deployed (Deploy ID: 0AfSq000003onDVKAY) at 19:55 GMT
**Verification Needed**: Query NewOrg to confirm the fix is present

---

### Component 2: Sharing Triggers

**Status**: ❌ **INACTIVE in NewOrg**

| Trigger Name | Code Match | NewOrg Status | OldOrg Status | Action |
|--------------|------------|---------------|---------------|--------|
| ProducerContractSharingTrigger | ✅ Identical | ❌ Inactive | ✅ Active | ACTIVATE |
| ProducerObligationSharingTrigger | ✅ Identical | ❌ Inactive | ✅ Active | ACTIVATE |
| ProducerPlacedOnMarketSharingTrigger | ✅ Identical | ❌ Inactive | ✅ Active | ACTIVATE |
| UserSharingBackfill | ✅ Identical | ❌ Inactive | ✅ Active | ACTIVATE |

**Impact of Inactive Triggers**:
- Login license users CANNOT see producer records
- No automatic sharing when records are created
- Portal is unusable for Login users

**How to Activate**:
1. Navigate to Setup → Apex Triggers
2. For each trigger above, click Edit → Change Status to Active → Save
3. OR deploy with status=Active in metadata

---

### Component 3: Helper Classes

**Status**: ✅ **UP TO DATE in NewOrg**

| Class | NewOrg Last Modified | Match Status |
|-------|---------------------|--------------|
| ProducerSharingHelper | Oct 24, 2025 (Shintu John) | ✅ Recent deployment |
| ProducerSharingHelperTest | Oct 24, 2025 (Shintu John) | ✅ Recent deployment |
| UserSharingBackfillHelper | Oct 24, 2025 (Shintu John) | ✅ Recent deployment |
| UserSharingBackfillHelperTest | Oct 24, 2025 (Shintu John) | ✅ Recent deployment |

---

### Component 4: Flows

**Status**: ✅ **EXIST in NewOrg** (activation status TBD)

All critical flows exist:
- Producer_POM_Update_Status ✅
- Producer_POM_Acknowledge_Feedback ✅
- Producer_Placed_On_Market_Signature_Best_Action ✅
- Producer_Placed_On_Market_Question_Best_Action ✅
- Producer_Placed_On_Market_Resubmission_Best_Action ✅
- Allowed_Resubmission_of_POMD ✅
- validationQuestionsFlow ✅

**Action Needed**: Verify these flows are ACTIVE (not Draft)

---

### Component 5: LWC Components

**Status**: ✅ **EXISTS in NewOrg**

- captureSignature ✅

**Action Needed**: Verify code matches OldOrg version

---

## 3. Immediate Action Plan

### Step 1: Verify SignatureLwcHelper Deployment ✅ DONE
```bash
sf data query --query "SELECT LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'SignatureLwcHelper'" --target-org NewOrg
```

**Expected**:
- LastModifiedDate: 2025-10-27 (today)
- LengthWithoutComments: ~900 characters (NOT 826)

---

### Step 2: Activate All Sharing Triggers ⚠️ PENDING

**Option A: Via UI (Manual)**
1. Setup → Apex Triggers
2. Click on each trigger:
   - ProducerContractSharingTrigger
   - ProducerObligationSharingTrigger
   - ProducerPlacedOnMarketSharingTrigger
   - UserSharingBackfill
3. Change Status from Inactive to Active
4. Save

**Option B: Via Metadata Deployment (Automated)**
```bash
cd /home/john/Projects/Salesforce/deployment-execution/06-producer-portal
sf project deploy start \
  --source-dir code/main/default/triggers \
  --target-org NewOrg \
  --test-level NoTestRun
```

**Verification**:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name LIKE '%Sharing%' ORDER BY Name" --target-org NewOrg
```

Expected: All should show Status = Active

---

### Step 3: Verify Flow Activation ⚠️ PENDING

Cannot query FlowDefinition directly. Need to:
1. Setup → Flows
2. Check each flow listed above
3. Ensure Status = Active (not Draft)

---

### Step 4: Create Test Portal User ⚠️ PENDING

1. Create Contact with Account
2. Create User:
   - Profile: Producer Director User Login
   - License: Customer Community Plus Login
   - ContactId: (link to Contact)
3. Assign Permission Set:
   - Customer_Community_Plus
4. Activate user

---

### Step 5: Test Signature Workflow ⚠️ PENDING

1. Login as portal user
2. Navigate to Producer_Placed_on_Market__c record
3. Ensure status = "Pending Director Review"
4. Draw signature and click "Capture Signature"
5. **Expected**:
   - Signature saves
   - Status changes to "Signed"
   - Page redirects to record
   - **NO infinite loop!**

---

## 4. Risk Assessment

### High Risk Items:
1. **Inactive Triggers**: Portal completely non-functional for Login users
2. **Outdated SignatureLwcHelper**: Would cause infinite loop (✅ mitigated by deployment)

### Medium Risk Items:
1. **No active portal users**: Cannot test until users are created
2. **Flow activation unknown**: Flows might be Draft

### Low Risk Items:
1. **Helper classes**: Already up to date from Oct 24 deployment

---

## 5. Testing Checklist

Once all components are activated:

- [ ] Verify SignatureLwcHelper has Is_Record_Signed__c fix
- [ ] Verify all 4 sharing triggers are Active
- [ ] Verify all 7 flows are Active
- [ ] Create test portal user with Login license
- [ ] Assign Customer_Community_Plus permission set
- [ ] Test record visibility (user should see producer records)
- [ ] Test signature capture workflow (no infinite loop)
- [ ] Test status progression (Draft → Pending → Signed)
- [ ] Test validation questions workflow
- [ ] Test resubmission workflow

---

## 6. Deployment History Reference

| Component | Deploy ID | Date | Status |
|-----------|-----------|------|--------|
| SignatureLwcHelper (fixed) | 0AfSq000003onDVKAY | Oct 27, 2025 19:55 GMT | ✅ Succeeded |
| Helper Classes | Various | Oct 24, 2025 | ✅ Complete |
| Triggers (code) | Various | Oct 24, 2025 | ✅ Deployed but Inactive |

---

## 7. Next Steps for Tomorrow's Testing

1. **Before Testing**:
   - [ ] Activate all 4 sharing triggers
   - [ ] Verify all flows are Active
   - [ ] Create 1-2 test portal users
   - [ ] Assign permission sets

2. **During Testing**:
   - [ ] Test with director user (Login license)
   - [ ] Test signature workflow end-to-end
   - [ ] Monitor for infinite loop issue
   - [ ] Test all producer portal tabs/features

3. **After Testing**:
   - [ ] Document any new issues found
   - [ ] Create fixes for any problems
   - [ ] Deploy fixes to both OldOrg and NewOrg simultaneously

---

## 8. Key Contacts & Resources

- **NewOrg URL**: https://recyclinglives-services.my.salesforce.com
- **OldOrg URL**: https://recyclinglives.my.salesforce.com
- **Deployment History**: [DEPLOYMENT_HISTORY.md](DEPLOYMENT_HISTORY.md)
- **Code Comparison**: [code-comparison/COMPARISON_REPORT.md](code-comparison/COMPARISON_REPORT.md)

---

**Last Updated**: October 27, 2025 19:56 GMT
**Next Review**: October 28, 2025 (before user testing)
