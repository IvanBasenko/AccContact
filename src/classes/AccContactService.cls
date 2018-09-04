/**
 * Created by Ivan Basenko on 03.09.2018.
 */

public with sharing class AccContactService {
    public static void insertAccCon(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        Map<Id, List<AccountContact__c>> contactMap = getContactsAccountContactsByIdContact(accountContacts, createdAccCon);
        for (AccountContact__c accountContact : accountContacts) {
            if (!createdAccCon.contains(accountContact)) {
                accountContact.isPrimary__c = true;
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
    }

    public static void updateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        List<AccountContact__c> changedList = new List<AccountContact__c>();
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
            } else if (accountContact.isPrimary__c == false && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == true) {
                changedList.add(accountContact);
            }
        }
        if (changedList.size() > 0) {
            changeIsPrimaryByDate(changedList);
        }
        update updatedList;
    }
    private static Map<Id, List<AccountContact__c>> getContactsAccountContactsByIdContact(List<AccountContact__c> accountContacts, List<AccountContact__c> createdAccCon) {
        Map<Id, List<AccountContact__c>> contactMap = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            contactMap.put(accountContact.Contact__c, new List<AccountContact__c>());
            for (AccountContact__c oldAccountContact : createdAccCon) {
                if (oldAccountContact.Contact__c == accountContact.Contact__c) {
                    contactMap.get(oldAccountContact.Contact__c).add(oldAccountContact);
                }

            }
        }
        return contactMap;
    }

    public static void onDelete(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> deletedListWhereIsPrimaryTrue = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c == true) {
                deletedListWhereIsPrimaryTrue.add(accountContact);
            }
        }
        changeIsPrimaryByDate(deletedListWhereIsPrimaryTrue);
    }

    private static void changeIsPrimaryByDate(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        Map<Id, List<AccountContact__c>> contactMap = getContactsAccountContactsByIdContact(accountContacts, createdAccCon);
        for (Id contactId : contactMap.keySet()) {
            for (AccountContact__c accountContact : accountContacts) {
                if (contactMap.get(contactId).get(0).Id == accountContact.Id) {
                    contactMap.get(contactId).remove(0);
                }
                AccountContact__c newAccountContact = contactMap.get(contactId).get(0);
                newAccountContact.isPrimary__c = true;
                updatedList.add(newAccountContact);
            }
        }
        update updatedList;
    }

    private static List<AccountContact__c> getAllAccountContactsForContactId(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> allAccountContacts = [SELECT Id,isPrimary__c, CreatedDate, Account__c, Contact__c FROM AccountContact__c WHERE Contact__r.Id IN :getContactIds(accountContacts) ORDER BY CreatedDate];
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