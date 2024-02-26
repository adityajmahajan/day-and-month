//1.) When ever a case is created with origin as email then set status as new and Priority as Medium.


trigger ContactTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            System.debug('After Insert: Trigger.new Values: ' + Trigger.new);
            caseTriggerHelperClass.caseFieldUpdate(Trigger.new);
        }
    }
}

public with sharing class caseTriggerHelperClass {
    public caseFieldUpdate(List<Case> caseList) {
        for(Case c : CaseList){
            if(c.origin = 'email'){
                c.Priority = 'Medium';
                c.Status = 'New';
            }
        }
    }
}

//2.) When ever Lead is created with LeadSource as Web then give rating as cold otherwise hot.

trigger LeadTrigger on Lead (before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            System.debug('After Insert: Trigger.new Values: ' + Trigger.new);
            leadTriggerHelper.leadFieldUpdate(Trigger.new);
        }
    }
}

public with sharing class leadTriggerHelper {
    public static void leadFieldUpdate(List<Lead> leadList) {
        for(Lead l : leadList){
            if(l.LeadSource=='Web'){
                l.Rating='cold';
            }
            else {
                l.Rating='hot';
            }
        }
    }
}

//3.) Whenever New Account Record is created then needs to create associated Contact Record automatically.

trigger AccountTrigger on Account (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            System.debug('After Insert: Trigger.new Values: ' + Trigger.new);
            AccountCreateChildContactTriggerHelper.createChildContact(Trigger.new);
        }
    }
}

public with sharing class AccountCreateChildContactTriggerHelper {
    public static void createChildContact(List<Account> accList) {
        for(Account a : accList){
            Contact c = new Contact(LastName = 'Trigger Generated '+Math.random()*100, AccountId = a.Id);
            insert c;
        }
    }
}