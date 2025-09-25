import { LightningElement, track, wire } from 'lwc';
import getProducts from '@salesforce/apex/ProductService.getProducts';

export default class ProductList extends LightningElement {
    @track products = [];
    @track error;

    // Define columns here
    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'SKU', fieldName: 'SKU__c' },
        { label: 'Price', fieldName: 'Price__c', type: 'currency' },
        { label: 'Available', fieldName: 'QuantityAvailable__c', type: 'number' }
    ];

    @wire(getProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data;
            console.log(this.products);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.products = [];
        }
    }
}
