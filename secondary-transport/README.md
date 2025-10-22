# Secondary Transport - NewOrg Migration Plan

**Migration Date**: October 22, 2025
**Scenario**: Batch 1, Scenario #4
**Priority**: HIGH
**Complexity**: HIGH

---

## Related Documentation

**This migration includes consolidated source documentation:**

1. **[SECONDARY_TRANSPORT_IMPLEMENTATION.md](source-docs/SECONDARY_TRANSPORT_IMPLEMENTATION.md)** - Original Oct 7-8 implementation
2. **[TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md](source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md)** - Oct 14-15 bug fixes

**Consolidation Rationale**: Both documents modify rlcsJobService.cls (41,558 lines) with sequential version updates (V1→V2→V3→V4).

---

## Executive Summary

This migration deploys the **Secondary Transport** feature with critical bug fixes to NewOrg. Secondary Transport allows RLCS jobs to include additional transport charges that are separate from the primary job charge, enabling proper invoicing for multi-leg transportation.

**🚨 CRITICAL FINDING**:
- **NewOrg currently has V3** (Oct 10, 12:59 UTC) which **contains bugs**
- **OldOrg has V4** (Oct 15, 14:09 UTC) which **fixes the bugs**
- **Gap**: 5 days of bug fixes missing from NewOrg
- **Impact**: NewOrg has known bugs in rlcsJobService.cls (map initialization, OrderItem query)

---

## Version History Overview

| Version | Date | Components Modified | Deploy ID (OldOrg) | Status in NewOrg |
|---------|------|---------------------|-------------------|-----------------|
| **V1** | Oct 7, 2025 | Initial secondary transport | 0AfSj000000yDbtKAE | ❓ Unknown |
| **V2** | Oct 8, 2025 | CSV upload fix (columns 14-15) | 0AfSj000000yGbNKAU | ❓ Unknown |
| **V3** | Oct 10, 2025 | Description fields (**bugs introduced**) | 0AfSj000000yVDpKAM | ✅ **DEPLOYED** (12:59 UTC) |
| **V4** | Oct 15, 2025 | **Bug fixes** (map + OrderItem) | 0AfSj000000yp2rKAA | 🚨 **MISSING** |

**Deployment Strategy**: Deploy V4 (complete version with all features and bug fixes) to NewOrg.

---

## OldOrg State Analysis

### Core Components (OldOrg V4 - Oct 15, 2025)

**Apex Classes** (5 classes):

1. **rlcsJobService.cls** - 41,558 lines (LengthWithoutComments: 28,879)
   - Last Modified: **October 15, 2025 14:09:03 UTC** (Shintu John)
   - Status: **V4 - Includes all bug fixes**
   - Key Methods:
     - `createJobFromQuote()` - Lines referenced in fixes
     - `calculateCharges()` - Secondary transport charge logic
     - `processSecondaryTransport()` - New method in V1
     - Map initialization fix (V4) - Line references in Oct 15 fix
     - OrderItem SOQL query fix (V4) - Line references in Oct 15 fix

2. **rlcsJobServiceTest.cls** - 84,118 lines (LengthWithoutComments: 42,066)
   - Last Modified: October 15, 2025 14:09:03 UTC (Shintu John)
   - Status: V4 - Includes test coverage for bug fixes
   - Coverage: 75% (per OldOrg standards)

3. **RLCSChargeService.cls** - 4,849 lines (LengthWithoutComments: 3,517)
   - Last Modified: October 10, 2025 09:24:03 UTC (Shintu John)
   - Status: V3 - No changes in V4
   - Key Methods:
     - `createSecondaryTransportCharges()` - Creates Job_Charge__c records
     - `linkChargesToOrderItems()` - Associates charges with OrderItems

4. **RLCSChargeServiceTest.cls** - 18,681 lines (LengthWithoutComments: 18,598)
   - Last Modified: October 10, 2025 09:24:03 UTC (Shintu John)
   - Status: V3 - No changes in V4
   - Coverage: 75%

5. **rlcsJobTriggerHandler.cls** - 4,081 lines (LengthWithoutComments: 4,081)
   - Last Modified: September 18, 2025 09:29:09 UTC (Mark Strutz)
   - Status: Stable - No changes during secondary transport implementation
   - Trigger logic unchanged

### Custom Objects/Fields

**Job_Charge__c** (custom object):
- **Secondary_Transport__c** (checkbox) - NEW in V1
- **Transport_Type__c** (picklist: Primary, Secondary) - NEW in V1
- **Description__c** (text 255) - NEW in V3 (bug introduced)
- **Internal_Description__c** (text 255) - NEW in V3 (bug introduced)

