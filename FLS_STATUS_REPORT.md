# Field-Level Security (FLS) Status Report

**Date:** October 23, 2025
**Analysis Method:** Metadata retrieval via sf CLI
**Profile Analyzed:** Admin
**Source:** Retrieved from NewOrg

---

## Summary

**Finding:** FLS is partially set, but some fields are READ-ONLY when they should be EDITABLE.

### Status Overview
- ✅ **Transport fields**: FLS set correctly (readable + editable)
- ⚠️ **Secondary Transport fields**: FLS set but only READABLE (not editable)
- ✅ **All fields exist**: No missing fields

---

## Detailed FLS Analysis

### Transport Fields (from transport-charges scenario)

| Field API Name | Readable | Editable | Status | Notes |
|----------------|----------|----------|--------|-------|
| `Transport_Per_Tonne__c` | ✅ true | ✅ true | ✅ CORRECT | Used to flag per-tonne calculation |
| `Transport_Per_Unit__c` | ✅ true | ✅ true | ✅ CORRECT | Used to flag per-unit calculation |
| `Transport__c` | ✅ true | ✅ true | ✅ CORRECT | Transport rate field |

**Note:** There is NO `Transport_Per_Load__c` field. "Per Load" is the default when both `Transport_Per_Tonne__c` and `Transport_Per_Unit__c` are false. The quantity defaults to 1.

---

### Secondary Transport Fields (from secondary-transport scenario)

| Field API Name | Readable | Editable | Status | Required Action |
|----------------|----------|----------|--------|-----------------|
| `Secondary_Transport_Charge__c` | ✅ true | ✅ true | ✅ CORRECT | Enable secondary transport |
| `Secondary_Transport_P_T__c` | ✅ true | ✅ true | ✅ CORRECT | Secondary transport rate |
| `Secondary_Transport_Per_Tonne__c` | ✅ true | ❌ **false** | ⚠️ INCOMPLETE | **SET TO EDITABLE** |
| `Secondary_Transport_Per_Unit__c` | ✅ true | ❌ **false** | ⚠️ INCOMPLETE | **SET TO EDITABLE** |
| `Secondary_Haulier__c` | (not checked) | (not checked) | ? | Need to verify |

---

## Root Cause Analysis

### Why Integration Test Failed

The integration test script failed with:
```
System.SObjectException: Invalid field Transport_Per_Load__c for OrderItem
```

**Analysis:**
1. **Initially thought**: FLS not set for transport fields
2. **After metadata retrieval**: FLS IS set for transport fields
3. **Actual cause**: Test script referenced non-existent field `Transport_Per_Load__c`

The test script needs to be corrected to NOT use `Transport_Per_Load__c`. Instead:
- Set `Transport_Per_Tonne__c = false`
- Set `Transport_Per_Unit__c = false`
- This defaults to "Per Load" behavior (quantity = 1)

### Secondary Transport FLS Issue

The secondary transport fields were set to READABLE but not EDITABLE in the Admin profile:
```xml
<fieldPermissions>
    <editable>false</editable>
    <field>OrderItem.Secondary_Transport_Per_Tonne__c</field>
    <readable>true</readable>
</fieldPermissions>
<fieldPermissions>
    <editable>false</editable>
    <field>OrderItem.Secondary_Transport_Per_Unit__c</field>
    <readable>true</readable>
</fieldPermissions>
```

**Required Fix:**
- Navigate to Setup → Object Manager → Order Products (OrderItem) → Fields
- For each field, click "Set Field-Level Security"
- For Admin profile, check BOTH "Visible" and "Read-Only" checkboxes
- Uncheck "Read-Only" to make fields editable

---

## Remediation Steps

### Step 1: Fix Secondary Transport FLS ⚠️ REQUIRED

**Location:** Setup → Object Manager → Order Products (OrderItem) → Fields → Set Field-Level Security

**Fields to Update:**
1. `Secondary_Transport_Per_Tonne__c`
   - Current: Visible ✅, Read-Only ✅ (editable=false)
   - Required: Visible ✅, Read-Only **UNCHECKED** (editable=true)

2. `Secondary_Transport_Per_Unit__c`
   - Current: Visible ✅, Read-Only ✅ (editable=false)
   - Required: Visible ✅, Read-Only **UNCHECKED** (editable=true)

**Time Required:** 5 minutes

---

### Step 2: Verify Secondary_Haulier__c FLS

**Action:** Check if `Secondary_Haulier__c` (Lookup to Account) has correct FLS

**Steps:**
1. Setup → Object Manager → Order Products → Fields → Secondary_Haulier__c
2. Click "Set Field-Level Security"
3. Verify Admin profile has:
   - Visible: ✅ Checked
   - Read-Only: **UNCHECKED** (to make editable)

---

### Step 3: Re-Run Integration Test

After fixing FLS, the integration test should be updated and re-run:

