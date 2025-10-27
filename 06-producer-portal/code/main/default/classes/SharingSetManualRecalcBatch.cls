/**
 * Manual Sharing Set Recalculation Batch
 *
 * This batch job manually creates share records for Producer Portal Login users
 * to work around the Sharing Set not auto-recalculating after profile additions.
 *
 * Mimics the behavior of Producer_Standard_User sharing set which grants Edit access
 * to Producer_Placed_on_Market__c records where Account__c matches user's Account.
 */
global class SharingSetManualRecalcBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all active Login profile users
        return Database.getQueryLocator([
            SELECT Id, Contact.AccountId
            FROM User
            WHERE IsActive = true
            AND Contact.AccountId != null
            AND (Profile.Name = 'Producer Director User Login'
                 OR Profile.Name = 'Producer Standard User Login')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<User> users) {
        List<Producer_Placed_on_Market__Share> sharesToCreate = new List<Producer_Placed_on_Market__Share>();

        // Get Account IDs for these users
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> accountToUserMap = new Map<Id, Id>(); // Account ID -> User ID

        for(User u : users) {
            accountIds.add(u.Contact.AccountId);
            accountToUserMap.put(u.Contact.AccountId, u.Id);
        }

        // Get all POM records for these accounts
        List<Producer_Placed_on_Market__c> pomRecords = [
            SELECT Id, Account__c
            FROM Producer_Placed_on_Market__c
            WHERE Account__c IN :accountIds
        ];

        // Get existing shares to avoid duplicates
        Set<String> existingShareKeys = new Set<String>();
        for(Producer_Placed_on_Market__Share existingShare : [
            SELECT ParentId, UserOrGroupId
            FROM Producer_Placed_on_Market__Share
            WHERE UserOrGroupId IN :users
        ]) {
            existingShareKeys.add('' + existingShare.ParentId + '_' + existingShare.UserOrGroupId);
        }

        // Create shares for matching accounts
        for(Producer_Placed_on_Market__c pom : pomRecords) {
            Id userId = accountToUserMap.get(pom.Account__c);
            if(userId != null) {
                String shareKey = '' + pom.Id + '_' + userId;

                // Only create if doesn't already exist
                if(!existingShareKeys.contains(shareKey)) {
                    Producer_Placed_on_Market__Share newShare = new Producer_Placed_on_Market__Share();
                    newShare.ParentId = pom.Id;
                    newShare.UserOrGroupId = userId;
                    newShare.AccessLevel = 'Edit';
                    newShare.RowCause = Schema.Producer_Placed_on_Market__Share.RowCause.Manual;

                    sharesToCreate.add(newShare);
                }
            }
        }

        if(!sharesToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(sharesToCreate, false);

            // Log any errors
            Integer successCount = 0;
            Integer errorCount = 0;
            for(Database.SaveResult sr : results) {
                if(sr.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error creating share: ' + err.getMessage());
                    }
                }
            }

            System.debug('Created ' + successCount + ' new shares, ' + errorCount + ' errors');
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Sharing Set manual recalculation complete');
    }
}
