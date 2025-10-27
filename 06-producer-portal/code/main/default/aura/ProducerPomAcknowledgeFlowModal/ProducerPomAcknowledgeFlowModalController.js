({
    doInit: function(component, event, helper) {
        console.log('[FlowModal] Component initialized');
        helper.checkAndShowFlow(component);
    },

    handleFlowStatusChange: function(component, event, helper) {
        var status = event.getParam("status");
        console.log('[FlowModal] Flow status changed:', status);

        if (status === "FINISHED" || status === "FINISHED_SCREEN") {
            console.log('[FlowModal] Flow finished - reloading page');
            // Reload the page to refresh the record
            window.location.reload();
        }
    }
})
