# FRED Integration Certificate Renewal - NewOrg Configuration Guide

⚠️ **SCENARIO TYPE: CONFIGURATION/CERTIFICATE RENEWAL - NOT A CODE DEPLOYMENT**

**Target Org**: NewOrg
**Priority**: 🔴 Critical (when needed)
**Estimated Time**: 2-3 hours (including testing)
**Type**: Configuration/Certificate Management
**Complexity**: Low-Medium

---

## Executive Summary

This guide provides instructions for renewing the FRED Integration client certificate in NewOrg when it approaches expiration. This is a configuration task, not a code deployment.

### When to Use This Guide

**Trigger Events**:
- Certificate expiration approaching (30 days before)
- Certificate expired and integration failing
- Infrastructure team provides new certificate
- Regular annual renewal cycle

**Prerequisites**:
- FRED Integration must exist in NewOrg
- Named Credential "DBS" must be configured
- Access to Infrastructure team for certificate generation
- Salesforce Admin permissions (Modify All Data or Certificate Management)

---

## Pre-Configuration Checklist

### Step 1: Verify FRED Integration Exists in NewOrg

**Check for Named Credential**:

```bash
# Query NewOrg for DBS Named Credential
sf data query -q "SELECT Id, DeveloperName, Endpoint, NamedCredentialType FROM NamedCredential WHERE DeveloperName = 'DBS'" -o NewOrg
```

**Expected Result**:
- Named Credential "DBS" exists
- Endpoint: https://fred-updater.recyclinglives-services.com (or similar)
- Type: Legacy

**If Not Found**:
- FRED Integration may not be deployed to NewOrg yet
- Check if this integration is needed in NewOrg
- Coordinate with Infrastructure team about NewOrg endpoints

---

### Step 2: Check Current Certificate Status

**Query Certificates**:

```bash
# Check for existing FRED certificates
sf data query -q "SELECT Id, DeveloperName, ExpirationDate, MasterLabel FROM Certificate WHERE DeveloperName LIKE '%FRED%' OR MasterLabel LIKE '%FRED%'" -o NewOrg
```

**Expected Results**:
- May have no certificates (first-time setup)
- May have expired certificate from OldOrg migration
- May have current certificate with upcoming expiration

---

### Step 3: Identify Integration Components

**Find Apex Classes Using DBS**:

```bash
# Search for Apex classes using Named Credential
sf data query -q "SELECT Id, Name FROM ApexClass WHERE Body LIKE '%callout:DBS%'" -o NewOrg --json
```

**Find Flows with HTTP Callouts**:

```bash
# Check for flows with external callouts
sf data query -q "SELECT Id, MasterLabel, ProcessType FROM FlowDefinition WHERE ActiveVersionId != null" -o NewOrg
# Manual review: Check flows for HTTP Callout actions referencing DBS
```

---

## Certificate Renewal Process for NewOrg

### Approach: Complete Certificate Package (RECOMMENDED ⭐)

This is the same approach used in OldOrg, proven to work effectively.

---

## Step-by-Step Instructions

### Step 1: Request Certificate from Infrastructure

**Email Template** (customize for NewOrg):

```
Subject: FRED Certificate Renewal - Request for NewOrg Environment

Hi [Infrastructure Engineer Name],

I need a new client certificate for our FRED integration in NewOrg (Recycling Lives Group).

WHAT I NEED:
• File Format: PKCS#12 (.p12 or .pfx file)
• Must contain: Certificate + Private Key
• Password protected (minimum 12 characters)
• Key size: 4096-bit RSA
• Validity: 1 year
• Purpose: Client Authentication for NGINX mutual TLS

ENVIRONMENT: NewOrg (Recycling Lives Group)
• Salesforce Org: NewOrg
• Integration: FRED Updater
• Endpoint: https://fred-updater.recyclinglives-services.com (or NewOrg-specific endpoint)
• Purpose: New deployment to NewOrg environment

DELIVERY:
• Send .p12 file via secure method (encrypted email/secure file share)
• Send password via SEPARATE channel (phone, encrypted message)

NGINX CONFIGURATION:
• Configure NGINX to accept this new certificate for NewOrg callouts
• Provide any NewOrg-specific endpoint URLs if different from OldOrg

Please confirm you can generate this and provide an estimated delivery date.

Thank you!
[Your Name]
[Your Email]
[Your Phone]
```

---

### Step 2: Verify Certificate Package

**Pre-Import Checks** (on Mac/Linux with OpenSSL):

