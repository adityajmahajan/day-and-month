//TEST CLASS
@isTest
private class Mar4TestBatchOppDel {
    @isTest
    static void closedLostAndInLast60Days() {
        List<Opportunity> oppCorrectList = Mar4TestDataFactoryOpportunity.createOppRecords('Closed Lost',120);
        for(Opportunity opp : oppCorrectList)
        {
            Test.setCreatedDate(opp.Id, Date.Today().addDays(-10));//Created date set to 10 days ago
        }
        Test.startTest();
        feb28MorningDeleteOldClosedLostOpp b = new feb28MorningDeleteOldClosedLostOpp();
        Database.executeBatch(b, 10); // Test with a batch size of 10
        Test.stopTest();

        List<Opportunity> successfullyDelOpps = [SELECT Id FROM Opportunity WHERE StageName='Closed Lost' AND CreatedDate>LAST_N_DAYS:60];//no records should be fetched
        System.assertEquals(0, successfullyDelOpps.size(), 'Batch class fails to delete all Closed Lost Opportunities created in the last 60 days');
    }

    @isTest
    static void allWrongCombination() {
        List<Opportunity> oppCorrectList = Mar4TestDataFactoryOpportunity.createOppRecords('Qualification',80);
        for(Opportunity opp : oppCorrectList)
        {
            Test.setCreatedDate(opp.Id, Date.Today().addDays(-100));//Created date set to 100 days ago
        }
        Test.startTest();
        feb28MorningDeleteOldClosedLostOpp b = new feb28MorningDeleteOldClosedLostOpp();
        Database.executeBatch(b, 10);
        Test.stopTest();
        List<Opportunity> successfullyDelOpps = [SELECT Id FROM Opportunity];//All opportunities
        System.assertEquals(80, successfullyDelOpps.size(), 'Batch deletes all Opportunities'); 
    }
}
//TestDataFactory
@isTest
public with sharing class Mar4TestDataFactoryOpportunity {
    @TestVisible
    static List<Opportunity> createOppRecords(String stageNameInput, Integer noOfRecords) {
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i=0; i<noOfRecords; i++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Opp Closed Lost ' + i;
            opp.CloseDate = Date.today().addDays(30+i);
            opp.Reason__c = 'Just Cause';//to satisfy validation rule
            opp.StageName = stageNameInput;
            OppList.add(opp);
        }
        insert oppList;
        return oppList;
    }
}
//Batch Class
public class feb28MorningDeleteOldClosedLostOpp implements Database.Batchable<sObject>, Database.Stateful {

    public Integer recordsProcessed = 0; 

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Name, StageName, CreatedDate FROM Opportunity WHERE CreatedDate > LAST_N_DAYS:60 AND StageName = 'Closed Lost']);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> oppList) {
        Database.DeleteResult[] deleteResults = Database.delete(oppList, false);
        for (Database.DeleteResult dr : deleteResults) {
            if (dr.isSuccess()) {
                recordsProcessed++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        String toAddresses = 'adityajmahajan@gmail.com'; 
        String subject = 'Batch Completion: Old Closed Lost Opportunities'; 
        String body = 'Batch job processed ' + recordsProcessed + ' records.';
        EmailManager.sendMail(toAddresses, subject, body);
        System.debug('Done');

    }
}
/*
feb28MorningDeleteOldClosedLostOpp b = new feb28MorningDeleteOldClosedLostOpp();
Database.executeBatch(b,10);
*/