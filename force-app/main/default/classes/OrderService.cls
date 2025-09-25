public with sharing class OrderService {

    // Expose this method to LWC
    @AuraEnabled
    public static Partner_Order__c createPartnerOrder(Id distributorId, Id productId, Integer quantity) {
        // Calculate total
        Decimal unitPrice = [SELECT Price__c FROM Product__c WHERE Id = :productId].Price__c;
        Decimal total = unitPrice * quantity;

        // Create partner order
        Partner_Order__c po = new Partner_Order__c(
            Distributor__c = distributorId,
            Order_Date__c = Date.today(),
            Total_Amount__c = total
        );
        insert po;

        // Create order line item
        Order_Line_Item__c oli = new Order_Line_Item__c(
            Partner_Order__c = po.Id,
            Product__c = productId,
            Quantity__c = quantity,
            UnitPrice__c = unitPrice
        );
        insert oli;

        // Update inventory
        Inventory__c inv = [SELECT Id, QuantityAvailable__c FROM Inventory__c WHERE Product__c = :productId LIMIT 1];
        if(inv != null){
            inv.QuantityAvailable__c -= quantity;
            update inv;
        }

        return po;
    }
}
