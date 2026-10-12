public with sharing class LeadByTypeQuery {
    public static List<Lead> getLeadsByType(String leadType) {
        return [SELECT Id, Name, Type__c FROM Lead WHERE Type__c = :leadType];
    }
}
