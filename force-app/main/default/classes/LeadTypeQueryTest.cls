@isTest
private class LeadTypeQueryTest {
    @isTest
    static void returnsOnlyLeadsWithType() {
        insert new List<Lead>{
            new Lead(LastName = 'Lead A', Company = 'Test Co', Type__c = 'Converted'),
            new Lead(LastName = 'Lead B', Company = 'Test Co', Type__c = 'Failed'),
            new Lead(LastName = 'Lead C', Company = 'Test Co')
        };

        Test.startTest();
        List<Lead> result = LeadTypeQuery.getLeadsWithType();
        Test.stopTest();

        System.assertEquals(2, result.size());
        for (Lead l : result) {
            System.assertNotEquals(null, l.Type__c);
        }
    }
}
