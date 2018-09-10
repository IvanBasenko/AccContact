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
}