# PO Consumption Email Notifications - NewOrg Migration Plan

**Scenario**: Purchase Order Consumption Monitoring System
**Migration Date**: TBD
**Priority**: 🟡 Medium (Batch 2)
**Estimated Time**: 3-4 hours
**Complexity**: Medium

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Gap Analysis](#gap-analysis)
3. [Migration Strategy](#migration-strategy)
4. [Pre-Deployment Environment Verification](#pre-deployment-environment-verification)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment Validation](#post-deployment-validation)
7. [Rollback Plan](#rollback-plan)
8. [Testing Plan](#testing-plan)
9. [Known Issues & Risks](#known-issues--risks)

---

## Executive Summary

### What's Being Migrated

Automated email notification system that monitors Purchase Order consumption and alerts stakeholders when consumption reaches critical thresholds (50%, 75%, 90%).

### Components to Deploy

- 1 Custom Setting object with 5 fields
- 6 Order object fields (3 checkboxes + 3 date/time fields)
- 3 Email templates (50%, 75%, 90% alerts)
- 1 Record-triggered Flow

### Business Value

- **Proactive Monitoring**: Alert stakeholders before POs are fully consumed
- **Prevents Service Disruption**: Ensure new POs obtained before current PO exhausted
- **Configurable**: Easy to add/remove POs from monitoring
- **Scalable**: No code changes needed to monitor additional POs

### Current Status in OldOrg

**Deployed**: October 14, 2025
**Active POs Monitored**: 1 (Order #00059438)
**System Health**: ✅ Fully functional
**Notifications Sent**: 0 (PO at 0% consumption)

---

## Gap Analysis

### Gap Analysis: OldOrg vs NewOrg

**Comparison Date**: October 22, 2025

| Component | OldOrg Status | NewOrg Status | Gap | Action Required |
|-----------|---------------|---------------|-----|-----------------|
| **Custom Setting** | | | | |
| PO_Notification_Settings__c | ✅ Deployed (Oct 14) | ❌ Not Found | Missing object | Deploy Custom Setting + 5 fields |
| **Order Fields** | | | | |
| Notified_50_Percent__c | ✅ Exists | ❌ Not Found | Missing field | Deploy checkbox field |
| Notified_75_Percent__c | ✅ Exists | ❌ Not Found | Missing field | Deploy checkbox field |
| Notified_90_Percent__c | ✅ Exists | ❌ Not Found | Missing field | Deploy checkbox field |
| Notified_50_Percent_Date__c | ✅ Exists | ❌ Not Found | Missing field | Deploy DateTime field |
| Notified_75_Percent_Date__c | ✅ Exists | ❌ Not Found | Missing field | Deploy DateTime field |
| Notified_90_Percent_Date__c | ✅ Exists | ❌ Not Found | Missing field | Deploy DateTime field |
| **Email Templates** | | | | |
| PO_Consumption_50_Percent_Alert | ✅ Exists | ❌ Not Found | Missing template | Deploy email template |
| PO_Consumption_75_Percent_Alert | ✅ Exists | ❌ Not Found | Missing template | Deploy email template |
| PO_Consumption_90_Percent_Alert | ✅ Exists | ❌ Not Found | Missing template | Deploy email template |
| **Flow** | | | | |
| Order_Consumption_Multi_Threshold_Notification | ✅ Active (V1) | ❌ Not Found | Missing flow | Deploy + activate flow |

### Missing Features in NewOrg

#### 🚨 Critical Missing (System Won't Work)

1. **Custom Setting Object** - Required for PO configuration
   - Without this: Flow cannot determine which POs to monitor
   - Impact: System will not function

2. **Order Notification Fields** - Required to track notification state
   - Without these: Flow cannot prevent duplicate emails
   - Impact: Stakeholders receive repeated emails every time Order updates

3. **Email Templates** - Required for formatted notifications
   - Without these: Flow cannot send emails
   - Impact: No notifications sent

4. **Flow** - Required for monitoring logic
   - Without this: No automation
   - Impact: System does not exist

---

## Migration Strategy

### Deployment Order

**Phase 1**: Custom Setting (foundation)
**Phase 2**: Order Fields (state tracking)
**Phase 3**: Email Templates (communication)
**Phase 4**: Flow (automation logic)
**Phase 5**: Configuration (Custom Setting data)

### Why This Order

1. **Custom Setting First**: Flow references this object, must exist before Flow deployment
2. **Order Fields Second**: Flow updates these fields, must exist before Flow deployment
3. **Email Templates Third**: Flow sends these emails, must exist before Flow activation
4. **Flow Fourth**: All dependencies met, can deploy and activate
5. **Configuration Last**: Manual step to add monitored POs

### Estimated Timeline

| Phase | Component | Time |
|-------|-----------|------|
| Phase 1 | Custom Setting | 30 min |
| Phase 2 | Order Fields | 45 min |
| Phase 3 | Email Templates | 30 min |
| Phase 4 | Flow | 45 min |
| Phase 5 | Configuration | 15 min |
| **Testing** | Full validation | 30 min |
| **Total** | | **3-4 hours** |

---

## Pre-Deployment Environment Verification

### Verify Dependencies Exist in NewOrg

#### Check Order Object Exists

```bash
sf data query --query "SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'Order'" --target-org NewOrg
```

**Expected**: 1 row returned (Order object exists)
**If Not Found**: Standard Order object should exist, verify org setup

#### Check Required Order Fields

```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND QualifiedApiName IN ('TotalAmount', 'OrderNumber', 'Status')" --target-org NewOrg
```

**Expected**: 3 rows (TotalAmount, OrderNumber, Status)
**If Not Found**: Standard fields missing, contact Salesforce support

#### Check Email Deliverability

```bash
sf data query --query "SELECT Id, EmailEncodingKey, LocaleSidKey FROM Organization" --target-org NewOrg
```

**Expected**: Organization configured for email
**Action**: Verify SMTP settings allow outbound email

#### Check for Conflicting Flows

```bash
sf data query --query "SELECT Definition.DeveloperName, Status FROM Flow WHERE Definition.DeveloperName LIKE '%Order%Consumption%' OR Definition.DeveloperName LIKE '%PO%Notification%'" --target-org NewOrg --use-tooling-api
```

**Expected**: 0 rows (no conflicts)
**If Found**: Review existing flows, may need different naming

---

## Deployment Steps

### Phase 1: Deploy Custom Setting

#### Step 1.1: Deploy Custom Setting Object

**Command**:
```bash
sf project deploy start \
  --source-dir force-app/main/default/objects/PO_Notification_Settings__c \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output**:
```
Deploy ID: 0AfSq000...
Status: Succeeded
Components: 1 CustomObject, 5 CustomFields
```

**Immediate Verification**:
```bash
sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'PO_Notification_Settings__c'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 1 row (PO_Notification_Settings__c)

**✅ If Successful**: Proceed to Phase 2
**❌ If Failed**:
- Error: "Insufficient privileges" → Check deploying user has Modify All Data
- Error: "Object already exists" → Verify not deployed previously, check object name

---

### Phase 2: Deploy Order Fields

#### Step 2.1: Deploy All 6 Order Fields

**Command**:
```bash
sf project deploy start \
  --source-dir force-app/main/default/objects/Order/fields/Notified_50_Percent__c.field-meta.xml \
  --source-dir force-app/main/default/objects/Order/fields/Notified_75_Percent__c.field-meta.xml \
  --source-dir force-app/main/default/objects/Order/fields/Notified_90_Percent__c.field-meta.xml \
  --source-dir force-app/main/default/objects/Order/fields/Notified_50_Percent_Date__c.field-meta.xml \
  --source-dir force-app/main/default/objects/Order/fields/Notified_75_Percent_Date__c.field-meta.xml \
  --source-dir force-app/main/default/objects/Order/fields/Notified_90_Percent_Date__c.field-meta.xml \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output**:
```
Deploy ID: 0AfSq000...
Status: Succeeded
Components: 6 CustomFields
```

**Immediate Verification**:
```bash
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND QualifiedApiName LIKE 'Notified_%'" --target-org NewOrg
```

**Expected Result**: 6 rows (all notification fields)

**✅ If Successful**: Proceed to Phase 3
**❌ If Failed**:
- Error: "Field already exists" → Check if partially deployed, verify field names
- Error: "Invalid field type" → Check metadata XML matches OldOrg

---

### Phase 3: Deploy Email Templates

#### Step 3.1: Deploy All 3 Email Templates

**Command**:
```bash
sf project deploy start \
  --source-dir force-app/main/default/email \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output**:
```
Deploy ID: 0AfSq000...
Status: Succeeded
Components: 3 EmailTemplate
```

**Immediate Verification**:
```bash
sf data query --query "SELECT Name, Subject FROM EmailTemplate WHERE Name LIKE '%PO%Consumption%'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 3 rows (50%, 75%, 90% templates)

**✅ If Successful**: Proceed to Phase 4
**❌ If Failed**:
- Error: "Invalid email template" → Check HTML syntax in templates
- Error: "Missing folder" → Create email folder first: `unfiled$public`

---

### Phase 4: Deploy Flow

#### Step 4.1: Deploy Flow (Inactive)

**Command**:
```bash
sf project deploy start \
  --source-dir force-app/main/default/flows/Order_Consumption_Multi_Threshold_Notification.flow-meta.xml \
  --target-org NewOrg \
  --test-level NoTestRun \
  --wait 10
```

**Expected Output**:
```
Deploy ID: 0AfSq000...
Status: Succeeded
Components: 1 Flow
Note: Flow deployed as Draft/Inactive
```

**Immediate Verification**:
```bash
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName = 'Order_Consumption_Multi_Threshold_Notification'" --target-org NewOrg --use-tooling-api
```

**Expected Result**: 1 row, Status = Draft or Inactive

**✅ If Successful**: Proceed to Step 4.2
**❌ If Failed**:
- Error: "Invalid flow" → Check flow XML syntax
- Error: "Missing referenced component" → Verify Custom Setting + Fields deployed

---

#### Step 4.2: Activate Flow

**Manual Steps** (via Salesforce UI):

1. Navigate to Setup → Flows
2. Search for: `Order_Consumption_Multi_Threshold_Notification`
3. Click flow name to open
4. Click: **Activate**
5. Confirm activation

**OR via CLI** (if flow deploys as Active):
```bash
# Flow should auto-activate if Status=Active in XML
# Verify:
sf data query --query "SELECT Status FROM Flow WHERE Definition.DeveloperName = 'Order_Consumption_Multi_Threshold_Notification' AND VersionNumber = 1" --target-org NewOrg --use-tooling-api
```

**Expected**: Status = Active

**✅ If Successful**: Proceed to Phase 5
**❌ If Failed**:
- Flow shows errors → Review error messages, fix dependencies
- Cannot activate → Check all Custom Setting + Fields exist

---

### Phase 5: Configuration

#### Step 5.1: Add PO to Custom Setting

**Manual Steps**:

1. Navigate to: Setup → Custom Settings
2. Find: **PO Notification Settings**
3. Click: **Manage**
4. Click: **New**
5. Fill in:
   - **Name**: `PO_00059438`
   - **PO ID**: `801Sj00000OjGCUIA3` (update with NewOrg Order ID)
   - **PO Number**: `00059438`
   - **Notifications Enabled**: ☑ (checked)
   - **Use Repeated Reminders**: ☐ (unchecked)
   - **Reminder Frequency Hours**: `24`
6. Click: **Save**

**Verification Query**:
```bash
sf data query --query "SELECT Name, PO_ID__c, PO_Number__c, Notifications_Enabled__c FROM PO_Notification_Settings__c" --target-org NewOrg
```

**Expected**: 1 row with PO_00059438 configuration

**✅ If Successful**: Proceed to Post-Deployment Validation
**❌ If Failed**:
- Custom Setting not visible → Check object deployment, refresh metadata
- Cannot save → Check required fields, data types

---

## Post-Deployment Validation

### Component Verification (Must Complete All)

- [ ] **Custom Setting Object**: Exists in NewOrg
  ```bash
  sf data query --query "SELECT DeveloperName FROM CustomObject WHERE DeveloperName = 'PO_Notification_Settings__c'" --target-org NewOrg --use-tooling-api
  ```
  ✅ Expected: 1 row returned

- [ ] **Custom Setting Data**: OrgDefaults or PO-specific record exists
  ```bash
  sf data query --query "SELECT Name, Notifications_Enabled__c FROM PO_Notification_Settings__c WHERE Name = 'PO_00059438'" --target-org NewOrg
  ```
  ✅ Expected: Notifications_Enabled__c = TRUE

- [ ] **Order Fields**: All 6 fields exist
  ```bash
  sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order' AND QualifiedApiName LIKE 'Notified_%'" --target-org NewOrg
  ```
  ✅ Expected: 6 rows

- [ ] **Email Templates**: All 3 templates exist
  ```bash
  sf data query --query "SELECT Name FROM EmailTemplate WHERE Name LIKE '%PO%Consumption%'" --target-org NewOrg --use-tooling-api
  ```
  ✅ Expected: 3 rows

- [ ] **Flow**: Active version exists
  ```bash
  sf data query --query "SELECT Status FROM Flow WHERE Definition.DeveloperName = 'Order_Consumption_Multi_Threshold_Notification' AND Status = 'Active'" --target-org NewOrg --use-tooling-api
  ```
  ✅ Expected: Status = Active

### Functional Verification (Must Test All)

#### Test 1: Flow Triggers on Order Update

**Action**: Update monitored Order (add note to Description field)

**Expected**:
- Flow executes (check Debug Logs)
- No errors in flow execution
- No emails sent (consumption still 0%)

**Verification**:
```bash
# Check flow execution in Debug Logs (Setup → Debug Logs)
# OR query Flow Interview:
sf data query --query "SELECT Status, CurrentElement FROM FlowInterview WHERE Name LIKE '%Order_Consumption%' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg --use-tooling-api
```

**✅ Pass**: Flow executed without errors
**❌ Fail**: Review Debug Logs for errors

---

#### Test 2: 50% Threshold Email

**Action**: Update Order to 50% consumption

**Setup**:
1. Navigate to test Order in NewOrg
2. Update a field to simulate 50% consumption (if `Consumed_Amount__c` is editable)
3. OR manually set: `Notified_50_Percent__c = FALSE` and `Consumed_Percent__c >= 50`

**Expected**:
- Flow detects 50% threshold crossed
- Email sent to 4 recipients
- `Notified_50_Percent__c = TRUE`
- `Notified_50_Percent_Date__c` populated with timestamp

**Verification**:
```bash
# Check Order field:
sf data query --query "SELECT Notified_50_Percent__c, Notified_50_Percent_Date__c FROM Order WHERE Id = '801Sj...' LIMIT 1" --target-org NewOrg

# Check Email Logs:
sf data query --query "SELECT Subject, ToAddress, Status FROM EmailMessage WHERE Subject LIKE '%50% Consumed%' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg
```

**✅ Pass**: Email sent, checkbox marked
**❌ Fail**: Check Debug Logs, verify email template exists

---

#### Test 3: Reset Logic (Consumption Drops)

**Action**: Update Order to <50% consumption (e.g., 45%)

**Expected**:
- Flow executes
- `Notified_50_Percent__c` automatically resets to FALSE
- No email sent

**Verification**:
```bash
sf data query --query "SELECT Notified_50_Percent__c FROM Order WHERE Id = '801Sj...' LIMIT 1" --target-org NewOrg
```

**✅ Pass**: Checkbox = FALSE (auto-reset)
**❌ Fail**: Check flow reset logic formula

---

#### Test 4: Re-notification After Reset

**Action**: Update Order back to 52% consumption

**Expected**:
- Flow detects 50% threshold crossed again
- Email sent again (because checkbox was reset)
- `Notified_50_Percent__c = TRUE`

**Verification**: Same as Test 2

**✅ Pass**: Second email sent successfully
**❌ Fail**: Reset logic not working

---

#### Test 5: Multiple Thresholds

**Action**: Update Order to 78% consumption

**Expected**:
- Flow checks all thresholds
- Only 75% email sent (not 50%, not 90%)
- `Notified_75_Percent__c = TRUE`
- `Notified_50_Percent__c` remains FALSE (wasn't crossed)

**Verification**:
```bash
sf data query --query "SELECT Notified_50_Percent__c, Notified_75_Percent__c, Notified_90_Percent__c FROM Order WHERE Id = '801Sj...' LIMIT 1" --target-org NewOrg
```

**✅ Pass**: Only 75% checkbox TRUE
**❌ Fail**: Check flow threshold logic order

---

### Success Criteria

**All Must Pass**:
- ✅ Custom Setting deployed and configured
- ✅ All 6 Order fields exist
- ✅ All 3 email templates deployed
- ✅ Flow Active and executing on Order updates
- ✅ 50% threshold test passed
- ✅ 75% threshold test passed
- ✅ 90% threshold test passed (if applicable)
- ✅ Reset logic test passed
- ✅ Re-notification test passed
- ✅ Emails delivered to all 4 recipients

---

## Rollback Plan

### Immediate Rollback (< 15 minutes)

If critical issues detected:

#### Option 1: Deactivate Flow Only

```bash
# Deactivate flow via UI:
# Setup → Flows → Order_Consumption_Multi_Threshold_Notification → Deactivate
```

**Impact**: Monitoring stops, no emails sent
**Data**: Order fields remain, can reactivate later
**Recommendation**: Use if emails sending incorrectly or too frequently

---

#### Option 2: Delete Custom Setting Data

```bash
# Navigate to: Setup → Custom Settings → PO Notification Settings → Manage
# Delete all records
```

**Impact**: Flow runs but finds no monitored POs, exits early
**Data**: Fields + Flow remain, can re-add POs later
**Recommendation**: Use if need to pause monitoring temporarily

---

### Full Rollback (< 1 hour)

If major issues require complete removal:

#### Step 1: Deactivate Flow

```bash
# Via UI: Setup → Flows → [Flow Name] → Deactivate
```

#### Step 2: Delete Custom Setting Records

```bash
# Delete all Custom Setting data (Manual via UI)
```

#### Step 3: Remove Components (Metadata Deployment)

**NOT RECOMMENDED** unless absolutely necessary:
- Deleting Custom Setting requires all dependent flows removed first
- Deleting Order fields may impact data

**Alternative**: Keep components deployed but inactive (safer)

---

## Testing Plan

### Test Scenarios

#### Scenario 1: New PO Monitoring

**Objective**: Verify system works for newly added PO

**Steps**:
1. Add new Order to Custom Setting
2. Update Order to 50% consumption
3. Verify email sent

**Expected**: Email delivered to 4 recipients

---

#### Scenario 2: Multiple POs

**Objective**: Ensure system handles multiple POs independently

**Steps**:
1. Add 2 POs to Custom Setting
2. Update PO #1 to 50%
3. Update PO #2 to 75%
4. Verify separate emails sent for each

**Expected**: 2 emails (one per PO)

---

#### Scenario 3: Disabled Monitoring

**Objective**: Verify Notifications_Enabled toggle works

**Steps**:
1. Set `Notifications_Enabled__c = FALSE` for a PO
2. Update that PO to 90% consumption
3. Verify NO email sent

**Expected**: No email, flow exits early

---

#### Scenario 4: Edge Case - 100% Consumption

**Objective**: Verify behavior at 100%

**Steps**:
1. Update PO to 100% consumption
2. Verify 90% email sent (if not already sent)
3. Verify no errors

**Expected**: 90% email only (system gracefully handles 100%)

---

## Known Issues & Risks

### Low Risk ✅

- **New System**: No existing processes affected
- **Isolated**: Only affects monitored POs in Custom Setting
- **Configurable**: Easy to disable via Custom Setting
- **Tested**: Fully tested in OldOrg since Oct 14, 2025

### Medium Risk ⚠️

- **Email Delivery**: Depends on SMTP configuration
  - **Mitigation**: Verify email settings before deployment
  - **Test**: Send test email before go-live

- **Formula Fields**: Requires `Consumed_Amount__c` and `Consumed_Percent__c` on Order
  - **Mitigation**: Verify these fields exist in NewOrg
  - **Action**: If missing, create calculated fields first

### Mitigation Strategies

1. **Comprehensive Testing**: Test all 3 thresholds + reset logic in NewOrg sandbox first
2. **Phased Rollout**: Start with 1 PO, monitor for 1 week, then add more
3. **Email Verification**: Verify all 4 recipients receive test emails
4. **Monitoring**: Check Debug Logs daily for first week after deployment
5. **Documentation**: Provide user guide to stakeholders on how to interpret emails

---

## Success Metrics

### Immediate (Day 1)

- ✅ All components deployed without errors
- ✅ Flow Active and visible in Setup
- ✅ Custom Setting configured with at least 1 PO
- ✅ Test emails delivered to all recipients

### Short-term (Week 1)

- ✅ No flow errors in Debug Logs
- ✅ Emails sent when thresholds crossed
- ✅ Reset logic working (checkboxes auto-reset)
- ✅ Stakeholders acknowledge receiving emails

### Long-term (Month 1)

- ✅ PO monitoring prevents service disruptions
- ✅ New POs obtained before old POs fully consumed
- ✅ System scaled to monitor additional POs (if needed)
- ✅ Zero production issues

---

## Deployment Checklist

**Pre-Deployment**:
- [ ] Review Gap Analysis
- [ ] Verify NewOrg has Order object with required fields
- [ ] Verify email delivery configured
- [ ] Backup OldOrg metadata
- [ ] Schedule deployment window

**During Deployment**:
- [ ] Phase 1: Deploy Custom Setting ✅
- [ ] Phase 2: Deploy Order Fields ✅
- [ ] Phase 3: Deploy Email Templates ✅
- [ ] Phase 4: Deploy + Activate Flow ✅
- [ ] Phase 5: Configure Custom Setting data ✅
- [ ] Run Post-Deployment Validation ✅

**Post-Deployment**:
- [ ] All 5 functional tests passed
- [ ] Email delivery verified
- [ ] Stakeholders notified of go-live
- [ ] Monitor Debug Logs for 48 hours
- [ ] Document any issues + resolutions

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Maintained By**: Migration Team
