import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getNextActions from '@salesforce/apex/ProducerPomAcknowledgeController.getNextActions';

const FIELDS = [
    'Producer_Placed_on_Market__c.Unanswered_Questions__c',
    'Producer_Placed_on_Market__c.Status__c',
    'Producer_Placed_on_Market__c.Weights_Entered__c',
    'Producer_Placed_on_Market__c.Show_Signature_Popup__c',
    'Producer_Placed_on_Market__c.Show_Acknowledgement_PopUp__c'
];

export default class ProducerNextActions extends LightningElement {
    @api recordId;

    showValidationQuestionsFlow = false;
    showSignatureFlow = false;
    showAcknowledgementFlow = false;

    nextActionsData;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    @wire(getNextActions, { recordId: '$recordId' })
    wiredNextActions({ error, data }) {
        if (data && data.success) {
            this.nextActionsData = data;
        } else if (error) {
            console.error('Error loading next actions:', error);
        }
    }

    get hasActions() {
        return this.showValidationQuestions || this.showSignature || this.showAcknowledgement;
    }

    get showValidationQuestions() {
        if (!this.record || !this.record.data) return false;
        const unansweredQuestions = getFieldValue(this.record.data, FIELDS[0]);
        return unansweredQuestions > 0;
    }

    get showSignature() {
        // Use Apex result which checks user profile dynamically
        if (this.nextActionsData && this.nextActionsData.shouldShowSignature !== undefined) {
            return this.nextActionsData.shouldShowSignature;
        }
        // Fallback to field (though it won't work correctly for Directors)
        if (!this.record || !this.record.data) return false;
        const showSignaturePopup = getFieldValue(this.record.data, FIELDS[3]);
        return showSignaturePopup === true;
    }

    get showAcknowledgement() {
        if (!this.record || !this.record.data) return false;
        const showAckPopup = getFieldValue(this.record.data, FIELDS[4]);
        const status = getFieldValue(this.record.data, FIELDS[1]);
        const weightsEntered = getFieldValue(this.record.data, FIELDS[2]);
        return showAckPopup === true || (status === 'Waiting for Market Data' && weightsEntered === true);
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleValidationQuestions() {
        this.showValidationQuestionsFlow = true;
    }

    handleSignature() {
        this.showSignatureFlow = true;
    }

    handleAcknowledgement() {
        this.showAcknowledgementFlow = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // Flow completed - refresh the record
            this.showValidationQuestionsFlow = false;
            this.showSignatureFlow = false;
            this.showAcknowledgementFlow = false;

            // Refresh the page to show updated data
            eval("$A.get('e.force:refreshView').fire();");
        }
    }
}