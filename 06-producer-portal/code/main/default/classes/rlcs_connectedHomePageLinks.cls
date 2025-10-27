public class rlcs_connectedHomePageLinks {
	@AuraEnabled(Cacheable=true)
    public static List<Producer_Placed_on_Market__c> getUpcomingDates(){
        Id userAccountId = getUserAccountId();
        if (userAccountId == null) {
            return new List<Producer_Placed_on_Market__c>();
        }
        return [Select Id, Quarter_With_Year__c, Action_Date__c
                from Producer_Placed_on_Market__c
                Where Quarter_End_Date__c > TODAY
                AND Account__c = :userAccountId
                ORDER BY Quarter_Start_Date__c ASC LIMIT 1];
    }


	@AuraEnabled(Cacheable=true)
    public static List<Producer_Placed_on_Market__c> getPastDue(){
        Id userAccountId = getUserAccountId();
        if (userAccountId == null) {
            return new List<Producer_Placed_on_Market__c>();
        }
        return [Select Id, Quarter_With_Year__c, Action_Date__c
                from Producer_Placed_on_Market__c
                Where Quarter_End_Date__c < TODAY
                AND Acknowledgement_of_Statements__c = false
                AND Account__c = :userAccountId
                ORDER BY Quarter_End_Date__c ASC];
    }

    /**
     * Helper method to get current user's Account ID
     */
    private static Id getUserAccountId() {
        try {
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
            return currentUser.Contact?.AccountId;
        } catch (Exception e) {
            System.debug('Error getting user account: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Get current user's account information including Producer Obligation Type
     * Used to determine if Reports link should be shown
     */
    @AuraEnabled(cacheable=true)
    public static AccountInfo getCurrentUserAccountInfo() {
        try {
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
            
            if (currentUser.Contact?.AccountId == null) {
                return new AccountInfo();
            }
            
            Account userAccount = [
                SELECT Id, Name, Producer_Obligation_Yype__c
                FROM Account 
                WHERE Id = :currentUser.Contact.AccountId 
                LIMIT 1
            ];
            
            return new AccountInfo(userAccount);
        } catch (Exception e) {
            System.debug('Error in getCurrentUserAccountInfo: ' + e.getMessage());
            return new AccountInfo();
        }
    }
    
    /**
     * Wrapper class for account information
     */
    public class AccountInfo {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String producerObligationType;
        @AuraEnabled public Boolean showReportsLink;
        
        public AccountInfo() {
            this.accountId = null;
            this.accountName = null;
            this.producerObligationType = null;
            this.showReportsLink = true; // Default to showing reports link
        }
        
        public AccountInfo(Account acc) {
            this.accountId = acc.Id;
            this.accountName = acc.Name;
            this.producerObligationType = acc.Producer_Obligation_Yype__c;
            // Hide reports link if Producer Obligation Type is B2B
            this.showReportsLink = acc.Producer_Obligation_Yype__c != 'B2B';
        }
    }
}