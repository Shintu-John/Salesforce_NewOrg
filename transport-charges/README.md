# Transport Charge Issues - NewOrg Migration Plan

**Scenario**: RLCS Transport & Data Issues (3 Critical Bug Fixes)
**Source**: OldOrg (Recycling Lives Service)
**Target**: NewOrg (Recycling Lives Group)
**Priority**: 🚨 **CRITICAL** - Financial impact £1.7M+ if not deployed
**Status**: ✅ **DEPLOYED TO NEWORG** - October 23, 2025
**Deploy IDs**: 0AfSq000003nLkjKAE (code), 0AfSq000003nLw1KAE (validation rule)

## 📋 Quick Links

- 📊 **[Deployment History](./DEPLOYMENT_HISTORY.md)** - Complete deployment log with 3 bug fixes
- ✅ **[Functional Test Results](./FUNCTIONAL_TEST_RESULTS.md)** - 8/8 tests passed (£1.7M+ protected)
- 🧪 **[Test Scripts](./tests/)** - Functional test scripts for all 3 issues
- 📝 **[Deployed Code](./code/)** - rlcsJobService.cls (819 lines) and validation rule
- 🔙 **[Main README](../README.md)** - Repository overview and deployment progress

---

## 🎉 Deployment Summary

**Deployment Date**: October 23, 2025
**Deployment Status**: ✅ COMPLETE
**All Tests**: 65/65 Passed (100%)

### What Was Deployed:
- ✅ rlcsJobService.cls (updated to Oct 15 version)
- ✅ rlcsJobServiceTest.cls (newly deployed, 65 tests)
- ✅ rlcsJobTrigger (activated from Inactive to Active)
- ✅ Transport_Flag_Validation (new validation rule on OrderItem)

### Deploy IDs:
- Phase 1 (Code): `0AfSq000003nLkjKAE`
- Phase 2 (Validation Rule): `0AfSq000003nLw1KAE`

**See**: [DEPLOYMENT_HISTORY.md](DEPLOYMENT_HISTORY.md) for complete deployment details

---

## Executive Summary

NewOrg is running **OUTDATED CODE** with **5-day-old version** missing critical bug fixes that prevented £1,788,766 in financial issues in OldOrg.

### Critical Version Mismatch

| Metric | OldOrg (Source) | NewOrg (Target) | Gap |
|--------|-----------------|-----------------|-----|
| **Last Modified** | Oct 15, 2025 11:18 | Oct 10, 2025 12:59 | **5 days behind** |
| **Lines of Code** | 819 lines | 575 lines | **244 lines missing** |
| **Issue 1 Fix** | ✅ Deployed Oct 14 | ❌ **MISSING** | Map reassignment bug |
| **Issue 3 Fix** | ✅ Deployed Oct 15 | ❌ **MISSING** | Hybrid calculation bug |
| **Secondary Transport** | ✅ Implemented | ❌ **MISSING** | Entire feature missing |

### Business Impact If Not Deployed

🚨 **WITHOUT THIS DEPLOYMENT**, NewOrg will experience:

1. **Issue 1: Missing Transport Charges**
   - 53% of Jobs will have NO transport charges
   - Manual backfill required for hundreds of Jobs
   - Revenue loss: Potentially £900K+ untracked

2. **Issue 3: Incorrect Charge Calculations**
   - Hybrid bug: Uses OrderItem rates but Job flags
   - Massive overcharges: £136 × 100 units = £13,600 (should be £340)
   - Financial impact: £870K+ in incorrect charges

3. **Missing Secondary Transport Feature**
   - Cannot handle dual-transport Jobs
   - 244 lines of functionality missing
   - Business process limitation

---

## Gap Analysis

### Component Comparison

| Component | OldOrg | NewOrg | Status | Action Required |
|-----------|--------|--------|--------|-----------------|
| **rlcsJobService.cls** | 819 lines (Oct 15) | 575 lines (Oct 10) | ❌ **OUTDATED** | ✅ Deploy complete class |
| **rlcsJobServiceTest.cls** | 2,400+ lines | ❌ **MISSING** | ❌ **NOT IN NEWORG** | ✅ Deploy test class |
| **Transport Flag Validation** | ✅ Deployed | ❌ **MISSING** | ❌ **NOT IN NEWORG** | ⚠️ Manual UI (validation rule) |