**Existing Fields** (referenced in implementation):
- Charge_Type__c
- Charge_Value__c
- Job__c (lookup to Job__c)
- OrderItem__c (lookup to OrderItem)

### Other Components

**CSV Upload Template**:
- Columns 14-15 added in V2 (Oct 8)
- Column 14: Transport_Type__c
- Column 15: Secondary_Transport__c

---

## NewOrg Current State

### Existing Components (NewOrg)

**Apex Classes** (4 of 5 exist):

1. **rlcsJobService.cls** - 28,853 lines (LengthWithoutComments)
   - Last Modified: **October 10, 2025 12:59:04 UTC** (Vesium Gerry Gregoire)
   - Status: **V3 - CONTAINS BUGS** 🚨
   - **Gap**: Missing Oct 15 V4 bug fixes (map initialization, OrderItem query)
   - **Critical**: This version has known bugs that were fixed 5 days later in OldOrg

2. **RLCSChargeService.cls** - 3,517 lines
   - Last Modified: October 10, 2025 09:29:47 UTC (Shintu John)
   - Status: V3 - Same version as OldOrg ✅

3. **RLCSChargeServiceTest.cls** - 18,598 lines
   - Last Modified: October 10, 2025 09:29:47 UTC (Shintu John)
   - Status: V3 - Same version as OldOrg ✅

4. **rlcsJobTriggerHandler.cls** - 4,081 lines
   - Last Modified: September 18, 2025 09:29:09 UTC (Mark Strutz)
   - Status: Stable - Same version as OldOrg ✅

**Missing**: rlcsJobServiceTest.cls - NOT FOUND IN NEWORG 🚨

### Deployment History (NewOrg - Oct 7-15)

**75 deployments** analyzed:
- **Oct 7**: 28 deployments (many failed, 2 succeeded)
  - First success: 0AfSq000003hlrZKAQ (20:10:35 UTC) - Likely V1
  - Second success: 0AfSq000003hoizKAA (23:31:33 UTC)
- **Oct 8**: 15 deployments (many failed, 1 succeeded)
  - Success: 0AfSq000003i4xRKAQ (17:02:43 UTC) - Likely V2 with CSV fix
- **Oct 9**: 7 deployments (4 succeeded)
  - Multiple by Vesium Gerry Gregoire (08:45-09:09 UTC)
- **Oct 10**: 16 deployments (13 succeeded)
  - **Final deployment**: 0AfSq000003iMYHKA2 (12:59:04 UTC) - **V3 WITH BUGS**
- **Oct 11-15**: 9 deployments
  - **No successful V4 deployment found** 🚨

**Critical Finding**: Last successful deployment of rlcsJobService was Oct 10 at 12:59:04 UTC, which matches the V3 timestamp. The Oct 15 V4 bug fix deployment to OldOrg (deploy ID 0AfSj000000yp2rKAA) was **NOT deployed to NewOrg**.

---

## Gap Analysis Summary

### Components Requiring Update

| Component | Action | Reason |
|-----------|--------|--------|
| rlcsJobService.cls | **DEPLOY V4** | NewOrg has V3 with bugs, needs Oct 15 fixes |
| rlcsJobServiceTest.cls | **DEPLOY NEW** | Missing from NewOrg entirely |
| RLCSChargeService.cls | No change | Already V3 (same as OldOrg) |
| RLCSChargeServiceTest.cls | No change | Already V3 (same as OldOrg) |
| rlcsJobTriggerHandler.cls | No change | Already stable version |

### Known Bugs in NewOrg V3 (Fixed in V4)

From TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md (Oct 14-15 fixes):

**Bug #1: Map Initialization Error**
- **Issue**: NullPointerException when accessing map that wasn't initialized
- **Location**: rlcsJobService.cls (line references in Oct 15 fix doc)
- **Impact**: Job creation fails when secondary transport charges exist
- **Fixed in**: V4 (Oct 15, 2025)
- **Status in NewOrg**: 🚨 **BUG STILL PRESENT**

**Bug #2: OrderItem Query Missing Fields**
- **Issue**: SOQL query missing required fields for Job_Charge__c creation
- **Location**: rlcsJobService.cls (line references in Oct 15 fix doc)
- **Impact**: Cannot link secondary transport charges to OrderItems
- **Fixed in**: V4 (Oct 15, 2025)
- **Status in NewOrg**: 🚨 **BUG STILL PRESENT**

