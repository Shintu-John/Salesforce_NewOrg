# Sage API Integration - NewOrg Migration Plan

**Created**: October 22, 2025
**Target Org**: NewOrg (Recycling Lives Group)
**Status**: 📋 Ready for Deployment
**Migration Priority**: 🔴 High (Financial integration - invoice export)
**Estimated Time**: 4-6 hours (includes OAuth setup and testing)

---

## Related Documentation

**This migration plan consolidates the following documentation** (component-based analysis):

1. **[SAGE_API_HTTP_401_AUTHENTICATION_FIX.md](source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md)** - OAuth authentication issue fix (Oct 15, 2025)
2. **[RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md](source-docs/RLCS_VENDOR_INVOICE_SAGE_EXPORT_FIX.md)** - RLCS batch export SOQL fix (Oct 6, 2025)
3. **OldOrg State README**: [/tmp/Salesforce_OldOrg_State/sage-api-integration/README.md](../../../Salesforce_OldOrg_State/sage-api-integration/README.md) - Current verified state

**Component Analysis - Why Consolidated**:
- Both fixes affect the same Sage API integration system
- OAuth fix is infrastructure (affects all API calls)
- SOQL fix is implementation (specific to RLCS batch export)
- Must deploy as complete V2 system with both fixes

**Migration Strategy**: Deploy OldOrg V2 (includes both Oct 6 SOQL fix + Oct 15 OAuth configuration) to NewOrg.

**Complete Scenario Index**: See [DOCUMENTATION_MAPPING_AND_SCENARIOS.md](../../Documentation/DOCUMENTATION_MAPPING_AND_SCENARIOS.md) for all migration scenarios.

---

## Executive Summary

**What We're Migrating**: Complete Sage 200 accounting system integration with invoice export and account synchronization.

**Why High Priority**: Critical for financial operations - vendor/customer invoice export to Sage accounting system. RLCS month-end processing depends on this.

**Current NewOrg State**:
- ✅ All 7 Apex classes exist
- ⚠️ **CRITICAL**: Oct 6 RLCS fix may NOT be deployed (timestamp mismatch)
- ✅ Named Credential "SIA" exists but OAuth needs re-authentication
- ❌ NO scheduled jobs configured (must create manually)

**Migration Approach**: Deploy latest OldOrg code (V2) to ensure RLCS fix is present, then manually configure OAuth and scheduled jobs.

---

## Gap Analysis: OldOrg vs NewOrg

### Apex Classes Comparison

| Class | OldOrg Status | NewOrg Status | Gap? |
|-------|---------------|---------------|------|
| SageAPIClient | ✅ Sep 11, 2025 | ✅ Sep 18, 2025 | ⚠️ **Verify version** |
| ExportVendorInvoiceSageBatch | ✅ **Oct 6, 2025** (RLCS fix) | ⚠️ Oct 6, 15:34 | 🔴 **MISSING FIX** (45 min before OldOrg) |
| ExportVendorInvoiceSage | ✅ Jul 14, 2025 | ✅ Sep 18, 2025 | ✅ Likely OK |
| SageRLCSSupplierQueueable | ✅ Jul 14, 2025 | ✅ Sep 18, 2025 | ✅ Likely OK |
| SageCustomerQueueable | ✅ Jul 14, 2025 | ✅ Sep 18, 2025 | ✅ Likely OK |
| SageRLCSSupplierScheduler | ✅ Jul 14, 2025 | ✅ Sep 18, 2025 | ✅ Likely OK |
| SageCustomerScheduler | ✅ Jul 14, 2025 | ✅ Sep 18, 2025 | ✅ Likely OK |
| SageAPIClientTest | ✅ Sep 11, 2025 | Unknown | ⚠️ Verify exists |
| ExportVendorInvoiceSageTest | ✅ Jul 14, 2025 | Unknown | ⚠️ Verify exists |

**🚨 CRITICAL FINDING**:
`ExportVendorInvoiceSageBatch` in NewOrg was modified on **Oct 6 at 15:34:52 UTC**, which is **45 minutes BEFORE** the OldOrg fix (16:19:35 UTC). This strongly suggests the RLCS SOQL fix is **NOT in NewOrg**.

