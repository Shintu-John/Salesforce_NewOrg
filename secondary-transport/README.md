# Secondary Transport: NewOrg Gap Analysis & Migration Plan

## Gap Analysis Summary

**Analysis Date:** 2025-10-23
**Scenario:** secondary-transport (Priority #8)
**Status:** 🚨 **MISSING - NOT DEPLOYED TO NEWORG (Both Phases)**

### Critical Findings

| Component | OldOrg | NewOrg | Gap | Status |
|-----------|--------|--------|-----|--------|
| **rlcsJobService.cls** | 819 lines | 575 lines | -244 lines (29.8% missing) | ❌ SEVERELY OUTDATED |
| **RLCSJobAATFBatchProcessor.cls** | 325 lines | 293 lines | -32 lines (9.8% missing) | ❌ MISSING Phase 2 |
| **RLCSJobAATFController.cls** | 621 lines | 589 lines | -32 lines (5.2% missing) | ❌ MISSING Phase 2 |
| **iParserio_ICER_ReportCsvBatch.cls** | 149 lines | 139 lines | -10 lines (6.7% missing) | ❌ MISSING Phase 2 |
| **OrderItem Fields** | 3 fields created | ❓ Unknown | Fields may not exist | ❌ NEED VERIFICATION |
| **Validation Rule** | Created | ❓ Unknown | Rule may not exist | ❌ NEED VERIFICATION |
| **Picklist Value** | "Secondary Transport" | ❓ Unknown | Value may not exist | ❌ NEED VERIFICATION |

### Impact Assessment

**Risk Level:** 🚨 **CRITICAL**

**Business Impact - Phase 1 (Secondary Transport):**
- ❌ Cannot create TWO transport charges per job (PRIMARY + SECONDARY)
- ❌ Jobs requiring multiple transport legs (customer → depot → AATF) only have ONE charge
- ❌ Revenue loss: Missing secondary transport charges
- ❌ Manual workarounds required

**Business Impact - Phase 2 (CSV Upload Fix):**
- ❌ CSV uploads create Jobs with NULL weight/units (columns 14-15 not mapped)
- ❌ Charges calculated as: NULL × rate = £0 → No charges created
- ❌ **Same issue that created 97 invalid Jobs in OldOrg** (May-July 2025, £19K-£29K impact)
- ❌ Manual data entry required for EVERY job created via CSV
- ❌ ICER Report uploads don't update Job-level fields (only breakdowns)
- ❌ No automatic charge recalculation

**Technical Impact:**
- ❌ NewOrg has Oct 10 version of rlcsJobService (missing transport-charges fixes too)
- ❌ 244 lines missing from rlcsJobService (secondary transport + transport-charges)
- ❌ CSV upload bug active in NewOrg (will create invalid Jobs immediately on go-live)
- ❌ ICER Report upload incomplete (won't trigger charge recalculation)

---

## Detailed Gap Analysis

### 1. rlcsJobService.cls - 244 Lines Missing

**NewOrg Version:** 575 lines (Oct 10, 2025)
**OldOrg Version:** 819 lines (Oct 15, 2025)
**Gap:** 244 lines (29.8%)

**Missing Features:**
1. **Secondary Transport Logic** (Phase 1 - Oct 7):
   - Lines 424-467 in OldOrg (44 lines)
   - Creates SECONDARY transport charge when Order Product has Secondary_Transport_Charge__c = true
   - Supports Per Tonne, Per Unit, Per Load calculation methods
   - Optional different haulier via Secondary_Haulier__c field

2. **Transport Charges Fixes** (transport-charges scenario - Oct 15):
   - ~200 lines of transport-charges scenario fixes
   - **Note:** This file is shared with transport-charges scenario

**Verification:**
```bash
# Check for secondary transport logic
grep -n "SECONDARY_TRANSPORT\|secondaryTransportCharge" \
  /tmp/Salesforce_NewOrg/secondary-transport/code/classes/rlcsJobService.cls
# Result: NOT FOUND ❌
```

**Missing Code Example (Lines 424-467 in OldOrg):**
```apex
// SECONDARY TRANSPORT CHARGE (NEW LOGIC)
if (job.Order_Product__r?.Secondary_Transport_Charge__c == true) {
    RLCS_Charge__c secondaryTransportCharge = jobChargesByKey.get(
        job.Id + '~' + RLCSChargeService.JOB_CHARGE_TYPE_SECONDARY_TRANSPORT
    );

    // Determine calculation method
    Decimal secondaryTransportAmount = 0;
    Decimal secondaryTransportRate = job.Order_Product__r?.Secondary_Transport_P_T__c ?? 0;

    if (job.Order_Product__r?.Secondary_Transport_Per_Tonne__c == true) {
        secondaryTransportAmount = (job.Material_Weight_Tonnes__c ?? 0) * secondaryTransportRate;
    } else if (job.Order_Product__r?.Secondary_Transport_Per_Unit__c == true) {
        secondaryTransportAmount = (job.Unit_Count__c ?? 0) * secondaryTransportRate;
    } else {
        secondaryTransportAmount = 1 * secondaryTransportRate; // Per Load
    }
    // ... (charge creation logic)
}
```

### 2. RLCSJobAATFBatchProcessor.cls - 32 Lines Missing

**NewOrg Version:** 293 lines
**OldOrg Version:** 325 lines
**Gap:** 32 lines (9.8%)

**Missing Feature:** CSV Column Mapping (Phase 2 - Oct 8)
- Lines 130-183 in OldOrg
- Maps CSV columns 14-15 to Job.Material_Weight_Tonnes__c and Job.Unit_Count__c
- **Critical bug fix:** Without this, Jobs created via CSV have NULL weight/units

**Verification:**
```bash
grep -n "weeeTonnesIndex\|Material_Weight_Tonnes__c" \
  /tmp/Salesforce_NewOrg/secondary-transport/code/classes/RLCSJobAATFBatchProcessor.cls
# Result: NOT FOUND ❌
```

**Missing Code:**
```apex
// Define column indices
Integer weeeTonnesIndex = 13; // 14th column (0-based) - "WEEE Tonnes"
Integer weeeUnitsIndex = 14;  // 15th column (0-based) - "WEEE Units"

// Parse and assign to Job fields
if (weeeTonnesIndex >= 0 && weeeTonnesIndex < row.size()) {
    String weightValue = row[weeeTonnesIndex].trim();
    if (String.isNotBlank(weightValue)) {
        try {
            job.Material_Weight_Tonnes__c = Decimal.valueOf(weightValue);
        } catch (Exception e) {
            System.debug('Error parsing WEEE Tonnes: ' + e.getMessage());
        }
    }
}
// ... (same for Unit_Count__c)
```

### 3. RLCSJobAATFController.cls - 32 Lines Missing

**NewOrg Version:** 589 lines
**OldOrg Version:** 621 lines
**Gap:** 32 lines (5.2%)

**Missing Feature:** Same CSV column mapping as BatchProcessor (Phase 2 - Oct 8)
- Lines 232-288 in OldOrg
- Mirrors the batch processor logic for UI-based CSV uploads
- Same critical bug: Jobs created via UI CSV upload have NULL weight/units

### 4. iParserio_ICER_ReportCsvBatch.cls - 10 Lines Missing

**NewOrg Version:** 139 lines
**OldOrg Version:** 149 lines
**Gap:** 10 lines (6.7%)

**Missing Feature:** Job-Level Field Updates (Phase 2 - Oct 8)
- Lines 113-120 in OldOrg
- Updates Job.Material_Weight_Tonnes__c and Job.Unit_Count__c from ICER Report
- Currently only creates Material_Category_Breakdown__c (child records)
- Missing parent field updates means no trigger recalculation

**Verification:**
```bash
grep -n "ALSO populate Job-level fields\|job.Material_Weight_Tonnes__c" \
  /tmp/Salesforce_NewOrg/secondary-transport/code/classes/iParserio_ICER_ReportCsvBatch.cls
# Result: NOT FOUND ❌
```

**Missing Code:**
```apex
// ALSO populate Job-level fields for Material_Weight_Tonnes__c and Unit_Count__c
if(row.containsKey(MATERIAL_WEIGHT_TONNES) &&
   String.isNotBlank(row.get(MATERIAL_WEIGHT_TONNES))){
    job.Material_Weight_Tonnes__c = iParserio_Helper.convertToDecimal(
        row.get(MATERIAL_WEIGHT_TONNES)
    );
}

if(row.containsKey(UNIT_COUNT) && String.isNotBlank(row.get(UNIT_COUNT))){
    job.Unit_Count__c = iParserio_Helper.convertToInteger(row.get(UNIT_COUNT));
}

jobsToUpdate.put(job.Id, job);
```

---

## Migration Plan

### Deployment Order

**🚨 CRITICAL DEPENDENCIES:**

This scenario has complex dependencies:

1. **rlcsJobService.cls is shared with:**
   - transport-charges scenario (CRITICAL - 3 bugs fixed Oct 14-15)
   - cs-invoicing scenario (Medium - date/description fields Oct 10-13)
   - secondary-transport scenario (this one - Oct 7-8)

2. **Recommended Deployment Order:**
   ```
   Step 1: Deploy transport-charges (brings rlcsJobService to 819 lines)
           └─> Fixes £1.7M financial risk issues

   Step 2: Deploy cs-invoicing (modifies rlcsJobService further if needed)
           └─> Adds date/description auto-population

   Step 3: Deploy secondary-transport (this scenario)
           └─> Adds secondary transport charges + CSV fix
   ```

3. **Current rlcsJobService Version in NewOrg:**
   - 575 lines (Oct 10, 2025)
   - Missing ALL THREE scenario changes
   - Must deploy in order to avoid conflicts

### Phase 1 Deployment: Secondary Transport Charges

**Components to Deploy:**
1. OrderItem.Secondary_Transport_Per_Tonne__c (field)
2. OrderItem.Secondary_Transport_Per_Unit__c (field)
3. OrderItem.Secondary_Haulier__c (field)
4. RLCS_Charge__c.Charge_Type__c picklist value: "Secondary Transport"
5. Secondary_Transport_Only_One_Method (validation rule)
6. rlcsJobService.cls (819 lines - includes all scenarios)
7. RLCSChargeService.cls (if not already deployed)
8. Test classes

**CLI Commands:**

✅ **Step 1.1: Deploy Custom Fields**
```bash
sf project deploy start \
  -m "CustomField:OrderItem.Secondary_Transport_Per_Tonne__c,CustomField:OrderItem.Secondary_Transport_Per_Unit__c,CustomField:OrderItem.Secondary_Haulier__c" \
  -o NewOrg
```

✅ **Step 1.2: Deploy Picklist Value** (⚠️ Manual UI)
- Navigate to: Setup → Object Manager → RLCS_Charge__c → Fields & Relationships → Charge_Type__c
- Add picklist value: "Secondary Transport"

✅ **Step 1.3: Deploy Validation Rule**
```bash
sf project deploy start \
  -m "ValidationRule:OrderItem.Secondary_Transport_Only_One_Method" \
  -o NewOrg
```

✅ **Step 1.4: Deploy Apex Classes**
```bash
sf project deploy start \
  -m "ApexClass:rlcsJobService,ApexClass:RLCSChargeService" \
  -o NewOrg \
  --test-level RunSpecifiedTests \
  --tests "rlcsJobServiceTest" --tests "RLCSChargeServiceTest"
```

**Expected Results:**
- OrderItem fields created
- Validation rule active
- Picklist value available
- Apex classes deployed with 75%+ coverage
- Jobs can now create TWO transport charges

### Phase 2 Deployment: CSV Upload Fix

**Components to Deploy:**
1. RLCSJobAATFBatchProcessor.cls (325 lines)
2. RLCSJobAATFController.cls (621 lines)
3. iParserio_ICER_ReportCsvBatch.cls (149 lines)

**CLI Commands:**

✅ **Step 2.1: Deploy CSV Upload Classes**
```bash
sf project deploy start \
  -m "ApexClass:RLCSJobAATFBatchProcessor,ApexClass:RLCSJobAATFController,ApexClass:iParserio_ICER_ReportCsvBatch" \
  -o NewOrg \
  --test-level RunLocalTests
```

**Expected Results:**
- CSV uploads populate Job.Material_Weight_Tonnes__c and Job.Unit_Count__c
- ICER Report uploads update Job-level fields AND create breakdowns
- Trigger recalculates charges automatically
- No more NULL weight/units issues

---

## Verification Steps

### Post-Phase 1 Verification

**1. Verify Fields Created:**
```bash
sf data query --query "SELECT Id, DeveloperName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'OrderItem' AND DeveloperName IN ('Secondary_Transport_Per_Tonne__c', 'Secondary_Transport_Per_Unit__c', 'Secondary_Haulier__c')" -o NewOrg --use-tooling-api
```

**2. Verify Picklist Value:**
```bash
sf data query --query "SELECT Id, Picklist, Label, Value FROM PicklistValue WHERE EntityParticleId IN (SELECT Id FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'RLCS_Charge__c' AND DeveloperName = 'Charge_Type__c')" -o NewOrg --use-tooling-api | grep "Secondary Transport"
```

**3. Test Secondary Transport Creation:**
- Create test Order Product with:
  - Secondary_Transport_Charge__c = true
  - Secondary_Transport_Per_Tonne__c = true
  - Secondary_Transport_P_T__c = £50.00
- Create test Job with:
  - Material_Weight_Tonnes__c = 2.5
  - Link to above Order Product
- Verify: TWO charges created (Primary + Secondary)
- Expected Secondary charge: 2.5 × £50 = £125.00

### Post-Phase 2 Verification

**1. Test CSV Upload (RLCS Job Creator):**
- Prepare CSV with columns 14-15 populated:
  - Column 14: "WEEE Tonnes" = 1.5
  - Column 15: "WEEE Units" = 100
- Upload via RLCS Job Creator
- Query created Job:
  ```bash
  sf data query --query "SELECT Id, Name, Material_Weight_Tonnes__c, Unit_Count__c FROM RLCS_Job__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1" -o NewOrg
  ```
- Expected: Material_Weight_Tonnes__c = 1.5, Unit_Count__c = 100 ✅

**2. Test ICER Report Upload:**
- Generate ICER Report for test Job
- Upload ICER Report
- Verify Job fields updated:
  ```bash
  sf data query --query "SELECT Id, Material_Weight_Tonnes__c, Unit_Count__c FROM RLCS_Job__c WHERE Id = '[JobId]'" -o NewOrg
  ```
- Verify Material_Category_Breakdown__c created
- Verify charges recalculated (check LastModifiedDate on RLCS_Charge__c)

---

## Rollback Plan

### If Phase 1 Fails

**Scenario: Apex Deployment Fails**
1. Check test coverage in error message
2. Review specific failing tests
3. Do NOT rollback fields/picklist (can't delete, will orphan data)
4. Fix test issues and redeploy

**Scenario: Validation Rule Too Restrictive**
1. Deactivate validation rule via UI
2. Review existing OrderItem records
3. Fix data conflicts
4. Reactivate validation rule

### If Phase 2 Fails

**Scenario: CSV Upload Issues**
1. Check batch processor logs
2. Verify CSV format matches expected structure
3. Test with small CSV (5-10 rows) first
4. Review column indices (0-based vs 1-based)

**Scenario: ICER Upload Issues**
1. Check ICER Report format
2. Verify MATERIAL_WEIGHT_TONNES and UNIT_COUNT column names
3. Review iParserio_Helper conversion methods
4. Check for null/invalid data

---

## Dependencies & Prerequisites

### Must Be Deployed First
1. ✅ **transport-charges** (CRITICAL - brings rlcsJobService to 819 lines)
2. ✅ **cs-invoicing** (Medium - if deploying in order)

### Existing Components Required
- RLCS_Job__c.Material_Weight_Tonnes__c (should exist)
- RLCS_Job__c.Unit_Count__c (should exist)
- OrderItem.Secondary_Transport_Charge__c (already exists per documentation)
- OrderItem.Secondary_Transport_P_T__c (already exists per documentation)
- RLCS_Charge__c object (should exist)
- Material_Category_Breakdown__c object (should exist)

---

## Success Criteria

### Phase 1 Success
- ✅ 3 OrderItem fields created and queryable
- ✅ "Secondary Transport" picklist value available
- ✅ Validation rule active
- ✅ Apex classes deployed (75%+ coverage)
- ✅ Test Job creates TWO transport charges
- ✅ Secondary charge amount calculated correctly (Per Tonne/Unit/Load)
- ✅ Optional different haulier works

### Phase 2 Success
- ✅ CSV uploads populate Material_Weight_Tonnes__c and Unit_Count__c
- ✅ Jobs created via CSV have correct weight/units immediately
- ✅ Charges calculated correctly: weight × rate ≠ £0
- ✅ ICER Report uploads update Job-level fields
- ✅ Material_Category_Breakdown__c still created
- ✅ Trigger recalculates charges after ICER upload
- ✅ No NULL weight/units issues going forward

---

## Timeline Estimate

| Phase | Task | Estimated Time | Dependencies |
|-------|------|----------------|--------------|
| **Phase 1** | Deploy custom fields | 5 minutes | None |
| **Phase 1** | Add picklist value (Manual UI) | 2 minutes | None |
| **Phase 1** | Deploy validation rule | 2 minutes | Fields exist |
| **Phase 1** | Deploy Apex classes | 10-15 minutes | transport-charges deployed |
| **Phase 1** | Verify + test | 15 minutes | All deployed |
| **Phase 2** | Deploy CSV upload classes | 15-20 minutes | Phase 1 complete |
| **Phase 2** | Test CSV upload | 10 minutes | Classes deployed |
| **Phase 2** | Test ICER upload | 10 minutes | Classes deployed |
| **Docs** | Update migration docs | 5 minutes | All testing complete |
| **TOTAL** | | **1.5 - 2 hours** | |

---

## Known Risks

### Risk 1: Shared rlcsJobService.cls
**Risk:** Three scenarios modify same file (transport-charges, cs-invoicing, secondary-transport)
**Mitigation:** Deploy in correct order, test thoroughly after each
**Priority:** 🚨 CRITICAL

### Risk 2: Existing Data with NULL Weight
**Risk:** NewOrg may already have Jobs with NULL weight/units from CSV uploads
**Mitigation:**
- Query before deployment: `SELECT COUNT(Id) FROM RLCS_Job__c WHERE Transport_Per_Tonne__c = true AND Material_Weight_Tonnes__c = null`
- Review and fix data before go-live
**Priority:** 🟡 MEDIUM

### Risk 3: CSV Format Changes
**Risk:** CSV format may have changed since Oct 2025
**Mitigation:** Verify CSV column positions (14-15) before deployment
**Priority:** 🟢 LOW

---

**NewOrg Gap Analysis Generated:** 2025-10-23
**Analysis Confidence:** HIGH (line-by-line code verification completed)
**Ready for Deployment:** ⚠️ **YES** (after transport-charges and cs-invoicing deployed)
