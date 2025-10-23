# Sage API Integration - NewOrg Configuration Guide

**Created**: October 23, 2025
**Scenario Type**: ⚙️ **Configuration** (OAuth Authentication Setup)
**Target Organization**: NewOrg (Recycling Lives Group)
**Status**: 📋 Configuration Guide Ready

---

## Executive Summary

**What This Guides**: OAuth authentication setup and maintenance for Sage API Named Credential in NewOrg.

**Configuration Type**: **Manual UI Configuration** - No code deployment required

**Critical Information**:
- **NOT a code deployment scenario** - Pure OAuth authentication configuration
- **No Gap Analysis** - Code already exists in NewOrg (same Sage API integration classes)
- **Configuration Only**: Authenticate Named Credential with NewOrg Sage credentials
- **Pre-Requisites**: Named Credential "SIA" and Auth Provider "Sage" must exist in NewOrg

**What This Documents**:
1. How to authenticate Sage API Named Credential in NewOrg
2. Configuration verification steps
3. Testing procedures to confirm integration works
4. Troubleshooting guide for authentication failures
5. Monitoring and maintenance schedule

**OldOrg Reference**: See [OldOrg State Documentation](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/sage-api-integration) for incident details and resolution history from October 15-17, 2025.

---

## System Overview

### What is This Integration?

**Sage 200 Extra API Integration** connects Salesforce to Sage 200 accounting system for:

1. **Invoice Export** - Export customer and vendor invoices from Salesforce to Sage
2. **Customer Sync** - Sync customer data from Sage to Salesforce (scheduled)
3. **Supplier Sync** - Sync RLCS supplier data from Sage to Salesforce (scheduled)
4. **Account Management** - Bidirectional account synchronization

### Authentication Architecture

```
Salesforce NewOrg
├── SageAPIClient.cls (Apex Class) - Already deployed in NewOrg
│   └── Uses: callout:SIA/<endpoint>
│
├── Named Credential: "SIA" - ⚠️ NEEDS AUTHENTICATION
│   ├── Endpoint: api.columbus.sage.com/uk/sage200extra/accounts/v1/
│   ├── Protocol: OAuth 2.0
│   ├── Principal Type: NamedUser (org-wide authentication)
│   └── Scopes: openid profile email offline_access
│
└── Auth Provider: "Sage" - ⚠️ VERIFY CONFIGURATION
    ├── Type: OpenIdConnect (OAuth 2.0)
    ├── Consumer Key: HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb
    ├── Consumer Secret: (Must be configured in NewOrg)
    ├── Token URL: https://id.sage.com/oauth/token
    └── Auth URL: https://id.sage.com/authorize

                    ↓ OAuth Authentication ↓

Sage Identity Service (https://id.sage.com)
├── Issues Access Token (expires ~1 hour)
└── Issues Refresh Token (expires 60-90 days)

                    ↓ API Access ↓

Sage 200 Extra API (https://api.columbus.sage.com)
├── Accounts API
├── Invoices API
├── Suppliers API
└── Customers API
```

**Important**: NewOrg will use **NewOrg-specific Sage credentials**, NOT the same credentials as OldOrg.

---

## Pre-Configuration Verification

### Step 1: Verify Named Credential Exists

**Check if SIA Named Credential exists in NewOrg:**

1. Navigate to **Setup** (gear icon, top right)
2. In Quick Find, search for **"Named Credentials"**
3. Click **Named Credentials**
4. Look for **SIA** in the list

**Expected**: Named Credential "SIA" should exist (deployed as part of Sage API integration code)

**If Missing**:
- Check if Sage API integration code has been deployed to NewOrg
- Verify `namedCredentials/SIA.namedCredential-meta.xml` exists in org metadata

### Step 2: Verify Auth Provider Exists

**Check if Sage Auth Provider exists in NewOrg:**

1. Navigate to **Setup** → Quick Find → **Auth. Providers**
2. Look for **Sage** in the list
3. Click **Sage** to view configuration

**Expected Configuration**:

| Setting | Expected Value |
|---------|----------------|
| Provider Type | OpenIdConnect |
| Name | Sage |
| Consumer Key | `HfbzYzoh2jxTGkLfSG6T3Z8Qdh41Gesb` |
| Consumer Secret | **(Must be valid for NewOrg Sage environment)** |
| Authorize Endpoint URL | `https://id.sage.com/authorize?audience=s200ukipd/sage200` |
| Token Endpoint URL | `https://id.sage.com/oauth/token` |
| Default Scopes | `openid profile email offline_access` |

