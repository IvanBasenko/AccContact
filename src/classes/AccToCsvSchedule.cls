/**
 * Created by Basenko on 03.10.2018.
 */

public with sharing class AccToCsvSchedule implements Schedulable{
    public void execute(SchedulableContext context){
        Database.executeBatch(new ImportAccountsToCSVFileBatch());
    }
}