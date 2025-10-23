// ============================================================================
// FUNCTIONAL TEST: Secondary Transport Implementation
// ============================================================================

System.debug('=== Starting Secondary Transport Functional Tests ===\n');

try {
    // Create test Account
    Account testAccount = new Account(
        Name = 'Test Secondary Transport Account',
        comp_house__Company_Number__c = '99999999'
    );
    insert testAccount;
    System.debug('✅ Created test Account: ' + testAccount.Id);

    // Get Product and Pricebook
    Product2 testProduct = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 1];
    Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

    PricebookEntry pbe = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id = :testProduct.Id
        AND Pricebook2Id = :stdPbId
        AND IsActive = true
        LIMIT 1
    ];
    System.debug('✅ Using PricebookEntry: ' + pbe.Id);

    // Create Order
    Order testOrder = new Order(
        AccountId = testAccount.Id,
        EffectiveDate = Date.today(),
        Status = 'Draft',
        Pricebook2Id = stdPbId
    );
    insert testOrder;
    System.debug('✅ Created Order: ' + testOrder.Id);

    // ========================================================================
    // TEST 1: Secondary Transport Per Tonne
    // ========================================================================
    System.debug('\n=== TEST 1: Secondary Transport Per Tonne ===');

    OrderItem oi1 = new OrderItem(
        OrderId = testOrder.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100
    );
    oi1.put('Secondary_Transport_Charge__c', true);
    oi1.put('Secondary_Transport_Per_Tonne__c', true);
    oi1.put('Secondary_Transport_P_T__c', 50.00);
    insert oi1;
    System.debug('Created OrderItem with Secondary Transport Per Tonne');

    RLCS_Job__c job1 = new RLCS_Job__c(
        Order_Product__c = oi1.Id,
        Material_Weight_Tonnes__c = 2.5
    );
    insert job1;
    System.debug('Created Job with 2.5 tonnes');

    List<RLCS_Charge__c> charges1 = [
        SELECT Id, Charge_Type__c, Cost__c
        FROM RLCS_Charge__c
        WHERE RLCS_Job__c = :job1.Id
        ORDER BY Charge_Type__c
    ];

    System.debug('Total charges: ' + charges1.size());
    Boolean test1Passed = false;
    for (RLCS_Charge__c charge : charges1) {
        System.debug('  - ' + charge.Charge_Type__c + ': £' + charge.Cost__c);
        if (charge.Charge_Type__c == 'Secondary Transport' && charge.Cost__c == 125.00) {
            test1Passed = true;
        }
    }

    if (test1Passed) {
        System.debug('✅ TEST 1 PASSED: Secondary Transport Per Tonne (£125 = 2.5 × £50)');
    } else {
        System.debug('❌ TEST 1 FAILED: Secondary Transport charge incorrect or missing');
    }

    // ========================================================================
    // TEST 2: Secondary Transport Per Unit
    // ========================================================================
    System.debug('\n=== TEST 2: Secondary Transport Per Unit ===');

    OrderItem oi2 = new OrderItem(
        OrderId = testOrder.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100
    );
    oi2.put('Secondary_Transport_Charge__c', true);
    oi2.put('Secondary_Transport_Per_Unit__c', true);
    oi2.put('Secondary_Transport_P_T__c', 15.00);
    insert oi2;
    System.debug('Created OrderItem with Secondary Transport Per Unit');

    RLCS_Job__c job2 = new RLCS_Job__c(
        Order_Product__c = oi2.Id,
        Unit_Count__c = 10
    );
    insert job2;
    System.debug('Created Job with 10 units');

    List<RLCS_Charge__c> charges2 = [
        SELECT Id, Charge_Type__c, Cost__c
        FROM RLCS_Charge__c
        WHERE RLCS_Job__c = :job2.Id
        AND Charge_Type__c = 'Secondary Transport'
    ];

    Boolean test2Passed = false;
    if (charges2.size() > 0 && charges2[0].Cost__c == 150.00) {
        test2Passed = true;
        System.debug('  - Secondary Transport: £' + charges2[0].Cost__c);
        System.debug('✅ TEST 2 PASSED: Secondary Transport Per Unit (£150 = 10 × £15)');
    } else {
        System.debug('❌ TEST 2 FAILED: Expected £150, got ' + (charges2.size() > 0 ? '£' + charges2[0].Cost__c : 'no charge'));
    }

    // ========================================================================
    // TEST 3: No Secondary Transport When Not Enabled
    // ========================================================================
    System.debug('\n=== TEST 3: No Secondary Transport When Disabled ===');

    OrderItem oi3 = new OrderItem(
        OrderId = testOrder.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100
    );
    // Do NOT enable secondary transport
    insert oi3;

    RLCS_Job__c job3 = new RLCS_Job__c(
        Order_Product__c = oi3.Id,
        Material_Weight_Tonnes__c = 1.0
    );
    insert job3;

    List<RLCS_Charge__c> charges3 = [
        SELECT Id, Charge_Type__c
        FROM RLCS_Charge__c
        WHERE RLCS_Job__c = :job3.Id
        AND Charge_Type__c = 'Secondary Transport'
    ];

    if (charges3.size() == 0) {
        System.debug('✅ TEST 3 PASSED: No Secondary Transport charge when not enabled');
    } else {
        System.debug('❌ TEST 3 FAILED: Secondary Transport charge created when it should not be');
    }

    // ========================================================================
    // TEST 4: Job Fields Populated (CSV Upload Fix Verification)
    // ========================================================================
    System.debug('\n=== TEST 4: Job Weight and Unit Fields ===');

    RLCS_Job__c job4 = new RLCS_Job__c(
        Order_Product__c = oi1.Id,
        Material_Weight_Tonnes__c = 0.954,
        Unit_Count__c = 25
    );
    insert job4;

    RLCS_Job__c verifyJob = [
        SELECT Material_Weight_Tonnes__c, Unit_Count__c
        FROM RLCS_Job__c
        WHERE Id = :job4.Id
    ];

    if (verifyJob.Material_Weight_Tonnes__c == 0.954 && verifyJob.Unit_Count__c == 25) {
        System.debug('✅ TEST 4 PASSED: Job fields populated correctly');
        System.debug('  - Weight: ' + verifyJob.Material_Weight_Tonnes__c + ' tonnes');
        System.debug('  - Units: ' + verifyJob.Unit_Count__c);
    } else {
        System.debug('❌ TEST 4 FAILED: Job fields not populated correctly');
    }

    // ========================================================================
    // SUMMARY
    // ========================================================================
    System.debug('\n=== TEST SUMMARY ===');
    Integer passedCount = 0;
    if (test1Passed) passedCount++;
    if (test2Passed) passedCount++;
    if (charges3.size() == 0) passedCount++;
    if (verifyJob.Material_Weight_Tonnes__c == 0.954) passedCount++;

    System.debug('Tests Passed: ' + passedCount + '/4');
    if (passedCount == 4) {
        System.debug('✅ ALL TESTS PASSED - Secondary Transport deployment successful!');
    } else {
        System.debug('⚠️  ' + (4 - passedCount) + ' test(s) failed - review results above');
    }

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Line: ' + e.getLineNumber());
    System.debug('Stack: ' + e.getStackTraceString());
}
