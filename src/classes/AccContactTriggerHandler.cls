/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class AccContactTriggerHandler {
    AccContactService accContactService = new AccContactService();
    public void onBeforeInsertAccContact(List<AccountContact__c> accountContacts) {
        accContactService.insertAccCon(accountContacts);
    }

    public void onBeforeDeleteAccContact(List<AccountContact__c> accountContacts) {
        accContactService.onDelete(accountContacts);
    }

    public void onAfterUpdateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldAccountContactsByIds) {
        accContactService.updateAccContact(accountContacts, oldAccountContactsByIds);
    }
}