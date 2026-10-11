@isTest
private class HelloControllerTest {
    @isTest
    static void messageIsSetOnConstruction() {
        HelloController controller = new HelloController();
        System.assertEquals('Hello workd!', controller.message);
    }
}
