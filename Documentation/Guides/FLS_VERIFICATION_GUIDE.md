# Field-Level Security (FLS) Verification Guide

**Purpose:** Step-by-step guide to verify and set Field-Level Security for deployed custom fields

**Audience:** Deployment engineers, administrators

**Last Updated:** October 23, 2025

---

## Why FLS Verification is Critical

### The Problem
When you deploy custom fields via Salesforce CLI:
- ✅ Fields are created successfully
- ❌ **Field-Level Security (FLS) is NOT set**
- ❌ Fields are NOT visible or editable by users

### The Impact
- Users cannot see or edit the fields
- Anonymous Apex tests fail with `System.SObjectException: Invalid field`
- Functional testing fails
- Deployment appears successful but is actually incomplete

---

## Quick Reference

### Automated Verification (Recommended)
```bash
cd /home/john/Projects/Salesforce/deployment-execution
./Scripts/verify-fls.sh <scenario-name> <object-name>

# Example:
./Scripts/verify-fls.sh secondary-transport OrderItem
```

### Manual Verification (UI)
1. Setup → Object Manager → [Object] → Fields
2. Click field name → "Set Field-Level Security"
3. Verify:
   - ✅ "Visible" is checked
   - ✅ "Read-Only" is **UNCHECKED**

---

## Step-by-Step: Manual FLS Configuration

### Step 1: Navigate to Object Manager
1. Click **Setup** (gear icon, top right)
2. In Quick Find, search: **Object Manager**
3. Click **Object Manager**

### Step 2: Select Your Object
1. Find and click the object (e.g., **Order Products** for OrderItem)
2. Click **Fields & Relationships** in left sidebar

### Step 3: Locate Custom Field
1. Scroll to find your custom field (ends with `__c`)
2. Click the **field name** (not the edit link)

### Step 4: Set Field-Level Security
1. On the field detail page, click **Set Field-Level Security** button
2. You'll see a table of profiles

### Step 5: Configure FLS for Admin Profile
For **System Administrator** or **Admin** profile:
1. Check **Visible** checkbox
2. **UNCHECK** "Read-Only" checkbox
   - ⚠️ **Common mistake**: Leaving "Read-Only" checked makes field READ-ONLY!
   - ✅ **Correct**: Visible=checked, Read-Only=UNCHECKED

### Step 6: Save
1. Click **Save**
2. Repeat for each custom field

### Step 7: Verify (Automated)
```bash
./Scripts/verify-fls.sh <scenario> <object>
```

---

## Step-by-Step: Automated FLS Verification

### Method 1: Using verify-fls.sh Script

```bash
cd /home/john/Projects/Salesforce/deployment-execution

# Run verification
./Scripts/verify-fls.sh secondary-transport OrderItem
```

**Output Interpretation:**
```
| Field API Name                      | Readable | Editable | Status          |
|-------------------------------------|----------|----------|-----------------|
| Secondary_Transport_Per_Tonne__c    | ✅ Yes   | ✅ Yes   | ✅ CORRECT      |
| Secondary_Transport_Per_Unit__c     | ✅ Yes   | ⚠️  No    | ⚠️  READ-ONLY   |
| New_Field__c                        | ❌ No    | ❌ No    | ❌ NO FLS SET   |
```

**Status Meanings:**
- ✅ **CORRECT**: Field is readable and editable
- ⚠️ **READ-ONLY**: Field is visible but not editable (fix needed)
- ❌ **NO FLS SET**: Field has no FLS (critical - fix immediately)
- ❌ **NOT VISIBLE**: Field is not visible to users (critical)

### Method 2: Manual Metadata Retrieval

```bash
# Create manifest
cat > manifest/fls-check.xml << 'EOF'
<?xml version="1.0"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>OrderItem</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Admin</members>
        <name>Profile</name>
    </types>
    <version>62.0</version>
</Package>
EOF

# Retrieve metadata
sf project retrieve start \
  --manifest manifest/fls-check.xml \
  --target-org NewOrg \
  --output-dir fls-verify

# Check FLS
grep -B 1 -A 2 "Secondary_Transport" fls-verify/profiles/Admin.profile-meta.xml
```

**Expected Output (Correct FLS):**
```xml
<fieldPermissions>
    <editable>true</editable>
    <field>OrderItem.Secondary_Transport_Per_Tonne__c</field>
    <readable>true</readable>
</fieldPermissions>
```

**Problem Output (Read-Only):**
```xml
<fieldPermissions>
    <editable>false</editable>  <!-- ❌ Should be true! -->
    <field>OrderItem.Secondary_Transport_Per_Unit__c</field>
    <readable>true</readable>
</fieldPermissions>
```

---

## Common FLS Issues & Solutions

### Issue 1: Fields Show as "Read-Only"

**Symptom:**
```
| Secondary_Transport_Per_Tonne__c | ✅ Yes | ⚠️  No | ⚠️  READ-ONLY |
```

