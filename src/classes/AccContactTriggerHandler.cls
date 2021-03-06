/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class AccContactTriggerHandler {
    AccContactPrimaryChangeService accContactService;

    public AccContactTriggerHandler() {
        accContactService = new AccContactPrimaryChangeService();
    }

    public void onBeforeInsertAccContact(List<AccountContact__c> accountContacts) {
        accContactService.beforeIsPrimaryValidator(accountContacts);
    }

    public void onBeforeDeleteAccContact(List<AccountContact__c> accountContacts) {
        accContactService.onDeleteAccContact(accountContacts);
    }

    public void onAfterUpdateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldAccountContactsByIds) {
        accContactService.updateAccContact(accountContacts, oldAccountContactsByIds);
    }

    public void onBeforeUpdateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldAccountContactsByIds) {
        accContactService.onBeforeUpdateAccContact(accountContacts, oldAccountContactsByIds);
    }
}