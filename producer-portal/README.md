# Producer Portal - NewOrg Migration Plan

**Target Organization**: NewOrg (Recycling Lives Group)
**Source Organization**: OldOrg (Recycling Lives Service)
**Migration Type**: Incremental Update + New Components
**Priority**: 🔴 High
**Estimated Time**: 2-3 hours (includes testing and validation)
**Status**: 📋 Ready for Review

---

## Related Documentation

**This migration plan consolidates multiple documentation sources**:

1. **PRODUCER_PORTAL_MASTER_DOCUMENTATION.md** - Primary comprehensive system documentation (1926 lines)
2. **PRODUCER_PORTAL_ACCESS_ERROR_TROUBLESHOOTING.md** - Troubleshooting guide documenting fixes implemented in OldOrg
3. **OldOrg State README**: [/tmp/Salesforce_OldOrg_State/producer-portal/README.md](../../../Salesforce_OldOrg_State/producer-portal/README.md) - Current verified state
4. **Archive/PRODUCER_PORTAL_*.md** - Historical versions and analysis documents

**Complete Mapping**: See [/home/john/Projects/Salesforce/Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md](../../Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md) for full documentation relationship analysis.

**Why These Are Consolidated**:
- All documents relate to the same Producer Portal system
- Troubleshooting guide documents the 5 issues fixed in OldOrg V2-V3 (Oct 20-21, 2025) that this migration deploys
- This migration brings NewOrg to parity with OldOrg's production-tested implementation
- Archived documents provide historical context for the system's evolution

---

## Executive Summary

### What's Being Migrated

This migration will update the Producer Portal system in NewOrg to match the fully-functional OldOrg implementation. The Producer Portal is a WEEE compliance management system used by 132 producer customers to manage contracts, obligations, and quarterly tonnage submissions.

**Critical Changes**:
1. **Deploy 3 new sharing triggers** - Required for Login license users
2. **Deploy 4 new Apex classes** - Sharing helpers for trigger-based sharing
3. **Update existing trigger** - ProducerPlacedOnMarketTrigger (currently inactive)
4. **Activate 7 flows** - Currently in Draft status in NewOrg
5. **Update permission set** - Enhance Customer_Community_Plus with field-level security

### Expected Benefits

- **Login License Support**: Directors and other users with Login licenses will be able to access Producer data
- **Enhanced Sharing**: Trigger-based sharing ensures consistent access regardless of license type
- **Complete Variance Detection**: Multi-period validation question logic
- **System Parity**: NewOrg will match OldOrg's production-tested functionality

### Business Impact

- **Downtime**: None (deploy as inactive, activate during maintenance window)
- **User Impact**: Positive - expands access to more user types
- **Data Impact**: None - read-only migration
- **Testing Required**: Yes - comprehensive portal user testing

---

## Gap Analysis

### Components Comparison

