@RestResource(urlMapping='/partner/v1/products')
global with sharing class PartnerProductService {
    @HttpGet
    global static List<Product__c> doGet() {
        try {
            List<Product__c> prods = [
                SELECT Id, Name, SKU__c, Price__c
                FROM Product__c
                WHERE Active__c = TRUE
                ORDER BY Name
            ];
            return prods;
        } catch(Exception e) {
            RestContext.response.statusCode = 500;
            // return an empty list (client will see 500)
            return new List<Product__c>();
        }
    }
}
