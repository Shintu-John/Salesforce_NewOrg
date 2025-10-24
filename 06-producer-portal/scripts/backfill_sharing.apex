/**
 * Backfill Sharing Script for Producer Portal
 *
 * Purpose: Create manual sharing records for all existing Producer data
 * Run Once: After initial deployment of sharing triggers
 *
 * Usage:
 *   sf apex run --file scripts/backfill_sharing.apex --target-org NewOrg
 *
 * Expected Results:
 *   - Processes all active portal users with Producer Standard User Login profile
 *   - Creates sharing records for all existing Producer records
 *   - Users immediately gain access to their account's historical data
 *
 * Prerequisites:
 *   - ProducerSharingHelper class deployed
 *   - UserSharingBackfillHelper class deployed
 *   - All sharing triggers deployed and active
 *
 * Created: October 24, 2025
 * Last Modified: October 24, 2025
 */

System.debug('=== Starting Producer Portal Sharing Backfill ===');
System.debug('Timestamp: ' + System.now());

// Get all active portal users with Producer Standard User Login profile
List<User> portalUsers = [
    SELECT Id, Username, Contact.Account.Name
    FROM User
    WHERE Profile.Name = 'Producer Standard User Login'
    AND IsActive = true
    AND ContactId != null
    ORDER BY Username
];

System.debug('Found ' + portalUsers.size() + ' portal users to process');

if (portalUsers.isEmpty()) {
    System.debug('ERROR: No portal users found with profile "Producer Standard User Login"');
    System.debug('Please verify:');
    System.debug('  1. Portal users exist in the org');
    System.debug('  2. Users are active');
    System.debug('  3. Users have ContactId populated');
    System.debug('  4. Profile name is exactly "Producer Standard User Login"');
} else {
    // Display users to be processed
    System.debug('Portal Users to Process:');
    for (User u : portalUsers) {
        System.debug('  - ' + u.Username + ' (Account: ' + u.Contact.Account.Name + ')');
    }

    // Extract user IDs
    List<Id> userIds = new List<Id>();
    for (User u : portalUsers) {
        userIds.add(u.Id);
    }

    // Call backfill helper
    System.debug('Calling UserSharingBackfillHelper.backfillSharingForNewUsers()...');

    try {
        UserSharingBackfillHelper.backfillSharingForNewUsers(userIds);
        System.debug('SUCCESS: Backfill completed successfully!');

        // Query sharing records created
        Integer contractShares = [
            SELECT COUNT()
            FROM Producer_Contract__Share
            WHERE RowCause = 'Manual'
        ];

        Integer obligationShares = [
            SELECT COUNT()
            FROM Producer_Obligation__Share
            WHERE RowCause = 'Manual'
        ];

        Integer pomShares = [
            SELECT COUNT()
            FROM Producer_Placed_on_Market__Share
            WHERE RowCause = 'Manual'
        ];

        System.debug('Sharing Records Created:');
        System.debug('  - Producer_Contract__Share: ' + contractShares + ' records');
        System.debug('  - Producer_Obligation__Share: ' + obligationShares + ' records');
        System.debug('  - Producer_Placed_on_Market__Share: ' + pomShares + ' records');
        System.debug('  - Total: ' + (contractShares + obligationShares + pomShares) + ' sharing records');

    } catch (Exception e) {
        System.debug('ERROR: Backfill failed!');
        System.debug('Exception Type: ' + e.getTypeName());
        System.debug('Error Message: ' + e.getMessage());
        System.debug('Stack Trace: ' + e.getStackTraceString());
        System.debug('Line Number: ' + e.getLineNumber());
    }
}

System.debug('=== Backfill Script Complete ===');
