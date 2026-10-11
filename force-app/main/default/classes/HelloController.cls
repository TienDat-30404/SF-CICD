public with sharing class HelloController {
    public static String getGreeting(String name) {
        String displayName = String.isBlank(name) ? 'Salesforce' : name.trim();
        return 'Xin chào, ' + displayName + '!';
    }
}