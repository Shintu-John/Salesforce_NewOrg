# Portal Exchange Email - NewOrg Migration Plan

**Migration Date**: TBD
**Scenario**: Portal Exchange Email SPF/DMARC Fix
**OldOrg Implementation**: October 16, 2025
**Migration Status**: 📋 Ready for Review
**Priority**: 🔴 HIGH
**Estimated Time**: 2-3 hours

---

## Executive Summary

**What's Being Migrated**: Complete Portal Exchange Email SPF/DMARC fix from OldOrg to NewOrg, including:
- 2 Apex classes (handler V2 + test V2) - **REPLACE outdated V1**
- 1 Apex trigger (NewCaseEmailTrigger) - **NEW**
- 1 Custom label (From_Address_Portal_Exchanges) - **NEW**
- 5 Email templates with ({!User.Email}) pattern - **UPDATE**
- 2 Flows (Cancel_Flow, Job_Organise_Collection) - **NEW**
- 4 Flow verifications (fromEmailAddress parameter) - **VERIFY**

**Why This Migration is Needed**:
- NewOrg has **outdated V1 handler** (missing 46% of code including email extraction logic)
- **Trigger completely missing** - handler never executes
- **Custom label missing** - flow deployment will fail
- **Email templates incomplete** - regex extraction won't work
- **2 flows missing** - incomplete SPF/DMARC coverage

**Expected Benefits**:
1. ✅ All portal emails pass SPF/DMARC validation (no bounces/spam)
2. ✅ Contact/Account automatically populated from portal user email
3. ✅ Cases properly linked for reporting and portal visibility
4. ✅ Consistent FROM address across all portal email scenarios

**Migration Impact**: HIGH - Core email functionality currently broken in NewOrg

---

## Gap Analysis Summary

### Critical Components (🚨 Deployment Blockers)

| Component | OldOrg Status | NewOrg Status | Gap | Impact |
|-----------|--------------|---------------|-----|--------|
| Custom Label | ✅ EXISTS | 🚨 **MISSING** | Label not created | Flow deployment will fail |
| Trigger | ✅ Active | 🚨 **MISSING** | Not deployed | Handler never executes |
| Handler Class | V2 (2,827 lines) | V1 (1,522 lines) | **Missing 46% of code** | Email extraction broken |
| Cancel_Flow | V4 Active | 🚨 **NOT ACTIVE** | Flow missing | Cancellation SPF fails |
| Job_Organise_Collection | V23 Active | 🚨 **NOT ACTIVE** | Flow missing | Collection SPF fails |

### High Priority Components (⚠️ Functional Issues)

| Component | OldOrg Status | NewOrg Status | Gap | Impact |
|-----------|--------------|---------------|-----|--------|
| Test Class | V2 (5,608 lines) | V1 (1,660 lines) | **Missing 70% of code** | Cannot verify V2 works |
| Email Templates (5) | Has ({!User.Email}) | Missing ({!User.Email}) | Pattern incomplete | Regex extraction fails |

### Verification Required (✅ Existing Components)

| Component | OldOrg Version | NewOrg Version | Status | Action |
|-----------|---------------|---------------|--------|--------|
| Exchange_Job | V42 | V1 | ✅ Has fromEmailAddress | Verify parameter value |
| Create_Job | V58 | V1 | ✅ Has fromEmailAddress | Verify parameter value |
| Create_Mixed_Waste_Type_Job | V4 | V1 | ✅ Has fromEmailAddress | Verify parameter value |
| Cancel_Collection_Flow | V2 | V1 | ✅ Has fromEmailAddress | Verify parameter value |

**Note**: Version number differences (V42→V1) are expected - NewOrg is new org, starts at V1

---

## Migration Strategy

### Deployment Approach

**Selected Strategy**: **Complete Deployment from OldOrg**

**Rationale**:
1. NewOrg V1 components are outdated (Oct 2, 2025 vs Oct 16, 2025)
2. Multiple critical components completely missing
3. Partial deployment would leave functionality broken
4. Complete deployment ensures all components work together

**What Will Be Deployed**:
- **Replace**: Handler V1 → V2, Test V1 → V2
- **New**: Trigger, Custom Label, 2 Flows
- **Update**: 5 Email Templates
- **Verify**: 4 Existing Flows

---

### Deployment Order

Components must be deployed in this specific order to satisfy dependencies:

```
Phase 0: Pre-Deployment Checks
    ↓
Phase 1: Foundation (Custom Label)
    ↓
Phase 2: Code (Apex Classes - Handler + Test)
    ↓
Phase 3: Activation (Apex Trigger)
    ↓
Phase 4: Configuration (Email Templates)
    ↓
Phase 5: Flows (Missing Flows)
    ↓
Phase 6: Verification (Existing Flows)
    ↓
Phase 7: Testing (End-to-End)
    ↓
Phase 8: Activation & Monitoring
```

---

## Pre-Deployment Checklist

**Before starting deployment, verify**:

### 1. Org Access ✅
```bash
# Verify connection to NewOrg
sf org display --target-org NewOrg

# Expected: Status shows "Connected", username displayed
```

### 2. Org-Wide Email Address ✅
```bash
# Verify org-wide address exists
sf data query --query "SELECT Address, DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE Address = 'portal-exchanges@recyclinglives-services.com'" --target-org NewOrg

# Expected: 1 record with Address = portal-exchanges@recyclinglives-services.com
```

**If org-wide address doesn't exist**:
1. Go to Setup → Organization-Wide Addresses
2. Add email address: portal-exchanges@recyclinglives-services.com
3. Verify email address via confirmation link
4. Enable "Allow All Profiles" or grant access to portal profiles

### 3. Email-to-Case Enabled ✅
```bash
# Check if Email-to-Case is enabled
sf data query --query "SELECT IsCaseEnabled FROM OrganizationSettings" --target-org NewOrg

# Expected: IsCaseEnabled = true
```

### 4. Portal Users Exist ✅
```bash
# Verify portal users exist
sf data query --query "SELECT COUNT() FROM User WHERE UserType = 'CspLitePortal' AND IsActive = true" --target-org NewOrg

# Expected: Count > 0 (at least some portal users exist)
```

