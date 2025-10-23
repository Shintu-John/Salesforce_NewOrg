# Portal Exchange Email SPF Fix - NewOrg Deployment Package

**Migration Date**: October 23, 2025
**Priority**: High (Customer-Facing Portal)
**Complexity**: Medium
**Estimated Deployment Time**: 1.5-2 hours
**Status**: ⏳ **PENDING VERIFICATION** - Manual prerequisites completed, awaiting email verification

---

## 🚨 Deployment Status - October 23, 2025

### ✅ Completed Manual Prerequisites (October 23, 2025):
1. **Custom Label Created**: `From_Address_Portal_Exchanges` with value `portal-exchanges@recyclinglives-services.com`
2. **Org-Wide Email Address Created**: `portal-exchanges@recyclinglives-services.com` with Display Name "Portal Exchanges"

### ⏳ Awaiting Verification:
- **Org-Wide Email Verification**: Verification email sent, pending user to click verification link
- **Estimated Time**: 5-10 minutes once email is accessed

### 📋 Next Steps After Verification:
1. Confirm Org-Wide Email status = **Verified** in Setup
2. Deploy Apex classes and trigger (NewCaseEmailPopACCandContactHandler, NewCaseEmailPopACCandContactHandlerTest, NewCaseEmailPopACCandContact)
3. Deploy 6 Flows with fromEmailAddress parameter
4. Perform functional testing of portal email functionality
5. Document deployment in DEPLOYMENT_HISTORY.md

---

## Executive Summary

This deployment package migrates the **SPF/DMARC email validation fix** from OldOrg to NewOrg. Without this deployment, portal exchange requests from customers with strict SPF policies (e.g., Amey Highways) will fail to reach the Customer Service inbox.

**Critical Finding**: NewOrg has **OUTDATED** handler code from October 2, 2025 (14 days older than OldOrg Oct 16 version). Flows may also need updates to include `fromEmailAddress` parameter.

**Business Impact**:
- Customers with strict SPF policies cannot submit portal requests
- Emails rejected by recipient mail servers (SPF validation fails)
- No Cases created from Email-to-Case
- Portal functionality broken for Amey Highways and similar customers

---

## Related Documentation

### OldOrg State Documentation
- **Complete Implementation Details**: [OldOrg README.md](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/portal-exchange-email)
- **Source Documentation**: [source-docs/PORTAL_EXCHANGE_EMAIL_FIX_COMPLETE_GUIDE.md](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/portal-exchange-email/source-docs)

---

## Gap Analysis

### Component Status Comparison

| Component | Type | OldOrg Status | NewOrg Status | Gap | Action Required |
|-----------|------|---------------|---------------|-----|-----------------|
| **NewCaseEmailPopACCandContactHandler.cls** | ApexClass | ✅ 64 lines (Oct 16, 2025) | ⚠️ Unknown version (Oct 2, 2025) | **14 days outdated** | **DEPLOY (May have old regex or logic)** |
| **NewCaseEmailPopACCandContactHandlerTest.cls** | ApexClass | ✅ 135 lines (Oct 16, 2025) | ⚠️ Unknown version (Sept 17, 2025) | **29 days outdated** | **DEPLOY (Very old test class)** |
| **NewCaseEmailPopACCandContact.trigger** | ApexTrigger | ✅ 2 lines (Oct 16, 2025) | ✅ Exists | Needs verification | **VERIFY and DEPLOY if outdated** |
| **Exchange_Job.flow** | Flow | ✅ Modified (Oct 16) | ✅ Exists | Needs version check | **VERIFY fromEmailAddress parameter** |
| **Create_Job.flow** | Flow | ✅ Modified (Oct 16) | ✅ Exists | Needs version check | **VERIFY fromEmailAddress parameter** |
| **Create_Mixed_Waste_Type_Job.flow** | Flow | ✅ Modified (Oct 16) | ⚠️ Different name? | Needs verification | **VERIFY flow name and parameter** |
| **Cancel_Collection_Flow.flow** | Flow | ✅ Modified (Oct 16) | ✅ Exists | Needs version check | **VERIFY fromEmailAddress parameter** |
| **Cancel_Flow.flow** | Flow | ✅ Modified (Oct 16) | ✅ Exists | Needs version check | **VERIFY fromEmailAddress parameter** |
| **Job_Organise_Collection.flow** | Flow | ✅ Modified (Oct 16) | ✅ Exists | Needs version check | **VERIFY fromEmailAddress parameter** |
| **From_Address_Portal_Exchanges** | Custom Label | ✅ Exists (OldOrg) | Unknown | Not verified | **CREATE if missing** |
| **portal-exchanges@... (Org-Wide Email)** | Config | ✅ Verified (OldOrg) | Unknown | Not verified | **VERIFY or CREATE** |

