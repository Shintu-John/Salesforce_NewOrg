({   
    invoke : function(component, event, helper) {
        
        helper.redirectToRecordId(component, event, helper);
        
        /*
        var workspaceAPI = component.find("workspaceAPI");
        
        if (workspaceAPI) {
            workspaceAPI.isConsoleNavigation()
                .then(function(response) {
                    let isConsole = response;
                    var navEvt = $A.get("e.force:navigateToSObject");
                    if(isConsole && navEvt){
                        navEvt.setParams({
                            "recordId": recordId
                        });
                        navEvt.fire();
                    }else{
                        helper.redirectToRecordId(component, event, helper);
                    }
                    
                })
                .catch(function(error) {
                    helper.redirectToRecordId(component, event, helper);
                });
        } else {
            helper.redirectToRecordId(component, event, helper);
        } */
    }
})