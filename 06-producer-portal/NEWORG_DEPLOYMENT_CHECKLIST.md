# NewOrg Producer Portal Deployment Checklist

**Date**: October 28, 2025 (Updated after OldOrg fixes)
**Status**: READY FOR DEPLOYMENT - Complete gap analysis done
**Target**: NewOrg (shintu.john@recyclinglives-services.com)

---

## 🚨 CRITICAL: Use This Document in New Session

This checklist provides step-by-step commands for deploying producer portal fixes to NewOrg.
All gaps have been identified and documented with exact deployment commands.

---

## Executive Summary

### ✅ OldOrg Status (Production)
- All components deployed and tested successfully
- Signature popup profile check: ✅ FIXED (Oct 28)
- Infinite loop issue: ✅ FIXED (Oct 27)
- All sharing triggers: ✅ ACTIVE

### ❌ NewOrg Status (Production) - NEEDS DEPLOYMENT
- **ProducerPomAcknowledgeController**: ❌ MISSING (signature popup logic)
- **Show_Signature_Popup__c formula**: ❌ Wrong field (uses Profile_Name__c)
- **All 4 Sharing Triggers**: ❌ INACTIVE (portal non-functional)
- **SignatureLwcHelper**: ✅ Has Is_Record_Signed__c fix (Oct 27)

### Business Impact
Without this deployment:
- ❌ Producer portal completely non-functional in NewOrg
- ❌ Login license users cannot see any producer records
- ❌ Signature popup appears for ALL users (not just Directors)
- 💰 £1.5M+ compliance fees at risk

---

## Gap Analysis: OldOrg vs NewOrg

### 1. Apex Classes

| Class Name | OldOrg | NewOrg | Status |
|------------|--------|--------|--------|
| ProducerSharingHelper | ✅ Oct 21 (6,343 chars) | ✅ Oct 24 (6,343 chars) | ✅ MATCH |
| ProducerSharingHelperTest | ✅ Oct 21 (11,647 chars) | ⚠️ Oct 24 (13,428 chars) | ⚠️ Different (OK) |
| UserSharingBackfillHelper | ✅ Oct 21 (2,576 chars) | ✅ Oct 24 (2,576 chars) | ✅ MATCH |
| UserSharingBackfillHelperTest | ✅ Oct 21 (6,919 chars) | ⚠️ Oct 24 (9,447 chars) | ⚠️ Different (OK) |
| SignatureLwcHelper | ✅ Oct 27 (944 chars) | ✅ Oct 27 (944 chars) | ✅ MATCH |
| SignatureLwcHelperTest | ✅ Feb 28 (324 chars) | ✅ Oct 27 (324 chars) | ✅ MATCH |
| **ProducerPomAcknowledgeController** | ✅ Oct 28 (3,304 chars) | ❌ **MISSING** | ❌ **MUST DEPLOY** |
| **ProducerPomAcknowledgeControllerTest** | ✅ Oct 28 (2,045 chars) | ❌ **MISSING** | ❌ **MUST DEPLOY** |

### 2. Triggers

| Trigger Name | OldOrg | NewOrg | Action |
|--------------|--------|--------|--------|
| **ProducerContractSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **ProducerObligationSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **ProducerPlacedOnMarketSharingTrigger** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |
| **UserSharingBackfill** | ✅ Active | ❌ **Inactive** | **ACTIVATE** |

### 3. Custom Fields

**Show_Signature_Popup__c Formula Field**

| Aspect | OldOrg (Fixed Oct 28) | NewOrg (Needs Fix) |
|--------|----------------------|---------------------|
| Uses reliable field | ✅ `$Profile.Name` | ❌ `$User.Profile_Name__c` |
| Works correctly | ✅ Yes | ❌ No - All users see popup |

---

## Deployment Plan - Execute in Order

### Prerequisites
```bash
cd /home/john/Projects/Salesforce/deployment-execution/06-producer-portal
sf org list
# Verify you can see: OldOrg and NewOrg
```

---

### Phase 1: Deploy ProducerPomAcknowledgeController (CRITICAL)
**Priority**: P0 BLOCKING - Portal broken without this
**Time**: 5 minutes

This class controls the signature popup visibility based on user profile.

```bash
cd /home/john/Projects/Salesforce/deployment-execution/06-producer-portal

sf project deploy start \
  --source-dir code/main/default/classes/ProducerPomAcknowledgeController.cls \
             code/main/default/classes/ProducerPomAcknowledgeController.cls-meta.xml \
             code/main/default/classes/ProducerPomAcknowledgeControllerTest.cls \
             code/main/default/classes/ProducerPomAcknowledgeControllerTest.cls-meta.xml \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerPomAcknowledgeControllerTest
```

**Expected Output**:
```
Status: Succeeded
Test Results: Passing: 1/1
Deploy ID: 0AfSq00000XXXXXXX
```

**Record Deploy ID**: _________________

---

