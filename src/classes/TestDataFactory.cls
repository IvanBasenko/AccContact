/**
 * Created by Ivan Basenko on 10.09.2018.
 */
@IsTest
public with sharing class TestDataFactory {
    public static List<Account> generateAccounts(Integer amount) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < amount; i++) {
            Account a = new Account(Name = 'TestAccount' + i);
            accounts.add(a);
        }
        insert accounts;
        return accounts;
    }

    public static List<Contact> generateContacts(Integer amount) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < amount; i++) {
            Contact a = new Contact(LastName = 'TestContact' + i);
            contacts.add(a);
        }
        insert contacts;
        return contacts;
    }

    public static List<AccountContact__c> generateAccContacts(List<Account> accounts, List<Contact> contacts) {
        List<AccountContact__c> accountContacts = new List<AccountContact__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Contact__c = contacts[i].Id;
            accountContact.Account__c = accounts[i].Id;
            accountContacts.add(accountContact);
        }
        accountContacts[0].Contact__c = contacts[3].Id;
        accountContacts[1].isPrimary__c = false;
        accountContacts[4].Contact__c = contacts[3].Id;
        insert accountContacts;
        return accountContacts;

    }
}