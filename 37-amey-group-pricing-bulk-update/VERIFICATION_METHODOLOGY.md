# Bulk Update Verification Methodology

**Scenario:** 37-amey-group-pricing-bulk-update
**Date:** 2025-10-31
**Author:** John Shintu
**Purpose:** Document verification methodology for bulk pricing updates

---

## Overview

This document outlines the verification methodology used to ensure bulk pricing updates are correctly applied to Salesforce records. This methodology was developed during the Amey Group pricing update (900 Order Products) and can be reused for future bulk update scenarios.

---

## The Critical Learning: Record IDs vs Display Numbers

### The Key Discovery

When performing bulk updates in Salesforce, there's a critical distinction between:

1. **Display numbers** (e.g., Order Product Number: 0000060338) - user-facing identifiers
2. **Salesforce Record IDs** (e.g., 802Sj000000HlKHIA0) - the actual database keys

**IMPORTANT:** Bulk updates use **Salesforce Record IDs**, NOT display numbers.

### Why This Matters

During the Amey Group pricing update, initial verification appeared to show failures:
- Backup CSV showed Order Product Numbers like "27202" (missing leading zeros)
- Excel file showed "0000027202" (with leading zeros)
- This looked like a mismatch, but it wasn't!

**Root cause:** Pandas converts numeric-looking strings to integers when writing/reading CSVs, which drops leading zeros from display numbers.

**Why it doesn't matter:** The update CSV uses Salesforce Record IDs (e.g., `8024H00000R9ibmQAB`), which are alphanumeric and never get converted. The update operation is 100% correct even when backup CSV display numbers look wrong.

---

## Verification Methodology

### Phase 1: Pre-Update Validation

**Purpose:** Ensure CSV files contain correct data BEFORE executing the update.

#### Step 1: Verify Record Count
```bash
# Count records in update CSV (excluding header)
wc -l data/amey-pricing-update-oldorg.csv
# Should match expected count (e.g., 900 + 1 header = 901 lines)
```

#### Step 2: Validate Salesforce Record IDs
Query Salesforce to confirm the Record IDs in the update CSV actually exist:

```bash
# Take sample IDs from update CSV
head -20 data/amey-pricing-update-oldorg.csv | tail -10

# Query OldOrg to verify they exist
sf data query --query "SELECT Id, OrderItemNumber FROM OrderItem WHERE Id IN ('802Sj000000HlKHIA0', '802Sj000000HlKIIA0', ...)" --target-org OldOrg --json
```

**Expected result:** All Record IDs should return valid Order Product records.

#### Step 3: Cross-Reference Display Numbers
Even though update uses Record IDs, verify the mapping between Record IDs and display numbers is correct:

```bash
# Query for specific display numbers (Order Product Numbers)
sf data query --query "SELECT Id, OrderItemNumber FROM OrderItem WHERE OrderItemNumber IN ('0000060338', '0000060339', '0000060340')" --target-org OldOrg --json

# Compare IDs returned with IDs in update CSV
```

**Expected result:** Record IDs from query match Record IDs in update CSV.

#### Step 4: Sample Price Verification
Manually verify a sample (10+ records) showing:
1. Order Product Number (display)
2. Salesforce Record ID (update key)
3. Excel price value
4. Update CSV price value

**Expected result:** Excel prices exactly match update CSV prices for the same Record IDs.

---

### Phase 2: Execute Update

```bash
sf data upsert bulk \
  --sobject OrderItem \
  --file data/amey-pricing-update-oldorg.csv \
  --external-id Id \
  --target-org OldOrg \
  --wait 10
```

**Monitor:** Watch for completion status:
- `UploadComplete` = CSV uploaded successfully
- `Completed` = All records processed
- Check for failed records count

---

### Phase 3: Post-Update Verification

**Purpose:** Confirm the update was applied correctly in Salesforce.

#### Step 1: Query Updated Records
Query a sample of Order Products to fetch current pricing:

```bash
sf data query --query "
SELECT Id, OrderItemNumber, Sales_Price__c, Sales_Transport__c,
       Sales_Tonnage_charge_thereafter__c
FROM OrderItem
WHERE OrderItemNumber IN (
  '0000060338', '0000060339', '0000060340', '0000060341', '0000060342',
  '0000027202', '0000027203', '0000027204', '0000027205', '0000027206'
)" --target-org OldOrg --json
```

