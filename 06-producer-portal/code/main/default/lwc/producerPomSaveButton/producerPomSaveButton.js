import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    'Producer_Placed_on_Market__c.Is_Ready_To_Acknowledge__c',
    'Producer_Placed_on_Market__c.Acknowledgement_of_Statements__c'
];

export default class ProducerPomSaveButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    isLoading = false;
    recordData;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.recordData = data;
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

    handleSave() {
        this.isLoading = true;

        // Trigger the save event to save the form
        const saveEvent = new CustomEvent('save');
        this.dispatchEvent(saveEvent);

        // Wait a moment for the save to complete, then check if we should launch acknowledge flow
        setTimeout(() => {
            this.checkAndLaunchAcknowledgeFlow();
        }, 1000);
    }

    checkAndLaunchAcknowledgeFlow() {
        const isReadyToAcknowledge = getFieldValue(this.recordData, 'Producer_Placed_on_Market__c.Is_Ready_To_Acknowledge__c');
        const isAcknowledged = getFieldValue(this.recordData, 'Producer_Placed_on_Market__c.Acknowledgement_of_Statements__c');

        if (isReadyToAcknowledge && !isAcknowledged) {
            // Launch the Acknowledge flow
            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: {
                    componentName: 'c__producerPomAcknowledgeFlow'
                },
                state: {
                    c__recordId: this.recordId
                }
            });
        } else {
            // Just show success message and stay on page
            this.showSuccessToast();
        }

        this.isLoading = false;
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Record saved successfully',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
}