**Required Action**: Deploy ExportVendorInvoiceSageBatch from OldOrg to ensure RLCS fields are included in SOQL query.

### Named Credential Comparison

| Component | OldOrg | NewOrg | Gap? |
|-----------|--------|--------|------|
| SIA Named Credential | ✅ Exists + OAuth authenticated (Oct 15) | ✅ Exists | ⚠️ **OAuth needs re-auth** |
| Endpoint | api.columbus.sage.com | api.columbus.sage.com | ✅ Same |

**Required Action**: Manually re-authenticate OAuth in NewOrg (cannot be deployed).

### Scheduled Jobs Comparison

| Job Name | OldOrg | NewOrg | Gap? |
|----------|--------|--------|------|
| Sage RLCS Supplier Sync | ✅ 0 55 5 * * ? | ❌ Not configured | 🔴 **MISSING** |
| Sage Supplier Sync | ✅ 0 30 5 * * ? | ❌ Not configured | 🔴 **MISSING** |
| Sage RLCS Customer Sync | ✅ 0 45 5 * * ? | ❌ Not configured | 🔴 **MISSING** |
| Sage Customer Sync | ✅ 0 15 5 * * ? | ❌ Not configured | 🔴 **MISSING** |
| Sage Supplier Invoice Sync | ✅ 0 5 6 * * ? | ❌ Not configured | 🔴 **MISSING** |
| Sage Customer Invoice Sync | ✅ 0 15 6 * * ? | ❌ Not configured | 🔴 **MISSING** |

**Required Action**: Manually schedule all 6 jobs in NewOrg post-deployment.

---

## Migration Strategy

### Phase 1: Pre-Deployment Preparation (1 hour)

**Prerequisites**:
1. ✅ Sage admin access to generate OAuth credentials for NewOrg
2. ✅ Test data: 3 RLCS vendor invoices in NewOrg for testing
3. ✅ Backup current NewOrg classes (if needed for rollback)
4. ✅ System admin access to schedule jobs

**Risk Assessment**:
- **Risk Level**: MEDIUM
- **External Dependency**: Sage API (external system)
- **Manual Config Required**: OAuth + 6 scheduled jobs
- **Rollback Complexity**: MEDIUM (deactivate jobs, revert classes if needed)

**Verification Steps Before Deployment**:
```bash
# Verify RLCS fields exist in NewOrg
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Vendor_Invoice__c' AND QualifiedApiName IN ('RLCS_Nominal_Code__c', 'RLCS_Cost_Centre__c')" --target-org NewOrg --use-tooling-api

# Verify Named Credential exists
sf data query --query "SELECT DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = 'SIA'" --target-org NewOrg --use-tooling-api

# Backup current ExportVendorInvoiceSageBatch
sf project retrieve start --target-org NewOrg -m "ApexClass:ExportVendorInvoiceSageBatch" -d /tmp/sage-backup-neworg/
```

### Phase 2: Code Deployment (30 minutes)

**Deployment Order** (all classes together):

```bash
# Deploy all Sage API classes from OldOrg code to NewOrg
sf project deploy start --target-org NewOrg \
  -m "ApexClass:SageAPIClient" \
  -m "ApexClass:SageAPIClientTest" \
  -m "ApexClass:ExportVendorInvoiceSage" \
  -m "ApexClass:ExportVendorInvoiceSageBatch" \
  -m "ApexClass:ExportVendorInvoiceSageTest" \
  -m "ApexClass:SageRLCSSupplierQueueable" \
  -m "ApexClass:SageCustomerQueueable" \
  -m "ApexClass:SageRLCSSupplierScheduler" \
  -m "ApexClass:SageCustomerScheduler" \
  --test-level RunSpecifiedTests \
  --tests SageAPIClientTest \
  --tests ExportVendorInvoiceSageTest
```

**Expected Result**:
- ✅ 9 classes deployed successfully
- ✅ 2 test classes pass (coverage maintained)
- ✅ ExportVendorInvoiceSageBatch now includes RLCS SOQL fix

**If Deployment Fails**:
1. Check test failures in deployment log
2. Verify RLCS custom fields exist
3. Check for any org-specific customizations
4. Review dependencies (other classes/objects)

### Phase 3: OAuth Configuration (2-3 hours)

