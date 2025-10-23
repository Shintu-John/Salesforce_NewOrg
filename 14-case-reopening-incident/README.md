# Case Reopening Incident - NewOrg Prevention Guide

**Created**: October 23, 2025
**Scenario Type**: 📋 **Prevention Guide** (Lessons Learned from OldOrg Incident)
**Target Organization**: NewOrg (Recycling Lives Group)
**Status**: 📋 Prevention Checklist Ready

---

## Executive Summary

**What This Guides**: Prevention measures for NewOrg based on critical incident in OldOrg where cases failed to automatically reopen when customers replied.

**OldOrg Incident Summary** (October 16, 2025):
- **Issue**: 584 cases created without record types due to profile misconfiguration
- **Impact**: Cases failed to reopen when customers replied; 5 ignored customer emails over 7 days
- **Root Cause**: "2.0 Customer Service" profile had no Case record type access
- **Business Impact**: Critical customer escalation (Wates Construction)
- **Resolution**: Fixed profile configuration, assigned record types to all cases

**Critical Lesson for NewOrg**: **Profile configuration must be correct BEFORE go-live** to prevent cases being created without record types.

**OldOrg Reference**: See [OldOrg Incident Documentation](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/case-reopening-incident) for complete incident details.

---

## The Problem (What Happened in OldOrg)

### How Case Reopening Should Work

**Flow**: `EmailMessage_Open_Closed_Case_on_Email`

**Normal Behavior**:
1. Customer replies to closed case via email
2. Email creates EmailMessage record attached to Case
3. Flow detects: Incoming email + Case is Closed + **Case has Record Type**
4. Flow automatically sets Status = "Reopen"
5. Case returns to queue for customer service follow-up

**Expected Result**: ✅ Customer gets timely response

### What Went Wrong in OldOrg

**Profile Misconfiguration**:
- "2.0 Customer Service" profile had **NO record type access** for Cases
- Record Type field appeared greyed out when staff created cases manually
- 584 cases created with `RecordTypeId = null` (January - October 2025)

**Flow Failure**:
- Flow condition requires Case to have Record Type
- Cases without record types didn't match flow criteria
- **Cases didn't reopen when customers replied**
- Customers ignored for days/weeks

**Critical Example** (Case 00474147):
- Customer (Wates Construction) replied **5 times over 7 days**
- All emails ignored (case never reopened)
- Escalated to senior management
- Reputation damage with major client

---

## Prevention Measures for NewOrg

### ✅ **Critical Action 1: Verify Profile Configuration**

**Before NewOrg Go-Live**:

Check **ALL** profiles that create cases manually have proper Case record type access.

**Profiles to Check**:
- 2.0 Customer Service
- 2.0 - RLCS (if creates cases)
- Any other profiles used by customer service staff
- Any profiles used by call center staff

**How to Verify**:

1. Navigate to **Setup** → **Profiles**
2. Open each customer-facing profile
3. Scroll to **Record Type Settings** → **Case**
4. Verify:
   - ✅ **At least ONE record type is visible**
   - ✅ **ONE record type is set as default** (recommend: "Email")
   - ✅ **Record type access is enabled**

**Example Correct Configuration**:
```xml
<recordTypeVisibilities>
    <default>true</default>
    <recordType>Case.Email</recordType>
    <visible>true</visible>
</recordTypeVisibilities>
```

**Test**:
1. Login as a user with the profile
2. Navigate to Cases tab
3. Click **New** to create a case manually
4. Verify Record Type field is **NOT greyed out**
5. Verify Record Type defaults to "Email" (or configured default)

### ✅ **Critical Action 2: Test Case Reopening Flow**

**Test Scenario**:

1. Create a test case manually via UI (as customer service user)
2. Verify case has a Record Type assigned
3. Close the case (Status = "Case Closed")
4. Send an email to the case (simulate customer reply)
5. **Verify**: Case Status changes to "Reopen" automatically

**Expected Result**: ✅ Case reopens automatically

**If Test Fails**:
- Check case Record Type is in flow criteria (Email/Paperwork_Compliance/RLES_Invoicing/RLES_Purchase_Ledger)
- Check flow `EmailMessage_Open_Closed_Case_on_Email` is Active
- Check email routing rules assign correct Record Type

### ✅ **Critical Action 3: Monitor for NULL Record Types**

**Create Dashboard Report**:

```soql
SELECT Id, CaseNumber, Subject, CreatedDate, CreatedBy.Name, Origin
FROM Case
WHERE RecordTypeId = null
  AND CreatedDate = LAST_N_DAYS:7
ORDER BY CreatedDate DESC
```

**Alert Threshold**: **ANY case with NULL record type = immediate action required**

**Frequency**: Run daily for first 30 days after go-live, then weekly

### ✅ **Action 4: Enhance Flow (Optional Improvement)**

**Flow Enhancement Recommendation** for `Flow_to_manage_email_inbox_record_type_changes`:

