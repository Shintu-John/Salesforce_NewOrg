# SmartWaste New Site Configuration Checklist

**Purpose:** Step-by-step checklist for configuring SmartWaste integration for a new account/site
**Created:** October 30, 2025
**Created By:** John Shintu

---

## Pre-Configuration Checklist

### Information Gathering

Before starting, collect the following information:

- [ ] **SmartWaste Project ID** (from SmartWaste portal admin)
  - Example: `7197501`
  - Where to find: SmartWaste portal → Projects/Sites section

- [ ] **SmartWaste Company ID** (if new company)
  - Example: `20226`
  - Check if account already exists in Salesforce with Company ID

- [ ] **SmartWaste Client Key** (if new company)
  - Example: `fduij4389rdjfgtsd`
  - API authentication key

- [ ] **SmartWaste Private Key** (if new company)
  - Example: `9fsdjbkgsd8u5t`
  - Private API key

- [ ] **SmartWaste Username** (if new company)
  - Example: `glen.bagshaw`
  - SmartWaste portal username

- [ ] **Integration Start Date**
  - Example: `2025-10-30`
  - Only jobs delivered on/after this date will sync
  - Leave blank to sync ALL jobs (including historical)

### Verify SmartWaste Portal Setup

Contact SmartWaste portal administrator to confirm:

- [ ] Project/Site exists in SmartWaste portal
- [ ] Project is linked to correct Company
- [ ] API credentials are active and valid
- [ ] Project ID number confirmed

---

## Configuration Steps

### Step 1: Account Configuration

Navigate to Account record and populate SmartWaste fields:

- [ ] Open Account record in Salesforce
  - Account Name: `_______________________`
  - Account ID: `_______________________`

- [ ] Click Edit button

- [ ] Fill in SmartWaste fields:
  - [ ] **SmartWaste Company Id**: `_______________________`
  - [ ] **SmartWaste Client Key**: `_______________________`
  - [ ] **SmartWaste Private Key**: `_______________________`
  - [ ] **SmartWaste Username**: `_______________________`
  - [ ] **SmartWaste Job Start Date**: `_______________________` (or leave blank)

- [ ] Click Save

- [ ] Verify saved values (refresh page and check)

**CLI Alternative:**
```bash
sf data update record \
  --sobject Account \
  --record-id [ACCOUNT_ID] \
  --values "SmartWaste_Company_Id__c=[COMPANY_ID],SmartWaste_Client_Key__c=[CLIENT_KEY],SmartWaste_Private_Key__c=[PRIVATE_KEY],SmartWaste_Username__c=[USERNAME],SmartWaste_JobStartDate__c=[START_DATE]" \
  --target-org [ORG_ALIAS]
```

### Step 2: Site Configuration

Navigate to Site record and add SmartWaste Project ID:

- [ ] Open Site record in Salesforce
  - Site Name: `_______________________`
  - Site ID: `_______________________`

- [ ] Check if "SmartWaste Id" field is visible on page layout
  - [ ] **If YES**: Proceed to next step
  - [ ] **If NO**: Add field to page layout first (see Step 2a below)

- [ ] Click Edit button

- [ ] Fill in SmartWaste field:
  - [ ] **SmartWaste Id**: `_______________________` (Project ID from portal)

- [ ] Click Save

- [ ] Verify saved value (refresh page and check)

**CLI Alternative:**
```bash
sf data update record \
  --sobject Site__c \
  --record-id [SITE_ID] \
  --values "SmartWaste_Id__c=[PROJECT_ID]" \
  --target-org [ORG_ALIAS]
```

#### Step 2a: Add SmartWaste Id Field to Site Page Layout (If Needed)

- [ ] Go to Setup → Object Manager → Site
- [ ] Click "Page Layouts"
- [ ] Click "Edit" next to the relevant page layout
- [ ] Find "SmartWaste Id" in the field list (left side)
- [ ] Drag "SmartWaste Id" to desired section on layout
- [ ] Click Save
- [ ] Return to Step 2 to populate the field

---

## Verification Steps

### Step 3: Verify Configuration

Run SOQL queries to confirm setup:

**Query 1: Verify Account Configuration**
```sql
SELECT Id, Name,
       SmartWaste_Company_Id__c,
       SmartWaste_Client_Key__c,
       SmartWaste_Private_Key__c,
       SmartWaste_Username__c,
       SmartWaste_JobStartDate__c
FROM Account
WHERE Id = '[ACCOUNT_ID]'
```

