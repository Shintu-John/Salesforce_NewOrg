# Daily Reminder Emails - NewOrg Migration Plan

**Scenario**: Daily Reminder Emails - Consolidated Two-Tier Reporting System
**Migration Date**: October 22, 2025
**Source**: OldOrg (October 20, 2025 deployment)
**Target**: NewOrg
**Migration Status**: 🔴 **READY FOR DEPLOYMENT**

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Overview](#migration-overview)
3. [Gap Analysis Summary](#gap-analysis-summary)
4. [Pre-Deployment Checklist](#pre-deployment-checklist)
5. [Deployment Phases](#deployment-phases)
6. [Testing and Validation](#testing-and-validation)
7. [Rollback Procedures](#rollback-procedures)
8. [Post-Deployment Monitoring](#post-deployment-monitoring)
9. [Known Issues and Limitations](#known-issues-and-limitations)
10. [Success Criteria](#success-criteria)

---

## Executive Summary

### Business Problem

**Current State (NewOrg)**:
- 133+ individual schedule reminder emails sent daily (outdated Sep 17, 2025 logic)
- No delivery confirmation tracking (Tier 1 missing entirely)
- Schedule reminders sent for jobs WITHOUT confirmed delivery (incorrect business logic)
- Record locking errors during Email-to-Case processing
- Customer Service inbox overwhelmed

**Target State (Post-Migration)**:
- 2 consolidated daily reports (99.6% email reduction: 133+ → 2)
- Tier 1: Delivery Confirmation Report at 8 AM (438 jobs)
- Tier 2: Schedule Creation Report at 9 AM (133 jobs)
- Schedule reminders ONLY for confirmed deliveries
- No record locking errors (staggered schedules)

### Migration Scope

**Components to Deploy**: 4 Apex classes + 2 scheduled jobs
- 2 NEW classes: JobDeliveryConfirmationReminderBatch + test
- 2 UPDATED classes: JobMissingScheduleEmailNotificationBatch + test

**Deployment Method**: Salesforce CLI (sf project deploy)
**Estimated Time**: 2 hours deployment + 24 hours monitoring
**Risk Level**: 🟡 **MEDIUM** (Replacing existing class with updated logic)

---

## Migration Overview

### What Changed Between OldOrg and NewOrg

| Aspect | OldOrg (Oct 20, 2025) | NewOrg (Sep 17, 2025) | Impact |
|--------|----------------------|----------------------|--------|
| **Email Approach** | ✅ Consolidated daily reports | ❌ Individual emails per job | 99.6% email reduction LOST |
| **Tier 1 (Delivery)** | ✅ EXISTS - 8 AM report | ❌ MISSING | No delivery tracking |
| **Tier 2 (Schedule)** | ✅ UPDATED - 9 AM report | ⚠️ OUTDATED logic | Wrong business logic |
| **Delivery Filter** | ✅ `Delivery_Confirmed__c = true` | ❌ No filter | Wrong jobs get reminders |
| **Urgency Categories** | ✅ 4-tier (Critical/High/Med/Recent) | ❌ None | No prioritization |
| **Report Format** | ✅ HTML color-coded tables | ❌ Plain template emails | Poor readability |
| **Scheduled Jobs** | ✅ 2 jobs (8 AM, 9 AM) | ❌ 0 jobs scheduled | No automation |

### Components Summary

**NEW Components (Deploy to NewOrg)**:
1. `JobDeliveryConfirmationReminderBatch.cls` (10,072 lines)
2. `JobDeliveryConfirmationReminderBatchTest.cls` (6,428 lines)

**UPDATED Components (Replace in NewOrg)**:
3. `JobMissingScheduleEmailNotificationBatch.cls` (11,375 lines - was 2,742)
4. `JobMissingScheduleEmailNotificationTest.cls` (2,549 lines - was missing)

**SCHEDULED JOBS (Create in NewOrg)**:
5. JobDeliveryConfirmationReminderBatch at 8 AM (CRON: `0 0 8 ? * 2,3,4,5,6,7`)
6. JobMissingScheduleEmailNotificationBatch at 9 AM (CRON: `0 0 9 ? * 2,3,4,5,6`)

---

## Gap Analysis Summary

### Critical Findings

**Gap Severity**: 🔴 **HIGH** - NewOrg contains outdated implementation with critical business logic errors

**Key Gaps Identified**:

1. **JobDeliveryConfirmationReminderBatch.cls**: ❌ MISSING
   - **Impact**: No Tier 1 (delivery confirmation) report being generated
   - **Expected**: 438 jobs without confirmed delivery should receive daily report at 8 AM
   - **Current**: No tracking at all

2. **JobMissingScheduleEmailNotificationBatch.cls**: ⚠️ OUTDATED (Sep 17, 2025)
   - **Critical Issue**: Missing `Delivery_Confirmed__c = true` filter in SOQL
   - **Impact**: Schedule reminders sent for jobs WITHOUT confirmed delivery (incorrect)
   - **Email Volume**: 133+ individual emails instead of 1 consolidated report
   - **Code Size**: 2,742 lines (old) vs 11,375 lines (new) - complete rewrite

3. **Scheduled Jobs**: ❌ MISSING BOTH
   - **Impact**: No automated daily reports running

**Full Gap Analysis**: See [GAP_ANALYSIS.md](./GAP_ANALYSIS.md)

---

## Pre-Deployment Checklist

### Prerequisites Verification

**Before starting deployment, verify the following in NewOrg**:

#### 1. Custom Fields on Job__c Object

```bash
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Job__c' AND QualifiedApiName IN ('Schedule_Not_Created_Warning__c', 'Delivery_Confirmed__c', 'Delivery_Date__c', 'Schedule__c', 'May_Require_Schedule__c', 'RLES_Standard_Job_Filters__c')" --target-org NewOrg
```

**Expected Result**: 6 fields exist
- `Schedule_Not_Created_Warning__c` (Number) - Reminder counter
- `Delivery_Confirmed__c` (Checkbox) - Delivery confirmation flag
- `Delivery_Date__c` (Date) - Delivery date
- `Schedule__c` (Lookup) - Schedule reference
- `May_Require_Schedule__c` (Checkbox) - Schedule requirement flag
- `RLES_Standard_Job_Filters__c` (Formula) - Standard filters

**Status**: ✅ ⬜ (Check one)

---

#### 2. Custom Label

```bash
sf data query --query "SELECT Name, Value FROM CustomLabel WHERE Name = 'fromaddress_customerservice'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Label exists with value "customerservice@recyclinglives-services.com"

**Status**: ✅ ⬜ (Check one)

---

#### 3. OrgWideEmailAddress

```bash
sf data query --query "SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'customerservice@recyclinglives-services.com'" --target-org NewOrg
```

**Expected Result**: Record exists with Address = customerservice@recyclinglives-services.com

**Status**: ✅ ⬜ (Check one)

---

#### 4. Email Deliverability

```bash
sf org display --target-org NewOrg
```

**Verify**: Email Deliverability = "All email" or "System email only" (NOT "No access")

**Status**: ✅ ⬜ (Check one)

---

#### 5. Test Data Availability

```bash
# Tier 1 candidates (no confirmed delivery)
sf data query --query "SELECT COUNT() FROM Job__c WHERE RLES_Standard_Job_Filters__c = true AND Schedule__c = null AND May_Require_Schedule__c = true AND Delivery_Confirmed__c = false" --target-org NewOrg

# Tier 2 candidates (confirmed delivery)
sf data query --query "SELECT COUNT() FROM Job__c WHERE RLES_Standard_Job_Filters__c = true AND Schedule__c = null AND May_Require_Schedule__c = true AND Delivery_Confirmed__c = true" --target-org NewOrg
```

**Expected Result**:
- Tier 1: ~438 jobs (or similar count)
- Tier 2: ~133 jobs (or similar count)

**Actual Counts**:
- Tier 1: _______ jobs
- Tier 2: _______ jobs

**Status**: ✅ ⬜ (Check one)

---

#### 6. Backup Current State

```bash
# Backup current JobMissingScheduleEmailNotificationBatch (Sep 17 version)
mkdir -p /tmp/Salesforce_NewOrg/daily-reminder-emails/backups
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'JobMissingScheduleEmailNotificationBatch'" --target-org NewOrg --use-tooling-api --json > /tmp/Salesforce_NewOrg/daily-reminder-emails/backups/JobMissingScheduleEmailNotificationBatch_Sep17_2025.json

# Verify backup created
ls -lh /tmp/Salesforce_NewOrg/daily-reminder-emails/backups/
```

**Status**: ✅ ⬜ (Check one)

---

### Pre-Deployment Checklist Summary

| Item | Status | Notes |
|------|--------|-------|
| 1. Custom Fields Verified | ⬜ | |
| 2. Custom Label Verified | ⬜ | |
| 3. OrgWideEmailAddress Verified | ⬜ | |
| 4. Email Deliverability Verified | ⬜ | |
| 5. Test Data Available | ⬜ | |
| 6. Current State Backed Up | ⬜ | |

**Proceed to Deployment**: ⬜ YES (All items checked) / ⬜ NO (Issues to resolve)

---

## Deployment Phases

### Phase 1: Retrieve Source Code from OldOrg

**Objective**: Get the October 20, 2025 version of all 4 Apex classes

**Commands**:

```bash
# Create deployment directory
mkdir -p /tmp/daily-reminder-emails-deployment/force-app/main/default/classes

# Retrieve Tier 1 Batch Class
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'JobDeliveryConfirmationReminderBatch'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatch.cls

# Retrieve Tier 1 Test Class
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'JobDeliveryConfirmationReminderBatchTest'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatchTest.cls

# Retrieve Tier 2 Batch Class
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'JobMissingScheduleEmailNotificationBatch'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobMissingScheduleEmailNotificationBatch.cls

# Retrieve Tier 2 Test Class
sf data query --query "SELECT Body FROM ApexClass WHERE Name = 'JobMissingScheduleEmailNotificationTest'" --target-org OldOrg --use-tooling-api --json | jq -r '.result.records[0].Body' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobMissingScheduleEmailNotificationTest.cls

# Create metadata files (API version 60.0 for Tier 1, 64.0 for Tier 2 test)
echo '<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatch.cls-meta.xml

cp /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatch.cls-meta.xml /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatchTest.cls-meta.xml

cp /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobDeliveryConfirmationReminderBatch.cls-meta.xml /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobMissingScheduleEmailNotificationBatch.cls-meta.xml

echo '<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>64.0</apiVersion>
    <status>Active</status>
</ApexClass>' > /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/JobMissingScheduleEmailNotificationTest.cls-meta.xml

# Create sfdx-project.json
echo '{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "64.0"
}' > /tmp/daily-reminder-emails-deployment/sfdx-project.json

# Verify files created
ls -lh /tmp/daily-reminder-emails-deployment/force-app/main/default/classes/
```

**Expected Result**: 8 files created (4 .cls + 4 .cls-meta.xml)

**Status**: ⬜ COMPLETE

---

### Phase 2: Deploy Test Classes First

**Objective**: Deploy test classes to meet Salesforce 75% coverage requirement

**Why Test Classes First**: Salesforce requires test coverage before deploying production classes. Deploying tests first ensures we can validate the main classes during deployment.

**Commands**:

```bash
# Deploy ONLY test classes
cd /tmp/daily-reminder-emails-deployment

sf project deploy start \
  --source-dir force-app/main/default/classes/JobDeliveryConfirmationReminderBatchTest.cls \
  --source-dir force-app/main/default/classes/JobMissingScheduleEmailNotificationTest.cls \
  --target-org NewOrg \
  --wait 10 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 2
  - JobDeliveryConfirmationReminderBatchTest.cls
  - JobMissingScheduleEmailNotificationTest.cls
```

**Troubleshooting**:
- **Error: "cannot deploy without parent class"**: This is expected if tests reference the main classes. Proceed to Phase 3 to deploy all together.
- **Error: "Invalid cross reference"**: Verify custom fields exist (Pre-Deployment Checklist #1)

**Status**: ⬜ COMPLETE (or ⬜ SKIPPED - deploying all together)

---

### Phase 3: Deploy Batch Classes

**Objective**: Deploy/update main batch classes

**Option A: Deploy All Together (Recommended)**:

```bash
cd /tmp/daily-reminder-emails-deployment

sf project deploy start \
  --source-dir force-app/main/default/classes \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 20 \
  --verbose
```

**Option B: Deploy Individually (If Option A Fails)**:

```bash
# Deploy Tier 1 (Delivery Confirmation) - NEW
sf project deploy start \
  --source-dir force-app/main/default/classes/JobDeliveryConfirmationReminderBatch.cls \
  --source-dir force-app/main/default/classes/JobDeliveryConfirmationReminderBatchTest.cls \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 10 \
  --verbose

# Deploy Tier 2 (Schedule Creation) - UPDATE
sf project deploy start \
  --source-dir force-app/main/default/classes/JobMissingScheduleEmailNotificationBatch.cls \
  --source-dir force-app/main/default/classes/JobMissingScheduleEmailNotificationTest.cls \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 10 \
  --verbose
```

**Expected Result**:
```
Status: Succeeded
Components Deployed: 4
  - JobDeliveryConfirmationReminderBatch.cls
  - JobDeliveryConfirmationReminderBatchTest.cls
  - JobMissingScheduleEmailNotificationBatch.cls
  - JobMissingScheduleEmailNotificationTest.cls

Test Results:
  - JobDeliveryConfirmationReminderBatchTest.testJobDeliveryConfirmationEmailNotificationBatch: PASS
  - JobDeliveryConfirmationReminderBatchTest.testSchedulableInterface: PASS
  - JobMissingScheduleEmailNotificationTest.testJobMissingScheduleEmailNotificationBatch: PASS
  - JobMissingScheduleEmailNotificationTest.testSchedulableInterface: PASS

Code Coverage: 100% (all classes)
```

**Troubleshooting**:
- **Test Failures**: Review test error messages - likely data setup issues or missing fields
- **Coverage < 75%**: Verify test classes deployed correctly
- **Deployment Timeout**: Increase `--wait` to 30 minutes

**Status**: ⬜ COMPLETE

**Deployment ID**: _________________ (Record for rollback)

---

### Phase 4: Verify Deployment Success

**Objective**: Confirm all classes deployed with correct timestamps and line counts

**Commands**:

```bash
# Verify all 4 classes exist in NewOrg
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name, LengthWithoutComments FROM ApexClass WHERE Name IN ('JobDeliveryConfirmationReminderBatch', 'JobDeliveryConfirmationReminderBatchTest', 'JobMissingScheduleEmailNotificationBatch', 'JobMissingScheduleEmailNotificationTest') ORDER BY Name" --target-org NewOrg --use-tooling-api

# Verify test results
sf apex run test --class-names JobDeliveryConfirmationReminderBatchTest --class-names JobMissingScheduleEmailNotificationTest --result-format human --target-org NewOrg
```

**Expected Result**:
- **JobDeliveryConfirmationReminderBatch**: 10,072 lines, LastModifiedDate = TODAY
- **JobDeliveryConfirmationReminderBatchTest**: 6,428 lines, LastModifiedDate = TODAY
- **JobMissingScheduleEmailNotificationBatch**: 11,375 lines, LastModifiedDate = TODAY
- **JobMissingScheduleEmailNotificationTest**: 2,549 lines, LastModifiedDate = TODAY
- **All Tests**: PASS (100% coverage)

**Actual Results**:
- JobDeliveryConfirmationReminderBatch: _______ lines, Date: _____________
- JobDeliveryConfirmationReminderBatchTest: _______ lines, Date: _____________
- JobMissingScheduleEmailNotificationBatch: _______ lines, Date: _____________
- JobMissingScheduleEmailNotificationTest: _______ lines, Date: _____________
- Test Results: ⬜ ALL PASS / ⬜ FAILURES (describe: _________________)

**Status**: ⬜ COMPLETE

---

### Phase 5: Schedule Batch Jobs

**Objective**: Create two scheduled jobs for daily automated reports

#### 5A. Schedule Tier 1 (Delivery Confirmation Report at 8 AM)

**Command**:

```bash
# Create Apex script to schedule the job
cat > /tmp/schedule_tier1.apex << 'EOF'
// Remove any existing scheduled job with same name
List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'JobDeliveryConfirmationReminderBatch at 8AM'];
for(CronTrigger ct : existingJobs) {
    System.abortJob(ct.Id);
    System.debug('Aborted existing job: ' + ct.Id);
}

// Schedule new job
String cronExp = '0 0 8 ? * 2,3,4,5,6,7'; // Daily at 8 AM (Tuesday-Sunday)
String jobId = System.schedule('JobDeliveryConfirmationReminderBatch at 8AM',
                               cronExp,
                               new JobDeliveryConfirmationReminderBatch());
System.debug('Scheduled Tier 1 job with ID: ' + jobId);
EOF

# Execute scheduling
sf apex run --file /tmp/schedule_tier1.apex --target-org NewOrg
```

**Expected Output**: "Scheduled Tier 1 job with ID: [CronTrigger ID]"

**Status**: ⬜ COMPLETE

**Scheduled Job ID**: _________________ (Record for monitoring)

---

#### 5B. Schedule Tier 2 (Schedule Creation Report at 9 AM)

**Command**:

```bash
# Create Apex script to schedule the job
cat > /tmp/schedule_tier2.apex << 'EOF'
// Remove any existing scheduled job with same name
List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'JobMissingScheduleEmailNotificationBatch at 9AM'];
for(CronTrigger ct : existingJobs) {
    System.abortJob(ct.Id);
    System.debug('Aborted existing job: ' + ct.Id);
}

// Schedule new job
String cronExp = '0 0 9 ? * 2,3,4,5,6'; // Daily at 9 AM (Tuesday-Saturday)
String jobId = System.schedule('JobMissingScheduleEmailNotificationBatch at 9AM',
                               cronExp,
                               new JobMissingScheduleEmailNotificationBatch());
System.debug('Scheduled Tier 2 job with ID: ' + jobId);
EOF

# Execute scheduling
sf apex run --file /tmp/schedule_tier2.apex --target-org NewOrg
```

**Expected Output**: "Scheduled Tier 2 job with ID: [CronTrigger ID]"

**Status**: ⬜ COMPLETE

**Scheduled Job ID**: _________________ (Record for monitoring)

---

#### 5C. Verify Scheduled Jobs Created

**Command**:

```bash
sf data query --query "SELECT Id, CronJobDetail.Name, CronExpression, State, NextFireTime, PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE '%Job%Reminder%' OR CronJobDetail.Name LIKE '%Delivery%Confirmation%' ORDER BY CronJobDetail.Name" --target-org NewOrg
```

**Expected Result**: 2 jobs

| Job Name | CRON Expression | State | Next Run Time |
|----------|-----------------|-------|---------------|
| JobDeliveryConfirmationReminderBatch at 8AM | 0 0 8 ? * 2,3,4,5,6,7 | WAITING | Oct 23, 2025 08:00 UTC |
| JobMissingScheduleEmailNotificationBatch at 9AM | 0 0 9 ? * 2,3,4,5,6 | WAITING | Oct 23, 2025 09:00 UTC |

**Actual Results**:
- Tier 1 Job: ⬜ FOUND (Next Run: _____________) / ⬜ NOT FOUND
- Tier 2 Job: ⬜ FOUND (Next Run: _____________) / ⬜ NOT FOUND

**Status**: ⬜ COMPLETE

---

### Phase 6: Manual Test Run (Optional but Recommended)

**Objective**: Execute batch once manually to verify email generation before first scheduled run

#### 6A. Test Tier 1 (Delivery Confirmation Report)

**Command**:

```bash
cat > /tmp/test_tier1.apex << 'EOF'
// Execute batch with batch size 200
Database.executeBatch(new JobDeliveryConfirmationReminderBatch(), 200);
EOF

sf apex run --file /tmp/test_tier1.apex --target-org NewOrg
```

**Expected Result**: Batch job starts, executes, sends email to customerservice@recyclinglives-services.com

**Monitor Batch Job**:
```bash
# Get batch job ID from Apex execution output
sf data query --query "SELECT Id, Status, JobItemsProcessed, NumberOfErrors, CreatedDate FROM AsyncApexJob WHERE ApexClass.Name = 'JobDeliveryConfirmationReminderBatch' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**Check Email Sent**:
- **Recipient**: customerservice@recyclinglives-services.com
- **Subject**: "Daily Delivery Confirmation Report - [X] Jobs Requiring Delivery Confirmation"
- **Content**: HTML report with 4 urgency categories (Critical, High, Medium, Recent)

**Status**: ⬜ COMPLETE / ⬜ SKIPPED

**Email Received**: ⬜ YES (Job count: _______) / ⬜ NO (Issue: _________________)

---

#### 6B. Test Tier 2 (Schedule Creation Report)

**Command**:

```bash
cat > /tmp/test_tier2.apex << 'EOF'
// Execute batch with batch size 200
Database.executeBatch(new JobMissingScheduleEmailNotificationBatch(), 200);
EOF

sf apex run --file /tmp/test_tier2.apex --target-org NewOrg
```

**Expected Result**: Batch job starts, executes, sends email to customerservice@recyclinglives-services.com

**Monitor Batch Job**:
```bash
sf data query --query "SELECT Id, Status, JobItemsProcessed, NumberOfErrors, CreatedDate FROM AsyncApexJob WHERE ApexClass.Name = 'JobMissingScheduleEmailNotificationBatch' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**Check Email Sent**:
- **Recipient**: customerservice@recyclinglives-services.com (To), kaylie.morris@..., lucas.hargreaves@... (CC)
- **Subject**: "Daily Schedule Creation Report - [X] Jobs Requiring Schedules"
- **Content**: HTML report with 4 urgency categories (Critical, High, Medium, Recent)

**Status**: ⬜ COMPLETE / ⬜ SKIPPED

**Email Received**: ⬜ YES (Job count: _______) / ⬜ NO (Issue: _________________)

---

### Deployment Phases Summary

| Phase | Status | Completion Time | Notes |
|-------|--------|-----------------|-------|
| 1. Retrieve Source Code | ⬜ | _____________ | |
| 2. Deploy Test Classes | ⬜ | _____________ | |
| 3. Deploy Batch Classes | ⬜ | _____________ | Deployment ID: _______ |
| 4. Verify Deployment | ⬜ | _____________ | |
| 5. Schedule Jobs | ⬜ | _____________ | 2 jobs scheduled |
| 6. Manual Test Run | ⬜ | _____________ | Optional |

**Overall Deployment Status**: ⬜ SUCCESS / ⬜ PARTIAL / ⬜ FAILED

---

## Testing and Validation

### Unit Testing (Automated)

**Already Completed During Deployment** (Phase 3 - RunLocalTests)

**Test Classes**:
1. JobDeliveryConfirmationReminderBatchTest
2. JobMissingScheduleEmailNotificationTest

**Test Coverage**: 100% (both batch classes)

**Test Results**: ⬜ ALL PASS / ⬜ FAILURES

---

### Integration Testing (Manual)

#### Test Scenario 1: Tier 1 Report Generation

**Objective**: Verify delivery confirmation report contains correct jobs

**Steps**:
1. Query jobs without confirmed delivery:
   ```bash
   sf data query --query "SELECT Id, Name, Account__r.Name, Delivery_Date__c FROM Job__c WHERE RLES_Standard_Job_Filters__c = true AND Schedule__c = null AND May_Require_Schedule__c = true AND Delivery_Confirmed__c = false AND Delivery_Date__c != null ORDER BY Delivery_Date__c LIMIT 10" --target-org NewOrg
   ```
2. Execute Tier 1 batch manually (see Phase 6A)
3. Verify email received with matching job counts
4. Verify jobs categorized correctly by days overdue

**Expected Result**: Email contains jobs from Step 1, categorized by urgency

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 2: Tier 2 Report Generation

**Objective**: Verify schedule creation report contains ONLY confirmed deliveries

**Steps**:
1. Query jobs WITH confirmed delivery:
   ```bash
   sf data query --query "SELECT Id, Name, Account__r.Name, Delivery_Date__c FROM Job__c WHERE RLES_Standard_Job_Filters__c = true AND Schedule__c = null AND May_Require_Schedule__c = true AND Delivery_Confirmed__c = true AND Delivery_Date__c != null ORDER BY Delivery_Date__c LIMIT 10" --target-org NewOrg
   ```
2. Execute Tier 2 batch manually (see Phase 6B)
3. Verify email received with matching job counts
4. **CRITICAL**: Verify NO jobs from Tier 1 appear in Tier 2 report

**Expected Result**: Email contains ONLY jobs with Delivery_Confirmed__c = true

**Actual Result**: ⬜ PASS / ⬜ FAIL (Describe: _________________)

---

#### Test Scenario 3: Reminder Counter Increment

**Objective**: Verify Schedule_Not_Created_Warning__c counter increments daily

**Steps**:
1. Query a job's current reminder count:
   ```bash
   sf data query --query "SELECT Id, Name, Schedule_Not_Created_Warning__c FROM Job__c WHERE RLES_Standard_Job_Filters__c = true AND Schedule__c = null AND May_Require_Schedule__c = true AND Delivery_Confirmed__c = true LIMIT 1" --target-org NewOrg
   ```
2. Execute batch (Tier 2)
3. Re-query same job:
   ```bash
   sf data query --query "SELECT Id, Name, Schedule_Not_Created_Warning__c FROM Job__c WHERE Id = '<JOB_ID>'" --target-org NewOrg
   ```
4. Verify counter increased by 1

**Expected Result**: Counter increments from N to N+1

**Actual Result**: ⬜ PASS (Before: _____, After: _____) / ⬜ FAIL

---

#### Test Scenario 4: Email Recipients

**Objective**: Verify emails sent to correct recipients with correct CC

**Steps**:
1. Execute both batch jobs manually
2. Check Customer Service inbox (customerservice@recyclinglives-services.com)
3. Verify Tier 1 email received (To: Customer Service, NO CC)
4. Verify Tier 2 email received (To: Customer Service, CC: Kaylie Morris, Lucas Hargreaves)

**Expected Result**:
- Tier 1: To only
- Tier 2: To + 2 CC recipients

**Actual Result**:
- Tier 1: ⬜ PASS / ⬜ FAIL (Recipients: _________________)
- Tier 2: ⬜ PASS / ⬜ FAIL (Recipients: _________________)

---

#### Test Scenario 5: Scheduled Job Execution

**Objective**: Verify first scheduled run executes successfully

**Steps**:
1. Wait for first scheduled run (Oct 23, 2025 08:00 UTC for Tier 1)
2. Query batch job execution:
   ```bash
   sf data query --query "SELECT Id, Status, JobItemsProcessed, NumberOfErrors, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name = 'JobDeliveryConfirmationReminderBatch' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
   ```
3. Verify email received
4. Repeat for Tier 2 (09:00 UTC)

**Expected Result**:
- Status: Completed
- NumberOfErrors: 0
- Emails received

**Actual Result**:
- Tier 1: ⬜ PASS (Status: _______, Errors: _______) / ⬜ FAIL
- Tier 2: ⬜ PASS (Status: _______, Errors: _______) / ⬜ FAIL

---

### User Acceptance Testing (UAT)

**Stakeholders**: Customer Service team (Kaylie Morris, Lucas Hargreaves)

**UAT Checklist**:

| Test Case | Expected Result | Actual Result | Status |
|-----------|-----------------|---------------|--------|
| Receive 8 AM delivery report | Email with jobs needing delivery confirmation | | ⬜ |
| Receive 9 AM schedule report | Email with jobs needing schedules (confirmed deliveries only) | | ⬜ |
| Verify urgency categories | Critical (30+ days) highlighted in red | | ⬜ |
| Click job links | Opens Job record in Salesforce | | ⬜ |
| No duplicate emails | Only 2 emails received daily (not 133+) | | ⬜ |
| Email readability | HTML format, color-coded, sortable tables | | ⬜ |

**UAT Sign-Off**: ⬜ APPROVED / ⬜ ISSUES FOUND (Describe: _________________)

---

## Rollback Procedures

### When to Rollback

**Trigger rollback if**:
- ❌ Test failures in production
- ❌ Email delivery failures (OrgWideEmailAddress issues)
- ❌ SOQL governor limit errors
- ❌ Incorrect job categorization (wrong urgency levels)
- ❌ Email volume reduction < 90% (indicates logic issue)
- ❌ Record locking errors persist

### Rollback Steps

#### Step 1: Abort Scheduled Jobs

```bash
# Query scheduled jobs
sf data query --query "SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE '%JobDeliveryConfirmationReminderBatch%' OR CronJobDetail.Name LIKE '%JobMissingScheduleEmailNotificationBatch at 9AM%'" --target-org NewOrg

# Abort jobs (run for each job ID)
cat > /tmp/abort_job.apex << 'EOF'
System.abortJob('<JOB_ID>');
EOF

sf apex run --file /tmp/abort_job.apex --target-org NewOrg
```

**Status**: ⬜ COMPLETE (Jobs aborted: _________________)

---

#### Step 2: Restore Previous Version (If Available)

**Option A: Restore from Backup** (Recommended if backup exists)

```bash
# Deploy old version from backup
sf project deploy start \
  --metadata-dir /tmp/Salesforce_NewOrg/daily-reminder-emails/backups \
  --target-org NewOrg \
  --wait 10
```

**Option B: Delete New Classes and Keep Old** (If old version was complete)

```bash
# Delete Tier 1 classes (NEW - not in old version)
cat > /tmp/delete_tier1.apex << 'EOF'
ApexClass tier1Batch = [SELECT Id FROM ApexClass WHERE Name = 'JobDeliveryConfirmationReminderBatch'];
delete tier1Batch;

ApexClass tier1Test = [SELECT Id FROM ApexClass WHERE Name = 'JobDeliveryConfirmationReminderBatchTest'];
delete tier1Test;
EOF

sf apex run --file /tmp/delete_tier1.apex --target-org NewOrg
```

**Note**: Cannot "rollback" JobMissingScheduleEmailNotificationBatch to Sep 17 version easily. This is why backup is critical.

**Status**: ⬜ COMPLETE / ⬜ N/A (Keeping new version, disabling jobs only)

---

#### Step 3: Verify Rollback Success

```bash
# Verify current state
sf data query --query "SELECT Name, LastModifiedDate FROM ApexClass WHERE Name IN ('JobDeliveryConfirmationReminderBatch', 'JobMissingScheduleEmailNotificationBatch')" --target-org NewOrg --use-tooling-api

# Verify no scheduled jobs
sf data query --query "SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE '%Job%Reminder%'" --target-org NewOrg
```

**Expected Result**:
- Scheduled jobs: 0 records (or old jobs restored)
- Classes: Old versions or deleted

**Status**: ⬜ COMPLETE

---

#### Step 4: Notify Stakeholders

**Communication**:
- Subject: "Daily Reminder Emails Deployment Rollback"
- Recipients: Customer Service, Kaylie Morris, Lucas Hargreaves
- Content: Explain rollback reason, timeline for re-deployment

**Status**: ⬜ COMPLETE

---

### Rollback Decision Log

| Date | Issue | Decision | Executed By | Result |
|------|-------|----------|-------------|--------|
| | | ⬜ ROLLBACK / ⬜ KEEP | | |

---

## Post-Deployment Monitoring

### First 24 Hours (Critical Monitoring)

**Monitoring Schedule**:

| Time (UTC) | Event | Action | Status |
|------------|-------|--------|--------|
| Oct 23, 08:00 | Tier 1 first run | Monitor batch execution, verify email | ⬜ |
| Oct 23, 08:30 | Tier 1 post-run | Check AsyncApexJob status, error logs | ⬜ |
| Oct 23, 09:00 | Tier 2 first run | Monitor batch execution, verify email | ⬜ |
| Oct 23, 09:30 | Tier 2 post-run | Check AsyncApexJob status, error logs | ⬜ |
| Oct 24, 08:00 | Tier 1 second run | Verify consistency, check job counts | ⬜ |
| Oct 24, 09:00 | Tier 2 second run | Verify consistency, check job counts | ⬜ |

---

### Monitoring Queries

#### Query 1: Batch Job Execution Status

```bash
sf data query --query "SELECT Id, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name IN ('JobDeliveryConfirmationReminderBatch', 'JobMissingScheduleEmailNotificationBatch') AND CreatedDate = TODAY ORDER BY CreatedDate DESC" --target-org NewOrg
```

**Run Frequency**: After each scheduled execution (08:30 and 09:30 UTC daily)

**Expected Result**: Status = Completed, NumberOfErrors = 0

---

#### Query 2: Email Sent Count

```bash
sf data query --query "SELECT Id, Subject, Status, CreatedDate FROM EmailMessage WHERE Subject LIKE '%Daily%Report%' AND CreatedDate = TODAY ORDER BY CreatedDate DESC" --target-org NewOrg
```

**Run Frequency**: Daily at 10:00 UTC (after both jobs run)

**Expected Result**: 2 emails (Tier 1 at 08:00, Tier 2 at 09:00)

---

#### Query 3: Job Reminder Counter Updates

```bash
sf data query --query "SELECT COUNT() FROM Job__c WHERE Schedule_Not_Created_Warning__c != null AND LastModifiedDate = TODAY" --target-org NewOrg
```

**Run Frequency**: Daily at 10:00 UTC

**Expected Result**: Count should match total jobs in both reports (e.g., 438 + 133 = 571)

---

#### Query 4: Error Logs

```bash
sf data query --query "SELECT Id, ApexClass.Name, Message, StackTrace FROM ApexLog WHERE ApexClass.Name IN ('JobDeliveryConfirmationReminderBatch', 'JobMissingScheduleEmailNotificationBatch') AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg --use-tooling-api
```

**Run Frequency**: After each scheduled execution if errors occur

**Expected Result**: No records (no errors)

---

### First Week Monitoring Checklist

| Day | Tier 1 Email Received | Tier 2 Email Received | Job Counts Match | Errors | Notes |
|-----|----------------------|----------------------|------------------|--------|-------|
| Oct 23 (Tue) | ⬜ | ⬜ | ⬜ | ⬜ | First run |
| Oct 24 (Wed) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Oct 25 (Thu) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Oct 26 (Fri) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Oct 27 (Sat) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Oct 28 (Sun) | ⬜ | N/A | N/A | ⬜ | Tier 2 doesn't run Sunday |
| Oct 29 (Mon) | N/A | N/A | N/A | N/A | Neither job runs Monday |

**First Week Status**: ⬜ SUCCESS / ⬜ ISSUES FOUND (Describe: _________________)

---

### Long-Term Monitoring (Ongoing)

**Weekly Review**:
- Email volume trends (should remain ~2 per day)
- Job count trends (increasing/decreasing jobs requiring schedules)
- Error rate (should be 0%)
- User feedback from Customer Service team

**Monthly Review**:
- Evaluate if urgency day thresholds need adjustment (current: 30/8/4/1 days)
- Review CC recipient list (currently: Kaylie Morris, Lucas Hargreaves)
- Assess if batch size needs tuning (current: 200 for Tier 1, 1 for Tier 2)

---

## Known Issues and Limitations

### Known Issue 1: Hardcoded Email Recipients

**Issue**: CC email addresses hardcoded in JobMissingScheduleEmailNotificationBatch (Line 100)
```apex
email.setCcAddresses(new List<String>{'kaylie.morris@recyclinglives-services.com', 'lucas.hargreaves@recyclinglives-services.com'});
```

**Impact**: Requires code change to update CC recipients

**Workaround**: Manual deployment to update recipients

**Future Enhancement**: Move to Custom Metadata Type for easier updates

---

### Known Issue 2: Batch Size Difference

**Issue**:
- Tier 1 (Delivery Confirmation): Batch size 200
- Tier 2 (Schedule Creation): Batch size 1

**Reason**: Tier 2 inherited batch size from original March 2024 implementation. Tier 1 uses optimized batch size 200.

**Impact**: Tier 2 may run slower for large volumes (133+ jobs = 133 batch executions)

**Recommendation**: Consider increasing Tier 2 batch size to 200 in future iteration (requires testing)

---

### Known Issue 3: No Email Template Customization

**Issue**: Email HTML/text built dynamically in Apex (no Lightning Email Template)

**Impact**: Cannot customize email format via Setup UI

**Workaround**: Code changes required for format updates

**Future Enhancement**: Migrate to Lightning Email Templates for easier customization

---

### Known Issue 4: Static Urgency Day Thresholds

**Issue**: Urgency categories use hardcoded day thresholds:
- Critical: 30+ days
- High Priority: 8-29 days
- Medium Priority: 4-7 days
- Recent: 1-3 days

**Impact**: Cannot adjust thresholds without code change

**Future Enhancement**: Move thresholds to Custom Metadata or Custom Settings

---

### Limitation 1: Tier 1 Has No CC Recipients

**Design Decision**: Tier 1 (delivery confirmation) emails sent To: Customer Service only (no CC)

**Reason**: Delivery confirmation is internal Customer Service task; does not require management visibility

**Tier 2** (schedule creation) includes management CC (Kaylie Morris, Lucas Hargreaves)

---

### Limitation 2: Manual Job Filtering

**Issue**: Reports include ALL jobs matching SOQL filter criteria. No manual filtering or exclusions.

**Workaround**: Update Job__c fields (e.g., May_Require_Schedule__c = false) to exclude from reports

---

## Success Criteria

### Deployment Success Criteria

**Deployment is successful if**:
- ✅ All 4 Apex classes deployed without errors
- ✅ All test classes pass (100% coverage)
- ✅ Both scheduled jobs created (8 AM, 9 AM)
- ✅ Manual test runs send emails successfully

---

### Business Success Criteria (Post-Deployment)

**Migration is successful if** (measure after 1 week):

1. **Email Volume Reduction**: ⬜
   - **Target**: 99% reduction (556 emails → 2 reports)
   - **Actual**: _______ emails per day
   - **Status**: ⬜ MET / ⬜ NOT MET

2. **Correct Job Categorization**: ⬜
   - **Target**: Tier 1 contains ONLY jobs WITHOUT confirmed delivery
   - **Target**: Tier 2 contains ONLY jobs WITH confirmed delivery
   - **Status**: ⬜ MET / ⬜ NOT MET

3. **No Record Locking Errors**: ⬜
   - **Target**: Zero record locking errors during batch execution
   - **Actual**: _______ errors in first week
   - **Status**: ⬜ MET / ⬜ NOT MET

4. **User Satisfaction**: ⬜
   - **Target**: Customer Service team finds reports useful and actionable
   - **Feedback**: _________________________________________________
   - **Status**: ⬜ MET / ⬜ NOT MET

5. **Urgency Visibility**: ⬜
   - **Target**: Critical/High priority jobs clearly highlighted
   - **Feedback**: _________________________________________________
   - **Status**: ⬜ MET / ⬜ NOT MET

---

### Final Sign-Off

| Stakeholder | Role | Sign-Off Date | Status |
|-------------|------|---------------|--------|
| Customer Service | End User | | ⬜ APPROVED / ⬜ PENDING |
| Kaylie Morris | Management | | ⬜ APPROVED / ⬜ PENDING |
| Lucas Hargreaves | Management | | ⬜ APPROVED / ⬜ PENDING |
| Technical Lead | Implementation | | ⬜ APPROVED / ⬜ PENDING |

**Overall Migration Status**: ⬜ SUCCESS / ⬜ PARTIAL SUCCESS / ⬜ FAILED

---

## Appendix

### A. Deployment Checklist Summary

**Pre-Deployment**:
- ⬜ Custom fields verified
- ⬜ Custom label verified
- ⬜ OrgWideEmailAddress verified
- ⬜ Email deliverability verified
- ⬜ Test data available
- ⬜ Current state backed up

**Deployment**:
- ⬜ Source code retrieved from OldOrg
- ⬜ Test classes deployed
- ⬜ Batch classes deployed
- ⬜ Deployment verified
- ⬜ Scheduled jobs created
- ⬜ Manual test run executed

**Post-Deployment**:
- ⬜ Integration testing complete
- ⬜ UAT complete
- ⬜ First scheduled run monitored
- ⬜ First week monitoring complete
- ⬜ Stakeholder sign-off obtained

---

### B. Key Contacts

| Role | Name | Email | Responsibility |
|------|------|-------|----------------|
| Customer Service | Team | customerservice@recyclinglives-services.com | Report recipients (To) |
| Management | Kaylie Morris | kaylie.morris@recyclinglives-services.com | Report recipients (CC) - Tier 2 only |
| Management | Lucas Hargreaves | lucas.hargreaves@recyclinglives-services.com | Report recipients (CC) - Tier 2 only |
| Technical Lead | [Your Name] | [Your Email] | Deployment execution |

---

### C. Reference Documentation

- **OldOrg State README**: `/tmp/Salesforce_OldOrg_State/daily-reminder-emails/README.md`
- **NewOrg Gap Analysis**: `/tmp/Salesforce_NewOrg/daily-reminder-emails/GAP_ANALYSIS.md`
- **Source Documentation**: `/tmp/Salesforce_OldOrg_State/daily-reminder-emails/source-docs/DAILY_REMINDER_EMAILS_COMPLETE_GUIDE.md`

---

### D. CRON Expression Reference

**Tier 1 (Delivery Confirmation)**: `0 0 8 ? * 2,3,4,5,6,7`
- Runs: Daily at 8:00 AM UTC
- Days: Tuesday-Sunday (skips Monday)
- Reason: Monday skip aligns with business workflow

**Tier 2 (Schedule Creation)**: `0 0 9 ? * 2,3,4,5,6`
- Runs: Daily at 9:00 AM UTC
- Days: Tuesday-Saturday (skips Sunday-Monday)
- Reason: Management CC recipients may not monitor on Sunday

**CRON Syntax**: `second minute hour day_of_month month day_of_week`
- `?` = no specific value (day_of_month not specified)
- `2,3,4,5,6,7` = Tuesday-Sunday (1=Sunday, 2=Monday, ..., 7=Saturday)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| Oct 22, 2025 | 1.0 | Initial migration plan created | Claude (Automated) |

---

**END OF MIGRATION PLAN**

**Ready for Deployment**: ✅ YES
**Next Action**: Begin Pre-Deployment Checklist
