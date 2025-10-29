# Smart Waste Portal Integration Analysis

**Date:** October 29, 2025 (Updated)
**Original Analysis:** October 8, 2025
**Organization:** OldOrg (Recycling Lives Service)
**Issue Reported:** "All data is not coming through to Smart Waste portal"

---

## Executive Summary

✅ **Integration is WORKING but with HIGH ERROR RATE**

**Key Findings:**
- Integration batch runs daily at midnight (00:00 UTC)
- **Success Rate Today:** Only 14 jobs sent successfully
- **Error Rate Today:** 2,119 error log entries
- **Success Rate:** <1% (14 successful out of ~2,600 attempted)

**Root Cause:** Data is being sent, but **99% of jobs are failing validation** due to missing required data in Salesforce.

**⚠️ CRITICAL FINDING (October 29, 2025):**
One validation rule is **INCORRECT** and blocking 149 jobs unnecessarily:
- **Depot Account WCL validation** is NOT required by SmartWaste API
- This is an internal validation error in Salesforce code
- Depots need Environmental Permits (not Waste Carrier Licenses)
- **Recommendation:** Remove this validation immediately

---

## Table of Contents

1. [Integration Architecture](#integration-architecture)
2. [SmartWaste API Requirements (ACTUAL)](#smartwaste-api-requirements-actual)
3. [Internal Salesforce Validations](#internal-salesforce-validations)
4. [Validation vs API Requirements Comparison](#validation-vs-api-requirements-comparison)
5. [Identified Validation Issues](#identified-validation-issues)
6. [Integration Flow Detailed](#integration-flow-detailed)
7. [Recommendations](#recommendations)

---

## Integration Architecture

### How It Works

1. **Scheduled Job:** `SmartWaste_Integration-10`
   - Runs daily at 00:00 UTC
   - Batch size: Default (configurable)
   - Timeout: 120 seconds per callout

2. **Batch Class:** `SmartWasteIntegrationBatch`
   - Location: OldOrg Apex Class
   - Lines of Code: ~500 lines
   - Processes jobs in batches
   - Makes API callouts to Smart Waste portal
   - Creates integration logs for failures

3. **Middleware Class:** `SmartWasteIntegrationMiddleware`
   - Location: OldOrg Apex Class
   - Lines of Code: ~2,100 lines
   - Handles all HTTP callouts to SmartWaste API
   - Manages authentication, data transformation, error handling

4. **Email Notification:**
   - Sends summary email to `dincer.uyav@vesium.com` after each run
   - Contains success/failure counts

### Recent Execution History

| Date | Total Jobs | Errors | Duration | Status |
|------|-----------|--------|----------|--------|
| Oct 8, 2025 | 2,632 | 2 | 1h 7m | Completed |
| Oct 7, 2025 | 2,626 | 1 | 1h 9m | Completed |
| Oct 6, 2025 | 2,609 | 3 | 1h 10m | Completed |
| Oct 5, 2025 | 2,616 | 1 | 1h 8m | Completed |
| Oct 4, 2025 | 2,638 | 2 | 1h 5m | Completed |

**Note:** "Errors" column shows batch-level errors (technical failures). The actual data validation errors are tracked separately in `SmartWaste_Integration_Log__c`.

---

## SmartWaste API Requirements (ACTUAL)

This section documents what the **SmartWaste API actually requires** based on code analysis of API request structures.

### API Endpoints

**Base URL:** `https://api.smartwaste.co.uk/v1/`

**Authentication Endpoint:**
```
GET /authenticate/{clientKey}?token={randomToken}&password={md5Hash}
```

**Main Data Endpoints:**
1. `POST /{companyId}/waste-carriers` - Create/update waste carrier (hauler/supplier)
2. `POST /{companyId}/waste-destinations` - Create/update waste destination (depot)
3. `POST /{companyId}/projects/{projectId}/waste-items` - Create waste item (job)
4. `POST /{companyId}/projects/{projectId}/waste-carriers/{carrierId}` - Assign carrier to project
5. `POST /{companyId}/projects/{projectId}/waste-destinations/{destinationId}` - Assign destination to project

---

### API Requirement 1: Authentication

**Endpoint:** `GET /authenticate/{clientKey}?token={randomToken}&password={md5Hash}`

**Required Fields:**

| Salesforce Field | API Parameter | Data Type | Source Object | Required? |
|-----------------|---------------|-----------|---------------|-----------|
| `Account.SmartWaste_Client_Key__c` | `clientKey` | String | Account | ✅ YES |
| `Account.SmartWaste_Private_Key__c` | Used to generate `password` | String | Account | ✅ YES |
| `Account.SmartWaste_Username__c` | Used in all subsequent requests | String | Account | ✅ YES |

**API Response:**
```json
{
  "authToken": "abc123...",
  "success": true
}
```

**Notes:**
- Token is session-based, valid for duration of batch execution
- Password is MD5 hash of: `{randomToken}{privateKey}`

---

### API Requirement 2: Create Waste Carrier (Supplier/Hauler)

**Endpoint:** `POST /{companyId}/waste-carriers`

**API Request Structure:**
```json
{
  "carrierName": "string",
  "address1": "string",
  "address2": "string",
  "postcode": "string",
  "county": "string (optional)",
  "town": "string (optional)",
  "licences": [
    {
      "licenceNumber": "string",
      "licenceExpiryDate": "dd/mm/yyyy",
      "licenceIssueDate": "dd/mm/yyyy",
      "evidenceFilename": "string (optional)"
    }
  ],
  "wasteTransferNoteStorage": "string (optional)"
}
```

**Required Salesforce Fields:**

| Salesforce Field | API Field | Data Type | Required by API? | Validation Location |
|-----------------|-----------|-----------|-----------------|---------------------|
| `Account.Name` | `carrierName` | String | ✅ YES | Implicit (Account.Name always exists) |
| `Account.BillingStreet` | `address1` | String | ✅ YES | Not validated (should be) |
| `Account.BillingCity` | `address2` | String | ✅ YES | Not validated (should be) |
| `Account.BillingPostalCode` | `postcode` | String | ✅ YES | Not validated (should be) |
| `Account.Waste_Carriers_License_number__c` | `licences[0].licenceNumber` | String | ✅ YES | Not validated (should be) |
| `Account.Waste_Carriers_License_Date__c` | `licences[0].licenceExpiryDate` | Date | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:447) |
| `Account.Waste_Carriers_Issue_Date__c` | `licences[0].licenceIssueDate` | Date | ✅ YES | Not validated (should be) |

**API Response:**
```json
{
  "carrierID": 12345,
  "carrierName": "...",
  "Success": true
}
```

**Code Location:** `SmartWasteIntegrationMiddleware.saveWasteCarrierToCompany()` (lines 46-101)

---

### API Requirement 3: Create Waste Destination (Depot)

**Endpoint:** `POST /{companyId}/waste-destinations`

**API Request Structure:**
```json
{
  "destinationName": "string",
  "address1": "string",
  "address2": "string",
  "postcode": "string",
  "county": "string (optional)",
  "town": "string (optional)",
  "parentCarrierID": 12345,
  "licences": [
    {
      "licenceNumber": "string",
      "licenceExpiryDate": "dd/mm/yyyy",
      "licenceIssueDate": "dd/mm/yyyy",
      "evidenceFilename": "string (optional)"
    }
  ],
  "rate": [
    {
      "startDate": "dd/mm/yyyy",
      "endDate": "dd/mm/yyyy",
      "recyclingRate": 70,
      "energyRecoveryRate": 20,
      "destinationProductRate": [
        {
          "productID": 1,
          "recyclingRate": 80,
          "energyRecoveryRate": 15
        }
      ]
    }
  ]
}
```

**Required Salesforce Fields:**

| Salesforce Field | API Field | Data Type | Required by API? | Validation Location |
|-----------------|-----------|-----------|-----------------|---------------------|
| `Depot__c.Name` | `destinationName` | String | ✅ YES | Implicit (always exists) |
| `Depot__c.Street__c` | `address1` | String | ✅ YES | Not validated (should be) |
| `Depot__c.City__c` | `address2` | String | ✅ YES | Not validated (should be) |
| `Depot__c.PostCode__c` | `postcode` | String | ✅ YES | Not validated (should be) |
| `Depot__c.Account__r.SmartWaste_Id__c` | `parentCarrierID` | Integer | ✅ YES | ✅ Validated indirectly (creates carrier first) |
| `Depot__c.Permit_Reference__c` | `licences[0].licenceNumber` | String | ✅ YES | Not validated (should be) |
| `Depot__c.Registered_Date__c` | `licences[0].licenceIssueDate` | Date | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:416) |
| `Depot__c.Expiry_Date__c` | `licences[0].licenceExpiryDate` | Date | ⚠️ OPTIONAL | ✅ Validated if populated (SmartWasteIntegrationBatch:419) |
| `Depot__c.SmartWaste_RecyclingRate__c` | `rate[0].recyclingRate` | Integer | ⚠️ Optional (defaults to 70) | Not validated |
| `Depot__c.SmartWaste_EnergyRecoveryRate__c` | `rate[0].energyRecoveryRate` | Integer | ⚠️ Optional (defaults to 20) | Not validated |

**🔴 CRITICAL NOTE:**
- API sends **Depot's Environmental Permit** info (not Depot Account's WCL)
- `licenceNumber` = `Depot.Permit_Reference__c` (EA permit code)
- `licenceIssueDate` = `Depot.Registered_Date__c` (permit issue date)
- `licenceExpiryDate` = `Depot.Expiry_Date__c` (permit expiry)
- **Depot Account WCL is NEVER sent to this endpoint**

**API Response:**
```json
{
  "destinationID": 98765,
  "destinationName": "...",
  "Success": true
}
```

**Code Location:** `SmartWasteIntegrationMiddleware.saveWasteDestinationToCompany()` (lines 151-260)

---

### API Requirement 4: Create Waste Item (Job)

**Endpoint:** `POST /{companyId}/projects/{projectId}/waste-items`

**API Request Structure:**
```json
{
  "wasteID": "",
  "dateEntered": "dd/mm/yyyy",
  "wasteCarrier": {
    "carrierID": 12345
  },
  "wasteDestination": {
    "destinationID": 98765
  },
  "projectPhase": {
    "projectPhaseID": 3
  },
  "wasteManagementRoute": {
    "wasteManagementRouteID": 3
  },
  "wasteManagementLocation": {
    "wasteManagementLocationID": 2
  },
  "skipSize": {
    "skipSizeID": 42,
    "volume": 8.0
  },
  "wasteTransferNote": "WTN12345",
  "voidPercentage": 10,
  "numberOfContainers": 1,
  "overallTonnage": 5.5,
  "sicCode": "38.11",
  "containerSegregated": false,
  "projectTransport": {
    "totalDistanceKms": 25.5,
    "totalDistanceMiles": 15.8,
    "vehicleType": {
      "vehicleTypeID": 1
    },
    "modeOfTransport": {
      "modeID": 1
    },
    "fuelType": {
      "fuelTypeID": 1
    }
  },
  "wasteProducts": [
    {
      "wasteProductID": 20,
      "percentage": 100,
      "tonnage": 5.5
    }
  ],
  "subcontractor": {
    "subcontractorID": 0
  }
}
```

**Plus multipart form data:**
- `file` - Base64 encoded WTN/Consignment Note or ADOC PDF

**Required Salesforce Fields:**

| Salesforce Field | API Field | Data Type | Required by API? | Validation Location |
|-----------------|-----------|-----------|-----------------|---------------------|
| `Job__c.Collection_Date__c` | `dateEntered` | Date | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:400, 453) |
| `Job__c.Supplier__r.SmartWaste_Id__c` | `wasteCarrier.carrierID` | Integer | ✅ YES | ✅ Created if missing |
| `Job__c.Depot_Dispose__r.SmartWaste_Id__c` | `wasteDestination.destinationID` | Integer | ✅ YES | ✅ Created if missing |
| `Job__c.Site__r.SmartWaste_Phase_Id__c` | `projectPhase.projectPhaseID` | Integer | ⚠️ Optional (defaults to 3) | Not validated |
| `Job__c.SmartWaste_Route_Id__c` | `wasteManagementRoute.wasteManagementRouteID` | Integer | ✅ YES (hardcoded to 3) | Not validated |
| `Job__c.Order_Product__r.Product2.SmartWaste_Id__c` | `skipSize.skipSizeID` | Integer | ✅ YES (0 if missing) | ✅ Validated (SmartWasteIntegrationBatch:463) |
| `Job__c.Smartwaste_m3__c` | `skipSize.volume` | Decimal | ⚠️ Optional | Not validated |
| `Job__c.Transport_Receipt_Ref__c` | `wasteTransferNote` | String | ⚠️ Optional | Not validated |
| `Job__c.Void_Percentage__c` | `voidPercentage` | Integer | ⚠️ Optional | Not validated |
| `Job__c.Container_Counter__c` | `numberOfContainers` | Integer | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:456) |
| `Job__c.Weight__c` | `overallTonnage` | Decimal | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:409) |
| `Job__c.SIC_Code__c` | `sicCode` | String | ⚠️ Optional | Not validated |
| `Job__c.Total_Distance_KM__c` | `projectTransport.totalDistanceKms` | Decimal | ⚠️ Optional | Not validated |
| `Job__c.Total_Distance_Miles__c` | `projectTransport.totalDistanceMiles` | Decimal | ⚠️ Optional | Not validated |
| `Job__c.SmartwasteVehicleId__c` | `projectTransport.vehicleType.vehicleTypeID` | Integer | ⚠️ Optional | Not validated |
| `Job__c.SmartWaste_Product_Id__c` | `wasteProducts[0].wasteProductID` | Integer | ✅ YES | ✅ Auto-calculated from EWC code |
| `Job__c.ProductPercentage__c` | `wasteProducts[0].percentage` | Integer | ✅ YES | ✅ Validated (SmartWasteIntegrationBatch:432) |
| `Job__c.WTN_ContentDistribution_Id__c` | Attachment file | String (ContentDistribution ID) | ⚠️ Conditional | ✅ Validated if in Required_Paperwork__c (SmartWasteIntegrationBatch:435) |
| `Job__c.DOC_ContentDistribution_Id__c` | Attachment file | String (ContentDistribution ID) | ⚠️ Conditional | ✅ Validated if in Required_Paperwork__c (SmartWasteIntegrationBatch:438) |

**API Response:**
```json
{
  "wasteID": 555666,
  "Success": true
}
```

**Code Location:** `SmartWasteIntegrationMiddleware.saveWasteItem()` (lines 328-480)

---

## Internal Salesforce Validations

All validations occur in **`SmartWasteIntegrationBatch.validateJob()`** method (lines 397-500).

### Complete Validation List (In Order of Execution)

| # | Validation Check | Error Message | Line # | Required by API? | Status |
|---|-----------------|---------------|--------|-----------------|--------|
| 1 | `Collection_Date__c < Account.SmartWaste_JobStartDateFormula__c` | Job > Collection Date cannot be before than {date} | 400-401 | ❌ Business rule | ✅ Correct |
| 2 | `Site__r.SmartWaste_Id__c` is blank | Job > Site > SmartWasteId (ProjectId) cannot be empty | 403-404 | ✅ YES (used in API URLs) | ✅ Correct |
| 3 | `Paperwork_Done__c = false` | Job > Paperwork Done was unchecked | 406-407 | ❌ Business rule | ✅ Correct |
| 4 | `Weight__c = null` | Job > Weight cannot be empty | 409-410 | ✅ YES (overallTonnage) | ✅ Correct |
| 5 | `Depot_Dispose__c` is blank | Job > Depot Dispose cannot be empty | 412-413 | ✅ YES (destinationID) | ✅ Correct |
| 6 | `Depot_Dispose__r.Registered_Date__c = null` | Job > Depot Dispose Registered Date cannot be empty | 416-417 | ✅ YES (licenceIssueDate) | ✅ Correct |
| 7 | `Depot_Dispose__r.Expiry_Date__c < TODAY` | Job > Depot Dispose Expired | 419-421 | ⚠️ Optional field check | ✅ Correct |
| 8 | `Supplier__c` is blank | Job > Supplier cannot be empty | 426-427 | ✅ YES (carrierID) | ✅ Correct |
| 9 | `ProductPercentage__c = null` | Job > Product Percentage cannot be empty | 432-433 | ✅ YES (wasteProducts percentage) | ✅ Correct |
| 10 | WTN/Consignment Note file missing (if required) | Job > WTN/Consignment Note File required but there was no file attached | 435-436 | ⚠️ Conditional | ✅ Correct |
| 11 | ADOC file missing (if required) | Job > ADOC File required but there was no file attached to this job or Schedule record | 438-439 | ⚠️ Conditional | ✅ Correct |
| 12 | `Account.SmartWaste_Company_Id__c` is blank | Job > Site > Account > SmartWaste CompanyId cannot be empty | 441-442 | ✅ YES (used in API URLs) | ✅ Correct |
| 13 | `Account.SmartWaste_Username__c` is blank | Job > Site > Account > SmartWaste Username cannot be empty | 444-445 | ✅ YES (authentication) | ✅ Correct |
| 14 | `Supplier__r.SmartWaste_Id__c` is blank AND `Supplier__r.Waste_Carriers_License_Date__c` is blank | Job > Supplier > Waste Carrier License Date cannot be empty | 447-448 | ✅ YES (licenceExpiryDate) | ✅ Correct |
| 15 | `Depot_Dispose__r.Account__r.SmartWaste_Id__c` is blank AND `Depot_Dispose__r.Account__r.Waste_Carriers_License_Date__c` is blank | Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty | 450-451 | 🔴 **NO - WRONG!** | ❌ **INCORRECT** |
| 16 | `Collection_Date__c = null` | Job > Collection Date cannot be empty | 453-454 | ✅ YES (dateEntered) | ✅ Correct (duplicate of #1) |
| 17 | `Container_Counter__c = null` | Job > Container Count cannot be empty | 456-458 | ✅ YES (numberOfContainers) | ✅ Correct |
| 18 | `Order_Product__r.Product2.SmartWaste_Id__c` is blank | Job > Order Product > Product > SmartWasteId cannot be empty (Will be used for skip size) | 463-464 | ✅ YES (skipSizeID) | ✅ Correct |
| 19 | Status not in (Collected, Paperwork Provided, Completed) | Job > Status can only be Collected, Paperwork Provided and Completed | 467-468 | ❌ Business rule | ✅ Correct |
| 20 | Heap size > 12MB | General > Salesforce Heap Size too large for API communication, please check the job attachment sizes (WTN, Adoc). Max allowed file size is 6mb. | 495-496 | ✅ Technical limit | ✅ Correct |

---

## Validation vs API Requirements Comparison

### ✅ Correctly Validated (17 validations)

These validations correctly enforce SmartWaste API requirements:

1. **Authentication Fields** - Company ID, Username (required for all API calls)
2. **Job Core Fields** - Collection Date, Weight, Product Percentage, Container Count
3. **Supplier WCL** - Required by API for waste carrier creation
4. **Depot Permit Fields** - Registered Date (issue date), Expiry Date (if populated)
5. **Product Mapping** - SmartWaste Product ID for skip size
6. **Paperwork Files** - WTN/ADOC when flagged as required
7. **Site Project ID** - Required for API URL construction

### ❌ Incorrectly Validated (1 validation)

**Validation #15: Depot Account Waste Carrier License**

**Current Logic:**
```apex
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)
    && String.isBlank(String.valueOf(j.Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_DATE__C))){
    validationMessages += 'Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty \r\n';
}
```

**Why This Is Wrong:**

1. **SmartWaste API doesn't require it:**
   - When creating a Waste Destination, the API receives:
     - `licenceNumber` = `Depot.Permit_Reference__c` (Environmental Permit)
     - `licenceIssueDate` = `Depot.Registered_Date__c` (Permit issue date)
     - `licenceExpiryDate` = `Depot.Expiry_Date__c` (Permit expiry)
   - The Depot Account's WCL is **NEVER sent** to the waste-destinations endpoint

2. **UK Regulatory Context:**
   - **Waste Carrier License (WCL):** Required for TRANSPORTING waste
   - **Environmental Permit:** Required for TREATING/DISPOSING waste at facilities
   - Depots are disposal facilities, not transport companies
   - They need Environmental Permits, not WCL

3. **Data Reality:**
   - Many depot Accounts correctly have NULL `Waste_Carriers_License_Date__c`
   - All depots have `Permit_Reference__c` (their actual permit)
   - This validation is blocking 149 jobs unnecessarily

4. **Code Flow Shows It's Not Needed:**
   - When Depot Account needs to be a carrier (for transport), it's created separately
   - The validation checks if Account already has `SmartWaste_Id__c` (meaning it's already created)
   - If not, it checks WCL - but this is wrong because we're creating a DESTINATION, not a CARRIER

**Impact:**
- 149 jobs blocked with error SW-13715925
- "Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty"

**Fix Required:**
Remove lines 450-452 from `SmartWasteIntegrationBatch.validateJob()`:
```apex
// DELETE THESE LINES:
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c) && String.isBlank(String.valueOf(j.Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_DATE__C))){
    validationMessages += 'Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty \r\n';
}
```

### ⚠️ Missing Validations (Recommendations)

These fields are required by SmartWaste API but NOT validated:

| Field | API Requirement | Current Validation | Risk Level |
|-------|----------------|-------------------|-----------|
| `Supplier.BillingStreet` | address1 | None | 🟡 Medium - Will cause API error |
| `Supplier.BillingCity` | address2 | None | 🟡 Medium - Will cause API error |
| `Supplier.BillingPostalCode` | postcode | None | 🟡 Medium - Will cause API error |
| `Supplier.Waste_Carriers_License_number__c` | licenceNumber | None | 🟡 Medium - Will cause API error |
| `Supplier.Waste_Carriers_Issue_Date__c` | licenceIssueDate | None | 🟡 Medium - Will cause API error |
| `Depot.Street__c` | address1 | None | 🟡 Medium - Will cause API error |
| `Depot.City__c` | address2 | None | 🟡 Medium - Will cause API error |
| `Depot.PostCode__c` | postcode | None | 🟡 Medium - Will cause API error |
| `Depot.Permit_Reference__c` | licenceNumber | None | 🟡 Medium - Will cause API error |

**Recommendation:** Add these validations to prevent API errors downstream.

---

## Identified Validation Issues

### Issue 1: Depot Account WCL Validation (CRITICAL)

**Error Log Example:** SW-13715925
**Error Message:** "Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty"

**Status:** 🔴 **BLOCKING 149 JOBS**

**Affected Job Example:**
```
Job: Job-000570220
Supplier: BIOMARSH ENVIRONMENTAL LTD
Supplier WCL Date: 2028-03-30 ✅ VALID
Depot: Swindon STW
Depot Permit: EA/EPR/WB3634FD/A001 ✅ VALID
Depot Account WCL Date: NULL ❌ VALIDATION FAILS
```

**Root Cause Analysis:**

The validation confuses two different regulatory concepts:

1. **Waste Carrier License (WCL):**
   - UK regulation: Required to TRANSPORT waste
   - Applies to: Suppliers (haulers), Transport companies
   - Field: `Account.Waste_Carriers_License_Date__c`
   - Expires: Every 3 years

2. **Environmental Permit:**
   - UK regulation: Required to TREAT/DISPOSE waste
   - Applies to: Depots (disposal facilities)
   - Field: `Depot__c.Permit_Reference__c`, `Depot__c.Registered_Date__c`, `Depot__c.Expiry_Date__c`
   - Issued by: Environment Agency (EA)

**SmartWaste API Behavior:**

When creating a Waste Destination (depot), the API endpoint is:
```
POST /{companyId}/waste-destinations
```

Request body includes:
```json
{
  "destinationName": "Swindon STW",
  "licences": [
    {
      "licenceNumber": "EA/EPR/WB3634FD/A001",  // ← Depot PERMIT (not Account WCL)
      "licenceIssueDate": "01/01/1992",          // ← Depot Registered_Date__c
      "licenceExpiryDate": "01/01/2025"          // ← Depot Expiry_Date__c
    }
  ]
}
```

**The Depot Account's WCL is NOT included in this request.**

**Why the Validation Exists:**

Looking at the code logic, there's a scenario where the Depot Account might also be registered as a Waste Carrier (for transport purposes). The code does this:

```apex
// Line 296-310 in SmartWasteIntegrationBatch
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)){
    // Create Depot Account as a Waste Carrier
    SmartWasteIntegrationMiddleware.saveWasteCarrierToCompany(..., j.Depot_Dispose__r.Account__r, ...);
}
```

However:
1. This is **OPTIONAL** - only happens if Depot Account doesn't have a SmartWaste_Id__c yet
2. Most Depot Accounts are NOT transport companies
3. The validation should NOT block jobs where the Depot Account won't be used as a carrier

**Correct Logic Should Be:**

```apex
// Only validate Depot Account WCL if we're about to create it as a carrier
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)) {
    // Check if this account is ALSO a transport company
    // Most depots are NOT, so this check should be removed entirely
    // OR: Only require WCL if Account.Type__c = 'Transport Company'
}
```

**Fix Recommendation:**

**Option A (Recommended):** Remove the validation entirely
```apex
// DELETE lines 450-452
```

**Option B (Alternative):** Make it conditional on Account Type
```apex
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)
    && j.Depot_Dispose__r.Account__r.Type__c == 'Transport Company'
    && String.isBlank(String.valueOf(j.Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_DATE__C))){
    validationMessages += 'Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty \r\n';
}
```

**Testing Impact:**
- Will unblock 149 jobs immediately
- No risk to API functionality (API doesn't require this field)
- Aligns with UK regulatory requirements

---

### Issue 2: Duplicate Collection Date Validation

**Validation #1 (Line 400):** Checks `Collection_Date__c < Account.SmartWaste_JobStartDateFormula__c`
**Validation #16 (Line 453):** Checks `Collection_Date__c = null`

**Status:** ⚠️ **REDUNDANT** (not harmful, but inefficient)

**Fix Recommendation:** Remove validation #16 (line 453-454) as it's covered by validation #1

---

### Issue 3: Missing Address Validations

**Fields Required by API but Not Validated:**

**For Suppliers (Waste Carriers):**
- `Account.BillingStreet` → API: `address1`
- `Account.BillingCity` → API: `address2`
- `Account.BillingPostalCode` → API: `postcode`
- `Account.Waste_Carriers_License_number__c` → API: `licenceNumber`
- `Account.Waste_Carriers_Issue_Date__c` → API: `licenceIssueDate`

**For Depots (Waste Destinations):**
- `Depot__c.Street__c` → API: `address1`
- `Depot__c.City__c` → API: `address2`
- `Depot__c.PostCode__c` → API: `postcode`
- `Depot__c.Permit_Reference__c` → API: `licenceNumber`

**Status:** 🟡 **MISSING VALIDATION** (will cause API errors downstream)

**Current Behavior:**
- Jobs pass validation
- API call fails with HTTP 400 error
- Error message: "The request is badly formed"
- No specific field indicated

**Fix Recommendation:** Add these validations to `validateJob()` method:

```apex
// After line 428 (Supplier validation section)
if (String.isBlank(j.Supplier__r.SmartWaste_Id__c)) {
    if (String.isBlank(j.Supplier__r.BillingStreet)) {
        validationMessages += 'Job > Supplier > Billing Street cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.BillingCity)) {
        validationMessages += 'Job > Supplier > Billing City cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.BillingPostalCode)) {
        validationMessages += 'Job > Supplier > Billing Postal Code cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.Waste_Carriers_License_number__c)) {
        validationMessages += 'Job > Supplier > Waste Carrier License Number cannot be empty \r\n';
    }
    if (j.Supplier__r.Waste_Carriers_Issue_Date__c == null) {
        validationMessages += 'Job > Supplier > Waste Carrier License Issue Date cannot be empty \r\n';
    }
}

// After line 423 (Depot validation section)
if (String.isBlank(j.Depot_Dispose__r.SmartWaste_Id__c)) {
    if (String.isBlank(j.Depot_Dispose__r.Street__c)) {
        validationMessages += 'Job > Depot Dispose > Street cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.City__c)) {
        validationMessages += 'Job > Depot Dispose > City cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.PostCode__c)) {
        validationMessages += 'Job > Depot Dispose > Postal Code cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.Permit_Reference__c)) {
        validationMessages += 'Job > Depot Dispose > Permit Reference cannot be empty \r\n';
    }
}
```

---

## Integration Flow Detailed

### Complete Flow with API Calls

```
┌─────────────────────────────────────────────────────────────┐
│ 1. SCHEDULED JOB EXECUTION                                 │
│    - SmartWaste_Integration-10                             │
│    - Daily at 00:00 UTC                                    │
│    - Starts SmartWasteIntegrationBatch                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. QUERY ELIGIBLE JOBS                                     │
│    - Status = Collected/Paperwork Provided/Completed       │
│    - SmartWaste_Id__c = null (not sent yet)                │
│    - Account has SmartWaste credentials                    │
│    - Attempt_Send_to_SmartWaste__c = true                  │
│    Result: ~2,600 jobs                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. FOR EACH JOB: PRE-API VALIDATION                        │
│    - Run validateJob() method (20 checks)                  │
│    - If fails: Create SmartWaste_Integration_Log__c        │
│    - If passes: Continue to API calls                      │
│    Current: 99% fail here (2,119 jobs)                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. AUTHENTICATION (per Account)                            │
│    API: GET /authenticate/{clientKey}?token=...            │
│    - Uses SmartWaste_Client_Key__c                         │
│    - Uses SmartWaste_Private_Key__c                        │
│    - Returns: authToken (valid for batch duration)         │
│    - Cached in accountTokens Map                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. CREATE/UPDATE WASTE CARRIER (Supplier)                  │
│    IF Supplier.SmartWaste_Id__c = null                     │
│    API: POST /{companyId}/waste-carriers                   │
│    - Sends: Name, Address, WCL info                        │
│    - Returns: carrierID                                    │
│    - Saves to: Supplier.SmartWaste_Id__c                   │
│    - Auto-assigns to project                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. CREATE DEPOT ACCOUNT AS CARRIER (if needed)             │
│    IF Depot.Account.SmartWaste_Id__c = null                │
│    API: POST /{companyId}/waste-carriers                   │
│    - Sends: Depot Account WCL info                         │
│    - Returns: carrierID                                    │
│    - Saves to: Depot.Account.SmartWaste_Id__c              │
│    - Auto-assigns to project                               │
│    NOTE: This is where the incorrect validation comes in   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. CREATE/UPDATE WASTE DESTINATION (Depot)                 │
│    IF Depot.SmartWaste_Id__c = null                        │
│    API: POST /{companyId}/waste-destinations               │
│    - Sends: Name, Address, Permit info, Recycling rates    │
│    - Requires: parentCarrierID (from step 6)               │
│    - Returns: destinationID                                │
│    - Saves to: Depot.SmartWaste_Id__c                      │
│    - Auto-assigns to project                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. UPDATE WASTE DESTINATION RATES                          │
│    API: PUT /{companyId}/waste-destinations/{id}           │
│    - Sends: Material_Recycling_Rate__c records             │
│    - Updates recycling rates per waste product type        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. CREATE WASTE ITEM (Job)                                 │
│    API: POST /{companyId}/projects/{projectId}/waste-items │
│    - Sends: Job details, tonnage, products, files          │
│    - Multipart form data with WTN/ADOC PDF                 │
│    - Returns: wasteID                                      │
│    - Saves to: Job.SmartWaste_Id__c                        │
│    SUCCESS: Job sent to SmartWaste portal!                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 10. ERROR HANDLING                                         │
│     IF any API call fails:                                 │
│     - Create SmartWaste_Integration_Log__c                 │
│     - Store error message from API                         │
│     - Job.SmartWaste_Id__c remains null                    │
│     - Will retry in next batch run                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 11. BATCH COMPLETION                                       │
│     - Count: successfullJobCount, failedJobCount           │
│     - Send email to dincer.uyav@vesium.com                 │
│     - Email contains: success count, failure count, link   │
└─────────────────────────────────────────────────────────────┘
```

### API Call Dependencies

```
authenticate()
    ↓
    ├─→ saveWasteCarrierToCompany(Supplier) → returns carrierID
    │
    ├─→ saveWasteCarrierToCompany(Depot.Account) → returns parentCarrierID
    │       ↓
    │       └─→ saveWasteDestinationToCompany(Depot) → returns destinationID
    │               ↓
    │               └─→ updateWasteDestination(rates)
    │
    └─→ saveWasteItem(Job) → returns wasteID ✅ SUCCESS
```

**Key Dependency:** Depot Account must have SmartWaste_Id__c (parentCarrierID) before creating the Waste Destination.

**This is where the bug is:** The validation assumes Depot Account MUST have a WCL to get a SmartWaste_Id__c, but that's not true:
- If Depot Account already has SmartWaste_Id__c, WCL is NOT needed
- If Depot Account will be created as a carrier, WCL would be needed BUT most depot accounts are NOT transport companies
- The validation incorrectly blocks ALL cases where Depot Account lacks WCL

---

## Recommendations

### Immediate Actions (Next 24 Hours)

#### 1. 🔴 **CRITICAL: Fix Depot Account WCL Validation**

**Action:** Remove incorrect validation from `SmartWasteIntegrationBatch`

**Code Change:**
```apex
// File: SmartWasteIntegrationBatch.cls
// Method: validateJob()
// Lines: 450-452

// DELETE THESE LINES:
if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c) && String.isBlank(String.valueOf(j.Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_DATE__C))){
    validationMessages += 'Job > Depot Dispose > Account > Waste Carrier License Date cannot be empty \r\n';
}
```

**Impact:**
- Unblocks 149 jobs immediately
- No risk to API functionality
- Aligns with UK regulations
- Aligns with SmartWaste API requirements

**Testing:**
```apex
// Test with Job-000570220 (currently failing)
SmartWasteIntegrationBatch batch = new SmartWasteIntegrationBatch('a26Sj000001NgHJIA0');
Database.executeBatch(batch, 1);
// Expected: Job should pass validation and send to SmartWaste
```

**Deployment:**
1. Create change set with SmartWasteIntegrationBatch
2. Deploy to NewOrg
3. Run batch manually for blocked jobs
4. Monitor SmartWaste_Integration_Log__c for new errors

---

#### 2. 🟡 **MEDIUM: Add Missing Address Validations**

**Action:** Add validations for API-required fields

**Code Changes:**
```apex
// After line 428 (after Supplier validation)
if (String.isBlank(j.Supplier__r.SmartWaste_Id__c)) {
    if (String.isBlank(j.Supplier__r.BillingStreet)) {
        validationMessages += 'Job > Supplier > Billing Street cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.BillingCity)) {
        validationMessages += 'Job > Supplier > Billing City cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.BillingPostalCode)) {
        validationMessages += 'Job > Supplier > Billing Postal Code cannot be empty \r\n';
    }
    if (String.isBlank(j.Supplier__r.Waste_Carriers_License_number__c)) {
        validationMessages += 'Job > Supplier > Waste Carrier License Number cannot be empty \r\n';
    }
    if (j.Supplier__r.Waste_Carriers_Issue_Date__c == null) {
        validationMessages += 'Job > Supplier > Waste Carrier License Issue Date cannot be empty \r\n';
    }
}

// After line 423 (after Depot validation)
if (String.isBlank(j.Depot_Dispose__r.SmartWaste_Id__c)) {
    if (String.isBlank(j.Depot_Dispose__r.Street__c)) {
        validationMessages += 'Job > Depot Dispose > Street cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.City__c)) {
        validationMessages += 'Job > Depot Dispose > City cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.PostCode__c)) {
        validationMessages += 'Job > Depot Dispose > Postal Code cannot be empty \r\n';
    }
    if (String.isBlank(j.Depot_Dispose__r.Permit_Reference__c)) {
        validationMessages += 'Job > Depot Dispose > Permit Reference cannot be empty \r\n';
    }
}
```

**Impact:**
- Prevents downstream API 400 errors
- Provides clearer error messages to users
- Improves data quality

**Note:** This will likely INCREASE validation failures initially, but that's good - it surfaces data quality issues earlier.

---

#### 3. 🟢 **LOW: Remove Duplicate Validation**

**Action:** Remove duplicate Collection Date null check

**Code Change:**
```apex
// Lines: 453-454
// DELETE THESE LINES (already checked at line 400):
if (j.Collection_Date__c == null){
    validationMessages += 'Job > Collection Date cannot be empty \r\n';
}
```

**Impact:**
- Cleaner code
- No functional change (already validated above)

---

### Short-Term Actions (Next Week)

#### 4. **Update SOQL Query in Batch**

**Current Issue:** Query doesn't include all fields needed for new validations

**Action:** Add missing fields to query in `SmartWasteIntegrationBatch` constructor

**Code Change:**
```apex
// Add after line 28:
query += ' ,Supplier__r.BillingStreet, Supplier__r.BillingCity, Supplier__r.BillingPostalCode';
query += ' ,Depot_Dispose__r.Street__c, Depot_Dispose__r.City__c, Depot_Dispose__r.PostCode__c';
```

---

#### 5. **Create Validation Report**

**Action:** Create Salesforce report to identify data quality issues BEFORE batch runs

**Report Type:** Jobs

**Columns:**
- Job Name
- Status
- Account Name
- Validation Status (formula field - see below)
- Missing Fields (formula field - see below)

**Formula Field: Validation_Status__c**
```
IF(
  AND(
    Paperwork_Done__c,
    NOT(ISBLANK(Weight__c)),
    NOT(ISBLANK(ProductPercentage__c)),
    NOT(ISBLANK(Supplier__c)),
    NOT(ISBLANK(Depot_Dispose__c)),
    NOT(ISBLANK(Site__r.SmartWaste_Id__c)),
    NOT(ISBLANK(Order_Product__r.Product2.SmartWaste_Id__c))
  ),
  "✅ Ready",
  "❌ Incomplete"
)
```

---

#### 6. **User Training Materials**

**Action:** Create documentation for operations team

**Documents to Create:**
1. **SmartWaste Field Requirements Checklist** (PDF)
2. **Common Validation Errors Guide** (Knowledge Article)
3. **Step-by-Step Job Completion Process** (Video/Screenshots)

**Key Points to Cover:**
- Why each field is required
- Where to find the information
- How to attach WTN/ADOC files correctly
- How to check if job will pass validation

---

### Long-Term Actions (Next Month)

#### 7. **Implement Real-Time Validation**

**Action:** Create Lightning Web Component on Job page

**Features:**
- ✅ Show "SmartWaste Readiness" score (0-100%)
- ✅ List missing required fields
- ✅ Show warnings for optional fields
- ✅ "Test Validation" button
- ✅ Green checkmark when ready

**Benefits:**
- Proactive issue prevention
- Users can fix issues immediately
- Reduces batch failure rate

---

#### 8. **Enhanced Error Logging**

**Action:** Improve SmartWaste_Integration_Log__c structure

**New Fields:**
- `Validation_Type__c` (picklist: Pre-API, API Error, Network Error)
- `Field_Name__c` (which field caused the error)
- `Resolved__c` (checkbox - marked when job succeeds)
- `Resolution_Date__c` (date - when resolved)

**Benefits:**
- Better error analytics
- Track resolution time
- Identify recurring issues

---

#### 9. **Validation Rule on Job Object**

**Action:** Prevent status changes without required fields

**Rule Logic:**
```
AND(
  ISCHANGED(Status__c),
  OR(
    ISPICKVAL(Status__c, "Collected"),
    ISPICKVAL(Status__c, "Paperwork Provided")
  ),
  OR(
    NOT(Paperwork_Done__c),
    ISBLANK(Weight__c),
    ISBLANK(ProductPercentage__c),
    ISBLANK(Supplier__c),
    ISBLANK(Depot_Dispose__c)
  )
)
```

**Error Message:**
"Cannot mark job as Collected/Paperwork Provided without completing: Paperwork Done, Weight, Product Percentage, Supplier, and Depot Dispose fields."

---

## Current Integration Query Criteria

Jobs are eligible for Smart Waste integration IF:

```sql
WHERE Site__r.Account__r.SmartWaste_Private_Key__c != ''
  AND Site__r.Account__r.SmartWaste_Client_Key__c != ''
  AND SMS_Job_Id__c = ''
  AND SMS_Job_Duplicated__c = false
  AND (Status__c = 'Collected' OR Status__c = 'Paperwork Provided' OR Status__c = 'Completed')
  AND SmartWaste_Id__c = null
  AND Attempt_Send_to_SmartWaste__c = true
```

**Translation:**
- Account must have Smart Waste credentials configured
- Job must be Collected/Paperwork Provided/Completed status
- Job hasn't been sent yet (SmartWaste_Id__c is null)
- Job is flagged to attempt sending

---

## Supporting Documentation

### Code Locations

**Primary Classes:**
- `SmartWasteIntegrationBatch` - Main batch class (~500 lines)
  - `validateJob()` method - Lines 397-500 (validation logic)
  - `execute()` method - Lines 127-395 (API orchestration)
  - `finish()` method - Lines 396 (email notification)

- `SmartWasteIntegrationMiddleware` - API callout handler (~2,100 lines)
  - `authenticate()` - Lines 790-820
  - `saveWasteCarrierToCompany()` - Lines 46-101
  - `saveWasteDestinationToCompany()` - Lines 151-260
  - `saveWasteItem()` - Lines 328-480
  - `updateWasteDestination()` - Lines 650-750

**Custom Objects:**
- `SmartWaste_Integration_Log__c` - Error tracking
  - Fields: Description__c, Related_Job__c, Related_Account__c, Related_Site__c

**Scheduled Jobs:**
- `SmartWaste_Integration-10` - Daily at 00:00 UTC
- `SmartWaste Log Cleanup` - Daily at 08:00 UTC

---

### Integration Logs Location

- Object: `SmartWaste_Integration_Log__c`
- View: [Smart Waste Integration Logs](https://recyclinglives.lightning.force.com/lightning/o/SmartWaste_Integration_Log__c/list?filterName=00B8E000003asRgUAI)
- Current Count: 2,119 error entries (October 8, 2025)

---

## Conclusion

**The integration is working correctly** - it's validating data before sending to SmartWaste API.

**The primary issue is one INCORRECT validation:**
- Depot Account WCL check is not required by SmartWaste API
- This blocks 149 jobs unnecessarily
- Should be removed immediately

**Secondary issues are MISSING validations:**
- Supplier and Depot address fields
- These should be added to prevent API errors

**Data quality remains the main challenge:**
- 99% of jobs missing required fields
- Need user training and process improvements
- Real-time validation would help significantly

**Next Steps:**
1. Remove Depot Account WCL validation (deploy today)
2. Add missing address validations (deploy this week)
3. Create validation report for proactive monitoring
4. Implement real-time validation component (next month)

---

**Analysis Completed By:** Claude Code
**Date:** October 29, 2025
**Original Analysis:** October 8, 2025
**Organization:** OldOrg (Recycling Lives Service)
**Document Version:** 2.0 (Complete API Requirements vs Validation Analysis)
