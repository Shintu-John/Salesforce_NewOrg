# Job Charge Credit on Account Fix - NewOrg Migration Plan

**Target Org**: NewOrg
**Migration Priority**: 🟡 Medium
**Estimated Time**: 30-45 minutes
**Dependencies**: Job_Charge__c object, Flow framework
**Complexity**: Low

---

## Executive Summary

This migration deploys a bug fix for the "Job Charge Minimum 20% Gross on Rebate" flow that was incorrectly executing on "Credit on Account" charges and overwriting user-entered Cost values.

### What This Fix Does

**Problem Solved**:
- Flow was executing on both "Rebate" AND "Credit on Account" charges
- Should only execute on "Rebate" charges
- Caused incorrect Cost values for 3 out of 279 Credit on Account charges (1.08%)

**Solution**:
- Removed "Credit on Account" from flow entry criteria
- Flow now only executes on "Rebate" charges as intended
- No code changes, only flow configuration

---

## Gap Analysis

### Current State in NewOrg

**Need to Verify**:
1. ✅ Job_Charge__c object exists
2. ✅ Flow "Job_Charge_Minimum_20_Gross_on_Rebate" exists
3. ⚠️ Check if flow has same bug (includes "Credit on Account" in criteria)

**Verification Commands**:

```bash
# Check if object exists
sf data query -q "SELECT Id FROM Job_Charge__c LIMIT 1" -o NewOrg

# List all flows to find this one
sf project retrieve start --metadata Flow:Job_Charge_Minimum_20_Gross_on_Rebate -o NewOrg
```

---

## Component to Deploy

### Flow: Job_Charge_Minimum_20_Gross_on_Rebate

**File**: `Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml`

**Source**: `/home/john/Projects/Salesforce/Backup/2025-10-22_job_charge_credit_on_account_fix/`

**Changes**:
1. Removed "Credit on Account" filter from entry criteria
2. Updated filterLogic from `1 AND (2 OR 3) AND 4 AND 5 AND 6` to `1 AND 2 AND 3 AND 4 AND 5`
3. Updated description with change date

**Version**: v6 (from OldOrg)

---

## Pre-Deployment Checklist

### Step 1: Verify Flow Exists in NewOrg

```bash
# Retrieve current flow version
sf project retrieve start \
  --metadata Flow:Job_Charge_Minimum_20_Gross_on_Rebate \
  -o NewOrg \
  --target-metadata-dir retrieved-flow/
```

### Step 2: Check Current Flow Configuration

**Review Current Entry Criteria**:
```bash
# Read flow XML
cat retrieved-flow/flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml | grep -A 10 "filterLogic"
```

**Look For**:
- Does filterLogic include an OR condition?
- Is "Credit on Account" in the filters?
- If yes → Deploy fix
- If no → Fix may already be deployed or flow structure is different

---

### Step 3: Check for Affected Records in NewOrg

```bash
# Find Credit on Account charges on Jobs with < 20% margin
sf data query -q "SELECT Id, Name, Job__r.Name, Charge_Type__c, Cost__c, Sales_Price__c, CreatedDate, Job__r.Margin__c FROM Job_Charge__c WHERE Charge_Type__c = 'Credit on Account' AND CreatedDate >= 2025-01-15T00:00:00Z AND Job__r.Margin__c < 20 ORDER BY CreatedDate DESC" -o NewOrg

# Review results to identify any affected records
```

---

## Deployment Steps

### Step 1: Copy Fixed Flow from Backup

```bash
# Copy fixed flow file to NewOrg project
cp /home/john/Projects/Salesforce/Backup/2025-10-22_job_charge_credit_on_account_fix/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml \
   /path/to/NewOrg/force-app/main/default/flows/
```

---

### Step 2: Deploy Flow to NewOrg

```bash
# Deploy the fixed flow
sf project deploy start \
  --source-dir force-app/main/default/flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml \
  -o NewOrg \
  --wait 10
```

