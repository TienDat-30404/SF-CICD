@isTest
private class LeadTypeCountTest {
    @isTest
    static void countsLeadsByType() {
        insert new List<Lead>{
            new Lead(LastName = 'Lead A', Company = 'Test Co', Type__c = 'Converted'),
            new Lead(LastName = 'Lead B', Company = 'Test Co', Type__c = 'Converted'),
            new Lead(LastName = 'Lead C', Company = 'Test Co', Type__c = 'Failed'),
            new Lead(LastName = 'Lead D', Company = 'Test Co')
        };

        Test.startTest();
        Map<String, Integer> result = LeadTypeCount.countLeadsByType();
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assertEquals(2, result.get('Converted'));
        System.assertEquals(1, result.get('Failed'));
    }
}
