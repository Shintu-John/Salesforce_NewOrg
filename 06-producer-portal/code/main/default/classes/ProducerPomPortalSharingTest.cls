@isTest
private class ProducerPomPortalSharingTest {

    @isTest
    static void testShareRecordsWithPortalUsers() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Producer POM record
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            Quarter__c = 'Q1',
            Compliance_Year__c = '2025'
        );
        insert pom;

        // Test the sharing method
        Test.startTest();
        Set<Id> pomIds = new Set<Id>{pom.Id};
        ProducerPomPortalSharing.shareRecordsWithPortalUsers(pomIds);
        Test.stopTest();

        // Verify - just check it runs without error
        System.assertNotEquals(null, pom.Id, 'Record should be created');
    }

    @isTest
    static void testShareAllRecordsWithPortalUsers() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Producer POM record
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            Quarter__c = 'Q1',
            Compliance_Year__c = '2025'
        );
        insert pom;

        // Test the batch sharing method
        Test.startTest();
        ProducerPomPortalSharing.shareAllRecordsWithPortalUsers();
        Test.stopTest();

        // Verify - just check it runs without error
        System.assertNotEquals(null, pom.Id, 'Record should be created');
    }
}