### Phase 2: Deploy Show_Signature_Popup__c Formula Fix
**Priority**: P0 BLOCKING - Wrong users see popup
**Time**: 3-5 minutes (deploys 262 components)

This updates the formula to use `$Profile.Name` instead of `$User.Profile_Name__c`.

```bash
sf project deploy start \
  --source-dir code/main/default/objects \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ProducerSharingHelperTest \
  --tests UserSharingBackfillHelperTest
```

**Expected Output**:
```
Status: Succeeded
Components: 262/262 (100%)
```

**Record Deploy ID**: _________________

**⚠️ Note**: This deploys the entire objects directory (262 components). It's the safest approach for production.

---

### Phase 3: Activate Sharing Triggers (MANUAL - UI ONLY)
**Priority**: P0 BLOCKING - Users can't see records
**Time**: 10 minutes
**Method**: MUST be done via UI (cannot activate triggers via CLI in production)

#### Steps:

1. **Login to NewOrg**:
   - URL: https://recyclinglives-services.my.salesforce.com
   - Username: shintu.john@recyclinglives-services.com

2. **Navigate to Triggers**:
   - Setup (gear icon) → Setup Home
   - Quick Find → Search "Apex Triggers"
   - Click "Apex Triggers"

3. **Activate Each Trigger** (repeat for all 4):
   - Click trigger name: **ProducerContractSharingTrigger**
   - Click "Edit" button
   - Change "Status" dropdown from "Inactive" to "Active"
   - Click "Save"

   Repeat for:
   - ✅ ProducerContractSharingTrigger
   - ✅ ProducerObligationSharingTrigger
   - ✅ ProducerPlacedOnMarketSharingTrigger
   - ✅ UserSharingBackfill

4. **Verify All Active**:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name IN ('ProducerContractSharingTrigger', 'ProducerObligationSharingTrigger', 'ProducerPlacedOnMarketSharingTrigger', 'UserSharingBackfill') ORDER BY Name" --target-org NewOrg
```

**Expected Output**: All 4 triggers show `Status: Active`

---

### Phase 4: Verify Flows Are Active
**Priority**: P1 HIGH - Flows might be inactive
**Time**: 5 minutes
**Method**: UI check

1. **Navigate to Flows**:
   - Setup → Quick Find → "Flows"

2. **Check Each Flow** shows Status = "Active":
   - Producer_POM_Update_Status
   - Producer_POM_Acknowledge_Feedback
   - Producer_Placed_On_Market_Signature_Best_Action
   - Producer_Placed_On_Market_Question_Best_Action
   - Producer_Placed_On_Market_Resubmission_Best_Action
   - Allowed_Resubmission_of_POMD
   - validationQuestionsFlow

3. **If Any Are "Draft"**:
   - Click flow name
   - Click "Activate" button
   - Confirm activation

---

### Phase 5: Verify SignatureLwcHelper Has Fix
**Priority**: P1 HIGH - Verify Oct 27 fix is present
**Time**: 2 minutes

```bash
sf project retrieve start \
  --metadata ApexClass:SignatureLwcHelper \
  --target-org NewOrg \
  --output-dir temp-verify-neworg

