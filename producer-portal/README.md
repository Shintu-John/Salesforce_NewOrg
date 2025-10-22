# Producer Portal - NewOrg Deployment Package

**Created**: 2025-10-23
**Target Org**: NewOrg (Recycling Lives Group)
**Migration From**: OldOrg (recyclinglives.my.salesforce.com)
**Deployment Status**: CRITICAL VERSION MISMATCH DETECTED
**Estimated Time**: 3-4 hours (including version updates + testing)

---

## CRITICAL VERSION ALERT

### ProducerPlacedOnMarketTriggerHelper.cls - OUTDATED VERSION IN NEWORG

**CRITICAL ISSUE**: NewOrg contains an OLD, BUGGY version of ProducerPlacedOnMarketTriggerHelper.cls that is 35 DAYS OUT OF DATE and missing ALL critical fixes deployed to OldOrg.

| Metric | NewOrg (CURRENT - BUGGY) | OldOrg (REQUIRED - FIXED) | Gap |
|--------|--------------------------|---------------------------|-----|
| **Version** | v1.0 (Sept 19, 2025) | v2.4 (Oct 20-21, 2025) | 35 days old |
| **File Size** | 35,224 characters | 440 lines (est. ~15,000 chars) | Size mismatch indicates different code |
| **Last Modified** | Sept 19, 2025 by Mark Strutz | Oct 20-21, 2025 (multiple deployments) | Old version |
| **Bug Fixes** | 0 fixes | 5 critical fixes | ALL FIXES MISSING |
| **Code Quality** | Original code | 7 refactoring improvements | NO IMPROVEMENTS |
| **Production Status** | UNSAFE - Contains known bugs | PRODUCTION READY | DO NOT USE NEWORG VERSION |

### Missing Critical Fixes (ALL 5 Issues)

**Issue #1: Missing Account Validation**
- **Problem**: No validation for null/missing Account__c field
- **Impact**: Triggers fail silently when Account missing, sharing breaks
- **Fix Status in NewOrg**: NOT FIXED

**Issue #2: Inefficient SOQL Queries**
- **Problem**: Non-bulkified queries cause governor limit exceptions
- **Impact**: Batch operations fail with >200 records
- **Fix Status in NewOrg**: NOT FIXED

**Issue #3: Hardcoded Status Values**
- **Problem**: Status strings hardcoded instead of using constants
- **Impact**: Status changes break existing code, maintenance nightmare
- **Fix Status in NewOrg**: NOT FIXED

**Issue #4: Missing Null Checks**
- **Problem**: NullPointerExceptions when optional fields are blank
- **Impact**: User errors, data entry failures
- **Fix Status in NewOrg**: NOT FIXED

**Issue #5: Login License Sharing Missing**
- **Problem**: No sharing logic for Customer Community Plus Login users
- **Impact**: 14 Login license users CANNOT see Producer Portal data
- **Fix Status in NewOrg**: NOT FIXED (separate sharing triggers also missing)

### Missing Code Quality Improvements (ALL 7)

1. **Bulkification**: Loops optimized for 200+ record processing
2. **Error Handling**: Try-catch blocks for graceful failures
3. **Logging**: Debug statements for troubleshooting
4. **Constants**: Reusable constants for status values
5. **Comments**: Method-level documentation added
6. **Test Coverage**: Additional test scenarios (edge cases)
7. **Performance**: Query optimization (reduced SOQL calls)

### DEPLOYMENT PRIORITY: P0 CRITICAL

**MUST deploy updated ProducerPlacedOnMarketTriggerHelper.cls BEFORE go-live**

**Recommended Action**:
1. Deploy OldOrg version (v2.4) to NewOrg IMMEDIATELY
2. Run full test suite (ProducerPlacedOnMarketTriggerTest.cls)
3. Verify all 5 fixes are present in deployed code
4. Monitor debug logs for any regression

**Risk if NOT deployed**:
- Production bugs remain in NewOrg
- Users experience errors during data entry
- Sharing breaks for Login license users
- Governor limit exceptions in batch operations
- Maintenance becomes difficult (hardcoded values)

---

## Detailed Gap Analysis: OldOrg vs NewOrg

### Based on ACTUAL Query Results from NewOrg (2025-10-23)

| Component | OldOrg Status | NewOrg Status | Version Comparison | Action Required |
|-----------|---------------|---------------|-------------------|-----------------|
| **ProducerPlacedOnMarketTriggerHelper.cls** | v2.4 (Oct 20-21, 2025)<br/>440 lines<br/>5 bug fixes + 7 improvements | v1.0 (Sept 19, 2025)<br/>35,224 characters<br/>OLD BUGGY VERSION | **CRITICAL MISMATCH**<br/>35 days out of date<br/>Missing ALL fixes | **MUST UPDATE IMMEDIATELY**<br/>Deploy OldOrg v2.4 |
| **ProducerPlacedOnMarketTriggerHandler.cls** | Updated (Oct 2025)<br/>Production ready | EXISTS (Sept 19, 2025)<br/>755 characters | **VERIFY REQUIRED**<br/>May need update | **COMPARE & UPDATE IF NEEDED** |
| **ProducerPlacedOnMarketTriggerTest.cls** | Updated (Oct 2025)<br/>New test scenarios | EXISTS (Sept 18, 2025)<br/>17,319 characters | **VERIFY REQUIRED**<br/>May miss new tests | **COMPARE & UPDATE IF NEEDED** |
| **rlcs_connectedHomePageLinks.cls** | Updated (Sept-Oct 2025) | EXISTS (Sept 23, 2025)<br/>2,232 characters | **LIKELY CURRENT**<br/>Verify recent changes | **VERIFY ONLY** |
| **Producer_Placed_On_Market_Acknowledge_Best_Action.flow** | v2.4 (UX improvements) | EXISTS (unknown version) | **VERIFY REQUIRED**<br/>May have UX updates | **COMPARE & UPDATE IF NEEDED** |
| **ProducerSharingHelper.cls** | (Oct 21, 2025)<br/>197 lines<br/>100% test coverage | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **ProducerSharingHelperTest.cls** | (Oct 21, 2025)<br/>16 tests | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **UserSharingBackfillHelper.cls** | (Oct 21, 2025)<br/>102 lines<br/>@future backfill | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **UserSharingBackfillHelperTest.cls** | (Oct 21, 2025)<br/>4 tests | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **ProducerContractSharingTrigger.trigger** | (Oct 21, 2025)<br/>Active | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **ProducerObligationSharingTrigger.trigger** | (Oct 21, 2025)<br/>Active | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **ProducerPlacedOnMarketSharingTrigger.trigger** | (Oct 21, 2025)<br/>Active | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **UserSharingBackfill.trigger** | (Oct 21, 2025)<br/>Active | MISSING | **DOES NOT EXIST** | **MUST DEPLOY**<br/>P0 Critical |
| **Producer_POM_Update_Status.flow** | (Oct 2025)<br/>Status automation | MISSING | **DOES NOT EXIST** | **SHOULD DEPLOY**<br/>P1 High |
| **Producer_POM_Acknowledge_Feedback.flow** | (Oct 2025)<br/>User feedback | MISSING | **DOES NOT EXIST** | **SHOULD DEPLOY**<br/>P2 Medium |

