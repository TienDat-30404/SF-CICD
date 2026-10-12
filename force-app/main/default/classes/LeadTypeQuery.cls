public with sharing class LeadTypeQuery {
    public static List<Lead> getLeads() {
        return [SELECT Id, Name, Type__c FROM Lead];
    }
}
