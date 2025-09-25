// create test data for integration testing
Account a = new Account(Name='Distributor Test');
insert a;

Product__c p = new Product__c(Name='API Product 1', SKU__c='API-SKU-1', Price__c=150, Active__c=true);
insert p;

Inventory__c inv = new Inventory__c(Product__c = p.Id, QuantityAvailable__c = 20);
insert inv;

System.debug('DIST:'+a.Id+' PROD:'+p.Id);
