# Activated Triggers and Their Test Classes

This document tracks all triggers that were INACTIVE in NewOrg and have been ACTIVATED during deployment, along with their associated test classes.

**Purpose:** Ensure all activated triggers have proper test coverage and that test classes are available for reference.

---

## Activated Triggers

### 1. rlcsJobTrigger (RLCS_Job__c)

**Activation Details:**
- **Scenario:** transport-charges
- **Activation Date:** October 23, 2025
- **Status:** ⏸️ INACTIVE → ✅ ACTIVE
- **Approved By:** John Shintu

**Trigger Purpose:**
Automatically creates and updates RLCS_Charge__c records (transport, tonnage, rebate) when Jobs are inserted or updated. Critical for automatic charge generation.

**Trigger Handler:**
- `rlcsJobTriggerHandler.cls` (extends TriggerHandler)
  - Calls `rlcsJobService.createUpdateAutoJobCharges()` on insert/update
  - Calls `manageHeirarchy()` for parent/child Job relationships

**Test Class:**
- **Name:** `rlcsJobServiceTest.cls`
- **Location:** `/home/john/Projects/Salesforce/deployment-execution/transport-charges/code/classes/rlcsJobServiceTest.cls`
- **Lines:** 2,436 lines
- **Status:** ✅ Deployed to NewOrg (Oct 23, 2025)
- **Deploy ID:** 0AfSq000003nLkjKAE (transport-charges)
- **Test Methods:** 65 test methods
- **Coverage:** 100% of rlcsJobService

**Key Test Methods:**
- `testCreateUpdateAutoJobChargesInsert` - Tests charge creation on Job insert
- `testCreateUpdateAutoJobChargesUpdate` - Tests charge updates when Job changes
- `testTransportChargeCalculation` - Tests transport charge logic
- `testSecondaryTransportCharges` - Tests secondary transport charge logic
- `testTonnageChargeCalculation` - Tests tonnage charge logic
- `testRebateChargeCalculation` - Tests rebate charge logic
- `testFixedPricingMethod` - Tests Fixed pricing
- `testPerTonnePricing` - Tests Per Tonne pricing
- `testPerUnitPricing` - Tests Per Unit pricing
- `testNullHandling` - Tests edge cases with null values

**Business Impact:**
- £1.79M+ financial protection
- Automatic charge creation for all Jobs
- Prevents manual charge entry errors

---

### 2. RLCS_ChargeTrigger (RLCS_Charge__c)

**Activation Details:**
- **Scenario:** cs-invoicing
- **Activation Date:** October 23, 2025
- **Status:** ⏸️ INACTIVE → ✅ ACTIVE
- **Approved By:** John Shintu

**Trigger Purpose:**
Automatically rolls up `Sales_Price__c` from RLCS_Charge__c records to `Total_Net__c` on parent Invoice__c. Critical for accurate invoice totals.

**Trigger Events:**
- after insert
- after update
- after delete
- after undelete

**Trigger Logic:**
Calls `RollupService.handleInsertUpdate()` or `RollupService.handleDelete()` with parameters:
- Child Object: RLCS_Charge__c
- Parent Object: Invoice__c
- Relationship Field: Sales_Invoice__c
- Rollup Field (Child): Sales_Price__c
- Summary Field (Parent): Total_Net__c

**Test Class:**
- **Name:** `RollupServiceTest.cls`
- **Location:** `/home/john/Projects/Salesforce/deployment-execution/cs-invoicing/code/classes/RollupServiceTest.cls`
- **Lines:** 65 lines
- **Status:** ✅ Already exists in NewOrg (created Sept 19, 2025)
- **Created By:** Glen Bagshaw
- **Last Modified:** Sept 19, 2025

**Key Test Methods:**
- `testExampleRollup` - Tests rollup calculation on insert/update/delete

**Test Coverage:**
The test uses Opportunity → Account as an example rollup, but the RollupService is generic and works for any parent-child relationship including RLCS_Charge__c → Invoice__c.

**Note:**
While the test class uses different objects (Opportunity/Account), it tests the same RollupService methods that RLCS_ChargeTrigger uses:
- `RollupService.handleInsertUpdate()` ✅
- `RollupService.handleDelete()` ✅

**Business Impact:**
- Automatic invoice total calculation
- Eliminates manual calculation errors
- Real-time invoice total updates when charges change

---

## Test Class File Locations

### transport-charges Test Classes
```
/home/john/Projects/Salesforce/deployment-execution/transport-charges/code/classes/
├── rlcsJobServiceTest.cls
└── rlcsJobServiceTest.cls-meta.xml
```

### cs-invoicing Test Classes
```
/home/john/Projects/Salesforce/deployment-execution/cs-invoicing/code/classes/
├── RollupServiceTest.cls
└── RollupServiceTest.cls-meta.xml
```

---

## Verification Commands

### Verify Trigger Status in NewOrg
```bash
# Check rlcsJobTrigger
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name = 'rlcsJobTrigger'" --target-org NewOrg --use-tooling-api

# Check RLCS_ChargeTrigger
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name = 'RLCS_ChargeTrigger'" --target-org NewOrg --use-tooling-api
```

**Expected Result:** Status = Active for both

### Verify Test Classes in NewOrg
```bash
# Check rlcsJobServiceTest
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate FROM ApexClass WHERE Name = 'rlcsJobServiceTest'" --target-org NewOrg --use-tooling-api

# Check RollupServiceTest
sf data query --query "SELECT Name, LengthWithoutComments, LastModifiedDate FROM ApexClass WHERE Name = 'RollupServiceTest'" --target-org NewOrg --use-tooling-api
```

### Run Test Classes
```bash
# Run rlcsJobServiceTest
sf apex run test --class-names rlcsJobServiceTest --target-org NewOrg --result-format human --code-coverage

# Run RollupServiceTest
sf apex run test --class-names RollupServiceTest --target-org NewOrg --result-format human --code-coverage
```

---

## Future Trigger Activations

When activating new triggers, add entries here with:
1. Trigger name and object
2. Activation date and scenario
3. Test class name and location
4. Test coverage details
5. Business impact

---

**Created:** October 23, 2025
**Last Updated:** October 23, 2025
**Maintained By:** Deployment Execution Team
