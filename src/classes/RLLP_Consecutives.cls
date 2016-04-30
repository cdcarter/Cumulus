public class RLLP_Consecutives implements Database.Batchable<Account> {
    private RLLP_Rollups_API RollupUTIL;
    private ApexPages.StandardSetController ssc;
    
    public RLLP_Consecutives() {}
    
    public Iterable<Account> start(Database.BatchableContext bc) {
        return [SELECT Id FROM Account];
    }
    public void finish(Database.BatchableContext bc) {
        
    }
    public void execute(Database.BatchableContext bc, List<Account> accs) {
        this.RollupUTIL = new RLLP_Rollups_API();
        List<Account> accountsToUpdateWithRollups = new List<Account>();
        
        Set<Id> accountIdsInBatch = new Set<Id>();
        for(Account a : accs) {accountIdsInBatch.add(a.Id);}
        RollupUTIL = new RLLP_Rollups_API();
        Set<Id> rtIdsToExclude = RollupUTIL.getRecordTypesToExcludeAccts();
        Date sinceDate = UTIL_CustomSettings_API.getHouseholdsSettings().Donated_Since_Date__c;
        Date sincePeriodDate = RollupUTIL.getStartOfNFiscalYearsAgo((Integer)UTIL_CustomSettings_API.getHouseholdsSettings().Number_of_Periods_Rollup__c);
        
        //let's just brute force this first by writing different SOQL queries for each option
        
        String periodFunction;
        if(RollupUTIL.getUseFiscalYear()) {
            periodFunction = 'FISCAL_YEAR';
        } else {
            periodFunction = 'CALENDAR_YEAR';
        }
        
        //first, number of years given, ever ever
        String numberOfYearsQuery = 'SELECT Count(Id),AccountId,{0}(CloseDate) yr FROM Opportunity' +
            ' WHERE RecordTypeID NOT IN :rtIdsToExclude' +
            ' AND AccountId IN :accountIdsInBatch' +
            ' GROUP BY AccountId,{0}(CloseDate)' +
            ' ORDER BY {0}(CloseDate) DESC';
        List<AggregateResult> arNumberOfYears = Database.query(String.format(numberOfYearsQuery,new List<String>{periodFunction}));
        Map<Id,List<AggregateResult>> accountIdToARNumberOfYears = new Map<Id,List<AggregateResult>>();
        for(AggregateResult ar : arNumberOfYears){
            Id accountId = (Id)ar.get('AccountId');
            if(accountIdToARNumberOfYears.containsKey(accountId)) {
                accountIdToARNumberOfYears.get(accountId).add(ar);
            } else {
                accountIdToARNumberOfYears.put(accountId, new List<AggregateResult>{ar});
            }
        }
        
        String numberOfYearsSincePeriodDateQuery = 'SELECT Count(Id),AccountId,{0}(CloseDate) yr FROM Opportunity' +
            ' WHERE RecordTypeID NOT IN :rtIdsToExclude' +
            ' AND AccountId IN :accountIdsInBatch' +
            ' AND CloseDate >= :sincePeriodDate' + 
            ' GROUP BY AccountId,{0}(CloseDate)' +
            ' ORDER BY {0}(CloseDate) DESC';
        
        
        List<AggregateResult> numberOfYearsSincePeriodDate = Database.query(String.format(numberOfYearsSincePeriodDateQuery,new List<String>{periodFunction}));
        Map<Id,List<AggregateResult>> accountIdToARNumberOfYearsSincePeriodDate = new Map<Id,List<AggregateResult>>();
        for(AggregateResult ar : numberOfYearsSincePeriodDate){
            Id accountId = (Id)ar.get('AccountId');
            if(accountIdToARNumberOfYearsSincePeriodDate.containsKey(accountId)) {
                accountIdToARNumberOfYearsSincePeriodDate.get(accountId).add(ar);
            } else {
                accountIdToARNumberOfYearsSincePeriodDate.put(accountId, new List<AggregateResult>{ar});
            }
        }
        
        String numberOfYearsSinceDateQuery = 'SELECT Count(Id),AccountId,{0}(CloseDate) yr FROM Opportunity' +
            ' WHERE RecordTypeID NOT IN :rtIdsToExclude' +
            ' AND AccountId IN :accountIdsInBatch' +
            ' AND CloseDate >= :sinceDate' + 
            ' GROUP BY AccountId,{0}(CloseDate)' +
            ' ORDER BY {0}(CloseDate) DESC';
        
        
        List<AggregateResult> arNumberOfYearsSince = Database.query(String.format(numberOfYearsSinceDateQuery,new List<String>{periodFunction}));
        Map<Id,List<AggregateResult>> accountIdToARNumberOfYearsSince = new Map<Id,List<AggregateResult>>();
        for(AggregateResult ar : arNumberOfYearsSince){
            Id accountId = (Id)ar.get('AccountId');
            if(accountIdToARNumberOfYearsSince.containsKey(accountId)) {
                accountIdToARNumberOfYearsSince.get(accountId).add(ar);
            } else {
                accountIdToARNumberOfYearsSince.put(accountId, new List<AggregateResult>{ar});
            }
        }
        
        
        for(Account a : accs) {
            Account resultAccount = new Account(Id=a.Id, Number_of_Consecutive_Years_RLLP__c = 0);
            
            if(accountIdToARNumberOfYears.containsKey(a.Id)) {
                resultAccount.Number_of_Years_RLLP__c = accountIdToARNumberOfYears.get(a.Id).size();
                resultAccount.Number_of_Consecutive_Years_RLLP__c = calculateConsecutiveYears(accountIdToARNumberOfYears.get(a.Id));
            } else {
                resultAccount.Number_of_Years_RLLP__c = 0;
            }
            
            if(accountIdToARNumberOfYearsSince.containsKey(a.Id)) {
                resultAccount.Number_of_Years_Donated_Since_Y_RLLP__c  = accountIdToARNumberOfYearsSince.get(a.Id).size();
            } else {
                resultAccount.Number_of_Years_Donated_Since_Y_RLLP__c  = 0;
            }
            
            if(accountIdToARNumberOfYearsSincePeriodDate.containsKey(a.Id)) {
                resultAccount.Number_Of_Years_In_RLLP__c  = accountIdToARNumberOfYearsSincePeriodDate.get(a.Id).size();
            } else {
                resultAccount.Number_Of_Years_In_RLLP__c  = 0;
            }
            
            accountsToUpdateWithRollups.add(resultAccount);
        }
        
        update accountsToUpdateWithRollups;
    }
    
    private Integer calculateConsecutiveYears(List<AggregateResult> ars) {
        Integer result = 0;
        Integer mostRecentYear = (Integer)ars[0].get('yr');
        
        // fail fast if there's no streak
        if(ars.size() == 0) {return result;}
        if(mostRecentYear != RollupUTIL.getCurrentFY() && mostRecentYear != (RollupUTIL.getCurrentFY()-1)) {
            return result;
        }
        
        if(mostRecentYear == RollupUTIL.getCurrentFY()) {
            ars.remove(0);
            result += 1;
        }
        
        Integer compareYear = RollupUTIL.getCurrentFY()-1;
        for(AggregateResult yearAR : ars ) {
            Integer arYear = (Integer)yearAR.get('yr');
            if(compareYear == arYear) {
                result += 1;
            } else {
                break;
            }
            
            compareYear -= 1;
        }
        
        return result;
    }
    
    public RLLP_Consecutives(ApexPages.StandardSetController ssc) {this.ssc=ssc;}
    public PageReference listButtonBatch() { 
        List<SObject> allRecords;
        if(!this.ssc.getCompleteResult()) {
            throw new RLLP_ConsecutivesException('This list view has too many records to query');
        }
        if(this.ssc.getSelected().size() > 0){
            allRecords = this.ssc.getSelected();
        } else {
            allRecords = new List<SObject>();
            Integer startingPage = this.ssc.getPageNumber();
            allRecords.addAll(this.ssc.getRecords());
            
            while(this.ssc.getHasPrevious()) {
                this.ssc.previous();
                allRecords.addAll(this.ssc.getRecords());
            }
            
            this.ssc.setPageNumber(startingPage);
            while(this.ssc.getHasNext()) {
                this.ssc.next();
                allRecords.addAll(this.ssc.getRecords());
            }
        }
        List<Account> accountsToRun = new List<Account>();
        for(SObject o : allRecords) {accountsToRun.add(new Account(id=o.Id));}
        this.execute(null,accountsToRun);
        
        return new PageReference('/'+Account.SObjectType.getDescribe().getKeyPrefix());
    }
    
    public class RLLP_ConsecutivesException extends Exception {}
}