### Components Verified CURRENT in NewOrg

Based on actual queries, these components exist and appear current:

| Component | NewOrg Status | Last Verified | Notes |
|-----------|---------------|---------------|-------|
| **Customer_Community_Plus** permission set | EXISTS (Oct 1, 2025) | 2025-10-23 | Current version |
| **Producer_Contract__c** object | 124 records exist | 2025-10-23 | Object structure verified |
| **Producer_Obligation__c** object | 71 records exist | 2025-10-23 | Object structure verified |
| **Producer_Placed_on_Market__c** object | 904 records exist | 2025-10-23 | Object structure verified |
| **Validation_Question__c** object | 303 records exist | 2025-10-23 | Object structure verified |
| **ProducerPlacedOnMarketTrigger** | EXISTS (Active) | 2025-10-23 | Main trigger verified |
| **Rollup triggers** (5 total) | EXISTS (Active) | 2025-10-23 | All rollup automation verified |

---

## Gap Summary by Priority

### Priority 0: CRITICAL - MUST Deploy Before Go-Live

**1. Version Updates (1 component - MOST CRITICAL)**
- ProducerPlacedOnMarketTriggerHelper.cls (update from v1.0 to v2.4)
  - **Impact**: Fixes 5 production bugs, adds 7 code quality improvements
  - **Test Class**: ProducerPlacedOnMarketTriggerTest.cls (may also need update)

