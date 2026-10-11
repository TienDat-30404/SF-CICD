public with sharing class HelloController {
    public String message { get; private set; }
    
    public HelloController() {
        message = 'Hello workd!';
    }
}