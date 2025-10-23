/**
 * Simple handler class to call case auto-assignment from Flows with proper transaction handling
 */
public class rlsServiceCaseAutoAssignHandler {

    public class FlowInputs {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    @InvocableMethod(label='Auto Assign Case (Async)' description='Assigns case to user asynchronously after transaction completes')
    public static void assignCaseAsync(List<FlowInputs> inputs) {
        List<Id> caseIds = new List<Id>();

        for (FlowInputs input : inputs) {
            if (input.caseId != null) {
                caseIds.add(input.caseId);
            }
        }

        if (!caseIds.isEmpty()) {
            // Call the future method to run in separate transaction
            assignCasesFuture(caseIds);
        }
    }

    @future
    public static void assignCasesFuture(List<Id> caseIds) {
        // Call the main assignment logic
        rlsServiceCaseAutoAssign.assignCasesToUsers(caseIds);
    }
}