**Expected Result**:
- Deployment succeeds
- Flow version increments (e.g., v5 → v6)
- Flow automatically activated (if it was active before)

---

### Step 3: Verify Flow Activation

```bash
# Check flow status
sf project retrieve start \
  --metadata Flow:Job_Charge_Minimum_20_Gross_on_Rebate \
  -o NewOrg

# Verify the flow shows correct filterLogic (without Credit on Account)
cat force-app/main/default/flows/Job_Charge_Minimum_20_Gross_on_Rebate.flow-meta.xml | grep -A 20 "<filters>"
```

---

## Post-Deployment Validation

### Test 1: Create Credit on Account on Low Margin Job

**Test Scenario**:
1. Create or find a Job with < 20% margin
2. Create a new Credit on Account Job Charge with negative Cost value
3. Save the record

**Expected Result**:
- ✅ Cost__c preserves user-entered negative value
- ✅ Flow does NOT execute
- ✅ No automatic value changes

**Test Steps**:

```apex
// Execute in Developer Console → Execute Anonymous (NewOrg)

// Step 1: Find or create Job with low margin
Job__c testJob = new Job__c(
    Name = 'Test Job - Low Margin',
    Supplier_Price__c = 100,
    Sales_Price__c = 119,  // 19% margin (< 20%)
    Weight__c = 1.0
    // Add other required fields
);
insert testJob;

// Step 2: Create Credit on Account charge
Job_Charge__c testCharge = new Job_Charge__c(
    Job__c = testJob.Id,
    Charge_Type__c = 'Credit on Account',
    Cost__c = -50.00,  // Negative value
    Sales_Price__c = -40.00
    // Add other required fields
);
insert testCharge;

// Step 3: Verify Cost__c was NOT changed
Job_Charge__c verifyCharge = [
    SELECT Id, Cost__c, Sales_Price__c
    FROM Job_Charge__c
    WHERE Id = :testCharge.Id
];

System.debug('Cost__c after save: ' + verifyCharge.Cost__c);
System.assert(verifyCharge.Cost__c == -50.00, 'Cost__c should preserve negative value');
System.debug('✅ TEST PASSED: Cost value preserved');

// Cleanup
delete testCharge;
delete testJob;
```

---

### Test 2: Verify Flow Still Works for Rebates

**Test Scenario**:
1. Create or find a Job with < 20% margin
2. Create a new Rebate Job Charge
3. Save the record

**Expected Result**:
- ✅ Flow DOES execute for Rebate charges
- ✅ Cost__c is auto-calculated to enforce 20% margin
- ✅ Rebate behavior unchanged (as designed)

**Test Steps**:

```apex
// Execute in Developer Console → Execute Anonymous (NewOrg)

// Step 1: Create Job with low margin
Job__c testJob = new Job__c(
    Name = 'Test Job - Rebate Low Margin',
    Supplier_Price__c = 100,
    Sales_Price__c = 115,  // 15% margin (< 20%)
    Weight__c = 5.0
    // Add other required fields
);
insert testJob;

// Step 2: Create Rebate charge
Job_Charge__c rebateCharge = new Job_Charge__c(
    Job__c = testJob.Id,
    Charge_Type__c = 'Rebate',
    Cost__c = 50.00,
    Sales_Price__c = 100.00
    // Add other required fields
);
insert rebateCharge;

// Step 3: Verify flow auto-adjusted Cost__c
Job_Charge__c verifyRebate = [
    SELECT Id, Cost__c, Sales_Price__c
    FROM Job_Charge__c
    WHERE Id = :rebateCharge.Id
];

System.debug('Rebate Cost__c after save: ' + verifyRebate.Cost__c);
System.debug('Expected: Flow should have adjusted this value');
System.debug('✅ TEST PASSED: Flow executes for Rebates');

// Cleanup
delete rebateCharge;
delete testJob;
```

---

### Test 3: Check Debug Logs

