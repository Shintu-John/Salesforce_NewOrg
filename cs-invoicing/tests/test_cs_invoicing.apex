/**
 * Functional Test Script for CS-Invoicing Deployment
 * Deploy ID: 0AfSq000003nOU5KAM
 * Date: October 23, 2025
 *
 * Tests:
 * 1. Collection_Date__c field auto-population on RLCS_Charge__c
 * 2. Description__c field auto-population on RLCS_Charge__c
 * 3. RLCS_ChargeTrigger rollup to Invoice__c.Total_Net__c
 */

System.debug('=== CS-INVOICING FUNCTIONAL TEST START ===');

// SETUP: Get test data
Account customerAccount = [SELECT Id FROM Account WHERE Type = 'Customer' LIMIT 1];
System.debug('✓ Found Customer Account: ' + customerAccount.Id);

// Create Product and Order (needed for Order_Product__c)
Product2 testProduct = new Product2(Name = 'CS Invoicing Test Product', IsActive = true);
insert testProduct;
System.debug('✓ Created Product: ' + testProduct.Id);

Id standardPriceBookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
PricebookEntry pbe = new PricebookEntry(
    Pricebook2Id = standardPriceBookId,
    Product2Id = testProduct.Id,
    UnitPrice = 100,
    IsActive = true
);
insert pbe;
System.debug('✓ Created PricebookEntry: ' + pbe.Id);

Order testOrder = new Order(
    AccountId = customerAccount.Id,
    EffectiveDate = Date.today(),
    Status = 'Draft',
    Pricebook2Id = standardPriceBookId
);
insert testOrder;
System.debug('✓ Created Order: ' + testOrder.Id);

OrderItem orderProduct = new OrderItem(
    OrderId = testOrder.Id,
    Product2Id = testProduct.Id,
    PricebookEntryId = pbe.Id,
    Quantity = 1,
    UnitPrice = 100
);
insert orderProduct;
System.debug('✓ Created OrderItem: ' + orderProduct.Id);

// =================================================================
// TEST 1: Automatic Charge Creation with Collection_Date__c and Description__c
// =================================================================
System.debug('\n=== TEST 1: Collection Date & Description Auto-Population ===');

Date testCollectionDate = Date.today().addDays(-7);

RLCS_Job__c testJob = new RLCS_Job__c(
    Customer_Account__c = customerAccount.Id,
    Status__c = 'Open',
    Delivery_Date__c = Date.today(),
    Collected_Date__c = testCollectionDate,
    Order_Product__c = orderProduct.Id,
    Waste_Type__c = 'Mixed Recycling',
    EWC__c = '20 03 01'
);

try {
    insert testJob;
    System.debug('✅ TEST 1A PASSED: Job created successfully');
    System.debug('   Job ID: ' + testJob.Id);
} catch (Exception e) {
    System.debug('❌ TEST 1A FAILED: Could not create Job');
    System.debug('   Error: ' + e.getMessage());
}

// Wait a moment for trigger to process
System.debug('Waiting for rlcsJobTrigger to create charges...');

// Query for auto-created charges
List<RLCS_Charge__c> autoCharges = [
    SELECT Id, Name, Collection_Date__c, Description__c, Charge_Type__c, RLCS_Job__c
    FROM RLCS_Charge__c
    WHERE RLCS_Job__c = :testJob.Id
    ORDER BY CreatedDate DESC
];

if (autoCharges.size() > 0) {
    System.debug('✅ TEST 1B PASSED: rlcsJobTrigger created ' + autoCharges.size() + ' charge(s)');

    for (RLCS_Charge__c charge : autoCharges) {
        System.debug('\n--- Charge: ' + charge.Name + ' (' + charge.Charge_Type__c + ') ---');

        // TEST 1C: Check Collection_Date__c
        if (charge.Collection_Date__c == testCollectionDate) {
            System.debug('✅ TEST 1C PASSED: Collection_Date__c = ' + charge.Collection_Date__c);
        } else {
            System.debug('❌ TEST 1C FAILED: Collection_Date__c mismatch');
            System.debug('   Expected: ' + testCollectionDate);
            System.debug('   Actual: ' + charge.Collection_Date__c);
        }

        // TEST 1D: Check Description__c
        if (String.isNotBlank(charge.Description__c)) {
            System.debug('✅ TEST 1D PASSED: Description__c populated');
            System.debug('   Description: "' + charge.Description__c + '"');

            // Verify description contains expected fields
            Boolean hasWasteType = charge.Description__c.contains('Mixed Recycling');
            Boolean hasEWC = charge.Description__c.contains('20 03 01');

            if (hasWasteType && hasEWC) {
                System.debug('✅ TEST 1E PASSED: Description contains Waste Type and EWC');
            } else {
                System.debug('⚠️  TEST 1E WARNING: Description missing expected fields');
                System.debug('   Has Waste Type: ' + hasWasteType);
                System.debug('   Has EWC: ' + hasEWC);
            }
        } else {
            System.debug('❌ TEST 1D FAILED: Description__c is blank');
        }
    }
} else {
    System.debug('❌ TEST 1B FAILED: No charges auto-created by rlcsJobTrigger');
}

// =================================================================
// TEST 2: RLCS_ChargeTrigger Rollup to Invoice
// =================================================================
System.debug('\n=== TEST 2: Invoice Total Rollup via RLCS_ChargeTrigger ===');

// Create an Invoice
Invoice__c testInvoice = new Invoice__c(
    Account__c = customerAccount.Id,
    // Invoice_Date__c not available
    Total_Net__c = 0 // Should be updated by trigger
);
insert testInvoice;
System.debug('✓ Created Invoice: ' + testInvoice.Id);