grep -n "Is_Record_Signed__c" temp-verify-neworg/classes/SignatureLwcHelper.cls
```

**Expected Output**: Should find lines 21-23:
```
21:    // Mark record as signed to trigger status update flow (for Producer_Placed_on_Market__c only)
22:    if(sObjectType == Schema.Producer_Placed_on_Market__c.SObjectType){
23:        record.put('Is_Record_Signed__c', true);
```

**If NOT found**: SignatureLwcHelper needs redeployment (shouldn't happen - was deployed Oct 27)

---

## Testing Plan

### Test Case 1: Normal Producer (Non-Director)
**Profile**: Producer Standard User Login
**Expected**: NO signature popup

```bash
# Steps:
# 1. Login as producer user in NewOrg portal
# 2. Navigate to Producer_Placed_on_Market__c record
# 3. Enter market data
# 4. Complete acknowledgement
# 5. Verify: Status changes, NO signature popup appears
```

**Result**: ✅ Pass / ❌ Fail

---

### Test Case 2: Director User
**Profile**: Producer Director User Login
**Expected**: Signature popup APPEARS

```bash
# Steps:
# 1. Login as director user in NewOrg portal
# 2. Navigate to record with Status = "Pending Director Review"
# 3. Verify: Signature popup appears
# 4. Draw signature, click "Capture Signature"
# 5. Verify: Signature saves, status → "Signed", NO infinite loop
```

**Result**: ✅ Pass / ❌ Fail

---

### Test Case 3: Record Sharing
**Profile**: Producer Standard User Login
**Expected**: User sees their own account's records

```bash
# Steps:
# 1. Login as producer user
# 2. Navigate to Producer Placed on Market tab
# 3. Verify: User sees records for their account
# 4. Verify: User does NOT see other accounts' records
```

**Result**: ✅ Pass / ❌ Fail

---

## Post-Deployment Documentation

### Update DEPLOYMENT_HISTORY.md

Add NewOrg deployment section:

```markdown
### NewOrg Deployment (Date: ______)

**Phase 1**: ProducerPomAcknowledgeController
- Deploy ID: ________________
- Status: Succeeded
- Test Coverage: 100%

**Phase 2**: Show_Signature_Popup__c formula fix
- Deploy ID: ________________
- Status: Succeeded
- Components: 262

**Phase 3**: Sharing Triggers Activation
- Method: Manual UI activation
- All 4 triggers: Active

**Phase 4**: Flow Verification
- All 7 flows: Active

**Testing Results**:
- Test Case 1 (Producer): ✅ Pass
- Test Case 2 (Director): ✅ Pass
- Test Case 3 (Sharing): ✅ Pass
```

### Commit Changes

```bash
cd /home/john/Projects/Salesforce/deployment-execution

git add 06-producer-portal/DEPLOYMENT_HISTORY.md
git add 06-producer-portal/NEWORG_DEPLOYMENT_CHECKLIST.md
git add README.md

# Verify no AI attribution
git diff --cached | grep -i "claude\|ai assistant\|co-authored"
# Should output: (nothing)

git commit -m "Producer Portal: NewOrg deployment complete

Deployed Components:
- ProducerPomAcknowledgeController (signature popup logic)
- Show_Signature_Popup__c formula fix ($Profile.Name)
- Activated 4 sharing triggers manually

Deployment IDs:
- Phase 1: [Deploy ID]
- Phase 2: [Deploy ID]

Testing: All test cases passed
Status: NewOrg producer portal fully functional

Author: John Shintu
Date: [Date]"

git push origin main
```

---

## Troubleshooting

### Issue: ProducerPomAcknowledgeController Test Fails
**Error**: Test class not found or coverage <75%
**Solution**:
```bash
# Deploy test class first
sf project deploy start \
  --source-dir code/main/default/classes/ProducerPomAcknowledgeControllerTest* \
  --target-org NewOrg \
  --test-level RunLocalTests
```

### Issue: Triggers Won't Activate
**Error**: "Cannot activate trigger"
**Cause**: Triggers can only be activated in UI for production orgs
**Solution**: Follow Phase 3 manual steps carefully, must use UI

### Issue: Formula Field Deployment Times Out
**Error**: Deployment exceeds timeout
**Cause**: 262 components take time
**Solution**: Increase timeout or deploy in smaller batches (not recommended for production)

### Issue: Signature Popup Still Shows for Non-Directors
**Check**:
1. Verify ProducerPomAcknowledgeController deployed: `sf data query --query "SELECT Name FROM ApexClass WHERE Name = 'ProducerPomAcknowledgeController'" --target-org NewOrg`
2. Verify formula field updated: Check Show_Signature_Popup__c formula in Setup
3. Clear browser cache and re-login

---

## Quick Reference

### Key Files
- Apex Controller: `code/main/default/classes/ProducerPomAcknowledgeController.cls`
- Formula Field: `code/main/default/objects/Producer_Placed_on_Market__c/fields/Show_Signature_Popup__c.field-meta.xml`
- Deployment History: `DEPLOYMENT_HISTORY.md`
- Gap Analysis: `NEWORG_DEPLOYMENT_PLAN.md`

### Key Components
- **ProducerPomAcknowledgeController**: Controls signature popup via `getNextActions()` method
- **Show_Signature_Popup__c**: Formula field for UI visibility
- **4 Sharing Triggers**: Enable Login users to see records
- **SignatureLwcHelper**: Saves signature and sets `Is_Record_Signed__c`

### Deploy IDs (OldOrg Reference)
- Formula Field: 0AfSj000000zMq1KAE
- Apex Controller: 0AfSj000000zMrdKAE
- SignatureLwcHelper: 0AfSj000000zMDJKA2

---

## Completion Checklist

- [ ] Phase 1: ProducerPomAcknowledgeController deployed
- [ ] Phase 2: Formula field fixed
- [ ] Phase 3: All 4 triggers activated (verified via query)
- [ ] Phase 4: All 7 flows active (verified in UI)
- [ ] Phase 5: SignatureLwcHelper verified
- [ ] Test Case 1: Producer user tested (NO popup)
- [ ] Test Case 2: Director user tested (popup works)
- [ ] Test Case 3: Sharing verified (users see records)
- [ ] Documentation updated (DEPLOYMENT_HISTORY.md)
- [ ] Changes committed and pushed to repository

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

**Ready for Deployment to NewOrg**

---

## Additional Resources

- OldOrg Fixes Documentation: `SIGNATURE_POPUP_FIX_SUMMARY.md`
- Root Cause Analysis: `SIGNATURE_POPUP_ISSUE.md`
- Complete Deployment Plan: `NEWORG_DEPLOYMENT_PLAN.md`
- Code Comparison: `code-comparison/COMPARISON_REPORT.md`