### Critical Gaps Summary

**⚠️ 2 Components Definitely Outdated**:
1. **NewCaseEmailPopACCandContactHandler** - Oct 2 version (14 days older than Oct 16)
2. **NewCaseEmailPopACCandContactHandlerTest** - Sept 17 version (29 days older)

**⚠️ 6 Flows Need Verification**:
3-8. All 6 flows exist but need ACTIVE version check for `fromEmailAddress` parameter

**⚠️ 2 Configuration Items Need Verification**:
9. **Custom Label** - From_Address_Portal_Exchanges (portal-exchanges@recyclinglives-services.com)
10. **Org-Wide Email Address** - Must be verified in Setup

### Missing Functionality Risk

Without this deployment, NewOrg will experience:
- **SPF validation failures** for emails from portal users with strict SPF policies
- **Emails rejected** by recipient mail servers (never reach Customer Service)
- **No Cases created** from Email-to-Case (email doesn't arrive)
- **Portal broken** for Amey Highways and similar customers
- **Customer complaints** about portal not working

**User Impact**: High-priority customers (Amey Highways) cannot use portal functionality.

---

## Pre-Deployment Environment Verification

### 1. Check Custom Label
```bash
sf data query --query "SELECT Id, Name, Value FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'" --target-org NewOrg

# Expected: 1 record with value 'portal-exchanges@recyclinglives-services.com'
# If missing: Deploy Custom Label first
```

### 2. Verify Org-Wide Email Address
```bash
sf data query --query "SELECT Id, Address, DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE Address = 'portal-exchanges@recyclinglives-services.com'" --target-org NewOrg

# Expected: 1 record with IsAllowAllProfiles = true OR specific profile access
# If missing: Create and verify org-wide email address in Setup
```

### 3. Check Flow Active Versions
```bash
sf data query --query "SELECT Id, DeveloperName, VersionNumber, Status FROM Flow WHERE DeveloperName IN ('Exchange_Job','Create_Job','Cancel_Collection_Flow','Cancel_Flow','Job_Organise_Collection') AND Status = 'Active'" --target-org NewOrg --use-tooling-api

# Expected: 5-6 flows with Status = 'Active'
# Action: Verify each flow has fromEmailAddress parameter
```

---

## Deployment Steps

### Phase 1: ⚠️ Create/Verify Custom Label (Manual UI)

**Check if exists**:
1. Go to **Setup** → Quick Find → **Custom Labels**
2. Search for "From_Address_Portal_Exchanges"

**If Missing - Create**:
1. Click **New Custom Label**
2. Fill in:
   - Label: `From_Address_Portal_Exchanges`
   - Name: `From_Address_Portal_Exchanges`
   - Value: `portal-exchanges@recyclinglives-services.com`
   - Short Description: "From Address Portal Exchanges"
   - Language: English
   - Protected: Unchecked
3. Click **Save**

**Verification**:
```bash
sf data query --query "SELECT Id, Name, Value FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'" --target-org NewOrg
```

---

### Phase 2: ⚠️ Verify/Create Org-Wide Email Address (Manual UI)

**Check if exists**:
1. Go to **Setup** → Quick Find → **Organization-Wide Addresses**
2. Look for `portal-exchanges@recyclinglives-services.com`

**If Missing - Create**:
1. Click **Add**
2. Enter Email Address: `portal-exchanges@recyclinglives-services.com`
3. Display Name: `Portal Exchanges`
4. Click **Save**
5. **Check email** for verification link
6. Click verification link to verify address
7. Return to Setup and confirm status = **Verified**

**If Exists - Verify Status**:
- Status must be **Verified** (not Pending)
- If Pending: Resend verification email and verify

---

### Phase 3: ✅ Deploy Apex Classes and Trigger (CLI)

**Command**:
```bash
cd /tmp/Salesforce_NewOrg/portal-exchange-email/code
sf project deploy start --source-dir classes/ --source-dir triggers/ --target-org NewOrg --test-level RunLocalTests
```

**Expected Output**:
```
=== Deployed Source
FULL NAME                                 TYPE         PROJECT PATH
────────────────────────────────────────  ───────────  ──────────────────────────────────────────────────
NewCaseEmailPopACCandContactHandler       ApexClass    classes/NewCaseEmailPopACCandContactHandler.cls
NewCaseEmailPopACCandContactHandlerTest   ApexClass    classes/NewCaseEmailPopACCandContactHandlerTest.cls
NewCaseEmailPopACCandContact              ApexTrigger  triggers/NewCaseEmailPopACCandContact.trigger

Deploy Succeeded.
Test Success  100%
```

**Verification**:
```bash
sf data query --query "SELECT Id, Name, LastModifiedDate FROM ApexClass WHERE Name LIKE '%NewCaseEmailPopACCandContact%' ORDER BY LastModifiedDate DESC" --target-org NewOrg

# Expected: LastModifiedDate = TODAY (Oct 23, 2025)
```

**What This Does**:
- Updates handler with Oct 16 regex logic
- Updates test class with Oct 16 tests
- Ensures trigger calls correct handler method
- Runs all tests to verify functionality

---

### Phase 4: ⚠️ Deploy/Update Flows (Manual UI - Metadata API)

**IMPORTANT**: Flows cannot be easily updated via CLI. Two options:

**Option A: Update Each Flow Manually (Recommended for safety)**

For each flow (Exchange_Job, Create_Job, etc.):
1. Go to **Setup** → **Flows**
2. Find flow name (e.g., "Exchange_Job")
3. Click **Edit** (or create new version)
4. Find **Send Email** action
5. Verify/Add field: **From Email Address**
   - Set to: `{!$Label.From_Address_Portal_Exchanges}`
6. Click **Save**
7. Click **Activate** (new version becomes active)

**Option B: Deploy via Metadata API (Advanced)**

```bash
cd /tmp/Salesforce_NewOrg/portal-exchange-email/code
sf project deploy start --source-dir flows/ --target-org NewOrg
```

**WARNING**: This will overwrite active flow versions. Test in sandbox first!

**Flows to Update** (6 total):
1. Exchange_Job
2. Create_Job
3. Create_Mixed_Waste_Type_Job (verify name in NewOrg)
4. Cancel_Collection_Flow
5. Cancel_Flow
6. Job_Organise_Collection

---

### Phase 5: ⚠️ Update Email Templates (Manual UI)

**Templates to Update** (5 total):
1. New_Exchange_Request_Email_1_1
2. New_Job_Booking_Request_Email_1_1
3. Cancel_Collection_Customer_Email_1_1
4. Cancel_Delivery_Customer_Email_1_1
5. Organise_Collection_Customer_Email_1_0

**For Each Template**:
1. Go to **Setup** → **Email Templates**
2. Find template name
3. Click **Edit**
4. Find line: `sent by {!User.Name}`
5. Change to: `sent by {!User.Name} ({!User.Email})`
6. Update BOTH **Text Body** AND **HTML Body**
7. Click **Save**

**Why This Is Required**:
- Handler extracts portal user email from body using regex: `\(([email@domain.com])\)`
- Without email in parentheses, handler cannot match Contact/Account

---

### Phase 6: ⚠️ Test with Real Portal User (Manual)

**Prerequisites**:
- Portal user access (Community/Experience Cloud)
- Test environment or production with caution

**Test Steps**:
1. Log in as **portal user** (not internal user)
2. Navigate to portal page for job exchange/creation
3. Submit a test request (e.g., exchange job)
4. Check email sent to Customer Service:
   - FROM: portal-exchanges@recyclinglives-services.com ✅
   - Body contains: "sent by [Name] ([email])" ✅
5. Verify Case created in Salesforce:
   - Case.ContactId populated ✅
   - Case.AccountId populated ✅
   - Case.Description contains portal user email ✅

**If Test Fails**:
- Check debug logs for trigger execution
- Verify Custom Label value
- Verify org-wide email address verified
- Check flow active version has fromEmailAddress parameter

---

### Phase 7: ✅ Run Full Test Suite (CLI)

**Command**:
```bash
sf apex run test --test-level RunLocalTests --target-org NewOrg --result-format human --code-coverage --detailed-coverage
```

**Expected**:
- All tests pass (100%)
- NewCaseEmailPopACCandContactHandlerTest passes
- Code coverage >75%

---

## Code Files Reference

### Apex Classes (4 files)
- `classes/NewCaseEmailPopACCandContactHandler.cls` (64 lines) - Handler with regex
- `classes/NewCaseEmailPopACCandContactHandler.cls-meta.xml` - Metadata
- `classes/NewCaseEmailPopACCandContactHandlerTest.cls` (135 lines) - Test class
- `classes/NewCaseEmailPopACCandContactHandlerTest.cls-meta.xml` - Metadata

### Apex Triggers (2 files)
- `triggers/NewCaseEmailPopACCandContact.trigger` (2 lines) - Before update trigger
- `triggers/NewCaseEmailPopACCandContact.trigger-meta.xml` - Metadata

### Flows (6 files)
- `flows/Exchange_Job.flow-meta.xml` - Exchange job flow
- `flows/Create_Job.flow-meta.xml` - Create job flow
- `flows/Create_Mixed_Waste_Type_Job.flow-meta.xml` - Mixed waste flow
- `flows/Cancel_Collection_Flow.flow-meta.xml` - Cancel collection flow
- `flows/Cancel_Flow.flow-meta.xml` - Cancel job flow
- `flows/Job_Organise_Collection.flow-meta.xml` - Organise collection flow

**Total**: 12 files (6 Apex + 6 flows)

---

## Post-Deployment Validation

- [ ] Custom Label created/verified (From_Address_Portal_Exchanges)
- [ ] Org-wide email address verified (portal-exchanges@recyclinglives-services.com)
- [ ] Apex classes deployed (LastModifiedDate = today)
- [ ] Trigger deployed (LastModifiedDate = today)
- [ ] All 6 flows updated with fromEmailAddress parameter
- [ ] All 5 email templates updated with ({!User.Email})
- [ ] Test with portal user successful
- [ ] Case.ContactId populated correctly
- [ ] Case.AccountId populated correctly
- [ ] All Apex tests pass
- [ ] No SPF failures in email logs

---

## Rollback Procedures

**Immediate Rollback**:
```bash
# Redeploy Oct 2 versions (save before deployment)
sf project deploy start --source-dir /tmp/rollback/classes/ --target-org NewOrg
```

**Partial Rollback** (if only flows problematic):
- Deactivate new flow versions
- Reactivate previous flow versions

---

## Known Risks

### Risk 1: Flow Deployment Overwrites Active Versions
**Mitigation**: Test in sandbox first, or update manually via UI

### Risk 2: Email Template Updates May Break Regex
**Mitigation**: Exact format required: `sent by {!User.Name} ({!User.Email})`

### Risk 3: Org-Wide Email Not Verified
**Mitigation**: Verify before deployment, test email sending

---

## Success Metrics

**Deployment Success**:
- ✅ All 12 files deploy without errors
- ✅ All tests pass (100%)
- ✅ Custom Label and org-wide email configured

**Functional Success**:
- ✅ Portal emails sent from portal-exchanges@...
- ✅ SPF validation passes (no rejections)
- ✅ Cases created with Contact/Account populated
- ✅ Amey Highways and similar customers can submit requests

---

## Implementation Timeline

| Phase | Activity | Duration | Type |
|-------|----------|----------|------|
| Phase 1 | Create/Verify Custom Label | 5 min | Manual UI |
| Phase 2 | Verify Org-Wide Email | 10 min | Manual UI |
| Phase 3 | Deploy Apex classes/trigger | 10 min | CLI |
| Phase 4 | Update 6 flows | 30 min | Manual UI |
| Phase 5 | Update 5 email templates | 20 min | Manual UI |
| Phase 6 | Test with portal user | 15 min | Manual |
| Phase 7 | Run test suite | 10 min | CLI |

**Total**: 1.5-2 hours

---

**Total Files in Package**: 12 (6 Apex + 6 flows)
**Deployment Method**: CLI (Phase 3, 7) + Manual UI (Phases 1, 2, 4, 5, 6)
**Risk Level**: Medium (customer-facing portal, but reversible)