**⚠️ CRITICAL**: This CANNOT be automated and requires Sage admin access.

**Step 1: Prepare Sage OAuth Provider** (if not already configured):

1. In NewOrg Setup → Auth. Providers → New
2. Provider Type: Salesforce
3. Name: SageOAuth (or similar)
4. Consumer Key: [From Sage admin portal]
5. Consumer Secret: [From Sage admin portal]
6. Authorize Endpoint URL: [From Sage documentation]
7. Token Endpoint URL: [From Sage documentation]
8. Save

**Step 2: Configure Named Credential**:

1. Setup → Named Credentials → Edit "SIA"
2. Select Auth Provider created in Step 1
3. Click "Save"
4. Click "Authenticate" (redirects to Sage login)
5. Login with Sage credentials
6. Authorize Salesforce to access Sage API
7. Redirected back to Salesforce - OAuth token stored

**Step 3: Verify OAuth Configuration**:

```apex
// Run in Anonymous Apex
SageAPIClient client = new SageAPIClient();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SIA/customers');
req.setMethod('GET');
HttpResponse res = client.sendRequest(req);
System.debug('Status: ' + res.getStatusCode()); // Should be 200, not 401
```

**Expected Result**: HTTP 200 response (not 401 Unauthorized)

**If OAuth Fails**:
- Check Sage API credentials are valid for NewOrg environment
- Verify Auth Provider configuration
- Check Sage admin portal for any IP restrictions
- Review Salesforce logs for OAuth errors

### Phase 4: Schedule Jobs (30 minutes)

**⚠️ CRITICAL**: Scheduled jobs do NOT deploy. Must be manually created.

**Job Configuration** (in order):

1. **Sage Customer Sync** (earliest - 5:15 AM):
   ```apex
   System.schedule('Sage Customer Sync at 5:15 AM', '0 15 5 * * ?', new SageCustomerScheduler());
   ```

2. **Sage Supplier Sync** (5:30 AM):
   ```apex
   System.schedule('Sage Supplier Sync at 5:30 AM', '0 30 5 * * ?', new SageRLCSSupplierScheduler()); // Note: Uses RLCS scheduler for supplier
   ```

3. **Sage RLCS Customer Sync** (5:45 AM):
   ```apex
   // TBD: Verify if this scheduler exists or uses SageCustomerScheduler
   ```

4. **Sage RLCS Supplier Sync** (5:55 AM):
   ```apex
   System.schedule('Sage RLCS Supplier Sync at 5:55 AM', '0 55 5 * * ?', new SageRLCSSupplierScheduler());
   ```

5. **Sage Supplier Invoice Sync** (6:05 AM):
   ```apex
   // TBD: Verify which scheduler handles supplier invoice sync
   ```

6. **Sage Customer Invoice Sync** (6:15 AM):
   ```apex
   System.schedule('Sage Customer Invoice Sync at 6:15 AM', '0 15 6 * * ?', new SageCustomerScheduler()); // May use customer scheduler
   ```

**Verify Jobs Scheduled**:
```bash
sf data query --query "SELECT Id, CronJobDetail.Name, State, NextFireTime, CronExpression FROM CronTrigger WHERE CronJobDetail.Name LIKE '%Sage%'" --target-org NewOrg
```

**Expected Result**: 6 jobs in WAITING state with correct next fire times

### Phase 5: Post-Deployment Testing (1-2 hours)

**Test Case 1: RLCS Batch Export (>5 Invoices)** 🔴 CRITICAL

**Setup**:
1. Create 6+ RLCS vendor invoices in NewOrg (or use existing)
2. Ensure RLCS_Nominal_Code__c and RLCS_Cost_Centre__c are populated
3. Set status to "Released For Payment"

**Execute**:
1. Select all 6+ invoices
2. Click "Export to Sage" button
3. Batch job should execute

**Expected Result**:
- ✅ Batch completes successfully (no SOQL errors)
- ✅ All invoices exported to Sage
- ✅ CSV button becomes visible
- ❌ If fails with SOQL error → RLCS fix NOT deployed (rollback needed)

**Test Case 2: OAuth Token Validity**

**Execute**:
```apex
// Run in Anonymous Apex
SageAPIClient client = new SageAPIClient();
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:SIA/customers');
req.setMethod('GET');
HttpResponse res = client.sendRequest(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
```

