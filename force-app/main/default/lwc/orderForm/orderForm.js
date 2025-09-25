import { LightningElement, track } from 'lwc';
import createPartnerOrder from '@salesforce/apex/OrderService.createPartnerOrder';
import getProducts from '@salesforce/apex/ProductService.getProducts';

export default class OrderForm extends LightningElement {
    @track products = [];
    @track selectedProductId = '';
    @track quantity = 1;
    @track message = '';

    connectedCallback() {
        this.loadProducts();
    }

    // Load products from Apex
    loadProducts() {
        getProducts()
            .then(result => { 
                this.products = result; 
                console.log('this.products : ', this.products);
            })
            .catch(error => { 
                this.message = error.body ? error.body.message : error.message; 
            });
    }

    // Getter for lightning-combobox options
    get productsOptions() {
        return this.products.map(product => ({
            label: product.Name,
            value: product.Id
        }));
    }

    handleProductChange(event) {
        this.selectedProductId = event.target.value;
    }

    handleQuantityChange(event) {
        this.quantity = parseInt(event.target.value);
    }

    handleSubmit() {
        if (!this.selectedProductId || this.quantity < 1) {
            this.message = 'Please select a product and enter a valid quantity.';
            return;
        }

        createPartnerOrder({ productId: this.selectedProductId, quantity: this.quantity })
            .then(result => {
                this.message = 'Order created successfully!';
                this.selectedProductId = '';
                this.quantity = 1;
            })
            .catch(error => {
                this.message = error.body ? error.body.message : error.message;
            });
    }
}
