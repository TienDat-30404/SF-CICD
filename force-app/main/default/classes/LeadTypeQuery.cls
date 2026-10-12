public with sharing class LeadTypeQuery {
    public static List<Lead> getLeadsWithType() {
        return [SELECT Id, Name, Type__c FROM Lead WHERE Type__c != NULL];
    }
}
