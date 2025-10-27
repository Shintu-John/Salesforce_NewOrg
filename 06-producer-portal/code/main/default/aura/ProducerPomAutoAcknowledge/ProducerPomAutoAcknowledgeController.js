({
    doInit: function(component, event, helper) {
        console.log('[v4] ProducerPomAutoAcknowledge: Component initialized - NOT checking on page load');
        // Don't check on initial page load - only check after save (handleRefresh)
    },

    handleRefresh: function(component, event, helper) {
        console.log('[v4] ProducerPomAutoAcknowledge: Page refreshed after save');
        // Call immediately without delay
        helper.checkAndRedirect(component);
    }
})