### Missing Fixes

#### Issue 1 Fix (Oct 14) - ❌ NOT IN NEWORG

**Location**: Line 281 (OldOrg)
**Fix**: `jobsToProcessById = jobsWithOrderProductMap;`

**Verification**:
```bash
# OldOrg (HAS FIX):
grep "jobsToProcessById = jobsWithOrderProductMap" rlcsJobService.cls
# Returns: Line 281

# NewOrg (MISSING):
grep "jobsToProcessById = jobsWithOrderProductMap" rlcsJobService.cls
# Returns: (empty - NOT FOUND)
```

**Impact if not deployed**: 53% of Jobs will have no transport charges.

#### Issue 3 Fix (Oct 15) - ❌ NOT IN NEWORG

**Locations**: 9 locations in OldOrg using `Order_Product__r?.Transport_Per_Tonne__c`

**Verification**:
```bash
# OldOrg (HAS FIX):
grep "Order_Product__r?.Transport_Per_Tonne__c" rlcsJobService.cls
# Returns: 9 lines (393, 395, 432, 434, 536, 676, 678, 715, 717)

# NewOrg (MISSING - HAS OLD BUGGY CODE):
grep "job.Transport_Per_Tonne__c ?" rlcsJobService.cls
# Returns: 3 lines (345, 396, 513) - STILL USING JOB FLAGS (BUGGY!)
```

**Impact if not deployed**: £870K+ in incorrect charge calculations.

#### Secondary Transport Feature - ❌ NOT IN NEWORG

**Missing Lines**: 244 lines of code
**Missing Functionality**:
- Secondary transport charge creation
- Different haulier support
- Independent calculation methods

**Impact**: Cannot handle dual-transport Jobs (collection + final destination).

### SOQL Query Gaps

**OldOrg queries include** (4 locations):
- `Order_Product__r.Transport_Per_Tonne__c`
- `Order_Product__r.Transport_Per_Unit__c`
- `Order_Product__r.Secondary_Transport_Charge__c`
- `Order_Product__r.Secondary_Transport_Per_Tonne__c`
- `Order_Product__r.Secondary_Transport_Per_Unit__c`

**NewOrg queries**: ❌ **MISSING ALL OrderItem flag fields**

### Test Class Gap

- **OldOrg**: rlcsJobServiceTest.cls exists (2,400+ lines, 65 tests)
- **NewOrg**: ❌ **Test class does NOT exist**
- **Impact**: Cannot deploy without test class (deployment will fail)

---

## Pre-Deployment Verification

### Environment Checks

Run these queries in NewOrg **BEFORE** deployment:

#### 1. Check Current Code Version

```apex
// Query current class metadata
ApexClass cls = [SELECT Id, LastModifiedDate, LastModifiedBy.Name
                 FROM ApexClass WHERE Name = 'rlcsJobService' LIMIT 1];
System.debug('Current Version: ' + cls.LastModifiedDate);
// Expected: 2025-10-10 12:59:04 (OLD)
// After deployment: 2025-10-15 11:18:21 (NEW)
```

#### 2. Check for Active Jobs

```soql
SELECT COUNT()
FROM RLCS_Job__c
WHERE CreatedDate = LAST_N_DAYS:7
AND Order_Product__c != NULL
```

**Why**: Understand volume of recent Jobs that might be affected.

#### 3. Check Existing Transport Charges

```soql
SELECT COUNT(), SUM(Cost__c)
FROM RLCS_Charge__c
WHERE Charge_Type__c = 'Transport'
AND CreatedDate = LAST_N_DAYS:30
```

**Why**: Baseline for post-deployment comparison.

#### 4. Backup Recommendation

⚠️ **CRITICAL**: Create sandbox backup before deploying to production NewOrg.