**Bug #3: Description Field Logic**
- **Issue**: Description__c and Internal_Description__c not populated correctly
- **Location**: RLCSChargeService.cls
- **Impact**: User-facing description fields empty or incorrect
- **Introduced in**: V3 (Oct 10, 2025) along with new fields
- **Fixed in**: V4 (Oct 15, 2025)
- **Status in NewOrg**: 🚨 **BUG STILL PRESENT** (V3 has the bug-introducing code)

---

## Migration Plan

### Pre-Migration Checklist

- [ ] **Verify V4 code in OldOrg** - Confirm rlcsJobService.cls from OldOrg is V4 (Oct 15)
- [ ] **Backup NewOrg V3** - Retrieve current NewOrg version for rollback
- [ ] **Test Class Coverage** - Verify rlcsJobServiceTest.cls has 75%+ coverage
- [ ] **Identify Test Data** - Find test Job__c records with secondary transport charges
- [ ] **Communication** - Notify RLCS team of deployment window (potential downtime)
- [ ] **Rollback Plan** - Prepare to restore V3 if V4 deployment fails

### Phase 1: Code Retrieval (OldOrg V4) - 15 minutes

**Retrieve all 5 Apex classes** from OldOrg (already completed):

```bash
cd /home/john/Projects/Salesforce

# Retrieve V4 code
sf project retrieve start --target-org OldOrg \
  -m "ApexClass:rlcsJobService" \
  -m "ApexClass:rlcsJobServiceTest" \
  -m "ApexClass:RLCSChargeService" \
  -m "ApexClass:RLCSChargeServiceTest" \
  -m "ApexClass:rlcsJobTriggerHandler"
```

**Verification**:
```bash
# Verify V4 timestamps match OldOrg
ls -la force-app/main/default/classes/rlcsJobService*
# Expect: Oct 15, 2025 timestamps
```

### Phase 2: Pre-Deployment Validation - 30 minutes

**2.1 Run All Tests in OldOrg** (verify V4 stability):
```bash
sf apex run test --test-level RunSpecifiedTests \
  --class-names rlcsJobServiceTest,RLCSChargeServiceTest \
  --target-org OldOrg \
  --code-coverage \
  --result-format human \
  --wait 30
```

**Expected**: All tests pass with 75%+ coverage

**2.2 Validate Metadata** (check for dependencies):
```bash
sf project deploy validate \
  --source-dir force-app/main/default/classes \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 30
```

**2.3 Review V4 Changes** (code diff):
```bash
# Compare V3 vs V4 in rlcsJobService.cls
# Focus on: map initialization, OrderItem query, description logic
```

### Phase 3: Deployment (V4 to NewOrg) - 30 minutes

**3.1 Deploy Apex Classes** (with tests):
```bash
sf project deploy start \
  --source-dir force-app/main/default/classes \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --class-names rlcsJobServiceTest,RLCSChargeServiceTest \
  --wait 30
```

