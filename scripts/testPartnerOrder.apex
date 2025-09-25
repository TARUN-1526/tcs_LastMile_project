// Test PartnerOrderService class by simulating a REST call
Id distributorId = '001gL00000P8auLQAR'; // Distributor Account ID
Id productId = 'a07gL00000EiBURQA3'; // Product ID
Integer quantity = 5;

PartnerOrderService poService = new PartnerOrderService();
poService.createOrder(distributorId, productId, quantity);

System.debug('Partner Order created successfully for Distributor: ' + distributorId);