```bash
# Create changeset or backup current version
sf project retrieve start -o NewOrg -m ApexClass:rlcsJobService
```

---

## Deployment Steps

### Phase 1: Deploy Code (CLI)

**Deploy ID**: (Will be generated)
**Estimated Time**: 10-15 minutes
**Test Coverage Required**: 75%+

#### Step 1.1: Deploy Apex Classes

✅ **CLI Command**:
```bash
# From /tmp/Salesforce_NewOrg/transport-charges/code/classes/
sf project deploy start -o NewOrg \
  -m "ApexClass:rlcsJobService" \
  -m "ApexClass:rlcsJobServiceTest" \
  --test-level RunLocalTests \
  --dry-run
```

**Verification**:
- ✅ Dry-run succeeds
- ✅ All tests pass (65/65 expected)
- ✅ Test coverage > 75%

#### Step 1.2: Actual Deployment

✅ **CLI Command**:
```bash
# Remove --dry-run flag for actual deployment
sf project deploy start -o NewOrg \
  -m "ApexClass:rlcsJobService" \
  -m "ApexClass:rlcsJobServiceTest" \
  --test-level RunLocalTests
```

**Expected Output**:
```
Status: Succeeded
Component Deployments: 4/4
Apex Test Results: 65/65 Passed
Code Coverage: 85%+ (estimated)
```

**Save Deploy ID for rollback**.

### Phase 2: Add Validation Rule (Manual UI)

⚠️ **MANUAL UI STEP** (Cannot be automated via CLI)

**Object**: Order_Product__c (OrderItem - Standard Salesforce)
**Rule Name**: Transport_Flag_Validation

#### Step 2.1: Create Validation Rule

1. Navigate to **Setup** → **Object Manager** → **Order Product** (OrderItem)
2. Click **Validation Rules** → **New**
3. **Rule Name**: `Transport_Flag_Validation`
4. **Error Condition Formula**:
   ```
   AND(
     Transport_Per_Tonne__c,
     Transport_Per_Unit__c
   )
   ```
5. **Error Message**:
   ```
   Transport charge cannot be both Per Tonne and Per Unit.
   Please select only one calculation method.
   ```
6. **Error Location**: Top of Page
7. Click **Save**

**Verification**:
- ✅ Rule active
- ✅ Test: Try setting both flags to true on OrderItem → Should error

---

## Post-Deployment Validation

### Verification Queries

Run these in NewOrg **AFTER** deployment:

#### 1. Verify Code Version

```apex
ApexClass cls = [SELECT Id, LastModifiedDate, Body
                 FROM ApexClass WHERE Name = 'rlcsJobService' LIMIT 1];
System.debug('New Version: ' + cls.LastModifiedDate);
System.debug('Line Count: ' + cls.Body.split('\n').size());
// Expected LastModifiedDate: > 2025-10-15
// Expected Line Count: 819
```

#### 2. Verify Issue 1 Fix

```apex
// Check for map reassignment line
ApexClass cls = [SELECT Body FROM ApexClass WHERE Name = 'rlcsJobService'];
Boolean hasFix = cls.Body.contains('jobsToProcessById = jobsWithOrderProductMap');
System.debug('Issue 1 Fix Present: ' + hasFix);
// Expected: true
```

#### 3. Verify Issue 3 Fix

```apex
// Check for OrderItem flag usage
ApexClass cls = [SELECT Body FROM ApexClass WHERE Name = 'rlcsJobService'];
Boolean hasFix = cls.Body.contains('Order_Product__r?.Transport_Per_Tonne__c');
System.debug('Issue 3 Fix Present: ' + hasFix);
// Expected: true
```

#### 4. Functional Test - Create Test Job

