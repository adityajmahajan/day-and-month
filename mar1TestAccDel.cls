//Test Class
@isTest
public class TestFeb21Morning {

    @TestSetup
    public static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    @isTest
    static void testErrorBeforeDeleting() {
        Account acc =[SELECT Id FROM Account WHERE Name = 'Test Account'];
        Database.DeleteResult deleteResult = Database.delete(acc, false);
    
        System.assertEquals(false, deleteResult.isSuccess(), 'Delete operation should not be successful');
        System.assertEquals('Account cannot be deleted', deleteResult.getErrors()[0].getMessage(), 'Unexpected error message');

    }
}


//Trigger
trigger AccountTrigger on Account (after insert,before delete) {
if(Trigger.isBefore && Trigger.isDelete){
        feb21morning.errorBeforeDeleting(Trigger.oldMap);
    }
}

//Class inside Trigger
public with sharing class feb21morning {
    /*10.) Write a trigger in which if an account that has related contacts and the user tries to delete that account it throws you an error "Account cannot be deleted". */
    public static void errorBeforeDeleting(Map<Id,Account> oldAccMap) {

        // Gather IDs of Accounts being deleted
        Set<Id> accountIds = oldAccMap.keySet();
        
        // Query all Contacts related to these Accounts
        List<Contact> relatedContacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds];
        
        // Check if any Accounts have related Contacts
        for (Account acc : oldAccMap.values()) {
            for (Contact con : relatedContacts) {
                if (acc.Id == con.AccountId) {
                    acc.addError('Account cannot be deleted'); // throw error to prevent deletion
                    break; // because even if 1 contact present, stop checking further
                }
            }                                 
        }
    }
    public static void updateAcc(List<Contact> newConList, List<Contact> oldConList, String triggerOperationType){
        /* Write a logic to update the count of number of contacts on Account. whenever a  contact is created or updated or deleted.*/

        // Collect Account IDs related to the Contacts being modified
        Set<Id> accountIds = new Set<Id>();
        if(newConList!=	null){
        	for (Contact c : newConList) {
            	accountIds.add(c.AccountId);
        	}
        }

        if (triggerOperationType=='AFTER_DELETE') {
            for (Contact c : oldConList) {
                accountIds.add(c.AccountId);
            }
        }
        // Query for related Accounts, including their Contacts
        List<Account> accountsToUpdate = [SELECT Id, No_of_Contacts__c, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accountIds];
        // Update the number of Contacts for each Account
        for (Account acc : accountsToUpdate) {
            acc.No_of_Contacts__c = acc.Contacts.size();
        }
        // Update the Accounts in bulk
        update accountsToUpdate;
    }
}