**Expected Results:**
- [ ] SmartWaste_Company_Id__c is populated
- [ ] SmartWaste_Client_Key__c is populated
- [ ] SmartWaste_Private_Key__c is populated
- [ ] SmartWaste_Username__c is populated
- [ ] SmartWaste_JobStartDate__c is populated (or intentionally blank)

**Query 2: Verify Site Configuration**
```sql
SELECT Id, Name, SmartWaste_Id__c,
       Account__r.SmartWaste_Company_Id__c,
       Account__r.SmartWaste_Username__c
FROM Site__c
WHERE Id = '[SITE_ID]'
```

**Expected Results:**
- [ ] SmartWaste_Id__c is populated (Project ID)
- [ ] Account SmartWaste fields are all populated

### Step 4: Check Job Eligibility

Run query to see if any jobs are now eligible for sync:

```sql
SELECT Id, Name, Status__c,
       Delivery_Date__c,
       Collection_Date__c,
       Attempt_Send_to_SmartWaste__c,
       SmartWaste_Id__c
FROM Job__c
WHERE Site__c = '[SITE_ID]'
  AND Status__c IN ('Collected', 'Completed', 'Paperwork Provided')
ORDER BY Delivery_Date__c DESC
LIMIT 10
```

**Expected Results:**
- [ ] At least one job shows `Attempt_Send_to_SmartWaste__c = true`
- [ ] Jobs with Delivery_Date__c >= Start Date have `Attempt_Send_to_SmartWaste__c = true`
- [ ] Jobs with Delivery_Date__c < Start Date have `Attempt_Send_to_SmartWaste__c = false` (if start date set)

**If all jobs show `Attempt_Send_to_SmartWaste__c = false`:**

Check the formula conditions one by one:

```sql
SELECT Id, Name,
       -- Formula conditions breakdown:
       Account__r.SmartWaste_Company_Id__c, -- Must be populated
       Site__r.SmartWaste_Id__c, -- Must be populated
       Delivery_Date__c, -- Must be >= Start Date
       Account__r.SmartWaste_JobStartDate__c, -- Or must be blank
       Collection_Date__c, -- Must be < TODAY
       Status__c, -- Must not be Failed/Wasted/Cancelled
       SmartWaste_Id__c, -- Must be null (not already synced)
       Attempt_Send_to_SmartWaste__c -- Final result
FROM Job__c
WHERE Site__c = '[SITE_ID]'
ORDER BY Delivery_Date__c DESC
LIMIT 5
```

**Troubleshooting:**
- [ ] If `Delivery_Date__c < SmartWaste_JobStartDate__c`: Set start date earlier or to null
- [ ] If `Collection_Date__c = null`: Jobs need collection dates
- [ ] If `Collection_Date__c >= TODAY()`: Jobs must be collected in the past
- [ ] If Status = Failed/Wasted/Cancelled: Status prevents sync

---

## Testing Steps

### Step 5: Job Validation Check (Optional)

For jobs showing `Attempt_Send_to_SmartWaste__c = true`, verify they will pass validation:

```sql
SELECT Id, Name,
       Paperwork_Done__c,
       Weight__c,
       ProductPercentage__c,
       Supplier__c,
       Depot_Dispose__c,
       Container_Counter__c,
       Order_Product__r.Product2.SmartWaste_Id__c
FROM Job__c
WHERE Site__c = '[SITE_ID]'
  AND Attempt_Send_to_SmartWaste__c = true
  AND SmartWaste_Id__c = null
LIMIT 5
```

**Validation Checklist (per job):**
- [ ] `Paperwork_Done__c = true`
- [ ] `Weight__c` is populated
- [ ] `ProductPercentage__c` is populated
- [ ] `Supplier__c` is populated
- [ ] `Depot_Dispose__c` is populated
- [ ] `Container_Counter__c` is populated
- [ ] `Order_Product__r.Product2.SmartWaste_Id__c` is populated

**If any field is missing:** Jobs will fail validation and create error logs

### Step 6: Test Batch Job (Optional - Advanced)

