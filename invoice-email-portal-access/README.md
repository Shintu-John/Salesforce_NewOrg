# Invoice Email Portal Access Solution - NewOrg Migration Plan

**Target Org**: NewOrg
**Migration Priority**: 🟡 Medium
**Estimated Time**: 3-4 hours
**Dependencies**: Invoice__c object, InvoiceTrigger, Community/Site setup
**Complexity**: Medium

---

## Executive Summary

This migration deploys the invoice portal access solution that allows customers to view and download invoice PDFs through a guest-accessible web portal. The solution addresses a critical customer experience issue where portal pages only displayed job paperwork but not invoice PDFs.

### What This Solution Does

**Customer Experience**:
1. Customer receives invoice email with PDF attachment + portal link
2. Customer clicks portal link (no login required)
3. Portal displays BOTH invoice PDFs and job paperwork
4. Customer can download invoice PDF directly from portal
5. Fully automated - no manual steps for new invoices

**Business Value**:
- Improved customer experience (access to invoices via portal)
- Reduced support tickets (customers can self-serve)
- Automated ContentDistribution creation (no manual work)
- Guest user compatible (no authentication required)

---

## Gap Analysis

### Current State in NewOrg

Need to verify the following components exist:

**Required Objects**:
- ✅ Invoice__c (custom object - should exist)
- ✅ ContentDocumentLink (standard object)
- ✅ ContentDistribution (standard object)

**Required Trigger**:
- ✅ InvoiceTrigger (should exist - check if it calls InvoiceTriggerHandler)

**Required Community/Site**:
- ⚠️ Need to verify: Guest-accessible community or site for portal pages
- ⚠️ Need to verify: Guest user profile with proper permissions

**Missing Components** (to be deployed):
- ❌ Modified InvoiceFileListController.cls (Apex Class)
- ❌ Modified ContentDistributionHelper.cls (Apex Class)
- ❌ Modified InvoiceTriggerHandler.cls (Apex Class)
- ❌ Modified InvoiceFileList.page (Visualforce Page)
- ❌ Test classes for all modified classes

---

## Components to Deploy

### 1. Apex Classes

#### A. InvoiceFileListController.cls

**Purpose**: Controller for invoice portal page

**Modifications from Base Version**:
- Added `invoiceFileDetailsList` property
- Added invoice file fetching logic (queries ContentDocumentLink)
- Added deduplication logic (shows most recent file version only)
- Added InvoiceFileDetails inner class

**Lines Changed**: +55 lines (192-246, 311-323)

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/InvoiceFileListController.cls`

**Dependencies**:
- Invoice__c object
- ContentDocumentLink
- ContentDistribution

---

#### B. ContentDistributionHelper.cls

**Purpose**: Utility class for creating ContentDistribution records

**Modifications from Base Version**:
- Added `manageInvoiceContentDistribution(Set<Id> invoiceIds)` method
- Handles both job paperwork AND invoice PDFs
- Bulkified for efficiency (200 invoices per transaction)
- Does NOT set RelatedRecordId for invoice PDFs (guest user access)

**Lines Changed**: +63 lines (78-140)

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/ContentDistributionHelper.cls`

**Dependencies**:
- ContentDocumentLink
- ContentDistribution
- ContentVersion

---

#### C. InvoiceTriggerHandler.cls

**Purpose**: Trigger handler for Invoice__c object

**Modifications from Base Version**:
- Added ContentDistributionHelper call in afterInsert()
- Added ContentDistributionHelper call in afterUpdate()
- Automatically creates ContentDistribution for all invoice PDFs

**Lines Changed**: +2 lines (6, 30)

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/InvoiceTriggerHandler.cls`

**Dependencies**:
- ContentDistributionHelper class

---

### 2. Visualforce Page

#### InvoiceFileList.page

**Purpose**: Guest-accessible portal page for invoice and job file display

**Modifications from Base Version**:
- Added `cache="false"` to prevent caching
- Added "Invoice Files" section with download buttons
- Removed empty "Invoice" section
- Uses DistributionPublicUrl for guest user downloads

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/InvoiceFileList.page`

**Dependencies**:
- InvoiceFileListController class

---

### 3. Test Classes

#### A. InvoiceFileListControllerTest.cls

**Purpose**: Test class for InvoiceFileListController