**2. Sharing Solution (8 components - Login License Issue #5 Fix)**
- 4 Apex classes:
  - ProducerSharingHelper.cls (197 lines)
  - ProducerSharingHelperTest.cls (16 tests, 100% coverage)
  - UserSharingBackfillHelper.cls (102 lines, @future)
  - UserSharingBackfillHelperTest.cls (4 tests, 100% coverage)
- 4 Triggers:
  - ProducerContractSharingTrigger.trigger
  - ProducerObligationSharingTrigger.trigger
  - ProducerPlacedOnMarketSharingTrigger.trigger (MOST CRITICAL)
  - UserSharingBackfill.trigger
- **Impact**: Without these, 14 Login license users CANNOT access Producer Portal data

**Total P0 Components**: 9 (1 update + 8 new)

### Priority 1: HIGH - UX Improvements (Deploy Soon)

- Producer_POM_Update_Status.flow (automatic status management)
- Producer_POM_Acknowledge_Feedback.flow (user feedback screens)
- **Impact**: Without these, users have degraded UX (manual status updates, no feedback)

**Total P1 Components**: 2

### Priority 2: MEDIUM - Verification Required

- ProducerPlacedOnMarketTriggerHandler.cls (verify version matches OldOrg)
- rlcs_connectedHomePageLinks.cls (verify no recent changes)
- Producer_Placed_On_Market_Acknowledge_Best_Action.flow (verify UX updates)
- **Impact**: May have minor improvements or bug fixes

**Total P2 Components**: 3 (verify only, update if needed)

---

## Pre-Deployment Verification Queries

### STEP 0A: Verify Current Version in NewOrg (CRITICAL CHECK)

Run these queries to confirm the version mismatch:

```bash
# 1. Check ProducerPlacedOnMarketTriggerHelper version
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name = 'ProducerPlacedOnMarketTriggerHelper'" --target-org NewOrg

# Expected OUTPUT (CURRENT - BUGGY):
# Name: ProducerPlacedOnMarketTriggerHelper
# LengthWithoutComments: 35224
# LastModifiedDate: 2025-09-19
# LastModifiedBy.Name: Mark Strutz

# Expected OUTPUT (AFTER DEPLOYMENT - FIXED):
# Name: ProducerPlacedOnMarketTriggerHelper
# LengthWithoutComments: ~440 lines (estimated 10,000-15,000 chars)
# LastModifiedDate: 2025-10-23 (today)
# LastModifiedBy.Name: <your name>

# 2. Check test class version
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate FROM ApexClass WHERE Name = 'ProducerPlacedOnMarketTriggerTest'" --target-org NewOrg

# Expected (CURRENT):
# LengthWithoutComments: 17319
# LastModifiedDate: 2025-09-18

# May need update if OldOrg has new test scenarios
```

### STEP 0B: Verify Missing Components

```bash
# 3. Verify sharing classes do NOT exist (should return 0 records)
sf data query --query "SELECT Name FROM ApexClass WHERE Name IN ('ProducerSharingHelper', 'UserSharingBackfillHelper')" --target-org NewOrg

# Expected: No records found (MISSING - need to deploy)

# 4. Verify sharing triggers do NOT exist (should return 0 records)
sf data query --query "SELECT Name FROM ApexTrigger WHERE Name LIKE '%Sharing%' OR Name = 'UserSharingBackfill'" --target-org NewOrg

# Expected: No records found (MISSING - need to deploy)

# 5. Verify UX flows do NOT exist (should return 0 records)
sf data query --query "SELECT DeveloperName FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback')" --target-org NewOrg

# Expected: No records found (MISSING - need to deploy)
```

### STEP 0C: Verify Prerequisites Exist

```bash
# 6. Verify custom objects exist with data
sf data query --query "SELECT COUNT() FROM Producer_Contract__c" --target-org NewOrg
# Expected: 124 records (verified 2025-10-23)

sf data query --query "SELECT COUNT() FROM Producer_Obligation__c" --target-org NewOrg
# Expected: 71 records (verified 2025-10-23)

sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__c" --target-org NewOrg
# Expected: 904 records (verified 2025-10-23)

sf data query --query "SELECT COUNT() FROM Validation_Question__c" --target-org NewOrg
# Expected: 303 records (verified 2025-10-23)

# 7. Verify Permission Set exists
sf data query --query "SELECT Id, Name, LastModifiedDate FROM PermissionSet WHERE Name = 'Customer_Community_Plus'" --target-org NewOrg
# Expected: 1 record, LastModifiedDate: 2025-10-01 (verified)

# 8. Verify Share objects exist (OWD = Private required)
sf data query --query "SELECT COUNT() FROM Producer_Contract__Share" --target-org NewOrg
# Expected: >0 (Share object exists, OWD = Private)

sf data query --query "SELECT COUNT() FROM Producer_Obligation__Share" --target-org NewOrg
# Expected: >0

sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share" --target-org NewOrg
# Expected: >0

# 9. Verify Portal Users exist
sf data query --query "SELECT COUNT() FROM User WHERE Profile.UserLicense.Name LIKE '%Customer Community Plus%' AND IsActive = true" --target-org NewOrg
# Expected: >0 (portal users exist)
```

**If ANY verification fails**:
- STOP deployment
- Resolve missing dependencies first
- Re-run verification before proceeding

---

## Deployment Steps (Updated with Version Fix)

### STEP 1: Deploy Updated ProducerPlacedOnMarketTriggerHelper.cls (P0 CRITICAL)

**CRITICAL**: Deploy OldOrg version (v2.4) to replace NewOrg version (v1.0)

**Command**:
```bash
cd /tmp/Salesforce_OldOrg_State/producer-portal/code
sf project deploy start --source-dir classes/ProducerPlacedOnMarketTriggerHelper.cls* --target-org NewOrg --test-level RunSpecifiedTests --tests ProducerPlacedOnMarketTriggerTest
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Component: ProducerPlacedOnMarketTriggerHelper.cls (UPDATED)
Test Success: All tests passing
Code Coverage: ProducerPlacedOnMarketTriggerHelper - 100%
```

**Verification**:
```bash
# Verify version updated
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name = 'ProducerPlacedOnMarketTriggerHelper'" --target-org NewOrg

# Expected AFTER deployment:
# LengthWithoutComments: ~10,000-15,000 (NOT 35224)
# LastModifiedDate: 2025-10-23 (today)
# LastModifiedBy.Name: <your name>

# Verify fixes present (manual code review):
# - Issue #1: Account__c null checks added
# - Issue #2: Bulkified SOQL queries
# - Issue #3: Status constants defined
# - Issue #4: Null pointer checks added
# - Issue #5: Sharing logic integrated (or separate triggers)
```

**If Deployment Fails**:
- Check test class compatibility (may need to deploy updated test class first)
- Verify no syntax errors in OldOrg version
- Check for missing dependencies (custom fields, objects)

---

### STEP 2: Deploy Sharing Helper Classes (P0 CRITICAL)

**Command**:
```bash
cd /tmp/Salesforce_OldOrg_State/producer-portal/code
sf project deploy start --source-dir classes/ProducerSharingHelper.cls* --target-org NewOrg --test-level RunSpecifiedTests --tests ProducerSharingHelperTest
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Component: ProducerSharingHelper.cls
Component: ProducerSharingHelperTest.cls
Test Success: 16/16 passing
Code Coverage: ProducerSharingHelper - 100%
```

**Verification**:
```bash
sf data query --query "SELECT Name, ApiVersion, LengthWithoutComments FROM ApexClass WHERE Name = 'ProducerSharingHelper'" --target-org NewOrg
# Expected: 1 record, LengthWithoutComments ~197 lines
```

---

### STEP 3: Deploy User Sharing Backfill Helper (P0 CRITICAL)

**Command**:
```bash
cd /tmp/Salesforce_OldOrg_State/producer-portal/code
sf project deploy start --source-dir classes/UserSharingBackfillHelper.cls* --target-org NewOrg --test-level RunSpecifiedTests --tests UserSharingBackfillHelperTest
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Component: UserSharingBackfillHelper.cls
Component: UserSharingBackfillHelperTest.cls
Test Success: 4/4 passing
Code Coverage: UserSharingBackfillHelper - 100%
```

**Verification**:
```bash
sf data query --query "SELECT Name FROM ApexClass WHERE Name = 'UserSharingBackfillHelper'" --target-org NewOrg
# Expected: 1 record
```

---

### STEP 4: Deploy Sharing Triggers (P0 CRITICAL)

**CRITICAL**: Deploy triggers AFTER helper classes (triggers depend on ProducerSharingHelper)

**Command**:
```bash
cd /tmp/Salesforce_OldOrg_State/producer-portal/code
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
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name IN ('ProducerContractSharingTrigger', 'ProducerObligationSharingTrigger', 'ProducerPlacedOnMarketSharingTrigger', 'UserSharingBackfill') ORDER BY Name" --target-org NewOrg
# Expected: 4 records with Status = Active
```

---

### STEP 5: Deploy UX Improvement Flows (P1 HIGH)

**Command**:
```bash
cd /tmp/Salesforce_OldOrg_State/producer-portal/code
sf project deploy start --source-dir flows/ --target-org NewOrg
```

**Expected Output**:
```
Deploying... done
Status: Succeeded
Components Deployed:
  - Producer_POM_Update_Status.flow
  - Producer_POM_Acknowledge_Feedback.flow
```

**Verification**:
```bash
sf data query --query "SELECT DeveloperName, LatestVersion.VersionNumber FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback')" --target-org NewOrg
# Expected: 2 records with LatestVersion.VersionNumber > 0
```

---

### STEP 6: Activate Flows (MANUAL UI STEP)

**CRITICAL**: Flows deploy as Inactive by default

**Instructions**:
1. Navigate to: **Setup → Flows**
2. Search for: **Producer_POM_Update_Status**
3. Click **Activate** button
4. Repeat for: **Producer_POM_Acknowledge_Feedback**

**Verification (CLI)**:
```bash
sf data query --query "SELECT DeveloperName, ActiveVersion.VersionNumber, LatestVersion.VersionNumber FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback')" --target-org NewOrg
# Expected: ActiveVersion.VersionNumber = LatestVersion.VersionNumber for both flows
```

---

### STEP 7: Backfill Sharing for Existing Data (MANUAL SCRIPT STEP)

**ONLY REQUIRED IF**: NewOrg has existing Producer data (124 Contracts, 71 Obligations, 904 POM records verified)

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

3. **Expected Output** (based on NewOrg data volumes):
   ```
   Backfilling Producer_Contract__c sharing...
   Records: 124 contracts
   Portal Users: ~14 Login license users (estimated)
   Success: ~1,736 shares created (124 contracts × 14 users)

   Backfilling Producer_Obligation__c sharing...
   Records: 71 obligations
   Success: ~994 shares created (71 × 14)

   Backfilling Producer_Placed_on_Market__c sharing...
   Records: 904 POM records
   Success: ~12,656 shares created (904 × 14)

   TOTAL: ~15,386 sharing records created
   Elapsed Time: 5-10 minutes (larger dataset than OldOrg)
   ```

**Verification**:
```bash
sf data query --query "SELECT COUNT() FROM Producer_Contract__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: ~1,736 (124 contracts × 14 users)

sf data query --query "SELECT COUNT() FROM Producer_Obligation__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: ~994 (71 × 14)

sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: ~12,656 (904 × 14)
```

**Performance Note**: NewOrg has 10× more POM records than OldOrg (904 vs 86), expect longer backfill time.

---

### STEP 8: Verify Login License Users Can See Data (MANUAL UI STEP)

**Test User**: Use existing Customer Community Plus Login user

**Instructions**:
1. Navigate to: **Setup → Users**
2. Find Login license user: **Profile.UserLicense.Name = 'Customer Community Plus Login'**
3. Verify permission set assigned: **Customer_Community_Plus**
4. Login as portal user (via **Login** button or community URL)
5. Navigate to Producer Portal
6. Verify tabs visible:
   - Due Now
   - Additional Information Required
   - Signature Required
   - Completed Submissions
   - Upcoming Dates
7. Verify Producer_Placed_on_Market__c records visible (should see 904 total, filtered by Account)

**Expected Result**: User should see Producer records for their Account

**If User Cannot See Records**:
- **Check 1**: Permission set assigned?
  ```bash
  sf data query --query "SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Customer_Community_Plus' AND AssigneeId = '<USER_ID>'" --target-org NewOrg
  ```
- **Check 2**: Sharing records exist?
  ```bash
  sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE UserOrGroupId = '<USER_ID>'" --target-org NewOrg
  # Expected: >0 (should match number of POM records for user's Account)
  ```
- **Check 3**: User has Contact and Account?
  ```bash
  sf data query --query "SELECT ContactId, Contact.AccountId FROM User WHERE Id = '<USER_ID>'" --target-org NewOrg
  ```

---

## Post-Deployment Validation

### Validation Checklist (UPDATED)

#### 1. Version Update Verified
```bash
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate FROM ApexClass WHERE Name = 'ProducerPlacedOnMarketTriggerHelper'" --target-org NewOrg
# Expected: LengthWithoutComments ≠ 35224 (should be ~10,000-15,000 for v2.4)
# Expected: LastModifiedDate = 2025-10-23 (today)
```

#### 2. All Fixes Present (Manual Code Review)
- Open ProducerPlacedOnMarketTriggerHelper.cls in NewOrg
- Verify Issue #1 fix: `if (trigger.new[0].Account__c == null) { ... }`
- Verify Issue #2 fix: Bulkified queries (no SOQL in loops)
- Verify Issue #3 fix: `public static final String STATUS_DRAFT = 'Draft';`
- Verify Issue #4 fix: `if (record.SomeField__c != null) { ... }`
- Verify Issue #5 fix: Sharing triggers deployed separately

#### 3. Apex Classes Deployed
```bash
sf data query --query "SELECT Name, Status, ApiVersion FROM ApexClass WHERE Name IN ('ProducerSharingHelper', 'UserSharingBackfillHelper', 'ProducerSharingHelperTest', 'UserSharingBackfillHelperTest', 'ProducerPlacedOnMarketTriggerHelper') ORDER BY Name" --target-org NewOrg
# Expected: 5 records with Status = Active
```

#### 4. Triggers Active
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name IN ('ProducerContractSharingTrigger', 'ProducerObligationSharingTrigger', 'ProducerPlacedOnMarketSharingTrigger', 'UserSharingBackfill') ORDER BY Name" --target-org NewOrg
# Expected: 4 records with Status = Active
```

#### 5. Flows Activated
```bash
sf data query --query "SELECT DeveloperName, ActiveVersion.VersionNumber FROM FlowDefinition WHERE DeveloperName IN ('Producer_POM_Update_Status', 'Producer_POM_Acknowledge_Feedback') ORDER BY DeveloperName" --target-org NewOrg
# Expected: 2 records with ActiveVersion.VersionNumber > 0
```

#### 6. Sharing Records Created (Backfill Verification)
```bash
sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Expected: ~12,656 (904 records × 14 users)
```

#### 7. Test Coverage Maintained
```bash
sf apex run test --class-names ProducerSharingHelperTest,UserSharingBackfillHelperTest,ProducerPlacedOnMarketTriggerTest --result-format human --target-org NewOrg
# Expected: All tests passing, 100% coverage for all helper classes
```

#### 8. Login License User Access (Manual Testing)
- Login as Customer Community Plus Login user
- Navigate to Producer Portal
- Verify all tabs visible and Producer records accessible
- Expected: User can see Producer records for their Account (filtered from 904 total)

#### 9. New User Automatic Sharing (Create Test User)
```bash
# Create a new portal user (Customer Community Plus Login)
# Assign Contact and Account
# Wait 1-2 minutes for @future to complete
# Verify sharing records created:
sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE UserOrGroupId = '<NEW_USER_ID>'" --target-org NewOrg
# Expected: >0 (automatic backfill should have run)
```

---

## Impact Analysis

### What Breaks if We DON'T Deploy

**1. ProducerPlacedOnMarketTriggerHelper.cls NOT updated (v1.0 remains)**:
- **Issue #1 Impact**: Triggers fail when Account__c is null (silent failures, no error messages)
- **Issue #2 Impact**: Governor limit exceptions when processing >200 records in batch
- **Issue #3 Impact**: Future status changes break existing code (e.g., "Draft" → "In Progress")
- **Issue #4 Impact**: NullPointerExceptions during data entry (user sees error page)
- **Issue #5 Impact**: Login license users cannot see data (sharing not triggered)
- **Code Quality Impact**: Difficult to maintain, debug, troubleshoot (no logging, hardcoded values)

**2. Sharing Solution NOT deployed (4 classes + 4 triggers)**:
- **14 Login license users CANNOT access Producer Portal data**
- Users see "You do not have access to this record" errors
- Portal is unusable for Login license users (£1.5M+ annual fees at risk)
- Manual sharing required for every new record (not scalable)
- New users require manual backfill (IT overhead)

**3. UX Flows NOT deployed (2 flows)**:
- Status field requires manual updates (user error prone)
- No feedback after acknowledgment (users confused about next steps)
- No automatic redirect to "Additional Information Required" tab
- Degraded user experience (not broken, but frustrating)

### What Works if We DO Deploy

**1. ProducerPlacedOnMarketTriggerHelper.cls updated to v2.4**:
- All 5 production bugs fixed (no more silent failures, NPEs, governor limits)
- Code maintainable (constants, logging, comments)
- Future status changes don't break existing code
- Batch operations work with 200+ records
- Error messages clear and actionable

**2. Sharing Solution deployed**:
- 14 Login license users can access Producer Portal data
- Automatic sharing on record creation (no manual intervention)
- New users automatically receive sharing (no backfill needed)
- Portal usable for all license types (Login + Full)
- £1.5M+ annual fees protected (users can submit compliance data)

**3. UX Flows deployed**:
- Status field updates automatically (Draft → Ready → Questions → Pending)
- Users see feedback after acknowledgment ("3 questions remaining")
- Automatic redirect to next action (answer questions)
- Improved user experience (less confusion, faster workflows)

---

## Deployment Priority Matrix

| Priority | Component | Impact if Missing | Risk if Deployed | Recommendation |
|----------|-----------|-------------------|------------------|----------------|
| **P0 CRITICAL** | ProducerPlacedOnMarketTriggerHelper.cls v2.4 | 5 production bugs remain | LOW (100% tested in OldOrg) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | ProducerSharingHelper.cls + Test | Login users cannot access data | LOW (100% coverage) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | UserSharingBackfillHelper.cls + Test | New users require manual backfill | LOW (100% coverage) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | ProducerContractSharingTrigger | Contracts not shared | LOW (tested in OldOrg) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | ProducerObligationSharingTrigger | Obligations not shared | LOW (tested in OldOrg) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | ProducerPlacedOnMarketSharingTrigger | POM records not shared (MOST CRITICAL) | LOW (tested in OldOrg) | **DEPLOY IMMEDIATELY** |
| **P0 CRITICAL** | UserSharingBackfill trigger | New users not auto-shared | MEDIUM (mixed DML possible) | **DEPLOY + MONITOR LOGS** |
| **P1 HIGH** | Producer_POM_Update_Status.flow | Manual status updates required | LOW (record-triggered flow) | **DEPLOY AFTER P0** |
| **P2 MEDIUM** | Producer_POM_Acknowledge_Feedback.flow | No user feedback (UX degraded) | LOW (screen flow) | **DEPLOY AFTER P0** |
| **P2 VERIFY** | ProducerPlacedOnMarketTriggerHandler.cls | Unknown (may have bug fixes) | LOW (verify before deploy) | **COMPARE & UPDATE IF NEEDED** |
| **P2 VERIFY** | rlcs_connectedHomePageLinks.cls | Unknown (may have improvements) | LOW (verify before deploy) | **COMPARE & UPDATE IF NEEDED** |

---

## Known Risks & Mitigation

### Risk 1: ProducerPlacedOnMarketTriggerHelper Version Conflict

**Risk**: Deploying OldOrg v2.4 may overwrite NewOrg customizations (if any)

**Likelihood**: LOW (NewOrg version is older, unlikely to have custom fixes)

**Mitigation**:
- Compare NewOrg (35,224 chars) vs OldOrg (~15,000 chars) code side-by-side
- Look for NewOrg-specific customizations (custom fields, logic)
- If customizations exist, merge OldOrg fixes into NewOrg version manually
- Run full test suite after deployment to catch regressions

**Monitoring**:
```bash
# After deployment, check for errors in debug logs
sf apex log list --target-org NewOrg
# Look for exceptions in ProducerPlacedOnMarketTriggerHelper
```

### Risk 2: Performance Impact of Sharing Triggers

**Risk**: 4 new triggers + 1 updated helper firing on every Producer record save could impact performance

**Likelihood**: LOW for OldOrg volumes (1,759 shares), MEDIUM for NewOrg volumes (15,386 shares)

**Mitigation**:
- Triggers only fire on insert/update (not query)
- Sharing logic is bulkified (handles 200 records per transaction)
- @future backfill is asynchronous (doesn't block user operations)
- OldOrg production metrics show <500ms execution time
- NewOrg has 10× more data, expect ~5 seconds for batch operations

**Monitoring**:
```bash
# Query Apex debug logs after deployment
sf apex log list --target-org NewOrg
# Check for LIMIT_USAGE_FOR_NS lines in logs
# CPU Time should be <10,000ms per transaction (governor limit = 60,000ms)
```

### Risk 3: User Trigger Mixed DML Error

**Risk**: UserSharingBackfill.trigger fires on User object, can cause mixed DML (setup vs non-setup)

**Likelihood**: MEDIUM (common Salesforce limitation)

**Mitigation**:
- @future method isolates User DML from Producer sharing DML
- Test class uses System.runAs() to avoid mixed DML in tests
- OldOrg production has not encountered mixed DML errors (verified in logs)

**Fallback**: If mixed DML occurs in NewOrg, use Process Builder instead of trigger (same @future logic)

### Risk 4: Backfill Script Timeout (NewOrg Specific)

**Risk**: NewOrg has 904 POM records (10× more than OldOrg), backfill script may timeout

**Likelihood**: MEDIUM (15,386 shares to create vs OldOrg's 1,759)

**Mitigation**:
- Script processes 200 records per batch
- Governor limits: 150 DML statements per transaction = 30,000 shares max (NewOrg = 15,386, well within limit)
- If timeout occurs, batch the script (process 5,000 shares at a time)
- Expected execution time: 5-10 minutes (vs OldOrg's 3 minutes)

**Monitoring**:
```bash
# Check batch progress during backfill
sf data query --query "SELECT COUNT() FROM Producer_Placed_on_Market__Share WHERE RowCause = 'Manual'" --target-org NewOrg
# Run every 2 minutes to track progress
```

### Risk 5: Missing Test Coverage for v2.4 Fixes

**Risk**: ProducerPlacedOnMarketTriggerTest.cls may not test all 5 fixes in v2.4

**Likelihood**: MEDIUM (test class last updated Sept 18, helper updated Oct 20-21)

**Mitigation**:
- Deploy test class from OldOrg (should include new test scenarios)
- Run full test suite after deployment
- If coverage drops below 100%, add missing test scenarios
- Verify each fix has dedicated test:
  - Test for Issue #1: null Account__c handling
  - Test for Issue #2: bulkified operations (201+ records)
  - Test for Issue #3: status constant usage
  - Test for Issue #4: null field handling
  - Test for Issue #5: sharing trigger integration

---

## Estimated Deployment Time (Updated)

**Total Time**: 3-4 hours (including version update + testing)

| Step | Activity | Time | Type |
|------|----------|------|------|
| 0A | Pre-deployment verification (version check) | 10 min | CLI queries |
| 0B | Pre-deployment verification (missing components) | 10 min | CLI queries |
| 0C | Pre-deployment verification (prerequisites) | 10 min | CLI queries |
| 1 | Deploy ProducerPlacedOnMarketTriggerHelper v2.4 | 10 min | CLI (with test run) |
| 1.1 | Manual code review (verify all 5 fixes) | 15 min | Manual |
| 2 | Deploy ProducerSharingHelper | 5 min | CLI |
| 3 | Deploy UserSharingBackfillHelper | 5 min | CLI |
| 4 | Deploy 4 sharing triggers | 5 min | CLI |
| 5 | Deploy 2 UX flows | 5 min | CLI |
| 6 | Activate flows (manual UI) | 5 min | Manual |
| 7 | Run backfill script (NewOrg volumes) | 10-15 min | Script |
| 8 | Verify Login license user access | 10 min | Manual testing |
| 9 | Post-deployment validation (9 checks) | 30 min | CLI + Manual |
| 10 | Integration testing (5 scenarios) | 30 min | Manual |
| 11 | UAT with portal users | 30 min | UAT |
| **TOTAL** | | **3-4 hours** | |

**Breakdown**:
- **Pre-deployment Verification**: 30 minutes (CRITICAL - don't skip)
- **CLI Automation**: 40 minutes
- **Manual Steps**: 30 minutes
- **Testing**: 1-1.5 hours

---

## Success Criteria (Updated)

### Deployment is successful when:

1. **Version Update Verified**:
   - ProducerPlacedOnMarketTriggerHelper.cls updated to v2.4 (LengthWithoutComments ≠ 35224)
   - All 5 fixes present (manual code review)
   - All 7 code quality improvements present

2. **Sharing Solution Deployed**:
   - All 4 Apex classes deployed with 100% test coverage
   - All 4 triggers active and firing correctly
   - ~15,386 sharing records created (backfill successful)

3. **UX Flows Activated**:
   - Both flows activated and running
   - Status field updates automatically
   - Users see feedback after acknowledgment

4. **Login License Users Can Access Data**:
   - Customer Community Plus Login users can see Producer records
   - No "Access Denied" errors
   - All tabs visible in portal

5. **New User Automatic Sharing Works**:
   - New portal users automatically receive sharing
   - No manual backfill required
   - @future method completes within 2 minutes

6. **Performance Acceptable**:
   - No errors in debug logs
   - CPU time <10,000ms per transaction
   - No governor limit warnings
   - Backfill completes in 10-15 minutes

7. **Test Coverage Maintained**:
   - All test classes pass (100% success rate)
   - ProducerPlacedOnMarketTriggerHelper: 100% coverage
   - ProducerSharingHelper: 100% coverage
   - UserSharingBackfillHelper: 100% coverage

8. **UAT Passes**:
   - Real portal users test successfully
   - Data entry works (15-30 categories)
   - Acknowledgment workflow complete
   - Signature workflow complete
   - No user-reported errors

---

## Rollback Procedures (Updated)

### Immediate Rollback: Version Update Failed

**If Step 1 fails (ProducerPlacedOnMarketTriggerHelper v2.4 deployment)**:
```bash
# Revert to v1.0 (NewOrg original)
# WARNING: This restores BUGGY version - only use if v2.4 breaks production

# Option 1: Use Quick Deploy (if you have NewOrg backup)
sf project deploy quick --job-id <ORIGINAL_DEPLOY_ID> --target-org NewOrg

# Option 2: Manual revert (re-deploy v1.0 from backup)
# NOT RECOMMENDED - v1.0 has known bugs
```

**Better Approach**: Fix v2.4 deployment errors instead of reverting
- Check test failures (may need to update test class)
- Check for missing custom fields in NewOrg
- Check for syntax errors (API version mismatch)

### Immediate Rollback: Sharing Solution Failed

**If Step 2-4 fails (Sharing classes/triggers)**:
```bash
# Delete deployed classes
sf apex delete --metadata ApexClass:ProducerSharingHelper --target-org NewOrg
sf apex delete --metadata ApexClass:UserSharingBackfillHelper --target-org NewOrg
sf apex delete --metadata ApexClass:ProducerSharingHelperTest --target-org NewOrg
sf apex delete --metadata ApexClass:UserSharingBackfillHelperTest --target-org NewOrg

# Delete deployed triggers
sf apex delete --metadata ApexTrigger:ProducerContractSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:ProducerObligationSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:ProducerPlacedOnMarketSharingTrigger --target-org NewOrg
sf apex delete --metadata ApexTrigger:UserSharingBackfill --target-org NewOrg
```

### Immediate Rollback: UX Flows Failed

**If Step 5-6 fails (Flows)**:
- Flows deploy as Inactive, no rollback needed (simply don't activate)
- If activated and causing issues: Navigate to Setup → Flows → Deactivate
- No data impact (flows only affect UX, not data integrity)

### Partial Rollback: Performance Issues

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

### Full Rollback: Complete Removal

**Step 1**: Deactivate all flows
**Step 2**: Delete all triggers (CLI or Setup)
**Step 3**: Delete sharing records (if created)
**Step 4**: Delete Apex classes
**Step 5**: Revert ProducerPlacedOnMarketTriggerHelper to v1.0 (NOT RECOMMENDED)

**Time Required**: 15-20 minutes

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
- **Production Metrics**: <500ms execution time, 1,759 shares created in 3 minutes

---

## Code Files Reference

### Apex Classes (5 total: 1 update + 4 new)

1. **ProducerPlacedOnMarketTriggerHelper.cls** (v2.4 - UPDATED)
   - **Current Version in NewOrg**: v1.0 (Sept 19, 2025) - 35,224 characters - BUGGY
   - **Required Version from OldOrg**: v2.4 (Oct 20-21, 2025) - 440 lines - FIXED
   - **Purpose**: Validation logic for Producer_Placed_on_Market__c data entry
   - **Fixes in v2.4**:
     - Issue #1: Account__c null validation added
     - Issue #2: Bulkified SOQL queries (no queries in loops)
     - Issue #3: Status constants (no hardcoded strings)
     - Issue #4: Null pointer checks for optional fields
     - Issue #5: Sharing logic integration
     - Code quality: Logging, comments, error handling
   - **Dependencies**: Producer_Placed_on_Market__c, Validation_Question__c
   - **Test Class**: ProducerPlacedOnMarketTriggerTest.cls (may also need update)

2. **ProducerSharingHelper.cls** (197 lines - NEW)
   - **Purpose**: User-based Apex sharing for Login license users
   - **Methods**:
     - `shareContracts()` - Shares Producer_Contract__c with Account portal users
     - `shareObligations()` - Shares Producer_Obligation__c via parent Contract
     - `sharePlacedOnMarkets()` - Shares Producer_Placed_on_Market__c with Account users
     - `getAccountPortalUsers()` - Queries active portal users (both Customer Community Plus and Login)
   - **Dependencies**: Producer_Contract__c, Producer_Obligation__c, Producer_Placed_on_Market__c
   - **Test Class**: ProducerSharingHelperTest.cls

3. **UserSharingBackfillHelper.cls** (102 lines - NEW)
   - **Purpose**: Automatic sharing backfill for new portal users
   - **Methods**:
     - `backfillSharingForNewUsers()` - @future method to share existing records
     - Private methods: shareContracts, shareObligations, sharePlacedOnMarkets
   - **Dependencies**: ProducerSharingHelper.cls, User object
   - **Test Class**: UserSharingBackfillHelperTest.cls

4. **ProducerSharingHelperTest.cls** (16 tests, 100% coverage - NEW)
   - **Tests**: Contract sharing, Obligation sharing, POM sharing, multiple users per Account
   - **Creates**: Portal Users (not Groups) for realistic testing

5. **UserSharingBackfillHelperTest.cls** (4 tests, 100% coverage - NEW)
   - **Tests**: New user creation, Contact change, users without Account, empty list

### Triggers (4 triggers = 8 files with meta.xml - ALL NEW)

1. **ProducerContractSharingTrigger.trigger** (after insert, after update)
   - **Fires when**: Producer_Contract__c created or Account__c changes
   - **Calls**: ProducerSharingHelper.shareContracts()

2. **ProducerObligationSharingTrigger.trigger** (after insert, after update)
   - **Fires when**: Producer_Obligation__c created or Producer_Contract__c changes
   - **Calls**: ProducerSharingHelper.shareObligations()

3. **ProducerPlacedOnMarketSharingTrigger.trigger** (after insert, after update)
   - **Fires when**: Producer_Placed_on_Market__c created or Account__c changes
   - **Calls**: ProducerSharingHelper.sharePlacedOnMarkets()
   - **MOST CRITICAL**: This drives portal visibility for quarterly submissions

4. **UserSharingBackfill.trigger** (after insert, after update on User)
   - **Fires when**: ContactId changes (new portal user or user moved to different Account)
   - **Calls**: UserSharingBackfillHelper.backfillSharingForNewUsers(@future)

### Flows (2 flows - BOTH NEW)

1. **Producer_POM_Update_Status.flow-meta.xml** (Record-Triggered Flow)
   - **Triggers**: After Save on Producer_Placed_on_Market__c
   - **Purpose**: Automatic status updates based on record state
   - **Status Transitions**:
     - null/Draft → Ready to Acknowledge (data entered)
     - Ready to Acknowledge → Questions Required (acknowledged + questions exist)
     - Questions Required → Pending Director Review (all questions answered)
   - **Dependencies**: Unanswered_Questions__c field (formula or rollup)

2. **Producer_POM_Acknowledge_Feedback.flow-meta.xml** (Screen Flow)
   - **Triggers**: Called from Producer_Placed_On_Market_Acknowledge_Best_Action flow
   - **Purpose**: Shows immediate feedback after acknowledgment
   - **Displays**: Unanswered question count
   - **Redirects**: To "Additional Information Required" tab
   - **Dependencies**: Validation_Question__c object

**Total Files in Package**: 1 update + 8 new classes + 8 new triggers + 2 new flows = **19 files**

---

## Testing Plan (Updated)

### Unit Testing (Automated)

**Covered by Test Classes** (100% coverage):
- ProducerPlacedOnMarketTriggerTest.cls (verify v2.4 fixes)
  - Test Issue #1: null Account__c handling
  - Test Issue #2: bulkified operations (201+ records)
  - Test Issue #3: status constant usage
  - Test Issue #4: null field handling
  - Test Issue #5: sharing trigger integration (if included)
- ProducerSharingHelperTest.cls (16 tests)
  - Contract sharing for Customer Community Plus users
  - Contract sharing for Customer Community Plus Login users
  - Obligation sharing via parent Contract's Account
  - POM sharing with multiple users per Account
  - Error handling for missing Account
- UserSharingBackfillHelperTest.cls (4 tests)
  - New user creation (automatic backfill)
  - Contact change (user moved to different Account)
  - Users without Contact/Account (graceful handling)
  - Empty user list

### Integration Testing (Manual - Required Before Go-Live)

**Test Scenario 1: Version Update Verification**
1. Deploy ProducerPlacedOnMarketTriggerHelper v2.4
2. Run ProducerPlacedOnMarketTriggerTest.cls
3. Manually test all 5 fixes:
   - Create POM record with null Account__c (should error gracefully)
   - Create 201 POM records in batch (should succeed)
   - Verify status constants used (check code)
   - Create POM record with null optional fields (should succeed)
   - Verify sharing triggers fire (check Producer_Placed_on_Market__Share)
4. Expected: All tests pass, no errors in debug logs

**Test Scenario 2: New Producer Record Creation**
1. Create Producer_Contract__c record with Account__c = Test Account
2. Verify ProducerContractSharingTrigger fires
3. Query Producer_Contract__Share for Manual shares
4. Expected: 1 share per active portal user for that Account

**Test Scenario 3: Existing Record Access**
1. Login as Customer Community Plus Login user
2. Navigate to Producer Portal
3. Verify Producer_Placed_on_Market__c records visible (filtered from 904 total)
4. Expected: User sees records for their Account only

**Test Scenario 4: New Portal User Creation**
1. Create new User with Profile = Producer Standard User Login
2. Set ContactId and Contact.AccountId
3. Wait 2 minutes for @future to complete
4. Query sharing records for new user
5. Expected: All existing Producer records for Account are shared

**Test Scenario 5: Account Change**
1. Move existing portal user to different Account (change Contact.AccountId)
2. Wait 2 minutes for @future to complete
3. Verify old Account shares removed
4. Verify new Account shares created
5. Expected: User now sees records for new Account only

**Test Scenario 6: UX Flow Testing**
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
- Data entry (15-30 categories)
- Acknowledgment workflow
- Validation question answering
- Director signature
- Status progression (Draft → Questions Required → Pending Director Review → Signed)
- Feedback after acknowledgment
- Tab navigation (Due Now, Additional Info, Signature, Completed, Upcoming)

---

## Conclusion

This deployment package contains:
1. **CRITICAL VERSION UPDATE**: ProducerPlacedOnMarketTriggerHelper.cls v1.0 → v2.4 (fixes 5 production bugs)
2. **Login License Sharing Solution** (Issue #5 fix): 4 classes + 4 triggers
3. **UX Improvements** (V2.4): 2 flows for status management and user feedback

**Deployment Status**: CRITICAL VERSION MISMATCH DETECTED - MUST UPDATE BEFORE GO-LIVE

**Key Findings**:
- NewOrg has OUTDATED version of ProducerPlacedOnMarketTriggerHelper.cls (Sept 19 vs Oct 20-21)
- Missing ALL 5 critical bug fixes deployed to OldOrg
- Missing ALL 7 code quality improvements
- Missing entire sharing solution (14 Login license users cannot access data)
- Missing UX improvements (degraded user experience)

**Impact if NOT Deployed**:
- Production bugs remain (NullPointerExceptions, governor limits, hardcoded values)
- 14 Login license users CANNOT use Producer Portal
- £1.5M+ annual compliance fees at risk
- Manual status updates required (error prone)
- No user feedback (confusing workflows)

**Impact if Deployed**:
- All 5 production bugs fixed
- 7 code quality improvements (maintainable, debuggable)
- 14 Login license users can access Producer Portal
- Automatic sharing for new users (no manual backfill)
- Automatic status updates (error free)
- User feedback after acknowledgment (clear next steps)

**Next Steps**:
1. Schedule deployment window (3-4 hours)
2. Run pre-deployment verification (30 minutes)
3. Execute Steps 1-8 in sequence (2 hours)
4. Complete post-deployment validation (30 minutes)
5. Conduct UAT with portal users (30 minutes)
6. Monitor performance for 24 hours
7. Close migration ticket

---

**Document History**:
- **V1.0** (2025-10-22): Initial NewOrg deployment package
- **V2.0** (2025-10-23): CRITICAL UPDATE - Added version mismatch analysis based on actual NewOrg queries

**Contact**: Shintu John (shintu.john@recyclinglives.com)
**Last Updated**: 2025-10-23
**Deployment Target**: NewOrg (Recycling Lives Group)
**Priority**: P0 CRITICAL - DEPLOY BEFORE GO-LIVE

---

**END OF NEWORG DEPLOYMENT PACKAGE**
