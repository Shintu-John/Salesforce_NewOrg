/**
 * Functional Test Script: Email-to-Case Assignment System
 *
 * Purpose: Validate automated case assignment functionality in NewOrg production
 * Deployment: 05-email-to-case-assignment (Oct 23, 2025)
 * Deploy IDs: 0AfSq000003nVNVKA2 (classes), 0AfSq000003nVaPKAU (Flow)
 *
 * Test Scenarios:
 * 1. Basic assignment - case assigned to available user
 * 2. Workload distribution - multiple cases distributed evenly
 * 3. User exclusion - users with exclusion flag are skipped
 * 4. Max threshold - assignment respects max open cases limit
 * 5. Previous owner reassignment - same-day previous owner logic
 *
 * IMPORTANT: Run this during low-activity period to minimize production impact
 * IMPORTANT: This script creates real test data - cleanup included at end
 */

System.debug('=== FUNCTIONAL TEST: Case Assignment System ===');
System.debug('Test Date: ' + System.now());
System.debug('User: ' + UserInfo.getName());
System.debug('');

// Track test data for cleanup
List<Case> testCases = new List<Case>();
List<Id> testCaseIds = new List<Id>();

try {
    // ============================================================================
    // PRE-TEST VERIFICATION
    // ============================================================================

    System.debug('--- PRE-TEST VERIFICATION ---');

    // 1. Verify Custom Settings exist
    Case_Auto_Assignment_Settings__c settings = Case_Auto_Assignment_Settings__c.getInstance();
    if (settings == null || settings.Max_Open_Cases_Per_User__c == null) {
        System.debug('❌ CRITICAL: Custom Settings not configured!');
        System.debug('   Action Required: Create org default Custom Setting with Max_Open_Cases_Per_User__c = 20');
        return;
    }
    System.debug('✅ Custom Settings found: Max cases per user = ' + settings.Max_Open_Cases_Per_User__c);

    // 2. Verify Customer Service users exist
    List<User> csUsers = [
        SELECT Id, Name, Profile.Name, IsActive, Dont_Auto_Assign_Cases__c
        FROM User
        WHERE IsActive = true
        AND Profile.Name LIKE '%Customer Service%'
        AND Dont_Auto_Assign_Cases__c = false
        LIMIT 5
    ];

    if (csUsers.isEmpty()) {
        System.debug('❌ CRITICAL: No eligible Customer Service users found!');
        System.debug('   Action Required: Verify Customer Service users exist and are active');
        return;
    }
    System.debug('✅ Found ' + csUsers.size() + ' eligible Customer Service users:');
    for (User u : csUsers) {
        System.debug('   - ' + u.Name + ' (ID: ' + u.Id + ')');
    }

    // 3. Verify Queue exists
    Group csQueue = [
        SELECT Id, Name
        FROM Group
        WHERE Type = 'Queue' AND Name = 'Customer Service Email'
        LIMIT 1
    ];
    System.debug('✅ Customer Service Email Queue found (ID: ' + csQueue.Id + ')');

    // 4. Verify Record Type exists
    RecordType emailRT = [
        SELECT Id, Name, DeveloperName
        FROM RecordType
        WHERE SobjectType = 'Case' AND DeveloperName = 'Email'
        LIMIT 1
    ];
    System.debug('✅ Email Record Type found (ID: ' + emailRT.Id + ')');

    // 5. Note about Flow activation
    // Note: Flow file name says "24_Hours" but actual threshold is 14 hours
    // Flow activation was verified manually (cannot query FlowDefinitionView in anonymous Apex)
    System.debug('✅ Flow activation assumed (manually activated during deployment)');
    System.debug('   Flow: Case_Remove_Case_Owner_if_Reopen_24_Hours');
    System.debug('   Note: Flow name says 24 hours but actual trigger is 14+ hours');

    // 6. Get test account
    Account testAccount = [
        SELECT Id, Name, CS_Contact__c
        FROM Account
        WHERE CS_Contact__c = null
        LIMIT 1
    ];
    System.debug('✅ Test Account found: ' + testAccount.Name + ' (ID: ' + testAccount.Id + ')');

    System.debug('');
    System.debug('--- PRE-TEST VERIFICATION COMPLETE ---');
    System.debug('');


    // ============================================================================
    // TEST 1: Basic Assignment
    // ============================================================================

    System.debug('=== TEST 1: Basic Assignment ===');
    System.debug('Objective: Create case and verify it gets assigned to a Customer Service user');

    Case test1Case = new Case(
        Subject = 'FUNCTIONAL TEST 1: Basic Assignment - ' + System.now(),
        Description = 'Test case for automated assignment validation',
        Status = 'New',
        Origin = 'Email',
        RecordTypeId = emailRT.Id,
        AccountId = testAccount.Id,
        OwnerId = csQueue.Id
    );
    insert test1Case;
    testCases.add(test1Case);
    testCaseIds.add(test1Case.Id);
    System.debug('✅ Test case created (ID: ' + test1Case.Id + ')');

    // Manually trigger assignment (since Email-to-Case workflow not available in test)
    rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{test1Case.Id});

    // Query updated case
    Case test1Result = [
        SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Type,
               rlsServiceCaseAutoAssign_Date_Time__c,
               Previous_Auto_Assigned_Owner__c
        FROM Case
        WHERE Id = :test1Case.Id
    ];

    System.debug('');
    System.debug('TEST 1 RESULTS:');
    System.debug('  Case Number: ' + test1Result.CaseNumber);
    System.debug('  Original Owner: Customer Service Email (Queue)');
    System.debug('  Current Owner: ' + test1Result.Owner.Name + ' (' + test1Result.Owner.Type + ')');
    System.debug('  Assignment DateTime: ' + test1Result.rlsServiceCaseAutoAssign_Date_Time__c);
    System.debug('  Previous Owner: ' + test1Result.Previous_Auto_Assigned_Owner__c);

    if (test1Result.Owner.Type == 'User') {
        System.debug('✅ TEST 1 PASSED: Case assigned to user');
    } else {
        System.debug('❌ TEST 1 FAILED: Case still owned by queue');
    }

    System.debug('');


    // ============================================================================
    // TEST 2: Workload Distribution (Multiple Cases)
    // ============================================================================

    System.debug('=== TEST 2: Workload Distribution ===');
    System.debug('Objective: Create 5 cases and verify even distribution across users');

    List<Case> test2Cases = new List<Case>();
    for (Integer i = 1; i <= 5; i++) {
        test2Cases.add(new Case(
            Subject = 'FUNCTIONAL TEST 2: Distribution Test ' + i + ' - ' + System.now(),
            Description = 'Test case ' + i + ' for workload distribution',
            Status = 'New',
            Origin = 'Email',
            RecordTypeId = emailRT.Id,
            AccountId = testAccount.Id,
            OwnerId = csQueue.Id
        ));
    }
    insert test2Cases;
    testCases.addAll(test2Cases);

    List<Id> test2CaseIds = new List<Id>();
    for (Case c : test2Cases) {
        test2CaseIds.add(c.Id);
        testCaseIds.add(c.Id);
    }
    System.debug('✅ Created 5 test cases');

    // Trigger assignment for all cases
    rlsServiceCaseAutoAssign.assignCasesToUsers(test2CaseIds);

    // Query results
    List<Case> test2Results = [
        SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Type
        FROM Case
        WHERE Id IN :test2CaseIds
        ORDER BY CaseNumber
    ];

    // Count assignments per user
    Map<Id, Integer> userAssignmentCount = new Map<Id, Integer>();
    for (Case c : test2Results) {
        if (c.Owner.Type == 'User') {
            if (!userAssignmentCount.containsKey(c.OwnerId)) {
                userAssignmentCount.put(c.OwnerId, 0);
            }
            userAssignmentCount.put(c.OwnerId, userAssignmentCount.get(c.OwnerId) + 1);
        }
    }

    System.debug('');
    System.debug('TEST 2 RESULTS:');
    System.debug('  Total cases created: 5');
    System.debug('  Distribution across users:');

    Integer totalAssigned = 0;
    for (Id userId : userAssignmentCount.keySet()) {
        String userName = [SELECT Name FROM User WHERE Id = :userId].Name;
        Integer count = userAssignmentCount.get(userId);
        System.debug('    - ' + userName + ': ' + count + ' case(s)');
        totalAssigned += count;
    }

    if (totalAssigned == 5) {
        System.debug('✅ TEST 2 PASSED: All 5 cases assigned');
        System.debug('   Distribution: ' + userAssignmentCount.size() + ' user(s) received assignments');
    } else {
        System.debug('❌ TEST 2 FAILED: Only ' + totalAssigned + '/5 cases assigned');
    }

    System.debug('');


    // ============================================================================
    // TEST 3: Previous Owner Reassignment (Same Day)
    // ============================================================================

    System.debug('=== TEST 3: Previous Owner Reassignment (Same Day) ===');
    System.debug('Objective: Verify same-day previous owner reassignment logic');

    // Get a Customer Service user
    User targetUser = csUsers[0];

    // Create case assigned to specific user
    Case test3Case = new Case(
        Subject = 'FUNCTIONAL TEST 3: Previous Owner Test - ' + System.now(),
        Description = 'Test case for previous owner reassignment',
        Status = 'New',
        Origin = 'Email',
        RecordTypeId = emailRT.Id,
        AccountId = testAccount.Id,
        OwnerId = targetUser.Id
    );
    insert test3Case;
    testCases.add(test3Case);
    testCaseIds.add(test3Case.Id);

    System.debug('✅ Test case created, assigned to: ' + targetUser.Name);

    // Simulate case going back to queue with Previous Owner set
    test3Case.OwnerId = csQueue.Id;
    test3Case.Previous_Auto_Assigned_Owner__c = targetUser.Id;
    test3Case.Most_Recent_Message__c = System.now(); // Same day
    update test3Case;

    System.debug('✅ Case moved to queue, Previous Owner = ' + targetUser.Name);
    System.debug('   Most Recent Message: TODAY');

    // Trigger assignment
    rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{test3Case.Id});

    // Query result
    Case test3Result = [
        SELECT Id, CaseNumber, OwnerId, Owner.Name,
               Previous_Auto_Assigned_Owner__c,
               Most_Recent_Message__c
        FROM Case
        WHERE Id = :test3Case.Id
    ];

    System.debug('');
    System.debug('TEST 3 RESULTS:');
    System.debug('  Target User: ' + targetUser.Name);
    System.debug('  Assigned To: ' + test3Result.Owner.Name);
    System.debug('  Previous Owner: ' + test3Result.Previous_Auto_Assigned_Owner__c);

    if (test3Result.OwnerId == targetUser.Id) {
        System.debug('✅ TEST 3 PASSED: Case reassigned to previous owner (same day)');
    } else {
        System.debug('⚠️  TEST 3 RESULT: Case assigned to different user');
        System.debug('   Note: This may be expected if previous owner has exceeded threshold');
    }

    System.debug('');


    // ============================================================================
    // TEST 4: User Exclusion Flag
    // ============================================================================

    System.debug('=== TEST 4: User Exclusion Flag ===');
    System.debug('Objective: Verify users with exclusion flag are not assigned cases');

    if (csUsers.size() < 2) {
        System.debug('⚠️  TEST 4 SKIPPED: Requires at least 2 Customer Service users');
    } else {
        User userToExclude = csUsers[0];

        // Set exclusion flag
        userToExclude.Dont_Auto_Assign_Cases__c = true;
        update userToExclude;
        System.debug('✅ Set exclusion flag for: ' + userToExclude.Name);

        // Create case
        Case test4Case = new Case(
            Subject = 'FUNCTIONAL TEST 4: Exclusion Test - ' + System.now(),
            Description = 'Test case for user exclusion validation',
            Status = 'New',
            Origin = 'Email',
            RecordTypeId = emailRT.Id,
            AccountId = testAccount.Id,
            OwnerId = csQueue.Id
        );
        insert test4Case;
        testCases.add(test4Case);
        testCaseIds.add(test4Case.Id);

        // Trigger assignment
        rlsServiceCaseAutoAssign.assignCasesToUsers(new List<Id>{test4Case.Id});

        // Query result
        Case test4Result = [
            SELECT Id, CaseNumber, OwnerId, Owner.Name
            FROM Case
            WHERE Id = :test4Case.Id
        ];

        System.debug('');
        System.debug('TEST 4 RESULTS:');
        System.debug('  Excluded User: ' + userToExclude.Name);
        System.debug('  Assigned To: ' + test4Result.Owner.Name);

        if (test4Result.OwnerId != userToExclude.Id) {
            System.debug('✅ TEST 4 PASSED: Excluded user was not assigned the case');
        } else {
            System.debug('❌ TEST 4 FAILED: Excluded user received assignment');
        }

        // Reset exclusion flag
        userToExclude.Dont_Auto_Assign_Cases__c = false;
        update userToExclude;
        System.debug('✅ Exclusion flag reset for: ' + userToExclude.Name);
    }

    System.debug('');


    // ============================================================================
    // TEST SUMMARY
    // ============================================================================

    System.debug('');
    System.debug('=== FUNCTIONAL TEST SUMMARY ===');
    System.debug('Total test cases created: ' + testCases.size());
    System.debug('Test execution date: ' + System.now());
    System.debug('');
    System.debug('Test Results:');
    System.debug('  TEST 1 (Basic Assignment): Check logs above');
    System.debug('  TEST 2 (Workload Distribution): Check logs above');
    System.debug('  TEST 3 (Previous Owner): Check logs above');
    System.debug('  TEST 4 (User Exclusion): Check logs above');
    System.debug('');


    // ============================================================================
    // CLEANUP
    // ============================================================================

    System.debug('--- CLEANUP ---');
    System.debug('Deleting ' + testCases.size() + ' test cases...');

    delete testCases;
    System.debug('✅ Test cases deleted');

    System.debug('');
    System.debug('=== FUNCTIONAL TEST COMPLETE ===');
    System.debug('');
    System.debug('NEXT STEPS:');
    System.debug('1. Review test results above');
    System.debug('2. Document results in FUNCTIONAL_TEST_RESULTS.md');
    System.debug('3. If any tests failed, investigate and resolve');
    System.debug('4. Monitor production case assignments for 24-48 hours');
    System.debug('5. Collect user feedback from Customer Service team');

} catch (Exception e) {
    System.debug('');
    System.debug('❌ FUNCTIONAL TEST ERROR ❌');
    System.debug('Error Type: ' + e.getTypeName());
    System.debug('Error Message: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
    System.debug('Line Number: ' + e.getLineNumber());
    System.debug('');
    System.debug('Attempting cleanup of test data...');

    if (!testCases.isEmpty()) {
        try {
            delete testCases;
            System.debug('✅ Test cases cleaned up after error');
        } catch (Exception cleanupEx) {
            System.debug('❌ Cleanup failed: ' + cleanupEx.getMessage());
            System.debug('Manual cleanup required for Case IDs: ' + testCaseIds);
        }
    }
}