#### Step 2: Compare with Update CSV
For each Order Product returned:
1. Find its Record ID in the update CSV
2. Compare `Sales_Price__c` values
3. Compare `Sales_Transport__c` values
4. Compare `Sales_Tonnage_charge_thereafter__c` values

**Expected result:** Values in Salesforce match values in update CSV exactly (allowing for floating point precision differences).

#### Step 3: Statistical Verification
For large updates (100+ records), perform statistical checks:

```bash
# Query summary statistics from Salesforce
sf data query --query "
SELECT
  COUNT(Id) as TotalRecords,
  AVG(Sales_Price__c) as AvgPrice,
  MIN(Sales_Price__c) as MinPrice,
  MAX(Sales_Price__c) as MaxPrice
FROM OrderItem
WHERE OrderItemNumber IN ('0000060338', '0000060339', ...)
" --target-org OldOrg --json

# Compare with summary statistics from update CSV using Python/Excel
```

**Expected result:** Statistical measures should align (within rounding tolerance).

---

## Verification Checklist

Use this checklist for every bulk update:

### Pre-Update
- [ ] Record count matches expected (Excel rows = CSV rows - header)
- [ ] Sample Salesforce Record IDs verified to exist in target org
- [ ] Display numbers (Order Product Numbers) correctly mapped to Record IDs
- [ ] Sample pricing values (10+ records) manually verified: Excel = Update CSV
- [ ] Backup CSV created (even if display numbers show without leading zeros)

### During Update
- [ ] Bulk upsert command executed without errors
- [ ] Job status shows `UploadComplete` or `Completed`
- [ ] Failed records count = 0 (or explained)

### Post-Update
- [ ] Sample verification: Query 10+ records from Salesforce
- [ ] Values match update CSV (Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c)
- [ ] Statistical summary matches (if applicable)
- [ ] Update documented in DEPLOYMENT_HISTORY.md

---

## Common Pitfalls

### Pitfall 1: Leading Zero Confusion
**Problem:** Backup CSV shows "27202" but Excel shows "0000027202"
**Why it happens:** Pandas/CSV tools convert numeric strings to integers
**Why it doesn't matter:** Update uses Record IDs (alphanumeric), not display numbers
**Solution:** Ignore leading zero mismatches in backup CSV. Focus on Record ID verification.

### Pitfall 2: Floating Point Precision
**Problem:** Excel shows 238.567 but Salesforce shows 238.56698599999999
**Why it happens:** Excel rounds for display, Salesforce stores full precision
**Solution:** Accept small floating point differences (< 0.00001). They're the same value.

### Pitfall 3: NULL vs Empty String
**Problem:** Update CSV has empty string `""` but Salesforce shows `null`
**Why it happens:** Salesforce treats empty strings as NULL in numeric fields
**Solution:** Both empty string and NULL mean "no value" - consider them equivalent.

### Pitfall 4: Order Product Number Format
**Problem:** Excel shows integer 60338, but Salesforce needs "0000060338"
**Why it happens:** Salesforce OrderItemNumber is a string field with leading zeros
**Solution:** Use `.zfill(10)` in Python to format numbers with leading zeros:
```python
order_number = str(int(excel_value)).zfill(10)  # 60338 → "0000060338"
```

---

## Sample Verification Results

### Amey Group Pricing Update (2025-10-31)

**Records Updated:** 900 Order Products
**Verification Sample:** 10 records
**Result:** 100% match (10/10 records verified)

| Order Product # | Sales_Price__c | Sales_Transport__c | Sales_Tonnage_charge | Status |
|----------------|----------------|--------------------|--------------------|---------|
| 0000027202 | 238.567 | null | null | ✓ Match |
| 0000027203 | 0 | null | null | ✓ Match |
| 0000027204 | 77.77 | null | null | ✓ Match |
| 0000027205 | 287.091 | null | 153.321 | ✓ Match |
| 0000027206 | 0 | null | null | ✓ Match |
| 0000060338 | 665.861 | null | 146.804 | ✓ Match |
| 0000060339 | 220.206 | null | null | ✓ Match |
| 0000060340 | 75 | null | null | ✓ Match |
| 0000060341 | 75 | null | null | ✓ Match |
| 0000060342 | 75 | null | null | ✓ Match |