### 5. Code Repository Access ✅
```bash
# Verify code is available
ls -la /tmp/Salesforce_OldOrg_State/portal-exchange-email/code/

# Expected: classes/, triggers/, flows/, email-templates/, custom-labels/ folders exist
```

---

## Phase 0: Pre-Deployment Setup

### Step 0.1: Backup NewOrg Current State

**Purpose**: Create rollback point before deployment

```bash
# Create backup directory
mkdir -p /tmp/Salesforce_NewOrg_Backup/portal-exchange-email/$(date +%Y-%m-%d)

# Retrieve existing components (V1 versions)
sf project retrieve start \
  --metadata "ApexClass:NewCaseEmailPopACCandContactHandler" \
  --metadata "ApexClass:NewCaseEmailPopACCandContactHandlerTest" \
  --metadata "Flow:Exchange_Job" \
  --metadata "Flow:Create_Job" \
  --metadata "Flow:Create_Mixed_Waste_Type_Job" \
  --metadata "Flow:Cancel_Collection_Flow" \
  --target-org NewOrg \
  --output-dir /tmp/Salesforce_NewOrg_Backup/portal-exchange-email/$(date +%Y-%m-%d)

# Backup email templates
sf project retrieve start \
  --metadata "EmailTemplate:New_Exchange_Request_Email_1_1" \
  --metadata "EmailTemplate:New_Job_Booking_Request_Email_1_1" \
  --metadata "EmailTemplate:Organise_Collection_Customer_Email_1_0" \
  --metadata "EmailTemplate:Cancel_Collection_Customer_Email_1_1" \
  --metadata "EmailTemplate:Cancel_Delivery_Customer_Email_1_1" \
  --target-org NewOrg \
  --output-dir /tmp/Salesforce_NewOrg_Backup/portal-exchange-email/$(date +%Y-%m-%d)
```

**Expected Output**: "Retrieved Source" message for each component

---

### Step 0.2: Deactivate Existing Trigger (if exists)

**Purpose**: Prevent conflicts during deployment

```bash
# Check if any triggers on Case Before Update exist
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE TableEnumOrId = 'Case' AND UsageBeforeUpdate = true AND Status = 'Active'" --target-org NewOrg --use-tooling-api

# If NewCaseEmailTrigger exists and is Active, deactivate it:
# (Likely not needed - trigger doesn't exist based on gap analysis)
```

