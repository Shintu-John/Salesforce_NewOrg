@isTest
public class rlsServiceCaseAutoAssignHandlerTest {

    @testSetup
    static void setup() {
        // Handle setup objects first to avoid mixed DML
        Profile csProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Customer Service%' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'CSUser',
            Email = 'test.csuser@example.com',
            Username = 'test.csuserssdadadewdcdsfdsarvfsdvsdvsz@example.com.test',
            Alias = 'tcsuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = csProfile.Id,
            IsActive = true,
            Dont_Auto_Assign_Cases__c = false
        );
        insert testUser;

        // Create Customer Service Email queue
        Group csQueue = new Group(
            Name = 'Customer Service Email',
            Type = 'Queue'
        );
        insert csQueue;

        // Associate queue with Case object
        QueueSobject queueSobject = new QueueSobject(
            QueueId = csQueue.Id,
            SobjectType = 'Case'
        );
        insert queueSobject;
    }

    // Helper method to create non-setup data
    private static void createTestData() {
        // Get the queue we created
        Group csQueue = [SELECT Id FROM Group WHERE Name = 'Customer Service Email' LIMIT 1];

        // Create Account without CS Contact
        Account testAccount = new Account(
            Name = 'Test Account',
            CS_Contact__c = null,
            comp_house__Company_Number__c = '12345678'
        );
        insert testAccount;

        // Create Email record type
        Id emailRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Email').getRecordTypeId();

        // Create test case in queue
        Case testCase = new Case(
            Subject = 'Test Case for Handler',
            AccountId = testAccount.Id,
            OwnerId = csQueue.Id,
            RecordTypeId = emailRecordTypeId,
            Status = 'Case Raised'
        );
        insert testCase;
    }

    @isTest
    static void testAssignCaseAsync() {
        createTestData();
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Prepare input for invocable method
        rlsServiceCaseAutoAssignHandler.FlowInputs input = new rlsServiceCaseAutoAssignHandler.FlowInputs();
        input.caseId = testCase.Id;
        List<rlsServiceCaseAutoAssignHandler.FlowInputs> inputs = new List<rlsServiceCaseAutoAssignHandler.FlowInputs>{input};

        Test.startTest();

        // Call the invocable method
        rlsServiceCaseAutoAssignHandler.assignCaseAsync(inputs);

        Test.stopTest();

        // Verify case was assigned to a user (not the queue)
        Case updatedCase = [SELECT Id, OwnerId, rlsServiceCaseAutoAssign_Date_Time__c FROM Case WHERE Id = :testCase.Id];

        // Check that owner is now a User, not the queue
        String ownerId = String.valueOf(updatedCase.OwnerId);
        System.assert(ownerId.startsWith('005'), 'Case should be assigned to a User');
        System.assertNotEquals(null, updatedCase.rlsServiceCaseAutoAssign_Date_Time__c, 'Assignment timestamp should be set');
    }

    @isTest
    static void testAssignCaseAsyncWithNullInput() {
        rlsServiceCaseAutoAssignHandler.FlowInputs input = new rlsServiceCaseAutoAssignHandler.FlowInputs();
        input.caseId = null;
        List<rlsServiceCaseAutoAssignHandler.FlowInputs> inputs = new List<rlsServiceCaseAutoAssignHandler.FlowInputs>{input};

        Test.startTest();

        // This should not throw an exception
        rlsServiceCaseAutoAssignHandler.assignCaseAsync(inputs);

        Test.stopTest();

        // No assertions needed - just verify no exception thrown
        System.assert(true, 'Method should handle null input gracefully');
    }

    @isTest
    static void testAssignCasesFuture() {
        createTestData();
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<Id> caseIds = new List<Id>{testCase.Id};

        Test.startTest();

        // Call the future method directly
        rlsServiceCaseAutoAssignHandler.assignCasesFuture(caseIds);

        Test.stopTest();

        // Verify case was assigned
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :testCase.Id];
        String ownerId = String.valueOf(updatedCase.OwnerId);
        System.assert(ownerId.startsWith('005'), 'Case should be assigned to a User');
    }
}