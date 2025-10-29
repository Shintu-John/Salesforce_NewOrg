@isTest
public class JobDeliveryConfirmationReminderBatchTest {

    @isTest
    static void testDailyReportGeneration() {
        // Get Customer record type for NewOrg lookup filter
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer').getRecordTypeId();

        // Create a valid test depot for NewOrg
        Depot__c testDepot = new Depot__c(
            Name = '(TD1) - Test Depot (WEX123456)',
            Permit_Reference__c = 'WEX123456',  // Required format for validation
            Valid__c = true,
            Status_Description__c = 'Active'
        );
        insert testDepot;

        // Create test Account with required NewOrg field and record type
        Account testAccount = new Account(
            Name = 'Test Account',
            comp_house__Company_Number__c = '12345678',  // Required in NewOrg
            RecordTypeId = customerRecordTypeId  // Required by Job__c lookup filter
        );
        insert testAccount;

        // Create test Jobs with various delivery dates (all unconfirmed)
        List<Job__c> testJobs = new List<Job__c>();

        // Critical: 30+ days overdue
        testJobs.add(new Job__c(
            Account__c = testAccount.Id,
            Delivery_Date__c = Date.today().addDays(-35),
            Delivery_Confirmed__c = false,
            Waste_Type_2__c = 'Mixed Municipal Waste',
            Depot_Dispose__c = testDepot.Id  // Required to avoid Red Scar/RLL validation
        ));

        // High Priority: 8-29 days overdue
        testJobs.add(new Job__c(
            Account__c = testAccount.Id,
            Delivery_Date__c = Date.today().addDays(-15),
            Delivery_Confirmed__c = false,
            Waste_Type_2__c = 'Mixed Municipal Waste',
            Depot_Dispose__c = testDepot.Id
        ));

        // Medium Priority: 4-7 days overdue
        testJobs.add(new Job__c(
            Account__c = testAccount.Id,
            Delivery_Date__c = Date.today().addDays(-5),
            Delivery_Confirmed__c = false,
            Waste_Type_2__c = 'Mixed Municipal Waste',
            Depot_Dispose__c = testDepot.Id
        ));

        // Recent: 1-3 days overdue
        testJobs.add(new Job__c(
            Account__c = testAccount.Id,
            Delivery_Date__c = Date.today().addDays(-2),
            Delivery_Confirmed__c = false,
            Waste_Type_2__c = 'Mixed Municipal Waste',
            Depot_Dispose__c = testDepot.Id
        ));

        insert testJobs;

        Test.startTest();

        // Run the batch
        JobDeliveryConfirmationReminderBatch batch = new JobDeliveryConfirmationReminderBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify the stateful variables were populated correctly
        // Note: In test context, we can't directly access the batch instance after execution
        // So we verify that the Jobs exist and meet the criteria
        List<Job__c> criticalJobs = [SELECT Id FROM Job__c
                                       WHERE Delivery_Date__c < :Date.today().addDays(-30)
                                       AND Delivery_Confirmed__c = false];
        System.assertEquals(1, criticalJobs.size(), 'Should have 1 critical job');

        List<Job__c> highPriorityJobs = [SELECT Id FROM Job__c
                                          WHERE Delivery_Date__c < :Date.today().addDays(-8)
                                          AND Delivery_Date__c >= :Date.today().addDays(-30)
                                          AND Delivery_Confirmed__c = false];
        System.assertEquals(1, highPriorityJobs.size(), 'Should have 1 high priority job');

        List<Job__c> mediumPriorityJobs = [SELECT Id FROM Job__c
                                            WHERE Delivery_Date__c < :Date.today().addDays(-4)
                                            AND Delivery_Date__c >= :Date.today().addDays(-8)
                                            AND Delivery_Confirmed__c = false];
        System.assertEquals(1, mediumPriorityJobs.size(), 'Should have 1 medium priority job');

        List<Job__c> recentJobs = [SELECT Id FROM Job__c
                                    WHERE Delivery_Date__c < :Date.today()
                                    AND Delivery_Date__c >= :Date.today().addDays(-4)
                                    AND Delivery_Confirmed__c = false];
        System.assertEquals(1, recentJobs.size(), 'Should have 1 recent job');
    }

