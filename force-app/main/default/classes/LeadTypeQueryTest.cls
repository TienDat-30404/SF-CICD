@isTest
private class LeadTypeQueryTest {
    @isTest
    static void returnsLeads() {
        insert new Lead(LastName = 'Lead A', Company = 'Test Co');

        Test.startTest();
        List<Lead> result = LeadTypeQuery.getLeads();
        Test.stopTest();

        System.assertEquals(1, result.size());
    }
}