| Component | OldOrg Status | NewOrg Status | Gap | Action |
|-----------|---------------|---------------|-----|--------|
| **Apex Classes** | | | | |
| ProducerPlacedOnMarketTriggerHandler | ✅ Active (Oct 21) | ✅ Exists | ⚠️ Outdated | Update to latest version |
| ProducerPlacedOnMarketTriggerHelper | ✅ Active (Oct 21) | ✅ Exists | ⚠️ Outdated | Update to latest version |
| ProducerPlacedOnMarketTriggerTest | ✅ Active | ✅ Exists | ⚠️ Outdated | Update test class |
| ProducerSharingHelper | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new class** |
| ProducerSharingHelperTest | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new test** |
| UserSharingBackfillHelper | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new class** |
| UserSharingBackfillHelperTest | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new test** |
| **Apex Triggers** | | | | |
| ProducerPlacedOnMarketTrigger | ✅ Active | ❌ Inactive | **CRITICAL** | **Activate trigger** |
| ProducerContractSharingTrigger | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new trigger** |
| ProducerObligationSharingTrigger | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new trigger** |
| ProducerPlacedOnMarketSharingTrigger | ✅ Active (Oct 21) | 🚨 Missing | **CRITICAL** | **Deploy new trigger** |
| **Flows** | | | | |
| Producer_Obligation_Before_Save | ✅ V2 Active | ⚠️ V1 Active | Outdated | Update to V2 |
| Producer_Obligation_After_Save | ✅ V1 Active | ✅ V1 Active | ✅ Match | No action |
| Producer_Contract_Before_Delete | ✅ V1 Active | ✅ V1 Active | ✅ Match | No action |
| Producer_Contract_After_Save | ✅ V2 Active | ⚠️ Draft | Inactive | Activate V2 |
| Producer_Obligation_Before_Delete | ✅ V1 Active | ✅ V1 Active | ✅ Match | No action |
| Validation_Question_Before_Save | ✅ V1 Active | ⚠️ Draft | Inactive | Activate flow |
| Manage_Producer_User_Access... | ✅ V1 Active | ⚠️ Draft | Inactive | Activate flow |
| **Custom Objects** | | | | |
| Producer_Contract__c | ✅ Configured | ✅ Exists | ✅ Match | Verify fields only |
| Producer_Obligation__c | ✅ Configured | ✅ Exists | ✅ Match | Verify fields only |
| Producer_Placed_on_Market__c | ✅ Configured | ✅ Exists | ✅ Match | Verify fields only |
| Producer_Obligation_Pricing__c | ✅ Configured | ✅ Exists | ✅ Match | Verify fields only |
| Validation_Question__c | ✅ Configured | ✅ Exists | ✅ Match | Verify fields only |
| **Permission Sets** | | | | |
| Customer_Community_Plus | ✅ Enhanced (Oct 20) | ⚠️ Basic | Outdated | Update with field permissions |

### Gap Summary

**Critical Gaps** (🚨):
- 4 missing Apex classes (2 sharing helpers + 2 tests)
- 3 missing sharing triggers
- 1 inactive trigger (ProducerPlacedOnMarketTrigger)

**Medium Gaps** (⚠️):
- 3 outdated Apex classes
- 1 outdated flow (Producer_Obligation_Before_Save)
- 3 inactive flows (currently in Draft)
- 1 outdated permission set

**Confirmed Matches** (✅):
- All 5 custom objects exist
- 3 flows match (Producer_Obligation_After_Save, Before_Delete flows)

---

## Pre-Deployment Environment Verification

**CRITICAL**: Execute these verification steps BEFORE starting any deployment.

### Step 1: Verify Custom Objects Exist

**Query**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName LIKE 'Producer%' OR DeveloperName = 'Validation_Question' ORDER BY DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Should return 5 objects

**Configuration Table**:
| Object | OldOrg | NewOrg | Match? | Action |
|--------|--------|--------|--------|--------|
| Producer_Contract | ✅ Exists | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |
| Producer_Obligation | ✅ Exists | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |
| Producer_Obligation_Pricing | ✅ Exists | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |
| Producer_Placed_on_Market | ✅ Exists | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |
| Validation_Question | ✅ Exists | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |

**✅ If All Exist**: Proceed to Step 2
**❌ If Any Missing**: STOP - Custom objects must be deployed first (different migration scenario)

### Step 2: Verify Permission Set Exists

**Query**:
```bash
sf data query --query "SELECT Name, Label, LicenseId FROM PermissionSet WHERE Name = 'Customer_Community_Plus'" --target-org NewOrg
```

**Expected Result**: 1 permission set

**Configuration Table**:
| Component | OldOrg Value | NewOrg Value | Match? | Action |
|-----------|--------------|--------------|--------|--------|
| Permission Set Name | Customer_Community_Plus | [YOUR RESULT] | [ ] Yes / [ ] No | STOP if missing |
| License ID | 1004H000000UqMTQA0 | [YOUR RESULT] | [ ] Yes / [ ] No | Note if different |

