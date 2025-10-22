# SmartWaste Integration - NewOrg Migration Plan

**Migration Date**: October 22, 2025
**Source**: OldOrg (Recycling Lives Service)
**Target**: NewOrg (Recycling Lives Group)
**Status**: 📋 Configuration-Only Migration (Code Already Deployed)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Overview](#migration-overview)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Phase 0: Pre-Migration Verification](#phase-0-pre-migration-verification)
5. [Phase 1: Activate Flows](#phase-1-activate-flows)
6. [Phase 2: Schedule Batch Jobs](#phase-2-schedule-batch-jobs)
7. [Phase 3: Verify and Update Custom Metadata](#phase-3-verify-and-update-custom-metadata)
8. [Phase 4: Testing and Validation](#phase-4-testing-and-validation)
9. [Phase 5: Go-Live Monitoring](#phase-5-go-live-monitoring)
10. [Rollback Procedures](#rollback-procedures)
11. [Post-Migration Tasks](#post-migration-tasks)
12. [Troubleshooting Guide](#troubleshooting-guide)

---

## Executive Summary

### What This Migration Does

This migration **activates** the SmartWaste Integration system in NewOrg. All code is already deployed; this migration only performs **configuration** tasks to make the integration functional.

### Current State (Before Migration)

**NewOrg Status**:
- ✅ All 11 Apex classes deployed (105,707 lines matching OldOrg)
- ✅ Custom object SmartWaste_Integration_Log__c exists
- ✅ 5 test classes deployed (better coverage than OldOrg)
- 🔴 All flows in DRAFT status (not executing)
- 🔴 NO scheduled jobs configured (integration not running)
- ⚠️ Custom metadata credentials may need updating

**Business Impact**: SmartWaste Integration is **non-functional** - zero Jobs are being sent to SmartWaste platform

### After Migration

- ✅ 3 flows ACTIVE (auto-populate date, duplicate WTN, cleanup logs)
- ✅ 2 scheduled jobs RUNNING (integration batch + log cleanup)
- ✅ Custom metadata verified/updated (correct credentials + Waste Type mappings)
- ✅ Jobs automatically sent to SmartWaste daily at 00:00 UTC
- ✅ Environmental compliance reporting operational

### Migration Complexity

| Aspect | Complexity | Reason |
|--------|------------|--------|
| **Code Deployment** | ✅ None | All code already deployed |
| **Configuration** | 🟡 Medium | Activate flows + schedule jobs + verify metadata |
| **Testing** | 🟢 Low | No code changes, only config validation |
| **Risk** | 🟡 Medium | Critical for compliance, but reversible |

**Estimated Time**: 3-4 hours (including testing and monitoring)

---

## Migration Overview

### Components to Configure (0 Code Deployments)

**Configuration Changes Only**:

1. **Activate 3 Flows** (currently Draft):
   - Populate_Date_Added_to_Smart_Waste_Field
   - SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed
   - SmartWaste_Logs_Delete_if_Site_Not_Linked

2. **Schedule 2 Batch Jobs** (currently not scheduled):
   - SmartWasteIntegrationBatch (daily 00:00 UTC)
   - SmartWasteLogCleanupScheduled (daily 08:00 UTC)

3. **Verify/Update Custom Metadata**:
   - SmartWasteAPI__mdt (API credentials)
   - Waste_Type__mdt (product/route mappings)

**No Code Deployment Required**: All Apex classes, test classes, and custom objects already exist in NewOrg

---

### Migration Phases

| Phase | Description | Duration | Rollback |
|-------|-------------|----------|----------|
| **Phase 0** | Pre-migration verification (query metadata, test API) | 1 hour | N/A |
| **Phase 1** | Activate flows (UI-based activation) | 30 minutes | Deactivate flows |
| **Phase 2** | Schedule batch jobs (Execute Anonymous Apex) | 15 minutes | Abort jobs |
| **Phase 3** | Verify/update custom metadata (if needed) | 1 hour | Revert metadata |
| **Phase 4** | Testing and validation (manual triggers, monitoring) | 2 hours | Abort jobs, deactivate flows |
| **Phase 5** | Go-live monitoring (watch scheduled execution) | Ongoing | Full rollback if needed |

**Total Estimated Time**: 4.75 hours (plus ongoing monitoring)

---

### Dependencies

**External Dependencies**:
- SmartWaste API credentials for NewOrg environment (obtain from SmartWaste support BEFORE migration)
- Access to NewOrg Salesforce org (System Administrator permissions required)
- Ability to execute Anonymous Apex (for scheduling jobs)

**Internal Dependencies**:
- All code already deployed (verified in Gap Analysis)
- Custom object SmartWaste_Integration_Log__c exists
- Custom fields exist on Job__c, Site__c, Waste_Types__c, Depot__c

**No Blocking Dependencies**: Migration can proceed immediately once credentials obtained

---

## Pre-Deployment Checklist

### Required Access

- [ ] System Administrator profile on NewOrg
- [ ] Permission to activate flows (Setup → Flows)
- [ ] Permission to execute Anonymous Apex (Developer Console)
- [ ] Permission to update Custom Metadata Types

### Required Information

- [ ] SmartWaste API Username for NewOrg environment
- [ ] SmartWaste API Client Key for NewOrg environment
- [ ] SmartWaste API Private Key for NewOrg environment
- [ ] SmartWaste environment URL (Production vs Sandbox)
- [ ] Contact information for SmartWaste support (if API issues arise)

### Pre-Migration Verification

- [ ] Confirm all 11 Apex classes exist in NewOrg (Phase 0 will verify)
- [ ] Confirm custom object SmartWaste_Integration_Log__c exists (Phase 0 will verify)
- [ ] Confirm flows exist in Draft status (Phase 0 will verify)
- [ ] Confirm no scheduled jobs exist (Phase 0 will verify)
- [ ] Test API connectivity to SmartWaste (Phase 0 will test)

### Communication

- [ ] Notify users that SmartWaste Integration will be activated
- [ ] Schedule migration during low-traffic period (recommended: weekend or after-hours)
- [ ] Prepare support team for potential SmartWaste-related questions
- [ ] Document go-live date/time

### Backup Plan

- [ ] Document current NewOrg flow statuses (Phase 0 will capture)
- [ ] Document current scheduled jobs (Phase 0 will verify none exist)
- [ ] Have rollback script prepared (see Rollback Procedures section)
- [ ] Identify rollback decision-maker (who can call stop-go-live)

---

## Phase 0: Pre-Migration Verification

**Objective**: Verify current state of NewOrg and identify any missing components

**Duration**: 1 hour

### Step 0.1: Verify Apex Classes

```bash
# Query NewOrg for all SmartWaste Apex classes
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name LIKE 'SmartWaste%' ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 11 classes (6 production + 5 test)

**Verification**:
- [ ] SmartWasteIntegrationBatch (37,114 lines)
- [ ] SmartWasteIntegrationBatchTest (11,553 lines)
- [ ] SmartWasteIntegrationFlowHandler (4,696 lines)
- [ ] SmartWasteIntegrationFlowHandlerTest (1,378 lines)
- [ ] SmartWasteIntegrationHexFormBuilder (2,748 lines)
- [ ] SmartWasteIntegrationHexFormBuilderTest (2,510 lines)
- [ ] SmartWasteIntegrationMiddleware (56,243 lines)
- [ ] SmartWasteIntegrationMiddlewareTest (8,777 lines)
- [ ] SmartWasteIntegrationMockGenerator (4,155 lines)
- [ ] SmartWasteLogCleanupScheduled (751 lines)
- [ ] SmartWasteLogCleanupScheduledTest (2,247 lines)

**If Missing Classes**: STOP - code must be deployed first (contact technical team)

---

### Step 0.2: Verify Flows

```bash
# Query NewOrg for SmartWaste flows
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName LIKE '%SmartWaste%' OR Definition.DeveloperName LIKE '%Smart_Waste%' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 4 flows in Draft status

**Verification**:
- [ ] Populate_Date_Added_to_Smart_Waste_Field (V1, Draft)
- [ ] SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed (V1, Draft)
- [ ] SmartWaste_Logs_Delete_if_Site_Not_Linked (V1, Draft)
- [ ] SmartWaste_Integration (V1, Draft - likely not needed)

**If Any Flow is Active**: Document which flows are already active (may indicate partial migration)

---

### Step 0.3: Verify Scheduled Jobs

```bash
# Query NewOrg for SmartWaste scheduled jobs
sf data query --query "SELECT CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE '%SmartWaste%'" --target-org NewOrg
```

**Expected Result**: 0 scheduled jobs

**If Scheduled Jobs Exist**: Document job names and decide whether to abort and reschedule or keep existing

---

### Step 0.4: Verify Custom Object

```bash
# Verify SmartWaste_Integration_Log__c object exists
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg
```

**Expected Result**: Query succeeds (object exists), returns count (e.g., 56,994 records)

**If Query Fails**: STOP - custom object missing (contact technical team)

---

### Step 0.5: Verify Custom Metadata - API Credentials

```bash
# Query SmartWasteAPI__mdt records
sf data query --query "SELECT Label, SmartWaste_Username__c, SmartWaste_Client_Key__c FROM SmartWasteAPI__mdt" --target-org NewOrg
```

**Expected Result**: At least 1 record returned with credentials

**Action**:
- [ ] Document current Username value
- [ ] Verify this is NewOrg environment username (NOT OldOrg username)
- [ ] If incorrect, note need to update in Phase 3

**Security Note**: Private Key will not be visible in query results (protected field)

---

### Step 0.6: Verify Custom Metadata - Waste Type Mappings

```bash
# Query Waste_Type__mdt records
sf data query --query "SELECT MasterLabel, SmartWaste_Id__c, SmartWaste_Route_Id__c FROM Waste_Type__mdt ORDER BY MasterLabel" --target-org NewOrg
```

**Expected Result**: Multiple records with SmartWaste_Id__c and SmartWaste_Route_Id__c populated

**Action**:
- [ ] Count total mappings (should match OldOrg count)
- [ ] Spot-check a few mappings (compare against OldOrg)
- [ ] Note any missing Waste Types

**If Major Gaps Identified**: Prepare list of missing mappings to add in Phase 3

---

### Step 0.7: Verify Custom Fields on Key Objects

```bash
# Verify Job__c has SmartWaste fields
sf data query --query "SELECT Id, Date_Added_to_SmartWaste__c, SmartWaste_Id__c, Site__r.SmartWaste_Id__c FROM Job__c WHERE Date_Added_to_SmartWaste__c != null LIMIT 1" --target-org NewOrg

# Verify Site__c has SmartWaste_Id__c field
sf data query --query "SELECT Id, Name, SmartWaste_Id__c FROM Site__c WHERE SmartWaste_Id__c != null LIMIT 1" --target-org NewOrg
```

**Expected Result**: Queries succeed (fields exist), may or may not return records

**If Queries Fail**: STOP - custom fields missing (contact technical team)

---

### Step 0.8: Test API Connectivity (Optional but Recommended)

**Manual Test via Developer Console**:

1. Open Developer Console in NewOrg
2. Go to Debug → Open Execute Anonymous Window
3. Run the following test code:

```apex
// Test SmartWaste API connectivity
SmartWasteAPI__mdt credentials = [SELECT SmartWaste_Username__c,
                                          SmartWaste_Client_Key__c,
                                          SmartWaste_Private_Key__c
                                   FROM SmartWasteAPI__mdt LIMIT 1];

Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SmartWasteAPI'); // Named Credential
req.setMethod('GET'); // Test endpoint (check SmartWaste API docs)
req.setHeader('Content-Type', 'application/json');

try {
    HttpResponse res = http.send(req);
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Response: ' + res.getBody());

    if (res.getStatusCode() == 200 || res.getStatusCode() == 401) {
        System.debug('✅ API endpoint reachable');
    } else {
        System.debug('⚠️ Unexpected status code');
    }
} catch (Exception e) {
    System.debug('❌ API connection failed: ' + e.getMessage());
}
```

**Expected Result**:
- Status Code 200 (success) OR
- Status Code 401 (unauthorized - means endpoint is reachable, credentials may be wrong)

**If Connection Fails (no response)**: Verify Named Credential "SmartWasteAPI" is configured correctly

---

### Step 0.9: Document Current State

Create verification report:

```
SmartWaste Integration - Pre-Migration Verification Report
Date: [Current Date/Time]
Org: NewOrg

✅ Apex Classes: 11/11 present
✅ Flows: 4/4 present (all Draft)
✅ Scheduled Jobs: 0/0 (none configured - expected)
✅ Custom Object: SmartWaste_Integration_Log__c exists (56,994 records)
✅ Custom Fields: Verified on Job__c and Site__c

Custom Metadata Status:
- SmartWasteAPI__mdt: [Record count] records found
  - Username: [value] (verify this is NewOrg username)
  - Client Key: [value] (verify this is NewOrg key)
- Waste_Type__mdt: [Record count] mappings found

API Connectivity Test:
- [ ] Passed (status code: [value])
- [ ] Failed (error: [description])
- [ ] Skipped (will test in Phase 3)

Issues Identified:
- [List any issues found]

Ready to Proceed: ✅ YES / ❌ NO (if NO, list blockers)
```

**Decision Point**: If all verifications passed, proceed to Phase 1. If issues found, resolve before continuing.

---

## Phase 1: Activate Flows

**Objective**: Activate 3 critical flows to enable record-triggered automation

**Duration**: 30 minutes

**Rollback**: Deactivate flows via Salesforce UI

---

### Step 1.1: Activate Populate_Date_Added_to_Smart_Waste_Field

**Purpose**: Auto-populate `Date_Added_to_SmartWaste__c` field when Job is created (makes Job eligible for integration)

**Steps**:
1. Login to NewOrg
2. Navigate to Setup → Flows
3. Search for "Populate_Date_Added_to_Smart_Waste_Field"
4. Click flow name to open
5. Verify flow details:
   - Trigger: Before Save (Job__c)
   - Logic: If `Date_Added_to_SmartWaste__c` is blank, set to TODAY()
6. Click "Activate" button
7. Confirm activation

**Verification**:
```bash
# Verify flow is Active
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'Populate_Date_Added_to_Smart_Waste_Field'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Status = Active

**Test** (optional):
1. Create a new Job record in NewOrg (leave `Date_Added_to_SmartWaste__c` blank)
2. Save Job
3. Refresh page
4. Verify `Date_Added_to_SmartWaste__c` is now populated with today's date

---

### Step 1.2: Activate SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed

**Purpose**: Duplicate Waste Transfer Note reference to WBT field if needed for SmartWaste integration

**Steps**:
1. Navigate to Setup → Flows
2. Search for "SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed"
3. Click flow name to open
4. Verify flow details:
   - Trigger: After Save (Job__c)
   - Logic: If WTN reference exists and WBT field is blank, duplicate WTN to WBT
5. Click "Activate" button
6. Confirm activation

**Verification**:
```bash
# Verify flow is Active
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Status = Active

---

### Step 1.3: Activate SmartWaste_Logs_Delete_if_Site_Not_Linked

**Purpose**: Automatically delete integration log records if related Site does not have SmartWaste_Id__c

**Steps**:
1. Navigate to Setup → Flows
2. Search for "SmartWaste_Logs_Delete_if_Site_Not_Linked"
3. Click flow name to open
4. Verify flow details:
   - Trigger: After Save (SmartWaste_Integration_Log__c)
   - Logic: If `Is_Site_Linked_to_Smart_Waste__c = FALSE`, delete record
5. Click "Activate" button
6. Confirm activation

**Verification**:
```bash
# Verify flow is Active
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'SmartWaste_Logs_Delete_if_Site_Not_Linked'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Status = Active

**Note**: This flow will immediately start deleting any existing logs where Site is not linked to SmartWaste. Monitor SmartWaste_Integration_Log__c record count:

```bash
# Check log count before activation
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg

# Wait 5-10 minutes after activation, then check again
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg
```

**Expected Behavior**: Record count may decrease if there are logs with unlinked Sites

---

### Step 1.4: Verify All Flows Are Active

```bash
# Query all SmartWaste flows, confirm Active status
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName LIKE '%SmartWaste%' OR Definition.DeveloperName LIKE '%Smart_Waste%' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: At least 3 flows with Status = Active

- ✅ Populate_Date_Added_to_Smart_Waste_Field: Active
- ✅ SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed: Active
- ✅ SmartWaste_Logs_Delete_if_Site_Not_Linked: Active
- SmartWaste_Integration: Draft (OK - this flow is not needed if batch job is primary method)

**If Any Flow Failed to Activate**: Review error message, resolve issue, retry activation

---

### Phase 1 Completion Checklist

- [ ] Populate_Date_Added_to_Smart_Waste_Field activated successfully
- [ ] SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed activated successfully
- [ ] SmartWaste_Logs_Delete_if_Site_Not_Linked activated successfully
- [ ] All 3 flows verified as Active via SOQL query
- [ ] Optional: Tested Job creation flow by creating test record

**Phase 1 Complete**: Flows are now executing on record changes ✅

---

## Phase 2: Schedule Batch Jobs

**Objective**: Schedule 2 batch jobs to run daily (integration + log cleanup)

**Duration**: 15 minutes

**Rollback**: Abort scheduled jobs via Execute Anonymous Apex

---

### Step 2.1: Schedule SmartWaste Integration Batch Job

**Purpose**: Daily batch job (00:00 UTC) to send Jobs to SmartWaste API

**Steps**:
1. Open Developer Console in NewOrg
2. Go to Debug → Open Execute Anonymous Window
3. Paste the following code:

```apex
// Schedule SmartWasteIntegrationBatch to run daily at 00:00 UTC
SmartWasteIntegrationBatch integrationBatch = new SmartWasteIntegrationBatch();
String cronExp = '0 0 0 * * ?'; // Daily at midnight UTC
String jobName = 'SmartWaste_Integration-10';

// Check if job already exists (prevent duplicates)
List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name
                                    FROM CronTrigger
                                    WHERE CronJobDetail.Name = :jobName];

if (existingJobs.isEmpty()) {
    String jobId = System.schedule(jobName, cronExp, integrationBatch);
    System.debug('✅ Scheduled SmartWaste Integration: Job ID = ' + jobId);
} else {
    System.debug('⚠️ Job already scheduled: ' + existingJobs[0].Id);
}
```

4. Click "Execute"
5. Check Debug Log for success message

**Verification**:
```bash
# Query scheduled job
sf data query --query "SELECT Id, CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = 'SmartWaste_Integration-10'" --target-org NewOrg
```

**Expected Result**:
- Name: SmartWaste_Integration-10
- State: WAITING
- NextFireTime: [Next occurrence of 00:00 UTC]

**Example Next Fire Time**: If scheduled on Oct 22, 2025 at 14:00 UTC, next fire time will be Oct 23, 2025 at 00:00 UTC

---

### Step 2.2: Schedule SmartWaste Log Cleanup Job

**Purpose**: Daily batch job (08:00 UTC) to delete integration logs older than 30 days

**Steps**:
1. Open Developer Console in NewOrg (if not already open)
2. Go to Debug → Open Execute Anonymous Window
3. Paste the following code:

```apex
// Schedule SmartWasteLogCleanupScheduled to run daily at 08:00 UTC
SmartWasteLogCleanupScheduled cleanupBatch = new SmartWasteLogCleanupScheduled();
String cronExp = '0 0 8 * * ?'; // Daily at 8 AM UTC
String jobName = 'SmartWaste Log Cleanup';

// Check if job already exists (prevent duplicates)
List<CronTrigger> existingJobs = [SELECT Id, CronJobDetail.Name
                                    FROM CronTrigger
                                    WHERE CronJobDetail.Name = :jobName];

if (existingJobs.isEmpty()) {
    String jobId = System.schedule(jobName, cronExp, cleanupBatch);
    System.debug('✅ Scheduled SmartWaste Log Cleanup: Job ID = ' + jobId);
} else {
    System.debug('⚠️ Job already scheduled: ' + existingJobs[0].Id);
}
```

4. Click "Execute"
5. Check Debug Log for success message

**Verification**:
```bash
# Query scheduled job
sf data query --query "SELECT Id, CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = 'SmartWaste Log Cleanup'" --target-org NewOrg
```

**Expected Result**:
- Name: SmartWaste Log Cleanup
- State: WAITING
- NextFireTime: [Next occurrence of 08:00 UTC]

---

### Step 2.3: Verify Both Scheduled Jobs

```bash
# Query all SmartWaste scheduled jobs
sf data query --query "SELECT CronJobDetail.Name, State, NextFireTime, CronExpression FROM CronTrigger WHERE CronJobDetail.Name LIKE '%SmartWaste%'" --target-org NewOrg
```

**Expected Result**: 2 scheduled jobs

| Job Name | State | Next Fire Time | Cron Expression |
|----------|-------|----------------|-----------------|
| SmartWaste_Integration-10 | WAITING | [Oct 23, 00:00 UTC] | 0 0 0 * * ? |
| SmartWaste Log Cleanup | WAITING | [Oct 23, 08:00 UTC] | 0 0 8 * * ? |

**If Job Missing**: Re-run Execute Anonymous Apex code for missing job

---

### Step 2.4: Optional - Test Integration Batch Manually

**Before waiting for scheduled run**, test the batch job manually to catch any errors:

```apex
// Execute Anonymous Apex to run integration batch immediately
Database.executeBatch(new SmartWasteIntegrationBatch(), 200);
```

**Monitor Batch Progress**:
1. Setup → Environments → Jobs → Apex Jobs
2. Look for "SmartWasteIntegrationBatch" in recent jobs
3. Check Status (Processing → Completed)
4. Check records processed
5. Check for errors

**Expected Result**: Batch completes successfully, Jobs sent to SmartWaste

**If Batch Fails**: Check error message, resolve issue before scheduled run

---

### Phase 2 Completion Checklist

- [ ] SmartWaste_Integration-10 scheduled successfully (00:00 UTC)
- [ ] SmartWaste Log Cleanup scheduled successfully (08:00 UTC)
- [ ] Both jobs verified as WAITING via SOQL query
- [ ] Optional: Manual batch execution successful (test run)

**Phase 2 Complete**: Scheduled jobs are ready to run daily ✅

---

## Phase 3: Verify and Update Custom Metadata

**Objective**: Ensure SmartWaste API credentials and Waste Type mappings are correct for NewOrg

**Duration**: 1 hour (if updates needed)

**Rollback**: Revert metadata to previous values

---

### Step 3.1: Review SmartWasteAPI__mdt Credentials

**Query Current Credentials**:
```bash
sf data query --query "SELECT Label, SmartWaste_Username__c, SmartWaste_Client_Key__c FROM SmartWasteAPI__mdt" --target-org NewOrg
```

**Review**:
- [ ] Username matches NewOrg SmartWaste environment (NOT OldOrg)
- [ ] Client Key matches NewOrg SmartWaste environment
- [ ] Private Key is correct (cannot verify via query, but check with SmartWaste support)

**If Credentials Are Correct**: Skip to Step 3.2

**If Credentials Need Updating**: Continue to Step 3.1a

---

### Step 3.1a: Update SmartWasteAPI__mdt Credentials (If Needed)

**Steps**:
1. Navigate to Setup → Custom Metadata Types
2. Click "Manage Records" next to SmartWasteAPI
3. Click existing record (or create new record if none exists)
4. Update fields:
   - `SmartWaste_Username__c`: [NewOrg username from SmartWaste support]
   - `SmartWaste_Client_Key__c`: [NewOrg client key]
   - `SmartWaste_Private_Key__c`: [NewOrg private key]
5. Click "Save"

**Verification**:
```bash
# Re-query to confirm updates
sf data query --query "SELECT Label, SmartWaste_Username__c, SmartWaste_Client_Key__c FROM SmartWasteAPI__mdt" --target-org NewOrg
```

**Expected Result**: Updated values reflected in query

---

### Step 3.2: Review Waste_Type__mdt Mappings

**Query Current Mappings**:
```bash
sf data query --query "SELECT MasterLabel, SmartWaste_Id__c, SmartWaste_Route_Id__c FROM Waste_Type__mdt ORDER BY MasterLabel" --target-org NewOrg
```

**Review**:
- [ ] Count total mappings (compare against OldOrg - see OldOrg State README for expected count)
- [ ] Spot-check product IDs and route IDs (verify they match SmartWaste platform)
- [ ] Check for any missing Waste Types (compare against OldOrg list)

**If Mappings Are Complete**: Skip to Step 3.3

**If Mappings Are Missing**: Continue to Step 3.2a

---

### Step 3.2a: Add Missing Waste Type Mappings (If Needed)

**Steps**:
1. Navigate to Setup → Custom Metadata Types
2. Click "Manage Records" next to Waste_Type
3. For each missing Waste Type:
   - Click "New"
   - Enter Label: [Waste Type Name]
   - Enter `SmartWaste_Id__c`: [Product ID from SmartWaste platform]
   - Enter `SmartWaste_Route_Id__c`: [Route ID from SmartWaste platform]
   - Click "Save"
4. Repeat for all missing mappings

**Verification**:
```bash
# Re-query to confirm new mappings
sf data query --query "SELECT COUNT() FROM Waste_Type__mdt" --target-org NewOrg
```

**Expected Result**: Count matches OldOrg count

---

### Step 3.3: Test API Connectivity with Updated Credentials

**Execute Anonymous Apex Test**:

```apex
// Test SmartWaste API connectivity with updated credentials
SmartWasteAPI__mdt credentials = [SELECT SmartWaste_Username__c,
                                          SmartWaste_Client_Key__c,
                                          SmartWaste_Private_Key__c
                                   FROM SmartWasteAPI__mdt LIMIT 1];

System.debug('Testing with Username: ' + credentials.SmartWaste_Username__c);

Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SmartWasteAPI'); // Named Credential
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');

// Add authentication (middleware will handle this, but test basic connectivity)
try {
    HttpResponse res = http.send(req);
    System.debug('✅ Status Code: ' + res.getStatusCode());
    System.debug('Response Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        System.debug('✅ API connection successful');
    } else if (res.getStatusCode() == 401) {
        System.debug('⚠️ API endpoint reachable but credentials may be invalid');
    } else {
        System.debug('⚠️ Unexpected status: ' + res.getStatusCode());
    }
} catch (Exception e) {
    System.debug('❌ API connection failed: ' + e.getMessage());
}
```

**Expected Result**:
- Status Code 200 (success) OR
- Status Code 401 (unauthorized - endpoint reachable, check credentials)

**If Connection Fails**: Verify Named Credential "SmartWasteAPI" is configured with correct endpoint URL

---

### Phase 3 Completion Checklist

- [ ] SmartWasteAPI__mdt credentials verified/updated for NewOrg environment
- [ ] Waste_Type__mdt mappings verified/updated (all Waste Types mapped)
- [ ] API connectivity test passed (status code 200 or 401)
- [ ] Named Credential "SmartWasteAPI" configured correctly

**Phase 3 Complete**: Custom metadata is ready for production use ✅

---

## Phase 4: Testing and Validation

**Objective**: Validate that SmartWaste Integration is fully functional in NewOrg

**Duration**: 2 hours

**Rollback**: N/A (testing phase, no changes)

---

### Step 4.1: Test Flow - Populate Date Added to SmartWaste

**Test Case**: Create Job record and verify `Date_Added_to_SmartWaste__c` auto-populates

**Steps**:
1. Navigate to Jobs tab in NewOrg
2. Click "New" to create a Job
3. Fill required fields (Account, Site, Waste Type, etc.)
4. **DO NOT** manually fill `Date_Added_to_SmartWaste__c` field (leave blank)
5. Click "Save"
6. Refresh page
7. Verify `Date_Added_to_SmartWaste__c` is now populated with today's date

**Expected Result**: ✅ Field auto-populated with today's date

**If Test Fails**:
- Check flow "Populate_Date_Added_to_Smart_Waste_Field" is Active
- Review flow logic for errors
- Check Debug Log for flow errors

---

### Step 4.2: Test Flow - Duplicate WTN Reference

**Test Case**: Update Job with WTN reference and verify WBT field duplicates value

**Steps**:
1. Open existing Job record (or use Job created in Step 4.1)
2. Populate WTN field (Waste Transfer Note reference)
3. Leave WBT field blank
4. Click "Save"
5. Refresh page
6. Verify WBT field now contains same value as WTN field

**Expected Result**: ✅ WBT field populated with WTN value

**If Test Fails**:
- Check flow "SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed" is Active
- Review flow logic for errors

**Note**: This test assumes your Job object has WTN and WBT fields. If field names differ, adjust test accordingly.

---

### Step 4.3: Test Flow - Delete Log if Site Not Linked

**Test Case**: Create integration log with unlinked Site and verify automatic deletion

**Steps**:
1. Identify a Site WITHOUT SmartWaste_Id__c populated (or create test Site)
2. Create a SmartWaste_Integration_Log__c record manually:
   - Related_Site__c: [Site without SmartWaste_Id__c]
   - Related_Job__c: [Any Job]
   - Is_Site_Linked_to_Smart_Waste__c: FALSE
3. Click "Save"
4. Immediately query for the record:
```bash
sf data query --query "SELECT Id FROM SmartWaste_Integration_Log__c WHERE Id = '[record ID]'" --target-org NewOrg
```

**Expected Result**: ❌ Record not found (flow deleted it immediately after save)

**If Test Fails**:
- Check flow "SmartWaste_Logs_Delete_if_Site_Not_Linked" is Active
- Review flow logic
- Check if `Is_Site_Linked_to_Smart_Waste__c` field is formula or manual (should be formula checking Site.SmartWaste_Id__c)

---

### Step 4.4: Test Batch Job - Manual Execution

**Test Case**: Manually execute SmartWasteIntegrationBatch and verify Jobs are processed

**Prerequisites**:
- At least 1 Job record with `Date_Added_to_SmartWaste__c` populated
- Job's Site has `SmartWaste_Id__c` populated
- Job's Waste Type is mapped in Waste_Type__mdt

**Steps**:
1. Open Developer Console
2. Execute Anonymous Apex:
```apex
// Execute SmartWaste Integration Batch
Database.executeBatch(new SmartWasteIntegrationBatch(), 200);
System.debug('✅ Batch job submitted');
```
3. Navigate to Setup → Environments → Jobs → Apex Jobs
4. Locate "SmartWasteIntegrationBatch" in job list
5. Monitor status (Processing → Completed)
6. Check records processed count
7. Check for errors

**Expected Result**:
- Status: Completed
- Records Processed: [number of eligible Jobs]
- Failures: 0

**Verification - Check Job Records**:
```bash
# Query Jobs that were processed
sf data query --query "SELECT Id, Name, SmartWaste_Id__c, SmartWaste_IsMainDisposalSent__c FROM Job__c WHERE Date_Added_to_SmartWaste__c != null AND SmartWaste_Id__c != null LIMIT 10" --target-org NewOrg
```

**Expected Result**: Jobs now have `SmartWaste_Id__c` populated (returned from SmartWaste API)

**Verification - Check Integration Logs**:
```bash
# Query recent integration logs
sf data query --query "SELECT Id, Related_Job__r.Name, JobSentSuccessfully__c, CreatedDate FROM SmartWaste_Integration_Log__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg
```

**Expected Result**: Logs created for each Job processed (success or error)

**If Batch Fails**:
- Check error message in Apex Jobs page
- Review Debug Log for detailed error
- Verify API credentials are correct
- Check Named Credential is configured
- Verify Waste Type mappings are complete

---

### Step 4.5: Test Log Cleanup Batch Job - Manual Execution

**Test Case**: Manually execute SmartWasteLogCleanupScheduled and verify old logs are deleted

**Prerequisites**: Integration logs older than 30 days exist in NewOrg

**Steps**:
1. Query current log count:
```bash
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg
```
Document count: [value]

2. Execute Anonymous Apex:
```apex
// Execute Log Cleanup Batch
Database.executeBatch(new SmartWasteLogCleanupScheduled(), 200);
System.debug('✅ Log cleanup batch submitted');
```

3. Monitor Apex Jobs page (wait for completion)

4. Query log count again:
```bash
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg
```

**Expected Result**: Count decreased (old logs deleted)

**If Count Unchanged**:
- Possible: No logs older than 30 days
- Verify log retention period in SmartWasteLogCleanupScheduled.cls (hardcoded 30 days)

---

### Step 4.6: Test Scheduled Job Execution (Next Day)

**Test Case**: Wait for scheduled jobs to run automatically and verify execution

**Timeline**:
- SmartWaste_Integration-10 runs at 00:00 UTC (next day)
- SmartWaste Log Cleanup runs at 08:00 UTC (next day)

**Verification Next Day**:

**After 00:00 UTC**:
```bash
# Check Apex Jobs for scheduled execution
sf data query --query "SELECT Id, Status, JobType, CompletedDate, NumberOfErrors FROM AsyncApexJob WHERE ApexClass.Name = 'SmartWasteIntegrationBatch' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**Expected Result**: Job executed with Status = Completed, NumberOfErrors = 0

**After 08:00 UTC**:
```bash
# Check Apex Jobs for log cleanup execution
sf data query --query "SELECT Id, Status, JobType, CompletedDate, NumberOfErrors FROM AsyncApexJob WHERE ApexClass.Name = 'SmartWasteLogCleanupScheduled' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**Expected Result**: Job executed with Status = Completed

**If Jobs Did Not Run**:
- Verify scheduled jobs are still in WAITING state (not aborted)
- Check cron expression is correct
- Review Salesforce platform status (scheduled jobs may be delayed during maintenance)

---

### Phase 4 Completion Checklist

- [ ] Flow test passed: Date Added to SmartWaste auto-populates
- [ ] Flow test passed: WTN duplication works
- [ ] Flow test passed: Logs deleted if Site not linked
- [ ] Batch test passed: Integration batch processes Jobs successfully
- [ ] Batch test passed: Log cleanup deletes old records
- [ ] Optional: Scheduled jobs verified to run automatically (wait until next day)

**Phase 4 Complete**: SmartWaste Integration is fully functional ✅

---

## Phase 5: Go-Live Monitoring

**Objective**: Monitor SmartWaste Integration in production after activation

**Duration**: Ongoing (intensive monitoring for first 7 days)

---

### Day 1 Monitoring Checklist

**After First Scheduled Run (00:00 UTC + 1 hour)**:

- [ ] Verify scheduled job executed:
```bash
sf data query --query "SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE ApexClass.Name = 'SmartWasteIntegrationBatch' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

- [ ] Check for batch errors:
```bash
sf data query --query "SELECT Id, Related_Job__r.Name, JobSentSuccessfully__c FROM SmartWaste_Integration_Log__c WHERE CreatedDate = TODAY AND JobSentSuccessfully__c = false ORDER BY CreatedDate DESC" --target-org NewOrg
```

- [ ] Verify Jobs sent to SmartWaste:
```bash
sf data query --query "SELECT COUNT() FROM Job__c WHERE SmartWaste_Id__c != null AND LastModifiedDate = TODAY" --target-org NewOrg
```

- [ ] Confirm SmartWaste platform received data (login to SmartWaste portal, check for new records)

**After First Log Cleanup Run (08:00 UTC + 1 hour)**:

- [ ] Verify log cleanup executed:
```bash
sf data query --query "SELECT Status, NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE ApexClass.Name = 'SmartWasteLogCleanupScheduled' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

- [ ] Check log count (should be decreasing over time as old logs are deleted):
```bash
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c" --target-org NewOrg
```

---

### Week 1 Monitoring Checklist

**Daily (for first 7 days)**:

- [ ] Check scheduled jobs executed without errors
- [ ] Review integration logs for failed Jobs
- [ ] Monitor SmartWaste platform for data accuracy
- [ ] Verify no user complaints about missing SmartWaste data

**Weekly Report Template**:

```
SmartWaste Integration - Week 1 Monitoring Report
Report Date: [Date]

Scheduled Job Execution:
- SmartWaste_Integration-10: [X/7 successful runs]
- SmartWaste Log Cleanup: [X/7 successful runs]

Integration Statistics:
- Total Jobs processed: [count]
- Successful integrations: [count]
- Failed integrations: [count]
- Common errors: [list top 3 errors]

Data Quality:
- Jobs with missing Site SmartWaste ID: [count]
- Jobs with unmapped Waste Types: [count]
- Invalid collection dates: [count]

Action Items:
- [List any issues requiring attention]

Overall Status: ✅ Healthy / ⚠️ Needs Attention / ❌ Critical Issues
```

---

### Ongoing Monitoring (After Week 1)

**Monthly**:
- Review integration error trends
- Verify Waste Type mappings are up to date
- Check log retention (ensure log cleanup is working)
- Review SmartWaste API credential expiration (if applicable)

**Quarterly**:
- Audit SmartWaste data accuracy (compare Salesforce vs SmartWaste platform)
- Review user feedback on SmartWaste integration
- Plan any enhancements or fixes

---

### Phase 5 Completion Checklist

- [ ] Day 1 monitoring completed (both scheduled jobs verified)
- [ ] Week 1 monitoring completed (7 days of successful runs)
- [ ] Integration errors documented and resolved (or known issues logged)
- [ ] SmartWaste platform confirmed receiving accurate data
- [ ] Ongoing monitoring plan established

**Phase 5 Complete**: SmartWaste Integration is stable in production ✅

---

## Rollback Procedures

### When to Rollback

**Consider rollback if**:
- SmartWaste API connectivity fails consistently
- Batch jobs cause performance issues
- Critical data errors discovered (incorrect data sent to SmartWaste)
- Business decision to postpone go-live

**DO NOT rollback for**:
- Minor integration errors (a few Jobs failing) - these can be fixed without rollback
- User confusion (address with training, not rollback)
- SmartWaste platform issues (not Salesforce's fault)

---

### Rollback Step 1: Abort Scheduled Jobs

**Execute Anonymous Apex**:

```apex
// Abort all SmartWaste scheduled jobs
List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name
                          FROM CronTrigger
                          WHERE CronJobDetail.Name LIKE '%SmartWaste%'];

for (CronTrigger job : jobs) {
    System.abortJob(job.Id);
    System.debug('Aborted job: ' + job.CronJobDetail.Name);
}

System.debug('✅ All SmartWaste scheduled jobs aborted');
```

**Verification**:
```bash
# Confirm no scheduled jobs exist
sf data query --query "SELECT CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE '%SmartWaste%'" --target-org NewOrg
```

**Expected Result**: 0 records (all jobs aborted)

---

### Rollback Step 2: Deactivate Flows

**Steps**:
1. Navigate to Setup → Flows
2. Deactivate each flow:
   - Populate_Date_Added_to_Smart_Waste_Field
   - SmartWaste_Dupe_WTN_Ref_as_WBT_If_Needed
   - SmartWaste_Logs_Delete_if_Site_Not_Linked
3. Confirm deactivation for each flow

**Verification**:
```bash
# Confirm no active flows
sf data query --query "SELECT Definition.DeveloperName, Status FROM Flow WHERE Definition.DeveloperName LIKE '%SmartWaste%' AND Status = 'Active'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 0 records (all flows deactivated)

---

### Rollback Step 3: Optional - Revert Custom Metadata

**If credentials were updated in Phase 3**:

1. Navigate to Setup → Custom Metadata Types → SmartWasteAPI
2. Click "Manage Records"
3. Edit record
4. Revert credentials to previous values (documented in Phase 0 verification report)
5. Save

**Verification**:
```bash
# Confirm credentials reverted
sf data query --query "SELECT SmartWaste_Username__c FROM SmartWasteAPI__mdt" --target-org NewOrg
```

---

### Rollback Verification

**Confirm Complete Rollback**:
- [ ] 0 scheduled jobs running (query returns 0 records)
- [ ] 0 active SmartWaste flows (query returns 0 records)
- [ ] Custom metadata reverted (if applicable)

**System State After Rollback**:
- SmartWaste Integration is inactive (same as before migration)
- No Jobs will be sent to SmartWaste
- Flows will not execute on record changes
- No automated log cleanup

**User Impact**:
- SmartWaste data must be entered manually (if required)
- No automated environmental reporting

---

## Post-Migration Tasks

### Immediate (Within 24 Hours)

- [ ] Document go-live date and time
- [ ] Update NewOrg README.md (mark SmartWaste Integration as Active)
- [ ] Notify stakeholders that SmartWaste Integration is live
- [ ] Share monitoring report with support team
- [ ] Update Salesforce_NewOrg repository with migration completion status

### Short-Term (Within 1 Week)

- [ ] Train users on SmartWaste Integration features (if needed)
- [ ] Create user documentation (how to view integration logs, troubleshoot errors)
- [ ] Set up alerts for integration failures (email notifications)
- [ ] Review first week monitoring report, identify trends

### Long-Term (Within 1 Month)

- [ ] Audit SmartWaste data accuracy (compare Salesforce vs SmartWaste platform)
- [ ] Review Waste Type mappings (ensure all products are mapped)
- [ ] Document lessons learned from migration
- [ ] Plan any enhancements (additional validation, error handling, etc.)

---

## Troubleshooting Guide

### Issue 1: Flow Not Triggering

**Symptoms**: `Date_Added_to_SmartWaste__c` not auto-populating on Job creation

**Diagnosis**:
```bash
# Check flow is Active
sf data query --query "SELECT Definition.DeveloperName, Status FROM Flow WHERE Definition.DeveloperName = 'Populate_Date_Added_to_Smart_Waste_Field'" --target-org NewOrg --use-tooling-api
```

**Possible Causes**:
- Flow in Draft status (not Active)
- Flow trigger criteria not met (check flow logic)
- Flow has errors (check Debug Log)

**Resolution**:
1. Activate flow (if Draft)
2. Review flow logic (ensure trigger is Before Save on Job__c)
3. Check Debug Log for flow errors (Setup → Debug Logs)

---

### Issue 2: Scheduled Job Not Running

**Symptoms**: No Apex Job records for SmartWasteIntegrationBatch at expected time

**Diagnosis**:
```bash
# Check scheduled job exists
sf data query --query "SELECT CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE '%SmartWaste%'" --target-org NewOrg
```

**Possible Causes**:
- Job not scheduled (no CronTrigger record)
- Job aborted manually
- Salesforce platform maintenance (scheduled jobs delayed)

**Resolution**:
1. Re-schedule job (Phase 2, Step 2.1)
2. Check Salesforce Trust status (https://status.salesforce.com)
3. Wait for next scheduled run time

---

### Issue 3: API Connection Failed

**Symptoms**: Batch job completes but all Jobs fail with "API connection error"

**Diagnosis**:
- Check Named Credential "SmartWasteAPI" is configured
- Test API connectivity (Phase 3, Step 3.3)
- Review Debug Log for HTTP errors

**Possible Causes**:
- Incorrect API credentials (SmartWasteAPI__mdt)
- Named Credential misconfigured (endpoint URL wrong)
- SmartWaste platform down (check with SmartWaste support)
- Firewall blocking API calls (contact Salesforce support)

**Resolution**:
1. Verify API credentials in SmartWasteAPI__mdt
2. Check Named Credential endpoint URL (Setup → Named Credentials)
3. Test API connectivity manually (Execute Anonymous Apex)
4. Contact SmartWaste support if platform is down

---

### Issue 4: Jobs Failing with "Missing Site ID"

**Symptoms**: Integration logs show "Site does not have SmartWaste_Id__c" error

**Diagnosis**:
```bash
# Query Sites without SmartWaste_Id__c
sf data query --query "SELECT Id, Name, SmartWaste_Id__c FROM Site__c WHERE SmartWaste_Id__c = null LIMIT 100" --target-org NewOrg
```

**Possible Causes**:
- Sites not linked to SmartWaste platform
- SmartWaste_Id__c field not populated

**Resolution**:
1. Populate SmartWaste_Id__c on Site records (obtain IDs from SmartWaste platform)
2. OR exclude these Sites from integration (set Account.SmartWaste_Integration_Enabled__c = false)
3. Train users to ensure Sites have SmartWaste_Id__c before creating Jobs

---

### Issue 5: Jobs Failing with "Invalid Product ID"

**Symptoms**: Integration logs show "Waste Type not mapped" or "Invalid product ID" error

**Diagnosis**:
```bash
# Query Waste Types without SmartWaste mapping
sf data query --query "SELECT MasterLabel, SmartWaste_Id__c FROM Waste_Type__mdt WHERE SmartWaste_Id__c = null" --target-org NewOrg
```

**Possible Causes**:
- Waste Type not mapped in Waste_Type__mdt
- SmartWaste Product ID incorrect (product doesn't exist in SmartWaste)

**Resolution**:
1. Add missing Waste Type mappings (Phase 3, Step 3.2a)
2. Verify Product IDs with SmartWaste platform
3. Update incorrect Product IDs in Waste_Type__mdt

---

### Issue 6: Batch Job Taking Too Long

**Symptoms**: SmartWasteIntegrationBatch runs for hours, causing performance issues

**Diagnosis**:
- Check number of Jobs being processed (Setup → Apex Jobs)
- Check batch size (default 200)

**Possible Causes**:
- Too many Jobs eligible for integration (backlog)
- Batch size too large (API timeout)
- SmartWaste API slow response times

**Resolution**:
1. Reduce batch size (modify batch invocation):
```apex
Database.executeBatch(new SmartWasteIntegrationBatch(), 50); // Smaller batch size
```
2. Re-schedule batch job with smaller batch size
3. Contact SmartWaste support about API performance

---

### Issue 7: Integration Logs Not Being Deleted

**Symptoms**: SmartWaste_Integration_Log__c record count keeps growing

**Diagnosis**:
```bash
# Check log cleanup scheduled job
sf data query --query "SELECT CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name = 'SmartWaste Log Cleanup'" --target-org NewOrg

# Check if logs older than 30 days exist
sf data query --query "SELECT COUNT() FROM SmartWaste_Integration_Log__c WHERE CreatedDate < LAST_N_DAYS:30" --target-org NewOrg
```

**Possible Causes**:
- Log cleanup job not scheduled
- Log cleanup job failing (check Apex Jobs for errors)
- No logs older than 30 days (expected behavior)

**Resolution**:
1. Schedule log cleanup job (Phase 2, Step 2.2)
2. Check Apex Jobs for SmartWasteLogCleanupScheduled errors
3. Manually execute batch to clear backlog:
```apex
Database.executeBatch(new SmartWasteLogCleanupScheduled(), 200);
```

---

## Summary

### Migration Phases Recap

| Phase | Duration | Complexity | Rollback | Status |
|-------|----------|------------|----------|--------|
| **Phase 0** | 1 hour | Low | N/A | ⏳ Pending |
| **Phase 1** | 30 min | Low | Easy | ⏳ Pending |
| **Phase 2** | 15 min | Low | Easy | ⏳ Pending |
| **Phase 3** | 1 hour | Medium | Medium | ⏳ Pending |
| **Phase 4** | 2 hours | Low | N/A | ⏳ Pending |
| **Phase 5** | Ongoing | Low | Easy | ⏳ Pending |

**Total Estimated Time**: 4.75 hours (excluding Phase 5 ongoing monitoring)

---

### Critical Success Factors

✅ **Before Starting Migration**:
- SmartWaste API credentials for NewOrg environment obtained
- System Administrator access to NewOrg confirmed
- Rollback plan reviewed and understood

✅ **During Migration**:
- All 3 flows activated successfully
- Both scheduled jobs configured and in WAITING state
- Custom metadata verified/updated for NewOrg
- Testing completed without critical errors

✅ **After Migration**:
- First scheduled run completes successfully
- Jobs successfully sent to SmartWaste platform
- Integration logs reviewed, errors addressed
- Week 1 monitoring completed

---

### Expected Outcomes

**Immediately After Migration**:
- ✅ Flows active and triggering on record changes
- ✅ Scheduled jobs ready to run daily
- ✅ Custom metadata configured for NewOrg environment

**Within 24 Hours**:
- ✅ First scheduled integration batch runs at 00:00 UTC
- ✅ Jobs sent to SmartWaste platform
- ✅ Log cleanup batch runs at 08:00 UTC

**Within 1 Week**:
- ✅ 7 successful scheduled runs (integration + cleanup)
- ✅ Environmental compliance reporting operational
- ✅ Integration errors identified and resolved

**Long-Term**:
- ✅ SmartWaste Integration stable in NewOrg production
- ✅ Data quality issues addressed (Waste Type mappings, Site IDs)
- ✅ Users trained on SmartWaste integration features

---

**Migration Plan Complete**
**Ready to Execute**: Follow phases sequentially, complete all checklist items
**Support**: Contact Salesforce administrators or SmartWaste support for issues

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Next Review**: After Phase 5 completion (1 week post-migration)
