/**
 * Created by Ivan Basenko on 02.10.2018.
 */

public with sharing class ImportAccountsToCSVFileBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String stringToCsv;
    private final static String FILE_NAME = 'accounts.csv';

    ImportAccountsToCSVFileBatch() {
        stringToCsv = '';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
                SELECT Id
                        ,Name
                        ,Phone
                FROM Account
                WHERE Phone != NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account account : scope) {
            stringToCsv += account.id + ','
                    + account.name.escapeCsv() + ','
                    + account.Phone.escapeCsv() + '\n';
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<ContentVersion> previousContentVersion = [
                SELECT Id,
                        ContentDocumentId
                FROM ContentVersion
                WHERE Title = :FILE_NAME
                LIMIT 1
        ];

        ContentVersion file = new ContentVersion(
                title = FILE_NAME,
                versionData = Blob.valueOf(stringToCsv),
                pathOnClient = '/' + FILE_NAME
        );

        if (!previousContentVersion.isEmpty()) {
            file.ContentDocumentId = previousContentVersion.get(0).ContentDocumentId;
        }

        insert file;
        if (previousContentVersion.isEmpty()) {
            ContentDistribution contentDistribution = new ContentDistribution(
                    Name = FILE_NAME.substring(0, 8),
                    ContentVersionId = file.id,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = false,
                    PreferencesPasswordRequired = false,
                    PreferencesAllowOriginalDownload = true
            );
            insert contentDistribution;
        }

    }

}