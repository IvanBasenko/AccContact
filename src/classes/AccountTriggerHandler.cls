/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class AccountTriggerHandler {
    AccContactPrimaryChangeService accContactService;

    public AccountTriggerHandler() {
        accContactService = new AccContactPrimaryChangeService();
    }

    public void onBeforeDeleteAccount(List<Account> accounts) {
        accContactService.onDeleteAccount(accounts);
    }
}