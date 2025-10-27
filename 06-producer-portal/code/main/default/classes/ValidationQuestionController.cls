public without sharing class ValidationQuestionController {
    @AuraEnabled
    public static List<Validation_Question__c> getQuestions(Id recordId) {
        return [
            SELECT Id, Name, Answer__c, Producer_Placed_on_Market__c, Answered__c 
            FROM Validation_Question__c 
            WHERE Answered__c = false AND Producer_Placed_on_Market__c = :recordId and Producer_Placed_on_Market__c != null
        ];
    }

    @AuraEnabled
    public static void saveAnswers(List<Validation_Question__c> questions) {
        try {
            update questions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}