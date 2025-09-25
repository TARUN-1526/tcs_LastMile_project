@isTest
private class PartnerOrderServiceTest {
    @isTest static void testCreateOrder_success() {
        // create account (distributor)
        Account acc = new Account(Name='Dist Test');
        insert acc;

        // create product and inventory
        Product__c p = new Product__c(Name='P1', SKU__c='SKU1', Price__c=100, Active__c=true);
        insert p;
        Inventory__c inv = new Inventory__c(Product__c = p.Id, QuantityAvailable__c = 10);
        insert inv;

        // prepare an HTTP POST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/partner/v1/orders';
        req.httpMethod = 'POST';
        String body = '{"distributorId":"'+acc.Id+'","items":[{"productId":"'+p.Id+'","quantity":2}]}';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
            Partner_Order__c result = PartnerOrderService.createOrder();
        Test.stopTest();

        // verify Partner Order created
        Partner_Order__c[] orders = [SELECT Id, Distributor__c, Total_Amount__c FROM Partner_Order__c WHERE Distributor__c = :acc.Id];
        System.assertEquals(1, orders.size());
        // verify line item
        Order_Line_Item__c[] lines = [SELECT Id, Product__c, Quantity__c FROM Order_Line_Item__c WHERE Partner_Order__c = :orders[0].Id];
        System.assertEquals(1, lines.size());
        System.assertEquals(2, Integer.valueOf(String.valueOf(lines[0].Quantity__c)));
        // verify inventory reduced
        Inventory__c invCheck = [SELECT QuantityAvailable__c FROM Inventory__c WHERE Product__c = :p.Id];
        System.assertEquals(8, Integer.valueOf(String.valueOf(invCheck.QuantityAvailable__c)));
    }
}
