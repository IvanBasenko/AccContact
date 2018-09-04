/**
 * Created by Ivan Basenko on 03.09.2018.
 */

public with sharing class AccContactService {
    public static void insertAccCon(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        Map<Id, List<AccountContact__c>> contactMap = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            contactMap.put(accountContact.Contact__c, new List<AccountContact__c>());
            if (!createdAccCon.contains(accountContact)) {
                accountContact.isPrimary__c = true;
            }
            for (AccountContact__c oldAccountContact : createdAccCon) {
                if (oldAccountContact.Contact__c == accountContact.Contact__c) {
                    contactMap.get(oldAccountContact.Contact__c).add(oldAccountContact);
                }

            }
        }

        for (Id contactId : contactMap.keySet()) {
            for (AccountContact__c oldAccountContact : contactMap.get(contactId)) {
                for (AccountContact__c accountContact : accountContacts) {
                    if (contactMap.get(contactId).size() > 0 && oldAccountContact.Contact__c == accountContact.Contact__c) {
                        accountContact.isPrimary__c = false;
                    } else if (contactMap.get(contactId).size() == 0) {
                        accountContact.isPrimary__c = true;
                    }
                }
            }
        }
        System.debug(accountContacts);
    }
    public static void updateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c == true && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == false) {
                for (AccountContact__c createdAccountContact : createdAccCon) {
                    if (createdAccountContact.Contact__c == accountContact.Contact__c && createdAccountContact.Id != accountContact.Id) {
                        AccountContact__c newAccountContact = new AccountContact__c();
                        newAccountContact.Id = createdAccountContact.Id;
                        newAccountContact.Contact__c = createdAccountContact.Contact__c;
                        newAccountContact.Account__c = createdAccountContact.Account__c;
                        newAccountContact.isPrimary__c = false;
                        updatedList.add(newAccountContact);
                    }
                }
            }
        }
        update updatedList;
    }
    private static List<AccountContact__c> getAllAccountContactsForContactId(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> allAccountContacts = [SELECT Id,isPrimary__c,Account__r.Name,Contact__r.Name, Account__c,Contact__c FROM AccountContact__c WHERE Contact__r.Id IN :getContactIds(accountContacts)];
        return allAccountContacts;

    }
    private static Set<Id> getContactIds(List<AccountContact__c> accountContacts) {
        Set<Id> contactIds = new Set<Id>();
        for (AccountContact__c accountContact : accountContacts) {
            contactIds.add(accountContact.Contact__c);
        }
        return contactIds;
    }
}