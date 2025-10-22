# SI-13024 Vendor Invoice Rollup Issue - NewOrg Prevention Guide

⚠️ **SCENARIO TYPE: ANALYSIS/PREVENTION - NOT A CODE DEPLOYMENT**

**Target Org**: NewOrg
**Priority**: 🟢 Low (Monitoring/Prevention)
**Estimated Time**: 1 hour (setup monitoring)
**Type**: Analysis & Prevention Documentation
**Complexity**: Low

---

## Executive Summary

This guide documents a one-time rollup bug that occurred in OldOrg (SI-13024 invoice) and provides monitoring/prevention strategies for NewOrg. No code deployment is required - only monitoring setup and documented procedures.

### What Happened in OldOrg

**Issue**: One vendor invoice (SI-13024) had rollup field `Job_Charge_Total__c` incorrectly set to £0 instead of £4,980, even though all charges were correctly allocated.

**Cause**: User edited invoice, triggering Rollup_RLCS_ChargeHandler, which reset the field to £0 and failed to recalculate.

**Resolution**: Manual Apex script to recalculate the total.

**Scope**: Only 1 invoice affected (isolated incident)

---

## No Code Deployment Required

**What This Guide Provides**:
- Monitoring query to detect similar issues
- Manual fix procedure (if needed)
- Prevention recommendations
- User training guidance

**What This Does NOT Include**:
- Apex code changes
- Trigger modifications
- Flow deployments

---

## Monitoring Setup for NewOrg

### Step 1: Create Monitoring Report

**Report Name**: "Vendor Invoices - Rollup Discrepancy Alert"

**Report Type**: Vendor Invoices with Related RLCS Charges

**Filters**:
- Job_Charge_Total__c equals 0
- Has RLCS Charges (count > 0)

**Columns**:
- Invoice Name
- Job_Charge_Total__c
- Total_Invoice_Difference__c
- Number of RLCS Charges
- Last Modified Date
- Last Modified By

**Schedule**: Run weekly, email to Finance team

---

### Step 2: Create Validation Query

**For Ad-Hoc Checking**:

```sql
-- Find invoices with charges but zero rollup total
SELECT Id, Name, Job_Charge_Total__c, Total_Invoice_Difference__c,
       (SELECT COUNT() FROM RLCS_Charges__r) AS ChargeCount,
       LastModifiedDate, LastModifiedBy.Name
FROM Vendor_Invoice__c
WHERE Job_Charge_Total__c = 0
  AND Id IN (SELECT Vendor_Invoice__c FROM RLCS_Charge__c WHERE Vendor_Invoice__c != null)
ORDER BY LastModifiedDate DESC
```

**Run This**:
- Weekly as part of invoice reconciliation
- After bulk invoice updates
- If users report "invoice won't release" issues

---

### Step 3: Set Up Process Builder Alert (Optional)

**Trigger**: Vendor_Invoice__c updated

**Criteria**:
- Job_Charge_Total__c = 0
- AND Total_Invoice_Difference__c > 0
- AND record has related RLCS Charges

**Action**: Email alert to Finance Manager

**Email Template**:
```
Subject: Vendor Invoice Rollup Alert - {!Vendor_Invoice__c.Name}

Invoice {!Vendor_Invoice__c.Name} may have a rollup calculation issue:
- Job Charge Total: £0
- Invoice Difference: {!Vendor_Invoice__c.Total_Invoice_Difference__c}

Please review and run validation query if needed.
```

---

## Manual Fix Procedure

### If Rollup Issue is Detected

**Step 1: Verify the Issue**

```sql
-- Check specific invoice
SELECT Id, Name, Job_Charge_Total__c, Total_Net__c, Total_Invoice_Difference__c
FROM Vendor_Invoice__c
WHERE Name = '[INVOICE-NAME]'

-- Check linked charges
SELECT Id, Name, Cost__c, Vendor_Invoice__r.Name
FROM RLCS_Charge__c
WHERE Vendor_Invoice__r.Name = '[INVOICE-NAME]'
```

**Expected**:
- Job_Charge_Total__c = 0
- Multiple charges linked with actual costs
- Total_Invoice_Difference__c = Total_Net__c (wrong)

---

**Step 2: Calculate Correct Total**

```apex
// Execute in Developer Console → Execute Anonymous

String invoiceName = 'SI-XXXXX'; // Replace with actual invoice name

// Calculate actual total from charges
List<RLCS_Charge__c> charges = [
    SELECT Cost__c
    FROM RLCS_Charge__c
    WHERE Vendor_Invoice__r.Name = :invoiceName
];

Decimal actualTotal = 0;
for (RLCS_Charge__c charge : charges) {
    actualTotal += (charge.Cost__c != null ? charge.Cost__c : 0);
}

System.debug('Invoice: ' + invoiceName);
System.debug('Number of charges: ' + charges.size());
System.debug('Calculated total: £' + actualTotal);

// Update the invoice
Vendor_Invoice__c invoice = [
    SELECT Id, Job_Charge_Total__c
    FROM Vendor_Invoice__c
    WHERE Name = :invoiceName
];

System.debug('Current Job_Charge_Total__c: £' + invoice.Job_Charge_Total__c);

invoice.Job_Charge_Total__c = actualTotal;
update invoice;

System.debug('✅ Updated Job_Charge_Total__c to: £' + actualTotal);

// Verify
Vendor_Invoice__c updated = [
    SELECT Id, Job_Charge_Total__c, Total_Invoice_Difference__c
    FROM Vendor_Invoice__c
    WHERE Name = :invoiceName
];

System.debug('New Job_Charge_Total__c: £' + updated.Job_Charge_Total__c);
System.debug('New Total_Invoice_Difference__c: £' + updated.Total_Invoice_Difference__c);
```

