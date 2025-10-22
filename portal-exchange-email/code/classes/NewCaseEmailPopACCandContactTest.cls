@isTest
public class NewCaseEmailPopACCandContactTest {
    @isTest
    static void testUpdateCaseWhenTotalEmailsEqualsOneWithMultipleRecipients() {
        // Create a test Account
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        // Create a test Contact linked to the test Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName='Doe',
            Email='johndoe@recyclinglives-services.com', // Email domain that triggers the handler
            AccountId=testAccount.Id
        );
        insert testContact;

        // Create another Contact to simulate multiple recipients scenario
        Contact secondTestContact = new Contact(
            FirstName= 'TTest',
            LastName='Smith',
            Email='janedoe@example.com',
            AccountId=testAccount.Id
        );
        insert secondTestContact;

        // Create a test Case with initial values
        Case testCase = new Case(
            Status='Pending External',
            Origin='Email',
            Total_Emails_Against_Case__c = 0 // Set initial emails count to 0
        );
        insert testCase;

        // Create a test EmailMessage linked to the test Case with the correct 'From' address
        EmailMessage testEmailMessage = new EmailMessage(
            FromAddress='noreply@recyclinglives-services.com', // From address containing the specified domain
            ToAddress='johndoe@recyclinglives-services.com;janedoe@example.com', // Multiple recipients
            RelatedToId=testCase.Id,
            Subject='Urgent: Review Needed',
            HtmlBody='<p>This is a test email message.</p>',
            Status='0' // Assuming '0' is a valid status for EmailMessage in your org
        );
        insert testEmailMessage;

        // Use Test.startTest() and Test.stopTest to ensure governor limits are properly recorded
        Test.startTest();
        testCase.Total_Emails_Against_Case__c = 1; // Trigger the logic by updating this field
        update testCase;
        Test.stopTest();

        // Re-query the case to verify changes
        testCase = [SELECT ContactId, AccountId, Subject, Most_Recent_Message__c FROM Case WHERE Id=:testCase.Id];

        // Assertions to verify that the case is correctly updated with only the first contact and the Most_Recent_Message__c field
        System.assertEquals(testContact.Id, testCase.ContactId, 'The Contact ID should be correctly updated to the first recipient.');
        System.assertEquals(testAccount.Id, testCase.AccountId, 'The Account ID should be correctly updated to the first recipient’s account.');
        System.assertEquals('Urgent: Review Needed', testCase.Subject, 'The Subject of the Case should be updated to match the Email Message.');
        System.assertNotEquals(null, testCase.Most_Recent_Message__c, 'The Most Recent Message field should be populated.');
        System.assertEquals(Date.today(), testCase.Most_Recent_Message__c.date(), 'The Most Recent Message field should have today’s date.');
    }
}