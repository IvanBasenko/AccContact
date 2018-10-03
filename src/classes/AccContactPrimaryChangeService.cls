/**
* Created by Ivan Basenko on 03.09.2018.
*/

public with sharing class AccContactPrimaryChangeService {

    public void beforeIsPrimaryValidator(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> accContactListWithIsPrimaryFalse = new List<AccountContact__c>();
        Map<Id, AccountContact__c> accContactByContactIds = new Map<Id, AccountContact__c>();
        Map<Id, List<AccountContact__c>> accContactListByContactIds = getAccContactListByContactIdsMapWithoutInserted(accountContacts);
        for (AccountContact__c accountContact : accountContacts) {
            List<AccountContact__c> accountContactsList = accContactListByContactIds.get(accountContact.Contact__c);
            if (!accountContactsList.isEmpty()) {
                accContactListWithIsPrimaryFalse.add(accountContact);
            }
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
            if (accountContactsByContactId.size() > 1) {
                beforeUpdateAccContactCheckedList.addAll(accountContactsByContactId);
            }
        }
        beforeIsPrimaryValidator(beforeUpdateAccContactCheckedList);
    }

    public void updateAccContact(List<AccountContact__c> accountContacts, Map<Id, AccountContact__c> oldMapAccountContacts) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
        Map<Id, List<AccountContact__c>> updatedMap = new Map<Id, List<AccountContact__c>>();
        List<AccountContact__c> oldAccContacts = new List<AccountContact__c>();
        List<AccountContact__c> changedAccContactsAfterChangeContact = new List<AccountContact__c>();
        List<AccountContact__c> changedList = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            AccountContact__c oldAccountContact = oldMapAccountContacts.get(accountContact.Id);
            if (accountContact.Account__c != oldAccountContact.Account__c) {
                continue;
            }

            if (whenContactChange(accountContact, oldAccountContact)) {
                oldAccContacts.add(oldAccountContact);
                continue;
            }

            if (whenNewTrueAndOldFalse(accountContact, oldAccountContact)) {
                updatedMap.put(accountContact.Contact__c, new List<AccountContact__c>(setCreatedContactIsPrimaryFalse(createdAccCon, accountContact)));
            }

            if (whenNewFalseAndOldTrue(accountContact, oldAccountContact)) {
                changedList.add(accountContact);
            }

        }
        changedAccContactsAfterChangeContact = getAllAccountContactsForContactId(oldAccContacts);
        if (!changedAccContactsAfterChangeContact.isEmpty()) {
            changeIsPrimaryByDateWithSelected(changedAccContactsAfterChangeContact);
        }

        if (!changedList.isEmpty()) {
            changeIsPrimaryByDateWithoutSelected(changedList);
        }

        List<AccountContact__c> updatedList = new List<AccountContact__c>();
        for (List<AccountContact__c> accountContactsForUpdate : updatedMap.values()) {
            updatedList.addAll(accountContactsForUpdate);
        }
        update updatedList;
    }

    public void onDeleteAccContact(List<AccountContact__c> accountContacts) {
        List<AccountContact__c> deletedListWhereIsPrimaryTrue = new List<AccountContact__c>();
        for (AccountContact__c accountContact : accountContacts) {
            if (accountContact.isPrimary__c) {
                deletedListWhereIsPrimaryTrue.add(accountContact);
            }
        }
        changeIsPrimaryByDateWithoutSelected(deletedListWhereIsPrimaryTrue);
    }

    public void onDeleteAccount(List<Account> accounts) {
        delete [SELECT Id FROM AccountContact__c WHERE Account__c IN :getIds(accounts, 'Id')];
    }

    public void onDeleteContact(List<Contact> contacts) {
        delete [SELECT Id FROM AccountContact__c WHERE Contact__c IN :getIds(contacts, 'Id')];
    }

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMap(List<AccountContact__c> accountContacts, Boolean flag) {
        List<AccountContact__c> createdAccCon = getAllAccountContactsForContactId(accountContacts);
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

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMapWithoutInserted(List<AccountContact__c> accountContacts) {
        return getAccContactListByContactIdsMap(accountContacts, true);
    }

    private Map<Id, List<AccountContact__c>> getAccContactListByContactIdsMapWithInserted(List<AccountContact__c> accountContacts) {
        return getAccContactListByContactIdsMap(accountContacts, false);
    }

    private void changeIsPrimaryByDateWithoutSelected(List<AccountContact__c> accountContacts) {
        Map<Id, List<AccountContact__c>> accContactListByContactIds = getAccContactListByContactIdsMapWithoutInserted(accountContacts);
        changeIsPrimaryByDate(accountContacts, accContactListByContactIds);
    }

    private void changeIsPrimaryByDateWithSelected(List<AccountContact__c> accountContacts) {
        Map<Id, List<AccountContact__c>> accContactListByContactIds = getAccContactListByContactIdsMapWithInserted(accountContacts);
        changeIsPrimaryByDate(accountContacts, accContactListByContactIds);
    }

    private void changeIsPrimaryByDate(List<AccountContact__c> accountContacts, Map<Id, List<AccountContact__c>> accContactListByContactIds) {
        Set<AccountContact__c> setToUpdate = new Set<AccountContact__c>();
        Map<Id, List<AccountContact__c>> accountContactMapForLastRecord = getAccContactListByContactIdsMapWithInserted(accountContacts);
        for (Id contactId : accContactListByContactIds.keySet()) {
            List<AccountContact__c> accountContactsList = accContactListByContactIds.get(contactId);
            AccountContact__c newAccountContact = null;
            if (!accountContactsList.isEmpty()) {
                newAccountContact = accountContactsList.get(0);
            } else {
                newAccountContact = accountContactMapForLastRecord.get(contactId).get(0);
            }
            newAccountContact.isPrimary__c = true;
            setToUpdate.add(newAccountContact);
        }
        update new List<AccountContact__c>(setToUpdate);
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

    private Boolean whenContactChange(AccountContact__c accountContact, AccountContact__c oldAccountContact) {
        return accountContact.Contact__c != oldAccountContact.Contact__c
                && (!accountContact.isPrimary__c && oldAccountContact.isPrimary__c == true
                || accountContact.isPrimary__c == true && oldAccountContact.isPrimary__c == true);
    }

    private Boolean whenNewTrueAndOldFalse(AccountContact__c accountContact, AccountContact__c oldAccountContact) {
        return accountContact.isPrimary__c && !oldAccountContact.isPrimary__c;
    }

    private Boolean whenNewFalseAndOldTrue(AccountContact__c accountContact, AccountContact__c oldAccountContact) {
        return !accountContact.isPrimary__c && oldAccountContact.isPrimary__c;
    }

    private List<AccountContact__c> setCreatedContactIsPrimaryFalse(List<AccountContact__c> createdAccountContacts, AccountContact__c accountContact) {
        List<AccountContact__c> accountContacts = new List<AccountContact__c>();
        for (AccountContact__c createdAccountContact : createdAccountContacts) {
            if (createdAccountContact.Contact__c == accountContact.Contact__c && createdAccountContact.Id != accountContact.Id) {
                createdAccountContact.isPrimary__c = false;
                accountContacts.add(createdAccountContact);
            }
        }
        return accountContacts;
    }

    private Set<Id> getIds(List<SObject> sObjects, String variable) {
        Set<Id> ids = new Set<Id>();
        for (SObject obj : sObjects) {
            ids.add((Id) obj.get(variable));
        }
        return ids;
    }
}