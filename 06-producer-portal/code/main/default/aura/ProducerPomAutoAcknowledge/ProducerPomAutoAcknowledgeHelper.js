({
    checkAndRedirect: function(component) {
        var recordId = component.get("v.recordId");
        var hasChecked = component.get("v.hasChecked");

        // If recordId not set, try to get it from URL
        if (!recordId) {
            recordId = this.getRecordIdFromUrl();
            if (recordId) {
                component.set("v.recordId", recordId);
                console.log('[v3] ProducerPomAutoAcknowledge: Got recordId from URL: ' + recordId);
            } else {
                console.log('[v3] ProducerPomAutoAcknowledge: No recordId found, skipping check');
                return;
            }
        }

        // Prevent multiple checks on same page load
        if (hasChecked) {
            console.log('[v4] ProducerPomAutoAcknowledge: Already checked on this page load, skipping');
            return;
        }

        component.set("v.hasChecked", true);
        console.log('[v4] ProducerPomAutoAcknowledge: Checking if popup should be shown...');

        // Call Apex to check if Show_Acknowledgement_PopUp__c is true
        var action = component.get("c.getRecordStatus");
        action.setParams({ recordId: recordId });

        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('[v4] ProducerPomAutoAcknowledge: Apex callback state: ' + state);

            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('[v4] ProducerPomAutoAcknowledge: shouldShowPopup = ' + result.shouldShowPopup);

                if (result.shouldShowPopup === true) {
                    console.log('[v4] ProducerPomAutoAcknowledge: Reloading page to trigger acknowledgement flow popup');
                    window.location.reload();
                } else {
                    console.log('[v4] ProducerPomAutoAcknowledge: No reload needed - popup not required');
                }
            } else {
                console.log('[v4] ProducerPomAutoAcknowledge: Error checking record status');
            }
        });

        $A.enqueueAction(action);
    },

    getRecordIdFromUrl: function() {
        // Get recordId from URL - look for 15 or 18 character Salesforce ID
        var url = window.location.href;

        // Try to match Salesforce record ID pattern (15 or 18 alphanumeric chars)
        var recordIdMatch = url.match(/([a-zA-Z0-9]{15,18})(?:\/|$|\?)/);

        if (recordIdMatch && recordIdMatch[1]) {
            var possibleId = recordIdMatch[1];
            // Verify it's a valid Salesforce ID length
            if (possibleId.length === 15 || possibleId.length === 18) {
                console.log('[v3] ProducerPomAutoAcknowledge: Extracted ID from URL: ' + possibleId);
                return possibleId;
            }
        }

        console.log('[v3] ProducerPomAutoAcknowledge: Could not extract record ID from URL: ' + url);
        return null;
    },

})
