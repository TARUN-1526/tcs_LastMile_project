public with sharing class ProductService {

    // Get all active products
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts() {
        return [SELECT Id, Name, SKU__c, Price__c, Active__c
                FROM Product__c
                WHERE Active__c = true
                ORDER BY Name];
    }

    // Check available quantity for a product
    public static Integer getAvailableQuantity(Id productId) {
        Inventory__c inv = [SELECT QuantityAvailable__c
                            FROM Inventory__c
                            WHERE Product__c = :productId
                            LIMIT 1];
        return inv != null ? (Integer)inv.QuantityAvailable__c : 0;
    }
}