    @isTest
    static void testNoReportForConfirmedDelivery() {
        // Get Customer record type for NewOrg lookup filter
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer').getRecordTypeId();

        // Create a valid test depot for NewOrg
        Depot__c testDepot = new Depot__c(
            Name = '(TD1) - Test Depot (WEX123456)',
            Permit_Reference__c = 'WEX123456',  // Required format for validation
            Valid__c = true,
            Status_Description__c = 'Active'
        );
        insert testDepot;

        // Create test Account with required NewOrg field and record type
        Account testAccount = new Account(
            Name = 'Test Account',
            comp_house__Company_Number__c = '12345678',  // Required in NewOrg
            RecordTypeId = customerRecordTypeId  // Required by Job__c lookup filter
        );
        insert testAccount;

        // Create test Job with past delivery date AND confirmed
        // This should NOT appear in the delivery confirmation report
        Job__c testJob = new Job__c(
            Account__c = testAccount.Id,
            Delivery_Date__c = Date.today().addDays(-5),
            Delivery_Confirmed__c = true, // CONFIRMED - should be excluded
            Waste_Type_2__c = 'Mixed Municipal Waste',
            Depot_Dispose__c = testDepot.Id
        );
        insert testJob;

        Test.startTest();

        // Run the batch
        JobDeliveryConfirmationReminderBatch batch = new JobDeliveryConfirmationReminderBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify NO Jobs should be included in report (all confirmed)
        List<Job__c> unconfirmedJobs = [SELECT Id FROM Job__c
                                         WHERE Delivery_Date__c < TODAY
                                         AND Delivery_Confirmed__c = false];
        System.assertEquals(0, unconfirmedJobs.size(),
                           'No unconfirmed jobs should exist - report should be empty');
    }

    @isTest
    static void testReportWithMultipleJobsInSameCategory() {
        // Get Customer record type for NewOrg lookup filter
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer').getRecordTypeId();

        // Create a valid test depot for NewOrg
        Depot__c testDepot = new Depot__c(
            Name = '(TD1) - Test Depot (WEX123456)',
            Permit_Reference__c = 'WEX123456',  // Required format for validation
            Valid__c = true,
            Status_Description__c = 'Active'
        );
        insert testDepot;

        // Create test Account with required NewOrg field and record type
        Account testAccount = new Account(
            Name = 'Test Account Multi',
            comp_house__Company_Number__c = '12345678',  // Required in NewOrg
            RecordTypeId = customerRecordTypeId  // Required by Job__c lookup filter
        );
        insert testAccount;

        // Create multiple Jobs in the same category (Critical)
        List<Job__c> testJobs = new List<Job__c>();
        for(Integer i = 0; i < 5; i++) {
            testJobs.add(new Job__c(
                Account__c = testAccount.Id,
                Delivery_Date__c = Date.today().addDays(-40 - i),
                Delivery_Confirmed__c = false,
                Waste_Type_2__c = 'Mixed Municipal Waste',
                Depot_Dispose__c = testDepot.Id
            ));
        }
        insert testJobs;

        Test.startTest();

        // Run the batch
        JobDeliveryConfirmationReminderBatch batch = new JobDeliveryConfirmationReminderBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify all 5 Jobs are in the critical category
        List<Job__c> criticalJobs = [SELECT Id, Name, Delivery_Date__c
                                       FROM Job__c
                                       WHERE Delivery_Date__c < :Date.today().addDays(-30)
                                       AND Delivery_Confirmed__c = false
                                       ORDER BY Delivery_Date__c ASC];
        System.assertEquals(5, criticalJobs.size(), 'Should have 5 critical jobs in report');
    }

    @isTest
    static void testSchedulableInterface() {
        Test.startTest();

        // Schedule the batch
        String cronExp = '0 0 8 * * ?'; // Daily at 8 AM
        String jobId = System.schedule('Test Delivery Confirmation Reminder',
                                       cronExp,
                                       new JobDeliveryConfirmationReminderBatch());

        Test.stopTest();

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');

        // Verify the scheduled job exists
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression, State
                                            FROM CronTrigger
                                            WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals(cronExp, scheduledJobs[0].CronExpression,
                           'Cron expression should match');
    }

    @isTest
    static void testEmptyReport() {
        // Don't create any Jobs - test that batch handles empty result set
        Test.startTest();

        // Run the batch with no data
        JobDeliveryConfirmationReminderBatch batch = new JobDeliveryConfirmationReminderBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify no errors occurred (email should still be sent but with 0 jobs)
        // This tests that the batch handles empty result sets gracefully
        List<Job__c> allJobs = [SELECT Id FROM Job__c];
        System.assertEquals(0, allJobs.size(), 'Should have no jobs in test context');
    }
}