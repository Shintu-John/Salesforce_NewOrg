trigger RLCS_ChargeTrigger on RLCS_Charge__c (after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            RollupService.handleInsertUpdate(Trigger.new, null, 'RLCS_Charge__c','Invoice__c','Sales_Invoice__c','Sales_Price__c','Total_Net__c');
        }else if(Trigger.isUpdate){
            RollupService.handleInsertUpdate(Trigger.new, Trigger.oldMap, 'RLCS_Charge__c','Invoice__c','Sales_Invoice__c','Sales_Price__c','Total_Net__c');
        }else if(Trigger.isDelete){
            RollupService.handleDelete(Trigger.old,'RLCS_Charge__c','Invoice__c','Sales_Invoice__c','Sales_Price__c','Total_Net__c');
        }else if(Trigger.isUnDelete){
            RollupService.handleInsertUpdate(Trigger.new, null, 'RLCS_Charge__c','Invoice__c','Sales_Invoice__c','Sales_Price__c','Total_Net__c');
        }
    }
}