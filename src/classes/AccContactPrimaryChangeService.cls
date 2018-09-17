/**
* Created by Ivan Basenko on 03.09.2018.
*/

public with sharing class AccContactPrimaryChangeService {
    public void insertAccContact(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> createdAccCon = this.getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> accContactListWithIsPrimaryFalse = new List<AccountContact__c>();
        Map<Id, AccountContact__c> accContactByContactIds = new Map<Id, AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactListByContactIds = this.getAccContactListByContactIdsMap(accountContacts, createdAccCon, true);
        for (AccountContact__c accountContact : accountContacts) {
            List<AccountContact__c> accountContactsList = accContactListByContactIds.get(accountContact.Contact__c);
            if (!accountContactsList.isEmpty()) {
                accContactListWithIsPrimaryFalse.add(accountContact);
            }
        }
        for (AccountContact__c accountContact : accountContacts) {
            accountContact.isPrimary__c = false;
            accContactByContactIds.put(accountContact.Contact__c, accountContact);
        }

        for (AccountContact__c accountContact : accContactByContactIds.values()) {
            if (!accContactListWithIsPrimaryFalse.contains(accountContact)) {
                accountContact.isPrimary__c = true;
            }
        }
    }
    public void onBeforeUpdateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> beforeUpdateAccContactCheckedList = new List<AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactByContactIds = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            AccountContact__c oldAccountContact = oldMapAccountContacts.get(accountContact.Id);
            if (accountContact.Account__c != oldAccountContact.Account__c
                    || (accountContact.isPrimary__c == oldAccountContact.isPrimary__c
                    && accountContact.Contact__c == oldAccountContact.Contact__c
                    || (accountContact.isPrimary__c != oldAccountContact.isPrimary__c
                    && accountContact.Contact__c == oldAccountContact.Contact__c))
                    ) {
                continue;
            }
            if (!accContactByContactIds.containsKey(accountContact.Contact__c)) {
                accContactByContactIds.put(accountContact.Contact__c, new List<AccountContact__c>());
                accountContact.isPrimary__c = accountContact.Contact__c != oldAccountContact.Contact__c;
            } else {
                accountContact.isPrimary__c = false;
            }
            accContactByContactIds.get(accountContact.Contact__c).add(accountContact);
            beforeUpdateAccContactCheckedList.add(accountContact);
        }
        for (List<AccountContact__c> accountContactsMap : accContactByContactIds.values()) {
            List<AccountContact__c> accountContactsByContactId = new List<AccountContact__c>(accountContactsMap);
            if (!accountContactsByContactId.isEmpty()) {
                beforeUpdateAccContactCheckedList.addAll(accountContactsByContactId);
            }
        }
        this.insertAccContact(beforeUpdateAccContactCheckedList);
    }
    public void updateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> createdAccCon = this.getAllAccountContactsForContactId(accountContacts);
        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        List<AccountContact__c> oldAccContacts = new List<AccountContact__c>();
        List<AccountContact__c> changedAccContactsAfterChangeContact = new List<AccountContact__c>();
        List<AccountContact__c> changedList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.Contact__c != oldMapAccountContacts.get(accountContact.Id).Contact__c) {
                if (accountContact.isPrimary__c == false && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == true) {
                    oldAccContacts.add(oldMapAccountContacts.get(accountContact.Id));
                }
                if (accountContact.isPrimary__c == true && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == true) {
                    oldAccContacts.add(oldMapAccountContacts.get(accountContact.Id));
                }
            } else if (accountContact.isPrimary__c == true && oldMapAccountContacts.get(accountContact.Id).isPrimary__c == false) {
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
        changedAccContactsAfterChangeContact = this.getAllAccountContactsForContactId(oldAccContacts);
        if (changedAccContactsAfterChangeContact.size() > 0) {
            this.changeIsPrimaryByDate(changedAccContactsAfterChangeContact, false);
        }
        if (changedList.size() > 0) {
            this.changeIsPrimaryByDate(changedList, true);
        }
        System.debug(updatedList);
        update updatedList;
    }

    public void onDeleteAccContact(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> deletedListWhereIsPrimaryTrue = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c) {
                deletedListWhereIsPrimaryTrue.add(accountContact);
            }
        }
        this.changeIsPrimaryByDate(deletedListWhereIsPrimaryTrue, true);
    }

    public void onDeleteAccount(List<Account> accounts) {
        delete [SELECT Id FROM AccountContact__c WHERE Account__c IN :getIds(accounts, 'Id')];
    }

    public void onDeleteContact(List<Contact> contacts) {
        delete [SELECT Id FROM AccountContact__c WHERE Contact__c IN :getIds(contacts, 'Id')];
    }

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMap(List<AccountContact__c> accountContacts, List<AccountContact__c> createdAccCon, Boolean flag) {
        Map<Id, List<AccountContact__c>> accContactListByContactIds = new Map<Id, List<AccountContact__c>>();
        for (AccountContact__c accountContact : accountContacts) {
            accContactListByContactIds.put(accountContact.Contact__c, new List<AccountContact__c>());
            for (AccountContact__c oldAccountContact : createdAccCon) {
                if (oldAccountContact.Contact__c == accountContact.Contact__c && accountContact.Id != oldAccountContact.Id && flag) {
                    accContactListByContactIds.get(oldAccountContact.Contact__c).add(oldAccountContact);
                }
                if (oldAccountContact.Contact__c == accountContact.Contact__c && !flag) {
                    accContactListByContactIds.get(oldAccountContact.Contact__c).add(oldAccountContact);
                }
            }
        }
        return accContactListByContactIds;
    }
    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMapWithoutInserted(List<AccountContact__c> accountContacts, List<AccountContact__c> createdAccCon) {
        return getAccContactListByContactIdsMap(accountContacts, createdAccCon, true);
    }

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMapWithInserted(List<AccountContact__c> accountContacts, List<AccountContact__c> createdAccCon) {
        return getAccContactListByContactIdsMap(accountContacts, createdAccCon, false);
    }
    private void changeIsPrimaryByDate(List<AccountContact__c> accountContacts, Boolean flag) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        Set<AccountContact__c> updatedSet = new Set<AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactListByContactIds = getAccContactListByContactIdsMap(accountContacts, createdAccCon, flag);
        Map<Id, List<AccountContact__c>> accountContactMapForLastRecord = getAccContactListByContactIdsMap(accountContacts, createdAccCon, false);
        for (Id contactId : accContactListByContactIds.keySet()) {
            if (accContactListByContactIds.get(contactId).size() > 0) {
                for (AccountContact__c accountContact : accountContacts) {
                    AccountContact__c newAccountContact = accContactListByContactIds.get(contactId).get(0);
                    newAccountContact.isPrimary__c = true;
                    updatedSet.add(newAccountContact);
                }
            } else if (accContactListByContactIds.get(contactId).isEmpty()) {
                AccountContact__c newAccountContact = accountContactMapForLastRecord.get(contactId).get(0);
                newAccountContact.isPrimary__c = true;
                updatedSet.add(newAccountContact);
            }
        }
        List<AccountContact__c> updatedList = new List<AccountContact__c>(updatedSet);
        update updatedList;
    }

    private List<AccountContact__c> getAllAccountContactsForContactId(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> allAccountContacts = [
                SELECT Id,
                        isPrimary__c,
                        CreatedDate,
                        Account__c,
                        Contact__c
                FROM AccountContact__c
                WHERE Contact__r.Id IN :getIds(accountContacts, 'Contact__c')
                ORDER BY CreatedDate
        ];
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