// Create manual charges with different amounts
Decimal charge1Amount = 100.50;
Decimal charge2Amount = 250.75;
Decimal charge3Amount = 50.00;
Decimal expectedTotal = charge1Amount + charge2Amount + charge3Amount; // 401.25

RLCS_Charge__c manualCharge1 = new RLCS_Charge__c(
    Sales_Invoice__c = testInvoice.Id,
    Sales_Price__c = charge1Amount,
    Collection_Date__c = Date.today(),
    Description__c = 'Test Charge 1'
);

RLCS_Charge__c manualCharge2 = new RLCS_Charge__c(
    Sales_Invoice__c = testInvoice.Id,
    Sales_Price__c = charge2Amount,
    Collection_Date__c = Date.today(),
    Description__c = 'Test Charge 2'
);

RLCS_Charge__c manualCharge3 = new RLCS_Charge__c(
    Sales_Invoice__c = testInvoice.Id,
    Sales_Price__c = charge3Amount,
    Collection_Date__c = Date.today(),
    Description__c = 'Test Charge 3'
);

try {
    insert new List<RLCS_Charge__c>{manualCharge1, manualCharge2, manualCharge3};
    System.debug('✅ TEST 2A PASSED: Created 3 manual charges');
    System.debug('   Charge 1: £' + charge1Amount);
    System.debug('   Charge 2: £' + charge2Amount);
    System.debug('   Charge 3: £' + charge3Amount);
    System.debug('   Expected Total: £' + expectedTotal);
} catch (Exception e) {
    System.debug('❌ TEST 2A FAILED: Could not create charges');
    System.debug('   Error: ' + e.getMessage());
}

// Query Invoice to check rollup
Invoice__c updatedInvoice = [SELECT Id, Total_Net__c FROM Invoice__c WHERE Id = :testInvoice.Id];

if (updatedInvoice.Total_Net__c == expectedTotal) {
    System.debug('✅ TEST 2B PASSED: RLCS_ChargeTrigger rollup correct!');
    System.debug('   Total_Net__c = £' + updatedInvoice.Total_Net__c);
} else {
    System.debug('❌ TEST 2B FAILED: RLCS_ChargeTrigger rollup incorrect');
    System.debug('   Expected: £' + expectedTotal);
    System.debug('   Actual: £' + updatedInvoice.Total_Net__c);
}

// =================================================================
// TEST 3: Update Charge Amount - Verify Rollup Updates
// =================================================================
System.debug('\n=== TEST 3: Rollup Update on Charge Amount Change ===');

Decimal newCharge1Amount = 150.00;
Decimal newExpectedTotal = newCharge1Amount + charge2Amount + charge3Amount; // 450.75

manualCharge1.Sales_Price__c = newCharge1Amount;

try {
    update manualCharge1;
    System.debug('✅ TEST 3A PASSED: Updated charge amount to £' + newCharge1Amount);
} catch (Exception e) {
    System.debug('❌ TEST 3A FAILED: Could not update charge');
    System.debug('   Error: ' + e.getMessage());
}

// Re-query Invoice
updatedInvoice = [SELECT Id, Total_Net__c FROM Invoice__c WHERE Id = :testInvoice.Id];

if (updatedInvoice.Total_Net__c == newExpectedTotal) {
    System.debug('✅ TEST 3B PASSED: RLCS_ChargeTrigger updated rollup correctly!');
    System.debug('   New Total_Net__c = £' + updatedInvoice.Total_Net__c);
} else {
    System.debug('❌ TEST 3B FAILED: RLCS_ChargeTrigger did not update rollup');
    System.debug('   Expected: £' + newExpectedTotal);
    System.debug('   Actual: £' + updatedInvoice.Total_Net__c);
}

// =================================================================
// TEST 4: Delete Charge - Verify Rollup Recalculates
// =================================================================
System.debug('\n=== TEST 4: Rollup Recalculation on Charge Deletion ===');

Decimal finalExpectedTotal = charge2Amount + charge3Amount; // 300.75 (without charge1)

try {
    delete manualCharge1;
    System.debug('✅ TEST 4A PASSED: Deleted charge (£' + newCharge1Amount + ')');
} catch (Exception e) {
    System.debug('❌ TEST 4A FAILED: Could not delete charge');
    System.debug('   Error: ' + e.getMessage());
}

// Re-query Invoice
updatedInvoice = [SELECT Id, Total_Net__c FROM Invoice__c WHERE Id = :testInvoice.Id];

if (updatedInvoice.Total_Net__c == finalExpectedTotal) {
    System.debug('✅ TEST 4B PASSED: RLCS_ChargeTrigger recalculated after delete!');
    System.debug('   Final Total_Net__c = £' + updatedInvoice.Total_Net__c);
} else {
    System.debug('❌ TEST 4B FAILED: RLCS_ChargeTrigger did not recalculate');
    System.debug('   Expected: £' + finalExpectedTotal);
    System.debug('   Actual: £' + updatedInvoice.Total_Net__c);
}

// =================================================================
// CLEANUP
// =================================================================
System.debug('\n=== CLEANUP ===');

try {
    delete testJob; // Cascade deletes auto-created charges
    delete new List<RLCS_Charge__c>{manualCharge2, manualCharge3};
    delete testInvoice;
    delete testOrder; // Cascade deletes OrderItem
    delete testProduct;
    System.debug('✓ Test data cleaned up');
} catch (Exception e) {
    System.debug('⚠️  Cleanup warning: ' + e.getMessage());
}

System.debug('\n=== CS-INVOICING FUNCTIONAL TEST COMPLETE ===');
System.debug('Review the test results above to verify all features are working correctly.');
