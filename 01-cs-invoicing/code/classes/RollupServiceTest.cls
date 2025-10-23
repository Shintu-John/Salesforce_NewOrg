/**
 * @description This tests the RollupService
 */

@IsTest
private class RollupServiceTest {

    private static void init() {}

    @TestSetup private static void setup() {}

    /**
     * @description Test a pretend rollup from opportunity to account
     */
    @IsTest
    static void testExampleRollup() {

        // Create an account
        Account testAccount = TestFactory.createSupplierAccount('Test Supplier','West Street','London','UB8 2LF');
        testAccount.NumberOfEmployees = 0; // Use this as a summary field
        insert testAccount;

        // Create some opportunities
        Map<String, Opportunity> opportunitiesByRef = new Map<String, Opportunity>();
        opportunitiesByRef.put('opp1',TestFactory.createOpportunity(testAccount.Id,'Opp 1',10,'Won',System.today()));
        opportunitiesByRef.put('opp2',TestFactory.createOpportunity(testAccount.Id,'Opp 2',15,'Won',System.today()));
        opportunitiesByRef.put('opp3',TestFactory.createOpportunity(testAccount.Id,'Opp 3',20,'Won',System.today()));
        opportunitiesByRef.put('opp4',TestFactory.createOpportunity(testAccount.Id,'Opp 4',25,'Won',System.today()));
        insert opportunitiesByRef.values();

        // Start the test
        Test.startTest();

        // Simulate an Insert of opportunities
        RollupService.handleInsertUpdate(opportunitiesByRef.values(), null, 'Opportunity', 'Account', 'AccountId', 'Amount', 'NumberOfEmployees');

        // Get the updated account
        Account updatedAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE Id=:testAccount.Id];
        System.assertEquals(70, updatedAccount.NumberOfEmployees);

        // Simulate a deletion
        delete opportunitiesByRef.get('opp1');
        List<Opportunity> deletedOpps = new List<Opportunity>{opportunitiesByRef.get('opp1')};

        // Check delete
        RollupService.handleDelete(deletedOpps,'Opportunity','Account','AccountId','Amount','NumberOfEmployees');

        // Get the updated account
        updatedAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE Id=:testAccount.Id];
        System.assertEquals(60, updatedAccount.NumberOfEmployees);

        // Undelete a record and try again
        undelete opportunitiesByRef.get('opp1');

        // Recalculate the undelete
        RollupService.handleDelete(deletedOpps,'Opportunity','Account','AccountId','Amount','NumberOfEmployees');

        // Stop the test
        Test.stopTest();

        // Get the updated account
        updatedAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE Id=:testAccount.Id];
        System.assertEquals(70, updatedAccount.NumberOfEmployees);

    }
}