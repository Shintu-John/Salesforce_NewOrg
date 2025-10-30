# KAM Budget Reforecast Implementation Guide
**Date:** 2025-10-30  
**Requestor:** Elliot Harrison-Holt  
**Implementing:** John Shintu

---

## Overview

This guide provides step-by-step instructions to update the KAM Budget data in the Old Org with the new FY25/26 reforecast budgets for Jan Ward and Katie Alexander.

### What's Changing:
- **Jan Ward**: Replace existing 396 records (old budget) with 240 new records
- **Katie Alexander**: Replace existing 648 records (under Elliot) with 240 new records
- **Total Changes**: Delete 1,044 records, Import 480 new records

---

## Files Generated

### Backup Files:
1. ✅ `KAM_Budget_BACKUP_20251030_115341.xlsx` - Complete backup of all 6,004 existing KAM Budget records
2. ✅ `KAM_Budget_BACKUP_20251030_115341.csv` - CSV version for easy re-import
3. ✅ `KAM_BUDGET_BACKUP_README.txt` - Documentation of backup

### Import Files:
1. ✅ `Jan_Ward_Budget_FY26_IMPORT.csv` - 240 records (20 accounts × 12 months)
2. ✅ `Katie_Alexander_Budget_FY26_IMPORT.csv` - 240 records (20 accounts × 12 months)

### Scripts:
1. ✅ `delete_old_kam_budgets.sh` - Bash script to delete old records
2. ✅ `prepare_budget_import.py` - Python script to generate import CSVs

---

## Budget Summary

### Jan Ward FY25/26 Budget:
- **Accounts:** 20
- **Period:** March 2025 - February 2026
- **Total Revenue:** £3,991,119
- **Total Margin:** £637,998 (16.0%)
- **Records:** 240 (20 accounts × 12 months)

### Katie Alexander FY25/26 Budget:
- **Accounts:** 20  
- **Period:** March 2025 - February 2026
- **Total Revenue:** £6,849,734
- **Total Margin:** £1,131,334 (16.5%)
- **Records:** 240 (20 accounts × 12 months)

---

## Implementation Steps

### Step 1: Review and Verify

1. **Open the backup file** to verify data was captured:
   ```bash
   open KAM_Budget_BACKUP_20251030_115341.xlsx
   ```

2. **Review the import CSVs**:
   ```bash
   head -20 Jan_Ward_Budget_FY26_IMPORT.csv
   head -20 Katie_Alexander_Budget_FY26_IMPORT.csv
   ```

3. **Check Account Names match Salesforce**:
   - The script uses `Account__r.Name` for lookup
   - Ensure account names in CSV exactly match Salesforce Account records
   - If needed, query Salesforce to verify account names

---

### Step 2: Delete Old Records

Run the deletion script:

```bash
cd /home/john/Projects/Salesforce
./delete_old_kam_budgets.sh
```

**What this does:**
- Prompts for confirmation before deleting
- Deletes Jan Ward's 396 records (Period: 2025-03-01 to 2026-02-01)
- Deletes Katie's 648 records currently under Elliot (Period: 2025-01-01 to 2026-02-01)
- Shows count of deleted records

**Expected output:**
```
Jan Ward records deleted: 396
Katie account records deleted: 648
Total deleted: 1044
```

---

### Step 3: Import New Budget Data

#### Option A: Using Salesforce CLI (Recommended)

```bash
# Import Jan Ward's budget
sf data import bulk \
  --sobject Management_Information__c \
  --file Jan_Ward_Budget_FY26_IMPORT.csv \
  --target-org OldOrg \
  --wait 10

# Import Katie Alexander's budget
sf data import bulk \
  --sobject Management_Information__c \
  --file Katie_Alexander_Budget_FY26_IMPORT.csv \
  --target-org OldOrg \
  --wait 10
```

#### Option B: Using Data Loader (Alternative)

1. Open Salesforce Data Loader
2. Select **Insert**
3. Choose **Management_Information__c** object
4. Map CSV columns to Salesforce fields:
   - `Account__r.Name` → `Account__c` (External ID lookup)
   - `Budget_Owner__c` → `Budget_Owner__c` (ID)
   - `Type__c` → `Type__c`
   - `Service_Group__c` → `Service_Group__c`
   - `Period__c` → `Period__c`
   - `Revenue__c` → `Revenue__c`
   - `Gross_Margin__c` → `Gross_Margin__c`
