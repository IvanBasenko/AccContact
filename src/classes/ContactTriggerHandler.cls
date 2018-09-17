/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class ContactTriggerHandler {
    AccContactPrimaryChangeService accContactService;

    public ContactTriggerHandler() {
        accContactService = new AccContactPrimaryChangeService();
    }

    public void onBeforeDeleteContacts(List<Contact> contacts) {
        accContactService.onDeleteContact(contacts);
    }
}