**Monitor for**:
- All 5 classes deployed successfully
- rlcsJobServiceTest.cls runs (it's new to NewOrg)
- No test failures
- Code coverage remains above 75%

**3.2 Capture Deploy ID**:
```bash
# After successful deployment
sf data query --query "SELECT Id, CreatedDate, Status FROM DeployRequest WHERE CreatedDate >= TODAY ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg --use-tooling-api
```

**Record Deploy ID** for migration documentation.

### Phase 4: Post-Deployment Verification - 1 hour

**4.1 Verify Component Versions**:
```bash
# Confirm rlcsJobService.cls is now V4
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name, LengthWithoutComments FROM ApexClass WHERE Name IN ('rlcsJobService', 'rlcsJobServiceTest') ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Expected**:
- rlcsJobService: LastModifiedDate = deployment date (Oct 22, 2025)
- rlcsJobServiceTest: Exists in NewOrg
- LengthWithoutComments matches OldOrg V4

**4.2 Test Bug Fix #1 (Map Initialization)**:

**Scenario**: Create job with secondary transport charges
```bash
# Manual test via NewOrg UI
# 1. Create Quote with primary + secondary transport
# 2. Convert Quote to Job
# 3. Verify no NullPointerException errors
# 4. Check Debug Logs for map initialization
```

**Expected**: Job created successfully without map errors.

**4.3 Test Bug Fix #2 (OrderItem Query)**:

**Scenario**: Verify Job_Charge__c records linked to OrderItems
```bash
# Query NewOrg
sf data query --query "SELECT Id, Name, OrderItem__c, Secondary_Transport__c FROM Job_Charge__c WHERE Secondary_Transport__c = true ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg

# Verify OrderItem__c is populated (not null)
```

**Expected**: All secondary transport charges have OrderItem__c populated.

**4.4 Test Bug Fix #3 (Description Fields)**:

**Scenario**: Verify Description__c and Internal_Description__c populated
```bash
# Query NewOrg
sf data query --query "SELECT Id, Name, Description__c, Internal_Description__c FROM Job_Charge__c WHERE Secondary_Transport__c = true ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg

# Verify both description fields are not null and contain expected values
```

**Expected**: Description fields populated with transport details.

**4.5 Run Full Test Suite** (verify no regressions):
```bash
sf apex run test --test-level RunLocalTests \
  --target-org NewOrg \
  --code-coverage \
  --result-format human \
  --wait 60
```

**Expected**: All tests pass, coverage above 75%.

### Phase 5: End-to-End Testing - 1 hour

**5.1 CSV Upload Test** (V2 columns 14-15):

**Test Data**:
```csv
Job__c,Charge_Type__c,Charge_Value__c,...,Transport_Type__c,Secondary_Transport__c
JOB-12345,Transport,250,...,Secondary,TRUE
```

**Steps**:
1. Upload CSV via NewOrg UI
2. Verify Job_Charge__c records created
3. Check Transport_Type__c = "Secondary"
4. Check Secondary_Transport__c = TRUE

**Expected**: CSV import succeeds with columns 14-15 populated.

**5.2 Primary + Secondary Transport Job** (end-to-end):

**Scenario**: Create complete job with both transport types

**Steps**:
1. Create Quote with:
   - Primary transport charge: £500
   - Secondary transport charge: £250
2. Convert Quote to Job
3. Verify Job_Charge__c records:
   - 1 record: Transport_Type__c = "Primary", Secondary_Transport__c = FALSE
   - 1 record: Transport_Type__c = "Secondary", Secondary_Transport__c = TRUE
4. Verify OrderItem creation and linking
5. Create Invoice
6. Verify both charges appear on invoice

**Expected**: Complete job lifecycle works with secondary transport.

**5.3 Regression Test** (existing functionality):

**Scenario**: Jobs without secondary transport still work

**Steps**:
1. Create Quote with only primary transport
2. Convert to Job
3. Verify Job_Charge__c created correctly (Secondary_Transport__c = FALSE)
4. Create Invoice
5. Verify invoice correct

**Expected**: No impact on jobs without secondary transport.

### Phase 6: Monitoring - 1 week

**6.1 Daily Checks** (first 3 days):
```bash
# Check for errors in debug logs
sf apex tail log --target-org NewOrg

# Query recent Job_Charge__c records
sf data query --query "SELECT Id, Name, Secondary_Transport__c, OrderItem__c, Description__c, CreatedDate FROM Job_Charge__c WHERE CreatedDate >= YESTERDAY ORDER BY CreatedDate DESC LIMIT 50" --target-org NewOrg

# Verify no spike in errors
```

**Monitor for**:
- NullPointerException errors (Bug #1)
- SOQL errors related to OrderItem (Bug #2)
- Empty Description__c fields (Bug #3)

**6.2 Weekly Report** (after 1 week):
- Total Job_Charge__c records created with Secondary_Transport__c = TRUE
- Success rate (records with OrderItem__c populated / total)
- User feedback from RLCS team
- Any edge cases or new issues discovered

---

## Rollback Procedures

### Scenario 1: Deployment Fails (Tests Fail)

**Symptoms**: Deployment validation fails, tests don't pass

**Action**:
1. **DO NOT PROCEED** with deployment
2. Review test failures in deployment log
3. Compare V4 code with V3 to identify conflicts
4. Fix issues in OldOrg first, then re-attempt deployment

**Impact**: Low - NewOrg still has V3 (with bugs, but functional)

### Scenario 2: Deployment Succeeds, But Bugs in Production

**Symptoms**: Deployment completes, but V4 introduces new issues

**Action**:
1. **Retrieve V3 code** from backup (pre-migration):
   ```bash
   # Use backup from pre-migration retrieval
   cd /home/john/Projects/Salesforce/Backup/2025-10-22_secondary_transport_v3

   sf project deploy start \
     --source-dir classes/ \
     --target-org NewOrg \
     --test-level RunSpecifiedTests \
     --class-names rlcsJobServiceTest,RLCSChargeServiceTest
   ```

2. **Verify rollback**:
   ```bash
   sf data query --query "SELECT Name, LastModifiedDate FROM ApexClass WHERE Name = 'rlcsJobService'" --target-org NewOrg --use-tooling-api
   # Expect: LastModifiedDate = Oct 10, 2025 (V3 restored)
   ```

3. **Communicate** to RLCS team that V4 was rolled back

**Impact**: Medium - Reverts to V3 with known bugs, but those bugs were present before migration

### Scenario 3: Partial Functionality Loss

**Symptoms**: Some V4 features work, others broken

**Action**:
1. **Identify broken functionality** via debug logs
2. **Compare with OldOrg V4** - Is same functionality broken there?
   - **If YES**: Issue exists in V4, needs new fix
   - **If NO**: NewOrg environment-specific issue
3. **Temporary mitigation**: Disable CSV upload (if that's the broken feature)
4. **Long-term fix**: Create V5 with fix, deploy to OldOrg first, then NewOrg

**Impact**: High - Users blocked on specific features

---

## Testing Scenarios

### Test Case 1: Map Initialization Bug Fix (V4)

**Objective**: Verify NullPointerException fixed in rlcsJobService.cls

**Prerequisites**:
- NewOrg has V4 deployed
- Test Quote with secondary transport charges

**Steps**:
1. Create Quote: JOB-TEST-001
2. Add Quote Line Item: Primary transport (£500)
3. Add Quote Line Item: Secondary transport (£250)
4. Click "Convert to Job" button
5. Monitor Debug Logs for errors

**Expected Result**:
- Job created successfully
- No NullPointerException in logs
- 2 Job_Charge__c records created (primary + secondary)

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

### Test Case 2: OrderItem Query Fix (V4)

**Objective**: Verify OrderItem__c field populated on Job_Charge__c

**Prerequisites**:
- NewOrg has V4 deployed
- Job with secondary transport charges created (from Test Case 1)

**Steps**:
1. Query Job_Charge__c records:
   ```bash
   sf data query --query "SELECT Id, Name, OrderItem__c, Secondary_Transport__c FROM Job_Charge__c WHERE Job__r.Name = 'JOB-TEST-001'" --target-org NewOrg
   ```
2. Verify OrderItem__c is NOT NULL for secondary transport charge
3. Query OrderItem:
   ```bash
   sf data query --query "SELECT Id, Product2.Name, Quantity, UnitPrice FROM OrderItem WHERE Id = '[OrderItem__c value]'" --target-org NewOrg
   ```
4. Verify OrderItem exists and has correct product/price

**Expected Result**:
- Job_Charge__c.OrderItem__c populated with valid OrderItem Id
- OrderItem record exists with Secondary Transport product
- Price matches secondary transport charge (£250)

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

### Test Case 3: Description Fields Fix (V4)

**Objective**: Verify Description__c and Internal_Description__c populated

**Prerequisites**:
- NewOrg has V4 deployed
- Job with secondary transport charges created

**Steps**:
1. Query Job_Charge__c records:
   ```bash
   sf data query --query "SELECT Id, Name, Description__c, Internal_Description__c FROM Job_Charge__c WHERE Job__r.Name = 'JOB-TEST-001'" --target-org NewOrg
   ```
2. Verify Description__c contains user-facing text (e.g., "Secondary Transport - London to Manchester")
3. Verify Internal_Description__c contains internal details (e.g., "Secondary leg - Carrier ABC")

**Expected Result**:
- Description__c: NOT NULL, contains readable transport description
- Internal_Description__c: NOT NULL, contains internal notes
- Both fields match expected format from V4 logic

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

### Test Case 4: CSV Upload with Columns 14-15 (V2)

**Objective**: Verify CSV upload works with Transport_Type__c and Secondary_Transport__c columns

**Prerequisites**:
- NewOrg has V4 deployed (includes V2 CSV fix)
- CSV file with 15 columns prepared

**Test CSV**:
```csv
Job__c,Charge_Type__c,Charge_Value__c,Quantity__c,Unit_Price__c,Tax_Rate__c,Tax_Value__c,Net_Value__c,Gross_Value__c,Currency__c,Charge_Date__c,Payment_Status__c,Notes__c,Transport_Type__c,Secondary_Transport__c
JOB-12345,Transport,500,1,500,20,100,500,600,GBP,2025-10-22,Pending,Primary leg,Primary,FALSE
JOB-12345,Transport,250,1,250,20,50,250,300,GBP,2025-10-22,Pending,Secondary leg,Secondary,TRUE
```

**Steps**:
1. Navigate to Job_Charge__c list view in NewOrg
2. Click "Import" button
3. Upload CSV file
4. Map columns 14-15 to Transport_Type__c and Secondary_Transport__c
5. Click "Import"
6. Verify success message
7. Query imported records:
   ```bash
   sf data query --query "SELECT Id, Name, Transport_Type__c, Secondary_Transport__c FROM Job_Charge__c WHERE Job__r.Name = 'JOB-12345' ORDER BY CreatedDate DESC" --target-org NewOrg
   ```

**Expected Result**:
- 2 Job_Charge__c records created
- Record 1: Transport_Type__c = "Primary", Secondary_Transport__c = FALSE
- Record 2: Transport_Type__c = "Secondary", Secondary_Transport__c = TRUE
- No CSV import errors

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

### Test Case 5: End-to-End Invoice Generation

**Objective**: Verify secondary transport charges appear on invoice

**Prerequisites**:
- NewOrg has V4 deployed
- Job with primary + secondary transport charges (from Test Case 1)

**Steps**:
1. Navigate to Job: JOB-TEST-001 in NewOrg
2. Click "Generate Invoice" button
3. Verify Invoice created successfully
4. Query Invoice Line Items:
   ```bash
   sf data query --query "SELECT Id, Description, Quantity, UnitPrice, TotalPrice FROM InvoiceLineItem WHERE Invoice__r.Job__c = '[Job Id]' ORDER BY CreatedDate" --target-org NewOrg
   ```
5. Verify 2 line items:
   - Line 1: Primary transport (£500)
   - Line 2: Secondary transport (£250)
6. Verify Invoice Total = £750 (+ tax)

**Expected Result**:
- Invoice created successfully
- 2 Invoice Line Items
- Descriptions match Description__c from Job_Charge__c
- Prices correct (£500 + £250 = £750 net)
- Invoice Total includes tax

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

### Test Case 6: Regression - Job Without Secondary Transport

**Objective**: Verify existing functionality not broken by V4

**Prerequisites**:
- NewOrg has V4 deployed

**Steps**:
1. Create Quote: JOB-TEST-002
2. Add Quote Line Item: Primary transport ONLY (£750)
3. Do NOT add secondary transport
4. Click "Convert to Job" button
5. Verify Job created successfully
6. Query Job_Charge__c:
   ```bash
   sf data query --query "SELECT Id, Name, Transport_Type__c, Secondary_Transport__c FROM Job_Charge__c WHERE Job__r.Name = 'JOB-TEST-002'" --target-org NewOrg
   ```
7. Verify:
   - 1 Job_Charge__c record created
   - Transport_Type__c = "Primary"
   - Secondary_Transport__c = FALSE
8. Generate Invoice
9. Verify Invoice correct (1 line item, £750 net)

**Expected Result**:
- Job without secondary transport works as before V4
- No errors or unexpected behavior
- Invoice generation unchanged

**Actual Result**: [To be filled during testing]

**Pass/Fail**: [To be determined]

---

## Success Criteria

**Deployment Success**:
- [ ] All 5 Apex classes deployed to NewOrg
- [ ] Deploy ID captured for documentation
- [ ] rlcsJobService.cls LastModifiedDate = deployment date (V4 confirmed)
- [ ] rlcsJobServiceTest.cls exists in NewOrg (new class deployed)
- [ ] All tests pass with 75%+ coverage

**Bug Fix Verification**:
- [ ] Test Case 1 PASS - Map initialization bug fixed
- [ ] Test Case 2 PASS - OrderItem query fixed
- [ ] Test Case 3 PASS - Description fields populated correctly

**Functionality Verification**:
- [ ] Test Case 4 PASS - CSV upload with columns 14-15 works
- [ ] Test Case 5 PASS - End-to-end invoice generation works
- [ ] Test Case 6 PASS - Regression test passes (existing functionality intact)

**Production Readiness**:
- [ ] No errors in debug logs (24 hours post-deployment)
- [ ] RLCS team confirms secondary transport feature working
- [ ] All Job_Charge__c records have OrderItem__c populated (100% success rate)
- [ ] No user-reported issues

**Documentation**:
- [ ] Deploy ID recorded in this README
- [ ] DOCUMENTATION_MAPPING_AND_SCENARIOS.md updated with ✅ COMPLETED status
- [ ] Root README.md files updated in both GitHub repos

---

## Risks and Mitigations

### Risk 1: Test Class Coverage Below 75%

**Probability**: LOW (OldOrg tests pass with 75%+)
**Impact**: HIGH (deployment will fail)

**Mitigation**:
- Run pre-deployment validation (Phase 2.1) to confirm coverage BEFORE deployment
- If coverage low, add test methods to rlcsJobServiceTest.cls
- Deploy test class updates separately, then deploy main classes

### Risk 2: V4 Introduces New Bugs (Unknown)

**Probability**: MEDIUM (V4 has 5 days of production use in OldOrg, but NewOrg environment may differ)
**Impact**: HIGH (breaks secondary transport functionality)

**Mitigation**:
- Thorough testing in Phase 4 and Phase 5
- Monitor debug logs for 24 hours post-deployment (Phase 6.1)
- Have rollback plan ready (restore V3 if critical bug found)
- Deploy during low-usage period (weekend or evening)

### Risk 3: NewOrg Environment Differences

**Probability**: LOW (NewOrg and OldOrg are similar sandboxes)
**Impact**: MEDIUM (some V4 features may not work due to config differences)

**Mitigation**:
- Compare custom settings between OldOrg and NewOrg before deployment
- Verify Job_Charge__c object fields exist in NewOrg (Description__c, Internal_Description__c from V3)
- Test in NewOrg sandbox first if possible, then production

### Risk 4: Missing Test Class (rlcsJobServiceTest.cls)

**Probability**: CONFIRMED (test class not in NewOrg)
**Impact**: HIGH (cannot deploy rlcsJobService.cls without tests)

**Mitigation**:
- Deploy rlcsJobServiceTest.cls FIRST in Phase 3.1
- Verify test class compiles before deploying main class
- If test class deployment fails, investigate dependencies and fix before proceeding

### Risk 5: User Confusion (V3 Bugs Still Present Until Deployment)

**Probability**: CONFIRMED (V3 bugs present in NewOrg until V4 deployed)
**Impact**: MEDIUM (users experience known bugs until V4 deployed)

**Mitigation**:
- Communicate to RLCS team that bugs exist and will be fixed in deployment
- Provide workarounds for known bugs (e.g., manual OrderItem linking)
- Prioritize deployment to minimize time users experience bugs

---

## Communication Plan

### Pre-Deployment Communication

**To**: RLCS Team (Chantal Cook, Glen Bagshaw, Mark Strutz, Vesium Gerry Gregoire)
**Subject**: Secondary Transport V4 Bug Fix Deployment to NewOrg - [Date]

**Message**:
```
Hi RLCS Team,

We will be deploying bug fixes for the Secondary Transport feature to NewOrg on [DATE] at [TIME].

**What's Being Fixed**:
- V4 includes fixes for 3 known bugs in V3 (currently in NewOrg):
  1. Map initialization error (NullPointerException)
  2. OrderItem query missing fields
  3. Description fields not populated

**Expected Downtime**: 30 minutes during deployment (Phase 3)

**Impact**:
- Secondary Transport functionality will be unavailable during deployment
- Jobs without secondary transport NOT affected
- Please avoid creating jobs with secondary transport during deployment window

**Post-Deployment**:
- All secondary transport features will work correctly
- Known bugs from Oct 10 will be resolved
- Please report any issues to [Contact]

Thank you,
[Your Name]
```

### Post-Deployment Communication

**To**: RLCS Team
**Subject**: Secondary Transport V4 Deployment Complete - NewOrg

**Message**:
```
Hi RLCS Team,

The Secondary Transport V4 deployment to NewOrg is complete.

**Deploy ID**: [Insert Deploy ID from Phase 3.2]
**Completion Time**: [Insert timestamp]

**What Was Fixed**:
✅ Map initialization error (no more NullPointerException)
✅ OrderItem query fixed (charges now linked correctly)
✅ Description fields populated (user-facing and internal descriptions)

**Testing Completed**:
- All 6 test cases passed
- End-to-end invoice generation verified
- Regression testing confirmed existing functionality intact

**Next Steps**:
- Please test secondary transport jobs in NewOrg
- Report any issues immediately
- We will monitor for 1 week

**Known Issues**: None

Thank you,
[Your Name]
```

---

## Related Resources

### OldOrg State Documentation

**📍 GitHub**: https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/secondary-transport

**README**: Complete OldOrg state documentation including:
- All 4 versions (V1→V2→V3→V4)
- 75 deployment history with timestamps
- Component analysis (5 Apex classes)
- Bug details and fixes

### Source Documentation

**📍 Location**: [source-docs/](source-docs/) folder in this repository

1. **[SECONDARY_TRANSPORT_IMPLEMENTATION.md](source-docs/SECONDARY_TRANSPORT_IMPLEMENTATION.md)**
   - Original Oct 7-8 implementation (V1, V2)
   - Feature requirements and design
   - CSV upload fix (columns 14-15)

2. **[TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md](source-docs/TRANSPORT_CHARGE_ISSUES_CONSOLIDATED.md)**
   - Oct 14-15 bug fixes (V4)
   - Map initialization fix details
   - OrderItem query fix details
   - Description field logic fix

### Workflow Rules

**📍 Location**: `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md`

**Version**: v1.9 (GitHub as Source of Truth)

**Key Sections**:
- Component-based consolidation rules
- WHY/WHAT/WHEN/TESTING/METRICS documentation standard
- GitHub source of truth workflow

### Master Scenario Index

**📍 Location**: `/home/john/Projects/Salesforce/Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md`

**Scenario #4**: Secondary Transport (Batch 1, HIGH priority, HIGH complexity)

**Status**: ⏳ PENDING → ✅ COMPLETED (after migration)

---

## Appendix

### A. Deploy IDs Reference

**OldOrg Deploy IDs**:
- **V1** (Oct 7, 2025 20:10 UTC): 0AfSj000000yDbtKAE
- **V2** (Oct 8, 2025 17:02 UTC): 0AfSj000000yGbNKAU
- **V3** (Oct 10, 2025 09:24 UTC): 0AfSj000000yVDpKAM (bugs introduced)
- **V4** (Oct 15, 2025 14:09 UTC): 0AfSj000000yp2rKAA (bugs fixed)

**NewOrg Deploy IDs**:
- **V3** (Oct 10, 2025 12:59 UTC): 0AfSq000003iMYHKA2 (CURRENT - with bugs)
- **V4** (Oct 22, 2025 [TBD]): [TO BE RECORDED DURING PHASE 3.2]

### B. Useful Queries

**Check current version in NewOrg**:
```bash
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name FROM ApexClass WHERE Name IN ('rlcsJobService', 'rlcsJobServiceTest', 'RLCSChargeService') ORDER BY Name" --target-org NewOrg --use-tooling-api
```

**Find recent Job_Charge__c records with secondary transport**:
```bash
sf data query --query "SELECT Id, Name, Job__r.Name, Secondary_Transport__c, Transport_Type__c, Description__c, OrderItem__c, CreatedDate FROM Job_Charge__c WHERE Secondary_Transport__c = true ORDER BY CreatedDate DESC LIMIT 50" --target-org NewOrg
```

**Check for NullPointerException errors**:
```bash
sf apex tail log --target-org NewOrg --color

# Look for: "System.NullPointerException"
```

**Count deployments in date range**:
```bash
sf data query --query "SELECT COUNT(Id), Status FROM DeployRequest WHERE CreatedDate >= 2025-10-07T00:00:00Z AND CreatedDate <= 2025-10-15T23:59:59Z GROUP BY Status" --target-org NewOrg --use-tooling-api
```

### C. Code Diff Commands

**Compare V3 vs V4** (rlcsJobService.cls):
```bash
# Retrieve V3 from NewOrg (backup)
cd /home/john/Projects/Salesforce/Backup/2025-10-22_secondary_transport_v3
sf project retrieve start --target-org NewOrg -m "ApexClass:rlcsJobService"

# Compare with V4 from OldOrg
cd /home/john/Projects/Salesforce
diff -u Backup/2025-10-22_secondary_transport_v3/force-app/main/default/classes/rlcsJobService.cls \
  force-app/main/default/classes/rlcsJobService.cls
```

**Key Differences to Look For**:
- Map initialization in createJobFromQuote() method
- OrderItem SOQL query field list
- Description__c and Internal_Description__c assignment logic

### D. Glossary

- **V1**: Initial secondary transport implementation (Oct 7, 2025)
- **V2**: CSV upload fix for columns 14-15 (Oct 8, 2025)
- **V3**: Description fields added (Oct 10, 2025) - **BUGS INTRODUCED**
- **V4**: Bug fixes (Oct 15, 2025) - **STABLE VERSION**
- **OldOrg**: Production/source org with V4 deployed
- **NewOrg**: Target org for migration, currently has V3 with bugs
- **Secondary Transport**: Additional transport charges separate from primary job charge
- **Job_Charge__c**: Custom object storing all charges (primary and secondary)
- **Transport_Type__c**: Picklist field (Primary, Secondary)
- **Secondary_Transport__c**: Boolean checkbox field

---

**Migration Plan Version**: 1.0
**Last Updated**: October 22, 2025
**Next Review**: After V4 deployment complete
**Owner**: Migration Team
**Approvers**: RLCS Team Lead, Salesforce Admin