**Test Coverage**: 89%
**Test Methods**: 3 tests

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/InvoiceFileListControllerTest.cls`

---

#### B. ContentDistributionHelperTest.cls

**Purpose**: Test class for ContentDistributionHelper

**Test Coverage**: 84%
**Test Methods**: Includes testInvoiceContentDistributionHelper()

**Source File**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/ContentDistributionHelperTest.cls`

---

## Pre-Deployment Checklist

### Step 1: Verify Required Objects Exist

Run these queries in NewOrg:

```bash
# Check if Invoice__c object exists
sf data query -q "SELECT Id, Name FROM Invoice__c LIMIT 1" -o NewOrg

# Check if InvoiceTrigger exists
sf data query -q "SELECT Id, Name FROM ApexTrigger WHERE Name = 'InvoiceTrigger'" -o NewOrg

# Check if InvoiceTriggerHandler exists
sf data query -q "SELECT Id, Name FROM ApexClass WHERE Name = 'InvoiceTriggerHandler'" -o NewOrg

# Check if ContentDistributionHelper exists (may need to be created)
sf data query -q "SELECT Id, Name FROM ApexClass WHERE Name = 'ContentDistributionHelper'" -o NewOrg

# Check if InvoiceFileListController exists (may be old version)
sf data query -q "SELECT Id, Name FROM ApexClass WHERE Name = 'InvoiceFileListController'" -o NewOrg

# Check if InvoiceFileList page exists
sf data query -q "SELECT Id, Name FROM ApexPage WHERE Name = 'InvoiceFileList'" -o NewOrg
```

---

### Step 2: Verify Community/Site Setup

**Check Existing Sites**:
```bash
sf data query -q "SELECT Id, Name, Subdomain, UrlPathPrefix FROM Site" -o NewOrg
```

**Required Site Configuration**:
- Public site or community accessible to guest users
- URL pattern: `https://[domain].my.salesforce-sites.com/invoicefiledetails`
- Guest user license available
- Guest user profile configured

**If site doesn't exist**, you'll need to:
1. Create a new Site in Setup > Sites
2. Configure guest user profile
3. Map InvoiceFileList page to URL path

---

### Step 3: Copy Source Files to NewOrg Project

```bash
# Create backup reference folder
mkdir -p /path/to/NewOrg/migration-source/invoice-portal-access

# Copy files from OldOrg backup
cp /Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/*.cls \
   /path/to/NewOrg/force-app/main/default/classes/

cp /Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/*.cls-meta.xml \
   /path/to/NewOrg/force-app/main/default/classes/

cp /Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/*.page \
   /path/to/NewOrg/force-app/main/default/pages/

cp /Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/*.page-meta.xml \
   /path/to/NewOrg/force-app/main/default/pages/
```

---

## Deployment Steps

### Phase 1: Deploy Apex Classes (with Tests)

**Deploy Order** (due to dependencies):

1. ContentDistributionHelper + Test
2. InvoiceTriggerHandler (depends on ContentDistributionHelper)
3. InvoiceFileListController + Test
4. InvoiceFileList page (depends on InvoiceFileListController)

**Deployment Command**:

```bash
# Option A: Deploy all components together
sf project deploy start \
  --source-dir force-app/main/default/classes/ContentDistributionHelper.cls \
  --source-dir force-app/main/default/classes/ContentDistributionHelperTest.cls \
  --source-dir force-app/main/default/classes/InvoiceTriggerHandler.cls \
  --source-dir force-app/main/default/classes/InvoiceFileListController.cls \
  --source-dir force-app/main/default/classes/InvoiceFileListControllerTest.cls \
  --source-dir force-app/main/default/pages/InvoiceFileList.page \
  --test-level RunSpecifiedTests \
  --tests ContentDistributionHelperTest \
  --tests InvoiceFileListControllerTest \
  -o NewOrg \
  --wait 15

# Option B: Deploy metadata folder (all components)
sf project deploy start \
  --metadata-dir force-app/main/default \
  --test-level RunLocalTests \
  -o NewOrg \
  --wait 15
```

**Expected Results**:
- All classes deployed successfully
- Test coverage ≥ 75%
- All tests passing (5+ tests total)

---

### Phase 2: Configure Guest User Profile