**Expected Output**: 0 records (trigger doesn't exist yet)

---

### Step 0.3: Verify Flow Active Versions

**Purpose**: Ensure we know which flow versions will be replaced

```bash
# Check active versions of existing flows
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status, LastModifiedDate FROM Flow WHERE Definition.DeveloperName IN ('Exchange_Job', 'Create_Job', 'Create_Mixed_Waste_Type_Job', 'Cancel_Collection_Flow') AND Status = 'Active' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api
```

**Expected Output**:
- Exchange_Job: V1 Active
- Create_Job: V1 Active
- Create_Mixed_Waste_Type_Job: V1 Active
- Cancel_Collection_Flow: V1 Active

**Note**: These flows should have fromEmailAddress parameter. We will verify in Phase 6.

---

## Phase 1: Foundation - Custom Label

**Purpose**: Create custom label BEFORE deploying flows (dependency requirement)

### Step 1.1: Prepare Custom Label Metadata

```bash
# Navigate to code directory
cd /tmp/Salesforce_OldOrg_State/portal-exchange-email/code

# Verify custom label file exists
ls -la custom-labels/From_Address_Portal_Exchanges.label-meta.xml
```

**Expected Output**: File exists with .label-meta.xml extension

---

### Step 1.2: Deploy Custom Label

```bash
# Deploy custom label to NewOrg
sf project deploy start \
  --source-dir "custom-labels" \
  --target-org NewOrg \
  --wait 10 \
  --verbose

# Note: Custom labels do not require test execution
```

**Expected Output**:
```
Deploying...
Status: Succeeded
Component Deployed: CustomLabel:From_Address_Portal_Exchanges
Deploy ID: [17-character ID]
```

**If Deployment Fails**:
- Check if custom-labels folder exists in code directory
- Verify .label-meta.xml file is well-formed XML
- Check for duplicate label name in NewOrg

---

### Step 1.3: Verify Custom Label Deployment

```bash
# Query custom label in NewOrg
sf data query --query "SELECT Name, Value, NamespacePrefix FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'" --target-org NewOrg --use-tooling-api

# Expected output:
# Name: From_Address_Portal_Exchanges
# Value: portal-exchanges@recyclinglives-services.com
# NamespacePrefix: null (or empty)
```

**Success Criteria**: ✅ Label exists with correct value

---

## Phase 2: Code - Apex Classes

**Purpose**: Deploy handler V2 and test V2 to replace outdated V1 versions

### Step 2.1: Prepare Apex Code

```bash
# Verify Apex classes exist
ls -la /tmp/Salesforce_OldOrg_State/portal-exchange-email/code/classes/

# Expected files:
# - NewCaseEmailPopACCandContactHandler.cls
# - NewCaseEmailPopACCandContactHandler.cls-meta.xml
# - NewCaseEmailPopACCandContactHandlerTest.cls
# - NewCaseEmailPopACCandContactHandlerTest.cls-meta.xml
```

---

### Step 2.2: Deploy Apex Handler + Test

```bash
# Deploy both classes together (handler + test)
sf project deploy start \
  --source-dir "classes" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "NewCaseEmailPopACCandContactHandlerTest" \
  --wait 10 \
  --verbose

# Note: Test class must pass during deployment
# Expected test result: 4 test methods passing, 91% coverage
```

**Expected Output**:
```
Running Specified Tests...
Test Results:
  NewCaseEmailPopACCandContactHandlerTest.testEmailExtraction - Pass
  NewCaseEmailPopACCandContactHandlerTest.testContactMatching - Pass
  NewCaseEmailPopACCandContactHandlerTest.testAccountPopulation - Pass
  NewCaseEmailPopACCandContactHandlerTest.testErrorHandling - Pass

Code Coverage:
  NewCaseEmailPopACCandContactHandler: 91%

Status: Succeeded
Deploy ID: [17-character ID]
```

**If Tests Fail**:
1. Check test failure message
2. Verify Contact records exist in NewOrg for test data
3. Check if Email-to-Case is enabled
4. Review debug logs for errors

---

### Step 2.3: Verify Apex Deployment

```bash
# Verify handler class deployed
sf data query --query "SELECT Name, LastModifiedDate, LastModifiedBy.Name, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandler'" --target-org NewOrg --use-tooling-api

# Expected: LengthWithoutComments = 2827 (V2 size)

# Verify test class deployed
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandlerTest'" --target-org NewOrg --use-tooling-api

# Expected: LengthWithoutComments = 5608 (V2 size)

# Verify test coverage
sf apex run test --tests "NewCaseEmailPopACCandContactHandlerTest" --target-org NewOrg --result-format human --code-coverage --wait 10

# Expected: 91% coverage, all 4 tests passing
```

**Success Criteria**:
- ✅ Handler class: 2,827 lines (up from 1,522)
- ✅ Test class: 5,608 lines (up from 1,660)
- ✅ Test coverage: 91%
- ✅ All 4 tests passing

---

## Phase 3: Activation - Apex Trigger

**Purpose**: Deploy trigger to enable handler execution on Case updates

### Step 3.1: Prepare Trigger Code

```bash
# Verify trigger exists
ls -la /tmp/Salesforce_OldOrg_State/portal-exchange-email/code/triggers/

# Expected files:
# - NewCaseEmailTrigger.trigger
# - NewCaseEmailTrigger.trigger-meta.xml
```

---

### Step 3.2: Deploy Apex Trigger

```bash
# Deploy trigger (will call handler class)
sf project deploy start \
  --source-dir "triggers" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "NewCaseEmailPopACCandContactHandlerTest" \
  --wait 10 \
  --verbose

# Note: Trigger deployment requires test execution
```

**Expected Output**:
```
Running Tests...
Test Results: 4/4 passing

Status: Succeeded
Component Deployed: ApexTrigger:NewCaseEmailTrigger
Deploy ID: [17-character ID]
```

**If Deployment Fails**:
- Check if handler class exists (deployed in Phase 2)
- Verify trigger syntax is correct
- Check for duplicate trigger on Case Before Update

---

### Step 3.3: Verify Trigger Deployment

```bash
# Verify trigger is active
sf data query --query "SELECT Name, Status, UsageBeforeUpdate, TableEnumOrId FROM ApexTrigger WHERE Name = 'NewCaseEmailTrigger'" --target-org NewOrg --use-tooling-api

# Expected output:
# Name: NewCaseEmailTrigger
# Status: Active
# UsageBeforeUpdate: true
# TableEnumOrId: Case
```

**Success Criteria**: ✅ Trigger Active, Before Update event, on Case object

---

## Phase 4: Configuration - Email Templates

**Purpose**: Update 5 email templates to include ({!User.Email}) pattern for regex extraction

### Step 4.1: Identify Email Templates to Update

**Templates Requiring Update**:
1. New_Exchange_Request_Email_1_1
2. New_Job_Booking_Request_Email_1_1
3. Organise_Collection_Customer_Email_1_0
4. Cancel_Collection_Customer_Email_1_1
5. Cancel_Delivery_Customer_Email_1_1

**Required Change**:
```
OLD: sent by {!User.Name}
NEW: sent by {!User.Name} ({!User.Email})
```

---

### Step 4.2: Deploy Updated Email Templates

**Option 1: Deploy from OldOrg Code (Recommended)**

```bash
# Verify email template files exist
ls -la /tmp/Salesforce_OldOrg_State/portal-exchange-email/code/email-templates/

# Deploy all 5 email templates
sf project deploy start \
  --source-dir "email-templates" \
  --target-org NewOrg \
  --wait 10 \
  --verbose

# Note: Email templates do not require test execution
```

**Expected Output**:
```
Status: Succeeded
Components Deployed:
  EmailTemplate:New_Exchange_Request_Email_1_1
  EmailTemplate:New_Job_Booking_Request_Email_1_1
  EmailTemplate:Organise_Collection_Customer_Email_1_0
  EmailTemplate:Cancel_Collection_Customer_Email_1_1
  EmailTemplate:Cancel_Delivery_Customer_Email_1_1
Deploy ID: [17-character ID]
```

**Option 2: Manual Update via Setup (Alternative)**

If deployment fails, update templates manually:
1. Go to Setup → Classic Email Templates
2. Search for template name
3. Click Edit
4. Find "sent by {!User.Name}"
5. Change to "sent by {!User.Name} ({!User.Email})"
6. Click Save
7. Repeat for all 5 templates

---

### Step 4.3: Verify Email Template Updates

```bash
# Query email template body to confirm pattern
sf data query --query "SELECT DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'New_Exchange_Request_Email_1_1'" --target-org NewOrg | grep "User.Email"

# Expected: Body contains "({!User.Email})" pattern

# Repeat for other 4 templates
sf data query --query "SELECT DeveloperName, Body FROM EmailTemplate WHERE DeveloperName IN ('New_Job_Booking_Request_Email_1_1', 'Organise_Collection_Customer_Email_1_0', 'Cancel_Collection_Customer_Email_1_1', 'Cancel_Delivery_Customer_Email_1_1')" --target-org NewOrg | grep "User.Email"

# Expected: All templates show "({!User.Email})" in body
```

**Success Criteria**: ✅ All 5 templates contain "({!User.Email})" pattern

---

## Phase 5: Flows - Missing Flows

**Purpose**: Deploy 2 missing flows (Cancel_Flow, Job_Organise_Collection) with fromEmailAddress parameter

### Step 5.1: Prepare Flow Metadata

```bash
# Verify flow files exist
ls -la /tmp/Salesforce_OldOrg_State/portal-exchange-email/code/flows/

# Expected files:
# - Cancel_Flow.flow-meta.xml
# - Job_Organise_Collection.flow-meta.xml
```

---

### Step 5.2: Deploy Missing Flows (INACTIVE)

```bash
# Deploy flows as INACTIVE first (safer approach)
sf project deploy start \
  --source-dir "flows" \
  --target-org NewOrg \
  --wait 10 \
  --verbose

# Note: Flows may deploy as Draft status initially
```

**Expected Output**:
```
Status: Succeeded
Components Deployed:
  Flow:Cancel_Flow
  Flow:Job_Organise_Collection
Deploy ID: [17-character ID]
```

**Important**: Flows deployed via API are often in Draft status. We'll activate in Phase 8.

---

### Step 5.3: Verify Flow Deployment

```bash
# Check if flows were deployed (any status)
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName IN ('Cancel_Flow', 'Job_Organise_Collection') ORDER BY Definition.DeveloperName, VersionNumber DESC" --target-org NewOrg --use-tooling-api

# Expected output (may be Draft or Inactive):
# Cancel_Flow: V1 Draft (or Inactive)
# Job_Organise_Collection: V1 Draft (or Inactive)
```

**Success Criteria**: ✅ Flows exist in NewOrg (Draft/Inactive status acceptable for now)

---

### Step 5.4: Verify fromEmailAddress Parameter

```bash
# Retrieve deployed flow to check fromEmailAddress
sf project retrieve start \
  --metadata "Flow:Cancel_Flow" \
  --target-org NewOrg \
  --output-dir /tmp/flow_verification

# Check if fromEmailAddress exists in flow
grep "fromEmailAddress" /tmp/flow_verification/flows/Cancel_Flow.flow-meta.xml

# Expected output:
# <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>

# Repeat for Job_Organise_Collection
sf project retrieve start \
  --metadata "Flow:Job_Organise_Collection" \
  --target-org NewOrg \
  --output-dir /tmp/flow_verification

grep "fromEmailAddress" /tmp/flow_verification/flows/Job_Organise_Collection.flow-meta.xml

# Expected output:
# <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>
```

**Success Criteria**: ✅ Both flows reference custom label in fromEmailAddress parameter

---

## Phase 6: Verification - Existing Flows

**Purpose**: Verify 4 existing flows (Exchange_Job, Create_Job, Create_Mixed_Waste_Type_Job, Cancel_Collection_Flow) have correct fromEmailAddress parameter

### Step 6.1: Retrieve Existing Flows

```bash
# Retrieve all 4 flows
sf project retrieve start \
  --metadata "Flow:Exchange_Job" \
  --metadata "Flow:Create_Job" \
  --metadata "Flow:Create_Mixed_Waste_Type_Job" \
  --metadata "Flow:Cancel_Collection_Flow" \
  --target-org NewOrg \
  --output-dir /tmp/flow_verification_existing
```

---

### Step 6.2: Verify fromEmailAddress Parameter

```bash
# Check each flow for fromEmailAddress
cd /tmp/flow_verification_existing/flows

# Check Exchange_Job
grep "fromEmailAddress" Exchange_Job.flow-meta.xml

# Expected: <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>

# Check Create_Job
grep "fromEmailAddress" Create_Job.flow-meta.xml

# Expected: <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>

# Check Create_Mixed_Waste_Type_Job
grep "fromEmailAddress" Create_Mixed_Waste_Type_Job.flow-meta.xml

# Expected: <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>

# Check Cancel_Collection_Flow
grep "fromEmailAddress" Cancel_Collection_Flow.flow-meta.xml

# Expected: <fromEmailAddress>{!$Label.From_Address_Portal_Exchanges}</fromEmailAddress>
```

**Success Criteria**: ✅ All 4 flows reference From_Address_Portal_Exchanges custom label

**If Any Flow is Missing fromEmailAddress**:
1. Deploy corrected flow from OldOrg
2. Re-verify fromEmailAddress parameter
3. Activate corrected version

---

## Phase 7: Testing - End-to-End Verification

**Purpose**: Test complete flow from portal email → Case creation → Contact/Account population

### Test Case 1: Email Extraction Regex

**Objective**: Verify handler extracts email using regex pattern

**Setup**:
```bash
# Create test Case with email pattern in Description
sf data create record --sobject Case \
  --values "Subject='Test Portal Email' Description='This request was sent by John Doe (john.doe@example.com). Please process.' Origin='Email'" \
  --target-org NewOrg
```

**Verification**:
```bash
# Query Case to check if trigger executed
sf data query --query "SELECT Id, Subject, Description, ContactId, AccountId FROM Case WHERE Subject = 'Test Portal Email' ORDER BY CreatedDate DESC LIMIT 1" --target-org NewOrg

# Expected: Case exists with Description containing email pattern
```

**Expected Behavior**: Handler should extract "john.doe@example.com" and attempt Contact lookup

---

### Test Case 2: Contact Matching

**Objective**: Verify handler matches extracted email to existing Contact

**Setup**:
```bash
# Create test Contact with known email
sf data create record --sobject Contact \
  --values "FirstName='John' LastName='Doe' Email='john.doe@example.com'" \
  --target-org NewOrg

# Get Contact ID
sf data query --query "SELECT Id FROM Contact WHERE Email = 'john.doe@example.com'" --target-org NewOrg

# Create Case with matching email pattern
sf data create record --sobject Case \
  --values "Subject='Test Contact Match' Description='Request sent by John Doe (john.doe@example.com)' Origin='Email'" \
  --target-org NewOrg
```

**Verification**:
```bash
# Query Case to check if ContactId populated
sf data query --query "SELECT Id, Subject, ContactId, Contact.Email FROM Case WHERE Subject = 'Test Contact Match'" --target-org NewOrg

# Expected: ContactId populated with john.doe@example.com Contact
```

**Success Criteria**: ✅ Case.ContactId matches Contact with john.doe@example.com

---

### Test Case 3: Account Population

**Objective**: Verify handler populates AccountId from Contact.AccountId

**Setup**:
```bash
# Create test Account
sf data create record --sobject Account \
  --values "Name='Test Company'" \
  --target-org NewOrg

# Get Account ID
ACCOUNT_ID=$(sf data query --query "SELECT Id FROM Account WHERE Name = 'Test Company'" --target-org NewOrg --json | jq -r '.result.records[0].Id')

# Create Contact linked to Account
sf data create record --sobject Contact \
  --values "FirstName='Jane' LastName='Smith' Email='jane.smith@testcompany.com' AccountId='$ACCOUNT_ID'" \
  --target-org NewOrg

# Create Case with Contact's email
sf data create record --sobject Case \
  --values "Subject='Test Account Population' Description='Request sent by Jane Smith (jane.smith@testcompany.com)' Origin='Email'" \
  --target-org NewOrg
```

**Verification**:
```bash
# Query Case to check both ContactId and AccountId
sf data query --query "SELECT Id, Subject, ContactId, Contact.Email, AccountId, Account.Name FROM Case WHERE Subject = 'Test Account Population'" --target-org NewOrg

# Expected:
# - ContactId: Jane Smith's Contact ID
# - AccountId: Test Company's Account ID
```

**Success Criteria**: ✅ Case.AccountId matches Contact.AccountId

---

### Test Case 4: SPF/DMARC Email Validation

**Objective**: Verify flows send emails with org-wide address (SPF pass)

**Setup**:
```bash
# Manually trigger one of the flows in NewOrg (e.g., Exchange_Job)
# OR wait for real portal user to create Job

# Check email logs
sf data query --query "SELECT Id, Subject, Status, ValidatedFromAddress, CreatedDate FROM EmailMessage WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg
```

**Verification**:
- Check email headers for "spf=pass" and "dmarc=pass"
- Verify FROM address is portal-exchanges@recyclinglives-services.com
- Confirm email delivered (not bounced/spam)

**Success Criteria**: ✅ SPF and DMARC validation pass

---

### Test Case 5: Missing Contact Scenario

**Objective**: Verify handler doesn't error when email doesn't match any Contact

**Setup**:
```bash
# Create Case with email that doesn't exist in system
sf data create record --sobject Case \
  --values "Subject='Test No Match' Description='Request sent by Unknown User (unknown@nowhere.com)' Origin='Email'" \
  --target-org NewOrg
```

**Verification**:
```bash
# Query Case to confirm it was created without Contact/Account
sf data query --query "SELECT Id, Subject, ContactId, AccountId FROM Case WHERE Subject = 'Test No Match'" --target-org NewOrg

# Expected:
# - Case exists
# - ContactId: null
# - AccountId: null
```

**Success Criteria**: ✅ Case created successfully, ContactId and AccountId null

---

## Phase 8: Activation & Monitoring

**Purpose**: Activate deployed flows and monitor system for issues

### Step 8.1: Activate Missing Flows

**Context**: Flows deployed in Phase 5 are likely in Draft/Inactive status

**Activation Options**:

**Option 1: Activate via Salesforce Setup (Recommended)**
1. Go to Setup → Flows
2. Find "Cancel_Flow"
3. Click "Activate" button
4. Confirm activation
5. Repeat for "Job_Organise_Collection"

**Option 2: Activate via Tooling API (Advanced)**
```bash
# Get Flow Definition IDs
sf data query --query "SELECT Definition.DeveloperName, Id, VersionNumber FROM Flow WHERE Definition.DeveloperName IN ('Cancel_Flow', 'Job_Organise_Collection') ORDER BY Definition.DeveloperName, VersionNumber DESC" --target-org NewOrg --use-tooling-api

# Use returned Flow IDs to activate (requires custom script or manual Setup activation)
```

**Note**: Flow activation via CLI is complex. Setup UI is recommended.

---

### Step 8.2: Verify Active Flow Versions

```bash
# Confirm all 6 flows are now active
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName IN ('Exchange_Job', 'Create_Job', 'Create_Mixed_Waste_Type_Job', 'Cancel_Collection_Flow', 'Cancel_Flow', 'Job_Organise_Collection') AND Status = 'Active' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api

# Expected: 6 flows, all Active status
```

**Success Criteria**: ✅ All 6 flows Active

---

### Step 8.3: Enable Debug Logs

**Purpose**: Monitor handler execution during initial period

```bash
# Enable debug logs for Case trigger execution
# (Requires manual Setup configuration)

# Steps:
# 1. Setup → Debug Logs
# 2. Click "New" Trace Flag
# 3. Traced Entity Type: User (select integration user or all users)
# 4. Start Date: Today
# 5. Expiration Date: Tomorrow
# 6. Debug Level: FINEST for Apex Code
```

---

### Step 8.4: Monitor Cases Created from Portal Emails

**First 24 Hours - Monitor every 2-3 hours**:

```bash
# Query Cases created today from Email origin
sf data query --query "SELECT Id, CaseNumber, Subject, Origin, ContactId, Contact.Email, AccountId, CreatedDate FROM Case WHERE Origin = 'Email' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 20" --target-org NewOrg

# Check for:
# - ContactId populated (if email matches Contact)
# - AccountId populated (if Contact has Account)
# - Email pattern in Description field
```

**Check Debug Logs**:
```bash
# View recent debug logs
sf data query --query "SELECT Id, Operation, Status, DurationMilliseconds, StartTime FROM ApexLog WHERE Operation = 'Trigger' ORDER BY StartTime DESC LIMIT 10" --target-org NewOrg --use-tooling-api

# Download and review logs for errors
# (Requires log file download via Setup UI or Tooling API)
```

**Monitor Email Deliverability**:
```bash
# Check for bounced emails
sf data query --query "SELECT Id, Subject, Status, BounceReason FROM EmailMessage WHERE CreatedDate = TODAY AND Status = 'Bounced'" --target-org NewOrg

# Expected: 0 bounced emails (SPF/DMARC should pass)
```

---

### Step 8.5: User Notification

**Notify stakeholders deployment is complete**:

**Email Template**:
```
Subject: Portal Exchange Email SPF Fix Deployed to NewOrg

Team,

The Portal Exchange Email SPF/DMARC fix has been successfully deployed to NewOrg.

Changes Deployed:
- Handler V2 with email extraction logic
- Trigger for automatic Contact/Account population
- Custom label for org-wide email address
- 5 updated email templates
- 2 new flows (Cancel_Flow, Job_Organise_Collection)

Expected Benefits:
- All portal emails pass SPF/DMARC validation
- Cases automatically linked to Contact/Account
- No more bounced/spam emails from portal users

Monitoring Period:
- First 24 hours: Monitored every 2-3 hours
- First week: Daily checks
- Report any issues immediately

Contact: [Your Contact Info]
```

---

## Post-Deployment Verification Summary

**Run all checks 24 hours after deployment**:

### Verification Checklist

```bash
# 1. Verify custom label exists
sf data query --query "SELECT Name, Value FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'" --target-org NewOrg --use-tooling-api
# ✅ Expected: 1 record

# 2. Verify handler V2 deployed
sf data query --query "SELECT Name, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandler'" --target-org NewOrg --use-tooling-api
# ✅ Expected: 2,827 lines

# 3. Verify trigger active
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name = 'NewCaseEmailTrigger'" --target-org NewOrg --use-tooling-api
# ✅ Expected: Active

# 4. Verify email templates updated
sf data query --query "SELECT DeveloperName FROM EmailTemplate WHERE Body LIKE '%User.Email%'" --target-org NewOrg | wc -l
# ✅ Expected: At least 5 templates

# 5. Verify all 6 flows active
sf data query --query "SELECT COUNT() FROM Flow WHERE Definition.DeveloperName IN ('Exchange_Job', 'Create_Job', 'Create_Mixed_Waste_Type_Job', 'Cancel_Collection_Flow', 'Cancel_Flow', 'Job_Organise_Collection') AND Status = 'Active'" --target-org NewOrg --use-tooling-api
# ✅ Expected: 6

# 6. Verify test coverage maintained
sf apex run test --tests "NewCaseEmailPopACCandContactHandlerTest" --target-org NewOrg --code-coverage --result-format human --wait 10
# ✅ Expected: 91% coverage, 4 tests passing

# 7. Check for errors in debug logs
sf data query --query "SELECT COUNT() FROM ApexLog WHERE Operation = 'Trigger' AND Status != 'Success' AND StartTime = TODAY" --target-org NewOrg --use-tooling-api
# ✅ Expected: 0 errors

# 8. Verify Cases linked to Contacts
sf data query --query "SELECT COUNT() FROM Case WHERE Origin = 'Email' AND ContactId != null AND CreatedDate = TODAY" --target-org NewOrg
# ✅ Expected: > 0 (if portal users created cases)

# 9. Check email deliverability
sf data query --query "SELECT COUNT() FROM EmailMessage WHERE CreatedDate = TODAY AND Status = 'Bounced'" --target-org NewOrg
# ✅ Expected: 0 bounced

# 10. Verify org-wide address used
sf data query --query "SELECT ValidatedFromAddress, COUNT(Id) FROM EmailMessage WHERE CreatedDate = TODAY GROUP BY ValidatedFromAddress" --target-org NewOrg
# ✅ Expected: portal-exchanges@recyclinglives-services.com appears
```

**All checks passing** = ✅ Deployment successful

---

## Rollback Plan

### Rollback Scenarios

**When to Rollback**:
- Handler errors prevent Case creation
- Email extraction failing consistently
- SPF/DMARC validation still failing
- Test coverage drops below 75%
- Critical production issues

---

### Immediate Rollback (2 minutes) - Deactivate Trigger Only

**Use when**: Minor issues, need to stop automation quickly

```bash
# Option 1: Via Tooling API (if supported)
# Get trigger ID
TRIGGER_ID=$(sf data query --query "SELECT Id FROM ApexTrigger WHERE Name = 'NewCaseEmailTrigger'" --target-org NewOrg --use-tooling-api --json | jq -r '.result.records[0].Id')

# Deactivate trigger (requires custom API call - Setup UI recommended)

# Option 2: Via Salesforce Setup (Recommended)
# 1. Setup → Apex Triggers
# 2. Find "NewCaseEmailTrigger"
# 3. Click "Edit"
# 4. Add // comment to disable: // trigger NewCaseEmailTrigger on Case (before update) { ... }
# 5. Save
```

**Impact**: Handler stops executing, Cases created without Contact/Account linkage (same as before deployment)

---

### Partial Rollback (10 minutes) - Deactivate Flows

**Use when**: Email deliverability issues, need to stop email sending

```bash
# Deactivate newly deployed flows
# Via Salesforce Setup (CLI activation not straightforward):
# 1. Setup → Flows
# 2. Find "Cancel_Flow" → Click → Deactivate
# 3. Find "Job_Organise_Collection" → Click → Deactivate
```

**Impact**: Cancellation and collection emails won't be sent automatically

---

### Full Rollback (60 minutes) - Restore Backup

**Use when**: Fundamental issues, need complete removal

```bash
# 1. Deactivate trigger (Immediate Rollback above)

# 2. Deploy V1 components from backup
cd /tmp/Salesforce_NewOrg_Backup/portal-exchange-email/$(date +%Y-%m-%d)

# 3. Deploy old handler + test (V1 versions)
sf project deploy start \
  --source-dir "force-app/main/default/classes" \
  --target-org NewOrg \
  --test-level RunLocalTests \
  --wait 10

# 4. Restore email templates
sf project deploy start \
  --source-dir "force-app/main/default/email" \
  --target-org NewOrg \
  --wait 10

# 5. Delete custom label (if needed)
# Via Setup → Custom Labels → Delete "From_Address_Portal_Exchanges"

# 6. Delete trigger (if needed)
sf project delete source \
  --metadata "ApexTrigger:NewCaseEmailTrigger" \
  --target-org NewOrg \
  --no-prompt

# 7. Deactivate newly deployed flows
# Via Setup → Flows → Deactivate Cancel_Flow and Job_Organise_Collection

# 8. Verify rollback complete
sf data query --query "SELECT Name, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandler'" --target-org NewOrg --use-tooling-api
# Expected: 1,522 lines (V1)
```

**Impact**: System returns to pre-deployment state (V1 with limited functionality)

---

## Known Issues & Limitations

### Known Limitations

1. **Email Pattern Dependency**: Handler only works if email templates use exact pattern "sent by {!User.Name} ({!User.Email})"
   - **Impact**: Any template variation breaks extraction
   - **Mitigation**: Standardize all templates with pattern

2. **Single Contact Match**: If multiple Contacts have same email, only first match used
   - **Impact**: May link to wrong Contact if duplicates exist
   - **Mitigation**: Ensure Contact email uniqueness

3. **Manual Case Creation**: Handler only runs on Cases created from Email-to-Case
   - **Impact**: Manually created Cases won't have handler logic
   - **Mitigation**: Document this limitation for CS team

4. **Case Update Timing**: Trigger runs on before update, may conflict with other automation
   - **Impact**: Rare race conditions possible
   - **Mitigation**: Monitor debug logs for conflicts

5. **Regex Complexity**: Email extraction relies on regex pattern matching
   - **Impact**: Malformed emails may not extract correctly
   - **Mitigation**: Test various email formats

---

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Handler errors during Case creation | Low | High | Test thoroughly, monitor debug logs |
| Email extraction regex fails on edge cases | Medium | Medium | Comprehensive test cases, error handling |
| SPF/DMARC still fails (org-wide address misconfigured) | Low | High | Verify org-wide address before deployment |
| Test coverage drops below 75% | Low | High | Run tests during deployment, verify 91% maintained |
| Flow deployment as Draft (not Active) | High | Medium | Manual activation in Setup required (Phase 8) |
| Custom label not created before flows | Medium | High | Deploy custom label in Phase 1 (before flows) |
| Email templates not updated | Medium | High | Verify templates in Phase 4 |
| Multiple triggers on Case Before Update conflict | Low | Medium | Verify no other triggers on Case Before Update |

---

## Success Criteria

**Deployment considered successful when**:

### Technical Criteria
- ✅ Custom label exists with correct value
- ✅ Handler V2 deployed (2,827 lines)
- ✅ Test V2 deployed (5,608 lines, 91% coverage)
- ✅ Trigger active (Before Update on Case)
- ✅ All 5 email templates updated with ({!User.Email}) pattern
- ✅ 2 new flows deployed and active (Cancel_Flow, Job_Organise_Collection)
- ✅ 4 existing flows verified with fromEmailAddress
- ✅ All tests passing (4 test methods)

### Functional Criteria
- ✅ Cases created from portal emails have ContactId populated (when email matches Contact)
- ✅ Cases have AccountId populated (when Contact has Account)
- ✅ Emails sent with org-wide address (SPF/DMARC pass)
- ✅ No bounced emails from portal scenarios
- ✅ No errors in debug logs

### Business Criteria
- ✅ CS team can see portal Cases linked to Contacts
- ✅ Reporting by Account/Contact includes portal Cases
- ✅ Portal users see their Cases in portal
- ✅ Email deliverability improved (no spam/bounces)

---

## Migration Timeline

**Estimated Total Time**: 2-3 hours

| Phase | Task | Estimated Time | Dependencies |
|-------|------|---------------|--------------|
| 0 | Pre-Deployment Setup | 30 min | Org access |
| 1 | Deploy Custom Label | 15 min | None |
| 2 | Deploy Apex Classes | 30 min | None |
| 3 | Deploy Apex Trigger | 15 min | Phase 2 complete |
| 4 | Update Email Templates | 45 min | None |
| 5 | Deploy Missing Flows | 45 min | Phase 1 complete |
| 6 | Verify Existing Flows | 30 min | Phase 1 complete |
| 7 | End-to-End Testing | 45 min | Phases 1-6 complete |
| 8 | Activation & Monitoring | 30 min | Phase 7 complete |

**Total**: 3 hours 45 minutes (rounded to 2-3 hours accounting for overlaps)

---

## Deployment Checklist

**Before Deployment**:
- [ ] Read OldOrg State README
- [ ] Read this Migration Plan completely
- [ ] Verify NewOrg access
- [ ] Verify org-wide email address exists and is verified
- [ ] Backup current NewOrg state
- [ ] Notify stakeholders of deployment window

**During Deployment**:
- [ ] Phase 0: Pre-Deployment Setup complete
- [ ] Phase 1: Custom Label deployed and verified
- [ ] Phase 2: Apex Classes deployed, tests passing
- [ ] Phase 3: Trigger deployed and active
- [ ] Phase 4: Email Templates updated and verified
- [ ] Phase 5: Missing Flows deployed
- [ ] Phase 6: Existing Flows verified
- [ ] Phase 7: All test cases passing
- [ ] Phase 8: Flows activated, monitoring enabled

**After Deployment**:
- [ ] All verification checks passing
- [ ] Debug logs show no errors
- [ ] Cases linked to Contacts correctly
- [ ] Emails passing SPF/DMARC
- [ ] User notification sent
- [ ] 24-hour monitoring scheduled
- [ ] Update scenario status to "Deployed"
- [ ] Document Deploy ID in this README

---

## Post-Deployment Monitoring

### First 24 Hours (Check every 2-3 hours)

```bash
# Monitor script - run every 2-3 hours
#!/bin/bash

echo "=== Portal Exchange Email Monitoring ==="
echo "Date: $(date)"
echo ""

echo "1. Cases created from email today:"
sf data query --query "SELECT COUNT() FROM Case WHERE Origin = 'Email' AND CreatedDate = TODAY" --target-org NewOrg
echo ""

echo "2. Cases with Contact linked:"
sf data query --query "SELECT COUNT() FROM Case WHERE Origin = 'Email' AND ContactId != null AND CreatedDate = TODAY" --target-org NewOrg
echo ""

echo "3. Bounced emails today:"
sf data query --query "SELECT COUNT() FROM EmailMessage WHERE Status = 'Bounced' AND CreatedDate = TODAY" --target-org NewOrg
echo ""

echo "4. Trigger errors today:"
sf data query --query "SELECT COUNT() FROM ApexLog WHERE Operation = 'Trigger' AND Status != 'Success' AND StartTime = TODAY" --target-org NewOrg --use-tooling-api
echo ""

echo "5. Recent Cases with extraction pattern:"
sf data query --query "SELECT Id, CaseNumber, Subject, ContactId, AccountId FROM Case WHERE Origin = 'Email' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 5" --target-org NewOrg
echo ""

echo "=== Monitoring Complete ==="
```

### First Week (Daily checks)

- Review debug logs for errors
- Check email deliverability stats
- Verify Contact/Account linkage rate
- Gather CS team feedback
- Monitor SPF/DMARC pass rates

### First Month (Weekly reviews)

- Analyze Case linkage patterns
- Review any unmatched emails
- Optimize regex pattern if needed
- Update documentation with lessons learned

---

## Related Scenarios

**Dependencies**:
- Email-to-Case configuration (prerequisite)
- Producer Portal (portal users exist)

**Related Implementations**:
- Email-to-Case Assignment (automatic Case assignment after creation)
- Portal User Management (portal user provisioning)

**Integration Points**:
- Case object (trigger target)
- Contact object (SOQL lookup)
- Account object (relationship)
- EmailMessage object (deliverability tracking)

---

## Documentation Updates

**After successful deployment, update**:

1. **This README**:
   - Migration Status: 📋 Ready for Review → 🚀 Deployed
   - Deployment Date: [Actual date]
   - Deploy ID: [Salesforce Deploy ID]

2. **MIGRATION_PROGRESS.md** (main project):
   - Mark Portal Exchange Email as "Deployed"
   - Update Batch 2 progress

3. **OldOrg State README** (reference):
   - Add note: "Deployed to NewOrg on [date]"

4. **Workflow Rules** (if applicable):
   - Document any lessons learned
   - Update deployment best practices

---

## Support Information

**Migration Owner**: John Shintu
**Deployment Team**: [Team Names]
**Business Stakeholders**: CS Team, Portal Administrators

**For Issues During Deployment**:
- Check rollback plan (this document)
- Review debug logs
- Contact: [Contact Info]

**For Post-Deployment Issues**:
- Monitor Cases not linking to Contacts
- Check email deliverability
- Review error logs

---

## Appendices

### Appendix A: Regex Pattern Explanation

**Pattern**: `\\(([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})\\)`

**Breakdown**:
- `\\(` - Opening parenthesis (escaped)
- `([a-zA-Z0-9._%+-]+` - Email local part (before @)
- `@` - At symbol
- `[a-zA-Z0-9.-]+` - Domain name
- `\\.` - Dot (escaped)
- `[a-zA-Z]{2,}` - TLD (2+ characters)
- `\\)` - Closing parenthesis (escaped)

**Example Matches**:
- `(john.doe@example.com)` ✅ Matches
- `(test_user+tag@sub.domain.co.uk)` ✅ Matches
- `john.doe@example.com` ❌ No match (missing parentheses)
- `(invalid-email)` ❌ No match (no @ symbol)

---

### Appendix B: Component Dependencies

```
From_Address_Portal_Exchanges (Custom Label)
    ↓
    Required by: All 6 Flows
    ↓
Exchange_Job, Create_Job, Create_Mixed_Waste_Type_Job,
Cancel_Collection_Flow, Cancel_Flow, Job_Organise_Collection
    ↓
    Send emails using: Org-Wide Email Address
    ↓
Email Templates (with ({!User.Email}) pattern)
    ↓
    Used by: All 6 Flows
    ↓
    Email sent to: CS Team
    ↓
Email-to-Case creates: Case
    ↓
NewCaseEmailTrigger (Before Update)
    ↓
NewCaseEmailPopACCandContactHandler.handleBeforeUpdate()
    ↓
    Extracts email using: Regex Pattern
    ↓
    Queries: Contact (by Email)
    ↓
    Populates: Case.ContactId, Case.AccountId
```

---

### Appendix C: Verification Queries Reference

```bash
# Custom Label
sf data query --query "SELECT Name, Value FROM CustomLabel WHERE Name = 'From_Address_Portal_Exchanges'" --target-org NewOrg --use-tooling-api

# Handler Class
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandler'" --target-org NewOrg --use-tooling-api

# Test Class
sf data query --query "SELECT Name, LastModifiedDate, LengthWithoutComments FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandlerTest'" --target-org NewOrg --use-tooling-api

# Trigger
sf data query --query "SELECT Name, Status, UsageBeforeUpdate FROM ApexTrigger WHERE Name = 'NewCaseEmailTrigger'" --target-org NewOrg --use-tooling-api

# Email Templates
sf data query --query "SELECT DeveloperName, LastModifiedDate FROM EmailTemplate WHERE DeveloperName IN ('New_Exchange_Request_Email_1_1', 'New_Job_Booking_Request_Email_1_1', 'Organise_Collection_Customer_Email_1_0', 'Cancel_Collection_Customer_Email_1_1', 'Cancel_Delivery_Customer_Email_1_1')" --target-org NewOrg

# Flows
sf data query --query "SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName IN ('Exchange_Job', 'Create_Job', 'Create_Mixed_Waste_Type_Job', 'Cancel_Collection_Flow', 'Cancel_Flow', 'Job_Organise_Collection') AND Status = 'Active' ORDER BY Definition.DeveloperName" --target-org NewOrg --use-tooling-api

# Org-Wide Email Address
sf data query --query "SELECT Address, DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE Address = 'portal-exchanges@recyclinglives-services.com'" --target-org NewOrg

# Recent Cases
sf data query --query "SELECT Id, CaseNumber, Subject, Origin, ContactId, Contact.Email, AccountId, CreatedDate FROM Case WHERE Origin = 'Email' AND CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg

# Email Deliverability
sf data query --query "SELECT Id, Subject, Status, ValidatedFromAddress, CreatedDate FROM EmailMessage WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --target-org NewOrg

# Trigger Errors
sf data query --query "SELECT Id, Operation, Status, StartTime FROM ApexLog WHERE Operation = 'Trigger' AND Status != 'Success' AND StartTime = TODAY ORDER BY StartTime DESC" --target-org NewOrg --use-tooling-api
```

---

## Quick Links

- [OldOrg State Documentation](/tmp/Salesforce_OldOrg_State/portal-exchange-email/README.md)
- [Gap Analysis](/tmp/Salesforce_OldOrg_State/portal-exchange-email/GAP_ANALYSIS.md)
- [Original Implementation Guide](/home/john/Projects/Salesforce/Documentation/PORTAL_EXCHANGE_EMAIL_FIX_COMPLETE_GUIDE.md)

---

**Migration Plan Status**: 📋 Ready for Review
**Last Updated**: October 22, 2025
**Next Steps**:
1. Review this migration plan
2. Verify all prerequisites
3. Execute deployment phases in order
4. Complete post-deployment verification
5. Monitor for 24-48 hours

**Ready for Deployment** ✅
