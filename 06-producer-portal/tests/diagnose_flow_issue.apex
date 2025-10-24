/**
 * Diagnostic Script: Producer POM - Update Status Flow
 *
 * Purpose: Diagnose why the flow cannot be activated
 * This script checks all field dependencies and picklist values
 *
 * Usage:
 *   sf apex run --file scripts/diagnose_flow_issue.apex --target-org NewOrg
 */

System.debug('=== Flow Activation Diagnostic ===');
System.debug('Flow: Producer POM - Update Status');

// Get object schema
Schema.SObjectType pomType = Schema.getGlobalDescribe().get('Producer_Placed_on_Market__c');
Schema.DescribeSObjectResult pomDescribe = pomType.getDescribe();
Map<String, Schema.SObjectField> fieldMap = pomDescribe.fields.getMap();

System.debug('\n1. Checking Required Fields:');
String[] requiredFields = new String[]{
    'Is_Record_Signed__c',
    'Acknowledgement_of_Statements__c',
    'Unanswered_Questions__c',
    'Is_Ready_To_Acknowledge__c',
    'Status__c'
};

Boolean allFieldsExist = true;
for (String fieldName : requiredFields) {
    if (fieldMap.containsKey(fieldName)) {
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
        System.debug('  ✓ ' + fieldName + ' - Type: ' + fieldDescribe.getType() + ', Updateable: ' + fieldDescribe.isUpdateable());

        // If it's Status__c, check picklist values
        if (fieldName == 'Status__c' && fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
            System.debug('    Picklist Values:');
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            Set<String> valueSet = new Set<String>();
            for (Schema.PicklistEntry entry : picklistValues) {
                valueSet.add(entry.getValue());
                System.debug('      - ' + entry.getValue() + ' (Active: ' + entry.isActive() + ')');
            }

            // Check if flow's required values exist
            String[] flowValues = new String[]{
                'Signed',
                'Questions Required',
                'Pending Director Review',
                'Acknowledge Market Data',
                'Ready to Acknowledge'
            };

            System.debug('    Flow Required Values:');
            for (String flowValue : flowValues) {
                if (valueSet.contains(flowValue)) {
                    System.debug('      ✓ "' + flowValue + '" - EXISTS');
                } else {
                    System.debug('      ✗ "' + flowValue + '" - MISSING!');
                    allFieldsExist = false;
                }
            }
        }
    } else {
        System.debug('  ✗ ' + fieldName + ' - MISSING!');
        allFieldsExist = false;
    }
}

System.debug('\n2. Checking Flow Record in Salesforce:');
try {
    // Query the Flow metadata
    List<Flow> flows = [
        SELECT Id, DefinitionId, VersionNumber, Status, ProcessType
        FROM Flow
        WHERE Definition.DeveloperName = 'Producer_POM_Update_Status'
        ORDER BY VersionNumber DESC
        LIMIT 1
    ];

    if (!flows.isEmpty()) {
        Flow latestFlow = flows[0];
        System.debug('  Latest Version: ' + latestFlow.VersionNumber);
        System.debug('  Status: ' + latestFlow.Status);
        System.debug('  ProcessType: ' + latestFlow.ProcessType);

        if (latestFlow.Status == 'InvalidDraft') {
            System.debug('\n  ⚠ Flow is in InvalidDraft status!');
            System.debug('  Common causes:');
            System.debug('    1. Missing picklist values in Status__c field');
            System.debug('    2. Field type mismatch');
            System.debug('    3. Formula field used in update action');
            System.debug('    4. Flow logic errors');
        }
    } else {
        System.debug('  ✗ Flow not found in org!');
    }
} catch (Exception e) {
    System.debug('  Error querying Flow: ' + e.getMessage());
}

System.debug('\n3. Recommendations:');
if (!allFieldsExist) {
    System.debug('  ✗ Some required fields or values are missing!');
    System.debug('  Action: Add missing picklist values to Status__c field');
} else {
    System.debug('  ✓ All fields and values exist');
    System.debug('  Action: Check Flow in Setup → Flows → Producer POM - Update Status');
    System.debug('  Look for specific validation errors in the Flow Builder');
}

System.debug('\n=== Diagnostic Complete ===');
