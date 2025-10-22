# Email-to-Case Assignment System - NewOrg Migration Plan

**Target Organization:** NewOrg (Recycling Lives Group)
**Source Organization:** OldOrg (Recycling Lives Service)
**Migration Date:** TBD (Pending Review & Approval)
**Status:** 📋 Ready for Review and Deployment

---

## Related Documentation

**This migration plan consolidates the following documentation** (component-based analysis):

1. **EMAIL_TO_CASE_ASSIGNMENT_MASTER.md** - Primary implementation guide from OldOrg
2. **OldOrg State README**: [/tmp/Salesforce_OldOrg_State/email-to-case-assignment/README.md](../../../Salesforce_OldOrg_State/email-to-case-assignment/README.md) - Current verified state
3. **CASE_REOPENING_INCIDENT_2025-10-16.md** - ✅ **CONSOLIDATED** - Incident when rlsServiceCaseAutoAssignTrigger was temporarily deactivated

**Component Analysis - Why Consolidated**:
- Core components: rlsServiceCaseAutoAssign.cls, rlsServiceCaseAutoAssignTest.cls, rlsServiceCaseAutoAssignTrigger.trigger
- Case Reopening Incident is part of version history (V2 - temporary trigger deactivation)
- Deploying V3 to NewOrg includes all fixes and optimizations from V1-V3
- Must be deployed as single unit to avoid version conflicts