**✅ If Exists**: Proceed to Step 3
**❌ If Missing**: STOP - Permission set must be created first

### Step 3: Check for NewOrg Deactivated Triggers

**Query**:
```bash
grep -i "producer" /home/john/Projects/Salesforce/Documentation/NEWORG_DEACTIVATED_TRIGGERS.md
```

**Purpose**: Verify ProducerPlacedOnMarketTrigger is on the deactivated list

**Expected Result**: Should find ProducerPlacedOnMarketTrigger in the list

**Configuration Table**:
| Trigger | In Deactivated List? | Current Status | Action |
|---------|---------------------|----------------|--------|
| ProducerPlacedOnMarketTrigger | [YOUR RESULT] | Inactive | Activate during migration |
| ProducerContractSharingTrigger | [YOUR RESULT] | N/A (new) | Deploy as active |
| ProducerObligationSharingTrigger | [YOUR RESULT] | N/A (new) | Deploy as active |
| ProducerPlacedOnMarketSharingTrigger | [YOUR RESULT] | N/A (new) | Deploy as active |

**✅ If On Deactivated List**: User approved activation
**❌ If Not On List**: Proceed with caution, confirm with user

### Step 4: Verify Community Exists

**Query**:
```bash
sf data query --query "SELECT Name, Status, UrlPathPrefix FROM Network WHERE Name LIKE '%Producer%' OR UrlPathPrefix LIKE '%producer%'" --target-org NewOrg
```

**Expected Result**: At least 1 community related to producers

**Configuration Table**:
| Component | OldOrg Value | NewOrg Value | Match? | Action |
|-----------|--------------|--------------|--------|--------|
| Community Name | Producer Portal | [YOUR RESULT] | [ ] Yes / [ ] No | Note if different |
| URL Prefix | producers | [YOUR RESULT] | [ ] Yes / [ ] No | Note if different |
| Status | Live | [YOUR RESULT] | [ ] Yes / [ ] No | Community must be Live |

**✅ If Community Exists and Active**: Proceed to Step 5
**⚠️ If Community Draft**: Migration can proceed but portal testing limited
**❌ If No Community**: STOP - Community must be configured first

### Step 5: Verify Producer Portal Users Exist

**Query**:
```bash
sf data query --query "SELECT COUNT(Id) TotalUsers FROM User WHERE Profile.Name LIKE '%Producer%' AND IsActive = true" --target-org NewOrg
```

**Expected Result**: At least 1 active producer user for testing

**Configuration Table**:
| Metric | OldOrg Value | NewOrg Value | Impact | Action |
|--------|--------------|--------------|--------|--------|
| Active Producer Users | 132 | [YOUR RESULT] | Testing scope | Note count |
| Test User Available | Yes | [YOUR RESULT] | Critical | Need at least 1 for testing |

**✅ If Users Exist**: Proceed to Step 6
**⚠️ If No Users**: Can deploy but cannot test portal access fully

### Step 6: Verify Sharing Settings

