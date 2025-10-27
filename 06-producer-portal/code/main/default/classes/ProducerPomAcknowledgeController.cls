public with sharing class ProducerPomAcknowledgeController {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getRecordStatus(String recordId) {
        try {
            System.debug('ProducerPomAcknowledgeController: Querying record: ' + recordId);

            Producer_Placed_on_Market__c pom = [
                SELECT Id,
                       Show_Acknowledgement_PopUp__c
                FROM Producer_Placed_on_Market__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            System.debug('ProducerPomAcknowledgeController: Record found - Show_Acknowledgement_PopUp__c: ' + pom.Show_Acknowledgement_PopUp__c);

            return new Map<String, Object>{
                'shouldShowPopup' => pom.Show_Acknowledgement_PopUp__c,
                'success' => true
            };
        } catch (Exception e) {
            System.debug('ProducerPomAcknowledgeController: ERROR - ' + e.getMessage());
            System.debug('ProducerPomAcknowledgeController: Stack trace - ' + e.getStackTraceString());

            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getNextActions(String recordId) {
        try {
            // Get current user's profile name
            User currentUser = [SELECT Id, Profile_Name__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // Check if user is a Director
            Boolean isDirector = currentUser.Profile_Name__c == 'Producer Director User' ||
                                currentUser.Profile_Name__c == 'Producer Director User Login' ||
                                currentUser.Profile_Name__c == 'RLCC - RLCS Producer Director';

            // Get record details
            Producer_Placed_on_Market__c pom = [
                SELECT Id,
                       Status__c,
                       Show_Acknowledgement_PopUp__c,
                       Acknowledgement_of_Statements__c,
                       Is_Record_Signed__c,
                       Unanswered_Questions__c
                FROM Producer_Placed_on_Market__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            // Determine if signature should be shown
            // Check conditions manually since formula field doesn't update dynamically
            Boolean shouldShowSignature = false;
            if (isDirector &&
                pom.Show_Acknowledgement_PopUp__c == false &&
                (pom.Unanswered_Questions__c == null || pom.Unanswered_Questions__c == 0) &&
                pom.Status__c == 'Pending Director Review' &&
                pom.Is_Record_Signed__c == false) {
                shouldShowSignature = true;
            }

            return new Map<String, Object>{
                'isDirector' => isDirector,
                'shouldShowSignature' => shouldShowSignature,
                'unansweredQuestions' => pom.Unanswered_Questions__c,
                'showAcknowledgement' => pom.Show_Acknowledgement_PopUp__c,
                'status' => pom.Status__c,
                'isSigned' => pom.Is_Record_Signed__c,
                'success' => true
            };
        } catch (Exception e) {
            System.debug('ProducerPomAcknowledgeController: ERROR in getNextActions - ' + e.getMessage());
            return new Map<String, Object>{
                'success' => false,
                'error' => e.getMessage()
            };
        }
    }
}
