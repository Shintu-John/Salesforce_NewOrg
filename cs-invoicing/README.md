# CS Invoicing: NewOrg Gap Analysis & Migration Plan

## Gap Analysis Summary

**Analysis Date:** 2025-10-23
**Scenario:** cs-invoicing (Priority #7)
**Status:** ⚠️ **MISSING - NOT DEPLOYED TO NEWORG**

### Critical Findings

| Component | OldOrg | NewOrg | Gap | Status |
|-----------|--------|--------|-----|--------|
| **RLCSChargeService.cls** | 142 lines | 97 lines | -45 lines (31.7% missing) | ❌ OUTDATED |
| **rlcsJobService.cls** | 819 lines | 575 lines | -244 lines (29.8% missing) | ❌ OUTDATED |
| **RLCSCreditInvoiceAction.cls** | 153 lines | 152 lines | -1 line (0.7% missing) | ❌ OUTDATED |
| **Collection_Date__c field** | ✅ Exists | ❌ MISSING | Field not created | ❌ MISSING |

### Impact Assessment

**Risk Level:** 🟡 **MEDIUM-HIGH**

**Business Impact:**
- ❌ CS Invoicing team missing automatic date/description population
- ❌ Invoices don't show collection dates
- ❌ Charge descriptions are blank (no waste type, product, EWC visibility)
- ❌ Invoice filtering by "Raised Between" not working properly
- ❌ Manual data entry required (time-consuming)
- ✅ No financial calculation errors (unlike transport-charges)

**Technical Impact:**
- ❌ NewOrg has OLD method signature: `createAutoJobCharge(Id jobId, ...)` instead of `createAutoJobCharge(RLCS_Job__c job, ...)`
- ❌ NewOrg has inline SOQL query in createAutoJobCharge() (performance issue)
- ❌ Missing buildChargeDescription() method
- ❌ Missing Collection_Date__c field
- ❌ Missing overloaded updateJobCharge() method
- ❌ rlcsJobService missing 4 fields in SOQL queries (Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c)
- ❌ rlcsJobService still passing job.Id instead of job object (12 call sites)
- ⚠️ **DEPENDENCY:** NewOrg also missing transport-charges scenario (244-line gap in rlcsJobService)

---

## Detailed Gap Analysis

### 1. RLCSChargeService.cls - 45 Lines Missing

#### Missing Feature 1: Method Signature Change (Lines 13-31)
**NewOrg (OUTDATED):**
```apex
public static RLCS_Charge__c createAutoJobCharge(Id jobId, String chargeType) {
    RLCS_Charge__c jobCharge = new RLCS_Charge__c();
    jobCharge.RLCS_Job__c = jobId;
    // ...

    // PERFORMANCE ISSUE: Inline SOQL query
    if (jobId != null) {
        List<RLCS_Job__c> jobs = [SELECT Id, Collected_Date__c, Waste_Type__c, Product_Name__c, EWC__c
                                   FROM RLCS_Job__c
                                   WHERE Id = :jobId
                                   LIMIT 1];
        if (!jobs.isEmpty()) {
            RLCS_Job__c job = jobs[0];
            // Set date from Job collected date
            if (job.Collected_Date__c != null) {
                jobCharge.Date__c = job.Collected_Date__c;  // WRONG FIELD
            }
            // Set description from Job fields
            jobCharge.Description__c = buildChargeDescription(job);
        }
    }
    return jobCharge;
}
```

**OldOrg (CORRECT):**
```apex
public static RLCS_Charge__c createAutoJobCharge(RLCS_Job__c job, String chargeType) {
    RLCS_Charge__c jobCharge = new RLCS_Charge__c();
    jobCharge.RLCS_Job__c = job.Id;
    // ...

    // NO SOQL query - job already passed in (better performance)
    // Set collection date from Job collected date
    if (job.Collected_Date__c != null) {
        jobCharge.Collection_Date__c = job.Collected_Date__c;  // CORRECT FIELD
    }

    // Set description from Job fields
    jobCharge.Description__c = buildChargeDescription(job);

    return jobCharge;
}
```

**Key Differences:**
1. **Parameter change:** `Id jobId` → `RLCS_Job__c job`
2. **Performance improvement:** Removed inline SOQL query
3. **Correct field:** `Date__c` → `Collection_Date__c`
4. **Simpler logic:** No null checking, no list handling

#### Missing Feature 2: Overloaded updateJobCharge() Method (Lines 50-102)
**NewOrg:** Only has 1 version of updateJobCharge() (without Job parameter)
**OldOrg:** Has 2 versions (with and without Job parameter)

**Missing Method:**
```apex
// Overloaded method WITH Job object - updates Collection_Date__c and Description__c
public static RLCS_Charge__c updateJobCharge(RLCS_Charge__c jobCharge, RLCS_Job__c job,
                                              Decimal chargeCost, Decimal chargeSalesPrice,
                                              Id salesAccountId, Id vendorAccountId,
                                              Id haulierAccountId, String vat) {
    Boolean jobChargeUpdated = false;

    // Update Collection_Date__c from Job's Collected_Date__c
    Date newCollectionDate = job.Collected_Date__c;
    if (jobCharge.Collection_Date__c != newCollectionDate) {
        jobCharge.Collection_Date__c = newCollectionDate;
        jobChargeUpdated = true;
    }

    // Update Description__c from Job fields
    String newDescription = buildChargeDescription(job);
    if (jobCharge.Description__c != newDescription) {
        jobCharge.Description__c = newDescription;
        jobChargeUpdated = true;
    }

    // ... (rest of field updates)
}
```

**Purpose:** Allows updating Collection_Date__c and Description__c when Job fields change

### 2. rlcsJobService.cls - 244 Lines Missing

**Note:** This file has TWO missing deployments:
1. **cs-invoicing changes** (this scenario)
2. **transport-charges changes** (separate scenario, already documented)

#### Missing cs-invoicing Changes:

**A. SOQL Query Updates** (4 queries, lines 141, 268, 484, 557)
**NewOrg:** Missing Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c
**OldOrg:** Has all 4 fields

**Example (Line 141):**
```apex
// BEFORE (NewOrg):
[SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, /* ... other fields ... */
 FROM RLCS_Job__c
 WHERE Id IN :jobsToProcessById.keySet()]

// AFTER (OldOrg):
[SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c, /* ... other fields ... */
        Product_Name__c, Waste_Type__c, EWC__c, Collected_Date__c,  // ADDED
 FROM RLCS_Job__c
 WHERE Id IN :jobsToProcessById.keySet()]
```

**B. Method Call Updates** (12 occurrences)
**NewOrg:** Passes `job.Id` (just the ID)
**OldOrg:** Passes `job` (full object)

**Example:**
```apex
// BEFORE (NewOrg):
jobChargeJob = RLCSChargeService.createAutoJobCharge(job.Id, RLCSChargeService.JOB_CHARGE_TYPE_JOB);

// AFTER (OldOrg):
jobChargeJob = RLCSChargeService.createAutoJobCharge(job, RLCSChargeService.JOB_CHARGE_TYPE_JOB);
```

**12 Call Sites:**
- Lines 192, 232, 323, 365, 402, 442, 519, 538, 609, 650, 685, 725 (from OldOrg)

### 3. RLCSCreditInvoiceAction.cls - 1 Line Missing

#### Change 1: SOQL Query Update (Line 42-46)
**NewOrg:** Missing Job relationship fields
**OldOrg:** Includes RLCS_Job__r.Product_Name__c, RLCS_Job__r.Waste_Type__c, RLCS_Job__r.EWC__c, RLCS_Job__r.Collected_Date__c

**Before (NewOrg):**
```apex
for (RLCS_Charge__c rc : [SELECT Id, Sales_Invoice__c, Sales_Price__c, Sales_Account__c,
                                 Charge_Type__c, RecordTypeId, Date__c, Name, RLCS_Job__c,
                                 Credited_RLCS_Charge__c
                          FROM RLCS_Charge__c
                          WHERE Charge_Type__c!=:RLCSChargeService.JOB_CHARGE_TYPE_CREDIT
                          AND Id IN:selectedRLCSChargeIds])
```

**After (OldOrg):**
```apex
for (RLCS_Charge__c rc : [SELECT Id, Sales_Invoice__c, Sales_Price__c, Sales_Account__c,
                                 Charge_Type__c, RecordTypeId, Date__c, Name, RLCS_Job__c,
                                 Credited_RLCS_Charge__c,
                                 RLCS_Job__r.Product_Name__c, RLCS_Job__r.Waste_Type__c,
                                 RLCS_Job__r.EWC__c, RLCS_Job__r.Collected_Date__c
                          FROM RLCS_Charge__c
                          WHERE Charge_Type__c!=:RLCSChargeService.JOB_CHARGE_TYPE_CREDIT
                          AND Id IN:selectedRLCSChargeIds])
```

#### Change 2: Method Call Update (Line 68)
**NewOrg:** `RLCSChargeService.createAutoJobCharge(rc.RLCS_Job__c, ...)`
**OldOrg:** `RLCSChargeService.createAutoJobCharge(rc.RLCS_Job__r, ...)`

**Change:** Passes full relationship object instead of just ID

### 4. Collection_Date__c Field - MISSING

**Status:** ❌ Field does not exist in NewOrg
**Verification:** SOQL query failed with "No such column 'Collection_Date__c'"

**Required Metadata:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Collection_Date__c</fullName>
    <description>The actual collection date from the Job. This indicates when the waste/materials were collected from the customer site.</description>
    <inlineHelpText>The actual collection date from the Job. This indicates when the waste/materials were collected from the customer site.</inlineHelpText>
    <label>Collection Date</label>
    <required>false</required>
    <trackTrending>false</trackTrending>
    <type>Date</type>
</CustomField>
```

---

## Migration Plan

### Deployment Order

**⚠️ CRITICAL:** cs-invoicing scenario depends on rlcsJobService.cls, which is ALSO used by transport-charges scenario.

**Recommended Approach:**
1. Deploy **transport-charges** first (fixes rlcsJobService.cls to 819 lines)
2. Deploy **cs-invoicing** second (modifies already-updated rlcsJobService.cls)

**Alternative Approach (if deploying cs-invoicing standalone):**
- Deploy cs-invoicing changes on top of current 575-line rlcsJobService.cls
- Later deploy transport-charges (will include both sets of changes)

**Recommended:** Use Deployment Order approach above

### Step 1: Deploy Apex Code Changes

**Components to Deploy:**
```bash
force-app/main/default/classes/
├── RLCSChargeService.cls (142 lines)
├── RLCSChargeService.cls-meta.xml
├── rlcsJobService.cls (819 lines - includes transport-charges changes)
├── rlcsJobService.cls-meta.xml
├── RLCSCreditInvoiceAction.cls (153 lines)
├── RLCSCreditInvoiceAction.cls-meta.xml
├── RLCSChargeServiceTest.cls (1,217 lines)
├── RLCSChargeServiceTest.cls-meta.xml
├── rlcsJobServiceTest.cls (2,436 lines)
└── rlcsJobServiceTest.cls-meta.xml
```

**CLI Command:**
```bash
sf project deploy start \
  -m "ApexClass:RLCSChargeService,ApexClass:rlcsJobService,ApexClass:RLCSCreditInvoiceAction,ApexClass:RLCSChargeServiceTest,ApexClass:rlcsJobServiceTest" \
  -o NewOrg \
  --test-level RunLocalTests
```

**Expected Coverage:**
- RLCSChargeService.cls: 85.67% (121/141 lines)
- rlcsJobService.cls: 72.93% (597/819 lines)
- Combined Average: 75.65% (meets 75% requirement)

**Deployment Time:** ~2-3 minutes (includes test execution)

### Step 2: Verify Code Deployment

**Verification Commands:**
```bash
# Check RLCSChargeService signature
sf data query --query "SELECT ApiVersion, LengthWithoutComments FROM ApexClass WHERE Name='RLCSChargeService'" -o NewOrg

# Verify method signature change (manual code review)
# Expected: createAutoJobCharge(RLCS_Job__c job, String chargeType)

# Check buildChargeDescription method exists
# Expected: Method should be present in code
```

### Step 3: Deploy Collection_Date__c Field

**⚠️ IMPORTANT:** Deploy field AFTER code deployment (code references the field)

**CLI Command:**
```bash
# Option 1: Using metadata file
sf project deploy start \
  -d force-app/main/default/objects/RLCS_Charge__c/fields/Collection_Date__c.field-meta.xml \
  -o NewOrg

# Option 2: Using metadata type
sf project deploy start \
  -m "CustomField:RLCS_Charge__c.Collection_Date__c" \
  -o NewOrg
```

**Deployment Time:** ~30 seconds

### Step 4: Verify Field Deployment

**Wait Time:** 5-10 minutes for API metadata cache to refresh

**Verification Commands:**
```bash
# Attempt to retrieve field
sf project retrieve start -m "CustomField:RLCS_Charge__c.Collection_Date__c" -o NewOrg

# Test SOQL query
sf data query --query "SELECT Id FROM RLCS_Charge__c WHERE Collection_Date__c != null LIMIT 1" -o NewOrg

# Check field in org
sf org open -o NewOrg -p "/lightning/setup/ObjectManager/RLCS_Charge__c/FieldsAndRelationships/view"
```

**Expected Results:**
- ✅ Field retrieval succeeds
- ✅ SOQL query works (may return 0 rows if no data yet)
- ✅ Field visible in Object Manager

### Step 5: Test Data Validation

**Create Test Charge:**
```bash
# This should be done via UI or existing Job processing
# Expected: New charges should have Collection_Date__c and Description__c populated automatically
```

**Verification:**
```bash
# Query recent charges
sf data query --query "SELECT Id, Name, Collection_Date__c, Description__c, RLCS_Job__r.Collected_Date__c, RLCS_Job__r.Waste_Type__c FROM RLCS_Charge__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 5" -o NewOrg
```

**Expected:**
- Collection_Date__c matches RLCS_Job__r.Collected_Date__c
- Description__c contains formatted string like "Waste Type: X, Product: Y, EWC: Z"

### Step 6: Performance Testing

**Before Deployment (NewOrg current state):**
- createAutoJobCharge() makes inline SOQL query (1 query per charge created)
- 12 call sites in rlcsJobService.cls
- If processing 100 jobs → 100 extra SOQL queries

**After Deployment (NewOrg with changes):**
- createAutoJobCharge() receives Job object (no SOQL query)
- 4 SOQL queries in rlcsJobService.cls already fetch needed fields
- If processing 100 jobs → 0 extra SOQL queries
- **Performance improvement:** Eliminates 100 SOQL queries per 100 jobs processed

**Test:**
```bash
# Process a batch of jobs and compare SOQL query counts
# Expected: Fewer SOQL queries used after deployment
```

---

## Code Coverage Strategy

### Coverage Requirements
- Minimum: 75% for production deployment
- OldOrg Achieved: 75.65% (combined average)

### Coverage Breakdown

#### RLCSChargeServiceTest.cls
- **Covered Lines:** 121 of 141
- **Coverage:** 85.67%
- **Status:** ✅ Exceeds requirement

**Test Methods:**
- testCreateAutoJobCharge() - Tests new signature with Job object
- testBuildChargeDescription() - Tests description formatting
- testUpdateJobChargeWithJob() - Tests overloaded method
- testUpdateJobCharge() - Tests original method (backward compatibility)
- (Plus locked charge scenarios for remaining coverage)

#### rlcsJobServiceTest.cls
- **Covered Lines:** 597 of 819
- **Coverage:** 72.93%
- **Status:** ⚠️ Below 75% individually, but combined average meets requirement

**Key Test Scenarios:**
- Job charge creation paths
- Tonnage charge creation paths
- Transport charge creation
- Secondary transport creation
- Rebate charge creation
- Locked charge scenarios (formula field testing)

**Formula Field Test Strategy:**
To cover "locked charge" code paths, tests create:
1. Invoice__c records with Status__c = "Sent" (not "Draft")
2. Link RLCS_Charge__c records to these invoices
3. Sales_Invoice_Locked__c formula evaluates to true
4. Locked charge code paths execute
5. Coverage increases

### Expected NewOrg Results
- Same test classes will be deployed
- Same test data creation strategy
- Expected coverage: 75.65% (same as OldOrg)
- **Risk:** Very low (tests proven in OldOrg production)

---

## Rollback Plan

### If Code Deployment Fails

**Scenario 1: Test Coverage Below 75%**
1. Review specific uncovered lines in error message
2. Add test methods to cover those lines
3. Redeploy with updated tests

**Scenario 2: Compilation Errors**
1. Check error messages for field references
2. Verify Collection_Date__c field doesn't exist yet (expected)
3. Deploy field first if needed (unusual but possible)

**Scenario 3: Deployment Timeout**
1. Reduce scope: Deploy one class at a time
2. Start with RLCSChargeService (smallest)
3. Then rlcsJobService
4. Then RLCSCreditInvoiceAction

### If Field Deployment Fails

**Scenario: Field Creation Error**
1. Check field already exists (use Object Manager)
2. Verify no naming conflicts
3. Manually create field via Setup UI if CLI fails

### If Post-Deployment Issues

**Issue: Collection_Date__c Not Populating**
1. Check field exists: `sf data query --query "DESCRIBE RLCS_Charge__c" -o NewOrg`
2. Check code deployed correctly (review in Setup → Apex Classes)
3. Verify Job has Collected_Date__c value
4. Check debug logs for errors

**Issue: Description__c Empty**
1. Verify Job has Waste_Type__c, Product_Name__c, or EWC__c values
2. Check buildChargeDescription() method exists in deployed code
3. Review debug logs

**Issue: Performance Problems**
1. Check SOQL query limits in debug logs
2. Verify code using new signature (not old inline query)
3. Review governor limit warnings

**Complete Rollback (Last Resort):**
```bash
# Restore previous code version
# Note: Field cannot be deleted once created (Salesforce limitation)
# But can be hidden from page layouts and removed from code references

# If needed, redeploy old code version:
sf project deploy start \
  -m "ApexClass:RLCSChargeService,ApexClass:rlcsJobService,ApexClass:RLCSCreditInvoiceAction" \
  --source-dir [backup directory with old code] \
  -o NewOrg
```

**Note:** Collection_Date__c field cannot be deleted, but:
- Remove from page layouts
- Remove from SOQL queries (if rolling back code)
- Hide from profiles/permission sets
- Field data will remain but won't be visible/used

---

## Dependencies & Prerequisites

### Must Be Deployed First
1. ✅ None (this is a standalone scenario)
   - **Exception:** If deploying transport-charges separately, deploy that first

### Depends On This Scenario
1. None currently identified

### Shared Components
- **rlcsJobService.cls** - Also used by:
  - transport-charges scenario (PRIMARY CONFLICT)
  - Any other job processing scenarios

**Resolution:** Deploy transport-charges first, then cs-invoicing

---

## Success Criteria

### Code Deployment Success
- ✅ All 5 Apex classes deployed without errors
- ✅ Test coverage ≥ 75% (target: 75.65%)
- ✅ All test methods pass
- ✅ No compilation errors
- ✅ No deployment warnings (acceptable: governor limit warnings if minor)

### Field Deployment Success
- ✅ Collection_Date__c field created
- ✅ Field queryable via SOQL (after cache refresh)
- ✅ Field visible in Object Manager
- ✅ Field accessible to all profiles (via Field-Level Security)

### Functional Testing Success
- ✅ New RLCS charges have Collection_Date__c populated (from Job.Collected_Date__c)
- ✅ New RLCS charges have Description__c populated (formatted string)
- ✅ Description format: "Waste Type: X, Product: Y, EWC: Z"
- ✅ Empty fields omitted from description (no "Waste Type: , Product: ")
- ✅ Credit charges (RLCSCreditInvoiceAction) work correctly
- ✅ Invoice filtering by "Raised Between" works

### Performance Testing Success
- ✅ No inline SOQL queries in createAutoJobCharge()
- ✅ SOQL query count reduced (compared to old version)
- ✅ No governor limit errors during batch job processing
- ✅ Charge creation time comparable or faster than before

---

## Timeline Estimate

| Phase | Task | Estimated Time | Dependencies |
|-------|------|----------------|--------------|
| **Prep** | Review OldOrg code | 30 minutes | None |
| **Prep** | Backup NewOrg current code | 15 minutes | None |
| **Deploy** | Deploy Apex classes + tests | 5-10 minutes | Code review complete |
| **Verify** | Verify code deployment | 10 minutes | Deployment complete |
| **Deploy** | Deploy Collection_Date__c field | 2 minutes | Code deployed |
| **Wait** | API cache refresh | 5-10 minutes | Field deployed |
| **Verify** | Verify field deployment | 5 minutes | Cache refreshed |
| **Test** | Create test charges | 15 minutes | Field verified |
| **Test** | Validate data population | 10 minutes | Test charges created |
| **Test** | Performance testing | 15 minutes | Functional tests pass |
| **Docs** | Update migration docs | 10 minutes | All testing complete |
| **TOTAL** | | **1.5 - 2 hours** | |

**Recommended Time Block:** 2-3 hours (includes buffer for issues)

---

## Post-Deployment Tasks

### Immediate (Same Day)
1. ✅ Monitor debug logs for errors
2. ✅ Verify new charges created today have correct data
3. ✅ Check with CS Invoicing team for any issues
4. ✅ Update migration tracking documents

### Short-Term (1 Week)
1. ⏸️ Update PDF invoice template to display Collection_Date__c
   - Requires Google Doc edit permission
   - Add merge field `<<Collection_Date__c>>`
   - Test PDF generation

### Long-Term (1 Month)
1. Monitor performance metrics
2. Gather feedback from CS Invoicing team
3. Consider removing Date__c field if Collection_Date__c fully replaces it
4. Document any edge cases discovered

---

## Contact Information

**Deployment Owner:** John Shintu
**OldOrg Deploy IDs:**
- Code: 0AfSj000000yGqHKAU (2025-10-10)
- Field: 0AfSj000000yeq1KAA (2025-10-13)
**Source Documentation:** CS_INVOICING_DATE_DESCRIPTION_FIELDS.md

---

**NewOrg Gap Analysis Generated:** 2025-10-23
**Analysis Confidence:** HIGH (line-by-line code verification completed)
**Ready for Deployment:** ⚠️ **YES** (after transport-charges deployed)
