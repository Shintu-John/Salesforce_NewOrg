import { LightningElement, api, track } from 'lwc';
import getQuestions from '@salesforce/apex/ValidationQuestionController.getQuestions';
import saveAnswers from '@salesforce/apex/ValidationQuestionController.saveAnswers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class ValidationQuestions extends LightningElement {
    @api recordId;
    @track questions = [];
    @track showThankYou = false;
    isLoading = false;
    maxCharacters = 255;

    connectedCallback() {
        this.fetchQuestions();
    }

    get title(){
        // Hide title when showing thank you screen
        if (this.showThankYou) {
            return "";
        }
        return "Placed On Market Data Queries (" + this.questions.length + ")";
    }

    get cardIconName(){
        // Hide icon when showing thank you screen
        if (this.showThankYou) {
            return "";
        }
        return "custom:custom63";
    }

    fetchQuestions() {
        this.isLoading = true;
        getQuestions({ recordId: this.recordId })
            .then((result) => {
                this.questions = result.map((q) => ({
                    ...q,
                    Answer__c: q.Answer__c || '',
                    characterCount: (q.Answer__c || '').length,
                    isOverLimit: (q.Answer__c || '').length > this.maxCharacters
                }));
                this.isLoading = false;
                
                // If no questions initially, show thank you page
                if (this.questions.length === 0) {
                    this.showThankYou = true;
                }
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const questionId = event.target.dataset.id;
        const value = event.target.value;

        this.questions = this.questions.map((q) =>
            q.Id === questionId ? { 
                ...q, 
                Answer__c: value,
                characterCount: value.length,
                isOverLimit: value.length > this.maxCharacters
            } : q
        );
    }

    get hasCharacterLimitErrors() {
        return this.questions.some(q => q.isOverLimit);
    }

    get charactersOverLimitCount() {
        return this.questions.filter(q => q.isOverLimit).length;
    }

    handleSave() {
        // Validate character limits before saving
        if (this.hasCharacterLimitErrors) {
            const errorMessage = `${this.charactersOverLimitCount} answer(s) exceed the maximum character limit of ${this.maxCharacters}. Please shorten your answers before saving.`;
            this.showToast('Character Limit Exceeded', errorMessage, 'error');
            return;
        }

        this.isLoading = true;
        saveAnswers({ questions: this.questions })
            .then(() => {
                this.showToast('Success', 'Answers saved successfully', 'success');
                this.fetchQuestions();
                
                // If no more questions after save, show thank you page
                if (this.questions.length === 0) {
                    this.showThankYou = true;
                }
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleComplete() {
        // Use Flow Navigation to finish the flow
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}