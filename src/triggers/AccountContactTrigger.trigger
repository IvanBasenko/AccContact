/**
 * Created by Ivan Basenko on 03.09.2018.
 */

trigger AccountContactTrigger on AccountContact__c (before insert, before delete, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccContactService.insertAccCon(Trigger.new);
        } else if (Trigger.isDelete) {
            AccContactService.onDelete(Trigger.old);
        }

    } else if (Trigger.isAfter) {
        if (CheckRecursive.runOnce()) {
            if (Trigger.isUpdate) {
                AccContactService.updateAccContact(Trigger.new, Trigger.oldMap);
            }
        }
    }

}