**Query**:
```bash
sf data query --query "SELECT DeveloperName, SharingModel FROM CustomObject WHERE DeveloperName LIKE 'Producer%' ORDER BY DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: All Producer objects should have Private sharing model

**Configuration Table**:
| Object | OldOrg Sharing | NewOrg Sharing | Match? | Action |
|--------|----------------|----------------|--------|--------|
| Producer_Contract | Private | [YOUR RESULT] | [ ] Yes / [ ] No | Must be Private for Apex sharing |
| Producer_Obligation | Private | [YOUR RESULT] | [ ] Yes / [ ] No | Must be Private for Apex sharing |
| Producer_Placed_on_Market | Private | [YOUR RESULT] | [ ] Yes / [ ] No | Must be Private for Apex sharing |

**✅ If All Private**: Ready for deployment
**❌ If Not Private**: STOP - Sharing settings must be updated first

---

## Migration Strategy

### Deployment Order

The deployment must follow this exact sequence to avoid dependency errors:

**Phase 1**: Foundation (Apex Classes)
- Deploy sharing helper classes first
- These have no dependencies on triggers

**Phase 2**: Apex Triggers
- Deploy 3 new sharing triggers
- Update ProducerPlacedOnMarketTrigger (activate)

**Phase 3**: Flows
- Update Producer_Obligation_Before_Save to V2
- Activate flows currently in Draft

**Phase 4**: Permission Set
- Update Customer_Community_Plus with field-level security

**Phase 5**: Testing & Activation
- Comprehensive testing with portal users
- Monitor sharing records creation
- Validate Login license user access

### Risk Mitigation

1. **Deploy as Inactive First**: All components deploy inactive/Draft initially
2. **Test Before Activating**: Comprehensive testing in inactive state
3. **Staged Activation**: Activate one component at a time
4. **Monitor Sharing**: Watch for share record creation
5. **Rollback Ready**: Deactivation scripts prepared

---

## Deployment Steps

### Phase 1: Deploy Apex Classes (NEW + Updates)

**Step 1.1: Deploy New Sharing Helper Classes**

```bash
cd /tmp/Salesforce_NewOrg/producer-portal

sf project deploy start \
  --source-dir "code/classes" \
  --metadata "ApexClass:ProducerSharingHelper" \
  --metadata "ApexClass:ProducerSharingHelperTest" \
  --metadata "ApexClass:UserSharingBackfillHelper" \
  --metadata "ApexClass:UserSharingBackfillHelperTest" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "ProducerSharingHelperTest" \
  --tests "UserSharingBackfillHelperTest" \
  --wait 15
```

**Expected Output**:
- Status: Succeeded
- Tests Run: 2 test classes
- Test Failures: 0
- Code Coverage: >75%

**Verification**:
```bash
sf data query --query "SELECT Name, LengthWithoutComments FROM ApexClass WHERE Name IN ('ProducerSharingHelper', 'UserSharingBackfillHelper') ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 2 classes returned

**Step 1.2: Update Existing Apex Classes**

```bash
sf project deploy start \
  --source-dir "code/classes" \
  --metadata "ApexClass:ProducerPlacedOnMarketTriggerHandler" \
  --metadata "ApexClass:ProducerPlacedOnMarketTriggerHelper" \
  --metadata "ApexClass:ProducerPlacedOnMarketTriggerTest" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "ProducerPlacedOnMarketTriggerTest" \
  --wait 15
```

**Expected Output**:
- Status: Succeeded
- Tests Run: 1 test class
- Test Failures: 0

**Verification**:
```bash
sf data query --query "SELECT Name, LastModifiedDate FROM ApexClass WHERE Name LIKE 'ProducerPlacedOnMarket%' ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 3 classes with recent LastModifiedDate

---

### Phase 2: Deploy Apex Triggers

**Step 2.1: Deploy New Sharing Triggers**

```bash
sf project deploy start \
  --source-dir "code/triggers" \
  --metadata "ApexTrigger:ProducerContractSharingTrigger" \
  --metadata "ApexTrigger:ProducerObligationSharingTrigger" \
  --metadata "ApexTrigger:ProducerPlacedOnMarketSharingTrigger" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "ProducerSharingHelperTest" \
  --wait 15
```

**Expected Output**:
- Status: Succeeded
- Tests Run: 1 test class (covers trigger logic)
- Test Failures: 0

**Verification**:
```bash
sf data query --query "SELECT Name, Status, TableEnumOrId FROM ApexTrigger WHERE Name LIKE 'Producer%Sharing%' ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 3 triggers, all Active

**Step 2.2: Update Main Trigger (Deploy as Active)**

```bash
sf project deploy start \
  --source-dir "code/triggers" \
  --metadata "ApexTrigger:ProducerPlacedOnMarketTrigger" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "ProducerPlacedOnMarketTriggerTest" \
  --wait 15
```