5. Run insert for `Jan_Ward_Budget_FY26_IMPORT.csv`
6. Run insert for `Katie_Alexander_Budget_FY26_IMPORT.csv`

---

### Step 4: Verify Import

```bash
# Check Jan Ward's records
sf data query \
  --query "SELECT COUNT(Id) FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Jan Ward'" \
  --target-org OldOrg

# Expected: 240

# Check Katie Alexander's records
sf data query \
  --query "SELECT COUNT(Id) FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Katie Alexander'" \
  --target-org OldOrg

# Expected: 240

# Verify a sample record for Jan Ward
sf data query \
  --query "SELECT Account__r.Name, Period__c, Revenue__c, Gross_Margin__c FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Jan Ward' AND Account__r.Name = 'Vinci Holdings' AND Period__c = 2025-03-01" \
  --target-org OldOrg

# Expected: Revenue = 94132.46, Margin = 18651.34
```

---

### Step 5: Create/Update Reports

The existing reports should automatically pick up the new data. However, you may need to create new reports if requested.

#### Report Requirements (from Elliot):
- **Format:** Matrix Report
- **Grouping:** 
  - Rows: Account Name
  - Columns: Period (Month)
- **Fields to Display:**
  - Budgeted Revenue
  - Actual Revenue
  - Revenue Variance
  - Budgeted Margin
  - Actual Margin
  - Margin Variance
- **Filters:**
  - Type = "KAM Budget"
  - Budget Owner = (Jan Ward OR Katie Alexander)
  - Period >= 2025-03-01 AND <= 2026-02-01
  - Service_Group__c = 'ALL' (to avoid showing service breakdown)
- **Summary:** Include Year-to-Date totals

#### Steps to Create Reports in UI:

1. Log into OldOrg Salesforce
2. Navigate to **Reports & Dashboards**
3. Click **New Report**
4. Select Report Type: **Management Information** (or create custom report type if needed)
5. Choose **Matrix** format
6. Configure as per requirements above
7. Save as:
   - "Jan Ward Budget vs Actuals - FY 25/26 (Reforecast)"
   - "Katie Alexander Budget vs Actuals - FY 25/26"
8. Share with:
   - Elliot Harrison-Holt
   - Jan Ward
   - Katie Alexander
9. Save to their respective personal folders

---

## Rollback Procedure

If you need to restore the old data:

```bash
# 1. Delete the new records
sf data delete bulk \
  --sobject Management_Information__c \
  --where "Type__c='KAM Budget' AND (Budget_Owner__r.Name='Jan Ward' OR Budget_Owner__r.Name='Katie Alexander') AND Period__c >= 2025-03-01" \
  --target-org OldOrg

# 2. Import the backup
sf data import bulk \
  --sobject Management_Information__c \
  --file KAM_Budget_BACKUP_20251030_115341.csv \
  --target-org OldOrg \
  --wait 10
```

---

## Key Points

### Why Delete Instead of Update?
- Existing records have service line breakdown (Skip, RO/RO, etc.)
- New budget has consolidated totals only
- Reports SUM all records per account/month
- Adding new records without deleting would cause double-counting
- Example: Vinci Mar 2025 would show £120k (old) + £94k (new) = £214k ❌

### No Impact on Previous Years
- All KAM Budget data is for FY25/26 only (Jan 2025 - Feb 2026)
- Zero records exist before 2025-01-01
- Safe to delete and replace

### Data Structure Change
- **Old:** Multiple records per account/month (by Service Group)
- **New:** One record per account/month (Service_Group__c = 'ALL')
- **Reports:** Still work because they SUM by account/month

---

## Contact

For questions or issues:
- **John Shintu:** john.shintu@recyclinglives-services.com
- **Elliot Harrison-Holt:** (original requestor)

---

## Checklist

- [ ] Backup reviewed and verified
- [ ] Import CSVs generated and checked
- [ ] Old records deleted (1,044 records)
- [ ] New records imported (480 records)
- [ ] Data verified in Salesforce
- [ ] Reports created/updated
- [ ] Reports shared with stakeholders
- [ ] Elliot, Jan, and Katie notified

---

**Implementation Date:** _________________  
**Implemented By:** _________________  
**Verified By:** _________________

