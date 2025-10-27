@isTest
public class rlcs_connectedHomePageLinksTest {
    
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Producer_Placed_on_Market__c records
        List<Producer_Placed_on_Market__c> testRecords = new List<Producer_Placed_on_Market__c>();

        // Create upcoming record (future quarter)
        Producer_Placed_on_Market__c upcoming = new Producer_Placed_on_Market__c(
            Quarter__c = 'Q4',
            Compliance_Year__c = '2025',
            Acknowledgement_of_Statements__c = false,
            Account__c = testAccount.Id
        );

        // Create past due record (past quarter, not acknowledged)
        Producer_Placed_on_Market__c pastDue = new Producer_Placed_on_Market__c(
            Quarter__c = 'Q1',
            Compliance_Year__c = '2024',
            Acknowledgement_of_Statements__c = false,
            Account__c = testAccount.Id
        );

        // Create acknowledged record (should not appear in past due)
        Producer_Placed_on_Market__c acknowledged = new Producer_Placed_on_Market__c(
            Quarter__c = 'Q2',
            Compliance_Year__c = '2024',
            Acknowledgement_of_Statements__c = true,
            Account__c = testAccount.Id
        );

        testRecords.add(upcoming);
        testRecords.add(pastDue);
        testRecords.add(acknowledged);

        insert testRecords;
    }
    
    @isTest
    static void testGetUpcomingDates() {
        Test.startTest();
        List<Producer_Placed_on_Market__c> results = rlcs_connectedHomePageLinks.getUpcomingDates();
        Test.stopTest();

        // In test context, current user has no contact, so should return empty list
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list when user has no account');
    }

    @isTest
    static void testGetPastDue() {
        Test.startTest();
        List<Producer_Placed_on_Market__c> results = rlcs_connectedHomePageLinks.getPastDue();
        Test.stopTest();

        // In test context, current user has no contact, so should return empty list
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list when user has no account');
    }
    
    @isTest
    static void testGetCurrentUserAccountInfo_WithValidUser() {
        Test.startTest();
        // Test with current user (no contact association in test context)
        rlcs_connectedHomePageLinks.AccountInfo result = rlcs_connectedHomePageLinks.getCurrentUserAccountInfo();
        Test.stopTest();
        
        // This will test the path where user has no contact (default constructor)
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.accountId, 'Account ID should be null when no contact');
        System.assertEquals(null, result.accountName, 'Account name should be null when no contact');
        System.assertEquals(null, result.producerObligationType, 'Producer obligation type should be null when no contact');
        System.assertEquals(true, result.showReportsLink, 'Should default to showing reports link');
    }
    
    @isTest
    static void testGetCurrentUserAccountInfo_ExceptionHandling() {
        Test.startTest();
        // Test exception handling when user has no contact
        rlcs_connectedHomePageLinks.AccountInfo result = rlcs_connectedHomePageLinks.getCurrentUserAccountInfo();
        Test.stopTest();
        
        // This tests the exception handling path and default constructor
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.accountId, 'Account ID should be null');
        System.assertEquals(null, result.accountName, 'Account name should be null');
        System.assertEquals(null, result.producerObligationType, 'Producer obligation type should be null');
        System.assertEquals(true, result.showReportsLink, 'Should default to showing reports link');
    }
    
    @isTest
    static void testGetCurrentUserAccountInfo_CurrentUserPath() {
        Test.startTest();
        // Test with current running user (tests the method's main execution path)
        rlcs_connectedHomePageLinks.AccountInfo result = rlcs_connectedHomePageLinks.getCurrentUserAccountInfo();
        Test.stopTest();
        
        // This tests the method execution and validates it returns a non-null result
        System.assertNotEquals(null, result, 'Result should not be null');
        // In test context, current user typically has no contact, so this tests the null path
        System.assertEquals(true, result.showReportsLink, 'Should default to showing reports link');
    }
    
    @isTest
    static void testAccountInfoDefaultConstructor() {
        Test.startTest();
        rlcs_connectedHomePageLinks.AccountInfo accountInfo = new rlcs_connectedHomePageLinks.AccountInfo();
        Test.stopTest();
        
        System.assertEquals(null, accountInfo.accountId, 'Account ID should be null');
        System.assertEquals(null, accountInfo.accountName, 'Account name should be null');
        System.assertEquals(null, accountInfo.producerObligationType, 'Producer obligation type should be null');
        System.assertEquals(true, accountInfo.showReportsLink, 'Should default to showing reports link');
    }
    
    @isTest
    static void testAccountInfoAccountConstructor() {
        Account testAccount = new Account(
            Name = 'Test Account Constructor',
            Producer_Obligation_Yype__c = 'B2C'
        );
        insert testAccount;
        
        Test.startTest();
        rlcs_connectedHomePageLinks.AccountInfo accountInfo = new rlcs_connectedHomePageLinks.AccountInfo(testAccount);
        Test.stopTest();
        
        System.assertEquals(testAccount.Id, accountInfo.accountId, 'Account ID should match');
        System.assertEquals(testAccount.Name, accountInfo.accountName, 'Account name should match');
        System.assertEquals('B2C', accountInfo.producerObligationType, 'Producer obligation type should match');
        System.assertEquals(true, accountInfo.showReportsLink, 'Should show reports link for B2C');
    }
}