**Expected Output**:
- Status: Succeeded
- Trigger Status: Active

**Verification**:
```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name = 'ProducerPlacedOnMarketTrigger'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Status = Active

---

### Phase 3: Update and Activate Flows

**Step 3.1: Update Producer_Obligation_Before_Save to V2**

```bash
sf project deploy start \
  --source-dir "code/flows" \
  --metadata "Flow:Producer_Obligation_Before_Save" \
  --target-org NewOrg \
  --wait 15
```

**Verification**:
```bash
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'Producer_Obligation_Before_Save' ORDER BY VersionNumber DESC" --target-org NewOrg --use-tooling-api
```

**Expected Result**: Latest version should be V2 or higher

**Step 3.2: Activate Draft Flows**

**Flows to Activate**:
1. Producer_Contract_After_Save
2. Validation_Question_Before_Save
3. Manage_Producer_User_Access_On_Producer_Placed_On_Market_Data

**Note**: Activation must be done via Setup UI or Metadata API (cannot be done via CLI directly)

**Manual Activation Steps**:
1. Navigate to Setup → Flows
2. Find each flow listed above
3. Open the latest Draft version
4. Click "Activate"
5. Confirm activation

**Verification After Activation**:
```bash
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName IN ('Producer_Contract_After_Save', 'Validation_Question_Before_Save', 'Manage_Producer_User_Access_On_Producer_Placed_On_Market_Data') ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: All 3 flows show Status = Active

---

### Phase 4: Update Permission Set

**Step 4.1: Export Current Permission Set**

```bash
sf project retrieve start \
  --target-org NewOrg \
  --metadata "PermissionSet:Customer_Community_Plus" \
  --output-dir /tmp/producer_perm_set_backup \
  --wait 10
```

**Step 4.2: Update Permission Set with Field-Level Security**

**Manual Update Required** (Permission set updates for field-level security are complex via CLI):

1. Navigate to Setup → Permission Sets → Customer_Community_Plus
2. For each Producer object (Producer_Contract__c, Producer_Obligation__c, Producer_Placed_on_Market__c, Producer_Obligation_Pricing__c, Validation_Question__c):
   - Click "Object Settings"
   - Select the object
   - Ensure "Read" and "Edit" are checked
   - Click "Edit" under Field Permissions
   - Enable Read/Edit for ALL fields
   - Save

**Verification**:
```bash
sf data query --query "SELECT Parent.Name, SobjectType, PermissionsRead, PermissionsEdit FROM ObjectPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_Plus') AND SobjectType LIKE 'Producer%'" --target-org NewOrg
```

**Expected Result**: Should return 5 records (one per Producer object) with Read and Edit = true

---

### Phase 5: Post-Deployment Validation

**Test 1: Verify Sharing Triggers Fire**

```bash
# Create a test Producer Contract record
sf data create record --sobject Producer_Contract__c --values "Name='Test Contract for Sharing'" --target-org NewOrg --json
```

**Expected Result**: Share records should be auto-created (verify via Setup → Sharing)

**Test 2: Verify Apex Classes Deployed**

```bash
sf data query --query "SELECT Name, Status FROM ApexClass WHERE Name LIKE 'Producer%' OR Name LIKE '%Sharing%' ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 7 classes, all with Status info available

**Test 3: Verify Triggers Active**

```bash
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name LIKE 'Producer%' ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 4 triggers, all Active

**Test 4: Verify Flows Active**

