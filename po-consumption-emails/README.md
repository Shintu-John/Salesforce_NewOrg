# Purchase Order Consumption Email Notifications - NewOrg Migration Package

**Scenario**: PO Consumption Email Notifications
**Target Org**: NewOrg (Recycling Lives Group)
**Migration Date**: Ready for deployment
**Original Implementation**: October 14, 2025 (OldOrg)
**Complexity**: Low-Medium
**Estimated Deployment Time**: 1.5-2 hours

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Related Documentation](#related-documentation)
3. [Gap Analysis](#gap-analysis)
4. [Pre-Deployment Environment Verification](#pre-deployment-environment-verification)
5. [Deployment Steps](#deployment-steps)
6. [Code Files Reference](#code-files-reference)
7. [Post-Deployment Validation](#post-deployment-validation)
8. [Rollback Procedures](#rollback-procedures)
9. [Testing Plan](#testing-plan)
10. [Known Risks & Mitigation](#known-risks--mitigation)

---

## Executive Summary

### What's Being Migrated

Automated email notification system that monitors Purchase Order consumption and sends alerts at 50%, 75%, and 90% thresholds.

### Business Value

- **Proactive Monitoring**: Automatic alerts prevent PO exhaustion surprises
- **Multi-Level Warnings**: 3 thresholds provide escalating awareness
- **Smart Re-notification**: Option B logic re-alerts if consumption fluctuates
- **No Manual Effort**: Fully automated after initial setup
- **Scalable**: Easily add more POs via Custom Setting

### Migration Status

- **OldOrg State**: Production-ready since October 14, 2025
- **NewOrg State**: Not deployed - all components missing
- **Gap**: 100% of components need deployment
- **Ready to Deploy**: Yes - all code files prepared

---

## Related Documentation

### OldOrg State Documentation

- [OldOrg Implementation Details](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/po-consumption-emails) - Complete verification and component inventory
- [Source Documentation](https://github.com/Shintu-John/Salesforce_OldOrg_State/blob/main/po-consumption-emails/source-docs/PO_CONSUMPTION_EMAIL_NOTIFICATIONS.md) - Original implementation guide

### Related Scenarios

None - This is a standalone scenario

### Migration Progress

- [Overall Migration Status](https://github.com/Shintu-John/Salesforce_OldOrg_State/blob/main/README.md)

---

## Gap Analysis

### Summary

**NewOrg Status** (Verified October 23, 2025):
- **Total Components Missing**: 12 out of 13
- **Pre-existing Components**: 3 (Order consumption fields)
- **Deployment Required**: Yes

### Detailed Component Comparison

| Component | Type | OldOrg Status | NewOrg Status | Gap | Action Required |
|-----------|------|---------------|---------------|-----|-----------------|
| **PO_Notification_Settings__c** | Custom Object | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy custom setting + 5 fields |
| **Flow: Order_Consumption_Multi_Threshold_Notification** | Flow | ✅ Active | ❌ Missing | 🚨 **MISSING** | Deploy and activate |
| **Order.Notified_50_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Notified_75_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Notified_90_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Last_Notified_50_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Last_Notified_75_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Last_Notified_90_Percent__c** | Custom Field | ✅ Deployed Oct 14 | ❌ Missing | 🚨 **MISSING** | Deploy field |
| **Order.Consumed_Amount__c** | Custom Field | ✅ Exists | ✅ Exists | ✅ **EXISTS** | No action - already deployed |
| **Order.Max_Value__c** | Custom Field | ✅ Exists | ✅ Exists | ✅ **EXISTS** | No action - already deployed |
| **Order.Consumed_Amount_Percent__c** | Custom Field | ✅ Exists | ✅ Exists | ✅ **EXISTS** | No action - already deployed |

### Gap Categories

#### 🚨 Critical Missing Components (System Won't Work)

**Count**: 9 components

1. **Custom Setting**: PO_Notification_Settings__c + 5 fields
   - Without this, Flow can't determine which POs to monitor
   - Configuration data cannot be stored

2. **Flow**: Order_Consumption_Multi_Threshold_Notification
   - Without this, no monitoring or notifications occur
   - All business logic resides in this Flow

3. **Order Fields**: 6 notification tracking fields
   - Without these, Flow cannot track notification state
   - Re-notification logic won't work
   - System will send duplicate emails continuously

**Impact if Missing**: System completely non-functional

---

#### ✅ Already Exists (No Action)

**Count**: 3 components

1. Order.Consumed_Amount__c ✅
2. Order.Max_Value__c ✅
3. Order.Consumed_Amount_Percent__c ✅

These fields are pre-existing dependencies already in NewOrg. No deployment needed.

---

## Pre-Deployment Environment Verification

### Required Pre-existing Components

Before deploying, verify these components exist in NewOrg:

#### 1. Order Object Standard Fields

```bash
sf data query --query "SELECT EntityDefinition.QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND QualifiedApiName IN ('Id', 'OrderNumber', 'Status')" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 3 fields (Id, OrderNumber, Status)
**If Missing**: Cannot proceed - standard Order object required

---

#### 2. Order Consumption Fields

```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND QualifiedApiName IN ('Consumed_Amount__c', 'Max_Value__c', 'Consumed_Amount_Percent__c')" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 3 fields
**If Missing**: Cannot proceed - these fields must exist before Flow deployment

---

#### 3. Email Deliverability

```bash
sf data query --query "SELECT Id, Status FROM Organization LIMIT 1" --target-org NewOrg
```

**Expected Result**: Organization record exists
**Additional Check**: Verify org can send emails (Setup → Email Administration → Deliverability → Access Level = "All Email")

---

### Environment Readiness Checklist

- [ ] Order object exists and accessible
- [ ] Order standard fields (Id, OrderNumber, Status) accessible
- [ ] Order custom fields (Consumed_Amount__c, Max_Value__c, Consumed_Amount_Percent__c) exist
- [ ] User has permission to create Custom Objects (for Custom Setting)
- [ ] User has permission to create Custom Fields on Order
- [ ] User has permission to create and activate Flows
- [ ] Org email deliverability enabled
- [ ] No conflicting flows on Order object (After Save triggers)

---

## Deployment Steps

### Phase 1: Deploy Custom Setting

**Type**: ✅ CLI Step

**Command**:
```bash
sf project deploy start -d code/PO_Notification_Settings__c --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Deployed Source:
- PO_Notification_Settings__c (CustomObject)
- PO_ID__c (CustomField)
- PO_Number__c (CustomField)
- Notifications_Enabled__c (CustomField)
- Use_Repeated_Reminders__c (CustomField)
- Reminder_Frequency_Hours__c (CustomField)
```

**Verification**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'PO_Notification_Settings'" --target-org NewOrg --use-tooling-api
```

**Expected**: 1 record (PO_Notification_Settings)

**If Fails**:
- Check deployment error message
- Verify user has Create Custom Object permission
- Check for naming conflicts

**Estimated Time**: 2-3 minutes

---

### Phase 2: Deploy Order Notification Fields

**Type**: ✅ CLI Step

**Command**:
```bash
# Create package.xml for Order fields
cat > /tmp/package.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Order.Notified_50_Percent__c</members>
        <members>Order.Notified_75_Percent__c</members>
        <members>Order.Notified_90_Percent__c</members>
        <members>Order.Last_Notified_50_Percent__c</members>
        <members>Order.Last_Notified_75_Percent__c</members>
        <members>Order.Last_Notified_90_Percent__c</members>
        <name>CustomField</name>
    </types>
    <version>64.0</version>
</Package>
EOF

# Deploy Order fields
sf project deploy start -d code/Order_fields -x /tmp/package.xml --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Deployed Source:
- Order.Notified_50_Percent__c (CustomField)
- Order.Notified_75_Percent__c (CustomField)
- Order.Notified_90_Percent__c (CustomField)
- Order.Last_Notified_50_Percent__c (CustomField)
- Order.Last_Notified_75_Percent__c (CustomField)
- Order.Last_Notified_90_Percent__c (CustomField)
```

**Verification**:
```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND (QualifiedApiName LIKE 'Notified%' OR QualifiedApiName LIKE 'Last_Notified%')" --target-org NewOrg --use-tooling-api
```

**Expected**: 6 fields

**If Fails**:
- Check if Order object is accessible
- Verify field API names don't conflict
- Check user has Create Field permission on Order

**Estimated Time**: 3-5 minutes

---

### Phase 3: Deploy Flow

**Type**: ✅ CLI Step

**Command**:
```bash
sf project deploy start -d code/flows --target-org NewOrg
```

**Expected Output**:
```
Status: Succeeded
Deployed Source:
- Order_Consumption_Multi_Threshold_Notification (Flow)
```

**Verification**:
```bash
sf data query --query "SELECT FullName, VersionNumber, Status FROM FlowDefinition WHERE DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'" --target-org NewOrg --use-tooling-api
```

**Expected**: 1 record, Status = "Active" or "Draft"

**If Fails**:
- Check Flow XML for syntax errors
- Verify all referenced fields exist (from Phases 1-2)
- Check Flow activation errors

**Estimated Time**: 5-10 minutes

---

### Phase 4: Activate Flow (If Deployed as Draft)

**Type**: ⚠️ Manual UI Step

**Instructions**:

1. Open NewOrg in browser
2. Navigate to: **Setup → Flows**
3. Find: **Order Consumption Multi-Threshold Notification**
4. If Status = "Draft":
   - Click flow name
   - Click **Activate**
   - Confirm activation
5. Verify Status changes to "Active"

**Verification Command**:
```bash
sf data query --query "SELECT FullName, VersionNumber, Status FROM FlowDefinition WHERE DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'" --target-org NewOrg --use-tooling-api
```

**Expected**: Status = "Active", VersionNumber = 1

**If Flow is Already Active**: Skip this step

**Estimated Time**: 2 minutes

---

### Phase 5: Configure Custom Setting Data

**Type**: ⚠️ Manual UI Step

**Instructions**:

This step depends on which POs you want to monitor. For initial setup, you can skip this or configure for a test PO.

#### Option A: Skip for Now (Recommended for Initial Deployment)
- Deploy system without monitoring any POs
- Test in sandbox/development environment first
- Add POs later when ready for production use

#### Option B: Configure Test PO (For Testing)

1. Open NewOrg in browser
2. Navigate to: **Setup → Custom Settings**
3. Find: **PO Notification Settings**
4. Click: **Manage**
5. Click: **New**
6. Fill in:
   - **Name**: `PO_TEST` (or any unique name)
   - **PO ID**: 18-character Salesforce Order ID from NewOrg
   - **PO Number**: Order number for reference
   - **Notifications Enabled**: ☑ (check)
   - **Use Repeated Reminders**: ☐ (leave unchecked)
   - **Reminder Frequency Hours**: 24
7. Click: **Save**

**Verification Command**:
```bash
sf data query --query "SELECT Name, PO_ID__c, PO_Number__c, Notifications_Enabled__c FROM PO_Notification_Settings__c" --target-org NewOrg
```

**Expected**: 0 or 1 record depending on which option chosen

**Estimated Time**: 5 minutes (if configuring test PO)

---

### Phase 6: Verify Field-Level Security

**Type**: ⚠️ Manual UI Step (Optional but Recommended)

**Instructions**:

1. Open NewOrg in browser
2. Navigate to: **Setup → Object Manager → Order**
3. Click: **Fields & Relationships**
4. For each notification field (6 total):
   - Click field name
   - Click: **Set Field-Level Security**
   - Verify appropriate profiles have Read/Edit access
   - Recommended: System Administrator = Read ✅ Edit ✅
5. Navigate to: **Setup → Object Manager → PO Notification Settings**
6. Repeat for Custom Setting fields (5 total)

**Verification**: Manual review of field permissions

**Estimated Time**: 10 minutes

---

### Phase 7: Test Email Delivery

**Type**: ⚠️ Manual UI Step (Recommended)

**Instructions**:

1. Find a test Order in NewOrg (or create one)
2. Verify it has:
   - Max_Value__c populated
   - Consumed_Amount__c populated
   - Consumed_Amount_Percent__c calculated
3. Add this Order to Custom Setting (if not already):
   - Name: `PO_TEST`
   - PO_ID__c: {Order.Id}
   - PO_Number__c: {Order.OrderNumber}
   - Notifications_Enabled__c: TRUE
4. Edit the test Order:
   - Set Consumed_Amount__c to 55% of Max_Value__c
   - Example: If Max = £100, set Consumed = £55
5. Save the Order
6. Check email inboxes for all 4 recipients:
   - customerservice@recyclinglives-services.com
   - kaylie.morris@recyclinglives-services.com
   - mark.simpson@recyclinglives-services.com
   - dennis.dadey@recyclinglives-services.com
7. Verify 50% email received

**Verification Command**:
```bash
# Check if notification was marked
sf data query --query "SELECT OrderNumber, Consumed_Amount_Percent__c, Notified_50_Percent__c, Notified_75_Percent__c, Notified_90_Percent__c FROM Order WHERE Id = 'YOUR_TEST_ORDER_ID'" --target-org NewOrg
```

**Expected**: Notified_50_Percent__c = true

**If Email Not Received**:
- Check org email deliverability settings
- Verify email addresses are valid
- Check Setup → Email Log Files for delivery status
- Check Flow execution errors: Setup → Flows → Flow name → View Run History

**Estimated Time**: 15-20 minutes

---

## Code Files Reference

### Deployment Package Contents

**Total Files**: 13 metadata files

#### Custom Setting (1 object + 5 fields = 6 files)

```
code/PO_Notification_Settings__c/
├── PO_Notification_Settings__c.object-meta.xml
└── fields/
    ├── Notifications_Enabled__c.field-meta.xml
    ├── PO_ID__c.field-meta.xml
    ├── PO_Number__c.field-meta.xml
    ├── Reminder_Frequency_Hours__c.field-meta.xml
    └── Use_Repeated_Reminders__c.field-meta.xml
```

**Purpose**: Configuration storage for monitored POs

---

#### Order Notification Fields (6 files)

```
code/Order_fields/
├── Notified_50_Percent__c.field-meta.xml
├── Notified_75_Percent__c.field-meta.xml
├── Notified_90_Percent__c.field-meta.xml
├── Last_Notified_50_Percent__c.field-meta.xml
├── Last_Notified_75_Percent__c.field-meta.xml
└── Last_Notified_90_Percent__c.field-meta.xml
```

**Purpose**: Track notification state per Order

---

#### Flow (1 file)

```
code/flows/
└── Order_Consumption_Multi_Threshold_Notification.flow-meta.xml
```

**Purpose**: Core business logic - monitoring, decision making, email sending

**Key Features**:
- Record-triggered on Order After Save (Update only)
- Custom Setting lookup
- Option B reset logic (3 formulas)
- 3 threshold checks (90%, 75%, 50%)
- Email sending (embedded templates)
- Notification marking

---

## Post-Deployment Validation

### Validation Checklist

#### 1. Component Existence

- [ ] Custom Setting exists: `PO_Notification_Settings__c`
- [ ] Custom Setting has 5 fields
- [ ] Order has 6 new notification fields
- [ ] Flow exists: `Order_Consumption_Multi_Threshold_Notification`
- [ ] Flow is Active

**Commands**:
```bash
# Custom Setting
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'PO_Notification_Settings'" --target-org NewOrg --use-tooling-api

# Order Fields
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND (QualifiedApiName LIKE 'Notified%' OR QualifiedApiName LIKE 'Last_Notified%')" --target-org NewOrg --use-tooling-api

# Flow
sf data query --query "SELECT FullName, Status FROM FlowDefinition WHERE DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'" --target-org NewOrg --use-tooling-api
```

---

#### 2. Flow Activation Status

- [ ] Flow status = "Active"
- [ ] Flow version = 1 or higher
- [ ] No Flow errors in run history

**Command**:
```bash
sf data query --query "SELECT FullName, VersionNumber, Status FROM FlowDefinition WHERE DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'" --target-org NewOrg --use-tooling-api
```

**Expected**: Status = "Active"

---

#### 3. Custom Setting Data (If Configured)

- [ ] At least one Custom Setting record exists (if POs configured)
- [ ] PO_ID__c matches valid Order IDs
- [ ] Notifications_Enabled__c = TRUE for monitored POs

**Command**:
```bash
sf data query --query "SELECT Name, PO_ID__c, PO_Number__c, Notifications_Enabled__c FROM PO_Notification_Settings__c" --target-org NewOrg
```

---

#### 4. Field-Level Security

- [ ] System Administrator profile has access to all 6 Order notification fields
- [ ] System Administrator profile has access to all 5 Custom Setting fields
- [ ] Other relevant profiles configured as needed

**Verification**: Manual review in Setup

---

#### 5. Email Deliverability

- [ ] Org deliverability = "All Email" or "System Email Only"
- [ ] Test email sent successfully
- [ ] Flow can send emails without errors

**Command**:
```bash
# Check org wide email settings
# (Manual check in Setup → Email Administration → Deliverability)
```

---

#### 6. Flow Execution Test

- [ ] Flow executes when Order updated
- [ ] Flow correctly identifies monitored POs via Custom Setting
- [ ] Flow sends email at correct threshold
- [ ] Flow marks notification checkboxes correctly
- [ ] Flow resets checkboxes when consumption drops (Option B logic)

**Test Procedure**: See "Phase 7: Test Email Delivery" above

---

## Rollback Procedures

### Immediate Rollback (If Major Issues During Deployment)

#### Scenario: Deployment failed mid-process

**Steps**:

1. **Deactivate Flow** (if partially deployed):
```bash
# Cannot deactivate via CLI - use UI
# Setup → Flows → Find flow → Deactivate
```

2. **Delete Custom Setting Data**:
```bash
# Query for IDs
sf data query --query "SELECT Id FROM PO_Notification_Settings__c" --target-org NewOrg

# Delete records
sf data delete record -s PO_Notification_Settings__c -i {RECORD_ID} --target-org NewOrg
```

3. **Stop Here**: Do not delete metadata components unless absolutely necessary
   - Fields cannot be deleted if data exists
   - Custom Setting cannot be deleted if records exist
   - Flow can be deactivated but not easily deleted

**Result**: System inactive but components remain (safest approach)

---

### Partial Rollback (If Issues After Deployment)

#### Scenario: System deployed but causing problems

**Option 1: Disable Monitoring** (Recommended)

1. Deactivate Flow:
   - Setup → Flows → Flow name → Deactivate
2. Delete Custom Setting records:
   - Setup → Custom Settings → Manage → Delete all records
3. System stops monitoring immediately
4. No metadata deletion required

**Option 2: Delete Custom Setting Records Only**
- Removes all monitored POs
- Flow still exists but won't trigger (no Custom Setting data)
- Quickest way to stop notifications

---

### Full Rollback (If Complete Removal Required)

#### Scenario: Must remove all components

**⚠️ WARNING**: Full rollback is complex and may not be possible if data exists

**Steps**:

1. Deactivate Flow (Setup → Flows)
2. Delete all Custom Setting data
3. Delete Flow:
```bash
# May require using Salesforce UI or IDE
# CLI deletion often fails for flows
```
4. Delete Order fields:
   - May fail if Order records have data in these fields
   - May need to clear field data first
5. Delete Custom Setting:
   - May fail if references exist

**Estimated Time**: 1-2 hours (if possible at all)

**Recommendation**: **Do not attempt full rollback**. Use partial rollback instead.

---

## Testing Plan

### Unit Testing

**What to Test**: Individual Flow elements

**Test Cases**:

1. **Custom Setting Lookup**:
   - ✅ Flow finds Custom Setting record when PO_ID matches
   - ✅ Flow handles missing Custom Setting record gracefully
   - ✅ Flow checks Notifications_Enabled__c correctly

2. **Option B Reset Logic**:
   - ✅ Checkbox unchecked when consumption drops below 50%
   - ✅ Checkbox unchecked when consumption drops below 75%
   - ✅ Checkbox unchecked when consumption drops below 90%
   - ✅ Checkbox NOT unchecked if consumption still above threshold

3. **Threshold Decisions**:
   - ✅ 50% email sent when consumption = 50-74% AND checkbox = FALSE
   - ✅ 75% email sent when consumption = 75-89% AND checkbox = FALSE
   - ✅ 90% email sent when consumption >= 90% AND checkbox = FALSE
   - ✅ No email sent if checkbox = TRUE

---

### Integration Testing

**What to Test**: End-to-end scenarios

**Test Cases**:

1. **New PO Crosses 50% Threshold**:
   - Setup: PO at 0%, Custom Setting configured
   - Action: Update Consumed_Amount to 55% of Max_Value
   - Expected: 50% email sent, Notified_50_Percent__c = TRUE

2. **PO Crosses Multiple Thresholds Sequentially**:
   - Setup: PO at 0%
   - Action 1: Update to 55% → Expect 50% email
   - Action 2: Update to 80% → Expect 75% email
   - Action 3: Update to 95% → Expect 90% email (URGENT)

3. **Option B: Consumption Drops and Re-rises**:
   - Setup: PO at 60%, Notified_50_Percent__c = TRUE
   - Action 1: Update to 45% → Expect checkbox reset to FALSE
   - Action 2: Update to 55% → Expect 50% email sent again

4. **Disabled Monitoring**:
   - Setup: Custom Setting with Notifications_Enabled__c = FALSE
   - Action: Update PO to 90%
   - Expected: No email sent

5. **Unmonitored PO**:
   - Setup: PO not in Custom Setting
   - Action: Update PO to 90%
   - Expected: No email sent

---

### User Acceptance Testing (UAT)

**What to Test**: Real-world business scenarios

**Test Cases**:

1. **Production PO Monitoring**:
   - Add real production PO to Custom Setting
   - Monitor for 1 week
   - Verify notifications sent at correct times
   - Verify stakeholders receive emails

2. **Email Content Validation**:
   - Verify email subject lines correct
   - Verify PO details accurate in email body
   - Verify link to PO works
   - Verify all 4 recipients receive emails

3. **Administrative Tasks**:
   - Add new PO to monitoring (Custom Setting)
   - Disable monitoring for a PO
   - Re-enable monitoring
   - Manually resend notification (uncheck checkbox)

---

## Known Risks & Mitigation

### Risk 1: Flow Recursion

**Description**: If Flow updates Order, it might trigger itself repeatedly

**Likelihood**: Low (Flow only triggers on Update, and Flow's own updates use same transaction)

**Impact**: High (could cause governor limit errors)

**Mitigation**:
- Flow designed to avoid recursion (no DML on trigger record during reset)
- Reset logic uses Record Update element on $Record (same transaction)
- Monitor Flow execution count in first 24 hours

**Detection**:
```bash
# Check Flow run history for excessive executions
Setup → Flows → Flow name → Run History
```

---

### Risk 2: Email Deliverability

**Description**: Emails might not reach recipients (spam filters, invalid addresses)

**Likelihood**: Medium (email delivery always has some risk)

**Impact**: Medium (notifications missed but system still functional)

**Mitigation**:
- Verify org email deliverability settings before deployment
- Test with valid email addresses
- Check email logs after first notification
- Add disclaimer footer (already in email templates)

**Detection**:
```bash
# Check email logs
Setup → Email Log Files → Search for "Purchase Order"
```

---

### Risk 3: Missing Pre-existing Fields

**Description**: Order consumption fields might not exist in NewOrg

**Likelihood**: Low (verification showed they exist)

**Impact**: High (Flow will fail to deploy)

**Mitigation**:
- Pre-deployment verification (Phase "Pre-Deployment Environment Verification")
- Deploy test run in sandbox first

**Detection**: Deployment will fail with error about missing fields

---

### Risk 4: Order Object Limits

**Description**: Order object might be at field limit (can't add 6 fields)

**Likelihood**: Low (standard objects have high limits)

**Impact**: High (deployment will fail)

**Mitigation**:
- Check current field count before deployment
- If at limit, remove unused fields first

**Detection**:
```bash
# Count existing Order fields
sf data query --query "SELECT COUNT(Id) FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order'" --target-org NewOrg --use-tooling-api
```

---

### Risk 5: Different PO Structure in NewOrg

**Description**: Orders in NewOrg might have different field values or structure

**Likelihood**: Medium (different org, different data)

**Impact**: Medium (notifications might not trigger as expected)

**Mitigation**:
- Test with actual NewOrg Orders
- Verify Max_Value__c and Consumed_Amount__c are populated correctly
- Verify Consumed_Amount_Percent__c calculation works

**Detection**: Monitor for 1 week after deployment

---

## Additional Notes

### Post-Deployment Configuration Tasks

After successful deployment, perform these configuration tasks as needed:

1. **Add Production POs to Monitoring**:
   - Identify POs to monitor (consult with Alisha Miller / Kaylie Morris)
   - Add each PO to Custom Setting
   - Test with one PO before adding others

2. **Configure Email Recipients** (if different in NewOrg):
   - Flow has hardcoded email addresses:
     - customerservice@recyclinglives-services.com
     - kaylie.morris@recyclinglives-services.com
     - mark.simpson@recyclinglives-services.com
     - dennis.dadey@recyclinglives-services.com
   - If NewOrg uses different addresses, Flow needs to be modified

3. **Set Field-Level Security**:
   - Grant appropriate profile access to notification fields
   - Minimum: System Administrator needs Read/Edit

4. **Create Reports/Dashboards** (Optional):
   - Report showing all monitored POs with current consumption
   - Dashboard with notification history

---

### Monitoring & Maintenance

**First 24 Hours**:
- Check Flow run history every 2 hours
- Monitor email logs
- Verify no errors

**First Week**:
- Daily check of Flow run history
- Review any failed Flow executions
- Verify stakeholders receiving emails

**Ongoing**:
- Weekly review of monitored POs
- Monthly review of Flow execution errors
- Quarterly stakeholder feedback

---

## Deployment Checklist

Use this checklist during deployment:

- [ ] Pre-deployment verification completed
- [ ] All required permissions confirmed
- [ ] Custom Setting deployed successfully
- [ ] Order notification fields deployed successfully
- [ ] Flow deployed successfully
- [ ] Flow activated
- [ ] Custom Setting data configured (if applicable)
- [ ] Field-level security configured
- [ ] Test Order updated to trigger notification
- [ ] Test email received by all 4 recipients
- [ ] Post-deployment validation completed
- [ ] Stakeholders notified of deployment
- [ ] Documentation updated
- [ ] Monitoring plan in place

---

## Success Criteria

Deployment is considered successful when:

✅ **All components deployed**: Custom Setting + 6 Order fields + Flow
✅ **Flow is Active**: Status = Active in NewOrg
✅ **No deployment errors**: All CLI deployments succeeded
✅ **Test email sent**: At least one threshold notification received
✅ **Checkboxes working**: Notification state tracking functional
✅ **Reset logic working**: Option B reset tested and verified
✅ **Zero errors**: No Flow execution errors in run history

---

## Support & Troubleshooting

**Technical Issues**: Review Flow run history (Setup → Flows → Flow name → Run History)

**Email Delivery Issues**: Check Setup → Email Log Files

**Configuration Questions**: Refer to [OldOrg Documentation](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/po-consumption-emails)

**Business Questions**: Contact Alisha Miller or Kaylie Morris

---

**Migration Package Status**: ✅ READY FOR DEPLOYMENT
**Code Files**: 13 files prepared
**Estimated Deployment Time**: 1.5-2 hours
**Risk Level**: Low-Medium
**Rollback Options**: Available (deactivate Flow + delete Custom Setting data)

---

*This migration package was created as part of the OldOrg → NewOrg migration project.*
*Last updated: October 23, 2025*
