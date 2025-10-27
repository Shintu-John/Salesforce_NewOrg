@isTest
private class ProducerPomAcknowledgeControllerTest {

    @isTest
    static void testGetRecordStatus() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Producer POM record
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            Quarter__c = 'Q1',
            Compliance_Year__c = '2025',
            Acknowledgement_of_Statements__c = false
        );
        insert pom;

        // Test the controller method
        Test.startTest();
        Map<String, Object> result = ProducerPomAcknowledgeController.getRecordStatus(pom.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(true, result.get('success'), 'Should succeed');
        System.assertNotEquals(null, result.get('shouldShowPopup'), 'Should return shouldShowPopup value');
    }

    @isTest
    static void testGetRecordStatusInvalidId() {
        // Test with invalid record ID
        Test.startTest();
        Map<String, Object> result = ProducerPomAcknowledgeController.getRecordStatus('invalid');
        Test.stopTest();

        // Verify error handling
        System.assertEquals(false, result.get('success'), 'Should fail with invalid ID');
        System.assertNotEquals(null, result.get('error'), 'Should return error message');
    }

    @isTest
    static void testGetNextActions() {
        // Create test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Producer POM record
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            Quarter__c = 'Q1',
            Compliance_Year__c = '2025',
            Status__c = 'Acknowledge Market Data',
            Acknowledgement_of_Statements__c = true
        );
        insert pom;

        // Test the controller method
        Test.startTest();
        Map<String, Object> result = ProducerPomAcknowledgeController.getNextActions(pom.Id);
        Test.stopTest();

        // Verify results
        System.assertEquals(true, result.get('success'), 'Should succeed');
        System.assertNotEquals(null, result.get('isDirector'), 'Should return isDirector value');
        System.assertNotEquals(null, result.get('status'), 'Should return status');
    }
}