```bash
sf data query --query "SELECT Definition.DeveloperName, Status FROM Flow WHERE Definition.DeveloperName LIKE 'Producer%' OR Definition.DeveloperName LIKE 'Validation%' OR Definition.DeveloperName LIKE 'Manage_Producer%' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Result**: All critical flows show Status = Active

**Test 5: Test Portal User Access** (Manual)

1. Log in as a Login license producer user
2. Navigate to Producer Contracts
3. Verify records are visible
4. Navigate to Producer Obligations
5. Verify records are visible
6. Navigate to Producer Placed on Market
7. Verify records are visible

**Expected Result**: All records visible with appropriate permissions

---

## Post-Deployment Testing Plan

### Test Case 1: Sharing for Customer Community Plus License

**Objective**: Verify manual + trigger-based sharing works for Customer Community Plus users

**Steps**:
1. Create test Producer Contract
2. Manually share with Customer Community Plus user
3. Verify user sees Contract
4. Verify user sees related Obligations
5. Verify user sees related Placed on Market records

**Expected Result**: All records visible via manual + trigger sharing

### Test Case 2: Sharing for Login License

**Objective**: Verify trigger-based sharing works for Login license users

**Steps**:
1. Identify Director user with Login license
2. Assign to Producer Contract
3. Verify share records created automatically
4. Log in as Director
5. Verify all related records visible

**Expected Result**: Full access via trigger-based sharing only

### Test Case 3: Variance Detection

**Objective**: Verify multi-period variance detection works

**Steps**:
1. Create Producer Obligation for Q1 2025
2. Create Placed on Market record with tonnage = 100 for Q1
3. Create Placed on Market record with tonnage = 25 for Q2 (75% drop)
4. Verify Validation Question auto-created (quarter-over-quarter)
5. Create Placed on Market record for Q1 2024 with tonnage = 100
6. Modify Q1 2025 to tonnage = 30 (70% drop year-over-year)
7. Verify Validation Question created (year-over-year)

**Expected Result**: Validation questions triggered by both comparison types

### Test Case 4: Flow Execution

**Objective**: Verify all flows execute correctly

**Steps**:
1. Test Producer_Obligation_Before_Save: Create obligation, verify validation
2. Test Producer_Contract_Before_Delete: Try to delete contract with obligations, verify prevention
3. Test Producer_Obligation_Before_Delete: Try to delete obligation with submissions, verify prevention
4. Test Validation_Question_Before_Save: Create validation question, verify logic

**Expected Result**: All flows execute as designed

### Test Case 5: Permission Set Field Access

**Objective**: Verify field-level security for Login license users

**Steps**:
1. Log in as Login license user
2. Navigate to Producer Contract
3. Verify all fields visible
4. Repeat for Producer Obligation
5. Repeat for Producer Placed on Market

**Expected Result**: All fields visible and editable per object permissions

---

## Rollback Procedures

### Immediate Rollback (5-10 minutes)

**When to Use**: Minor issues with sharing triggers or updated trigger

**Steps**:
```bash
# Deactivate new sharing triggers
# (Via Setup UI: Setup → Apex Triggers → Deactivate)
# 1. ProducerContractSharingTrigger
# 2. ProducerObligationSharingTrigger
# 3. ProducerPlacedOnMarketSharingTrigger

# Deactivate main trigger if needed
# ProducerPlacedOnMarketTrigger
```

**Impact**: Sharing stops for new records, existing shares remain

### Partial Rollback (15-20 minutes)

**When to Use**: Moderate issues affecting flows or multiple components

**Steps**:
1. Deactivate all sharing triggers (as above)
2. Deactivate flows via Setup UI:
   - Producer_Contract_After_Save
   - Validation_Question_Before_Save
   - Manage_Producer_User_Access_On_Producer_Placed_On_Market_Data
3. Deactivate ProducerPlacedOnMarketTrigger

**Impact**: Portal users lose automatic sharing, validation workflows stop

### Full Rollback (45-60 minutes)

**When to Use**: Fundamental issues requiring complete removal

**Steps**:
```bash
# Delete new sharing triggers
sf project delete source --metadata "ApexTrigger:ProducerContractSharingTrigger" --target-org NewOrg --wait 10
sf project delete source --metadata "ApexTrigger:ProducerObligationSharingTrigger" --target-org NewOrg --wait 10
sf project delete source --metadata "ApexTrigger:ProducerPlacedOnMarketSharingTrigger" --target-org NewOrg --wait 10

