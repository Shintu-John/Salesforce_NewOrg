public without sharing class ProducerPomPortalSharing {

    /**
     * Shares Producer Placed on Market records with portal users based on Account matching
     * Called from trigger or batch job
     */
    public static void shareRecordsWithPortalUsers(Set<Id> pomIds) {
        // Get all Producer POM records with their Account
        Map<Id, Producer_Placed_on_Market__c> pomRecords = new Map<Id, Producer_Placed_on_Market__c>([
            SELECT Id, Account__c
            FROM Producer_Placed_on_Market__c
            WHERE Id IN :pomIds AND Account__c != null
        ]);

        if (pomRecords.isEmpty()) {
            return;
        }

        // Get all Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Producer_Placed_on_Market__c pom : pomRecords.values()) {
            accountIds.add(pom.Account__c);
        }

        // Get all portal users for these accounts
        List<User> portalUsers = [
            SELECT Id, AccountId, Profile.Name
            FROM User
            WHERE AccountId IN :accountIds
            AND IsActive = true
            AND (Profile.Name LIKE '%Producer%' OR Profile.UserType = 'CustomerSuccess')
        ];

        // Create map of Account to Portal Users
        Map<Id, List<User>> accountToUsers = new Map<Id, List<User>>();
        for (User u : portalUsers) {
            if (!accountToUsers.containsKey(u.AccountId)) {
                accountToUsers.put(u.AccountId, new List<User>());
            }
            accountToUsers.get(u.AccountId).add(u);
        }

        // Get existing shares to avoid duplicates
        List<Producer_Placed_on_Market__Share> existingShares = [
            SELECT Id, ParentId, UserOrGroupId
            FROM Producer_Placed_on_Market__Share
            WHERE ParentId IN :pomIds
            AND RowCause = 'Manual'
        ];

        Set<String> existingShareKeys = new Set<String>();
        for (Producer_Placed_on_Market__Share share : existingShares) {
            existingShareKeys.add(share.ParentId + '-' + share.UserOrGroupId);
        }

        // Create shares
        List<Producer_Placed_on_Market__Share> sharesToInsert = new List<Producer_Placed_on_Market__Share>();

        for (Producer_Placed_on_Market__c pom : pomRecords.values()) {
            if (accountToUsers.containsKey(pom.Account__c)) {
                for (User portalUser : accountToUsers.get(pom.Account__c)) {
                    String shareKey = pom.Id + '-' + portalUser.Id;

                    // Only create share if it doesn't exist
                    if (!existingShareKeys.contains(shareKey)) {
                        Producer_Placed_on_Market__Share share = new Producer_Placed_on_Market__Share();
                        share.ParentId = pom.Id;
                        share.UserOrGroupId = portalUser.Id;
                        share.AccessLevel = 'Edit';
                        share.RowCause = 'Manual';
                        sharesToInsert.add(share);
                    }
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            try {
                insert sharesToInsert;
                System.debug('ProducerPomPortalSharing: Created ' + sharesToInsert.size() + ' share records');
            } catch (Exception e) {
                System.debug('ProducerPomPortalSharing: Error creating shares - ' + e.getMessage());
            }
        }
    }

    /**
     * Batch job to share all existing records with portal users
     */
    public static void shareAllRecordsWithPortalUsers() {
        List<Producer_Placed_on_Market__c> allRecords = [
            SELECT Id
            FROM Producer_Placed_on_Market__c
            WHERE Account__c != null
            LIMIT 10000
        ];

        Set<Id> recordIds = new Set<Id>();
        for (Producer_Placed_on_Market__c pom : allRecords) {
            recordIds.add(pom.Id);
        }

        if (!recordIds.isEmpty()) {
            shareRecordsWithPortalUsers(recordIds);
        }
    }
}