**Expected Result**:
- ✅ HTTP 200 response
- ✅ JSON response with customer data
- ❌ If 401 → OAuth not configured correctly

**Test Case 3: Non-Batch Export (≤5 Invoices)**

**Setup**:
1. Select 3-5 RLCS vendor invoices
2. Ensure fields populated

**Execute**:
1. Click "Export to Sage"
2. Non-batch export executes

**Expected Result**:
- ✅ Invoices export successfully
- ✅ No errors in debug logs

**Test Case 4: Scheduled Job Execution**

**Setup**:
1. Wait for next scheduled fire time OR manually execute:
```apex
System.enqueueJob(new SageRLCSSupplierQueueable());
```

**Expected Result**:
- ✅ Queueable job completes
- ✅ No errors in logs
- ✅ Suppliers/customers synced from Sage

### Phase 6: Monitoring (1 week)

**Daily Checks** (first 3 days):
1. Check scheduled job execution logs
2. Monitor for any OAuth 401 errors
3. Verify invoice exports working
4. Check account sync working

**Weekly Review** (after 1 week):
1. Review all scheduled job success rates
2. Check for any recurring errors
3. Validate data accuracy (invoices in Sage match Salesforce)
4. Get user feedback on export functionality

---

## Rollback Plan

### If Deployment Fails

**Option 1: Revert Classes** (if deployment completes but causes issues):
```bash
# Restore backup from Phase 1
sf project deploy start --target-org NewOrg -d /tmp/sage-backup-neworg/
```

**Option 2: Deactivate Scheduled Jobs**:
```apex
// Get all Sage job IDs
List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE '%Sage%'];
for (CronTrigger job : jobs) {
    System.abortJob(job.Id);
}
```

**Option 3: Deactivate OAuth** (if causing issues):
1. Setup → Named Credentials → Edit "SIA"
2. Change endpoint to invalid URL (temporarily disable)
3. Or delete OAuth token

### If RLCS Export Still Fails

**Diagnosis**:
1. Check ExportVendorInvoiceSageBatch.cls line 18-20 SOQL query
2. Verify RLCS_Nominal_Code__c and RLCS_Cost_Centre__c in query
3. If missing → Deployment did not include Oct 6 fix

**Resolution**:
1. Manually edit ExportVendorInvoiceSageBatch.cls in NewOrg
2. Add RLCS fields to SOQL query
3. Re-deploy single class

---

## Success Criteria

**Deployment Success**:
- ✅ All 9 Apex classes deployed to NewOrg
- ✅ Test classes pass (SageAPIClientTest, ExportVendorInvoiceSageTest)
- ✅ ExportVendorInvoiceSageBatch includes RLCS SOQL fix

**Configuration Success**:
- ✅ Named Credential "SIA" OAuth authenticated
- ✅ Test API call returns HTTP 200 (not 401)
- ✅ All 6 scheduled jobs created and in WAITING state

**Functional Success**:
- ✅ RLCS batch export (>5 invoices) works without SOQL errors
- ✅ Non-batch export (≤5 invoices) works
- ✅ OAuth token valid (no 401 errors)
- ✅ Scheduled jobs execute successfully
- ✅ Accounts sync from Sage to Salesforce
- ✅ Invoices export from Salesforce to Sage

**User Acceptance**:
- ✅ Finance team can export RLCS vendor invoices
- ✅ Month-end processing not blocked
- ✅ No user-reported issues for 1 week

---

## Post-Migration Maintenance

### OAuth Token Monitoring

**Expected Lifespan**: Months (exact duration unknown)
**Warning Signs**: HTTP 401 errors, admin email alerts
**Resolution**: Manual re-authentication (same as Oct 15 fix)
**Documentation**: See source-docs/SAGE_API_HTTP_401_AUTHENTICATION_FIX.md

### Scheduled Job Monitoring

**Frequency**: Daily execution (5:15 AM - 6:15 AM)
**Monitor**: Setup → Apex Jobs → Scheduled Jobs
**Success Rate**: Should be >95%
**Alert**: Set up email alerts for failed scheduled jobs

### Code Updates