```apex
// Create test Job with OrderItem
Account acc = [SELECT Id FROM Account LIMIT 1];
Order ord = new Order(AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft');
insert ord;

OrderItem oi = new OrderItem(
    OrderId = ord.Id,
    Quantity = 1,
    UnitPrice = 100,
    Transport__c = 10.00,
    Transport_Per_Tonne__c = true,
    Transport_Per_Unit__c = false
);
insert oi;

RLCS_Job__c job = new RLCS_Job__c(
    Order_Product__c = oi.Id,
    Material_Weight_Tonnes__c = 2.5,
    Unit_Count__c = 100
);
insert job;

// Check charge created
List<RLCS_Charge__c> charges = [SELECT Id, Cost__c, Charge_Type__c
                                 FROM RLCS_Charge__c
                                 WHERE RLCS_Job__c = :job.Id
                                 AND Charge_Type__c = 'Transport'];

System.debug('Charges Created: ' + charges.size());
System.debug('Charge Amount: ' + (charges.size() > 0 ? charges[0].Cost__c : 0));
// Expected: 1 charge
// Expected Amount: 2.5 tonnes × £10.00 = £25.00
```

#### 5. Verify Test Class

```apex
ApexClass test = [SELECT Id, Name FROM ApexClass WHERE Name = 'rlcsJobServiceTest'];
System.debug('Test Class Exists: ' + (test != null));
// Expected: true
```

#### 6. Run All Tests

```bash
sf apex run test -o NewOrg -n "rlcsJobServiceTest" --result-format human
```

**Expected**:
- ✅ 65/65 tests passing
- ✅ No failures
- ✅ Code coverage > 75%

---

## Rollback Procedure

### If Deployment Fails

#### Step 1: Check Failure Reason

```bash
sf project deploy report --job-id <DEPLOY_ID>
```

#### Step 2: Roll Back Code

```bash
# Retrieve pre-deployment backup
sf project deploy start -o NewOrg \
  --source-dir <backup-folder> \
  --test-level NoTestRun
```

#### Step 3: Remove Validation Rule (if added)

1. Navigate to Setup → Object Manager → Order Product
2. Click Validation Rules → Transport_Flag_Validation
3. Click **Delete**

### If Post-Deployment Issues Occur

#### Deactivate Validation Rule

1. Edit validation rule
2. Uncheck **Active**
3. Click **Save**

**Note**: Cannot rollback Apex code without redeploying old version.

---

## Risk Assessment

### High Risk (Critical Impact)

1. **Missing Test Class in NewOrg**
   - **Risk**: Deployment might fail if test class doesn't exist
   - **Mitigation**: Deploy test class first, verify it compiles
   - **Impact**: Deployment blocked until resolved

2. **Active Jobs During Deployment**
   - **Risk**: Jobs created during deployment might behave unexpectedly
   - **Mitigation**: Deploy during low-activity window (weekend/evening)
   - **Impact**: Minimal if deployment window < 5 minutes

### Medium Risk

1. **Data Differences (OldOrg vs NewOrg)**
   - **Risk**: NewOrg might have different OrderItem data
   - **Mitigation**: Post-deployment verification queries
   - **Impact**: Individual charge corrections if needed

### Low Risk

1. **Validation Rule Blocking Existing Data**
   - **Risk**: Existing OrderItems with both flags = true
   - **Mitigation**: Fix before activating rule (query and correct)
   - **Impact**: Minimal - rule only affects new/updated records

---

## Dependencies

### Required For Deployment

- ✅ Apex Class: rlcsJobService.cls (819 lines) - In `code/classes/`
- ✅ Apex Class: rlcsJobServiceTest.cls (2,400+ lines) - In `code/classes/`
- ✅ Salesforce CLI with NewOrg authentication
- ✅ Deploy permissions (System Administrator or equivalent)

### Optional (Manual UI)

- ⚠️ Validation Rule: Transport_Flag_Validation (prevents invalid flag states)

### Deployment Order

1. **First**: Deploy both Apex classes together (test class must deploy with service class)
2. **Second**: Add validation rule (after code deployment succeeds)

---

## Estimated Timeline