# Delete new Apex classes (only if no dependencies)
sf project delete source --metadata "ApexClass:ProducerSharingHelper" --target-org NewOrg --wait 10
sf project delete source --metadata "ApexClass:ProducerSharingHelperTest" --target-org NewOrg --wait 10
sf project delete source --metadata "ApexClass:UserSharingBackfillHelper" --target-org NewOrg --wait 10
sf project delete source --metadata "ApexClass:UserSharingBackfillHelperTest" --target-org NewOrg --wait 10

# Deactivate flows (as in Partial Rollback)
```

**Impact**: System returns to pre-migration state, Login users lose access

**Note**: Rollback of permission set changes requires manual reversal via Setup UI

---

## Known Issues & Risks

### Known Limitations

1. **Flow Activation**: Cannot activate flows via CLI, must use Setup UI
2. **Permission Set Updates**: Field-level security updates complex via CLI, manual recommended
3. **Community Testing**: Full testing requires actual community user access
4. **Data Migration**: This migration does NOT include data migration (records, users)

### Potential Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sharing triggers create too many share records | Low | High | Monitor initial sharing, may need to add filters |
| Flow activation breaks existing processes | Low | High | Activate one at a time, test each |
| Permission set update affects other features | Low | Medium | Back up permission set before changes |
| Login users still can't access after migration | Medium | High | Test thoroughly, may need manual share record creation |
| ProducerPlacedOnMarketTrigger conflicts with other triggers | Low | Medium | Monitor debug logs, check trigger order |
| Community not properly configured in NewOrg | Medium | High | Verify community exists and is Live before deployment |

### Risk Mitigation Strategies

1. **Deploy During Maintenance Window**: Schedule deployment when portal usage is low
2. **Staged Rollout**: Deploy to subset of users first if possible
3. **Monitor Debug Logs**: Watch for errors during first 24 hours
4. **User Communication**: Inform producers of potential access issues, provide support contact
5. **Rollback Plan Ready**: Have deactivation scripts prepared and tested
6. **Test Users Ready**: Have test users with both license types available for validation

---

## Monitoring & Validation

### First 24 Hours

**Check Every 2-3 Hours**:

1. **Debug Logs**:
```bash
# Check for Apex errors
sf apex tail log --target-org NewOrg
```

2. **Sharing Records**:
```bash
sf data query --query "SELECT COUNT(Id) FROM Producer_Contract__Share WHERE RowCause = 'Manual'" --target-org NewOrg
```

3. **User Reports**:
- Monitor support tickets for access issues
- Check community activity logs

### First Week

**Daily Checks**:

1. **Portal User Feedback**: Gather feedback from producer users
2. **Sharing Audit**: Verify share records created correctly
3. **Flow Errors**: Check for flow failures
4. **Performance**: Monitor SOQL queries, CPU time

### First Month

**Weekly Reviews**:

1. **Access Patterns**: Analyze which users are accessing which records
2. **Optimization**: Identify opportunities to reduce sharing records
3. **Documentation**: Update based on lessons learned

---

## Success Criteria

### Technical Success

- [ ] All 4 new Apex classes deployed successfully
- [ ] All 4 triggers active and firing correctly
- [ ] All 7 critical flows active
- [ ] Permission set updated with field-level security
- [ ] Test coverage >75% for all new classes
- [ ] No deployment errors or test failures

### Functional Success

- [ ] Login license users can access Producer data
- [ ] Sharing triggers create share records automatically
- [ ] Variance detection works for both period comparisons
- [ ] Validation questions auto-create correctly
- [ ] Portal users can submit quarterly data
- [ ] Flows execute without errors

### Business Success

- [ ] 132 producer users have appropriate access
- [ ] No support tickets for access issues
- [ ] Portal submission workflow functions end-to-end
- [ ] Directors with Login licenses have full visibility
- [ ] System stable for 1 week post-deployment

---

## Support & Resources

### Documentation References

- **OldOrg State**: `/tmp/Salesforce_OldOrg_State/producer-portal/README.md` - Current state snapshot with verification data
- **Primary Documentation**: `/home/john/Projects/Salesforce/Documentation/PRODUCER_PORTAL_MASTER_DOCUMENTATION.md` - Comprehensive system documentation (1926 lines)
- **Troubleshooting Guide**: `/home/john/Projects/Salesforce/Documentation/PRODUCER_PORTAL_ACCESS_ERROR_TROUBLESHOOTING.md` - Access error resolution (Login license issues)
- **Archived Documentation**: `/home/john/Projects/Salesforce/Documentation/Archive/PRODUCER_PORTAL_*.md` - Historical versions
- **Workflow Rules**: `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md` - Migration standards
- **Deactivated Triggers**: `/home/john/Projects/Salesforce/Documentation/NEWORG_DEACTIVATED_TRIGGERS.md` - Triggers that must remain inactive

**Related Documentation Analysis**:
All Producer Portal related documents consolidated into this migration scenario. Troubleshooting guide documents the specific access errors fixed in OldOrg V2-V3 (Oct 20-21, 2025) that are being deployed to NewOrg.

### Key Contacts

- **Technical Lead**: John Shintu (Implementation)
- **Original Developer**: Vesium Gerry Gregoire (V1 Build)
- **Business Owner**: [Producer Compliance Team]

### Troubleshooting

**Issue**: Login users still can't see records after deployment

**Solution**: Run UserSharingBackfillHelper to create share records for existing data
```apex
// Execute Anonymous Apex
UserSharingBackfillHelper.backfillSharing();
```

**Issue**: Sharing triggers creating too many share records

**Solution**: Review and add filters to ProducerSharingHelper logic

**Issue**: Flows not activating

**Solution**: Check for flow errors via Setup → Flows → Flow name → Edit → Debug

---

## Deployment Checklist

**Before Deployment**:
- [ ] All pre-deployment verification steps completed
- [ ] Custom objects confirmed to exist
- [ ] Permission set confirmed to exist
- [ ] Community confirmed to be Live (or Draft acceptable for testing)
- [ ] Producer portal users exist for testing
- [ ] Sharing settings confirmed as Private
- [ ] Maintenance window scheduled
- [ ] Stakeholders notified
- [ ] Rollback plan reviewed

**During Deployment**:
- [ ] Phase 1: Deploy Apex classes (new + updates)
- [ ] Verify Phase 1 deployment successful
- [ ] Phase 2: Deploy Apex triggers (new + activation)
- [ ] Verify Phase 2 deployment successful
- [ ] Phase 3: Update and activate flows
- [ ] Verify Phase 3 activation successful
- [ ] Phase 4: Update permission set
- [ ] Verify Phase 4 updates successful
- [ ] Phase 5: Run post-deployment validation tests
- [ ] Verify all tests pass

**After Deployment**:
- [ ] Test Case 1: Customer Community Plus sharing ✅
- [ ] Test Case 2: Login license sharing ✅
- [ ] Test Case 3: Variance detection ✅
- [ ] Test Case 4: Flow execution ✅
- [ ] Test Case 5: Permission set field access ✅
- [ ] Monitor debug logs (first 24 hours)
- [ ] Gather user feedback (first week)
- [ ] Update documentation with any deviations
- [ ] Mark migration as complete in MIGRATION_PROGRESS.md

---

**Migration Plan Status**: 📋 Ready for Review
**Last Updated**: October 22, 2025
**Next Steps**:
1. User reviews this migration plan
2. User approves deployment approach and timing
3. Execute pre-deployment verification
4. Schedule deployment during maintenance window
5. Execute deployment phases
6. Complete post-deployment testing
7. Monitor for 1 week
8. Mark as complete