**Current Behavior** (in OldOrg):
- Triggers when RecordTypeId changes to Email/RLES Invoicing/RLES Purchase Ledger
- **Always** sets Status = "Case Raised" (even if case was closed)
- Caused 143 closed cases to reopen in OldOrg incident

**Suggested Enhancement**:

Add condition to check if case is already closed before changing status:

```xml
<filterLogic>1 AND (2 or 3 or 4) AND 5</filterLogic>
<filters>
    <field>RecordTypeId</field>
    <operator>IsChanged</operator>
</filters>
<!-- New filter -->
<filters>
    <field>IsClosed</field>
    <operator>EqualTo</operator>
    <value>
        <booleanValue>false</booleanValue>
    </value>
</filters>
```

**Benefit**: Prevents mass reopening if bulk record type assignment is ever needed.

---

## Pre-Go-Live Checklist

### Profile Configuration

- [ ] Verified ALL customer service profiles have Case record type access
- [ ] Set "Email" as default record type for manual case creation
- [ ] Tested manual case creation with each profile
- [ ] Confirmed Record Type field is NOT greyed out

### Flow Testing

- [ ] Tested `EmailMessage_Open_Closed_Case_on_Email` flow
- [ ] Verified closed cases reopen when customers reply via email
- [ ] Tested with ALL record types (Email, Paperwork_Compliance, RLES_Invoicing, RLES_Purchase_Ledger)
- [ ] Confirmed flow is Active in NewOrg

### Monitoring Setup

- [ ] Created dashboard report for NULL record types
- [ ] Set up email alerts if cases created without record types
- [ ] Scheduled weekly report to admin team
- [ ] Documented escalation process if NULL record types detected

### Team Training

- [ ] Customer service staff trained on Record Type field
- [ ] Staff know Email is default record type for manual cases
- [ ] Staff know how to change record type if needed
- [ ] Staff understand importance of record types for case reopening

### Documentation

- [ ] Updated internal procedures for manual case creation
- [ ] Added Record Type field to case creation checklist
- [ ] Created troubleshooting guide for case reopening issues
- [ ] Documented which record types trigger automatic reopening

---

## Testing Procedure

### Test 1: Manual Case Creation

**Steps**:
1. Login to NewOrg as customer service user
2. Navigate to Cases → New
3. Fill in required fields
4. **Check**: Record Type field shows "Email" as default
5. **Check**: Field is NOT greyed out (can be changed)
6. Save case
7. Query case: `SELECT Id, RecordTypeId, RecordType.Name FROM Case WHERE Id = '<case_id>'`
8. **Verify**: RecordTypeId is NOT NULL
9. **Verify**: RecordType.Name = "Email"

**Expected Result**: ✅ Case created with Email record type

### Test 2: Case Reopening via Email

**Steps**:
1. Create test case with Email record type
2. Close case (Status = "Case Closed")
3. Send test email to case email address
4. Wait for email-to-case processing (usually < 1 minute)
5. Query case: `SELECT Status FROM Case WHERE Id = '<case_id>'`
6. **Verify**: Status = "Reopen"

**Expected Result**: ✅ Case automatically reopened

### Test 3: Record Type Change (Edge Case)

**Steps**:
1. Create test case with Email record type
2. Close case (Status = "Case Closed")
3. Change record type via Apex: `update new Case(Id='<id>', RecordTypeId='<different_type>');`
4. Query case: `SELECT Status FROM Case WHERE Id = '<case_id>'`
5. **Check**: If flow `Flow_to_manage_email_inbox_record_type_changes` is active
6. **Verify**: Status did NOT change (if flow enhanced) OR Status = "Case Raised" (if flow not enhanced)

**Expected Result**: Depends on flow enhancement (see Action 4 above)

---

## What to Do If NULL Record Types Are Detected

### Immediate Actions

1. **Identify Affected Cases**:
```soql
SELECT Id, CaseNumber, Subject, CreatedDate, CreatedBy.Name, Origin
FROM Case
WHERE RecordTypeId = null
  AND CreatedDate = TODAY
```

2. **Assign Record Types Immediately**:
```apex
Id emailRecordTypeId = [SELECT Id FROM RecordType
                        WHERE SobjectType = 'Case'
                        AND DeveloperName = 'Email' LIMIT 1].Id;

List<Case> casesToFix = [SELECT Id FROM Case WHERE RecordTypeId = null AND CreatedDate = TODAY];
for(Case c : casesToFix) {
    c.RecordTypeId = emailRecordTypeId;
}
update casesToFix;
```

3. **Check for Unintended Side Effects**:
   - If flow `Flow_to_manage_email_inbox_record_type_changes` is active
   - It will set Status = "Case Raised" for assigned cases
   - If any cases were closed, they will reopen (see OldOrg incident)

4. **Fix Root Cause**:
   - Identify which profile created NULL record type cases
   - Fix profile configuration immediately
   - Notify affected users
   - Retest manual case creation

### Investigation Steps

