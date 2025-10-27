import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    'Producer_Placed_on_Market__c.Is_Ready_To_Acknowledge__c',
    'Producer_Placed_on_Market__c.Acknowledgement_of_Statements__c',
    'Producer_Placed_on_Market__c.Name'
];

export default class ProducerPomRecordForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName = 'Producer_Placed_on_Market__c';

    isLoading = false;
    isReadyToAcknowledge = false;
    isAlreadyAcknowledged = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.isReadyToAcknowledge = data.fields.Is_Ready_To_Acknowledge__c?.value || false;
            this.isAlreadyAcknowledged = data.fields.Acknowledgement_of_Statements__c?.value || false;
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

    handleSuccess(event) {
        const savedRecordId = event.detail.id;

        // Check if we should launch the acknowledge flow
        if (this.isReadyToAcknowledge && !this.isAlreadyAcknowledged) {
            // Navigate to the Acknowledge flow
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/flow/Producer_Placed_On_Market_Acknowledge_Best_Action?recordId=${savedRecordId}`
                }
            });
        } else {
            // Show success message
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully',
                variant: 'success'
            });
            this.dispatchEvent(evt);
        }
    }

    handleError(event) {
        const evt = new ShowToastEvent({
            title: 'Error saving record',
            message: event.detail.message,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }

    handleSubmit(event) {
        this.isLoading = true;
        // Let the form handle the actual submit
    }

    handleLoad() {
        this.isLoading = false;
    }
}
