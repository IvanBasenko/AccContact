/**
 * Created by Ivan Basenko on 03.09.2018.
 */

trigger AccountContactTrigger on AccountContact__c (before insert, before delete, before update, after update) {
    AccContactTriggerHandler accContactTriggerHandler = new AccContactTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            accContactTriggerHandler.onBeforeInsertAccContact(Trigger.new);
        } else if (Trigger.isDelete) {
            accContactTriggerHandler.onBeforeDeleteAccContact(Trigger.old);
        } else if (Trigger.isUpdate) {
            accContactTriggerHandler.onBeforeUpdateAccContact(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (CheckRecursive.runOnce()) {
            if (Trigger.isUpdate) {
                accContactTriggerHandler.onAfterUpdateAccContact(Trigger.new, Trigger.oldMap);
            }
        }
    }

}