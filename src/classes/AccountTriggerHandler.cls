/**
 * Created by Ivan Basenko on 06.09.2018.
 */

public with sharing class AccountTriggerHandler {
    AccContactService accContactService = new AccContactService();
    public void onBeforeDeleteAccount(List<Account> accounts) {
        accContactService.onDeleteAccount(accounts);
    }
}