**Critical Check**: If **Consumer Secret** shows `Placeholder_Value` or is incorrect:
1. Retrieve the actual consumer secret from Sage developer portal for **NewOrg environment**
2. Update the Auth Provider with the correct secret
3. Click **Save**

**If Missing**:
- Check if Sage API integration code has been deployed to NewOrg
- Verify `authproviders/Sage.authprovider-meta.xml` exists in org metadata

### Step 3: Verify Sage API Settings (Custom Settings)

**Check Custom Setting values:**

```bash
sf data query --query "SELECT Endpoint_Prefix__c, Endpoint_Prefix_RLCS__c, Subscription_Key__c, Subscription_Key_RLCS__c, Site_Id__c, Site_Id_RLCS__c, Company_Id__c, Company_Id_RLCS__c FROM Sage_API_Settings__c" --target-org NewOrg --use-tooling-api
```

**Expected Values** (NewOrg-specific):

| Field | RLES Value | RLCS Value | Notes |
|-------|------------|------------|-------|
| Endpoint_Prefix | `SIA` | `SIA` | Same as OldOrg |
| Subscription_Key | `<NewOrg key>` | `<NewOrg key>` | ⚠️ May differ from OldOrg |
| Site_Id | `<NewOrg site ID>` | `<NewOrg site ID>` | ⚠️ May differ from OldOrg |
| Company_Id | `<NewOrg company>` | `<NewOrg company>` | ⚠️ May differ from OldOrg |

**If Values Missing or Incorrect**:
1. Navigate to **Setup** → Quick Find → **Custom Settings**
2. Click **Sage_API_Settings__c**
3. Click **Manage** → **New** (or **Edit** if exists)
4. Enter NewOrg-specific values from Sage 200 configuration

**⚠️ IMPORTANT**: Do NOT copy OldOrg values directly. Use NewOrg-specific Sage 200 configuration values.

---

## Configuration Steps (NewOrg)

### Phase 1: Authenticate Named Credential

**As Salesforce Administrator in NewOrg:**

1. Navigate to **Setup** (gear icon, top right)
2. In Quick Find, search for **"Named Credentials"**
3. Click **Named Credentials**
4. Find and click **SIA** in the list
5. Click **Edit** button
6. Look for the **Authentication Status** section
   - If shows "Not Authenticated" or "Authentication Required" → Proceed to next step
   - If shows "Authenticated" → Skip to Phase 2 (Testing)
7. Click **Authenticate** button
8. You will be redirected to Sage login page: `https://id.sage.com/authorize`
9. **Log in with NewOrg Sage 200 Extra credentials:**
   - Use the **NewOrg service account** credentials for Sage API access
   - **Important**: Use the account that has API permissions in NewOrg's Sage 200 instance
   - **NOT the same credentials as OldOrg**
10. **Authorize the application:**
    - Review requested permissions: `openid profile email offline_access`
    - Click **Allow** or **Authorize**
11. You'll be redirected back to Salesforce NewOrg
12. Verify authentication status shows **Connected** or **Authenticated**
13. Click **Save**

**Expected Result**:
- ✅ Named Credential status: **Authenticated**
- ✅ OAuth token successfully obtained
- ✅ Ready to test Sage API integrations

