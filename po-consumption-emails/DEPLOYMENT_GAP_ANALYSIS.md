# PO Consumption Emails - DEPLOYMENT GAP ANALYSIS

**Date**: October 22, 2025
**Finding**: Source documentation describes components that were NOT actually deployed to OldOrg

---

## Components Status

### ✅ DEPLOYED in OldOrg (Retrieved Successfully)

1. **Custom Setting**: `PO_Notification_Settings__c`
   - Location: `/code/objects/PO_Notification_Settings__c/`
   - Status: ✅ Retrieved from OldOrg
   - Fields: PO_ID__c, PO_Number__c, Notifications_Enabled__c, Use_Repeated_Reminders__c, Reminder_Frequency_Hours__c

2. **Flow**: `Order_Consumption_Multi_Threshold_Notification`
   - Location: `/code/flows/Order_Consumption_Multi_Threshold_Notification.flow-meta.xml`
   - Status: ✅ Retrieved from OldOrg
   - **WARNING**: Flow references fields that don't exist (see below)

---

## ❌ NOT DEPLOYED in OldOrg (Need to CREATE for NewOrg)

### Order__c Custom Fields (6 fields)
**Status**: ❌ NOT FOUND in OldOrg
**Impact**: CRITICAL - Flow will FAIL without these fields

The Flow references these fields in Update Records elements:
- `Order__c.Notified_50_Percent__c` (Checkbox)
- `Order__c.Notified_75_Percent__c` (Checkbox)
- `Order__c.Notified_90_Percent__c` (Checkbox)
- `Order__c.Last_Notified_50_Percent__c` (DateTime)
- `Order__c.Last_Notified_75_Percent__c` (DateTime)
- `Order__c.Last_Notified_90_Percent__c` (DateTime)

**Action Required**: Must CREATE these fields in NewOrg BEFORE deploying Flow

### Email Templates (3 templates)
**Status**: ❌ NOT FOUND in OldOrg
**Impact**: CRITICAL - Flow will FAIL without these templates

The Flow references these email actions:
- `PO_Consumption_50_Percent_Alert`
- `PO_Consumption_75_Percent_Alert`
- `PO_Consumption_90_Percent_Alert`

**Action Required**: Must CREATE these email templates in NewOrg BEFORE deploying Flow

---

## Root Cause Analysis

The source documentation (PO_CONSUMPTION_EMAIL_NOTIFICATIONS.md) appears to be a **DESIGN/PLAN** document rather than a post-deployment record. It includes:
- Deploy IDs that reference the Custom Setting and Flow (which DO exist)
- Deploy ID `0AfSj000000yjThKAI` for "Order Fields (6)" - but these fields DON'T exist
- Deploy ID `0AfSj000000yjYXKAY` for "Email Templates (3)" - but these templates DON'T exist

**Hypothesis**: The fields and email templates were PLANNED but never actually deployed to production, OR they were embedded in the Flow UI rather than as separate metadata.

---

## NewOrg Deployment Plan

### Phase 1: Create Missing Fields (MANUAL)
```bash
# Navigate to Setup → Object Manager → Order
# Create 6 custom fields per specifications in source doc
```

### Phase 2: Create Email Templates (MANUAL or via metadata)
```bash
# Option A: Create via UI (Setup → Email Templates)
# Option B: Create metadata files and deploy
```

### Phase 3: Deploy Retrieved Components
```bash
# Deploy Custom Setting
sf project deploy start \
  --source-dir po-consumption-emails/code/objects/PO_Notification_Settings__c \
  --target-org NewOrg

# Deploy Flow (AFTER fields and templates exist)
sf project deploy start \
  --source-dir po-consumption-emails/code/flows \
  --target-org NewOrg
```

### Phase 4: Activate and Configure
```bash
# 1. Activate Flow in NewOrg
# 2. Add PO records to Custom Setting
# 3. Test with sample Order updates
```

---

## Recommendation

**For complete deployment**, we need to:
1. Create field metadata files from source doc specifications
2. Create email template files from source doc specifications
3. Include all metadata in deployment package

OR

Document that NewOrg deployment requires manual setup of fields and templates before Flow deployment.
