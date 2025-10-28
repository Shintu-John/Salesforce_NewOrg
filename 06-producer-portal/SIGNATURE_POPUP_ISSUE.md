# Signature Popup Appearing for Non-Director Users - Root Cause Analysis

**Date**: October 27, 2025
**Issue**: Signature popup appears for normal producers when it should only appear for Directors
**Status**: ROOT CAUSE IDENTIFIED

---

## Issue Description

When a normal producer (not a director):
1. Enters data in Producer_Placed_on_Market__c record
2. Answers acknowledgement questions
3. Clicks "Complete"

**Expected**: Record status changes to "Completed" or similar, NO signature popup
**Actual**: Page refreshes and signature screen popup appears (should only appear for Directors)

---

## Root Cause Analysis

### Current Logic Flow

1. **Status Update Flow** (`Producer_POM_Update_Status.flow`)
   - When user completes acknowledgement + answers all questions
   - Status automatically changes to "Pending Director Review"
   - **This happens for ALL users** (no profile check)

2. **Signature Popup Field** (`Show_Signature_Popup__c` formula field)
   ```apex
   AND(
     Show_Acknowledgement_PopUp__c = FALSE,
     Show_Popup_For_Validation_Question__c = FALSE,
     ISPICKVAL(Status__c, "Pending Director Review"),
     OR(
       $User.Profile_Name__c = "Producer Director User",
       $User.Profile_Name__c = "Producer Director User Login",
       $User.Profile_Name__c = "RLCC - RLCS Producer Director"
     )
   )
   ```

3. **The Formula SHOULD Prevent** non-directors from seeing the popup by checking `$User.Profile_Name__c`

---

## Possible Root Causes

### Cause 1: Profile_Name__c Field Not Populated (MOST LIKELY)

**Check**: Is the `Profile_Name__c` custom field on the User object populated for the producer user?

```bash
# Query the user who experienced the issue
sf data query --query "SELECT Name, Profile.Name, Profile_Name__c FROM User WHERE Username = '<producer_username>'" --target-org OldOrg
```

**Expected**:
- Directors: Profile_Name__c = "Producer Director User" or "Producer Director User Login"
- Normal Producers: Profile_Name__c = "Producer Standard User" or "Producer Standard User Login"

**If Profile_Name__c is NULL or incorrect**: This is the bug!

**Solution**:
- Update the formula to use `$Profile.Name` instead of `$User.Profile_Name__c`
- OR ensure `Profile_Name__c` is populated via workflow/flow/trigger

---

### Cause 2: Wrong Profile Assigned to Producer User

**Check**: What profile does the normal producer have?

```bash
sf data query --query "SELECT Name, Profile.Name, UserType FROM User WHERE Name = '<producer_name>'" --target-org OldOrg
```

**Expected**: Normal producers should have:
- "Producer Standard User" (Customer Community Plus)
- "Producer Standard User Login" (Customer Community Plus Login)

**If they have a Director profile**: User is incorrectly assigned

---

### Cause 3: Record Page Action Triggering for All Users

The signature flow might be configured as a Record Page Action that triggers for all users viewing the record, not just Directors.

**Check**: Review the Producer_Placed_on_Market__c Lightning Record Page:
- Check if there's an Action that launches the signature flow
- Check if the Action has visibility filters

---

## Recommended Solution

### Option A: Fix the Formula Field (RECOMMENDED)

**Change** `Show_Signature_Popup__c` formula from:
```apex
$User.Profile_Name__c = "Producer Director User"
```

**To**:
```apex
$Profile.Name = "Producer Director User"
```

**Full Fixed Formula**:
```apex
AND(
  Show_Acknowledgement_PopUp__c = FALSE,
  Show_Popup_For_Validation_Question__c = FALSE,
  ISPICKVAL(Status__c, "Pending Director Review"),
  OR(
    $Profile.Name = "Producer Director User",
    $Profile.Name = "Producer Director User Login",
    $Profile.Name = "RLCC - RLCS Producer Director"
  )
)
```

**Why**: Using standard `$Profile.Name` is more reliable than a custom field that might not be populated.

---

### Option B: Ensure Profile_Name__c is Populated

If you want to keep using `Profile_Name__c`:

1. Create a workflow rule or flow that runs on User insert/update
2. Set `Profile_Name__c = Profile.Name`
3. Run a data update to backfill existing users

---

### Option C: Change Business Logic (if needed)

If the requirement is that producers should NEVER trigger the "Pending Director Review" status:

**Update** `Producer_POM_Update_Status.flow` to check user profile before setting status:
- Add decision element to check if current user is a Director
- If Director completes → Set status to "Pending Director Review"
- If Producer completes → Set status to "Completed" or "Ready for Review"

---

## Testing Plan

After implementing the fix:

### Test Case 1: Normal Producer User
1. Login as Producer Standard User (Login license)
2. Create/edit Producer_Placed_on_Market__c record
3. Complete data entry
4. Answer acknowledgement questions
5. Click "Complete"
6. **Expected**: NO signature popup appears
7. **Expected**: Status changes to appropriate value (NOT "Pending Director Review" if Option C is chosen)

### Test Case 2: Director User
1. Login as Producer Director User (Login license)
2. Open Producer_Placed_on_Market__c record with status = "Pending Director Review"
3. **Expected**: Signature popup DOES appear
4. Draw signature and click "Capture Signature"
5. **Expected**: Signature saves, status changes to "Signed", NO infinite loop

### Test Case 3: Verify Formula Logic
```bash
# Query records where signature popup should show
sf data query --query "SELECT Id, Status__c, Show_Signature_Popup__c, OwnerId FROM Producer_Placed_on_Market__c WHERE Status__c = 'Pending Director Review'" --target-org OldOrg

# For each record, verify Show_Signature_Popup__c is TRUE only for Director users viewing the record
```

---

## Immediate Actions Required

1. **Investigate**: Check the producer user's Profile_Name__c value
   ```bash
   sf data query --query "SELECT Name, Profile.Name, Profile_Name__c FROM User WHERE <identify_the_user>" --target-org OldOrg
   ```

2. **Choose Solution**: Decide between Option A (change formula) or Option B (populate field)

3. **Implement Fix**: Update the formula field or create the population mechanism

4. **Deploy to Both Orgs**: Deploy fix to OldOrg AND NewOrg

5. **Test**: Test with both producer and director users

---

## Files to Update

If choosing Option A (recommended):
- `/home/john/Projects/Salesforce/deployment-execution/06-producer-portal/code/main/default/objects/Producer_Placed_on_Market__c/fields/Show_Signature_Popup__c.field-meta.xml`

---

**Next Steps**: Please confirm which producer user experienced this issue so I can check their Profile_Name__c value and implement the appropriate fix.
