# Deployment Verification - Portal Exchange Email Fix

## Scenario Overview
**Scenario**: portal-exchange-email
**Purpose**: Fix email-to-case assignment for portal exchange emails by extracting actual sender email from body text
**Source Documentation**: PORTAL_EXCHANGE_EMAIL_FIX_COMPLETE_GUIDE.md

## Component Inventory

### Total Files: 25

### Apex Classes (6 files)
- ✅ NewCaseEmailPopACCandContactHandler.cls
- ✅ NewCaseEmailPopACCandContactHandler.cls-meta.xml
- ✅ NewCaseEmailPopACCandContactHandlerTest.cls
- ✅ NewCaseEmailPopACCandContactHandlerTest.cls-meta.xml
- ✅ NewCaseEmailPopACCandContactTest.cls
- ✅ NewCaseEmailPopACCandContactTest.cls-meta.xml

### Triggers (2 files)
- ✅ NewCaseEmailPopACCandContact.trigger
- ✅ NewCaseEmailPopACCandContact.trigger-meta.xml

### Flows (6 files)
- ✅ Cancel_Collection_Flow.flow-meta.xml
- ✅ Cancel_Flow.flow-meta.xml
- ✅ Create_Job.flow-meta.xml
- ✅ Create_Mixed_Waste_Type_Job.flow-meta.xml
- ✅ Exchange_Job.flow-meta.xml
- ✅ Job_Organise_Collection.flow-meta.xml

### Email Templates (10 files)
- ✅ Cancel_Collection_Customer_Email_1_1.email
- ✅ Cancel_Collection_Customer_Email_1_1.email-meta.xml
- ✅ Cancel_Delivery_Customer_Email_1_1.email
- ✅ Cancel_Delivery_Customer_Email_1_1.email-meta.xml
- ✅ New_Exchange_Request_Email_1_1.email
- ✅ New_Exchange_Request_Email_1_1.email-meta.xml
- ✅ New_Job_Booking_Request_Email_1_1.email
- ✅ New_Job_Booking_Request_Email_1_1.email-meta.xml
- ✅ Organise_Collection_Customer_Email_1_0.email
- ✅ Organise_Collection_Customer_Email_1_0.email-meta.xml

### Custom Labels (1 file)
- ✅ CustomLabels.labels-meta.xml

## File Structure
```
portal-exchange-email/code/
├── classes/
│   ├── NewCaseEmailPopACCandContactHandler.cls
│   ├── NewCaseEmailPopACCandContactHandler.cls-meta.xml
│   ├── NewCaseEmailPopACCandContactHandlerTest.cls
│   ├── NewCaseEmailPopACCandContactHandlerTest.cls-meta.xml
│   ├── NewCaseEmailPopACCandContactTest.cls
│   └── NewCaseEmailPopACCandContactTest.cls-meta.xml
├── triggers/
│   ├── NewCaseEmailPopACCandContact.trigger
│   └── NewCaseEmailPopACCandContact.trigger-meta.xml
├── flows/
│   ├── Cancel_Collection_Flow.flow-meta.xml
│   ├── Cancel_Flow.flow-meta.xml
│   ├── Create_Job.flow-meta.xml
│   ├── Create_Mixed_Waste_Type_Job.flow-meta.xml
│   ├── Exchange_Job.flow-meta.xml
│   └── Job_Organise_Collection.flow-meta.xml
├── email/
│   └── Customer_Portal_Notifications/
│       ├── Cancel_Collection_Customer_Email_1_1.email
│       ├── Cancel_Collection_Customer_Email_1_1.email-meta.xml
│       ├── Cancel_Delivery_Customer_Email_1_1.email
│       ├── Cancel_Delivery_Customer_Email_1_1.email-meta.xml
│       ├── New_Exchange_Request_Email_1_1.email
│       ├── New_Exchange_Request_Email_1_1.email-meta.xml
│       ├── New_Job_Booking_Request_Email_1_1.email
│       ├── New_Job_Booking_Request_Email_1_1.email-meta.xml
│       ├── Organise_Collection_Customer_Email_1_0.email
│       └── Organise_Collection_Customer_Email_1_0.email-meta.xml
└── labels/
    └── CustomLabels.labels-meta.xml
```

## Deployment Commands

### 1. Deploy All Components
```bash
cd /tmp/Salesforce_NewOrg

sf project deploy start \
  --source-dir portal-exchange-email/code \
  --test-level RunSpecifiedTests \
  --tests NewCaseEmailPopACCandContactHandlerTest \
  --tests NewCaseEmailPopACCandContactTest \
  --target-org NewOrg \
  --wait 15
```

