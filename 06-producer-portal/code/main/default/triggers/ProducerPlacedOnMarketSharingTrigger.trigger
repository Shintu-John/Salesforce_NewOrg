/**
 * @description Automatically share Producer_Placed_on_Market__c records with Account portal users
 *              and with directors when Status = 'Pending Director Review'
 * @created 2025-10-21
 * @revised 2025-10-27 - Added director sharing logic
 */
trigger ProducerPlacedOnMarketSharingTrigger on Producer_Placed_on_Market__c (after insert, after update) {

    List<Producer_Placed_on_Market__c> recordsToShare = new List<Producer_Placed_on_Market__c>();

    if (Trigger.isInsert) {
        recordsToShare = Trigger.new;
    } else if (Trigger.isUpdate) {
        // Re-share if Account__c or Status__c changed
        for (Producer_Placed_on_Market__c record : Trigger.new) {
            Producer_Placed_on_Market__c oldRecord = Trigger.oldMap.get(record.Id);

            if (record.Account__c != oldRecord.Account__c ||
                record.Status__c != oldRecord.Status__c) {
                recordsToShare.add(record);
            }
        }
    }

    if (!recordsToShare.isEmpty()) {
        ProducerSharingHelper.sharePlacedOnMarkets(recordsToShare);
    }
}