**Separate Scenarios** (No Component Overlap):
- ❌ `DOMESTIC_CUSTOMER_EMAIL_ISSUE_FIX.md` - Uses Domestic_Create_Job.flow (different system, see Scenario #18)
- ❌ `USER_LORNA_BARSBY_EMAIL_FIX.md` - User object only (no case assignment logic, see Scenario #28)
- ❌ `DAILY_REMINDER_EMAILS_COMPLETE_GUIDE.md` - Different flows and components (see Scenario #5)

**Complete Mapping**: See [/home/john/Projects/Salesforce/Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md](../../Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md) for full documentation relationship analysis.

**Migration Strategy**: Single deployment of V3 (latest version) which includes all V1-V3 functionality

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Gap Analysis: OldOrg vs NewOrg](#gap-analysis-oldorg-vs-neworg)
3. [Migration Strategy](#migration-strategy)
4. [Pre-Deployment Checklist](#pre-deployment-checklist)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment Verification](#post-deployment-verification)
7. [Rollback Plan](#rollback-plan)
8. [Testing Plan](#testing-plan)
9. [Known Issues & Risks](#known-issues--risks)

---

## Executive Summary

### What We're Migrating

The Email-to-Case Assignment System is a comprehensive automation that intelligently distributes incoming email cases to Customer Service representatives based on workload, key account relationships, and business rules.

**Current Version in OldOrg**: V3 (SOQL Optimization & Kaylie Morris Exemption)
**Last Updated in OldOrg**: October 20, 2025

### Migration Scope

This migration includes:
- ✅ 2 Apex Classes (rlsServiceCaseAutoAssign + Test)
- ✅ 1 Apex Trigger (rlsServiceCaseAutoAssignTrigger)
- ✅ 2 Flows (Case reopening + Email reopening logic)
- ✅ 1 Custom Setting (Case_Auto_Assignment_Settings__c)
- ✅ 2 Custom Fields (Previous_Auto_Assigned_Owner__c, Max_Open_Cases_Per_User__c)
- ✅ Configuration Data (Organization default threshold = 20)

### Expected Benefits

- Automated case distribution reducing manual assignment
- Balanced workload across Customer Service team
- Key account continuity
- Same-day case reassignment to familiar agents
- Prevents overload with threshold-based soft limits

---

## Gap Analysis: OldOrg vs NewOrg

### Current State Comparison (As of October 22, 2025)

| Component | OldOrg Status | NewOrg Status | Gap | Action Required |
|-----------|---------------|---------------|-----|-----------------|
| **rlsServiceCaseAutoAssign.cls** | ✅ Active (V3 - Oct 20, 2025) | ⚠️ Outdated (V1 - Oct 2, 2025) | V3 features missing | ✅ **Deploy V3 code** |
| **rlsServiceCaseAutoAssignTest.cls** | ✅ Active (14 tests - V3) | ⚠️ Outdated (9 tests - V1) | 5 test methods missing | ✅ **Deploy V3 test class** |
| **rlsServiceCaseAutoAssignTrigger** | ✅ Active | ❌ **Inactive** | Trigger not active | ✅ **Activate trigger** |
| **Case_Remove_Case_Owner_if_Reopen_24_Hours** | ✅ Active (V2) | ❌ Draft (V1) | Not active, missing V2 logic | ✅ **Deploy & activate V2** |
| **EmailMessage_Open_Closed_Case_on_Email** | ✅ Active (V4) | ❌ Not Found | Completely missing | ✅ **Deploy & activate V4** |
| **Case_Auto_Assignment_Settings__c** | ✅ Deployed | ❌ Not Found | Custom Setting missing | ✅ **Create custom setting** |
| **Max_Open_Cases_Per_User__c** | ✅ Deployed (Field) | ❌ Not Found | Field missing | ✅ **Deploy field** |
| **Previous_Auto_Assigned_Owner__c** | ✅ Deployed (Case Field) | ❌ Not Found | Case field missing | ✅ **Deploy case field** |
| **Organization Default Setting** | ✅ Configured (threshold=20) | ❌ Not Configured | Data not created | ✅ **Create org default** |

### Missing Features in NewOrg

#### 🚨 Critical Missing Components (System Won't Work)

1. **Custom Setting** - `Case_Auto_Assignment_Settings__c`
   - Required for threshold configuration
   - Without it: Apex class will use hardcoded default (20)

2. **Case Field** - `Previous_Auto_Assigned_Owner__c`
   - Required for same-day reassignment logic
   - Without it: Apex class will fail on Field references

3. **Flow** - `EmailMessage_Open_Closed_Case_on_Email`
   - Required for auto-reopening closed cases
   - Without it: Customer replies won't reopen cases

4. **Active Trigger** - `rlsServiceCaseAutoAssignTrigger`
   - Currently INACTIVE in NewOrg
   - Without it: No automatic case assignment happens

#### ⚠️ Important Missing Features (Reduced Functionality)

5. **V2 Flow** - `Case_Remove_Case_Owner_if_Reopen_24_Hours`
   - Currently Draft in NewOrg, missing V2 logic
   - Missing: Previous_Auto_Assigned_Owner__c capture
   - Impact: Same-day reassignment won't work

6. **V3 Apex Code** - SOQL optimization & Kaylie exemption
   - NewOrg has old V1 code (Oct 2, 2025)
   - Missing:
     - Recursion prevention guard
     - Query caching (RecordType, Queue IDs)
     - Kaylie Morris exemption
     - 5 additional test methods
   - Impact: Potential SOQL limit errors, Kaylie won't get exemption

### Version Comparison

#### Apex Class: rlsServiceCaseAutoAssign

| Feature | OldOrg (V3) | NewOrg (Current) | Status |
|---------|-------------|------------------|--------|
| Threshold-based assignment | ✅ | ✅ | ✅ Present |
| Same-day previous owner | ✅ | ⚠️ Partial | ⚠️ Code present, field missing |
| Key account assignment | ✅ | ✅ | ✅ Present |
| Kaylie Morris exemption | ✅ | ❌ | ❌ Missing |
| Recursion prevention | ✅ | ❌ | ❌ Missing |
| Query caching (SOQL optimization) | ✅ | ❌ | ❌ Missing |
| Test coverage | 14 methods | 9 methods | ⚠️ 5 tests missing |

#### Triggers

| Trigger | OldOrg | NewOrg | Status |
|---------|--------|--------|--------|
| rlsServiceCaseAutoAssignTrigger | **Active** | **Inactive** | ❌ Must activate |

#### Flows

| Flow | OldOrg | NewOrg | Status |
|------|--------|--------|--------|
| Case_Remove_Case_Owner_if_Reopen_24_Hours | V2 Active | V1 Draft | ❌ Deploy & activate V2 |
| EmailMessage_Open_Closed_Case_on_Email | V4 Active | Not Found | ❌ Deploy & activate V4 |

---

## Migration Strategy

### Approach: Consolidated Deployment

We will deploy all components together in a specific order to ensure dependencies are met.

### Deployment Order (Critical)

```
Phase 1: Foundation (Custom Objects & Fields)
   ├── Deploy Case_Auto_Assignment_Settings__c (Custom Setting)
   ├── Deploy Max_Open_Cases_Per_User__c (Custom Setting Field)
   └── Deploy Previous_Auto_Assigned_Owner__c (Case Field)

Phase 2: Apex Code (Classes & Trigger)
   ├── Deploy rlsServiceCaseAutoAssign.cls (V3)
   ├── Deploy rlsServiceCaseAutoAssignTest.cls (V3)
   └── Deploy rlsServiceCaseAutoAssignTrigger.trigger (keep inactive for now)

Phase 3: Flows
   ├── Deploy Case_Remove_Case_Owner_if_Reopen_24_Hours (V2)
   └── Deploy EmailMessage_Open_Closed_Case_on_Email (V4)

Phase 4: Configuration & Data
   ├── Create Organization Default Custom Setting (Max=20)
   ├── Activate Flows (both V2 and V4)
   └── Activate Trigger (rlsServiceCaseAutoAssignTrigger)

Phase 5: Verification
   ├── Run all 14 test methods
   ├── Create test case in "Customer Service Email" queue
   └── Verify automatic assignment works
```

### Why This Order?

1. **Fields First**: Apex code references custom fields, so they must exist before code deployment
2. **Code Before Flows**: Flows call Apex trigger which calls Apex class
3. **Activate Last**: Activate trigger only after everything is deployed and tested
4. **Flows After Code**: Flows reference fields that Apex expects to exist

---

## Pre-Deployment Checklist

### ✅ Prerequisites Verification

Before starting deployment, verify the following:

#### 1. Org Access & Permissions
- [ ] Confirmed deployment user has "Modify All Data" permission
- [ ] Confirmed deployment user can deploy Apex, Flows, and Custom Objects
- [ ] Confirmed deployment user can create Custom Settings data

#### 2. Environment Check
- [ ] NewOrg is accessible and operational
- [ ] Confirmed this is the correct target org (not production, if testing first)
- [ ] Backup of NewOrg current state created (if applicable)

#### 3. Dependencies Check
- [ ] "Customer Service Email" Queue exists in NewOrg
- [ ] Customer Service users exist and have queue access
- [ ] Email Record Type exists for Case object
- [ ] Email-to-Case is configured in NewOrg

#### 4. Conflict Check
- [ ] No active deployments currently running in NewOrg
- [ ] No scheduled maintenance windows that would interrupt deployment
- [ ] Confirmed rlsServiceCaseAutoAssignTrigger is currently INACTIVE (to prevent premature execution)

#### 5. Test Data Preparation
- [ ] Identified test users for verification (at least 2 CS users)
- [ ] Prepared test email address for creating test case
- [ ] Identified test Account with CS_Contact__c for key account testing

#### 6. Communication
- [ ] Stakeholders notified of deployment window
- [ ] Customer Service team notified that automation is being deployed
- [ ] Rollback plan communicated and understood

---

## Pre-Deployment Environment Verification

**CRITICAL**: Execute these verification steps BEFORE starting any deployment. This ensures all dependencies exist in NewOrg and identifies any configuration differences from OldOrg.

### Step 1: Verify Queue Exists

**Query**:
```bash
sf data query --query "SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'Queue' AND (DeveloperName LIKE '%Customer%Service%' OR Name LIKE '%Customer%Service%')" --target-org NewOrg
```

**Expected Result**: Should return 1 queue

**Example Output**:
```
Id: 00GXq000...
DeveloperName: Customer_Service_Email  (or similar)
Name: Customer Service Email
```

**✅ If Queue Exists**: Note the exact DeveloperName for reference
**❌ If Queue Missing**: STOP - Queue must be created before proceeding
**⚠️ If Name Different**: Note the difference - may need to update Apex code

**Configuration Table**:
| Component | OldOrg Value | NewOrg Value | Match? | Action |
|-----------|--------------|--------------|--------|--------|
| Queue DeveloperName | Customer_Service_Email | [YOUR RESULT] | [ ] Yes / [ ] No | Update code if different |
| Queue ID | 00GSj000001EAgXMAW | [YOUR RESULT] | N/A | Used by Apex cache |

---

### Step 2: Verify Record Types Exist

**Query**:
```bash
sf data query --query "SELECT Id, DeveloperName, Name, IsActive FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName IN ('Email', 'Paperwork_Compliance', 'RLES_Invoicing', 'RLES_Purchase_Ledger') ORDER BY DeveloperName" --target-org NewOrg
```

**Expected Result**: Should return 4 RecordTypes, all Active

**Example Output**:
```
| DeveloperName | Name | IsActive |
|---------------|------|----------|
| Email | Email | true |
| Paperwork_Compliance | RLES Compliance | true |
| RLES_Invoicing | RLES Invoicing | true |
| RLES_Purchase_Ledger | RLES Purchase Ledger | true |
```

**✅ All 4 Present and Active**: Proceed to next step
**❌ Missing RecordTypes**: Create missing RecordTypes before proceeding
**⚠️ Some Inactive**: Activate required RecordTypes

**Configuration Table**:
| RecordType | OldOrg ID | NewOrg ID | Active in NewOrg? | Used By |
|------------|-----------|-----------|-------------------|---------|
| Email | 012Sj0000004DZlIAM | [YOUR RESULT] | [ ] Yes | Apex class, Flow 2 |
| Paperwork_Compliance | 0128e000000oPy2AAE | [YOUR RESULT] | [ ] Yes | Flow 2 |
| RLES_Invoicing | 012Sj0000006IK1IAM | [YOUR RESULT] | [ ] Yes | Flow 2 |
| RLES_Purchase_Ledger | 012Sj0000006ILdIAM | [YOUR RESULT] | [ ] Yes | Flow 2 |

---

### Step 3: Verify Customer Service Users

**Query**:
```bash
sf data query --query "SELECT Id, Name, Email, IsActive FROM User WHERE Profile.Name LIKE '%Customer%Service%' AND IsActive = true ORDER BY Name" --target-org NewOrg
```

**Expected Result**: Should return multiple active CS users

**Example Output**:
```
| Name | Email | IsActive |
|------|-------|----------|
| User 1 | user1@example.com | true |
| User 2 | user2@example.com | true |
[etc...]
```

**✅ Multiple Users Found**: Note the count (OldOrg has 8 users)
**❌ No Users Found**: STOP - Need to provision CS users first
**⚠️ Different Count**: Note the difference - affects workload distribution

**Configuration Table**:
| Metric | OldOrg Value | NewOrg Value | Match? | Notes |
|--------|--------------|--------------|--------|-------|
| CS User Count | 8 | [YOUR RESULT] | [ ] Yes / [ ] No | Affects average load |
| Users Under Threshold | 8/8 (100%) | [TO BE CHECKED POST-DEPLOY] | N/A | Monitor after go-live |

---

### Step 4: Check Current Case Volume

**Query**:
```bash
sf data query --query "SELECT COUNT(Id) total FROM Case WHERE Status NOT IN ('Closed', 'Case Closed') AND RecordType.DeveloperName = 'Email'" --target-org NewOrg
```

**Expected Result**: Returns current open case count

**Example Output**:
```
total: [NUMBER]
```

**Purpose**: Establishes baseline before deployment

**Configuration Table**:
| Metric | OldOrg (Oct 22) | NewOrg (Before Deploy) | Notes |
|--------|-----------------|------------------------|-------|
| Open Email Cases | 73 | [YOUR RESULT] | Baseline for monitoring |
| Average per User | 9.13 | [CALCULATE] | Divide total by user count |
| Users Over Threshold | 0 | [TO BE CHECKED] | Should be 0 or low |

---

### Step 5: Verify Trigger Current Status

**Query**:
```bash
sf data query --query "SELECT Name, Status, TableEnumOrId FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Trigger exists and is INACTIVE

**Example Output**:
```
Name: rlsServiceCaseAutoAssignTrigger
Status: Inactive
TableEnumOrId: Case
```

**✅ Inactive**: Good - proceed with deployment
**⚠️ Active**: WARNING - Trigger is already active, may cause issues during deployment
**❌ Not Found**: Trigger will be created during deployment

---

### Step 6: Check Existing Components (Gap Confirmation)

#### Check Apex Classes

**Query**:
```bash
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate FROM ApexClass WHERE Name IN ('rlsServiceCaseAutoAssign', 'rlsServiceCaseAutoAssignTest') ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: May return old versions or nothing

**Document Results**:
| Class | Exists? | Size (chars) | Last Modified | Version |
|-------|---------|--------------|---------------|---------|
| rlsServiceCaseAutoAssign | [ ] Yes / [ ] No | [YOUR RESULT] | [YOUR RESULT] | Will be updated to V3 |
| rlsServiceCaseAutoAssignTest | [ ] Yes / [ ] No | [YOUR RESULT] | [YOUR RESULT] | Will be updated to V3 |

#### Check Custom Setting

**Query**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'Case_Auto_Assignment_Settings'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Likely returns nothing (custom setting doesn't exist)

**Document Result**:
| Component | Exists in NewOrg? | Action Required |
|-----------|-------------------|-----------------|
| Case_Auto_Assignment_Settings__c | [ ] Yes / [ ] No | Will be created in Phase 1 |

#### Check Case Field

**Query**:
```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Case' AND QualifiedApiName = 'Previous_Auto_Assigned_Owner__c'" --target-org NewOrg
```

**Expected Result**: Likely returns nothing (field doesn't exist)

**Document Result**:
| Field | Exists in NewOrg? | Action Required |
|-------|-------------------|-----------------|
| Previous_Auto_Assigned_Owner__c | [ ] Yes / [ ] No | Will be created in Phase 1 |

---

### Pre-Deployment Verification Summary

**Complete this table before proceeding**:

| Verification Item | Status | Notes |
|-------------------|--------|-------|
| ✅ Queue Exists | [ ] Pass / [ ] Fail | DeveloperName: _____________ |
| ✅ RecordTypes (4) Exist | [ ] Pass / [ ] Fail | All active: [ ] Yes / [ ] No |
| ✅ CS Users Exist | [ ] Pass / [ ] Fail | Count: _____ |
| ✅ Trigger is Inactive | [ ] Pass / [ ] Fail | Ready for deployment |
| ✅ Deployment User Permissions | [ ] Pass / [ ] Fail | Modify All Data confirmed |
| ✅ No Active Deployments | [ ] Pass / [ ] Fail | Clear to proceed |

**🚨 STOP IF ANY ITEM FAILS**: Resolve all failures before proceeding with deployment.

---

## Deployment Steps

### Phase 1: Deploy Custom Setting & Fields (Foundation)

**Estimated Time:** 10-15 minutes

#### Step 1.1: Deploy Custom Setting Object

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/objects/Case_Auto_Assignment_Settings__c" \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Component: CustomObject:Case_Auto_Assignment_Settings__c
Status: Deployed
```

**Verification:**
```bash
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'Case_Auto_Assignment_Settings'" --target-org NewOrg --use-tooling-api
```

#### Step 1.2: Deploy Case Field

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/objects/Case/fields/Previous_Auto_Assigned_Owner__c.field-meta.xml" \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Component: CustomField:Case.Previous_Auto_Assigned_Owner__c
Status: Deployed
```

**Verification:**
```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Case' AND QualifiedApiName = 'Previous_Auto_Assigned_Owner__c'" --target-org NewOrg
```

#### Step 1.3: Create Organization Default Custom Setting

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
Case_Auto_Assignment_Settings__c orgDefault = new Case_Auto_Assignment_Settings__c(
    Name = 'OrgDefaults',
    Max_Open_Cases_Per_User__c = 20
);
insert orgDefault;
System.debug('Created org default: ' + orgDefault.Id);
EOF
```

**Expected Output:**
```
USER_DEBUG|Created org default: a00Sq000000XXXXX
```

**Verification:**
```bash
sf data query --query "SELECT Name, Max_Open_Cases_Per_User__c FROM Case_Auto_Assignment_Settings__c" --target-org NewOrg
```

**Expected Result:**
```
Name: OrgDefaults
Max_Open_Cases_Per_User__c: 20
```

✅ **Phase 1 Complete** - Foundation is ready

---

### Phase 2: Deploy Apex Code

**Estimated Time:** 3-5 minutes

#### Step 2.1: Deploy Apex Classes with Tests

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/classes" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "rlsServiceCaseAutoAssignTest" \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Components:
  - ApexClass:rlsServiceCaseAutoAssign (Deployed)
  - ApexClass:rlsServiceCaseAutoAssignTest (Deployed)

Test Results: 14/14 Passing (100%)
Test Execution Time: ~40 seconds
Code Coverage: >75%
```

**If Deployment Fails:**

**Common Issue 1**: "Previous_Auto_Assigned_Owner__c field not found"
- **Cause**: Phase 1 Step 1.2 didn't complete successfully
- **Solution**: Re-run Step 1.2, then retry this deployment

**Common Issue 2**: "Case_Auto_Assignment_Settings__c not found"
- **Cause**: Phase 1 Step 1.1 didn't complete successfully
- **Solution**: Re-run Step 1.1, then retry this deployment

**Common Issue 3**: Test failures
- **Cause**: Data issues or org-specific configuration
- **Solution**: Review test failure details, address specific test issues

**Verification:**
```bash
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name IN ('rlsServiceCaseAutoAssign', 'rlsServiceCaseAutoAssignTest')" --target-org NewOrg --use-tooling-api
```

**Expected:**
- Both classes present
- LastModifiedDate = today
- LengthWithoutComments: ~27,000 (main), ~36,000 (test)

#### Step 2.2: Deploy Trigger (Inactive)

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/triggers" \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Component: ApexTrigger:rlsServiceCaseAutoAssignTrigger
Status: Deployed (Inactive)
```

**Verification:**
```bash
sf data query --query "SELECT Name, TableEnumOrId, Status FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger'" --target-org NewOrg --use-tooling-api
```

**Expected:**
```
Name: rlsServiceCaseAutoAssignTrigger
TableEnumOrId: Case
Status: Inactive  ← Should still be Inactive
```

✅ **Phase 2 Complete** - Apex code is deployed

---

### Phase 3: Deploy Flows

**Estimated Time:** 5-10 minutes

#### Step 3.1: Deploy Case Reopening Flow (V2)

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/flows/Case_Remove_Case_Owner_if_Reopen_24_Hours.flow-meta.xml" \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Component: Flow:Case_Remove_Case_Owner_if_Reopen_24_Hours
Status: Deployed (Draft)
```

**🚨 IMPORTANT**: Flow deploys as Draft by default via API

#### Step 3.2: Activate Flow V2 (Manual)

**Action Required**: Go to Salesforce UI

1. Navigate to: **Setup → Flows**
2. Find: "Case_Remove_Case_Owner_if_Reopen_24_Hours"
3. Click the flow name
4. Verify latest version shows the Previous_Auto_Assigned_Owner__c assignment step
5. Click **Activate**
6. Confirm activation

**Verification (after activation):**
```bash
sf data query --query "SELECT DefinitionId, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'Case_Remove_Case_Owner_if_Reopen_24_Hours' ORDER BY VersionNumber DESC LIMIT 1" --target-org NewOrg --use-tooling-api
```

**Expected:**
```
VersionNumber: 2 (or higher if re-deployed)
Status: Active  ← Should be Active now
```

#### Step 3.3: Deploy Email Reopening Flow (V4)

```bash
sf project deploy start \
  --source-dir "email-to-case-assignment/code/flows/EmailMessage_Open_Closed_Case_on_Email.flow-meta.xml" \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output:**
```
✅ Deploy Succeeded
Component: Flow:EmailMessage_Open_Closed_Case_on_Email
Status: Deployed (Draft)
```

#### Step 3.4: Activate Email Reopening Flow (Manual)

**Action Required**: Go to Salesforce UI

1. Navigate to: **Setup → Flows**
2. Find: "EmailMessage_Open_Closed_Case_on_Email"
3. Click the flow name
4. Verify flow logic checks for RecordTypes: Email, Paperwork_Compliance, etc.
5. Click **Activate**
6. Confirm activation

**Verification (after activation):**
```bash
sf data query --query "SELECT DefinitionId, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'EmailMessage_Open_Closed_Case_on_Email' ORDER BY VersionNumber DESC LIMIT 1" --target-org NewOrg --use-tooling-api
```

**Expected:**
```
VersionNumber: 4 (or higher if re-deployed)
Status: Active  ← Should be Active now
```

✅ **Phase 3 Complete** - Flows are deployed and activated

---

### Phase 4: Activate Trigger

**Estimated Time:** 2-3 minutes

**🚨 CRITICAL STEP**: This activates the entire automation system

#### Step 4.1: Final Pre-Activation Checklist

Before activating trigger, verify ALL of the following:

```bash
# Check Apex classes deployed
sf data query --query "SELECT Name FROM ApexClass WHERE Name IN ('rlsServiceCaseAutoAssign', 'rlsServiceCaseAutoAssignTest')" --target-org NewOrg --use-tooling-api

# Expected: 2 records returned

# Check custom setting exists
sf data query --query "SELECT Name, Max_Open_Cases_Per_User__c FROM Case_Auto_Assignment_Settings__c WHERE Name = 'OrgDefaults'" --target-org NewOrg

# Expected: 1 record with Max_Open_Cases_Per_User__c = 20

# Check Case field exists
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Case' AND QualifiedApiName = 'Previous_Auto_Assigned_Owner__c'" --target-org NewOrg

# Expected: 1 record

# Check flows are ACTIVE
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName IN ('Case_Remove_Case_Owner_if_Reopen_24_Hours', 'EmailMessage_Open_Closed_Case_on_Email') AND Status = 'Active'" --target-org NewOrg --use-tooling-api

# Expected: 2 records with Status = 'Active'
```

**If ANY check fails**: STOP and resolve the issue before proceeding

#### Step 4.2: Activate Trigger

**Method 1: Via Apex (Recommended)**

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
ApexTrigger trig = [SELECT Id, Status FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger' LIMIT 1];
trig.Status = 'Active';
update trig;
System.debug('Trigger activated: ' + trig.Id);
EOF
```

**Method 2: Via Metadata API (Alternative)**

If Method 1 doesn't work, manually edit trigger-meta.xml:

1. Retrieve trigger: `sf project retrieve start -o NewOrg -m "ApexTrigger:rlsServiceCaseAutoAssignTrigger"`
2. Edit `.trigger-meta.xml` file: Change `<status>Inactive</status>` to `<status>Active</status>`
3. Deploy: `sf project deploy start --source-dir force-app/main/default/triggers --target-org NewOrg`

**Verification:**
```bash
sf data query --query "SELECT Name, TableEnumOrId, Status FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger'" --target-org NewOrg --use-tooling-api
```

**Expected:**
```
Name: rlsServiceCaseAutoAssignTrigger
TableEnumOrId: Case
Status: Active  ← NOW Active!
```

✅ **Phase 4 Complete** - System is fully activated

---

## Post-Deployment Verification

**Estimated Time:** 15-20 minutes

### Test 1: Manual Case Assignment (Quick Test)

**Objective**: Verify trigger fires and Apex code executes without errors

#### Step 1: Create Test Case in Queue

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
// Get Queue ID
Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Email' LIMIT 1].Id;

// Get Email RecordType
Id emailRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Email' LIMIT 1].Id;

// Create test case
Case testCase = new Case(
    Subject = 'TEST - Email Assignment Verification',
    Description = 'Created to verify auto-assignment works after migration',
    Origin = 'Email',
    Status = 'New',
    RecordTypeId = emailRT,
    OwnerId = queueId
);
insert testCase;

System.debug('Test case created: ' + testCase.Id);

// Wait a moment for trigger to process
Test.startTest();
Test.stopTest();

// Check assignment
Case updatedCase = [SELECT Id, CaseNumber, OwnerId, Owner.Name FROM Case WHERE Id = :testCase.Id];
System.debug('Case ' + updatedCase.CaseNumber + ' assigned to: ' + updatedCase.Owner.Name);
EOF
```

**Expected Output:**
```
USER_DEBUG|Test case created: 500Sq000XXXXXX
USER_DEBUG|Case 00XXXXX assigned to: [CS User Name]
```

**✅ Success Criteria:**
- Case OwnerId changed from Queue to a User
- No errors in debug log
- User has fewer open cases than threshold

**❌ If Assignment Didn't Happen:**
1. Check trigger is Active: `sf data query --query "SELECT Status FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger'" --target-org NewOrg --use-tooling-api`
2. Check debug logs for errors
3. Verify queue name matches: Should be "Customer_Service_Email"

### Test 2: Threshold Logic Verification

**Objective**: Verify threshold-based filtering works correctly

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
// Get current case counts
List<AggregateResult> counts = [
    SELECT OwnerId, COUNT(Id) caseCount
    FROM Case
    WHERE Status NOT IN ('Closed', 'Case Closed')
      AND RecordType.DeveloperName = 'Email'
    GROUP BY OwnerId
];

System.debug('Current case distribution:');
for (AggregateResult ar : counts) {
    System.debug('  User: ' + ar.get('OwnerId') + ' - Cases: ' + ar.get('caseCount'));
}

// Get threshold from custom setting
Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getInstance();
System.debug('Configured threshold: ' + settings.Max_Open_Cases_Per_User__c);
EOF
```

**✅ Success Criteria:**
- Custom setting returns 20
- Case distribution shows counts
- New cases assign to users under threshold

### Test 3: Key Account Assignment

**Objective**: Verify key account CS_Contact__c assignment works

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
// Find an account with CS Contact
Account testAcct = [SELECT Id, Name, CS_Contact__c, CS_Contact__r.Name FROM Account WHERE CS_Contact__c != null LIMIT 1];
System.debug('Test Account: ' + testAcct.Name + ', CS Contact: ' + testAcct.CS_Contact__r.Name);

// Get Queue and RecordType
Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Email' LIMIT 1].Id;
Id emailRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Email' LIMIT 1].Id;

// Create case for this account
Case keyAccountCase = new Case(
    AccountId = testAcct.Id,
    Subject = 'TEST - Key Account Assignment',
    Origin = 'Email',
    Status = 'New',
    RecordTypeId = emailRT,
    OwnerId = queueId
);
insert keyAccountCase;

// Check assignment
Case updatedCase = [SELECT Id, CaseNumber, OwnerId, Owner.Name FROM Case WHERE Id = :keyAccountCase.Id];
System.debug('Case assigned to: ' + updatedCase.Owner.Name + ' (Expected: ' + testAcct.CS_Contact__r.Name + ')');

// Verify match
if (updatedCase.OwnerId == testAcct.CS_Contact__c) {
    System.debug('✅ KEY ACCOUNT ASSIGNMENT WORKS');
} else {
    System.debug('⚠️ Key account assigned to different user (may be over threshold)');
}
EOF
```

**✅ Success Criteria:**
- Case assigns to CS_Contact__c if they're under threshold
- If CS Contact over threshold, assigns to lowest workload user

### Test 4: Same-Day Previous Owner Reassignment

**Objective**: Verify reopened cases return to previous owner

```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
// Get a CS user
User csUser = [SELECT Id, Name FROM User WHERE IsActive = true AND Profile.Name LIKE '%Customer Service%' LIMIT 1];
Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Customer_Service_Email' LIMIT 1].Id;
Id emailRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Email' LIMIT 1].Id;

// Create and assign case
Case testCase = new Case(
    Subject = 'TEST - Same Day Reassignment',
    Origin = 'Email',
    Status = 'New',
    RecordTypeId = emailRT,
    OwnerId = csUser.Id,
    Previous_Auto_Assigned_Owner__c = csUser.Id
);
insert testCase;
System.debug('Case created and assigned to: ' + csUser.Name);

// Simulate reopening (trigger the flow logic manually for testing)
testCase.Status = 'Reopen';
testCase.OwnerId = queueId; // Back to queue
update testCase;
System.debug('Case moved to queue (simulating reopen)');

// Check if reassigned to previous owner
Test.startTest();
Test.stopTest();

Case finalCase = [SELECT Id, OwnerId, Owner.Name, Previous_Auto_Assigned_Owner__r.Name FROM Case WHERE Id = :testCase.Id];
System.debug('Case reassigned to: ' + finalCase.Owner.Name);
System.debug('Previous owner was: ' + finalCase.Previous_Auto_Assigned_Owner__r.Name);

if (finalCase.OwnerId == finalCase.Previous_Auto_Assigned_Owner__c) {
    System.debug('✅ SAME-DAY REASSIGNMENT WORKS');
} else {
    System.debug('⚠️ Assigned to different user (previous owner may be over threshold)');
}
EOF
```

**✅ Success Criteria:**
- Case returns to previous owner if they're under threshold
- If previous owner over threshold, assigns to lowest workload user

### Test 5: Flow Activation Verification

**Objective**: Verify both flows are active and working

```bash
# Check flow statuses
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status, ProcessType FROM Flow WHERE Definition.DeveloperName IN ('Case_Remove_Case_Owner_if_Reopen_24_Hours', 'EmailMessage_Open_Closed_Case_on_Email') ORDER BY Definition.DeveloperName, VersionNumber DESC" --target-org NewOrg --use-tooling-api
```

**Expected:**
```
Case_Remove_Case_Owner_if_Reopen_24_Hours | Version 2+ | Active | AutoLaunchedFlow
EmailMessage_Open_Closed_Case_on_Email    | Version 4+ | Active | AutoLaunchedFlow
```

**✅ Success Criteria:**
- Both flows show Status = 'Active'
- Version numbers match or exceed OldOrg versions

---

## Rollback Plan

**If critical issues are discovered post-deployment:**

### Immediate Rollback (Quick - 2 minutes)

**Deactivate Trigger Only**:
```bash
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
ApexTrigger trig = [SELECT Id, Status FROM ApexTrigger WHERE Name = 'rlsServiceCaseAutoAssignTrigger' LIMIT 1];
trig.Status = 'Inactive';
update trig;
System.debug('Trigger deactivated - auto-assignment stopped');
EOF
```

**Effect**: Stops all automatic case assignment immediately. Cases will queue normally but won't auto-assign.

**Use When**: Critical errors in assignment logic causing major issues

### Partial Rollback (Moderate - 10 minutes)

**Deactivate Trigger + Flows**:
1. Deactivate trigger (see above)
2. Navigate to Setup → Flows
3. Deactivate "Case_Remove_Case_Owner_if_Reopen_24_Hours"
4. Deactivate "EmailMessage_Open_Closed_Case_on_Email"

**Effect**: Stops auto-assignment and auto-reopening. System returns to manual operation.

**Use When**: Issues with both assignment and reopening logic

### Full Rollback (Complete - 30-60 minutes)

**Remove All Components**:

⚠️ **Warning**: This will delete data and cannot be easily undone

```bash
# Delete Apex classes
sf project delete source --metadata "ApexClass:rlsServiceCaseAutoAssign" --metadata "ApexClass:rlsServiceCaseAutoAssignTest" --target-org NewOrg --no-prompt

# Delete Trigger
sf project delete source --metadata "ApexTrigger:rlsServiceCaseAutoAssignTrigger" --target-org NewOrg --no-prompt

# Delete Flows (via UI - cannot delete via CLI if active)

# Delete Custom Setting Data
sf apex run --target-org NewOrg --file /dev/stdin <<'EOF'
delete [SELECT Id FROM Case_Auto_Assignment_Settings__c];
System.debug('Custom setting data deleted');
EOF

# Delete Case Field
sf project delete source --metadata "CustomField:Case.Previous_Auto_Assigned_Owner__c" --target-org NewOrg --no-prompt

# Delete Custom Setting Object
sf project delete source --metadata "CustomObject:Case_Auto_Assignment_Settings__c" --target-org NewOrg --no-prompt
```

**Use When**: Fundamental issues require complete removal and redesign

---

## Testing Plan

### Pre-Production Testing Recommendations

**If deploying to Sandbox first (Recommended):**

1. **Deploy to Sandbox**: Follow all deployment steps in sandbox
2. **Run Full Test Suite**: Execute all 5 verification tests
3. **Load Testing**: Create 50+ test cases to verify performance
4. **Stress Test**: Simulate high-volume email arrival (trigger recursion scenarios)
5. **User Acceptance Testing**: Have CS team test for 1-2 days
6. **Monitor Debug Logs**: Check for any errors or warnings
7. **Performance Check**: Verify SOQL query limits not exceeded

**Once Sandbox Testing Passes:**
- Deploy to Production (NewOrg) using same steps
- Monitor closely for first 24 hours
- Have rollback plan ready

### Production Testing (NewOrg)

**Day 1 - Close Monitoring:**
- Check case assignment every 2-3 hours
- Review debug logs for errors
- Verify workload distribution is balanced
- Confirm threshold logic working correctly

**Week 1 - Regular Monitoring:**
- Daily check of case distribution
- Review any user-reported issues
- Adjust threshold if needed via custom setting

**Month 1 - Periodic Reviews:**
- Weekly review of assignment patterns
- Gather user feedback
- Optimize if needed

---

## Known Issues & Risks

### Known Limitations

1. **Kaylie Morris Exemption is Hardcoded**
   - Kaylie's email is hardcoded in Apex class
   - If Kaylie's email changes, requires code modification
   - **Recommendation**: Consider making this configurable via Custom Setting in future

2. **Queue Name Dependency**
   - System assumes queue name is "Customer_Service_Email"
   - If queue name differs in NewOrg, assignment will fail
   - **Mitigation**: Verify queue name before deployment

3. **RecordType Dependency**
   - System assumes "Email" RecordType exists
   - Cases without RecordType won't auto-assign (by design)
   - **Mitigation**: Ensure all email cases have RecordType assigned

### Potential Risks

#### Risk 1: High-Volume Email Scenario
**Risk**: Multiple simultaneous emails could cause SOQL limit errors
**Likelihood**: Low (V3 has recursion prevention and query caching)
**Impact**: Medium (assignment would fail for that batch)
**Mitigation**: V3 code specifically addresses this with caching and recursion guard

#### Risk 2: Threshold Too Low
**Risk**: 20-case threshold may be too restrictive, causing uneven distribution
**Likelihood**: Medium (depends on CS team size and case volume)
**Impact**: Low (soft limit ensures cases still get assigned)
**Mitigation**: Monitor first week, adjust threshold via Custom Setting if needed

#### Risk 3: Key Account Manager Overload
**Risk**: Key account managers may get overloaded if they have many key accounts
**Likelihood**: Medium
**Impact**: Medium
**Mitigation**: V2 logic respects threshold for key account managers (except Kaylie)

#### Risk 4: Flow Version Confusion
**Risk**: Wrong flow version might be activated in UI
**Likelihood**: Low (following deployment steps carefully)
**Impact**: High (previous owner logic wouldn't work)
**Mitigation**: Verify version numbers match deployment expectations in verification step

### Blockers & Dependencies

**Critical Dependencies:**
- "Customer Service Email" queue must exist
- Email RecordType must exist
- Customer Service user profile must have proper permissions
- Email-to-Case must be configured

**Potential Blockers:**
- NewOrg may have different queue name → Requires Apex code modification
- NewOrg may have different RecordType names → Requires flow modification
- NewOrg may have different user structure → Requires testing adjustment

---

## Migration Readiness Checklist

### Before Requesting Approval

- [x] Gap analysis completed and documented
- [x] All components identified and retrieved from OldOrg
- [x] Deployment steps documented with commands
- [x] Verification tests prepared
- [x] Rollback plan documented
- [x] Known risks identified and mitigated
- [ ] User has reviewed this migration plan
- [ ] Target deployment date agreed upon
- [ ] Stakeholders notified of migration

### Ready for Deployment

**Status**: 📋 Awaiting User Review and Approval

**Next Steps:**
1. User reviews this migration plan
2. User approves deployment approach
3. User confirms deployment date/time
4. Execute deployment following this plan
5. Perform post-deployment verification
6. Monitor system for 24-48 hours

---

## Support & Contact

**Migration Owner**: John Shintu
**Original Developer**: Glen Bagshaw
**Deployment User**: [To be determined]

**For Issues During Migration:**
- Immediate: Trigger deactivation rollback (see Rollback Plan)
- Post-deployment: Monitor debug logs and case assignment patterns
- User feedback: Collect from Customer Service team

---

**Document Status**: ✅ Ready for Review
**Last Updated**: October 22, 2025
**Review Required By**: User (Shintu John)
