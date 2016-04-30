global class RLLP_Rollups_API {
    private RLLP_OppRollup_UTIL OppRollup;
    global RLLP_Rollups_API() {
        this.OppRollup = new RLLP_OppRollup_UTIL();
    }
    
    global Integer getCurrentFY() {
        return RLLP_OppRollup_UTIL.getCurrentFY();
    }
    
    global Set<Id> getRecordTypesToExcludeAccts() {
        return RLLP_OppRollup_UTIL.recordTypesToExcludeAccts;
    }
    
    global Boolean getUseFiscalYear() {
        return RLLP_OppRollup_UTIL.useFiscalYear;
    }
    
    global Date getStartOfNFiscalYearsAgo(Integer n) {
        return RLLP_OppRollup_UTIL.getStartOfNFiscalYearsAgo(n);
    }
}