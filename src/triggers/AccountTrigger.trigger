/**
 * Created by Ivan Basenko on 06.09.2018.
 */

trigger AccountTrigger on Account (before delete) {
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isDelete) {
            accountTriggerHandler.onBeforeDeleteAccount(Trigger.old);
        }
    }

}