### 2. Activate Flows (Manual Step)
After deployment, activate the following flows in NewOrg:
1. Exchange_Job
2. Create_Job
3. Create_Mixed_Waste_Type_Job
4. Cancel_Collection_Flow
5. Cancel_Flow
6. Job_Organise_Collection

## Post-Deployment Verification

### 1. Verify Trigger is Active
```bash
sf data query \
  --query "SELECT Id, Name, Status FROM ApexTrigger WHERE Name = 'NewCaseEmailPopACCandContact'" \
  --target-org NewOrg
```
Expected: Status = 'Active'

### 2. Verify Handler Class Deployed
```bash
sf data query \
  --query "SELECT Id, Name, Status FROM ApexClass WHERE Name = 'NewCaseEmailPopACCandContactHandler'" \
  --target-org NewOrg
```
Expected: Status = 'Active'

### 3. Verify Email Templates
```bash
sf data query \
  --query "SELECT DeveloperName, FolderName, Name FROM EmailTemplate WHERE DeveloperName IN ('New_Exchange_Request_Email_1_1', 'New_Job_Booking_Request_Email_1_1', 'Cancel_Collection_Customer_Email_1_1', 'Cancel_Delivery_Customer_Email_1_1', 'Organise_Collection_Customer_Email_1_0')" \
  --target-org NewOrg
```
Expected: All 5 templates present in "Customer Portal Notifications" folder

### 4. Verify Flows Deployed
```bash
sf data query \
  --query "SELECT DeveloperName, ProcessType, ActiveVersionId FROM FlowDefinition WHERE DeveloperName IN ('Exchange_Job', 'Create_Job', 'Create_Mixed_Waste_Type_Job', 'Cancel_Collection_Flow', 'Cancel_Flow', 'Job_Organise_Collection')" \
  --target-org NewOrg
```
Expected: All 6 flows present (check ActiveVersionId to confirm activation)

### 5. Verify Custom Labels
```bash
sf data query \
  --query "SELECT MasterLabel, Name, Value FROM ExternalString WHERE Name LIKE 'Portal%' OR Name LIKE 'Exchange%' OR Name LIKE 'Job%'" \
  --target-org NewOrg
```
Expected: All portal-related custom labels present

## Testing Instructions

### Test Case 1: Portal Exchange Email Processing
1. Send test email from portal-exchanges@recyclinglives-services.com
2. Email body should contain pattern: "sent by John Smith (john.smith@amey.co.uk)"
3. Verify Case created with:
   - ContactId set to john.smith@amey.co.uk contact
   - AccountId set to contact's account
   - Subject copied from email
   - Most_Recent_Message__c populated

### Test Case 2: Internal Email Processing
1. Send test email from agent@recyclinglives-services.com
2. ToAddress: "first@example.com;second@example.com"
3. Verify Case created with:
   - ContactId set to first@example.com contact (first address before semicolon)
   - AccountId set to contact's account
   - Subject copied from email

### Test Case 3: Email Count Transition
1. Create Case with Total_Emails_Against_Case__c = 0
2. Insert first EmailMessage (triggers 0→1 transition)
3. Verify handler runs and populates Contact/Account/Subject
4. Insert second EmailMessage (triggers 1→2 transition)
5. Verify handler does NOT run (Contact/Account/Subject remain unchanged)

## Key Implementation Details

### Handler Logic
- **Trigger Condition**: Only runs when Total_Emails_Against_Case__c changes from 0 to 1
- **Portal Exchange Logic**: Extracts email from body text using regex pattern `\(([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\)`
- **Internal Email Logic**: Splits ToAddress by semicolon, uses first email address
- **Error Handling**: Try-catch wraps all logic to prevent Case update failures

### Flow Dependencies
- Exchange_Job: Main flow for creating exchange jobs
- Create_Job: Subflow for job creation
- Create_Mixed_Waste_Type_Job: Handles mixed waste type jobs
- Cancel_Collection_Flow: Cancels collection requests
- Cancel_Flow: General cancellation flow
- Job_Organise_Collection: Organizes collection scheduling

## Deployment Status
- ⏳ **Status**: Ready for Deployment
- 📦 **Total Components**: 25 files
- ✅ **All Files Present**: Yes
- 🧪 **Test Classes**: 2 (NewCaseEmailPopACCandContactHandlerTest, NewCaseEmailPopACCandContactTest)

## Notes
- All flows must be manually activated after deployment
- Email templates deployed to "Customer Portal Notifications" folder
- Custom labels file contains all portal-related labels (shared across multiple features)
- Trigger is set to Active status in metadata
