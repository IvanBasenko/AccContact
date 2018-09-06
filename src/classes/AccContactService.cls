/**
 * Created by Ivan Basenko on 03.09.2018.
 */

public with sharing class AccContactService {
    public void insertAccContact(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = this.getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> accContactListWithIsPrimaryFalse = new List<AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactListByContactIds = this.getAccContactListByContactIdsMap(accountContacts, createdAccCon);
        for (AccountContact__c accountContact : accountContacts) {
            List<AccountContact__c> accountContactsList = accContactListByContactIds.get(accountContact.Contact__c);
            if (!accountContactsList.isEmpty() && accountContactsList.get(0).Contact__c == accountContact.Contact__c) {
                accountContact.isPrimary__c = false;
                accContactListWithIsPrimaryFalse.add(accountContact);
            }
        }

        for (AccountContact__c accountContact : accountContacts) {
            if (!accContactListWithIsPrimaryFalse.contains(accountContact)) {
                accountContact.isPrimary__c = true;
            }
        }
    }

    public void updateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> createdAccCon = this.getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        List<AccountContact__c> changedList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c == true && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == false) {
                for (AccountContact__c createdAccountContact : createdAccCon) {
                    if (createdAccountContact.Contact__c == accountContact.Contact__c && createdAccountContact.Id != accountContact.Id) {
                        createdAccountContact.isPrimary__c = false;
                        updatedList.add(createdAccountContact);
                    }
                }
            } else if (accountContact.isPrimary__c == false && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == true) {
                changedList.add(accountContact);
            }
        }
        if (changedList.size() > 0) {
            this.changeIsPrimaryByDate(changedList);
        }
        update updatedList;
    }

    public void onDeleteAccContact(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> deletedListWhereIsPrimaryTrue = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c == true) {
                deletedListWhereIsPrimaryTrue.add(accountContact);
            }
        }
        this.changeIsPrimaryByDate(deletedListWhereIsPrimaryTrue);
    }

    public void onDeleteAccount(List<Account> accounts) {
        delete [SELECT Id FROM AccountContact__c WHERE Account__c IN :getIds(accounts, 'Id')];
    }

    public void onDeleteContact(List<Contact> contacts) {
        delete [SELECT Id FROM AccountContact__c WHERE Contact__c IN :getIds(contacts, 'Id')];
    }

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMap(List<AccountContact__c> accountContacts, List<AccountContact__c> createdAccCon) {
        Map<Id, List<AccountContact__c>> accContactListByContactIds = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            accContactListByContactIds.put(accountContact.Contact__c, new List<AccountContact__c>());
            for (AccountContact__c oldAccountContact : createdAccCon) {
                if (oldAccountContact.Contact__c == accountContact.Contact__c && accountContact.Id != oldAccountContact.Id) {
                    accContactListByContactIds.get(oldAccountContact.Contact__c).add(oldAccountContact);
                }

            }
        }
        return accContactListByContactIds;
    }

    private void changeIsPrimaryByDate(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        Set<AccountContact__c> updatedSet = new Set<AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactListByContactIds = getAccContactListByContactIdsMap(accountContacts, createdAccCon);
        for (Id contactId : accContactListByContactIds.keySet()) {
            if (accContactListByContactIds.get(contactId).size() > 0) {
                for (AccountContact__c accountContact : accountContacts) {
                    AccountContact__c newAccountContact = accContactListByContactIds.get(contactId).get(0);
                    newAccountContact.isPrimary__c = true;
                    updatedSet.add(newAccountContact);
                }
            }
        }
        List<AccountContact__c> updatedList = new List<AccountContact__c>(updatedSet);
        update updatedList;
    }

    private List<AccountContact__c> getAllAccountContactsForContactId(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> allAccountContacts = [SELECT Id, isPrimary__c, CreatedDate, Account__c, Contact__c FROM AccountContact__c WHERE Contact__r.Id IN :getIds(accountContacts, 'Contact__c') ORDER BY CreatedDate];
        return allAccountContacts;

    }

    private Set<Id> getIds(List<SObject> sObjects, String variable) {
        Set<Id> ids = new Set<Id>();
        for (SObject obj : sObjects) {
            ids.add((Id) obj.get(variable));
        }
        return ids;
    }
}