**Required Changes to Test Script:**
1. Remove all references to `Transport_Per_Load__c` (field doesn't exist)
2. For "Per Load" test, use:
   ```apex
   // Per Load scenario - do NOT set Per Tonne or Per Unit flags
   // (defaults to Per Load with quantity = 1)
   oi1.put('Transport__c', 75.00);  // £75 per load
   // Do NOT set Transport_Per_Tonne__c or Transport_Per_Unit__c
   ```

3. Use dynamic field assignment with `.put()` for all custom fields:
   ```apex
   oi.put('Transport_Per_Tonne__c', true);
   oi.put('Secondary_Transport_Per_Tonne__c', true);
   ```

---

## Impact on Previous Deployments

### transport-charges Deployment

**Status:** ✅ FLS was correctly set for transport fields
**No Action Required**

The transport-charges deployment documentation should be updated to note that FLS was set correctly:
- `Transport_Per_Tonne__c`: editable ✅
- `Transport_Per_Unit__c`: editable ✅
- `Transport__c`: editable ✅

---

### secondary-transport Deployment

**Status:** ⚠️ FLS was PARTIALLY set (readable but not editable)
**Action Required:** Set editable=true for 2 fields

The secondary-transport deployment documentation should be updated:

**DEPLOYMENT_HISTORY.md Update Required:**
```markdown
### Issue 8: Secondary Transport Fields Not Editable

**Problem:** Fields were set to readable but not editable in Admin profile

**Discovery:** October 23, 2025 (during integration testing)

**Fields Affected:**
- Secondary_Transport_Per_Tonne__c (readable only)
- Secondary_Transport_Per_Unit__c (readable only)

**Root Cause:** When setting FLS via UI, "Read-Only" checkbox was left checked

**Resolution:**
1. Navigate to Setup → Object Manager → OrderItem → Fields → Set Field-Level Security
2. For each field, uncheck "Read-Only" for Admin profile
3. Verify fields are now editable via Anonymous Apex test

**Status:** ✅ Resolved
```

---

## Lessons Learned

### 1. FLS Verification Process

**Current Process:**
- Set FLS via UI manually
- Assume it's correct
- Discover issues during functional testing

**Improved Process:**
- Set FLS via UI manually
- **Retrieve metadata to verify**: `sf project retrieve start --manifest package-fls-check.xml`
- **Parse Profile XML**: Check `<editable>true</editable>` for all custom fields
- **Test via Anonymous Apex**: Verify fields are accessible with `.put()` before functional tests

**Time Investment:** +10 minutes per deployment
**Risk Reduction:** Catches FLS issues before functional testing

---

### 2. Field Existence Assumptions

**Issue:** Test script assumed `Transport_Per_Load__c` field existed
**Reality:** "Per Load" is a default behavior, not a separate field

**Lesson:** Always verify field API names via:
- Metadata retrieval
- Developer Console → Schema Builder
- SOQL describe calls

---

### 3. Read-Only vs Editable

**Key Distinction:**
- `readable=true, editable=false`: Field visible but cannot be modified (read-only)
- `readable=true, editable=true`: Field visible and can be modified

**UI Mapping:**
- "Visible" checkbox → `readable=true`
- "Read-Only" checkbox UNCHECKED → `editable=true`
- "Read-Only" checkbox CHECKED → `editable=false`

**Common Mistake:** Setting "Visible" but leaving "Read-Only" checked

---

## Recommendations

### For Future Deployments

1. **Always verify FLS via metadata retrieval** after manual UI configuration
2. **Test field editability** with Anonymous Apex before functional tests:
   ```apex
   OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
   oi.put('New_Field__c', testValue);
   update oi;
   System.debug('✅ Field is editable');
   ```
3. **Document FLS settings** in DEPLOYMENT_HISTORY.md with exact steps taken
4. **Add FLS verification** to DEPLOYMENT_WORKFLOW.md as mandatory step

---

### For DEPLOYMENT_WORKFLOW.md

Add new Step 2.7a: **Verify FLS via Metadata Retrieval**

```markdown
#### Step 2.7a: Verify FLS via Metadata Retrieval

After setting FLS manually via UI, verify with metadata retrieval:

1. Create FLS check manifest:
   ```bash
   cat > manifest/fls-check.xml << 'EOF'
   <?xml version="1.0"?>
   <Package xmlns="http://soap.sforce.com/2006/04/metadata">
       <types>
           <members>ObjectName</members>
           <name>CustomObject</name>
       </types>
       <types>
           <members>Admin</members>
           <name>Profile</name>
       </types>
       <version>62.0</version>
   </Package>
   EOF
   ```

2. Retrieve metadata:
   ```bash
   sf project retrieve start --manifest manifest/fls-check.xml --target-org NewOrg --output-dir fls-verify
   ```

3. Verify FLS settings:
   ```bash
   grep -A 2 "FieldApiName" fls-verify/profiles/Admin.profile-meta.xml
   ```

4. Check for `<editable>true</editable>` - if false, field is read-only!

5. If any fields are read-only when they should be editable, return to UI and uncheck "Read-Only" checkbox.
```

---

**Generated:** October 23, 2025
**Next Action:** Fix Secondary Transport FLS (Step 1 above)
**Document Status:** Ready for review and remediation