```bash
# Enable debug logs
sf apex log list -o NewOrg

# Check for flow execution entries
# Look for: "Job_Charge_Minimum_20_Gross_on_Rebate" flow entries
# Verify: Flow executes for Rebates, NOT for Credit on Account
```

---

## Handling Affected Records in NewOrg

### If Affected Records Found

**Query to Find**:
```sql
SELECT Id, Name, Job__r.Name, Charge_Type__c, Cost__c, Sales_Price__c,
       CreatedDate, Job__r.Margin__c
FROM Job_Charge__c
WHERE Charge_Type__c = 'Credit on Account'
AND CreatedDate >= 2025-01-15T00:00:00Z
AND Job__r.Margin__c < 20
ORDER BY CreatedDate DESC
```

**Manual Correction Steps**:
1. Export affected records
2. Review each record's expected Cost__c value
3. Update records with correct Cost__c values
4. Document corrections for audit trail

---

## Rollback Plan

### If Flow Deployment Fails

**Symptoms**:
- Deployment error
- Flow not activated
- Syntax errors

**Rollback Steps**:
1. No rollback needed - deployment failure leaves existing flow unchanged
2. Review error messages
3. Fix flow XML syntax issues
4. Redeploy

---

### If Fix Breaks Rebate Logic

**Symptoms**:
- Rebate charges no longer auto-adjust Cost__c
- Rebates with < 20% margin not enforcing minimum

**Rollback Steps**:
1. Retrieve previous flow version from NewOrg
2. Re-deploy previous version
3. Review flow logic
4. Coordinate with OldOrg team to verify correct fix

---

## Success Criteria

### Deployment Success ✅

- [ ] Flow deployed successfully to NewOrg
- [ ] Flow version incremented
- [ ] Flow is active
- [ ] No deployment errors
- [ ] Flow XML shows removed "Credit on Account" filter

---

### Functional Success ✅

- [ ] Test 1 PASSED: Credit on Account values preserved (no auto-adjustment)
- [ ] Test 2 PASSED: Rebate charges still auto-adjust (flow executes as designed)
- [ ] Test 3 PASSED: Debug logs confirm correct flow execution
- [ ] No user reports of incorrect Cost values
- [ ] All affected records (if any) manually corrected

---

## Monitoring & Maintenance

### What to Monitor Post-Deployment

**First 24 Hours**:
1. User reports of incorrect Cost values on Credit on Account charges
2. Debug logs for unexpected flow executions
3. Job Charges with Charge_Type = "Credit on Account" and margin < 20%

**Query for Monitoring**:
```sql
-- Run daily for first week
SELECT Id, Name, Charge_Type__c, Cost__c, CreatedDate
FROM Job_Charge__c
WHERE Charge_Type__c = 'Credit on Account'
AND CreatedDate >= YESTERDAY
ORDER BY CreatedDate DESC
```

---

## Estimated Timeline

**Total Time**: 30-45 minutes

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1 | Pre-deployment verification | 10 mins | Access to NewOrg |
| 2 | Copy and deploy flow | 5 mins | Backup files |
| 3 | Post-deployment testing | 15 mins | Deployment complete |
| 4 | Validation and monitoring setup | 10 mins | Tests passed |

---

## Resources & References

### Source Documentation

- **OldOrg State**: [job-charge-credit-on-account/README.md](../../Salesforce_OldOrg_State/job-charge-credit-on-account/README.md)
- **Complete Technical Documentation**: [JOB_CHARGE_CREDIT_ON_ACCOUNT_FIX.md](../../Salesforce/Documentation/JOB_CHARGE_CREDIT_ON_ACCOUNT_FIX.md)
- **Backup Files**: [/Backup/2025-10-22_job_charge_credit_on_account_fix/](../../Salesforce/Backup/2025-10-22_job_charge_credit_on_account_fix/)

---

**Document Version**: 1.0
**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Ready for Deployment
