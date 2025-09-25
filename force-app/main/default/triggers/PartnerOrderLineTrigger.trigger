trigger PartnerOrderLineTrigger on Order_Line_Item__c (after insert) {
    Map<Id, Integer> productQuantityMap = new Map<Id, Integer>();

    for(Order_Line_Item__c item : Trigger.New){
        if(item.Product__c != null){
            if(!productQuantityMap.containsKey(item.Product__c)){
                productQuantityMap.put(item.Product__c, 0);
            }
            productQuantityMap.put(item.Product__c,
                productQuantityMap.get(item.Product__c) + Integer.valueOf(item.Quantity__c));
        }
    }

    List<Inventory__c> invList = [SELECT Id, Product__c, QuantityAvailable__c
                                  FROM Inventory__c
                                  WHERE Product__c IN :productQuantityMap.keySet()];

    for(Inventory__c inv : invList){
        inv.QuantityAvailable__c -= productQuantityMap.get(inv.Product__c);
    }
    update invList;
}
