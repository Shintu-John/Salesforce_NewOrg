({
	redirectToRecordId : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        let prefix = component.get("v.prefix");
        let redirectUrl = ($A.util.isEmpty(prefix) ? '' : '/' + prefix) + '/' +  recordId;
        window.location = redirectUrl;
	}
})