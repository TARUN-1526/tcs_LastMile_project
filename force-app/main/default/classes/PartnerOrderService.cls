@RestResource(urlMapping='/partner/v1/orders')
global with sharing class PartnerOrderService {
    @HttpPost
    global static Object createOrder() {
        RestRequest req = RestContext.request;
        if (req == null || req.requestBody == null) {
            RestContext.response.statusCode = 400;
            return new Map<String,Object>{'error' => 'Empty request body'};
        }

        // parse JSON payload
        Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(req.requestBody.toString());
        if (payload == null || !payload.containsKey('distributorId') || !payload.containsKey('items')) {
            RestContext.response.statusCode = 400;
            return new Map<String,Object>{'error' => 'Payload must contain distributorId and items'};
        }

        Id distributorId = (Id) payload.get('distributorId');
        List<Object> itemsRaw = (List<Object>) payload.get('items');

        if (itemsRaw == null || itemsRaw.isEmpty()) {
            RestContext.response.statusCode = 400;
            return new Map<String,Object>{'error' => 'items array must not be empty'};
        }

        // collect product ids
        Set<Id> prodIds = new Set<Id>();
        for (Object o : itemsRaw) {
            Map<String,Object> m = (Map<String,Object>) o;
            if (m.get('productId') == null) {
                RestContext.response.statusCode = 400;
                return new Map<String,Object>{'error' => 'each item must include productId'};
            }
            prodIds.add((Id) m.get('productId'));
        }

        // query product prices
        Map<Id, Product__c> prodMap = new Map<Id, Product__c>(
            [SELECT Id, Price__c FROM Product__c WHERE Id IN :prodIds]
        );
        // query inventories
        Map<Id, Inventory__c> invMap = new Map<Id, Inventory__c>();
        for (Inventory__c inv : [SELECT Id, Product__c, QuantityAvailable__c FROM Inventory__c WHERE Product__c IN :prodIds]) {
            invMap.put(inv.Product__c, inv);
        }

        // validate quantities and build line items
        List<Order_Line_Item__c> lineItems = new List<Order_Line_Item__c>();
        Decimal total = 0;
        for (Object o : itemsRaw) {
            Map<String,Object> m = (Map<String,Object>) o;
            Id pid = (Id) m.get('productId');
            Integer qty;
            try {
                qty = Integer.valueOf(String.valueOf(m.get('quantity')));
            } catch (Exception ex) {
                RestContext.response.statusCode = 400;
                return new Map<String,Object>{'error' => 'Invalid quantity for product ' + pid};
            }
            if (!prodMap.containsKey(pid)) {
                RestContext.response.statusCode = 400;
                return new Map<String,Object>{'error' => 'Product not found: ' + pid};
            }
            Product__c p = prodMap.get(pid);
            Decimal price = p.Price__c == null ? 0 : p.Price__c;
            Inventory__c inv = invMap.get(pid);
            Integer available = inv == null || inv.QuantityAvailable__c == null ? 0 : Integer.valueOf(String.valueOf(inv.QuantityAvailable__c));
            if (qty > available) {
                RestContext.response.statusCode = 400;
                return new Map<String,Object>{'error' => 'Insufficient inventory for product ' + pid};
            }
            total += price * qty;
            lineItems.add(new Order_Line_Item__c(Product__c = pid, Quantity__c = qty, UnitPrice__c = price));
        }

        // create Partner Order
        Partner_Order__c po = new Partner_Order__c(Distributor__c = distributorId, Order_Date__c = Date.today(), Total_Amount__c = total);
        insert po;

        // attach and insert line items
        for (Order_Line_Item__c li : lineItems) li.Partner_Order__c = po.Id;
        insert lineItems;

        // update inventory
        List<Inventory__c> invUpdates = new List<Inventory__c>();
        for (Order_Line_Item__c li : lineItems) {
            Inventory__c inv = invMap.get(li.Product__c);
            if (inv != null) {
                inv.QuantityAvailable__c = inv.QuantityAvailable__c - li.Quantity__c;
                invUpdates.add(inv);
            }
        }
        if (!invUpdates.isEmpty()) update invUpdates;

        // Return order id (201 Created)
        RestContext.response.statusCode = 201;
        return new Map<String,Object>{'orderId' => po.Id};
    }
}