---

**Step 3: Verify Fix**

```sql
-- Confirm fields are correct
SELECT Id, Name, Job_Charge_Total__c, Total_Net__c, Total_Invoice_Difference__c
FROM Vendor_Invoice__c
WHERE Name = '[INVOICE-NAME]'
```

**Expected After Fix**:
- Job_Charge_Total__c = (sum of all charge costs)
- Total_Invoice_Difference__c = 0 (or correct difference)

---

## Prevention Recommendations

### 1. Review Rollup Trigger Code

**File to Review**: Rollup_RLCS_ChargeHandler.cls

**Look For**:
- Lines that reset fields to 0
- Queries that might return empty results under certain conditions
- Missing error handling when calculations fail

**Recommendation**: Add logging and safeguards:

```apex
// BEFORE (risky)
parentToUpdate.Job_Charge_Total__c = 0;

// AFTER (with safeguard)
Integer existingChargeCount = [
    SELECT COUNT()
    FROM RLCS_Charge__c
    WHERE Vendor_Invoice__c = :parentId
];

if (existingChargeCount > 0) {
    System.debug('Warning: Resetting Job_Charge_Total__c to 0 for invoice with ' + existingChargeCount + ' charges');
}

parentToUpdate.Job_Charge_Total__c = 0;
```

---

### 2. Consider Declarative Rollup Summaries

**Alternative to Custom Trigger**: Use DLRS (Declarative Lookup Rollup Summaries)

**Benefits**:
- More reliable than custom code
- Automatic recalculation
- Less prone to edge case bugs
- Easier to maintain

**Setup**:
1. Install DLRS managed package
2. Configure rollup: RLCS_Charge__c.Cost__c SUM → Vendor_Invoice__c.Job_Charge_Total__c
3. Test thoroughly before deactivating custom trigger

---

### 3. User Training

**Train Finance Users**:

**What to Watch For**:
- Invoice shows charges but Total_Invoice_Difference__c equals Total_Net__c
- Job_Charge_Total__c shows £0 but charges are visible

**What to Do**:
1. Don't panic - data is not lost
2. Run validation query or check report
3. Contact Salesforce admin to run fix script
4. Log the incident for pattern tracking

**What NOT to Do**:
- Don't manually edit Job_Charge_Total__c (read-only field)
- Don't unlink and relink charges (won't trigger recalculation)

---

## Testing in NewOrg

### Test Scenario 1: Normal Rollup

**Steps**:
1. Create vendor invoice
2. Allocate RLCS charges using standard flow
3. Verify Job_Charge_Total__c updates correctly

**Expected**: Rollup works as designed ✅

---

### Test Scenario 2: Invoice Amount Correction

**Steps**:
1. Create vendor invoice with charges allocated
2. Note the Job_Charge_Total__c value
3. Edit Total_Net__c (change invoice amount)
4. Save
5. Check if Job_Charge_Total__c changed

**Expected**: Job_Charge_Total__c should NOT change (correct behavior)

**If It Changes to £0**: Rollup trigger bug exists - apply monitoring immediately

---

### Test Scenario 3: Bulk Updates

**Steps**:
1. Select 10 vendor invoices with charges
2. Perform bulk update (e.g., change Status field)
3. Verify Job_Charge_Total__c remains correct for all

**Expected**: All rollups remain accurate ✅

---

## Success Criteria

### Monitoring Setup Complete ✅

- [ ] Weekly validation report created
- [ ] Report scheduled and emailing Finance team
- [ ] Validation query documented and accessible
- [ ] (Optional) Process Builder alert configured
- [ ] Finance team trained on what to watch for

---

### Prevention Measures in Place ✅

- [ ] Rollup trigger code reviewed for safeguards
- [ ] Error logging added (if needed)
- [ ] DLRS considered as alternative (document decision)
- [ ] Manual fix procedure documented and tested
- [ ] User training materials created

---

### Ongoing Maintenance ✅

- [ ] Run validation query weekly
- [ ] Review report results weekly
- [ ] Document any incidents
- [ ] Track patterns (if multiple incidents occur)

---

## Estimated Timeline

**Total Time**: 1 hour

| Phase | Task | Time |
|-------|------|------|
| 1 | Create validation report | 20 mins |
| 2 | Test manual fix procedure | 15 mins |
| 3 | Document user training | 15 mins |
| 4 | (Optional) Set up Process Builder alert | 30 mins |

---

## Resources & References

### Source Documentation

- **OldOrg Analysis**: [si13024-rollup-issue/README.md](../../Salesforce_OldOrg_State/si13024-rollup-issue/README.md)
- **Complete Analysis**: [SI13024_ROLLUP_ISSUE_COMPLETE_RESOLUTION.md](../../Salesforce/Documentation/SI13024_ROLLUP_ISSUE_COMPLETE_RESOLUTION.md)

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Ready for Implementation
**Type**: Monitoring & Prevention Guide