Run the batch job manually to test immediately (don't wait for midnight):

**Apex Anonymous:**
```apex
// Process up to 10 jobs for this specific job ID
Database.executeBatch(new SmartWasteIntegrationBatch('[SPECIFIC_JOB_ID]'), 10);
```

**Or for all eligible jobs:**
```apex
// Process all eligible jobs
Database.executeBatch(new SmartWasteIntegrationBatch(null), 10);
```

**Warning:** Only do this in non-production environments or after hours to avoid impacting users.

### Step 7: Monitor Results

Check for integration logs after batch runs (or wait until next morning after midnight batch):

**Query for Errors:**
```sql
SELECT Id, Name, Description__c, Related_Job__r.Name, CreatedDate
FROM SmartWaste_Integration_Log__c
WHERE Related_Site__c = '[SITE_ID]'
  AND CreatedDate = TODAY
ORDER BY CreatedDate DESC
```

**Expected Results:**
- [ ] No error logs (ideal)
- [ ] OR error logs with clear descriptions of missing fields (fix and retry)

**Query for Successful Syncs:**
```sql
SELECT Id, Name, SmartWaste_Id__c, Collection_Date__c, LastModifiedDate
FROM Job__c
WHERE Site__c = '[SITE_ID]'
  AND SmartWaste_Id__c != null
ORDER BY LastModifiedDate DESC
LIMIT 10
```

**Expected Results:**
- [ ] Jobs now have `SmartWaste_Id__c` populated (successfully synced)
- [ ] `LastModifiedDate` shows recent update

---

## Post-Configuration Monitoring

### Daily Monitoring Queries

**1. Jobs Pending Sync:**
```sql
SELECT COUNT(Id) PendingJobs
FROM Job__c
WHERE Site__c = '[SITE_ID]'
  AND Attempt_Send_to_SmartWaste__c = true
  AND SmartWaste_Id__c = null
```

**2. Recent Errors:**
```sql
SELECT COUNT(Id) ErrorCount
FROM SmartWaste_Integration_Log__c
WHERE Related_Site__c = '[SITE_ID]'
  AND CreatedDate = LAST_N_DAYS:7
```

**3. Successful Syncs This Week:**
```sql
SELECT COUNT(Id) SyncedJobs
FROM Job__c
WHERE Site__c = '[SITE_ID]'
  AND SmartWaste_Id__c != null
  AND LastModifiedDate = LAST_N_DAYS:7
```

### SmartWaste Portal Verification

- [ ] Log into SmartWaste portal
- [ ] Navigate to Project/Site: `_______________________`
- [ ] Verify waste data is appearing
- [ ] Check that data is under correct company account
- [ ] Confirm data accuracy (weights, dates, etc.)

---

## Troubleshooting

### Common Issues

#### Issue: `Attempt_Send_to_SmartWaste__c` stays false

**Checklist:**
- [ ] Site has `SmartWaste_Id__c` populated
- [ ] Account has `SmartWaste_Company_Id__c` populated
- [ ] Job `Delivery_Date__c` >= Account `SmartWaste_JobStartDate__c` (or start date is blank)
- [ ] Job `Collection_Date__c` < TODAY()
- [ ] Job `Status__c` not Failed/Wasted/Cancelled
- [ ] Job `SmartWaste_Id__c` is null (not already synced)

**Solution:** Fix the failing condition(s) above

#### Issue: Integration logs show validation errors

**Common Errors:**
- "Paperwork Done was unchecked" → Set `Paperwork_Done__c = true`
- "Weight cannot be empty" → Populate `Weight__c`
- "Product Percentage cannot be empty" → Populate `ProductPercentage__c`
- "Product > SmartWasteId cannot be empty" → Update Product2 record
- "Supplier > Waste Carrier License Date cannot be empty" → Update Supplier Account
- "Depot Dispose > Street cannot be empty" → Update Depot Site record

**Solution:** Fix the field(s) mentioned in error message, job will retry next night

#### Issue: SmartWaste Id field not visible on Site layout

**Solution:**
- Setup → Object Manager → Site → Page Layouts
- Edit relevant page layout
- Drag "SmartWaste Id" field onto layout
- Save

#### Issue: Data appears under wrong account in SmartWaste portal

**Explanation:**
- Multiple Salesforce accounts may share the same `SmartWaste_Client_Key__c`
- All data from accounts with same Client Key appears under one company in portal
- This may be intentional (e.g., Anchor data appears under Wates)

**Solution:**
- If intentional: No action needed
- If not intentional: Obtain separate Client Keys from SmartWaste admin

---

## Sign-Off

### Configuration Completed By

- **Name:** _______________________
- **Date:** _______________________
- **Account Name:** _______________________
- **Site Name:** _______________________
- **SmartWaste Project ID:** _______________________

### Verification Completed

- [ ] All configuration steps completed
- [ ] All verification queries run successfully
- [ ] At least one test job shows `Attempt_Send_to_SmartWaste__c = true`
- [ ] No blocking validation errors found
- [ ] Stakeholder notified of completion
- [ ] SmartWaste portal administrator notified

### Notes

_______________________________________________________________________________________

_______________________________________________________________________________________

_______________________________________________________________________________________

---

**Document Version:** 1.0
**Created:** October 30, 2025
**Created By:** John Shintu
