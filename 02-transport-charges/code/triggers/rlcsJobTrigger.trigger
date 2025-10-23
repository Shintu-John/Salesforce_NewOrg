trigger rlcsJobTrigger on RLCS_Job__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
// Create the handler
    rlcsJobTriggerHandler handler = new rlcsJobTriggerHandler(Trigger.isExecuting, Trigger.size);

    /* Before insert */
    if (Trigger.isBefore && Trigger.isInsert) {
        handler.OnBeforeInsert(Trigger.new);
    }

    /* After insert  */
    else if (Trigger.isAfter && Trigger.isInsert) {
        handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }

    /* Before Update */
    else if (Trigger.isBefore && Trigger.isUpdate) {
        handler.OnBeforeUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }

    /* After Update */
    else if (Trigger.isAfter && Trigger.isUpdate) {
        handler.OnAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }

    /* After Delete */
    else if (Trigger.isAfter && Trigger.isDelete) {
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }
}