```bash
# 1. Verify .p12 file integrity
openssl pkcs12 -in fred-updater-neworg-cert.p12 -noout -info
# Enter password when prompted

# 2. Extract and view certificate details
openssl pkcs12 -in fred-updater-neworg-cert.p12 -nokeys -clcerts | openssl x509 -noout -text

# 3. Verify key size (should show 4096-bit RSA)
openssl pkcs12 -in fred-updater-neworg-cert.p12 -nokeys -clcerts | openssl x509 -noout -text | grep "Public-Key"

# 4. Check validity dates
openssl pkcs12 -in fred-updater-neworg-cert.p12 -nokeys -clcerts | openssl x509 -noout -dates
```

**Expected Results**:
- Valid PKCS#12 format
- 4096-bit RSA key
- 1-year validity period
- Correct Subject/Issuer information

---

### Step 3: Import Certificate to NewOrg

**Salesforce UI Steps**:

1. **Navigate to Certificate Management**:
   - Login to NewOrg
   - Setup → Quick Find → "Certificate"
   - Click: **Certificate and Key Management**

2. **Import from Keystore**:
   - Click: **"Import from Keystore"** button
   - Click: **Choose File**
   - Select: `fred-updater-neworg-cert.p12`
   - Enter password (received via separate channel)
   - Click: **Next**

3. **Configure Certificate Settings**:
   - **Certificate Unique Name**: `FRED_Updater_NGINX_Client_Cert_NewOrg`
   - **Certificate Label**: `FRED Updater NGINX Client Certificate (NewOrg)`
   - **Description**: `Client certificate for FRED Updater mTLS authentication in NewOrg. Valid [start date] - [end date].`
   - **Exportable Private Key**: ⚠️ **UNCHECK THIS** (critical security setting)
   - Click: **Save**