**Profile Name**: "Invoice File Details Profile" (or your site's guest user profile)

#### A. Grant Apex Class Access

Navigate to: Setup > Profiles > [Guest User Profile] > Enabled Apex Classes

**Add These Classes**:
- InvoiceFileListController
- (Do NOT add ContentDistributionHelper or InvoiceTriggerHandler - internal only)

#### B. Grant Visualforce Page Access

Navigate to: Setup > Profiles > [Guest User Profile] > Enabled Visualforce Pages

**Add This Page**:
- InvoiceFileList

#### C. Grant Object Permissions

Navigate to: Setup > Profiles > [Guest User Profile] > Object Settings

**ContentDistribution**:
- Read: ✅ Enabled
- (Create/Edit/Delete: Leave disabled)

**ContentDocumentLink**:
- Read: ✅ Enabled
- (Create/Edit/Delete: Leave disabled)

**Invoice__c** (limited):
- Read: ✅ Enabled (for Id field only)
- Field-Level Security:
  - Id: ✅ Read
  - Name: ❌ Not required (guest user doesn't need to see invoice number)

#### D. Grant System Permissions

Navigate to: Setup > Profiles > [Guest User Profile] > System Permissions

**Enable These Permissions**:
- ActivitiesAccess
- ContentWorkspaces
- UseWebLink

---

### Phase 3: Configure Site/Community

#### A. Map Visualforce Page to URL

Navigate to: Setup > Sites > [Your Site] > Site Visualforce Pages

**Add Mapping**:
- URL Path: `/invoicefiledetails`
- Visualforce Page: `InvoiceFileList`
- Query Parameter: `invoiceid` (required)

**Test URL Pattern**:
```
https://[your-domain].my.salesforce-sites.com/invoicefiledetails?invoiceid=[test-invoice-id]
```

#### B. Enable Site for Public Access

Navigate to: Setup > Sites > [Your Site] > Public Access Settings

**Verify**:
- Site is Active
- Guest user profile is assigned
- Guest user has proper permissions

---

### Phase 4: Post-Deployment Validation

#### Test 1: Verify Components Deployed

```bash
# Check classes deployed
sf data query -q "SELECT Id, Name, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name IN ('InvoiceFileListController', 'ContentDistributionHelper', 'InvoiceTriggerHandler') ORDER BY Name" -o NewOrg

# Check page deployed
sf data query -q "SELECT Id, Name, LastModifiedDate, LastModifiedBy.Name FROM ApexPage WHERE Name = 'InvoiceFileList'" -o NewOrg
```

---

#### Test 2: Create Test ContentDistribution

**Option A: Via Apex (Developer Console)**:

```apex
// Get a test invoice with PDF attached
Invoice__c testInvoice = [SELECT Id, Name FROM Invoice__c
                          WHERE Id IN (SELECT LinkedEntityId FROM ContentDocumentLink)
                          LIMIT 1];

// Trigger ContentDistribution creation
Set<Id> invoiceIds = new Set<Id>{testInvoice.Id};
ContentDistributionHelper.manageInvoiceContentDistribution(invoiceIds);

// Verify ContentDistribution created
List<ContentDistribution> distributions = [
    SELECT Id, DistributionPublicUrl, ContentVersionId
    FROM ContentDistribution
    WHERE ContentVersionId IN (
        SELECT ContentDocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :testInvoice.Id
    )
];

System.debug('ContentDistributions created: ' + distributions.size());
for(ContentDistribution cd : distributions) {
    System.debug('Public URL: ' + cd.DistributionPublicUrl);
}
```

**Expected Result**:
- 1+ ContentDistribution records created
- Each has a valid DistributionPublicUrl

---

#### Test 3: Test Portal Page Access

**Get Test Invoice ID**:
```bash
sf data query -q "SELECT Id, Name FROM Invoice__c WHERE Id IN (SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocument.FileExtension = 'pdf') LIMIT 1" -o NewOrg
```

**Test Portal URL**:
```
https://[your-domain].my.salesforce-sites.com/invoicefiledetails?invoiceid=[test-invoice-id]
```

**Expected Results**:
- ✅ Page loads without authentication
- ✅ "Invoice Files" section displays
- ✅ Invoice PDF filename shown
- ✅ Download button present
- ✅ Download button works (opens/downloads PDF)
- ✅ "Job Paperwork" section displays (if applicable)

**If Page Shows "Authorization Required"**:
- Check guest user profile has access to InvoiceFileListController
- Check guest user profile has access to InvoiceFileList page
- Check site is active and public access is enabled

**If "Invoice Files" Section Doesn't Appear**:
- Verify invoice has PDF attached (ContentDocumentLink exists)
- Verify ContentDistribution exists for that PDF
- Run ContentDistributionHelper.manageInvoiceContentDistribution() manually

**If Download Button Doesn't Work**:
- Check ContentDistribution.DistributionPublicUrl is not null
- Check ContentDistribution preferences (AllowOriginalDownload = true)
- Check browser console for JavaScript errors

---

#### Test 4: Test Automatic Trigger

**Create Test Invoice with PDF**:

```apex
// Create test invoice
Invoice__c testInv = new Invoice__c(
    Name = 'TEST-AUTO-001',
    // Add required fields
);
insert testInv;

// Attach PDF (simulate email flow)
ContentVersion cv = new ContentVersion(
    Title = 'Test Invoice',
    PathOnClient = 'test-invoice.pdf',
    VersionData = Blob.valueOf('Test PDF Content'),
    FirstPublishLocationId = testInv.Id
);
insert cv;

// Trigger should fire automatically on insert
// Wait a moment, then check ContentDistribution

List<ContentDistribution> autoCreated = [
    SELECT Id, DistributionPublicUrl
    FROM ContentDistribution
    WHERE ContentVersionId = :cv.Id
];

System.debug('Auto-created ContentDistributions: ' + autoCreated.size());
```

**Expected Result**:
- ContentDistribution created automatically
- No manual intervention needed

---

#### Test 5: Test Deduplication Logic

**Upload Multiple PDFs with Same Name**:

```apex
Invoice__c testInv = [SELECT Id FROM Invoice__c WHERE Name = 'TEST-AUTO-001'];

// Upload first version
ContentVersion cv1 = new ContentVersion(
    Title = 'Invoice - TEST-AUTO-001',
    PathOnClient = 'Invoice - TEST-AUTO-001.pdf',
    VersionData = Blob.valueOf('Version 1 Content'),
    FirstPublishLocationId = testInv.Id
);
insert cv1;

// Upload second version (same name)
ContentVersion cv2 = new ContentVersion(
    Title = 'Invoice - TEST-AUTO-001',
    PathOnClient = 'Invoice - TEST-AUTO-001.pdf',
    VersionData = Blob.valueOf('Version 2 Content - Updated'),
    FirstPublishLocationId = testInv.Id
);
insert cv2;

// Check portal page
// Should show only 1 file (most recent)
```

**Expected Result**:
- Portal shows only 1 file
- Most recent version displayed
- No duplicates in list

---

## Configuration for Existing Invoices

### Create ContentDistribution for Old Invoices

If NewOrg has existing invoices (before this deployment), they won't have ContentDistribution records.

#### Option A: Manual Update (Small Number)

```apex
// Execute in Developer Console
Set<Id> oldInvoiceIds = new Set<Id>{
    'a28xxxxxxxxxxxxxxx',  // Replace with actual Invoice IDs
    'a28yyyyyyyyyyyyyyy',
    'a28zzzzzzzzzzzzzzz'
};

ContentDistributionHelper.manageInvoiceContentDistribution(oldInvoiceIds);
```

---

#### Option B: Batch Apex (Large Number)

```apex
public class CreateInvoiceContentDistributionBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all invoices with PDF attachments but no ContentDistribution
        return Database.getQueryLocator([
            SELECT Id
            FROM Invoice__c
            WHERE Id IN (
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocument.FileExtension = 'pdf'
                AND LinkedEntityId IN (SELECT Id FROM Invoice__c)
            )
            AND CreatedDate >= 2025-01-01T00:00:00Z
            ORDER BY CreatedDate DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Invoice__c> records) {
        Set<Id> invoiceIds = new Set<Id>();
        for(Invoice__c inv : records) {
            invoiceIds.add(inv.Id);
        }
        ContentDistributionHelper.manageInvoiceContentDistribution(invoiceIds);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed. ContentDistributions created for existing invoices.');
    }
}

// Execute batch
CreateInvoiceContentDistributionBatch batch = new CreateInvoiceContentDistributionBatch();
Database.executeBatch(batch, 50);
```

---

#### Option C: Trigger Re-Run (Update Records)

```apex
// Update all invoices to trigger ContentDistribution creation
List<Invoice__c> oldInvoices = [
    SELECT Id
    FROM Invoice__c
    WHERE CreatedDate >= 2025-01-01T00:00:00Z
    LIMIT 200
];

update oldInvoices;  // Triggers afterUpdate, creates ContentDistribution
```

---

## Rollback Plan

### If Deployment Fails

**Symptoms**:
- Test failures
- Compilation errors
- Governor limit exceptions

**Rollback Steps**:

1. **Revert Apex Classes**:
   ```bash
   sf project deploy start \
     --source-dir backup/pre-deployment/ \
     -o NewOrg \
     --wait 10
   ```

2. **Restore Previous Versions**:
   - Setup > Apex Classes > [Class Name] > Show History
   - Select previous version
   - Revert to that version

3. **No Data Loss**:
   - This deployment doesn't modify existing data
   - Invoice records unchanged
   - ContentDocumentLink unchanged
   - ContentDistribution records can be deleted if needed

---

### If Portal Shows Errors After Deployment

**Symptom**: "Authorization Required" error

**Fix**:
1. Verify guest user profile permissions
2. Check site is active
3. Verify page and controller in profile's enabled list

**Rollback**: Deactivate site temporarily while fixing permissions

---

## Monitoring & Maintenance

### What to Monitor Post-Deployment

#### 1. ContentDistribution Creation Failures

**Monitor**: Debug logs for ContentDistribution insert errors

**Check**:
```bash
# Query for recent invoices without ContentDistribution
sf data query -q "SELECT Id, Name, CreatedDate FROM Invoice__c WHERE Id IN (SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocument.FileExtension = 'pdf') AND Id NOT IN (SELECT ContentVersionId FROM ContentDistribution) AND CreatedDate >= LAST_N_DAYS:7" -o NewOrg
```

**If Failures Found**:
- Check trigger is active
- Check ContentDistributionHelper is deployed
- Re-run manually: `ContentDistributionHelper.manageInvoiceContentDistribution(invoiceIds)`

---

#### 2. Guest User Access Issues

**Monitor**: Customer reports of "Authorization Required" errors

**Check**:
- Site is active
- Guest user profile has proper permissions
- Apex classes and pages are in enabled list

---

#### 3. Portal Usage Statistics

**Monitor**: How many customers use portal vs. email attachment

**Track**:
- Page view statistics (Setup > Sites > [Your Site] > Site Detail)
- ContentDistribution download statistics (if available)

---

## Known Limitations & Considerations

### 1. Guest User Permissions ⚠️

**Technical Constraint**: ContentDistribution with `RelatedRecordId` set requires authentication

**Our Solution**: Set `RelatedRecordId = null` for invoice PDFs

**Impact**:
- Invoice ContentDistribution records are NOT linked back to Invoice__c
- Cannot query ContentDistribution by Invoice ID (must go through ContentVersionId)
- Acceptable trade-off for guest user access

---

### 2. No Invoice Number Display ⚠️

**Limitation**: Guest users don't have field-level security on `Invoice__c.Name`

**Impact**: Portal doesn't display invoice number

**Workaround**: Customer already knows invoice number from email

**Future Fix**: Grant FLS on `Invoice__c.Name` to guest user profile, then add section back to page

---

### 3. Community/Site Required ⚠️

**Requirement**: This solution requires an active Community or Site

**Impact**:
- Need guest user licenses
- Need site configuration
- Additional setup time

**Alternative**: Could use authenticated Experience Cloud site (no guest user limitations)

---

### 4. Bulk ContentDistribution Creation Limit ⚠️

**Governor Limit**: Max 200 invoices per trigger execution

**Impact**: If more than 200 invoices created at once, some may not get ContentDistribution

**Mitigation**:
- Trigger is bulkified to handle 200
- Unlikely to insert 200+ invoices at once
- Can re-run manually if needed

---

## Success Criteria

### Deployment Success ✅

- [ ] All Apex classes deployed successfully
- [ ] All test classes passing (≥75% coverage)
- [ ] Visualforce page deployed successfully
- [ ] Guest user profile configured
- [ ] Site/Community mapping complete
- [ ] No compilation errors
- [ ] No test failures

---

### Functional Success ✅

- [ ] Portal page loads without authentication
- [ ] "Invoice Files" section displays invoice PDFs
- [ ] Download button works for guest users
- [ ] New invoices automatically get ContentDistribution
- [ ] Trigger fires on invoice insert and update
- [ ] Deduplication shows only most recent file
- [ ] Job Paperwork section still works (if applicable)
- [ ] No customer-facing errors

---

### Performance Success ✅

- [ ] Page loads in < 3 seconds
- [ ] No SOQL governor limit exceptions
- [ ] No CPU time limit exceptions
- [ ] ContentDistribution creation completes in < 5 seconds

---

## Estimated Timeline

**Total Time**: 3-4 hours

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1 | Pre-deployment verification | 30 mins | Access to NewOrg |
| 2 | Copy source files | 15 mins | OldOrg backup files |
| 3 | Deploy Apex classes + tests | 30 mins | Files copied |
| 4 | Configure guest user profile | 30 mins | Deployment complete |
| 5 | Configure site/community | 30 mins | Profile configured |
| 6 | Post-deployment testing | 45 mins | All config complete |
| 7 | Create ContentDistribution for existing invoices | 30 mins | Testing complete |
| 8 | Documentation and handoff | 30 mins | All tasks complete |

---

## Resources & References

### Source Files Location

**OldOrg Backup**: `/Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/`

**Files Included**:
- ContentDistributionHelper.cls + meta.xml
- ContentDistributionHelperTest.cls + meta.xml
- InvoiceFileListController.cls + meta.xml
- InvoiceFileListControllerTest.cls + meta.xml
- InvoiceTriggerHandler.cls + meta.xml
- InvoiceFileList.page + meta.xml
- FILE_MANIFEST.txt (deployment metadata)
- README.md (deployment guide)
- INVOICE_EMAIL_PORTAL_ACCESS_SOLUTION.md (complete technical docs)

---

### Related Documentation

- **OldOrg State**: [invoice-email-portal-access/README.md](../../Salesforce_OldOrg_State/invoice-email-portal-access/README.md)
- **Complete Technical Documentation**: [INVOICE_EMAIL_PORTAL_ACCESS_SOLUTION.md](../../Salesforce/Documentation/INVOICE_EMAIL_PORTAL_ACCESS_SOLUTION.md)
- **OldOrg Backup Files**: [/Documentation/Backup/InvoicePortalAccess_2025-10-09/](../../Salesforce/Documentation/Backup/InvoicePortalAccess_2025-10-09/)

---

### Salesforce Documentation

- [ContentDistribution Object Reference](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contentdistribution.htm)
- [Sites and Site.com](https://help.salesforce.com/s/articleView?id=sf.sites_overview.htm)
- [Guest User Permissions](https://help.salesforce.com/s/articleView?id=sf.networks_guest_overview.htm)

---

## Support & Troubleshooting

### Common Issues

#### Issue 1: "Authorization Required" Error

**Symptoms**: Portal shows authorization error instead of invoice files

**Resolution**:
1. Check guest user profile has access to InvoiceFileListController
2. Check guest user profile has access to InvoiceFileList page
3. Verify site is active and public access enabled
4. Check ContentDistribution permissions in guest profile

---

#### Issue 2: "Invoice Files" Section Doesn't Appear

**Symptoms**: Portal loads but no invoice files section

**Resolution**:
1. Verify invoice has PDF attached:
   ```sql
   SELECT Id FROM ContentDocumentLink
   WHERE LinkedEntityId = '[invoice-id]'
   AND ContentDocument.FileExtension = 'pdf'
   ```
2. Verify ContentDistribution exists:
   ```sql
   SELECT Id FROM ContentDistribution
   WHERE ContentVersionId IN (
       SELECT ContentDocument.LatestPublishedVersionId
       FROM ContentDocumentLink
       WHERE LinkedEntityId = '[invoice-id]'
   )
   ```
3. If missing, run: `ContentDistributionHelper.manageInvoiceContentDistribution()`

---

#### Issue 3: Download Button Doesn't Work

**Symptoms**: Download button present but doesn't download file

**Resolution**:
1. Check ContentDistribution.DistributionPublicUrl is not null
2. Verify ContentDistribution preferences:
   - PreferencesAllowOriginalDownload = true
   - PreferencesAllowPDFDownload = true
   - PreferencesAllowViewInBrowser = true
3. Check browser console for JavaScript errors
4. Try opening URL directly in browser

---

#### Issue 4: Trigger Doesn't Fire

**Symptoms**: New invoices don't get ContentDistribution automatically

**Resolution**:
1. Verify InvoiceTrigger is active
2. Check InvoiceTriggerHandler is calling ContentDistributionHelper
3. Check debug logs for trigger execution
4. Manually run: `update [invoice-record]` to trigger afterUpdate

---

### Contact & Support

**Technical Owner**: Migration Team
**Deployment Lead**: TBD
**Issue Tracking**: [Project Management Tool]

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Ready for Deployment
