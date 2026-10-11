public with sharing class HelloController {
    public String message { get; private set; }

    public HelloController() {
        message = 'Xin chào từ Salesforce!';
    }
}