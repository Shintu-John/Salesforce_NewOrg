# NewOrg Producer Portal Deployment Plan

**Date**: October 28, 2025
**Prepared By**: John Shintu
**Status**: READY FOR DEPLOYMENT

---

## Executive Summary

Comprehensive comparison reveals NewOrg is PARTIALLY deployed. Critical components are missing or outdated:
- ❌ **ProducerPomAcknowledgeController** - MISSING (signature popup logic)
- ❌ **All Sharing Triggers** - INACTIVE (portal users can't see records)
- ⚠️ **SignatureLwcHelper** - DEPLOYED but needs Profile.Name fix
- ⚠️ **Show_Signature_Popup__c** - EXISTS but needs Profile.Name fix

**Risk**: Without this deployment, producer portal is NON-FUNCTIONAL in NewOrg.

---

## Component-by-Component Comparison

### 1. Licenses & Profiles

| Component | OldOrg | NewOrg | Status | Action |
|-----------|--------|--------|--------|--------|
| **Customer Community Plus** | 200 total, 199 used | 80 total, 0 used | ⚠️ Fewer licenses | Monitor usage |
| **Customer Community Plus Login** | 13,000 total, 863 used | 2,000 total, 1 used | ✅ Sufficient | None |
| **Producer Director User** | ✅ Exists | ✅ Exists | ✅ Match | None |
| **Producer Director User Login** | ✅ Exists | ✅ Exists | ✅ Match | None |
| **Producer Standard User** | ✅ Exists | ✅ Exists | ✅ Match | None |
| **Producer Standard User Login** | ✅ Exists | ✅ Exists | ✅ Match | None |

**Assessment**: ✅ Foundation is ready. Profiles exist in both orgs.

---

### 2. Apex Classes Comparison

| Class Name | OldOrg Status | NewOrg Status | Action Required |
|------------|---------------|---------------|-----------------|
| **ProducerSharingHelper** | ✅ Oct 21 (6,343 chars) | ✅ Oct 24 (6,343 chars) | ✅ MATCH - No action |
| **ProducerSharingHelperTest** | ✅ Oct 21 (11,647 chars) | ⚠️ Oct 24 (13,428 chars) | ⚠️ Different length - Check code |
| **UserSharingBackfillHelper** | ✅ Oct 21 (2,576 chars) | ✅ Oct 24 (2,576 chars) | ✅ MATCH - No action |
| **UserSharingBackfillHelperTest** | ✅ Oct 21 (6,919 chars) | ⚠️ Oct 24 (9,447 chars) | ⚠️ Different length - Check code |
| **SignatureLwcHelper** | ✅ Oct 27 (944 chars) | ✅ Oct 27 (944 chars) | ⚠️ NEEDS VERIFICATION - Has Profile.Name fix? |
| **SignatureLwcHelperTest** | ✅ Feb 28 (324 chars) | ✅ Oct 27 (324 chars) | ✅ MATCH - No action |
| **ProducerPomAcknowledgeController** | ✅ Oct 28 (3,304 chars) | ❌ **MISSING** | ❌ **DEPLOY REQUIRED** |
| **ProducerPomAcknowledgeControllerTest** | ✅ Oct 28 (2,045 chars) | ❌ **MISSING** | ❌ **DEPLOY REQUIRED** |

**Critical Finding**: ProducerPomAcknowledgeController is the KEY component that checks user profile and controls signature popup visibility!

---

### 3. Triggers Comparison

| Trigger Name | OldOrg Status | NewOrg Status | Action Required |
|--------------|---------------|---------------|-----------------|
| **ProducerContractSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **ProducerObligationSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **ProducerPlacedOnMarketSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **UserSharingBackfill** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| ProducerPlacedOnMarketTrigger | ✅ Active | ✅ Active | ✅ Already active |
| Rollup_ProducerContractTrigger | ✅ Active | ❌ Inactive | Not critical for portal |
| Rollup_ProducerObligationTrigger | ✅ Active | ✅ Active | ✅ Already active |
| Rollup_ProducerPlacedOnMarketTrigger | ✅ Active | ❌ Inactive | Not critical for portal |

**Critical Finding**: ALL 4 sharing triggers are inactive in NewOrg! Login license users CANNOT see producer records without these triggers.

---

### 4. Custom Fields (Show_Signature_Popup__c)

**OldOrg Version** (Fixed Oct 28):
```apex
OR(
  $Profile.Name = "Producer Director User",
  $Profile.Name = "Producer Director User Login",
  $Profile.Name = "RLCC - RLCS Producer Director"
)
```

**NewOrg Version** (Needs Update):
```apex
OR(
  $User.Profile_Name__c = "Producer Director User",  // ← WRONG!
  $User.Profile_Name__c = "Producer Director User Login",
  $User.Profile_Name__c = "RLCC - RLCS Producer Director"
)
```

**Action**: Deploy updated formula field

---

## Deployment Plan

### Phase 1: Deploy Missing Apex Controller (CRITICAL)
**Priority**: P0 - BLOCKING
**Estimated Time**: 5 minutes

```bash
cd /home/john/Projects/Salesforce/deployment-execution/06-producer-portal
sf project deploy start \
  --source-dir code/main/default/classes/ProducerPomAcknowledgeController* \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerPomAcknowledgeControllerTest
```

**Why Critical**: This class contains the `getNextActions()` method that determines if signature popup should show. Without it, the LWC component `producerNextActions` will fail.

**Expected Result**: Deploy succeeds, test passes with 100% coverage

---

### Phase 2: Deploy Formula Field Fix
**Priority**: P0 - BLOCKING
**Estimated Time**: 3 minutes

```bash
sf project deploy start \
  --source-dir code/main/default/objects \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerSharingHelperTest \
  --tests UserSharingBackfillHelperTest
```

**Why Critical**: Formula field needs to use `$Profile.Name` instead of `$User.Profile_Name__c` for reliable evaluation.

**Expected Result**: Formula field updated with correct profile check

---

### Phase 3: Activate Sharing Triggers (MANUAL - UI ONLY)
**Priority**: P0 - BLOCKING
**Estimated Time**: 10 minutes
**Method**: MANUAL UI activation (cannot be done via metadata in production)

**Steps**:
1. Login to NewOrg: https://recyclinglives-services.my.salesforce.com
2. Setup → Apex Triggers
3. For EACH trigger below, click Edit → Change Status to **Active** → Save:
   - `ProducerContractSharingTrigger`
   - `ProducerObligationSharingTrigger`
   - `ProducerPlacedOnMarketSharingTrigger`
   - `UserSharingBackfill`

**Why Critical**: Without active triggers, sharing records are NOT created. Login license users will have NO access to producer records.

**Verification**:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name LIKE '%Sharing%' ORDER BY Name" --target-org NewOrg
```
Expected: All 4 triggers show Status = Active

---

### Phase 4: Verify SignatureLwcHelper Has Fix
**Priority**: P1 - HIGH
**Estimated Time**: 2 minutes

Check if NewOrg version has the `Is_Record_Signed__c` fix:

```bash
sf project retrieve start \
  --metadata ApexClass:SignatureLwcHelper \
  --target-org NewOrg \
  --output-dir temp-verify

grep "Is_Record_Signed__c" temp-verify/classes/SignatureLwcHelper.cls
```

**If grep finds the code**: ✅ Fix already deployed (Oct 27)
**If grep finds nothing**: ❌ Need to redeploy SignatureLwcHelper

---

### Phase 5: Verify Flows Are Active
**Priority**: P1 - HIGH
**Estimated Time**: 5 minutes
**Method**: MANUAL UI check

1. Setup → Flows
2. Check each flow is **Active** (not Draft):
   - `Producer_POM_Update_Status`
   - `Producer_POM_Acknowledge_Feedback`
   - `Producer_Placed_On_Market_Signature_Best_Action`
   - `Producer_Placed_On_Market_Question_Best_Action`
   - `Producer_Placed_On_Market_Resubmission_Best_Action`
   - `Allowed_Resubmission_of_POMD`
   - `validationQuestionsFlow`

**If any are Draft**: Activate them manually in UI

---

## Risk Assessment

### High Risk Items (Deployment Blockers)

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| **Missing ProducerPomAcknowledgeController** | Portal completely broken | Deploy before any testing | ❌ Not deployed |
| **Inactive sharing triggers** | Users can't see records | Activate via UI | ❌ Not activated |
| **Wrong formula field** | All users see signature popup | Deploy corrected formula | ❌ Not deployed |

### Medium Risk Items

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| Different test class lengths | Possible test failures | Review code differences | ⚠️ Need to check |
| Flows might be Draft | Functionality not available | Activate in UI | ⚠️ Need to verify |

### Low Risk Items

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| Fewer licenses in NewOrg | Capacity constraints | Monitor usage | ⚠️ Acceptable for now |

---

## Testing Plan (After Deployment)

### Test Case 1: Producer Standard User (Non-Director)
**Profile**: Producer Standard User Login
**Expected Behavior**: NO signature popup

1. Login as producer
2. Navigate to Producer_Placed_on_Market__c record
3. Enter market data
4. Complete acknowledgement
5. **Verify**: Status changes, NO signature popup appears ✅

### Test Case 2: Producer Director User
**Profile**: Producer Director User Login
**Expected Behavior**: Signature popup DOES appear

1. Login as director
2. Navigate to Producer_Placed_on_Market__c record with Status = "Pending Director Review"
3. **Verify**: Signature popup appears ✅
4. Draw signature, click "Capture Signature"
5. **Verify**: Signature saves, status → "Signed", NO infinite loop ✅

### Test Case 3: Record Sharing Verification
**Profile**: Producer Standard User Login
**Expected Behavior**: User can see their own account's records

1. Login as producer
2. Navigate to Producer Placed on Market tab
3. **Verify**: User sees records related to their account ✅
4. **Verify**: User does NOT see other accounts' records ✅

---

## Post-Deployment Verification Checklist

- [ ] ProducerPomAcknowledgeController deployed successfully
- [ ] ProducerPomAcknowledgeControllerTest passed with 100% coverage
- [ ] Show_Signature_Popup__c formula updated with $Profile.Name
- [ ] All 4 sharing triggers are Active in NewOrg
- [ ] Producer Standard User does NOT see signature popup
- [ ] Producer Director User DOES see signature popup
- [ ] Signature workflow completes without infinite loop
- [ ] Login license users can see producer records
- [ ] Sharing rules are creating records correctly

---

## Rollback Plan

If deployment causes issues:

1. **Deactivate triggers** (if causing performance issues)
2. **Retrieve old ProducerPomAcknowledgeController** from backup
3. **Revert formula field** to previous version

**Backup Location**: `/home/john/Projects/Salesforce/deployment-execution/06-producer-portal/temp-retrieve/`

---

## Deployment Order Summary

1. ✅ Verify foundation (profiles, licenses) - COMPLETE
2. ❌ Deploy ProducerPomAcknowledgeController (Phase 1) - PENDING
3. ❌ Deploy Show_Signature_Popup__c fix (Phase 2) - PENDING
4. ❌ Activate 4 sharing triggers via UI (Phase 3) - PENDING
5. ⚠️ Verify SignatureLwcHelper has fix (Phase 4) - PENDING
6. ⚠️ Verify flows are Active (Phase 5) - PENDING
7. ✅ Test with producer and director users

**Estimated Total Time**: 25-30 minutes

---

---

## Quick Start Commands for New Session

### Prerequisites
```bash
cd /home/john/Projects/Salesforce/deployment-execution/06-producer-portal
sf org list
# Verify you can see both OldOrg and NewOrg
```

### Phase 1: Deploy ProducerPomAcknowledgeController
```bash
sf project deploy start \
  --source-dir code/main/default/classes/ProducerPomAcknowledgeController.cls code/main/default/classes/ProducerPomAcknowledgeController.cls-meta.xml code/main/default/classes/ProducerPomAcknowledgeControllerTest.cls code/main/default/classes/ProducerPomAcknowledgeControllerTest.cls-meta.xml \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerPomAcknowledgeControllerTest
```

Expected output: `Status: Succeeded`, `Test Results: Passing: 1`

### Phase 2: Deploy Formula Field Fix
```bash
sf project deploy start \
  --source-dir code/main/default/objects \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerSharingHelperTest \
  --tests UserSharingBackfillHelperTest
```

Expected output: `Status: Succeeded`

### Phase 3: Activate Sharing Triggers (MANUAL)
**IMPORTANT**: This MUST be done via UI - cannot be done via CLI in production

1. Open: https://recyclinglives-services.my.salesforce.com
2. Setup → Search "Apex Triggers" → Apex Triggers
3. For EACH trigger, click trigger name → Edit → Change Status to "Active" → Save:
   - ProducerContractSharingTrigger
   - ProducerObligationSharingTrigger
   - ProducerPlacedOnMarketSharingTrigger
   - UserSharingBackfill

4. Verify:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name IN ('ProducerContractSharingTrigger', 'ProducerObligationSharingTrigger', 'ProducerPlacedOnMarketSharingTrigger', 'UserSharingBackfill') ORDER BY Name" --target-org NewOrg
```

Expected: All 4 triggers show `Status: Active`

### Phase 4: Verify SignatureLwcHelper
```bash
sf project retrieve start \
  --metadata ApexClass:SignatureLwcHelper \
  --target-org NewOrg \
  --output-dir temp-verify-neworg

grep -n "Is_Record_Signed__c" temp-verify-neworg/classes/SignatureLwcHelper.cls
```

Expected: Should find line setting `Is_Record_Signed__c = true`
If NOT found: Deploy SignatureLwcHelper from code/classes/

### Phase 5: Verify Flows Are Active (MANUAL)
1. Setup → Flows
2. Check EACH flow shows Status = "Active":
   - Producer_POM_Update_Status
   - Producer_POM_Acknowledge_Feedback
   - Producer_Placed_On_Market_Signature_Best_Action
   - Producer_Placed_On_Market_Question_Best_Action
   - Producer_Placed_On_Market_Resubmission_Best_Action
   - Allowed_Resubmission_of_POMD
   - validationQuestionsFlow

If any show "Draft": Click flow name → Activate

### Phase 6: Update Documentation
```bash
# Record Deploy IDs in DEPLOYMENT_HISTORY.md under "NewOrg Deployment" section
# Update deployment-execution/README.md if needed
# Commit changes
```

### Phase 7: Testing
See "Testing Plan (After Deployment)" section above for detailed test cases.

---

## Troubleshooting

### Issue: ProducerPomAcknowledgeController deployment fails
**Solution**: Deploy test class separately first:
```bash
sf project deploy start \
  --source-dir code/main/default/classes/ProducerPomAcknowledgeControllerTest* \
  --target-org NewOrg \
  --test-level NoTestRun
```

### Issue: Sharing triggers won't activate
**Cause**: Triggers can only be activated in UI for production orgs
**Solution**: Follow Phase 3 manual steps carefully

### Issue: Test failures during deployment
**Solution**: Check test error messages, may need to review test class logic

### Issue: Formula field deployment takes too long
**Cause**: Deploying entire objects directory (262+ components)
**Solution**: Deploy only the specific field (not recommended in production - use full objects dir)

---

**Ready to Begin Deployment**