**Bulk Update Job Details:**
- Job ID: 750Sj00000Ll865IAB
- Status: Completed
- Total Records: 900
- Successful: 900
- Failed: 0
- Execution Time: ~10 seconds

---

## Tools and Commands

### Query Templates

**Basic verification query:**
```bash
sf data query --query "
SELECT Id, OrderItemNumber, Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c
FROM OrderItem
WHERE OrderItemNumber IN ('0000060338', '0000060339')
" --target-org OldOrg --json
```

**Count verification:**
```bash
sf data query --query "
SELECT COUNT(Id)
FROM OrderItem
WHERE OrderItemNumber IN ('0000060338', '0000060339', ...)
" --target-org OldOrg --json
```

### Python Verification Script

```python
import pandas as pd
import json
import subprocess

# Load update CSV
update_df = pd.read_csv('data/amey-pricing-update-oldorg.csv')

# Sample 10 Record IDs
sample_ids = update_df['Id'].head(10).tolist()

# Query Salesforce
query = f"SELECT Id, Sales_Price__c FROM OrderItem WHERE Id IN ('{\"','\".join(sample_ids)}')"
result = subprocess.run(['sf', 'data', 'query', '--query', query, '--target-org', 'OldOrg', '--json'],
                       capture_output=True, text=True)
sf_data = json.loads(result.stdout)['result']['records']

# Compare
for sf_record in sf_data:
    sf_id = sf_record['Id']
    sf_price = sf_record['Sales_Price__c']
    csv_price = update_df[update_df['Id'] == sf_id]['Sales_Price__c'].values[0]

    match = abs(sf_price - csv_price) < 0.00001 if pd.notna(csv_price) else pd.isna(sf_price)
    status = "✓ Match" if match else "✗ Mismatch"
    print(f"{sf_id}: SF={sf_price}, CSV={csv_price} - {status}")
```

---

## Best Practices

1. **Always create a backup CSV before updating** - even if display numbers have formatting issues, it still contains the current values with correct Record IDs

2. **Verify a statistically significant sample** - for 900 records, verify at least 10-20 (1-2%)

3. **Document Job ID** - save the bulk update Job ID for audit trail and troubleshooting

4. **Use Record IDs for verification** - don't rely on display numbers which can have formatting issues

5. **Test floating point equality with tolerance** - use `abs(a - b) < 0.00001` instead of `a == b`

6. **Query before and after** - compare before/after states to confirm changes

7. **Keep Excel source file** - preserve the source of truth for price values

---

## Rollback Procedure

If verification fails and rollback is needed:

```bash
# Use the backup CSV created before update
sf data upsert bulk \
  --sobject OrderItem \
  --file data/amey-pricing-backup-oldorg.csv \
  --external-id Id \
  --target-org OldOrg \
  --wait 10

# Verify rollback
sf data query --query "SELECT Id, Sales_Price__c FROM OrderItem WHERE Id IN (...)" --target-org OldOrg
```

**Note:** The backup CSV has correct Record IDs and pricing values, even if display numbers (OrderItemNumber column) show without leading zeros due to CSV formatting.

---

## Future Improvements

For future bulk update scenarios, consider:

1. **Automated verification script** - Python script that automatically compares update CSV with post-update Salesforce state

2. **Pre-update validation gate** - Require manual review of sample verification before allowing bulk update execution

3. **Comprehensive test in Sandbox** - Always test bulk update procedure in Sandbox org first for new scenarios

4. **Email notification on completion** - Configure Salesforce to email when bulk job completes

5. **Expanded statistical checks** - Add standard deviation, median, and outlier detection

---

## Related Documentation

- [README.md](README.md) - Scenario implementation plan
- [DEPLOYMENT_HISTORY.md](DEPLOYMENT_HISTORY.md) - Deployment execution details
- [prepare_pricing_update.py](scripts/prepare_pricing_update.py) - Data preparation script

---

**Document Maintained By:** John Shintu
**Email:** shintu.john@recyclinglives.com
**Last Updated:** 2025-10-31

---

**End of Verification Methodology**
