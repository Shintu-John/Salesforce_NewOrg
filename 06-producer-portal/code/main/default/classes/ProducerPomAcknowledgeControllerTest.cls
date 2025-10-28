@isTest
private class ProducerPomAcknowledgeControllerTest {

    @isTest
    static void testGetRecordStatus() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Account',
            comp_house__Company_Number__c = '12345678'
        );
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
        Account acc = new Account(
            Name = 'Test Account',
            comp_house__Company_Number__c = '12345678'
        );
        insert acc;

        // Create test Producer POM record
        Producer_Placed_on_Market__c pom = new Producer_Placed_on_Market__c(
            Account__c = acc.Id,
            Quarter__c = 'Q1',
            Compliance_Year__c = '2025',
            Status__c = 'Acknowledge Market Data',
            Category_1_Household__c = 100,
            Category_2_Household__c = 100,
            Category_3_Household__c = 100,
            Category_4_Household__c = 100,
            Category_5_Household__c = 100,
            Category_6_Household__c = 100,
            Category_7_Household__c = 100,
            Category_8_Household__c = 100,
            Category_9_Household__c = 100,
            Category_10_Household__c = 100,
            Category_11_Household__c = 100,
            Category_12_Household__c = 100,
            Category_13_Household__c = 100,
            Category_14_Household__c = 100,
            Category_15_Household__c = 100,
            Category_1_Non_Household__c = 100,
            Category_2_Non_Household__c = 100,
            Category_3_Non_Household__c = 100,
            Category_4_Non_Household__c = 100,
            Category_5_Non_Household__c = 100,
            Category_6_Non_Household__c = 100,
            Category_7_Non_Household__c = 100,
            Category_8_Non_Household__c = 100,
            Category_9_Non_Household__c = 100,
            Category_10_Non_Household__c = 100,
            Category_11_Non_Household__c = 100,
            Category_12_Non_Household__c = 100,
            Category_13_Non_Household__c = 100,
            Category_14_Non_Household__c = 100,
            Category_15_Non_Household__c = 100,
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