@isTest public class RLLP_Consecutives_TEST {
    @testSetup private static void insertTestAccountsAndOpps() {
        Account a1 = new Account(Name='Test1');
        Account a2 = new Account(Name='Test2');
        Account a3 = new Account(Name='Test3');
        insert new List<Account> {a1,a2,a3};
        
        Opportunity o1 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2011, 03, 20),StageName = 'Closed Won');
        Opportunity o2 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2012, 03, 20),StageName = 'Closed Won');
        Opportunity o3 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2013, 03, 20),StageName = 'Closed Won');
        Opportunity o4 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2014, 03, 20),StageName = 'Closed Won');
        Opportunity o5 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2015, 03, 20),StageName = 'Closed Won');
        Opportunity o6 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2015, 04, 20),StageName = 'Closed Won');
        Opportunity o7 = new Opportunity(Name='Blah',AccountId=a1.Id,CloseDate = Date.newInstance(2016, 03, 20),StageName = 'Closed Won');
            
        Opportunity o8 = new Opportunity(Name='Blah',AccountId=a2.Id,CloseDate = Date.newInstance(2011, 03, 20),StageName = 'Closed Won');

        insert new List<Opportunity>{o1,o2,o3,o4,o5,o6,o7,o8};

    }
    
    @isTest private static void test_simpleRollup() {
        Test.startTest();
        Database.executeBatch(new RLLP_Consecutives());
        Test.stopTest();
        
        Account a1 = [SELECT Id,Number_of_Years_RLLP__c,Number_of_Consecutive_Years_RLLP__c FROM Account WHERE Name='Test1'];
        Account a2 = [SELECT Id,Number_of_Years_RLLP__c,Number_of_Consecutive_Years_RLLP__c FROM Account WHERE Name='Test2'];
        System.assertEquals(6, a1.Number_of_Years_RLLP__c);
        System.assertEquals(6, a1.Number_of_Consecutive_Years_RLLP__c);
        System.assertEquals(1, a2.Number_of_Years_RLLP__c);
        System.assertEquals(0, a2.Number_of_Consecutive_Years_RLLP__c);

    }
}