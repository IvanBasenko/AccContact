/**
 * Created by Ivan Basenko on 02.10.2018.
 */

public with sharing class ImportAccountsToCSVFileBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String stringToCsv;
    private String query;
    private final static String FILE_NAME = 'accounts.csv';

    public ImportAccountsToCSVFileBatch() {
        stringToCsv = '';
        query = 'SELECT ContentDownloadUrl FROM ContentDistribution ';
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
            String contentDocumentId = previousContentVersion.get(0).ContentDocumentId;
            file.ContentDocumentId = contentDocumentId;
            query += 'WHERE ContentDocumentId =: contentDocumentId';
        }
        insert file;
        if (previousContentVersion.isEmpty()) {
            String insertedFileId = file.Id;
            ContentDistribution contentDistribution = new ContentDistribution(
                    Name = FILE_NAME.substring(0, 8),
                    ContentVersionId = insertedFileId,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = false,
                    PreferencesPasswordRequired = false,
                    PreferencesAllowOriginalDownload = true
            );
            query += 'WHERE ContentVersionId =: insertedFileId';
            insert contentDistribution;
        }
        List<ContentDistribution> url = Database.query(query);
        System.enqueueJob(new RESTCalloutToAnotherOrg(url[0].ContentDownloadUrl));
    }
}
