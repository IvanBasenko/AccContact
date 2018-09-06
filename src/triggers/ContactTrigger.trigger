/**
 * Created by Ivan Basenko on 06.09.2018.
 */

trigger ContactTrigger on Contact (before delete) {
    ContactTriggerHandler contactTriggerHandler = new ContactTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            contactTriggerHandler.onBeforeDeleteContacts(Trigger.old);
        }
    }
}