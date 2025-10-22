# Producer Portal - NewOrg Deployment Package

**Created**: 2025-10-22
**Target Org**: NewOrg (Recycling Lives Group)
**Migration From**: OldOrg (recyclinglives.my.salesforce.com)
**Deployment Status**: READY FOR DEPLOYMENT
**Estimated Time**: 2-3 hours (including testing)

---

## Executive Summary

This package contains the **missing components** required to complete the Producer Portal migration to NewOrg. The Producer Portal is a mission-critical WEEE compliance system managing £1.5M+ in annual fees for 102 producer companies.

**What's Being Deployed**:
- **Login License Sharing Solution** (Issue #5 fix from OldOrg)
  - 4 Apex classes (2 main + 2 test classes)
  - 4 sharing triggers (Producer_Contract, Producer_Obligation, Producer_Placed_on_Market, User)
- **UX Improvements** (V2.4 from OldOrg)
  - 2 record-triggered/screen flows (status management + feedback)

**Why This Deployment Is Critical**:
- Customer Community Plus **Login** license users currently CANNOT see Producer data in NewOrg
- Missing sharing solution from OldOrg (deployed 2025-10-21 as Issue #5 fix)
- Without this, 14 Login license users have NO access to portal data

---

## Related Documentation

### OldOrg State Documentation (Source of Truth)
- **GitHub URL**: https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/producer-portal
- **Contents**: Complete system documentation, dependency analysis, deployment history
- **Source Docs**: https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/producer-portal/source-docs

### Key References from OldOrg
- **Total Components in OldOrg**: 65 components (28 main + 37 dependencies)
- **Total Files**: 557 files (8 classes + 4 triggers + 3 flows + 5 objects/522 fields + 7 profiles + 1 permission set)
- **Test Coverage**: 100% for all main classes
- **Verified Deploy IDs**: 15 deployments from 2025-10-20 to 2025-10-21

---

## Gap Analysis: OldOrg vs NewOrg

### Components ALREADY in NewOrg ✅

| Component Type | Component Name | Status | Notes |
|----------------|----------------|--------|-------|
| **Apex Classes** | ProducerPlacedOnMarketTriggerHandler | ✅ Exists | Main trigger handler |
| | ProducerPlacedOnMarketTriggerHelper | ✅ Exists | Validation logic (441 lines) |
| | ProducerPlacedOnMarketTriggerTest | ✅ Exists | Test class |
| | Rollup_ProducerContractHandler | ✅ Exists | Rollup handler |
| | Rollup_ProducerObligationHandler | ✅ Exists | Rollup handler |
| | Rollup_ProducerPlacedOnMarketHandler | ✅ Exists | Rollup handler |
| | AutoCreateProducerObligationChargeBatch | ✅ Exists | Batch job |
| | rlcs_AllProducerXMLController | ✅ Exists | EA reporting |
| **Triggers** | ProducerPlacedOnMarketTrigger | ✅ Exists | Main data entry trigger |
| | Rollup_ProducerContractTrigger | ✅ Exists | Rollup trigger |
| | Rollup_ProducerObligationTrigger | ✅ Exists | Rollup trigger |
| | Rollup_ProducerPlacedOnMarketTrigger | ✅ Exists | Rollup trigger |
| | Rollup_ValidationQuestionTrigger | ✅ Exists | Rollup trigger |
| **Objects** | Producer_Contract__c | ✅ Exists | Master agreement |
| | Producer_Obligation__c | ✅ Exists | Annual compliance |
| | Producer_Placed_on_Market__c | ✅ Exists | Quarterly submissions |
| | Validation_Question__c | ✅ Exists | Variance questions |
| | Producer_Obligation_Pricing__c | ✅ Exists | Pricing matrix |
| **Permission Sets** | Customer_Community_Plus | ✅ Exists | Login license permissions |
| **Flows** | Producer_Placed_On_Market_Acknowledge_Best_Action | ✅ Exists | Acknowledgment workflow |
| | Producer_Placed_on_Market_After_Save | ✅ Exists | After save automation |
| | Producer_Placed_on_Market_Before_Save | ✅ Exists | Before save automation |
| | Producer_Obligation_After_Save | ✅ Exists | Obligation automation |
| | Producer_Obligation_Before_Save | ✅ Exists | Obligation automation |
| | Producer_Contract_After_Save | ✅ Exists | Contract automation |
| | Producer_Contract_Before_Delete | ✅ Exists | Contract protection |
| | Manage_Producer_User_Access* | ✅ Exists | Access management flows |

### Components MISSING from NewOrg ❌ (MUST DEPLOY)

| Component Type | Component Name | Status | Deploy Priority | Impact if Missing |
|----------------|----------------|--------|-----------------|-------------------|
| **Apex Classes** | **ProducerSharingHelper** | ❌ MISSING | **P0 CRITICAL** | Login license users cannot see ANY Producer data |
| | **ProducerSharingHelperTest** | ❌ MISSING | **P0 CRITICAL** | Cannot deploy without test class |
| | **UserSharingBackfillHelper** | ❌ MISSING | **P0 CRITICAL** | New users cannot see existing data |
| | **UserSharingBackfillHelperTest** | ❌ MISSING | **P0 CRITICAL** | Cannot deploy without test class |
| **Triggers** | **ProducerContractSharingTrigger** | ❌ MISSING | **P0 CRITICAL** | Contracts not shared with portal users |
| | **ProducerObligationSharingTrigger** | ❌ MISSING | **P0 CRITICAL** | Obligations not shared with portal users |
| | **ProducerPlacedOnMarketSharingTrigger** | ❌ MISSING | **P0 CRITICAL** | MOST CRITICAL: Quarterly submissions not visible |
| | **UserSharingBackfill** | ❌ MISSING | **P0 CRITICAL** | New users require manual backfill |
| **Flows** | Producer_POM_Update_Status | ❌ MISSING | **P1 HIGH** | No automatic status management (UX degradation) |
| | Producer_POM_Acknowledge_Feedback | ❌ MISSING | **P2 MEDIUM** | No user feedback after acknowledgment (UX issue) |

### Gap Analysis Summary

**P0 CRITICAL Components** (MUST deploy before go-live):
- 4 Apex classes (sharing solution)
- 4 Apex triggers (sharing automation)
- **Total**: 8 components

**P1-P2 Components** (UX improvements - can deploy later):
- 2 Flows (status management + feedback screens)
- **Total**: 2 components

**Grand Total Missing**: 10 components (18 files including meta.xml)

---

## Pre-Deployment Environment Verification

### STEP 0: Verify Prerequisites Exist in NewOrg

Before deploying, verify ALL dependencies exist in NewOrg:

```bash
# 1. Verify Custom Objects exist
sf data query --query "SELECT COUNT() FROM Producer_Contract__c" --target-org NewOrg
# Expected: 0 or more (object must exist, data optional)

sf data query --query "SELECT COUNT() FROM Producer_Obligation__c" --target-org NewOrg
# Expected: 0 or more

sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__c" --target-org NewOrg
# Expected: 0 or more

sf data query --query "SELECT COUNT() FROM Validation_Question__c" --target-org NewOrg
# Expected: 0 or more

# 2. Verify Permission Set exists
sf data query --query "SELECT Id, Name FROM PermissionSet WHERE Name = 'Customer_Community_Plus'" --target-org NewOrg
# Expected: 1 record

# 3. Verify Portal Users exist (if migrating existing data)
sf data query --query "SELECT COUNT() FROM User WHERE Profile.UserLicense.Name = 'Customer Community Plus Login' AND IsActive = true" --target-org NewOrg
# Expected: >0 if users already created

# 4. Verify Account object has portal users
sf data query --query "SELECT COUNT() FROM User WHERE ContactId != null AND IsActive = true" --target-org NewOrg
# Expected: >0 portal users with Contacts

# 5. Verify OWD Settings for Producer objects
# Manual check: Setup → Sharing Settings → Producer_Contract__c → External Access = Private
# Manual check: Producer_Obligation__c → External Access = Private
# Manual check: Producer_Placed_on_Market__c → External Access = Private
```

**If ANY verification fails**:
- STOP deployment
- Resolve missing dependencies first
- Re-run verification before proceeding

---

## Deployment Steps (CLI + Manual)

### STEP 1: Deploy Sharing Helper Classes ✅ CLI STEP

**Command**:
```bash
cd /tmp/Salesforce_NewOrg/producer-portal/code
sf project deploy start --source-dir classes/ProducerSharingHelper.cls* --target-org NewOrg --test-level RunSpecifiedTests --tests ProducerSharingHelperTest
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Test Success: 16/16 passing
Code Coverage: ProducerSharingHelper - 100%
```

**Verification**:
```bash
sf data query --query "SELECT Name, ApiVersion FROM ApexClass WHERE Name = 'ProducerSharingHelper'" --target-org NewOrg
# Expected: 1 record
```

**If Deployment Fails**:
- Check error message for missing dependencies
- Verify all Producer objects exist (Producer_Contract__c, Producer_Obligation__c, Producer_Placed_on_Market__c)
- Verify Share objects exist (Producer_Contract__Share, Producer_Obligation__Share, Producer_Placed_on_Market__Share)
- If Share objects missing: Ensure OWD = Private for Producer objects

---

### STEP 2: Deploy User Sharing Backfill Helper ✅ CLI STEP

**Command**:
```bash
sf project deploy start --source-dir classes/UserSharingBackfillHelper.cls* --target-org NewOrg --test-level RunSpecifiedTests --tests UserSharingBackfillHelperTest
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Test Success: 4/4 passing
Code Coverage: UserSharingBackfillHelper - 100%
```

**Verification**:
```bash
sf data query --query "SELECT Name FROM ApexClass WHERE Name = 'UserSharingBackfillHelper'" --target-org NewOrg
# Expected: 1 record
```

---

### STEP 3: Deploy Sharing Triggers ✅ CLI STEP

**CRITICAL**: Deploy triggers AFTER helper classes (triggers depend on ProducerSharingHelper)

**Command**:
```bash
cd /tmp/Salesforce_NewOrg/producer-portal/code
sf project deploy start --source-dir triggers/ --target-org NewOrg --test-level NoTestRun
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Components Deployed:
  - ProducerContractSharingTrigger
  - ProducerObligationSharingTrigger
  - ProducerPlacedOnMarketSharingTrigger
  - UserSharingBackfill
```

**Verification**:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name LIKE '%Sharing%' ORDER BY Name" --target-org NewOrg
# Expected: 4 triggers with Status = Active
```

---

### STEP 4: Deploy UX Improvement Flows ✅ CLI STEP

**Command**:
```bash
cd /tmp/Salesforce_NewOrg/producer-portal/code
sf project deploy start --source-dir flows/ --target-org NewOrg
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Components Deployed:
  - Producer_POM_Update_Status
  - Producer_POM_Acknowledge_Feedback
```

---

### STEP 5: Activate Flows ⚠️ MANUAL UI STEP

**CRITICAL**: Flows deploy as Inactive by default

**Instructions**:
1. Navigate to: **Setup → Flows**
2. Search for: **Producer_POM_Update_Status**
3. Click **Activate** button
4. Repeat for: **Producer_POM_Acknowledge_Feedback**

**Verification (CLI)**:
```bash
sf data query --query "SELECT DeveloperName, ActiveVersion.VersionNumber, LatestVersion.VersionNumber FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback')" --target-org NewOrg
# Expected: ActiveVersion.VersionNumber should equal LatestVersion.VersionNumber for both flows
```

**Note**: If ActiveVersion is null after activation, wait 1-2 minutes for cache refresh, then re-query.

---

### STEP 6: Backfill Sharing for Existing Data ⚠️ MANUAL SCRIPT STEP

**ONLY REQUIRED IF**: Migrating existing Producer data to NewOrg

**SKIP IF**: Starting with fresh data (sharing will be created automatically by triggers)

**Script Location**: `/home/john/Projects/Salesforce/scripts/backfill_producer_sharing.sh`

**Instructions**:
1. Edit script to point to NewOrg:
   ```bash
   ORG_ALIAS="NewOrg"  # Change from OldOrg to NewOrg
   ```

2. Run backfill script:
   ```bash
   bash /home/john/Projects/Salesforce/scripts/backfill_producer_sharing.sh
   ```

3. **Expected Output** (based on OldOrg volumes):
   ```
   Backfilling Producer_Contract__c sharing...
   Success: 186 shares created

   Backfilling Producer_Obligation__c sharing...
   Success: 129 shares created

   Backfilling Producer_Placed_on_Market__c sharing...
   Success: 1,444 shares created

   TOTAL: 1,759 sharing records created
   Elapsed Time: 3-5 minutes
   ```

**Verification**:
```bash
sf data query --query "SELECT COUNT() FROM Producer_Contract__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: >0 (number depends on data volume)

sf data query --query "SELECT COUNT() FROM Producer_Obligation__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: >0

sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: >0 (should be largest number - 1 share per record per portal user)
```

**Performance Considerations**:
- OldOrg backfill took 3 minutes for 1,759 shares
- NewOrg should be similar (3-150 DML statements, <1 second CPU per batch)
- If >10,000 shares needed, consider batching the script

---

### STEP 7: Verify Login License Users Can See Data ⚠️ MANUAL UI STEP

**Test User**: Create or use existing Customer Community Plus Login user

**Instructions**:
1. Navigate to: **Setup → Users**
2. Find Login license user: **Profile.UserLicense.Name = 'Customer Community Plus Login'**
3. Verify permission set assigned: **Customer_Community_Plus** (should already be assigned from OldOrg migration)
4. Login as portal user (via **Login** button or community URL)
5. Navigate to Producer Portal
6. Verify tabs visible:
   - Due Now
   - Additional Information Required
   - Signature Required
   - Completed Submissions
   - Upcoming Dates
7. Verify Producer_Placed_on_Market__c records visible in each tab

**Expected Result**: User should see Producer records for their Account

**If User Cannot See Records**:
- **Check 1**: Permission set assigned?
  ```bash
  sf data query --query "SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Customer_Community_Plus' AND AssigneeId = '<USER_ID>'" --target-org NewOrg
  ```
- **Check 2**: Sharing records exist?
  ```bash
  sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org NewOrg
  ```
- **Check 3**: User has Contact and Account?
  ```bash
  sf data query --query "SELECT ContactId, Contact.AccountId FROM User WHERE Id = '<USER_ID>'" --target-org NewOrg
  ```
- **Check 4**: Run backfill manually for specific user (see Step 6 script)

---

## Code Files Reference

### Apex Classes (4 main + 4 test = 8 files)

1. **ProducerSharingHelper.cls** (197 lines)
   - Purpose: User-based Apex sharing for Login license users
   - Methods:
     - `shareContracts()` - Shares Producer_Contract__c with Account portal users
     - `shareObligations()` - Shares Producer_Obligation__c via parent Contract
     - `sharePlacedOnMarkets()` - Shares Producer_Placed_on_Market__c with Account users
     - `getAccountPortalUsers()` - Queries active portal users (both Customer Community Plus and Login)
   - Dependencies: Producer_Contract__c, Producer_Obligation__c, Producer_Placed_on_Market__c
   - Test Class: ProducerSharingHelperTest.cls

2. **UserSharingBackfillHelper.cls** (102 lines)
   - Purpose: Automatic sharing backfill for new portal users
   - Methods:
     - `backfillSharingForNewUsers()` - @future method to share existing records
     - Private methods: shareContracts, shareObligations, sharePlacedOnMarkets
   - Dependencies: ProducerSharingHelper.cls, User object
   - Test Class: UserSharingBackfillHelperTest.cls

3. **ProducerSharingHelperTest.cls** (16 tests, 100% coverage)
   - Tests: Contract sharing, Obligation sharing, POM sharing, multiple users per Account
   - Creates portal Users (not Groups) for realistic testing

4. **UserSharingBackfillHelperTest.cls** (4 tests, 100% coverage)
   - Tests: New user creation, Contact change, users without Account, empty list

### Triggers (4 triggers = 8 files with meta.xml)

1. **ProducerContractSharingTrigger.trigger** (after insert, after update)
   - Fires when: Producer_Contract__c created or Account__c changes
   - Calls: ProducerSharingHelper.shareContracts()

2. **ProducerObligationSharingTrigger.trigger** (after insert, after update)
   - Fires when: Producer_Obligation__c created or Producer_Contract__c changes
   - Calls: ProducerSharingHelper.shareObligations()

3. **ProducerPlacedOnMarketSharingTrigger.trigger** (after insert, after update)
   - Fires when: Producer_Placed_on_Market__c created or Account__c changes
   - Calls: ProducerSharingHelper.sharePlacedOnMarkets()
   - **MOST CRITICAL**: This drives portal visibility for quarterly submissions

4. **UserSharingBackfill.trigger** (after insert, after update on User)
   - Fires when: ContactId changes (new portal user or user moved to different Account)
   - Calls: UserSharingBackfillHelper.backfillSharingForNewUsers(@future)

### Flows (2 flows)

1. **Producer_POM_Update_Status.flow-meta.xml** (Record-Triggered Flow)
   - Triggers: After Save on Producer_Placed_on_Market__c
   - Purpose: Automatic status updates based on record state
   - Status Transitions:
     - null/Draft → Ready to Acknowledge (data entered)
     - Ready to Acknowledge → Questions Required (acknowledged + questions exist)
     - Questions Required → Pending Director Review (all questions answered)
   - Dependencies: Unanswered_Questions__c field (formula or rollup)

2. **Producer_POM_Acknowledge_Feedback.flow-meta.xml** (Screen Flow)
   - Triggers: Called from Producer_Placed_On_Market_Acknowledge_Best_Action flow
   - Purpose: Shows immediate feedback after acknowledgment
   - Displays: Unanswered question count
   - Redirects: To "Additional Information Required" tab
   - Dependencies: Validation_Question__c object

**Total Files in Package**: 8 + 8 + 2 = **18 files**

---

## Post-Deployment Validation

### Validation Checklist

After completing all deployment steps, verify the following:

#### 1. Apex Classes Deployed
```bash
sf data query --query "SELECT Name, Status, ApiVersion FROM ApexClass WHERE Name IN ('ProducerSharingHelper', 'UserSharingBackfillHelper', 'ProducerSharingHelperTest', 'UserSharingBackfillHelperTest') ORDER BY Name" --target-org NewOrg
# Expected: 4 records with Status = Active
```

#### 2. Triggers Active
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name IN ('ProducerContractSharingTrigger', 'ProducerObligationSharingTrigger', 'ProducerPlacedOnMarketSharingTrigger', 'UserSharingBackfill') ORDER BY Name" --target-org NewOrg
# Expected: 4 records with Status = Active
```

#### 3. Flows Activated
```bash
sf data query --query "SELECT DeveloperName, ActiveVersion.VersionNumber FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback') ORDER BY DeveloperName" --target-org NewOrg
# Expected: 2 records with ActiveVersion.VersionNumber > 0
```

#### 4. Sharing Records Created (if data migrated)
```bash
sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: >0 (if backfill ran successfully)
```

#### 5. Test Coverage Maintained
```bash
sf apex run test --class-names ProducerSharingHelperTest,UserSharingBackfillHelperTest --result-format human --target-org NewOrg
# Expected: All tests passing, 100% coverage for both helper classes
```

#### 6. Login License User Access
```bash
# Login as a Customer Community Plus Login user
# Navigate to Producer Portal
# Verify all tabs visible and Producer records accessible
# Expected: User can see Producer records for their Account
```

#### 7. New User Automatic Sharing
```bash
# Create a new portal user (Customer Community Plus Login)
# Assign Contact and Account
# Wait 1-2 minutes for @future to complete
# Verify sharing records created:
sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE UserOrGroupId = '<NEW_USER_ID>'" --target-org NewOrg
# Expected: >0 (automatic backfill should have run)
```

---

## Rollback Procedures

### Immediate Rollback (if deployment fails mid-process)

**If Step 1-2 fails (Apex classes)**:
```bash
# Delete deployed classes
sf apex delete --metadata ApexClass:ProducerSharingHelper --target-org NewOrg
sf apex delete --metadata ApexClass:UserSharingBackfillHelper --target-org NewOrg
sf apex delete --metadata ApexClass:ProducerSharingHelperTest --target-org NewOrg
sf apex delete --metadata ApexClass:UserSharingBackfillHelperTest --target-org NewOrg
```

**If Step 3 fails (Triggers)**:
```bash
# Delete deployed triggers
sf apex delete --metadata ApexTrigger:ProducerContractSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:ProducerObligationSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:ProducerPlacedOnMarketSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:UserSharingBackfill --target-org NewOrg
```

**If Step 4-5 fails (Flows)**:
- Flows deploy as Inactive, no rollback needed (simply don't activate)
- If activated and causing issues: Navigate to Setup → Flows → Deactivate

### Partial Rollback (if sharing causes performance issues)

**Deactivate Triggers (keep classes deployed)**:
```bash
# Manually deactivate triggers via Setup → Apex Triggers
# This stops new sharing creation but keeps existing shares
```

**Delete Sharing Records (keep triggers active)**:
```bash
sf data delete bulk --sobject Producer_Contract__Share --where "RowCause = 'Manual'" --target-org NewOrg
sf data delete bulk --sobject Producer_Obligation__Share --where "RowCause = 'Manual'" --target-org NewOrg
sf data delete bulk --sobject Producer_Placed_on_Market__Share --where "RowCause = 'Manual'" --target-org NewOrg
# WARNING: This breaks Login license user access. Only use if critical performance issue.
```

### Full Rollback (complete removal)

**Step 1**: Deactivate all flows
**Step 2**: Delete all triggers (CLI or Setup)
**Step 3**: Delete sharing records (if created)
**Step 4**: Delete Apex classes

**Time Required**: 10-15 minutes

---

## Testing Plan

### Unit Testing (Automated)

**Covered by Test Classes** (100% coverage):
- ✅ ProducerSharingHelperTest.cls (16 tests)
  - Contract sharing for Customer Community Plus users
  - Contract sharing for Customer Community Plus Login users
  - Obligation sharing via parent Contract's Account
  - POM sharing with multiple users per Account
  - Error handling for missing Account
- ✅ UserSharingBackfillHelperTest.cls (4 tests)
  - New user creation (automatic backfill)
  - Contact change (user moved to different Account)
  - Users without Contact/Account (graceful handling)
  - Empty user list

### Integration Testing (Manual - Required Before Go-Live)

**Test Scenario 1: New Producer Record Creation**
1. Create Producer_Contract__c record with Account__c = Test Account
2. Verify ProducerContractSharingTrigger fires
3. Query Producer_Contract__Share for Manual shares
4. Expected: 1 share per active portal user for that Account

**Test Scenario 2: Existing Record Access**
1. Login as Customer Community Plus Login user
2. Navigate to Producer Portal
3. Verify Producer_Placed_on_Market__c records visible
4. Expected: User sees records for their Account only

**Test Scenario 3: New Portal User Creation**
1. Create new User with Profile = Producer Standard User Login
2. Set ContactId and Contact.AccountId
3. Wait 2 minutes for @future to complete
4. Query sharing records for new user
5. Expected: All existing Producer records for Account are shared

**Test Scenario 4: Account Change**
1. Move existing portal user to different Account (change Contact.AccountId)
2. Wait 2 minutes for @future to complete
3. Verify old Account shares removed
4. Verify new Account shares created
5. Expected: User now sees records for new Account only

**Test Scenario 5: UX Flow Testing**
1. Create Producer_Placed_on_Market__c record (Status = Draft)
2. Enter data and save
3. Verify Producer_POM_Update_Status flow updates Status to "Ready to Acknowledge"
4. Check Acknowledgement_of_Statements__c checkbox
5. Verify Producer_POM_Acknowledge_Feedback flow shows question count
6. Expected: User sees feedback screen with question count and redirect link

### User Acceptance Testing (UAT)

**Test with Real Portal Users** (2-3 users):
1. Login License user (Customer Community Plus Login)
2. Full License user (Customer Community Plus)
3. Director user (for signature testing)

**UAT Scenarios**:
- ✅ Data entry (15-30 categories)
- ✅ Acknowledgment workflow
- ✅ Validation question answering
- ✅ Director signature
- ✅ Status progression (Draft → Questions Required → Pending Director Review → Signed)
- ✅ Feedback after acknowledgment
- ✅ Tab navigation (Due Now, Additional Info, Signature, Completed, Upcoming)

---

## Known Risks & Mitigation

### Risk 1: Performance Impact of Sharing Triggers

**Risk**: 4 new triggers firing on every Producer record save could impact performance

**Likelihood**: LOW (OldOrg processes 1,759 shares in <1 second CPU)

**Mitigation**:
- Triggers only fire on insert/update (not query)
- Sharing logic is bulkified (handles 200 records per transaction)
- @future backfill is asynchronous (doesn't block user operations)
- OldOrg production metrics show <500ms total execution time

**Monitoring**:
```bash
# Query Apex debug logs after deployment
sf apex log list --target-org NewOrg
# Check for LIMIT_USAGE_FOR_NS lines in logs
# CPU Time should be <1000ms per transaction
```

### Risk 2: User Trigger Mixed DML Error

**Risk**: UserSharingBackfill.trigger fires on User object, which can cause mixed DML (setup vs non-setup)

**Likelihood**: MEDIUM (common Salesforce limitation)

**Mitigation**:
- @future method isolates User DML from Producer sharing DML
- Test class uses System.runAs() to avoid mixed DML in tests
- OldOrg production has not encountered mixed DML errors (verified in logs)

**Fallback**: If mixed DML occurs, use Process Builder instead of trigger (same @future logic)

### Risk 3: Missing Portal Role Groups

**Risk**: Solution assumes portal role Groups don't exist (user-based sharing)

**Likelihood**: LOW (verified in OldOrg - Groups don't exist)

**Mitigation**:
- Verify in NewOrg:
  ```bash
  sf data query --query "SELECT COUNT() FROM Group WHERE Type = 'Role' AND RelatedId IN (SELECT Id FROM Account)" --target-org NewOrg
  ```
- If Groups DO exist in NewOrg (unexpected), switch to Group-based sharing (requires code change)

### Risk 4: Backfill Script Timeout

**Risk**: If NewOrg has >10,000 Producer records, backfill script may timeout

**Likelihood**: LOW (OldOrg has 861 records, NewOrg likely similar)

**Mitigation**:
- Script processes 200 records per batch
- Governor limits: 150 DML statements per transaction = 30,000 records max
- If timeout occurs, batch the script (process 5,000 records at a time)

---

## Estimated Deployment Time

**Total Time**: 2-3 hours (including testing)

| Step | Activity | Time | Type |
|------|----------|------|------|
| 0 | Pre-deployment verification | 15 min | CLI queries |
| 1 | Deploy ProducerSharingHelper | 5 min | CLI |
| 2 | Deploy UserSharingBackfillHelper | 5 min | CLI |
| 3 | Deploy 4 sharing triggers | 5 min | CLI |
| 4 | Deploy 2 UX flows | 5 min | CLI |
| 5 | Activate flows (manual UI) | 5 min | Manual |
| 6 | Run backfill script (if data exists) | 5-10 min | Script |
| 7 | Verify Login license user access | 10 min | Manual testing |
| 8 | Post-deployment validation (7 checks) | 20 min | CLI + Manual |
| 9 | Integration testing (5 scenarios) | 30 min | Manual |
| 10 | UAT with portal users | 30 min | UAT |
| **TOTAL** | | **2-3 hours** | |

**Breakdown**:
- **CLI Automation**: 35 minutes
- **Manual Steps**: 25 minutes
- **Testing**: 1-1.5 hours

---

## Success Criteria

### Deployment is successful when:

1. ✅ All 4 Apex classes deployed with 100% test coverage
2. ✅ All 4 triggers active and firing correctly
3. ✅ Both flows activated and running
4. ✅ Customer Community Plus Login users can see Producer records
5. ✅ New portal users automatically receive sharing (no manual backfill)
6. ✅ Status field updates automatically (Draft → Ready to Acknowledge → etc.)
7. ✅ Users see feedback after acknowledgment
8. ✅ No errors in debug logs (CPU time <1000ms, no governor limit warnings)
9. ✅ UAT passes with real portal users
10. ✅ Performance metrics match OldOrg (sharing creation <500ms)

---

## Conclusion

This deployment package contains the **Login License Sharing Solution** (Issue #5 fix) and **UX Improvements** (V2.4) from OldOrg. These components are CRITICAL for Customer Community Plus Login license users to access Producer Portal data.

**Deployment Status**: ✅ **READY**
- All code tested (100% coverage)
- Gap analysis completed
- Deployment steps documented (CLI + Manual)
- Rollback procedures prepared
- Success criteria defined

**Next Steps**:
1. Schedule deployment window (2-3 hours)
2. Execute Steps 0-7 in sequence
3. Complete post-deployment validation
4. Conduct UAT with portal users
5. Monitor performance for 24 hours
6. Close migration ticket

---

**Document History**:
- **V1.0** (2025-10-22): Initial NewOrg deployment package

**Contact**: Shintu John (shintu.john@recyclinglives.com)
**Last Updated**: 2025-10-22
**Deployment Target**: NewOrg (Recycling Lives Group)

---

**END OF NEWORG DEPLOYMENT PACKAGE**
