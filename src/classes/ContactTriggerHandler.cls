/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class ContactTriggerHandler {
    AccContactService accContactService = new AccContactService();
    public void onBeforeDeleteContacts(List<Contact> contacts) {
        accContactService.onDeleteContact(contacts);
    }
}