| Phase | Task | Time | Type |
|-------|------|------|------|
| **Pre-Deployment** | Environment checks | 10 min | Queries |
| **Pre-Deployment** | Backup current code | 5 min | CLI |
| **Phase 1** | Deploy classes (dry-run) | 5 min | ✅ CLI |
| **Phase 1** | Review dry-run results | 5 min | Review |
| **Phase 1** | Deploy classes (actual) | 10 min | ✅ CLI |
| **Phase 2** | Add validation rule | 5 min | ⚠️ Manual UI |
| **Post-Deployment** | Verification queries | 10 min | Queries |
| **Post-Deployment** | Functional testing | 10 min | Test |
| **TOTAL** | **End-to-End** | **60 min** | **1 hour** |

**Recommended Window**: Saturday or Sunday, 2:00 PM - 4:00 PM (low activity period)

---

## Success Criteria

### Deployment Success

- ✅ Deploy status: Succeeded
- ✅ All tests passing: 65/65 (100%)
- ✅ Code coverage: > 75%
- ✅ No deployment errors or warnings

### Code Verification

- ✅ OldOrg code matches NewOrg code (819 lines)
- ✅ LastModifiedDate after Oct 15, 2025
- ✅ Issue 1 fix present (map reassignment)
- ✅ Issue 3 fix present (OrderItem flags)
- ✅ Test class exists and compiles

### Functional Verification

- ✅ Test Job creates Transport charge correctly
- ✅ Charge calculation uses OrderItem flags (not Job flags)
- ✅ Calculation: (tonnes OR units OR 1) × OrderItem rate
- ✅ Validation rule prevents invalid flag combinations

### Business Verification

- ✅ New Jobs in production create charges successfully
- ✅ Charge amounts match expected calculations
- ✅ No charge creation failures reported
- ✅ Finance team confirms charge accuracy

---

## Known Issues & Limitations

### Issue 2: Material Category Breakdown

**Status**: NOT PART OF THIS DEPLOYMENT

**Reason**: Issue 2 is a **user process issue**, not a code bug. It requires user action (upload ICER reports for 208 WEEE Jobs).

**Action Required**: Separate user training and data remediation project.

### Locked Charges (Issue 3 Data Correction)

**Status**: NOT APPLICABLE TO NEWORG

**Reason**: Issue 3 data corrections (Phase 2 & 3) were specific to OldOrg historical data. NewOrg starts fresh with corrected code.

**No action required** in NewOrg deployment.

---

## Related Documentation

### Source Documentation

- **OldOrg State**: [../../../Salesforce_OldOrg_State/transport-charges/README.md](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/transport-charges)
  - Complete OldOrg implementation details
  - All 3 issues documented with verification
  - Deployment IDs: 0AfSj000000ymo9KAA, 0AfSj000000yp2rKAA, 0AfSj000000ypVtKAI

- **Original Consolidated Doc**: [source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md](source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md)
  - Complete analysis of all 3 issues (1,140 lines)
  - Historical context and discovery timeline

### Deployment-Ready Code

All code verified and ready to deploy:

- [code/classes/rlcsJobService.cls](code/classes/rlcsJobService.cls) - 819 lines (Oct 15, 2025)
- [code/classes/rlcsJobServiceTest.cls](code/classes/rlcsJobServiceTest.cls) - 2,400+ lines, 65 tests

---

## Critical Alerts

🚨 **CRITICAL FINANCIAL RISK**: NewOrg has outdated code (5 days old, 244 lines missing) with bugs that caused £1.7M+ issues in OldOrg.

⚠️ **DEPLOYMENT URGENCY**: HIGH - Deploy before NewOrg processes significant Job volume.

✅ **DEPLOYMENT READINESS**: Code verified line-by-line, test class ready, deployment plan complete.

🎯 **SUCCESS RATE**: 99.8% (based on OldOrg deployment results - 1,032 of 1,034 Jobs fixed successfully).

---

**Migration Plan Status**: ✅ Ready for Deployment
**Deployment Method**: ✅ CLI (Apex classes) + ⚠️ Manual UI (validation rule)
**Estimated Time**: 1 hour
**Risk Level**: Medium (mitigated with rollback plan)

**Last Updated**: October 23, 2025
**Prepared By**: Migration Team (OldOrg → NewOrg Migration Project)
