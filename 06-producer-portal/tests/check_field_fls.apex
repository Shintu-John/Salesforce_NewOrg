/**
 * Check Field-Level Security for Producer POM - Update Status Flow
 *
 * Purpose: Verify FLS permissions for all fields used by the flow
 * The flow may fail to activate if the running user doesn't have FLS access
 *
 * Usage:
 *   sf apex run --file scripts/check_field_fls.apex --target-org NewOrg
 */

System.debug('=== Field-Level Security Check ===');
System.debug('Object: Producer_Placed_on_Market__c');
System.debug('Running as: ' + UserInfo.getName() + ' (' + UserInfo.getUserName() + ')');
System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);

// Get field map
Schema.SObjectType pomType = Schema.getGlobalDescribe().get('Producer_Placed_on_Market__c');
Map<String, Schema.SObjectField> fieldMap = pomType.getDescribe().fields.getMap();

String[] flowFields = new String[]{
    'Is_Record_Signed__c',
    'Acknowledgement_of_Statements__c',
    'Unanswered_Questions__c',
    'Is_Ready_To_Acknowledge__c',
    'Status__c'
};

System.debug('\nField Accessibility for Current User:');
System.debug('────────────────────────────────────────────────────────');

Boolean allAccessible = true;
for (String fieldName : flowFields) {
    if (fieldMap.containsKey(fieldName)) {
        Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();

        String accessibility = '';
        if (!field.isAccessible()) {
            accessibility = '✗ NOT READABLE';
            allAccessible = false;
        } else if (!field.isUpdateable()) {
            accessibility = '⚠ READABLE but NOT UPDATEABLE';
            if (fieldName == 'Status__c') {
                allAccessible = false; // Status__c needs to be updateable
            }
        } else {
            accessibility = '✓ Full Access (Read + Update)';
        }

        System.debug(fieldName);
        System.debug('  Accessibility: ' + accessibility);
        System.debug('  Type: ' + field.getType());
        System.debug('  Is Calculated: ' + field.isCalculated());
        System.debug('  Is Custom: ' + field.isCustom());

        // Special check for formula fields
        if (field.isCalculated()) {
            System.debug('  ⚠ WARNING: This is a formula field - cannot be updated by flows!');
            if (fieldName == 'Status__c' || fieldName == 'Is_Ready_To_Acknowledge__c') {
                System.debug('  ✗ CRITICAL: Flow tries to update a formula field!');
                allAccessible = false;
            }
        }
    } else {
        System.debug(fieldName + ': ✗ FIELD DOES NOT EXIST');
        allAccessible = false;
    }
    System.debug('');
}

System.debug('════════════════════════════════════════════════════════');
if (allAccessible) {
    System.debug('RESULT: ✓ All fields are accessible and updateable');
} else {
    System.debug('RESULT: ✗ FLS or field configuration issues detected');
    System.debug('\nPossible Solutions:');
    System.debug('1. If fields are not accessible:');
    System.debug('   → Grant FLS permissions via Profile or Permission Set');
    System.debug('   → Setup → Object Manager → Producer_Placed_on_Market__c → Fields');
    System.debug('');
    System.debug('2. If Is_Ready_To_Acknowledge__c is a formula field:');
    System.debug('   → Flow cannot read formula fields - this is expected');
    System.debug('   → Formulas evaluate automatically, no flow action needed');
    System.debug('');
    System.debug('3. If Status__c is a formula field:');
    System.debug('   → This is a PROBLEM - flow cannot update formula fields');
    System.debug('   → Change Status__c to a regular picklist field');
    System.debug('   → Use the flow to calculate and set the value');
}

System.debug('\n=== FLS Check Complete ===');
