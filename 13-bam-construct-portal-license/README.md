# BAM Construct Portal License Visibility - NewOrg Migration Package

**Scenario**: bam-construct-portal-license
**Priority**: 🟡 Medium (Data Quality / User Experience)
**Deployment Status**: ⏳ PENDING
**OldOrg Implementation**: October 15, 2025
**OldOrg State Documentation**: [View Here](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/bam-construct-portal-license)

---

## Executive Summary

This migration package enables customer portal users with "HQ" role to view supplier waste carrier license numbers and expiry dates in both Job detail pages and the Compliance tab. This is critical for UK waste management compliance verification.

**Business Value**:
- **Compliance**: HQ-level portal users can verify supplier waste carrier licenses for compliance
- **User Count**: 137 HQ users in NewOrg will gain license visibility
- **Risk**: LOW - Read-only fields, no data changes

**Components to Deploy**:
1. Formula field: `Waste_Carrier_License_Expiry__c` (NEW in NewOrg)
2. Job portal layout: License fields added to Supplier Details section
3. Apex class: `Utility_Community.cls` with license fields in SOQL query
4. LWC component: `depotViewCommunity` with license columns in Compliance tab

---

## Table of Contents

1. [Gap Analysis](#gap-analysis)
2. [Deployment Plan](#deployment-plan)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Validation](#post-deployment-validation)
6. [Rollback Procedures](#rollback-procedures)
7. [Configuration Tasks](#configuration-tasks)

---

## Gap Analysis

### NewOrg Current State

**Verified**: October 23, 2025

**Component Status**:

| Component | Exists in NewOrg | Has License Fields | Gap Status |
|-----------|------------------|-------------------|------------|
| `Job__c.Waste_Carrier_License_Expiry__c` | ❌ **NO** | N/A | **MISSING - Create Required** |
| `Job__c-Customer Community Job Layout` | ✅ Yes | ❌ **NO** | **UPDATE REQUIRED** |
| `Utility_Community.cls` | ✅ Yes | ❌ **NO** | **UPDATE REQUIRED** |
| `depotViewCommunity` LWC | ✅ Yes | ❌ **NO** | **UPDATE REQUIRED** |

**Summary**: All 4 components need deployment to NewOrg.

### Existing Field Dependencies (Already in NewOrg)

These fields should already exist in NewOrg (verify before deployment):

✅ **Job Object Fields**:
- `Job__c.Supplier__c` (Lookup to Account)
- `Job__c.Waste_Carrier_License_Number__c` (Formula field referencing `Supplier__r.Waste_Carriers_License_number__c`)

✅ **Account Object Fields**:
- `Account.Waste_Carriers_License_number__c` (Text field - source for license number)
- `Account.Waste_Carriers_License_Date__c` (Date field - source for license expiry)

**Verification Command**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomField WHERE TableEnumOrId = 'Job__c' AND DeveloperName IN ('Supplier', 'Waste_Carrier_License_Number') LIMIT 10" --use-tooling-api --target-org NewOrg

sf data query --query "SELECT DeveloperName FROM CustomField WHERE TableEnumOrId = 'Account' AND DeveloperName IN ('Waste_Carriers_License_number', 'Waste_Carriers_License_Date') LIMIT 10" --use-tooling-api --target-org NewOrg
```

### Trigger Dependency (Already in NewOrg)

✅ **CommunityAccessHelper.cls**:
- Should already exist in NewOrg
- Automatically creates AccountShare records for suppliers when HQ users access sites
- Line 37 logic: Only creates shares for users with `Contact.Community_Role__c = 'HQ'`

**Verification Command**:
```bash
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name = 'CommunityAccessHelper' LIMIT 1" --target-org NewOrg
```

---

## Deployment Plan

### Deployment Phases

**Phase 1: Create Formula Field** (CLI - 5 minutes)
- Deploy `Waste_Carrier_License_Expiry__c` custom field
- Grant field-level security to all community profiles

**Phase 2: Deploy Metadata** (CLI - 10 minutes)
- Deploy Job portal layout
- Deploy Apex class and LWC components (with test execution)

**Phase 3: Configure Users** (Manual UI - 30-60 minutes)
- Update `Community_Role__c = 'HQ'` for appropriate portal users
- Create AccountShare records for user's own account
- Create Site__Share records for user's sites
- Create AccountShare records for existing suppliers

**Phase 4: Testing** (Manual UI - 15-30 minutes)
- Test with actual portal users
- Verify license fields visible on Job detail pages
- Verify license columns visible in Compliance tab
- Document any issues

**Total Estimated Time**: 1.5-2 hours

---

## Pre-Deployment Checklist

### Step 1: Verify Prerequisites

Run these verification queries in NewOrg:

**1.1 Verify Existing Fields Exist**:
```bash
# Should return 2 records (Supplier__c, Waste_Carrier_License_Number__c)
sf data query --query "SELECT DeveloperName, LastModifiedDate FROM CustomField WHERE TableEnumOrId = 'Job__c' AND DeveloperName IN ('Supplier', 'Waste_Carrier_License_Number')" --use-tooling-api --target-org NewOrg

# Should return 2 records (Waste_Carriers_License_number__c, Waste_Carriers_License_Date__c)
sf data query --query "SELECT DeveloperName, LastModifiedDate FROM CustomField WHERE TableEnumOrId = 'Account' AND DeveloperName IN ('Waste_Carriers_License_number', 'Waste_Carriers_License_Date')" --use-tooling-api --target-org NewOrg
```

**1.2 Verify CommunityAccessHelper Trigger Exists**:
```bash
# Should return 1 record
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name = 'CommunityAccessHelper' LIMIT 1" --target-org NewOrg
```

**1.3 Count HQ Portal Users**:
```bash
# Count users who will see license information
sf data query --query "SELECT COUNT() FROM Contact WHERE Community_Role__c = 'HQ' AND Id IN (SELECT ContactId FROM User WHERE IsActive = true)" --target-org NewOrg
```

Expected: Approximately 137 HQ users (may vary in NewOrg)

**1.4 Verify Test Class Exists**:
```bash
# Should return 1 record
sf data query --query "SELECT Name, LastModifiedDate FROM ApexClass WHERE Name = 'Utility_CommunityTest' LIMIT 1" --target-org NewOrg
```

### Step 2: Review Community Users

**2.1 Identify Portal Users Who Need HQ Role**:
```bash
sf data query --query "SELECT Id, Name, Username, Contact.Community_Role__c, Contact.Account.Name FROM User WHERE Profile.Name LIKE '%Community%Manager%' AND Contact.Community_Role__c = null AND IsActive = true" --target-org NewOrg
```

**2.2 Document Users to Update**:
- Review the list with business stakeholders
- Determine which users should have `Community_Role__c = 'HQ'` (vs 'Site')
- Create spreadsheet with User ID, Contact ID, Account ID for Phase 3

---

## Deployment Steps

### PHASE 1: Create Formula Field (CLI - 5 minutes)

**Step 1.1: Deploy License Expiry Field**

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start --metadata "CustomField:Job__c.Waste_Carrier_License_Expiry__c" --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Deployed Source:
- CustomField: Job__c.Waste_Carrier_License_Expiry__c
```

**Verification**:
```bash
sf data query --query "SELECT DeveloperName, LastModifiedDate FROM CustomField WHERE DeveloperName = 'Waste_Carrier_License_Expiry' LIMIT 1" --use-tooling-api --target-org NewOrg
```

---

**Step 1.2: Grant Field-Level Security to All Community Profiles**

**Create Apex Script**: `grant_field_permissions.apex`
```apex
// Get all profiles that have access to Waste_Carrier_License_Number__c
List<FieldPermissions> existingFPs = [
    SELECT ParentId, Parent.ProfileId, Parent.Profile.Name
    FROM FieldPermissions
    WHERE Field = 'Job__c.Waste_Carrier_License_Number__c'
];

System.debug('Found ' + existingFPs.size() + ' existing field permissions for License Number');

// Create matching permissions for the Expiry field
List<FieldPermissions> newFPs = new List<FieldPermissions>();
Set<Id> processedParents = new Set<Id>();

for (FieldPermissions existing : existingFPs) {
    if (!processedParents.contains(existing.ParentId)) {
        FieldPermissions fp = new FieldPermissions();
        fp.ParentId = existing.ParentId;
        fp.SobjectType = 'Job__c';
        fp.Field = 'Job__c.Waste_Carrier_License_Expiry__c';
        fp.PermissionsRead = true;
        fp.PermissionsEdit = false;
        newFPs.add(fp);
        processedParents.add(existing.ParentId);
    }
}

try {
    insert newFPs;
    System.debug('SUCCESS: Granted field permissions to ' + newFPs.size() + ' profiles/permission sets');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
```

**Execute Command**:
```bash
sf apex run --target-org NewOrg < grant_field_permissions.apex
```

**Expected Output**:
```
SUCCESS: Granted field permissions to 17 profiles/permission sets
```

**Verification**:
```bash
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%' LIMIT 10" --target-org NewOrg
```

---

### PHASE 2: Deploy Metadata (CLI - 10 minutes)

**Step 2.1: Deploy Job Portal Layout**

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start --source-dir "force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml" --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Deployed Source:
- Layout: Job__c-Customer Community Job Layout
```

**Verification**: Check layout in Setup → Object Manager → Job → Page Layouts → Customer Community Job Layout → Supplier Details section should show:
- Supplier Name
- **Waste Carrier License Number** ✅
- **Waste Carrier License Expiry** ✅

---

**Step 2.2: Deploy Apex Class and LWC Components**

**Command**:
```bash
cd /home/john/Projects/Salesforce
sf project deploy start --source-dir "force-app/main/default/classes/Utility_Community.cls" --source-dir "force-app/main/default/lwc/depotViewCommunity" --test-level RunSpecifiedTests --tests Utility_CommunityTest --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Test Results: Passed
Deployed Source:
- ApexClass: Utility_Community
- LightningComponentBundle: depotViewCommunity
```

**Verification**: Query to confirm deployment:
```bash
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name = 'Utility_Community' LIMIT 1" --target-org NewOrg
```

---

### PHASE 3: Configure Users (Manual UI - 30-60 minutes)

**Step 3.1: Update Community_Role__c for Portal Users**

For each user who needs HQ access (identified in Pre-Deployment Step 2.2):

**Command Template**:
```bash
sf data update record --sobject Contact --record-id <CONTACT_ID> --values "Community_Role__c='HQ'" --target-org NewOrg
```

**Example**:
```bash
# Ruth Beavers at BAM Construct UK (example - adjust for NewOrg IDs)
sf data update record --sobject Contact --record-id 0032400000rtDPzAAM --values "Community_Role__c='HQ'" --target-org NewOrg
```

**Verification**:
```bash
sf data query --query "SELECT Id, Name, Community_Role__c FROM Contact WHERE Id = '<CONTACT_ID>'" --target-org NewOrg
```

---

**Step 3.2: Create AccountShare for User's Own Account**

Users need access to their own company account to see sites.

**Command Template**:
```bash
sf data create record --sobject AccountShare --values "AccountId='<CUSTOMER_ACCOUNT_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Edit' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org NewOrg
```

**Example**:
```bash
# BAM Construct UK account (example - adjust for NewOrg IDs)
sf data create record --sobject AccountShare --values "AccountId='0012400000RIcTpAAL' UserOrGroupId='005Sj000002aZAzIAM' AccountAccessLevel='Edit' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org NewOrg
```

---

**Step 3.3: Create Site__Share Records**

**Command Template** (for each site the user should access):
```bash
sf data create record --sobject Site__Share --values "ParentId='<SITE_ID>' UserOrGroupId='<USER_ID>' AccessLevel='Edit' RowCause='Manual'" --target-org NewOrg
```

**Example**:
```bash
# The Salesian Academy (example - adjust for NewOrg IDs)
sf data create record --sobject Site__Share --values "ParentId='a1dSj000000qQfxIAE' UserOrGroupId='005Sj000002aZAzIAM' AccessLevel='Edit' RowCause='Manual'" --target-org NewOrg
```

---

**Step 3.4: Create AccountShare for Existing Suppliers**

First, query to find suppliers used on user's sites:

```bash
sf data query --query "SELECT DISTINCT Supplier__c, Supplier__r.Name FROM Job__c WHERE Site__c = '<SITE_ID>' AND Supplier__c != null" --target-org NewOrg
```

Then create AccountShare for each supplier:

**Command Template**:
```bash
sf data create record --sobject AccountShare --values "AccountId='<SUPPLIER_ACCOUNT_ID>' UserOrGroupId='<USER_ID>' AccountAccessLevel='Read' OpportunityAccessLevel='Read' RowCause='Manual'" --target-org NewOrg
```

**Note**: Once `Community_Role__c = 'HQ'` is set, future suppliers will automatically get AccountShare through the CommunityAccessHelper trigger. Manual creation is only needed for existing suppliers.

---

**Step 3.5: Bulk User Configuration (Optional)**

For bulk user configuration, use this Apex script:

```apex
// Bulk create sharing records for all HQ users
List<Contact> hqContacts = [SELECT Id, AccountId FROM Contact WHERE Community_Role__c = 'HQ' AND Id IN (SELECT ContactId FROM User WHERE IsActive = true)];

List<AccountShare> accountShares = new List<AccountShare>();
List<Site__Share> siteShares = new List<Site__Share>();

for (Contact c : hqContacts) {
    User u = [SELECT Id FROM User WHERE ContactId = :c.Id LIMIT 1];

    // Create AccountShare for own account
    AccountShare as = new AccountShare();
    as.AccountId = c.AccountId;
    as.UserOrGroupId = u.Id;
    as.AccountAccessLevel = 'Edit';
    as.OpportunityAccessLevel = 'Read';
    as.RowCause = 'Manual';
    accountShares.add(as);

    // Create Site__Share for all sites belonging to user's account
    for (Site__c site : [SELECT Id FROM Site__c WHERE Account__c = :c.AccountId]) {
        Site__Share ss = new Site__Share();
        ss.ParentId = site.Id;
        ss.UserOrGroupId = u.Id;
        ss.AccessLevel = 'Edit';
        ss.RowCause = 'Manual';
        siteShares.add(ss);
    }
}

try {
    insert accountShares;
    insert siteShares;
    System.debug('SUCCESS: Created ' + accountShares.size() + ' AccountShare and ' + siteShares.size() + ' Site__Share records');
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
```

**Execute**:
```bash
sf apex run --target-org NewOrg < bulk_sharing_script.apex
```

---

### PHASE 4: Testing (Manual UI - 15-30 minutes)

**Step 4.1: Test with Portal User**

Log into customer portal as an HQ user (e.g., Ruth Beavers equivalent in NewOrg)

**Test 1: Job Detail Page**
1. Navigate: Sites → Select a Site → Jobs → Click a Job
2. Verify "Supplier Details" section shows:
   - ✅ Supplier Name
   - ✅ **Waste Carrier License Number** (e.g., CBDU180923)
   - ✅ **Waste Carrier License Expiry** (e.g., 25/06/2026)
   - ✅ Depot Supply Name
   - ✅ Depot Dispose Name

**Test 2: Compliance Tab**
1. Navigate: Compliance tab
2. Select a Site from dropdown
3. Click "Search"
4. Verify table displays columns:
   - ✅ Waste Carrier
   - ✅ **License Number**
   - ✅ **License Expiry**
   - ✅ Waste Destination
   - ✅ Waste Type
   - ✅ EWC Code
   - ✅ First Service
   - ✅ Last Service

**Test 3: Non-HQ Users (Negative Test)**
1. Log in as Site-level user (`Community_Role__c = 'Site'`)
2. Navigate to Job detail page
3. Verify: License fields are visible but **BLANK** (no data due to no AccountShare)
4. This is expected behavior - Site users don't need supplier compliance info

---

**Step 4.2: Backend Verification Queries**

**Check User Setup**:
```bash
# Verify Community_Role__c
sf data query --query "SELECT Id, Name, Community_Role__c, Account.Name FROM Contact WHERE Id = '<CONTACT_ID>'" --target-org NewOrg

# Verify AccountShare records
sf data query --query "SELECT AccountId, Account.Name, UserOrGroupId, AccountAccessLevel FROM AccountShare WHERE UserOrGroupId = '<USER_ID>'" --target-org NewOrg

# Verify Site__Share records
sf data query --query "SELECT ParentId, UserOrGroupId, AccessLevel FROM Site__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org NewOrg
```

**Check Field Permissions**:
```bash
# Verify field exists
sf data query --query "SELECT DeveloperName, TableEnumOrId FROM CustomField WHERE DeveloperName = 'Waste_Carrier_License_Expiry' LIMIT 1" --use-tooling-api --target-org NewOrg

# Verify FLS for community profiles
sf data query --query "SELECT Parent.Profile.Name, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Job__c.Waste_Carrier_License_Expiry__c' AND Parent.Profile.Name LIKE '%Community%'" --target-org NewOrg
```

---

## Post-Deployment Validation

### Validation Checklist

✅ **Component Deployment**:
- [ ] Formula field `Waste_Carrier_License_Expiry__c` exists in NewOrg
- [ ] Field-level security granted to all community profiles (~17 profiles)
- [ ] Job portal layout shows license fields in Supplier Details section
- [ ] Utility_Community.cls LastModifiedDate is recent
- [ ] depotViewCommunity LWC LastModifiedDate is recent

✅ **User Configuration**:
- [ ] HQ users have `Community_Role__c = 'HQ'`
- [ ] HQ users have AccountShare for their own account
- [ ] HQ users have Site__Share for their sites
- [ ] HQ users have AccountShare for existing suppliers

✅ **Portal Testing**:
- [ ] Job detail pages show license fields (for HQ users)
- [ ] Compliance tab shows license columns (for HQ users)
- [ ] Site users do NOT see license data (expected - no AccountShare)

### Success Criteria

**Deployment is successful when**:
1. All 4 components deployed without errors
2. At least 1 HQ user can see license information on Job detail pages
3. At least 1 HQ user can see license columns in Compliance tab
4. Site-level users do NOT see license data (confirms sharing rules work)

---

## Rollback Procedures

### If Issues Occur - Rollback Steps

**Rollback Step 1: Revert User Access Changes**

```bash
# Remove Community_Role__c
sf data update record --sobject Contact --record-id <CONTACT_ID> --values "Community_Role__c=''" --target-org NewOrg

# Query and delete AccountShare records
sf data query --query "SELECT Id FROM AccountShare WHERE UserOrGroupId = '<USER_ID>' AND RowCause = 'Manual'" --target-org NewOrg
sf data delete record --sobject AccountShare --record-id <ACCOUNTSHARE_ID> --target-org NewOrg

# Query and delete Site__Share records
sf data query --query "SELECT Id FROM Site__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org NewOrg
sf data delete record --sobject Site__Share --record-id <SITESHARE_ID> --target-org NewOrg
```

---

**Rollback Step 2: Revert Portal Layout**

Edit the layout file to remove license fields, then redeploy:

```bash
cd /home/john/Projects/Salesforce
# Edit layout file to remove lines 96-100 (license fields)
sf project deploy start --source-dir "force-app/main/default/layouts/Job__c-Customer Community Job Layout.layout-meta.xml" --target-org NewOrg
```

---

**Rollback Step 3: Revert Compliance Tab Changes**

```bash
# Use git to revert changes
cd /home/john/Projects/Salesforce
git checkout HEAD~1 -- force-app/main/default/classes/Utility_Community.cls
git checkout HEAD~1 -- force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.js
git checkout HEAD~1 -- force-app/main/default/lwc/depotViewCommunity/depotViewCommunity.html

# Redeploy
sf project deploy start --source-dir "force-app/main/default/classes/Utility_Community.cls" --source-dir "force-app/main/default/lwc/depotViewCommunity" --test-level RunSpecifiedTests --tests Utility_CommunityTest --target-org NewOrg
```

---

**Rollback Step 4: Remove Custom Field (NOT recommended)**

```bash
# Delete field metadata (WARNING: will lose data)
sf project delete source --metadata "CustomField:Job__c.Waste_Carrier_License_Expiry__c" --target-org NewOrg
```

**Note**: Deleting fields is usually not recommended. Instead, hide the field from layouts and profiles.

---

## Configuration Tasks

### Post-Deployment Data Quality

**Issue**: 65% of portal users in OldOrg (594 out of 914) have `Community_Role__c = null`

**Recommendation for NewOrg**:
1. Review all users with "RL Customer Community Plus Manager" profile
2. Determine if they should be HQ or Site role
3. Bulk update `Community_Role__c` for these users

**Query to Identify Affected Users**:
```bash
sf data query --query "SELECT Id, Name, Username, Contact.Community_Role__c, Contact.Account.Name FROM User WHERE Profile.Name = 'RL Customer Community Plus Manager' AND Contact.Community_Role__c = null AND IsActive = true" --target-org NewOrg
```

### Community Role Guidelines

**When to set Community_Role__c = 'HQ'**:
- Head office users
- Procurement staff
- Facilities management
- Senior site management
- Anyone who needs to verify supplier compliance

**When to set Community_Role__c = 'Site'**:
- On-site workers
- Day-to-day operations staff
- Users who don't need supplier compliance visibility

**When to leave Community_Role__c = null**:
- **Never** - this should always be set (data quality issue)

---

## Known Limitations

### Compliance Tab Filtering

**Issue**: Some suppliers with valid licenses may not appear in the Compliance tab grouping.

**Root Cause**: The `Utility_Community.getDepotInformations()` query includes filter:
```apex
WHERE Site__c IN :siteIds
AND Status__c NOT IN ('Pending Cancellation', 'Cancelled', 'Failed')
AND Supplier__c != NULL
AND Supplier__r.Name != NULL
AND Depot_Dispose__c != NULL  // <-- Filters out jobs without disposal location
```

**Impact**:
- Jobs without `Depot_Dispose__c` (Waste Destination) will NOT appear in Compliance tab
- These jobs ARE still visible when navigating to individual Job detail pages
- License information IS displayed on individual Job records

**This is existing business logic** - the Compliance tab was designed to show grouped supplier/depot compliance views.

---

## GitHub Repository Links

**OldOrg State Documentation**:
https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/bam-construct-portal-license

**This Document (NewOrg Migration Package)**:
https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/bam-construct-portal-license

---

**NewOrg Migration Package Complete** ✅
**Package Created**: October 23, 2025
**Estimated Deployment Time**: 1.5-2 hours
**Risk Level**: LOW
**Next Step**: Deploy to NewOrg following 4-phase plan above
