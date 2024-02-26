// trigger to update Count_of_Opportunities__c on User sObject and Account sObject

trigger opportunityTrigger on Opportunity (after insert, after update, after delete) {
/*
    //for synchronus method
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            feb26MorningSync.updateOpportunityCountOnAccount(Trigger.new);
            feb26MorningSync.updateOpportunityCountOnUser(Trigger.new);
        } else if (Trigger.isDelete) {
            feb26MorningSync.updateOpportunityCountOnAccount(Trigger.old);
            feb26MorningSync.updateOpportunityCountOnUser(Trigger.old);
        }
    }
*/
// For Future Method
    Set<Id> accountIds = new Set<Id>();
    Set<Id> userIds = new Set<Id>();

    
    if (Trigger.isDelete) {
        // Call the future method to update counts after deletion
        for (Opportunity opp : Trigger.old) {
            accountIds.add(opp.AccountId);
            userIds.add(opp.OwnerId);
        }
    
        feb26MorningFuture.updateOpportunityCount(accountIds, userIds);
    } 
    else {
        // Call the future method to update counts after insert or update
        for (Opportunity opp : Trigger.new) {
            accountIds.add(opp.AccountId);
            userIds.add(opp.OwnerId);
        }
        feb26MorningFuture.updateOpportunityCount(accountIds, userIds);
    }
}
----------------------------------------------------------------------

//this is the class with SYNCHRONOUS methods 

public with sharing class feb26MorningSync {
    public static void updateOpportunityCountOnAccount(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        List<Account> accountsToUpdate = new List<Account>();
// opportunity count soql is outside the for loop as per best practices 
        Integer opportunityCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :accountIds];
        for (Id accountId : accountIds) {
            accountsToUpdate.add(new Account(Id = accountId, Count_of_Opportunities__c = opportunityCount));
        }
        update accountsToUpdate;
    }

    public static void updateOpportunityCountOnUser(List<Opportunity> opportunities) {
        Set<Id> userIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
                userIds.add(opp.OwnerId);
        }
        List<User> usersToUpdate = new List<User>();
// opportunity count soql is outside the for loop as per best practices 
        Integer opportunityCount = [SELECT COUNT() FROM Opportunity WHERE OwnerId = :userIds];
        for (Id userId : userIds) {
            
            usersToUpdate.add(new User(Id = userId, Count_of_Opportunities__c = opportunityCount));
        }
        update usersToUpdate;
    }
}

-----------------------------------------------------------

// this is the class with one ASYNCHRONOUS future method called once in the trigger

public with sharing class feb26MorningFuture {
    @future
    public static void updateOpportunityCount(Set<Id> accountIds, Set<Id> userIds) {
        // Aggregate query to get counts for each Account inserted, updated or deleted
        Map<Id, Integer> accountCounts = new Map<Id, Integer>();
        List<AggregateResult> accResult = Database.query('SELECT AccountId, COUNT(Id) cnt FROM Opportunity WHERE AccountId IN :accountIds GROUP BY AccountId');
        for (AggregateResult aggregate : accResult) {
            accountCounts.put((Id) aggregate.get('AccountId'), (Integer) aggregate.get('cnt'));
        }

        // Aggregate query to get counts for each User inserted, updated or deleted
        Map<Id, Integer> userCounts = new Map<Id, Integer>();
        List<AggregateResult> userResult = Database.query('SELECT OwnerId, COUNT(Id) cnt FROM Opportunity WHERE OwnerId IN :userIds GROUP BY OwnerId');
        for (AggregateResult aggregate : userResult) {
            userCounts.put((Id) aggregate.get('OwnerId'), (Integer) aggregate.get('cnt'));
        }

        // Update Account and User records
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : accountIds) {
            Account accToUpdate = new Account(Id = accId);
    
            if (accountCounts.containsKey(accId)) {
                accToUpdate.Count_Of_opportunities__c = accountCounts.get(accId);
            } 
            else {
                accToUpdate.Count_Of_opportunities__c = 0;
            }
        accountsToUpdate.add(accToUpdate);
        }
        update accountsToUpdate;

        List<User> usersToUpdate = new List<User>();
        for (Id userId : userIds) {
            User userToUpdate = new User(Id = userId);
    
            if (userCounts.containsKey(userId)) {
                userToUpdate.Count_Of_opportunities__c = userCounts.get(userId);
            }
            else {
                userToUpdate.Count_Of_opportunities__c = 0;
            }
            usersToUpdate.add(userToUpdate);        }
        update usersToUpdate;
    }
}