**If Authentication Fails**:
- Verify Sage service account credentials are correct for NewOrg environment
- Check Auth Provider Consumer Secret is correct for NewOrg
- See [Troubleshooting Guide](#troubleshooting-guide) below

---

## Testing & Verification

### Phase 2: Test API Connection

**Test 1: Anonymous Apex Connection Test**

```apex
// Test Sage API connection in NewOrg
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SIA/sales_customers');
req.setMethod('GET');

// Get values from Custom Settings in NewOrg
Sage_API_Settings__c settings = Sage_API_Settings__c.getInstance();
req.setHeader('ocp-apim-subscription-key', settings.Subscription_Key__c);
req.setHeader('X-Site', settings.Site_Id__c);
req.setHeader('X-Company', settings.Company_Id__c);

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status Code: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());

// Expected: Status Code 200
// If 401: Authentication failed
// If 403: Authenticated but no permission
```

**Expected Result**:
- ✅ Status Code: `200`
- ✅ Response Body: JSON with customer data from NewOrg's Sage 200

**If Status Code 401**:
- Named Credential not authenticated properly
- Go back to Phase 1 and re-authenticate
- Check Auth Provider configuration

**If Status Code 403**:
- Authenticated successfully, but service account lacks permissions in Sage
- Check Sage 200 user permissions for the service account

### Phase 3: Test Invoice Export (Optional)

**If you have test invoice data in NewOrg:**

1. Navigate to a test RLCS Vendor Invoice record
2. Click **"Send to Sage"** button
3. Expected result: ✅ Invoice exports successfully, no HTTP 401 error

**Note**: Only test with non-production data in NewOrg. Do not export real invoices until full go-live.

### Phase 4: Verify Scheduled Jobs (If Configured)

**Check if scheduled jobs are configured in NewOrg:**

1. Navigate to **Setup** → Quick Find → **Scheduled Jobs**
2. Look for:
   - `SageRLCSSupplierScheduler`
   - `SageCustomerScheduler`

**If Scheduled Jobs Exist**:
- Monitor their execution after authentication
- Check **Setup → Apex Jobs** for completed/failed status
- Verify no HTTP 401 errors in job logs

**If Scheduled Jobs Don't Exist**:
- They will need to be scheduled separately (not part of this configuration)
- See Sage API integration deployment documentation for scheduling

---

## Monitoring & Maintenance

### Regular Monitoring

**Monitor these scheduled jobs** (if configured):

| Job Name | Frequency | Purpose | Alert If Failed |
|----------|-----------|---------|-----------------|
| SageRLCSSupplierScheduler | Daily/Hourly | Sync RLCS suppliers from Sage | ✅ Yes |
| SageCustomerScheduler | Daily/Hourly | Sync customers from Sage | ✅ Yes |

**Query to Check Recent Failures**:

```soql
SELECT Id, ApexClassName, Status, CompletedDate, ExtendedStatus, NumberOfErrors
FROM AsyncApexJob
WHERE ApexClass.Name IN (
    'SageRLCSSupplierQueueable',
    'SageCustomerQueueable',
    'ExportInvoiceSageBatch',
    'ExportVendorInvoiceSageBatch'
)
AND Status = 'Failed'
AND CreatedDate = LAST_N_DAYS:7
ORDER BY CreatedDate DESC
```

**Expected**: No recent failures with HTTP 401 errors

### Proactive Re-authentication Schedule

**OAuth Token Lifecycle**:
- Access Token: Expires ~1 hour (auto-refreshed by Salesforce)
- Refresh Token: Expires 60-90 days (requires manual re-authentication)

**Recommended Schedule**:
1. **Every 60 days**: Proactively re-authenticate SIA Named Credential
2. **After Sage password reset**: Re-authenticate immediately
3. **After Sage API changes**: Test connection and re-authenticate if needed

**Set Calendar Reminder**: Re-authenticate Named Credential every 60 days to prevent token expiration issues.

### Monitoring Best Practices

1. **Enable Email Alerts**
   - Navigate to **Setup** → **Email Administration** → **Deliverability**
   - Set up alerts for Apex job failures
   - Add admin emails to notification list

2. **Create Integration Health Dashboard**
   - Track Sage export success rate
   - Monitor recent Sage API errors
   - Display last successful sync timestamps

3. **Document Service Account**
   - Keep NewOrg Sage service account credentials documented securely
   - Record which service account is used for OAuth
   - Document Consumer Key/Secret for Auth Provider

---

## Troubleshooting Guide

### Issue: Authentication Fails - Cannot Log Into Sage

**Symptoms**:
- OAuth flow redirects to Sage login page
- Cannot log in with service account credentials
- Error: "Invalid username or password"

**Possible Causes**:
1. Incorrect Sage service account credentials for NewOrg
2. Service account locked or disabled in Sage 200
3. Service account password expired
4. Using OldOrg credentials instead of NewOrg credentials

**Resolution**:
1. Verify you're using **NewOrg-specific** Sage 200 credentials (not OldOrg)
2. Test credentials by logging into Sage 200 web UI directly
3. Check with Sage administrator if account is locked
4. Reset password if expired (then re-authenticate)

### Issue: Authentication Succeeds But API Returns 401

**Symptoms**:
- Named Credential shows "Authenticated"
- API test still returns HTTP 401

**Possible Causes**:
1. Auth Provider Consumer Secret is incorrect
2. OAuth token not properly stored after authentication
3. Named Credential configuration mismatch

**Resolution**:
1. Verify Auth Provider Consumer Secret is correct for NewOrg environment
2. Navigate to **Setup → Named Credentials → SIA → Edit**
3. Click **Re-authenticate** to refresh token
4. Test again with Anonymous Apex

### Issue: Authentication Succeeds But API Returns 403

**Symptoms**:
- Named Credential shows "Authenticated"
- API test returns HTTP 403 Forbidden

**Possible Causes**:
1. Service account authenticated but lacks API permissions in Sage 200
2. Subscription Key or Site ID incorrect for NewOrg
3. Company ID incorrect for NewOrg

**Resolution**:
1. Check Sage 200 user permissions for service account (must have API access)
2. Verify `Sage_API_Settings__c` Custom Setting values are correct for NewOrg
3. Confirm Subscription Key, Site ID, Company ID match NewOrg's Sage configuration
4. Contact Sage administrator to grant API permissions

### Issue: Consumer Secret Shows "Placeholder_Value"

**Symptoms**:
- Auth Provider Consumer Secret field shows "Placeholder_Value"
- Authentication fails

**Resolution**:
1. Retrieve actual Consumer Secret from Sage developer portal for NewOrg
2. Navigate to **Setup → Auth. Providers → Sage → Edit**
3. Update Consumer Secret field with actual value
4. Click **Save**
5. Re-authenticate Named Credential

### Issue: Scheduled Jobs Fail After Initial Success

**Symptoms**:
- Initial authentication works
- Jobs work for a few days
- Then start failing with HTTP 401

**Possible Causes**:
1. Refresh token expired (60-90 days)
2. Sage service account password changed
3. Sage API credentials rotated

**Resolution**:
1. Re-authenticate SIA Named Credential (same process as initial setup)
2. Set calendar reminder to re-authenticate every 60 days proactively
3. Implement monitoring to alert on authentication failures

---

## Configuration Checklist

Use this checklist when configuring NewOrg Sage API integration:

### Pre-Configuration
- [ ] Verify Sage API integration code deployed to NewOrg (SageAPIClient.cls, etc.)
- [ ] Verify Named Credential "SIA" exists in NewOrg
- [ ] Verify Auth Provider "Sage" exists in NewOrg
- [ ] Verify Auth Provider Consumer Secret is correct for NewOrg (not "Placeholder_Value")
- [ ] Verify Sage_API_Settings__c Custom Setting populated with NewOrg values
- [ ] Document NewOrg Sage service account credentials securely

### Authentication
- [ ] Navigate to Setup → Named Credentials → SIA
- [ ] Click Edit → Authenticate
- [ ] Log in with NewOrg Sage 200 service account
- [ ] Authorize application (scopes: openid profile email offline_access)
- [ ] Verify authentication status shows "Authenticated"
- [ ] Click Save

### Testing
- [ ] Run Anonymous Apex connection test (expect Status Code 200)
- [ ] Test invoice export with test data (if available)
- [ ] Verify no HTTP 401 or 403 errors
- [ ] Check Apex Jobs for any scheduled job failures

### Monitoring Setup
- [ ] Enable email alerts for Apex job failures
- [ ] Add admin emails to notification list
- [ ] Create Salesforce dashboard for integration health (optional)
- [ ] Set calendar reminder to re-authenticate every 60 days

### Documentation
- [ ] Document NewOrg Sage service account used for OAuth
- [ ] Record authentication date in this README
- [ ] Update NewOrg integration documentation with any issues encountered
- [ ] Share authentication process with other NewOrg admins

---

## Related Documentation

### Source Documentation

- [source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md](source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md) - Original OldOrg incident documentation (October 15-17, 2025)

### OldOrg State Documentation

- [OldOrg Sage API Integration State](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/sage-api-integration) - OldOrg configuration details and incident resolution history

### Referenced Components

**All components already deployed in NewOrg** (no deployment needed):

**Apex Classes**:
- `SageAPIClient.cls` - Core API client
- `ExportInvoiceSageBatch.cls` - Customer invoice export
- `ExportVendorInvoiceSageBatch.cls` - Vendor invoice export
- `SageRLCSSupplierQueueable.cls` - RLCS supplier sync
- `SageRLCSSupplierScheduler.cls` - RLCS supplier scheduler
- `SageCustomerQueueable.cls` - Customer sync
- `SageCustomerScheduler.cls` - Customer scheduler

**Configuration Components**:
- `namedCredentials/SIA.namedCredential-meta.xml` - Named Credential metadata
- `authproviders/Sage.authprovider-meta.xml` - Auth Provider metadata

**Custom Settings**:
- `Sage_API_Settings__c` - Endpoint prefixes, subscription keys, site IDs, company IDs

---

## Key Differences: OldOrg vs NewOrg

| Configuration Item | OldOrg | NewOrg | Notes |
|-------------------|---------|---------|-------|
| Sage Service Account | OldOrg-specific | **NewOrg-specific** | ⚠️ Must use different credentials |
| Subscription Key | `2234c7d0...` | **NewOrg-specific** | ⚠️ Likely different |
| Site ID | `b25b8b8a...` | **NewOrg-specific** | ⚠️ Likely different |
| Company ID (RLES) | `13` | **NewOrg-specific** | ⚠️ Likely different |
| Company ID (RLCS) | `9` | **NewOrg-specific** | ⚠️ Likely different |
| Consumer Key | Same | Same | ✅ Can be same |
| Consumer Secret | OldOrg-specific | **NewOrg-specific** | ⚠️ Likely different |

**⚠️ CRITICAL**: Do NOT copy Sage API credentials from OldOrg to NewOrg. Each organization must use its own Sage 200 environment configuration.

---

## Deployment Steps Summary

### ⚠️ Manual UI Steps Only (No CLI Deployment)

**Step 1: Pre-Verification** (⚠️ Manual UI)
- Verify Named Credential and Auth Provider exist in NewOrg
- Verify Auth Provider Consumer Secret is correct
- Verify Sage_API_Settings__c Custom Setting populated

**Step 2: Authenticate Named Credential** (⚠️ Manual UI)
- Setup → Named Credentials → SIA → Edit → Authenticate
- Log in with NewOrg Sage service account
- Authorize application
- Verify "Authenticated" status

**Step 3: Test Connection** (✅ CLI - Anonymous Apex)
```bash
sf apex run --file test-sage-connection.apex --target-org NewOrg
```
Expected: Status Code 200

**Step 4: Monitor** (⚠️ Manual UI)
- Setup → Apex Jobs → Monitor scheduled job success
- Enable email alerts for job failures
- Set calendar reminder to re-authenticate every 60 days

**Total Estimated Time**: 30-45 minutes (authentication + testing + monitoring setup)

---

## Risk Assessment

### Configuration Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Wrong Sage credentials used | Medium | High | Verify using NewOrg-specific credentials, test in Sage UI first |
| OAuth token expires after 60 days | High | High | Set calendar reminder, proactive re-authentication schedule |
| Service account lacks API permissions | Medium | High | Verify permissions in Sage 200 before authentication |
| Subscription Key incorrect | Low | High | Verify Custom Settings values match NewOrg Sage config |
| Consumer Secret incorrect | Low | High | Verify Auth Provider configuration before authentication |

### Rollback Procedure

**If Authentication Causes Issues**:

1. **Deactivate Named Credential** (temporarily disable integration):
   - Setup → Named Credentials → SIA → Edit
   - Change Callout Status to "Disabled"
   - Click Save
   - Result: All Sage API calls will fail (but no authentication attempts)

2. **Re-authenticate with Different Credentials**:
   - Setup → Named Credentials → SIA → Edit
   - Click Re-authenticate
   - Use different service account credentials
   - Verify authentication succeeds

3. **Update Auth Provider** (if Consumer Secret incorrect):
   - Setup → Auth. Providers → Sage → Edit
   - Update Consumer Secret with correct value
   - Click Save
   - Re-authenticate Named Credential

**Note**: There is no risk to existing data. This is purely OAuth authentication configuration - no data is modified.

---

**Configuration Guide Status**: ✅ Ready for NewOrg
**Last Updated**: October 23, 2025
**Documentation Type**: Configuration Guide (Manual UI Steps)
**Estimated Configuration Time**: 30-45 minutes

---

## Authentication Log (NewOrg)

**Track authentication history here:**

| Date | Authenticated By | Status | Notes |
|------|------------------|--------|-------|
| *TBD* | *NewOrg Admin* | *Pending* | Initial authentication pending NewOrg go-live |

**Next Re-authentication Due**: 60 days after initial authentication

---

