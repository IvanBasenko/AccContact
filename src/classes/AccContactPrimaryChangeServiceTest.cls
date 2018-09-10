/**
 * Created by Ivan Basenko on 10.09.2018.
 */

@IsTest
private class AccContactPrimaryChangeServiceTest {

    @IsTest static void testInsert() {
        List<Account> accounts = TestDataFactory.generateAccounts(100);
        List<Contact> contacts = TestDataFactory.generateContacts(100);
        List<AccountContact__c> accountContacts = new List<AccountContact__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            AccountContact__c accountContact = new AccountContact__c();
            accountContact.Account__c = accounts[i].Id;
            if (i == 50) {
                accountContact.Contact__c = contacts[i - 2].Id;
            } else
                    accountContact.Contact__c = contacts[i].Id;
            accountContacts.add(accountContact);
        }
        insert accountContacts;

        System.assertEquals(99, [SELECT COUNT() FROM AccountContact__c WHERE isPrimary__c = true]);
    }
    @isTest
    static void TestUpdateAccountContactsWithIsPrimaryFieldTrue() {
        List<AccountContact__c>firstHalfListAccountContactsForInsert = new List<AccountContact__c>();
        List<AccountContact__c>secondHalfListAccountContactsForInsert = new List<AccountContact__c>();
        List<Account> accounts = TestDataFactory.generateAccounts(200);
        List<Contact> contacts = TestDataFactory.generateContacts(200);
        List<AccountContact__c> accountContactsForUpdate = new List<AccountContact__c>();
        for (Integer i = 0; i < 200; i++) {
            AccountContact__c accountContact = new AccountContact__c();
            if (i < 100) {
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i].Id;
                firstHalfListAccountContactsForInsert.add(accountContact);
            } else {
                accountContact.Account__c = accounts[i].Id;
                accountContact.Contact__c = contacts[i - 100].Id;
                accountContact.isPrimary__c = true;
                secondHalfListAccountContactsForInsert.add(accountContact);
                accountContactsForUpdate.add(accountContact);
            }
        }
        insert firstHalfListAccountContactsForInsert;
        insert secondHalfListAccountContactsForInsert;
        Test.startTest();
        update accountContactsForUpdate;
        Test.stopTest();
        List<AccountContact__c> verifyAccountContacts = [SELECT Id, isPrimary__c FROM AccountContact__c];
        for (Integer i = 0; i < verifyAccountContacts.size(); i++) {
            if (i < 100) {
                System.assertEquals(false, verifyAccountContacts[i].isPrimary__c);
            } else {
                System.assertEquals(true, verifyAccountContacts[i].isPrimary__c);
            }
        }
    }
    @IsTest static void TestUpdateAccContactWhereChangeContact() {

    }
}