4. **Record Certificate Details**:
   - **Certificate Salesforce ID**: [Copy from URL after save]
   - **Expiration Date**: [Note from certificate details]
   - **Imported Date**: [Today's date]
   - **Imported By**: [Your name]

---

### Step 4: Configure Named Credential

**If Named Credential Already Exists**:

1. Setup → Quick Find → "Named Credentials"
2. Find: **DBS** Named Credential
3. Click: **Edit** (dropdown arrow → Edit)
4. **Certificate**: Select `FRED_Updater_NGINX_Client_Cert_NewOrg`
5. **Identity Type**: Named Principal (verify existing setting)
6. **Authentication Protocol**: NamedUser (verify existing setting)
7. Click: **Save**

---

**If Named Credential Doesn't Exist** (First-Time Setup):

1. Setup → Quick Find → "Named Credentials"
2. Click: **New Legacy** (or **New Named Credential** depending on Salesforce version)
3. **Configuration**:
   - **Label**: `DBS`
   - **Name**: `DBS`
   - **URL**: `https://fred-updater.recyclinglives-services.com` (confirm with Infrastructure)
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: Certificate
   - **Certificate**: `FRED_Updater_NGINX_Client_Cert_NewOrg`
   - **Generate Authorization Header**: Checked (if available)
   - **Allow Merge Fields in HTTP Header**: Unchecked
   - **Allow Merge Fields in HTTP Body**: Unchecked
4. Click: **Save**

---

### Step 5: Test Integration

**Test 1: Anonymous Apex Test**

```apex
// Execute in Developer Console → Execute Anonymous (NewOrg)

HttpRequest req = new HttpRequest();
req.setEndpoint('callout:DBS/test'); // Adjust path based on FRED API
req.setMethod('GET');
req.setTimeout(10000);

try {
    Http http = new Http();
    HTTPResponse res = http.send(req);

    System.debug('=== FRED Integration Test ===');
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    System.debug('Headers: ' + res.getHeaderKeys());

    if(res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: Certificate authentication working in NewOrg');
        System.debug('Response Body: ' + res.getBody());
    } else if(res.getStatusCode() == 401 || res.getStatusCode() == 403) {
        System.debug('❌ ERROR: Authentication failed - Check certificate configuration');
    } else {
        System.debug('⚠️ WARNING: Unexpected status code - ' + res.getStatusCode());
        System.debug('Response: ' + res.getBody());
    }
} catch(System.CalloutException e) {
    System.debug('❌ CALLOUT ERROR: ' + e.getMessage());
    System.debug('Possible causes:');
    System.debug('- Certificate not trusted by NGINX');
    System.debug('- Named Credential misconfigured');
    System.debug('- Endpoint URL incorrect');
    System.debug('- Network/firewall issue');
} catch(Exception e) {
    System.debug('❌ UNEXPECTED ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
```

**Expected Results**:
- ✅ Status Code 200: Certificate working correctly
- ⚠️ Status Code 404: Certificate authenticated but endpoint path wrong (acceptable, fix path)
- ❌ Status Code 401/403: Authentication failed (troubleshoot certificate)
- ❌ CalloutException: Network or NGINX configuration issue

---

**Test 2: Verify Named Credential**

```bash
# Query Named Credential details
sf data query -q "SELECT Id, DeveloperName, Endpoint, CertificateId FROM NamedCredential WHERE DeveloperName = 'DBS'" -o NewOrg

# Verify certificate is attached
# CertificateId should match the imported certificate ID
```

---

**Test 3: Check Remote Site Settings**

```bash
# Verify remote site is configured
sf data query -q "SELECT Id, SiteName, EndpointUrl, IsActive FROM RemoteSiteSetting WHERE EndpointUrl LIKE '%fred-updater%'" -o NewOrg
```

**If Not Found**:
Create Remote Site Setting:
1. Setup → Quick Find → "Remote Site Settings"
2. Click: **New Remote Site**
3. **Remote Site Name**: `FRED_Updater`
4. **Remote Site URL**: `https://fred-updater.recyclinglives-services.com`
5. **Disable Protocol Security**: Unchecked
6. **Active**: Checked
7. Click: **Save**

---

### Step 6: Monitor Integration (First 24 Hours)

**Enable Debug Logs**:

1. Setup → Debug Logs
2. Click: **New** (Debug Log)
3. **Traced Entity Type**: User
4. **Traced Entity Name**: [Your username or integration user]
5. **Expiration Date**: Tomorrow
6. **Debug Level**: Custom → Set all to FINEST
7. Save

**Monitor for Errors**:

```bash
# Check recent Apex logs for errors
sf data query -q "SELECT Id, Application, DurationMilliseconds, Operation, Status, StartTime FROM ApexLog WHERE Operation LIKE '%Callout%' AND StartTime >= TODAY ORDER BY StartTime DESC LIMIT 20" -o NewOrg
```

**Check for**:
- SSL/TLS errors
- Certificate validation errors
- Authentication failures
- Timeout errors

---

## Troubleshooting

### Issue 1: "Authorization Required" or 401 Error

**Symptoms**:
- HTTP 401 Unauthorized
- HTTP 403 Forbidden
- SSL handshake failure

**Possible Causes**:
1. Certificate not installed on NGINX server
2. Certificate not trusted by NGINX
3. Named Credential not configured correctly
4. Wrong certificate selected in Named Credential

**Resolution Steps**:

1. **Verify Certificate in Salesforce**:
   ```bash
   sf data query -q "SELECT Id, DeveloperName, ExpirationDate FROM Certificate WHERE DeveloperName = 'FRED_Updater_NGINX_Client_Cert_NewOrg'" -o NewOrg
   ```

2. **Verify Named Credential**:
   - Setup → Named Credentials → DBS
   - Check Certificate field shows correct certificate
   - Re-save if needed

3. **Contact Infrastructure Team**:
   - Verify certificate is installed on NGINX server
   - Verify NGINX is configured to accept this certificate
   - Check NGINX logs for certificate validation errors

---

### Issue 2: "Endpoint Not Reachable" or Network Error

**Symptoms**:
- System.CalloutException: Unable to tunnel through proxy
- Read timed out
- Connection refused

**Possible Causes**:
1. Remote Site Setting not configured
2. Endpoint URL incorrect
3. Network/firewall blocking connection
4. NGINX server down

**Resolution Steps**:

1. **Check Remote Site Setting** (Step 5, Test 3 above)

2. **Verify Endpoint URL**:
   - Confirm with Infrastructure team
   - Check if NewOrg uses different endpoint than OldOrg

3. **Test Network Connectivity**:
   ```bash
   # From local machine (if access to server)
   curl -v https://fred-updater.recyclinglives-services.com
   ```

4. **Check Salesforce IP Ranges**:
   - Verify NGINX firewall allows Salesforce IP ranges
   - NewOrg may have different IP ranges than OldOrg

---

### Issue 3: Certificate Import Fails

**Symptoms**:
- "Invalid PKCS#12 file"
- "Incorrect password"
- "Unable to import certificate"

**Resolution Steps**:

1. **Verify Password**:
   - Confirm password with Infrastructure team
   - Check for hidden characters (copy-paste issues)

2. **Verify File Integrity**:
   ```bash
   # Test locally with OpenSSL
   openssl pkcs12 -in fred-updater-neworg-cert.p12 -noout -info
   # If this fails, file is corrupted
   ```

3. **Request New Certificate**:
   - If file corrupted, request Infrastructure team resend
   - Ensure secure transmission method

---

### Issue 4: Certificate Works in Test but Fails in Production

**Symptoms**:
- Test callouts succeed
- Production/scheduled jobs fail
- Intermittent failures

**Possible Causes**:
1. Different user context (test vs. production)
2. Named Credential using "Per User" identity (wrong setting)
3. NGINX server has different config for different source IPs

**Resolution Steps**:

1. **Verify Named Credential Identity Type**:
   - Should be: Named Principal (NOT Per User)
   - Setup → Named Credentials → DBS → Edit
   - Change to Named Principal if needed

2. **Test with Actual Integration User**:
   - Run test as the user who executes scheduled jobs
   - Check for user-specific permission issues

3. **Check Scheduled Job Logs**:
   ```bash
   sf data query -q "SELECT Id, ApexClassId, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClass.Name LIKE '%FRED%' AND CompletedDate >= LAST_N_DAYS:7 ORDER BY CompletedDate DESC" -o NewOrg
   ```

---

## Rollback Plan (NewOrg)

### If New Certificate Doesn't Work

**Scenario**: New certificate imported but integration fails

**Option A: Revert to Previous Certificate** (if one existed):

1. Setup → Named Credentials → DBS → Edit
2. Certificate: Select previous working certificate
3. Save
4. Test integration
5. Troubleshoot new certificate with Infrastructure team

---

**Option B: Remove Named Credential** (if first-time setup):

1. Setup → Named Credentials → DBS
2. Delete Named Credential
3. Coordinate with Infrastructure team on correct configuration
4. Restart configuration process

---

## Post-Configuration Checklist

After successful certificate renewal:

- [ ] Certificate imported to NewOrg
- [ ] Certificate ID recorded: _______________
- [ ] Expiration date recorded: _______________
- [ ] Named Credential updated to use new certificate
- [ ] Anonymous Apex test passed (Status Code 200 or expected)
- [ ] Remote Site Setting configured (if needed)
- [ ] Debug logs reviewed (no SSL/certificate errors)
- [ ] Integration components tested (scheduled jobs, flows, etc.)
- [ ] Infrastructure team confirmed NGINX configuration
- [ ] Documentation updated with certificate details
- [ ] Calendar reminder set for next renewal (30 days before expiration)

---

## Certificate Lifecycle Management

### Annual Renewal Cycle

**Timeline**:
- **30 days before expiration**: Begin renewal process
- **14 days before expiration**: New certificate should be deployed
- **7 days before expiration**: Fallback deadline
- **Expiration date**: Old certificate stops working

**Best Practices**:
1. Set calendar reminder 45 days before expiration
2. Coordinate with Infrastructure team early
3. Test in sandbox/dev environment first (if available)
4. Deploy during low-usage window
5. Monitor for 24-48 hours after deployment

---

### Certificate Inventory (NewOrg)

**Current Certificates**:

| Certificate Name | Purpose | Expiration | Status | Notes |
|-----------------|---------|------------|--------|-------|
| FRED_Updater_NGINX_Client_Cert_NewOrg | FRED Integration | [Date TBD] | Active | Document expiration after import |

**Update This Table** after each certificate import or renewal.

---

## Success Criteria

### Deployment Success ✅

- [ ] Certificate imported successfully to NewOrg
- [ ] Named Credential configured with new certificate
- [ ] Test callouts return expected responses (200 or valid error codes)
- [ ] No SSL/TLS authentication errors in logs
- [ ] Infrastructure team confirms NGINX accepts certificate
- [ ] Integration components (jobs, flows) executing successfully

---

### Functional Success ✅

- [ ] FRED Integration callouts succeeding
- [ ] Data synchronization working (if applicable)
- [ ] No business process disruptions
- [ ] Monitoring shows healthy integration status
- [ ] Users report no issues with FRED-dependent features

---

## Estimated Timeline (NewOrg)

**Total Time**: 2-3 hours (excluding Infrastructure team wait time)

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1 | Pre-configuration verification | 30 mins | Access to NewOrg |
| 2 | Request certificate from Infrastructure | 5 mins | Infrastructure contact |
| 3 | Wait for certificate generation | 1-3 days | Infrastructure team |
| 4 | Verify certificate package | 15 mins | Certificate received |
| 5 | Import to Salesforce | 15 mins | Certificate verified |
| 6 | Configure Named Credential | 15 mins | Certificate imported |
| 7 | Test integration | 30 mins | Named Credential configured |
| 8 | Monitor and validate | 45 mins | Tests passed |
| 9 | Documentation | 15 mins | All complete |

---

## Resources & References

### Source Documentation

- **OldOrg Certificate Status**: [fred-certificate-renewal/README.md](../../Salesforce_OldOrg_State/fred-certificate-renewal/README.md)
- **Original Guides**:
  - FRED_CERTIFICATE_RENEWAL_QUICK_START.md
  - FRED_INTEGRATION_NGINX_CERTIFICATE_RENEWAL_GUIDE.md

### Salesforce Documentation

- [Certificate and Key Management](https://help.salesforce.com/s/articleView?id=sf.security_keys_about.htm)
- [Named Credentials](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm)
- [External Services Authentication](https://help.salesforce.com/s/articleView?id=sf.nc_authentication_methods.htm)

### Contact Information

**Infrastructure Team**: [Contact details]
**Salesforce Admin Team**: [Contact details]

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Ready for Use When Needed