1. **Identify Which Users Created NULL Cases**:
```soql
SELECT CreatedBy.Name, CreatedBy.Profile.Name, COUNT(Id) Total
FROM Case
WHERE RecordTypeId = null
  AND CreatedDate = LAST_N_DAYS:30
GROUP BY CreatedBy.Name, CreatedBy.Profile.Name
ORDER BY COUNT(Id) DESC
```

2. **Check Profile Configuration**:
   - Navigate to Setup → Profiles → [Identified Profile]
   - Check Record Type Settings → Case
   - Fix configuration if missing

3. **Review Recent Changes**:
   - Check Setup Audit Trail for profile changes
   - Check recent metadata deployments
   - Identify when/how configuration was broken

---

## Related Flows

### Flow: EmailMessage_Open_Closed_Case_on_Email
- **Purpose**: Automatically reopen closed cases when customers reply
- **Trigger**: Incoming EmailMessage
- **Criteria**: Case is Closed AND has Record Type (Email/Paperwork_Compliance/RLES_Invoicing/RLES_Purchase_Ledger)
- **Action**: Set Status = "Reopen"
- **Must Be**: ✅ Active in NewOrg

### Flow: Flow_to_manage_email_inbox_record_type_changes
- **Purpose**: Standardize status for email-related cases
- **Trigger**: RecordTypeId changed to Email/RLES Invoicing/RLES Purchase Ledger
- **Action**: Set Status = "Case Raised"
- **Caution**: ⚠️ Can reopen closed cases if bulk record type assignment is performed
- **Recommendation**: Enhance to check IsClosed before changing status

### Flow: Case_Remove_Case_Owner_if_Reopen_24_Hours
- **Purpose**: Reassign cases after 14+ hours of inactivity
- **Trigger**: Most_Recent_Message__c changed AND >14 hours
- **Must Be**: ✅ Active in NewOrg

### Flow: Flow_to_monitor_cases_if_reopened
- **Purpose**: Clear closure tracking fields when case reopens
- **Trigger**: Status changed to "Reopen"
- **Must Be**: ✅ Active in NewOrg

**Related Scenario**: See [email-to-case-assignment](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/email-to-case-assignment) for complete email-to-case system configuration.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Profile misconfigured before go-live | Medium | **Critical** | Pre-go-live checklist, manual testing with all profiles |
| Cases created without record types | Low (if checklist complete) | High | Daily monitoring report, automatic alerts |
| Bulk assignment causes mass reopening | Low | Medium | Enhance flow to check IsClosed, test bulk operations in sandbox |
| Staff forget to assign record types | Low (if default set) | Low | Default record type configured, staff training |

---

## Key Differences: OldOrg vs NewOrg

| Aspect | OldOrg (Incident) | NewOrg (Prevention) |
|--------|------------------|---------------------|
| Profile Config | ❌ No record type access | ✅ Must verify before go-live |
| Testing | ⚠️ Not tested | ✅ Must test with all profiles |
| Monitoring | ❌ No monitoring | ✅ Daily dashboard + alerts |
| Flow Enhancement | ⚠️ Can reopen closed cases | ✅ Optional enhancement available |
| Staff Training | ⚠️ Staff unaware | ✅ Must train before go-live |

---

## Success Criteria

**NewOrg Go-Live Ready When**:

1. ✅ ALL customer service profiles have Case record type access configured
2. ✅ Manual case creation tested successfully with each profile
3. ✅ Case reopening flow tested and working correctly
4. ✅ Monitoring dashboard created and tested
5. ✅ Email alerts configured for NULL record types
6. ✅ Customer service staff trained on Record Type field
7. ✅ Flow enhancement implemented (optional but recommended)
8. ✅ Troubleshooting procedures documented

---

## Related Documentation

### Source Documentation

- [source-docs/CASE_REOPENING_INCIDENT_2025-10-16.md](source-docs/CASE_REOPENING_INCIDENT_2025-10-16.md) - Complete OldOrg incident documentation

### OldOrg Incident Analysis

- [OldOrg case-reopening-incident](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/case-reopening-incident) - Full incident details and resolution

### Related Scenarios

- [email-to-case-assignment](https://github.com/Shintu-John/Salesforce_NewOrg/tree/main/email-to-case-assignment) - Email-to-case system configuration guide

---

## Contact & Escalation

**If NULL Record Types Detected in NewOrg**:
1. Immediately assign record types to affected cases
2. Fix profile configuration
3. Notify customer service team
4. Escalate to Salesforce admin team
5. Review all recent deployments/changes

**Documentation Owner**: John Shintu
**Incident Date (OldOrg)**: October 16, 2025
**Prevention Guide Created**: October 23, 2025

---

**Prevention Status**: 📋 **Checklist Ready for NewOrg Go-Live**
**Last Updated**: October 23, 2025
**Documentation Type**: Prevention Guide (Lessons Learned)
**Scenario Classification**: Analysis / Prevention (NOT code deployment)