**Root Cause:** "Read-Only" checkbox was left checked in UI

**Solution:**
1. Setup → Object Manager → OrderItem → Fields → Secondary_Transport_Per_Tonne__c
2. Click "Set Field-Level Security"
3. For Admin profile: **UNCHECK** "Read-Only"
4. Save
5. Re-run verification

### Issue 2: Fields Show as "NO FLS SET"

**Symptom:**
```
| New_Field__c | ❌ No | ❌ No | ❌ NO FLS SET |
```

**Root Cause:** FLS was never set after deployment

**Solution:**
1. Setup → Object Manager → [Object] → Fields → New_Field__c
2. Click "Set Field-Level Security"
3. For Admin profile:
   - ✅ Check "Visible"
   - ✅ **UNCHECK** "Read-Only"
4. Save

### Issue 3: Anonymous Apex Test Fails

**Symptom:**
```
System.SObjectException: Invalid field Secondary_Transport_Per_Tonne__c for OrderItem
```

**Root Cause:** FLS not set (field not accessible)

**Solution:**
1. Run FLS verification: `./Scripts/verify-fls.sh scenario OrderItem`
2. Fix any fields with ❌ or ⚠️ status
3. Re-run Anonymous Apex test

---

## FLS Verification Checklist

### After Every Deployment

- [ ] Run automated FLS verification:
  ```bash
  ./Scripts/verify-fls.sh <scenario> <object>
  ```

- [ ] Check for any ❌ or ⚠️ status fields

- [ ] Fix FLS issues via UI:
  - Navigate to field → Set Field-Level Security
  - Visible=✅, Read-Only=❌ (unchecked)

- [ ] Re-run verification to confirm fixes

- [ ] Test field access with Anonymous Apex:
  ```apex
  OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
  oi.put('New_Field__c', testValue);
  update oi;
  System.debug('✅ Field is accessible');
  ```

- [ ] Document FLS settings in DEPLOYMENT_HISTORY.md

---

## Integration with Deployment Workflow

### When to Verify FLS

**Step 2.7 (DEPLOYMENT_WORKFLOW.md):** Immediately after deploying custom fields

```bash
# Deploy fields
sf project deploy start -m "CustomField:OrderItem.New_Field__c" -o NewOrg

# Verify FLS (should show ❌ NO FLS SET)
./Scripts/verify-fls.sh scenario OrderItem

# Set FLS via UI
# [Follow manual steps above]

# Verify FLS again (should show ✅ CORRECT)
./Scripts/verify-fls.sh scenario OrderItem
```

### Automated Verification in CI/CD

Add to GitHub Actions or deployment scripts:

```yaml
- name: Verify FLS
  run: |
    cd deployment-execution
    ./Scripts/verify-fls.sh $SCENARIO $OBJECT
    if [ $? -ne 0 ]; then
      echo "❌ FLS verification failed!"
      exit 1
    fi
```

---

## Understanding FLS Metadata

### Profile XML Structure

```xml
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- ... -->
    <fieldPermissions>
        <editable>true</editable>      <!-- Can user edit? -->
        <field>Object.Field__c</field> <!-- Object.Field -->
        <readable>true</readable>      <!-- Can user see? -->
    </fieldPermissions>
    <!-- ... -->
</Profile>
```

### Possible Combinations

| Readable | Editable | User Experience |
|----------|----------|-----------------|
| `true` | `true` | ✅ Can see and edit field |
| `true` | `false` | ⚠️ Can see but NOT edit (read-only) |
| `false` | `false` | ❌ Field is invisible |
| `false` | `true` | ❓ Invalid (never happens) |

---

## Advanced: Bulk FLS Configuration

### For Multiple Fields

```bash
# Verify all fields for an object
./Scripts/verify-fls.sh scenario OrderItem

# Fix all fields at once via UI:
# Setup → Object Manager → OrderItem → Fields → "Set Field-Level Security"
# Click "Edit" next to Admin profile
# Bulk check/uncheck for all fields
```

### For Multiple Profiles

If deploying to production with multiple profiles:

1. Retrieve all profiles:
   ```xml
   <types>
       <members>*</members>
       <name>Profile</name>
   </types>
   ```

2. Check FLS for each profile

3. Set FLS for required profiles (not just Admin)

---

## References

- **Deployment Workflow:** [DEPLOYMENT_WORKFLOW.md](../DEPLOYMENT_WORKFLOW.md) Step 2.7
- **FLS Status Report:** [FLS_STATUS_REPORT.md](../../FLS_STATUS_REPORT.md)
- **Automation Script:** [Scripts/verify-fls.sh](../../Scripts/verify-fls.sh)
- **Salesforce Docs:** [Field-Level Security](https://help.salesforce.com/articleView?id=sf.admin_fls.htm)

---

**Last Updated:** October 23, 2025
**Version:** 1.0
