trigger UpdateEmailCountOnCase on EmailMessage (after insert, after delete) {
    Set<Id> caseIds = new Set<Id>();

    // Collect Case IDs from the inserted or deleted emails
    for (EmailMessage message : Trigger.isDelete ? Trigger.old : Trigger.new) {
        if (message.ParentId != null) {
            caseIds.add(message.ParentId);
        }
    }

    // Prepare to update Cases
    Map<Id, Case> casesToUpdate = new Map<Id, Case>([SELECT Id, Total_Emails_Against_Case__c FROM Case WHERE Id IN :caseIds]);

    // Aggregate query to count emails per case
    List<AggregateResult> emailCounts = [SELECT ParentId, Count(Id) emailCount FROM EmailMessage WHERE ParentId IN :caseIds GROUP BY ParentId];

    // Map counts back to cases
    for (AggregateResult aggResult : emailCounts) {
        Id caseId = (Id)aggResult.get('ParentId');
        Integer count = (Integer)aggResult.get('emailCount');
        if (casesToUpdate.containsKey(caseId)) {
            casesToUpdate.get(caseId).Total_Emails_Against_Case__c = count;
        }
    }

    // Update cases in database
    update casesToUpdate.values();
}