**If Sage API Changes**:
- Update SageAPIClient.cls endpoints
- Test in sandbox first
- Deploy to NewOrg with full test suite

**If New Fields Added**:
- Add to ExportVendorInvoiceSageBatch SOQL query
- Add to non-batch export query
- Test both export modes

---

## Known Issues and Limitations

### Issue 1: OAuth Tokens Can Expire

**Impact**: All Sage integrations fail simultaneously
**Frequency**: Rare (months between)
**Detection**: HTTP 401 errors, admin alerts
**Resolution**: Manual re-authentication
**Mitigation**: Document OAuth setup process

### Issue 2: Scheduled Jobs Not Deployable

**Impact**: Must manually configure in every org
**Workaround**: Document exact CRON expressions
**Requirement**: System admin access
**Time**: 30 minutes to schedule 6 jobs

### Issue 3: Batch Export Threshold Hard-Coded

**Current**: 5-invoice threshold in ExportVendorInvoiceSage.cls
**Impact**: Cannot adjust without code change
**Recommendation**: Consider making configurable via Custom Setting

### Issue 4: Named Credential Cannot Be Deployed

**Impact**: OAuth must be manually configured
**Requirement**: Sage admin credentials
**Time**: 1-2 hours for OAuth setup
**Documentation**: Detailed in Phase 3

---

## Risk Assessment

### Overall Risk: MEDIUM

**Complexity Factors**:
- 9 Apex classes to deploy
- External API dependency (Sage)
- OAuth authentication (org-specific, manual)
- 6 scheduled jobs (manual configuration)
- Critical RLCS fix verification needed
- Financial integration (high business impact)

**Mitigation Strategies**:
- Deploy to sandbox first
- Have Sage admin available during OAuth setup
- Test RLCS batch export thoroughly
- Monitor scheduled jobs for 1 week
- Have rollback plan ready
- Schedule deployment during maintenance window

**Success Probability**: HIGH
- Code is stable and tested in OldOrg
- V2 fixes validated in production
- Clear deployment steps documented
- Rollback procedures defined

---

## Estimated Timeline

**Total Time**: 4-6 hours (full deployment + configuration + testing)

**Breakdown**:
- Pre-deployment prep: 1 hour
- Code deployment: 30 minutes
- OAuth configuration: 2-3 hours (depends on Sage admin availability)
- Schedule jobs: 30 minutes
- Testing: 1-2 hours
- Initial monitoring: Ongoing (first week)

**Recommended Schedule**:
- **Day 1**: Pre-deployment prep + code deployment + OAuth setup (4 hours)
- **Day 2**: Schedule jobs + comprehensive testing (2 hours)
- **Days 3-7**: Monitoring and validation (15 min/day)

---

## Dependencies and Prerequisites

### External Systems

**Sage 200 API**:
- Admin access to Sage portal (to generate OAuth credentials)
- API endpoint accessible from Salesforce
- Test environment (optional but recommended)

### Salesforce Requirements

**NewOrg**:
- System Administrator profile
- Deploy metadata permission
- Schedule job permission
- Custom fields: RLCS_Nominal_Code__c, RLCS_Cost_Centre__c on Vendor_Invoice__c

**Test Data**:
- 6+ RLCS vendor invoices for batch export testing
- 3-5 RLCS vendor invoices for non-batch testing
- Sage customer/supplier test accounts

### Team Requirements

**Roles Needed**:
- Salesforce Admin (deployment, job scheduling)
- Sage Admin (OAuth credential generation)
- Finance Team Member (UAT - invoice export testing)
- Developer (if issues arise during deployment)

---

## Contact Information

**Deployment Lead**: [To be assigned]
**Sage Admin**: [To be confirmed]
**Finance Stakeholder**: Chantal Cook (reported Oct 6 issue)
**Escalation**: [To be defined]

---

## References

**OldOrg State Documentation**: `/tmp/Salesforce_OldOrg_State/sage-api-integration/README.md`
**Source Issue Docs**: `source-docs/` folder
**Workflow Rules**: `/home/john/Projects/Salesforce/Documentation/CLAUDE_WORKFLOW_RULES.md`
**Deploy ID (OldOrg Oct 6 fix)**: 0AfSj000000yACbKAM

---

**END OF MIGRATION PLAN**
