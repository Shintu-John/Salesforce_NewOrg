// FUNCTIONAL TEST: [Scenario Name]
// Purpose: [Brief description of what this test validates]
// Date: [Date]
// Deployment: [Deploy ID]

System.debug('=== FUNCTIONAL TEST: [Scenario Name] ===\n');

// ============================================================================
// SETUP: Create test data hierarchy
// ============================================================================

// Account (if needed)
Account testAcc = new Account(
    Name = '[Scenario] Test Account',
    comp_house__Company_Number__c = '99999999'  // Required for validation
);
insert testAcc;

// Product & Pricebook (if needed for OrderItem)
Product2 testProd = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 1];
Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
PricebookEntry pbe = [
    SELECT Id
    FROM PricebookEntry
    WHERE Product2Id = :testProd.Id
    AND Pricebook2Id = :stdPb.Id
    AND IsActive = true
    LIMIT 1
];

// ============================================================================
// TEST 1: [Test Description]
// ============================================================================

System.debug('\n--- TEST 1: [Test Name] ---');

// Setup test data
[Object] testObj1 = new [Object](
    // Required fields
    Field__c = value
);
// Use .put() for dynamic field assignment on newly deployed fields
testObj1.put('CustomField__c', value);
insert testObj1;

// Execute business logic (trigger fires, workflow executes, etc.)
[Object] result1 = [
    SELECT Id, Field__c, CustomField__c
    FROM [Object]
    WHERE Id = :testObj1.Id
];

// Verify results
if (result1.CustomField__c == expectedValue) {
    System.debug('✅ TEST 1 PASSED: [Success message]');
} else {
    System.debug('❌ TEST 1 FAILED: Expected [expected], got ' + result1.CustomField__c);
}

// ============================================================================
// TEST 2: [Test Description]
// ============================================================================

System.debug('\n--- TEST 2: [Test Name] ---');

// Setup test data
[Object] testObj2 = new [Object](
    Field__c = value
);
insert testObj2;

// Execute and verify
[Object] result2 = [
    SELECT Id, Field__c
    FROM [Object]
    WHERE Id = :testObj2.Id
];

if ([condition]) {
    System.debug('✅ TEST 2 PASSED: [Success message]');
} else {
    System.debug('❌ TEST 2 FAILED: [Failure message]');
}

// ============================================================================
// TEST 3: Edge Case - [Description]
// ============================================================================

System.debug('\n--- TEST 3: [Edge Case Name] ---');

// Test edge case (null values, boundary conditions, etc.)
try {
    [Object] edgeCase = new [Object](
        // Edge case data
    );
    insert edgeCase;
    System.debug('✅ TEST 3 PASSED: Edge case handled correctly');
} catch (Exception e) {
    System.debug('❌ TEST 3 FAILED: ' + e.getMessage());
}

// ============================================================================
// SUMMARY
// ============================================================================

System.debug('\n=== FUNCTIONAL TEST SUMMARY ===');
System.debug('Scenario: [Scenario Name]');
System.debug('Deploy ID: [Deploy ID]');
System.debug('Tests executed: [X]');
System.debug('Review test results above for ✅ PASSED or ❌ FAILED indicators.');
System.debug('\n=== END FUNCTIONAL TEST ===');
