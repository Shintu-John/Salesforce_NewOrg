# SmartWaste New Site Setup - Configuration Guide

**Scenario Type:** Configuration (No Code Deployment)
**Priority:** Reference / On-Demand
**Date Created:** October 30, 2025
**Created By:** John Shintu
**Status:** ✅ DOCUMENTED

---

## Executive Summary

This scenario documents the complete process for configuring SmartWaste integration for new accounts/sites in Salesforce. This is a **configuration-only scenario** with no code deployment required - the SmartWaste integration batch job already exists in both OldOrg and NewOrg.

**Use Case:** When a new customer account needs to send waste data to the SmartWaste portal, this guide provides step-by-step configuration requirements and validation criteria.

**Example:** Anchor Construction Logistics - Church End NW10 9EJ site configured to sync waste data to SmartWaste portal under Wates Group account (Request ID: ##922##)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Configuration Requirements](#configuration-requirements)
3. [Formula Field Logic](#formula-field-logic)
4. [Step-by-Step Setup Process](#step-by-step-setup-process)
5. [Validation & Testing](#validation--testing)
6. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
7. [Monitoring Integration](#monitoring-integration)

---

## Prerequisites

### Required Information from Stakeholder

Before starting configuration, collect the following from the SmartWaste portal administrator:

| Information | Example | Purpose |
|------------|---------|---------|
| SmartWaste Project ID | `7197501` | Identifies the site/project in SmartWaste portal |
| SmartWaste Company ID | `20226` | Parent company in SmartWaste (may already exist) |
| SmartWaste Client Key | `fduij4389rdjfgtsd` | Authentication key for API access |
| SmartWaste Private Key | `9fsdjbkgsd8u5t` | Private authentication key for API access |
| SmartWaste Username | `glen.bagshaw` | User account for API authentication |
| Integration Start Date | `2025-10-30` | Only jobs delivered on/after this date will sync |

### Existing Infrastructure

SmartWaste integration relies on these components (already deployed):

**Apex Classes:**
- `SmartWasteIntegrationBatch` - Main batch processing (runs nightly at 00:00 UTC)
- `SmartWasteIntegrationMiddleware` - API callout handler
- `SmartWasteIntegrationFlowHandler` - Flow integration support
- `SmartWasteIntegrationHexFormBuilder` - Form data builder

**Custom Objects:**
- `SmartWaste_Integration_Log__c` - Error tracking and validation logs

**Scheduled Jobs:**
- `SmartWaste_Integration-10` - Runs daily at 00:00 UTC
- `SmartWaste Log Cleanup` - Cleans old logs daily at 08:00 UTC

**Custom Metadata:**
- `Waste_Type__mdt` - Maps EWC codes to SmartWaste IDs and routes

---

## Configuration Requirements

### Account Level Configuration

Configure the following fields on the **Account** record:

| Field API Name | Type | Required | Notes |
|----------------|------|----------|-------|
| `SmartWaste_Company_Id__c` | Text | ✅ Yes | Company ID from SmartWaste portal |
| `SmartWaste_Client_Key__c` | Text | ✅ Yes | API authentication key |
| `SmartWaste_Private_Key__c` | Text | ✅ Yes | Private API key |
| `SmartWaste_Username__c` | Text | ✅ Yes | SmartWaste portal username |
| `SmartWaste_JobStartDate__c` | Date | ⚠️ Recommended | Only jobs delivered on/after this date sync. Leave blank to sync ALL jobs |

**Example:**
```javascript
Account: Anchor Construction Logistics
- SmartWaste_Company_Id__c = "20226"
- SmartWaste_Client_Key__c = "fduij4389rdjfgtsd"
- SmartWaste_Private_Key__c = "9fsdjbkgsd8u5t"
- SmartWaste_Username__c = "glen.bagshaw"
- SmartWaste_JobStartDate__c = 2025-10-30
```

### Site Level Configuration

Configure the following fields on the **Site__c** record:

| Field API Name | Type | Required | Notes |
|----------------|------|----------|-------|
| `SmartWaste_Id__c` | Text | ✅ Yes | Project ID from SmartWaste portal |

**Example:**
```javascript
Site: Church End NW10 9EJ
- SmartWaste_Id__c = "7197501"
```

**⚠️ Common Issue:** The `SmartWaste_Id__c` field may not be visible on the Site page layout by default.

**Solution:**
1. Go to Setup → Object Manager → Site → Page Layouts
2. Edit the relevant page layout
3. Drag "SmartWaste Id" field onto the layout
4. Save

### Job Level Requirements

Jobs automatically qualify for SmartWaste integration when they meet ALL conditions below. These are evaluated by the `Attempt_Send_to_SmartWaste__c` formula field:

| Requirement | Formula Condition | Notes |
|------------|------------------|-------|
| Account has Company ID | `Account__r.SmartWaste_Company_Id__c <> NULL` | Must be configured |
| Delivery date check | `Delivery_Date__c >= Account__r.SmartWaste_JobStartDate__c` | OR Start Date is blank |
| Site has Project ID | `Site__r.SmartWaste_Id__c <> NULL` | Must be configured |
| Not already synced | `SmartWaste_Id__c = NULL` | No SmartWaste ID means not sent yet |
| Valid status | NOT "Failed", "Wasted Journey", or "Cancelled" | Active jobs only |
| Collection in past | `Collection_Date__c < TODAY()` | Job must be collected |

---

## Formula Field Logic

### Attempt_Send_to_SmartWaste__c Formula

This calculated boolean field controls whether a job is eligible for SmartWaste integration:

```apex
AND(
  Account__r.SmartWaste_Company_Id__c <> NULL,
  OR(
    ISBLANK(Account__r.SmartWaste_JobStartDate__c),
    Delivery_Date__c >= Account__r.SmartWaste_JobStartDate__c
  ),
  Site__r.SmartWaste_Id__c <> NULL,
  SmartWaste_Id__c = NULL,
  NOT(ISPICKVAL(Status__c, "Failed")),
  NOT(ISPICKVAL(Status__c, "Wasted Journey")),
  NOT(ISPICKVAL(Status__c, "Cancelled")),
  Collection_Date__c < TODAY()
)
```

**Field Properties:**
- **Type:** Formula (Checkbox)
- **Updateable:** No (read-only, auto-calculated)
- **Dependencies:** Account SmartWaste fields, Site SmartWaste_Id__c, Job status/dates

### Batch Job Query Criteria

When the nightly batch runs, it queries jobs with:

```sql
WHERE Site__r.Account__r.SmartWaste_Private_Key__c != ''
  AND Site__r.Account__r.SmartWaste_Client_Key__c != ''
  AND SMS_Job_Id__c = ''
  AND SMS_Job_Duplicated__c = false
  AND (Status__c = 'Collected' OR Status__c = 'Paperwork Provided' OR Status__c = 'Completed')
  AND SmartWaste_Id__c = null
  AND Attempt_Send_to_SmartWaste__c = true
```

**Reference:** [SmartWasteIntegrationBatch.cls lines 42-72](../12-smartwaste-integration/fixed-code/SmartWasteIntegrationBatch.cls)

---

## Step-by-Step Setup Process

### Step 1: Verify SmartWaste Portal Configuration

**Before configuring Salesforce**, confirm with the SmartWaste administrator:

1. ✅ Project/Site exists in SmartWaste portal
2. ✅ Project is linked to the correct Company
3. ✅ API credentials are active and valid
4. ✅ You have the Project ID number

### Step 2: Configure Account Record

**Option A: Via UI**
1. Navigate to the Account record
2. Click Edit
3. Fill in SmartWaste fields:
   - SmartWaste Company Id
   - SmartWaste Client Key
   - SmartWaste Private Key
   - SmartWaste Username
   - SmartWaste Job Start Date (optional, defaults to "all jobs")
4. Save

**Option B: Via Data Loader / CLI**
```bash
sf data update record \
  --sobject Account \
  --record-id 001Sj00000By98eIAB \
  --values "SmartWaste_Company_Id__c=20226,SmartWaste_Client_Key__c=fduij4389rdjfgtsd,SmartWaste_Private_Key__c=9fsdjbkgsd8u5t,SmartWaste_Username__c=glen.bagshaw,SmartWaste_JobStartDate__c=2025-10-30" \
  --target-org OldOrg
```

### Step 3: Configure Site Record

**Option A: Via UI (if field is on layout)**
1. Navigate to the Site record
2. Click Edit
3. Enter SmartWaste Id (Project ID from portal)
4. Save

**Option B: Via Data Loader / CLI**
```bash
sf data update record \
  --sobject Site__c \
  --record-id a1dSj000000Zie5IAC \
  --values "SmartWaste_Id__c=7197501" \
  --target-org OldOrg
```

**Option C: If field not visible on layout**
1. Add field to page layout (see Configuration Requirements section above)
2. Then use Option A

### Step 4: Verify Configuration

Run this SOQL query to confirm setup:

```sql
SELECT Id, Name,
       Account__r.SmartWaste_Company_Id__c,
       Account__r.SmartWaste_Client_Key__c,
       Account__r.SmartWaste_Username__c,
       Account__r.SmartWaste_JobStartDate__c,
       SmartWaste_Id__c
FROM Site__c
WHERE Id = 'YOUR_SITE_ID'
```

**Expected Results:**
- All Account SmartWaste fields populated
- Site SmartWaste_Id__c populated
- No null values in critical fields

### Step 5: Test with Sample Job

Query a recent completed job to check if it's now eligible:

```sql
SELECT Id, Name, Status__c,
       Delivery_Date__c,
       Collection_Date__c,
       Attempt_Send_to_SmartWaste__c,
       Site__r.SmartWaste_Id__c,
       Account__r.SmartWaste_Company_Id__c
FROM Job__c
WHERE Site__c = 'YOUR_SITE_ID'
  AND Status__c IN ('Collected', 'Completed', 'Paperwork Provided')
  AND Delivery_Date__c >= [ACCOUNT_START_DATE]
ORDER BY CreatedDate DESC
LIMIT 5
```

**Expected Result:**
- `Attempt_Send_to_SmartWaste__c = true` (if job meets all formula criteria)
- `Attempt_Send_to_SmartWaste__c = false` (if delivery date before start date, or other condition fails)

---

## Validation & Testing

### Job Validation Requirements

When the batch job runs, it validates each job using `SmartWasteIntegrationBatch.validateJob()`. Jobs must meet ALL these criteria:

**Critical Requirements:**

| Field | Validation | Error Message |
|-------|-----------|---------------|
| Collection_Date__c | Must be >= Account Start Date | "Job > Collection Date cannot be before than [START_DATE]" |
| Site__r.SmartWaste_Id__c | Must be populated | "Job > Site > SmartWasteId (ProjectId) cannot be empty" |
| Paperwork_Done__c | Must be `true` | "Job > Paperwork Done was unchecked" |
| Weight__c | Must be populated | "Job > Weight cannot be empty" |
| Depot_Dispose__c | Must be populated | "Job > Depot Dispose cannot be empty" |
| Supplier__c | Must be populated | "Job > Supplier cannot be empty" |
| ProductPercentage__c | Must be populated | "Job > Product Percentage cannot be empty" |
| Container_Counter__c | Must be populated | "Job > Container Count cannot be empty" |
| Order_Product__r.Product2.SmartWaste_Id__c | Must be populated | "Job > Order Product > Product > SmartWasteId cannot be empty (Will be used for skip size)" |
| Status__c | Must be Collected, Paperwork Provided, or Completed | "Job > Status can only be Collected, Paperwork Provided and Completed" |

**Depot Requirements (if Depot has no SmartWaste_Id__c):**

| Field | Required |
|-------|----------|
| Depot_Dispose__r.Street__c | Yes |
| Depot_Dispose__r.City__c | Yes |
| Depot_Dispose__r.PostCode__c | Yes |
| Depot_Dispose__r.Permit_Reference__c | Yes |
| Depot_Dispose__r.Registered_Date__c | Yes |
| Depot_Dispose__r.Expiry_Date__c | Must be >= TODAY |

**Supplier Requirements (if Supplier has no SmartWaste_Id__c):**

| Field | Required |
|-------|----------|
| Supplier__r.BillingStreet | Yes |
| Supplier__r.BillingCity | Yes |
| Supplier__r.BillingPostalCode | Yes |
| Supplier__r.Waste_Carriers_License_number__c | Yes |
| Supplier__r.Waste_Carriers_License_Date__c | Yes |
| Supplier__r.Waste_Carriers_Issue_Date__c | Yes |

**Required Paperwork (if applicable):**

| Field | Condition | Required |
|-------|-----------|----------|
| WTN_ContentDistribution_Id__c OR Consignment_Note_ContentDistribution_Id__c | If Required_Paperwork__c contains 'WTN' | Yes |
| DOC_ContentDistribution_Id__c | If Required_Paperwork__c contains 'ADOC' | Yes |

**Reference:** [SmartWasteIntegrationBatch.cls lines 395-530](../12-smartwaste-integration/fixed-code/SmartWasteIntegrationBatch.cls)

### Manual Test Procedure

1. **Check Job Eligibility:**
   ```sql
   SELECT COUNT(Id) EligibleJobs
   FROM Job__c
   WHERE Site__c = 'YOUR_SITE_ID'
     AND Attempt_Send_to_SmartWaste__c = true
     AND SmartWaste_Id__c = null
   ```
   Expected: At least 1 job ready to sync

2. **Run Test Batch (Optional):**
   ```apex
   // Execute Anonymous Apex
   Database.executeBatch(new SmartWasteIntegrationBatch(null), 10);
   ```
   This will process up to 10 jobs immediately (don't wait for midnight)

3. **Check Integration Logs:**
   ```sql
   SELECT Id, Name, Description__c, CreatedDate
   FROM SmartWaste_Integration_Log__c
   WHERE Related_Site__c = 'YOUR_SITE_ID'
   ORDER BY CreatedDate DESC
   LIMIT 10
   ```
   Expected: No error logs (or logs showing what's missing)

4. **Verify Successful Sync:**
   ```sql
   SELECT Id, Name, SmartWaste_Id__c, Collection_Date__c
   FROM Job__c
   WHERE Site__c = 'YOUR_SITE_ID'
     AND SmartWaste_Id__c != null
   ORDER BY CreatedDate DESC
   LIMIT 5
   ```
   Expected: Jobs now have SmartWaste_Id__c populated

---

## Common Issues & Troubleshooting

### Issue 1: Jobs Not Showing `Attempt_Send_to_SmartWaste__c = true`

**Symptoms:**
- Site and Account configured correctly
- Jobs are Completed/Collected status
- But `Attempt_Send_to_SmartWaste__c = false`

**Diagnosis Checklist:**

| Check | SOQL Query | Expected |
|-------|-----------|----------|
| Site has Project ID | `SELECT SmartWaste_Id__c FROM Site__c WHERE Id = 'SITE_ID'` | Not null |
| Account has Company ID | `SELECT SmartWaste_Company_Id__c FROM Account WHERE Id = 'ACCOUNT_ID'` | Not null |
| Delivery date valid | `SELECT Delivery_Date__c, Account__r.SmartWaste_JobStartDate__c FROM Job__c WHERE Id = 'JOB_ID'` | Delivery >= Start Date |
| Collection date in past | `SELECT Collection_Date__c FROM Job__c WHERE Id = 'JOB_ID'` | < TODAY |
| Status valid | `SELECT Status__c FROM Job__c WHERE Id = 'JOB_ID'` | Not Failed/Cancelled/Wasted Journey |
| Not already synced | `SELECT SmartWaste_Id__c FROM Job__c WHERE Id = 'JOB_ID'` | null |

**Common Causes:**

1. **Delivery Date Before Start Date**
   - **Symptom:** Historical jobs with delivery dates before `SmartWaste_JobStartDate__c`
   - **Solution:**
     - Option A: Set `SmartWaste_JobStartDate__c = null` to include all jobs
     - Option B: Set `SmartWaste_JobStartDate__c` to earlier date (e.g., first of month)

2. **Collection Date Empty or Future**
   - **Symptom:** `Collection_Date__c = null` or `Collection_Date__c >= TODAY()`
   - **Solution:** Update job with actual collection date in the past

3. **Site Missing Project ID**
   - **Symptom:** `Site__r.SmartWaste_Id__c = null`
   - **Solution:** Follow Step 3 in setup process to add Project ID

### Issue 2: Jobs Fail Validation (Integration Logs Created)

**Symptoms:**
- Jobs have `Attempt_Send_to_SmartWaste__c = true`
- But SmartWaste_Integration_Log__c records are created
- Jobs don't get `SmartWaste_Id__c` populated

**Diagnosis:**
```sql
SELECT Description__c
FROM SmartWaste_Integration_Log__c
WHERE Related_Job__c = 'JOB_ID'
ORDER BY CreatedDate DESC
LIMIT 1
```

**Common Error Messages & Solutions:**

| Error | Cause | Solution |
|-------|-------|----------|
| "Job > Paperwork Done was unchecked" | `Paperwork_Done__c = false` | Check and complete all required paperwork |
| "Job > Weight cannot be empty" | `Weight__c = null` | Add weighbridge ticket data |
| "Job > Product Percentage cannot be empty" | `ProductPercentage__c = null` | Populate product percentage field |
| "Job > Order Product > Product > SmartWasteId cannot be empty" | Product not mapped to SmartWaste | Update Product2 record with SmartWaste_Id__c |
| "Job > Supplier > Waste Carrier License Date cannot be empty" | Missing supplier license | Update supplier Account with license details |
| "Job > Depot Dispose > Street cannot be empty" | Incomplete depot address | Complete depot Site__c address fields |

**Detailed Validation Requirements:** See [Validation & Testing](#validation--testing) section above

### Issue 3: SmartWaste_Id__c Field Not Visible on Site UI

**Symptom:**
- Cannot find "SmartWaste Id" field when editing Site record
- Field exists in object (can query it)

**Root Cause:**
- Field not added to Site page layout

**Solution:**
1. Go to Setup → Object Manager → Site
2. Click "Page Layouts"
3. Edit the relevant page layout (usually "Site Layout")
4. Find "SmartWaste Id" in the field list
5. Drag it to the desired section on the layout
6. Save

### Issue 4: Shared SmartWaste Client Key - Data Appears Under Wrong Account

**Symptom:**
- Multiple accounts share the same `SmartWaste_Client_Key__c`
- All data appears under one account in SmartWaste portal

**Explanation:**
- This is **BY DESIGN** in some scenarios
- Example: Anchor Construction Logistics shares Client Key with Wates Group
- All Anchor data appears under Wates in SmartWaste portal

**Solution:**
- If this is intentional: No action needed
- If accounts should be separate: Obtain separate Client Keys from SmartWaste portal administrator

**Example from Request ##922##:**
```
Anchor Construction Logistics (001Sj00000By98eIAB)
  SmartWaste_Client_Key__c = "fduij4389rdjfgtsd"

WATES CONSTRUCTION LIMITED (0014H00002HgDgXQAV)
  SmartWaste_Client_Key__c = "fduij4389rdjfgtsd"

Result: Both accounts' data appears under Wates in SmartWaste portal
```

---

## Monitoring Integration

### Real-Time Monitoring Queries

**1. Check Jobs Queued for Next Batch:**
```sql
SELECT Id, Name, Status__c, Site__r.Name, Collection_Date__c
FROM Job__c
WHERE Attempt_Send_to_SmartWaste__c = true
  AND SmartWaste_Id__c = null
ORDER BY Site__r.Account__r.Name, Collection_Date__c DESC
```

**2. Check Recent Integration Errors:**
```sql
SELECT Id, Name, Description__c, Related_Job__r.Name,
       Related_Site__r.Name, Related_Account__r.Name, CreatedDate
FROM SmartWaste_Integration_Log__c
WHERE CreatedDate = TODAY
ORDER BY CreatedDate DESC
LIMIT 50
```

**3. Check Successfully Synced Jobs Today:**
```sql
SELECT Id, Name, SmartWaste_Id__c, Site__r.Name,
       Collection_Date__c, LastModifiedDate
FROM Job__c
WHERE SmartWaste_Id__c != null
  AND LastModifiedDate = TODAY
ORDER BY LastModifiedDate DESC
```

**4. Monitor Specific Site Progress:**
```sql
SELECT
  COUNT(Id) TotalJobs,
  SUM(CASE WHEN SmartWaste_Id__c != null THEN 1 ELSE 0 END) SyncedJobs,
  SUM(CASE WHEN Attempt_Send_to_SmartWaste__c = true AND SmartWaste_Id__c = null THEN 1 ELSE 0 END) PendingJobs
FROM Job__c
WHERE Site__c = 'YOUR_SITE_ID'
  AND Status__c IN ('Collected', 'Completed', 'Paperwork Provided')
```

### Integration Performance Dashboard (Recommended)

Create a Salesforce Report with these fields:

**Report Type:** Jobs with Sites
**Filters:**
- Status = Collected, Completed, Paperwork Provided
- Collection Date >= Last 90 Days

**Grouping:**
- Primary: Site > Account > Name
- Secondary: Attempt Send to SmartWaste (true/false)

**Summary Fields:**
- Count of Jobs
- Count of Jobs with SmartWaste Id
- Sum of Weight

### Email Notifications

The batch job sends an email summary after each run to: `dincer.uyav@vesium.com`

**Email Contents:**
- Successful Count: Number of jobs successfully sent
- Failed Count: Number of jobs that failed validation
- Link to SmartWaste Integration Log list view

**Reference:** [SmartWasteIntegrationBatch.cls lines 373-392](../12-smartwaste-integration/fixed-code/SmartWasteIntegrationBatch.cls)

---

## Related Documentation

### In This Repository

- [12-smartwaste-integration/DEPLOYMENT_HISTORY.md](../12-smartwaste-integration/DEPLOYMENT_HISTORY.md) - Recent SmartWaste validation bug fix (Oct 29, 2025)
- [12-smartwaste-integration/fixed-code/SmartWasteIntegrationBatch.cls](../12-smartwaste-integration/fixed-code/SmartWasteIntegrationBatch.cls) - Batch job source code

### In Backup/Analysis

- [SMARTWASTE_INTEGRATION_ANALYSIS_2025-10-14.md](../../Backup/Completed_Scenarios/Analysis/SMARTWASTE_INTEGRATION_ANALYSIS_2025-10-14.md) - Comprehensive analysis of integration errors and common issues

### Key Reference Links

- **SmartWaste Integration Log List View:** `https://[ORG_DOMAIN]/lightning/o/SmartWaste_Integration_Log__c/list`
- **Scheduled Jobs:** Setup → Scheduled Jobs → Search "SmartWaste"
- **Batch Job Apex Class:** Setup → Apex Classes → SmartWasteIntegrationBatch

---

## Example: Anchor Construction Logistics Setup

**Request ID:** ##922##
**Date:** October 30, 2025
**Stakeholder:** Jan Ward

### Configuration Applied

**Account: Anchor Construction Logistics (001Sj00000By98eIAB)**
```
SmartWaste_Company_Id__c = "20226"
SmartWaste_Client_Key__c = "fduij4389rdjfgtsd"
SmartWaste_Private_Key__c = "9fsdjbkgsd8u5t"
SmartWaste_Username__c = "glen.bagshaw"
SmartWaste_JobStartDate__c = 2025-10-30
```

**Site: Church End NW10 9EJ (a1dSj000000Zie5IAC)**
```
SmartWaste_Id__c = "7197501"
```

**Site: Wates Site Office, Eric Road (a1d8e000000QOQCAA4)**
```
SmartWaste_Id__c = "7197501"
```

### Result

- Both sites at Church End NW10 9EJ now linked to SmartWaste Project 7197501
- Jobs delivered from October 30, 2025 onwards will automatically sync nightly
- Data appears in SmartWaste portal under Wates Group (shared Client Key)
- Historical jobs (before Oct 30) excluded from sync (by design)

### Commands Used

```bash
# Update Anchor Church End site
sf data update record \
  --sobject Site__c \
  --record-id a1dSj000000Zie5IAC \
  --values "SmartWaste_Id__c=7197501" \
  --target-org OldOrg

# Update Wates Church End site
sf data update record \
  --sobject Site__c \
  --record-id a1d8e000000QOQCAA4 \
  --values "SmartWaste_Id__c=7197501" \
  --target-org OldOrg
```

### Verification

```sql
SELECT Id, Name, Account__r.Name, SmartWaste_Id__c
FROM Site__c
WHERE Id IN ('a1dSj000000Zie5IAC', 'a1d8e000000QOQCAA4')
```

**Result:**
```
ID                 NAME                          ACCOUNT__R.NAME               SMARTWASTE_ID__C
a1d8e000000QOQCAA4 Wates Site Office, Eric Road  WATES CONSTRUCTION LIMITED    7197501
a1dSj000000Zie5IAC Church End NW10 9EJ           Anchor Construction Logistics 7197501
```

---

## Appendix: Field Reference

### Account Object - SmartWaste Fields

| Field API Name | Label | Type | Length | Required |
|----------------|-------|------|--------|----------|
| SmartWaste_Company_Id__c | SmartWaste Company Id | Text | 255 | Yes |
| SmartWaste_Client_Key__c | SmartWaste Client Key | Text | 255 | Yes |
| SmartWaste_Private_Key__c | SmartWaste Private Key | Text | 255 | Yes |
| SmartWaste_Username__c | SmartWaste Username | Text | 255 | Yes |
| SmartWaste_JobStartDate__c | SmartWaste Job Start Date | Date | - | Recommended |

### Site__c Object - SmartWaste Fields

| Field API Name | Label | Type | Length | Required |
|----------------|-------|------|--------|----------|
| SmartWaste_Id__c | SmartWaste Id | Text | 255 | Yes |

### Job__c Object - SmartWaste Fields

| Field API Name | Label | Type | Formula | Notes |
|----------------|-------|------|---------|-------|
| Attempt_Send_to_SmartWaste__c | Attempt Send to SmartWaste | Checkbox | Yes | Auto-calculated, read-only |
| SmartWaste_Id__c | SmartWaste Id | Text | No | Populated after successful sync |

---

## Support

**Created By:** John Shintu
**Email:** shintu.john@recyclinglives-services.com
**Last Updated:** October 30, 2025

For questions or issues with SmartWaste integration setup, contact John Shintu or refer to the [Common Issues & Troubleshooting](#common-issues--troubleshooting) section above.
