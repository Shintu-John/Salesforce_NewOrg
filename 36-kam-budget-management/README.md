# KAM Budget Management System - Configuration & Analysis

**Scenario Type:** Configuration & Analysis (No Code Deployment)
**Priority:** Reference Documentation
**Object:** `Management_Information__c`
**Date Created:** October 30, 2025
**Author:** John Shintu

---

## Overview

The KAM (Key Account Manager) Budget Management System is a comprehensive budget tracking and performance monitoring solution built on the `Management_Information__c` custom object. This system enables KAMs to set monthly revenue and margin budgets for their accounts and automatically tracks actual performance against those budgets.

### Key Features
- Monthly budget forecasting (Revenue and Gross Margin)
- Automated actual performance tracking from Job deliveries
- Variance analysis (Budget vs Actual)
- Multi-KAM support with owner-based data segregation
- Service Group breakdown capabilities
- Integration with Job__c object for real-time actuals

### Primary Users
- Elliot Harrison-Holt (Budget Owner)
- Jan Ward (Budget Owner)
- Katie Alexander (Budget Owner)

---

## Object Structure: Management_Information__c

### Core Fields

| Field API Name | Type | Label | Description | Editable? |
|----------------|------|-------|-------------|-----------|
| `Account__c` | Lookup(Account) | Account | Account this budget record applies to | Yes |
| `Budget_Owner__c` | Lookup(User) | Budget Owner | KAM responsible for this budget | Yes |
| `Type__c` | Picklist | Type | Record type - use "KAM Budget" | Yes |
| `Service_Group__c` | Picklist | Service Group | Service line (e.g., Skip, RO/RO, ALL) | Yes |
| `Period__c` | Date | Period | Budget month (first day of month) | Yes |
| `Revenue__c` | Currency(15,2) | Budgeted Revenue | Forecasted revenue for the month | **Yes - Manual** |
| `Gross_Margin__c` | Currency(16,2) | Budgeted Margin | Forecasted gross margin in £ | **Yes - Manual** |
| `Actual_Revenue__c` | Currency(16,2) | Actual Revenue | Actual revenue from Job deliveries | **No - Auto** |
| `Actual_Margin__c` | Currency(16,2) | Actual Margin | Actual margin from Job deliveries | **No - Auto** |
| `Revenue_Variance__c` | Formula (Percent) | Revenue Variance | `(Actual - Budget) / Budget` | No - Formula |
| `Margin_Variance__c` | Formula (Percent) | Margin Variance | `(Actual - Budget) / Budget` | No - Formula |
| `Budgeted_Gross__c` | Formula (Percent) | Budgeted Gross % | `Margin / Revenue` | No - Formula |
| `Actual_Gross__c` | Formula (Percent) | Actual Gross % | `Actual Margin / Actual Revenue` | No - Formula |
| `RLS_Entity__c` | Picklist | RLS Entity | Entity assignment | Yes |
| `Import_Ref__c` | Text(50) | Import Ref | External reference for imports | Yes |

### Additional System Fields

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number | Management Information Record (auto-generated) |
| `Account_ID__c` | Formula (Text) | Account.AccountNumber |
| `Account_Owner__c` | Formula (Text) | Account.Owner.Name |
| `Delivery_Date__c` | Formula (Date) | Period__c (duplicate for compatibility) |

---

## How Data is Populated

### Manual Fields (Set by Users)

These fields are **manually entered or imported** from Excel budget files:

1. **Revenue__c** (Budgeted Revenue)
   - Source: KAM's budget forecast spreadsheet
   - Represents expected revenue for Account + Month
   - Updated during budget planning cycles (typically quarterly or annually)

2. **Gross_Margin__c** (Budgeted Margin)
   - Source: KAM's budget forecast spreadsheet
   - Represents expected gross margin in £ (not percentage)
   - Calculated as: Revenue × Margin %
   - Updated during budget planning cycles

3. **Account__c**, **Budget_Owner__c**, **Type__c**, **Service_Group__c**, **Period__c**
   - Set during budget import/entry
   - Period__c must be first day of month (e.g., 2025-03-01 for March 2025)

### Automated Fields (System Calculated)

These fields are **automatically populated** by the `rlsBudgetManager` batch job:

1. **Actual_Revenue__c**
   - Populated by: `rlsBudgetManager` Apex batch class
   - Source: SUM of `Job__c.Sales_Total_F__c` where:
     - Job.Account__c matches this record's Account (including child accounts)
     - Job.Delivery_Date__c month matches this record's Period__c
   - Schedule: Runs 3x daily (8 AM, 12 PM, 4 PM on weekdays)
   - Processing Window: Last 6 months only

2. **Actual_Margin__c**
   - Populated by: `rlsBudgetManager` Apex batch class
   - Source: SUM of `Job__c.Internal_Commission_Total__c` where:
     - Job.Account__c matches this record's Account (including child accounts)
     - Job.Delivery_Date__c month matches this record's Period__c
   - Schedule: Runs 3x daily (8 AM, 12 PM, 4 PM on weekdays)
   - Processing Window: Last 6 months only

### Formula Fields (Auto-Calculated)

These fields automatically calculate based on other fields:

1. **Revenue_Variance__c**: `(Actual_Revenue__c - Revenue__c) / Revenue__c`
2. **Margin_Variance__c**: `(Actual_Margin__c - Gross_Margin__c) / Gross_Margin__c`
3. **Budgeted_Gross__c**: `Gross_Margin__c / Revenue__c`
4. **Actual_Gross__c**: `Actual_Margin__c / Actual_Revenue__c`

---

## Automated Batch Job: rlsBudgetManager

### Apex Class Details

**Class Name:** `rlsBudgetManager`
**Apex Class ID:** `01pSj000000gqDVIAY`
**Type:** Schedulable, Batchable
**Implements:** `Schedulable`, `Database.Batchable<sObject>`

### Schedule

**Cron Expression:** `0 0 8,12,16 ? * MON-FRI *`

- **Frequency:** 3 times per day on weekdays only
- **Run Times:** 8:00 AM, 12:00 PM, 4:00 PM (UK time)
- **Days:** Monday through Friday
- **No Weekend Runs:** Saturday and Sunday are excluded

### What It Does

1. **Query Phase (start method):**
   ```apex
   SELECT Id, Account__c, Service_Group__c, Actual_Revenue__c,
          Actual_Margin__c, Period__c
   FROM Management_Information__c
   WHERE Account__c != NULL
     AND Type__c = 'KAM Budget'
     AND Period__c <= TODAY
     AND Period__c >= LAST_6_MONTHS
   ```

2. **Processing Phase (execute method):**
   - For each Management_Information__c record:
     - Gets Account hierarchy (parent + all children)
     - Queries Job__c records where:
       - Account is in the hierarchy
       - Delivery_Date__c matches the Period__c month
     - Aggregates:
       - SUM(Job__c.Sales_Total_F__c) → Actual_Revenue__c
       - SUM(Job__c.Internal_Commission_Total__c) → Actual_Margin__c
     - Updates Management_Information__c record

3. **Processing Window:**
   - Only processes records for last 6 months
   - Skips future months (Period__c > TODAY)
   - Historical data older than 6 months is not updated

### Job Monitoring

Check scheduled job status:
```bash
sf data query --query "SELECT Id, CronJobDetail.Name, NextFireTime, State, PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name = 'rlsBudgetManager'" --target-org OldOrg
```

View batch job history:
```bash
sf data query --query "SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedDate, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name = 'rlsBudgetManager' ORDER BY CreatedDate DESC LIMIT 10" --target-org OldOrg
```

---

## How to Update Budget Data

### Scenario 1: Annual/Quarterly Budget Refresh (Recommended)

Use **UPDATE** operations to preserve Actual field data:

1. **Export current budget data:**
   ```bash
   sf data query --query "SELECT Id, Account__c, Budget_Owner__c, Period__c, Revenue__c, Gross_Margin__c FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Jan Ward'" --target-org OldOrg --result-format csv > current_budget.csv
   ```

2. **Prepare update CSV:**
   - Include `Id` column (required for UPDATE)
   - Update only `Revenue__c` and `Gross_Margin__c` columns
   - Do NOT include `Actual_Revenue__c` or `Actual_Margin__c`
   - Do NOT include formula fields

3. **Import using UPSERT:**
   ```bash
   sf data upsert bulk --sobject Management_Information__c --file updated_budget.csv --external-id Id --target-org OldOrg --wait 10
   ```

**Why UPDATE is Better:**
- ✅ Preserves Actual_Revenue__c and Actual_Margin__c
- ✅ Maintains historical performance data
- ✅ Formula fields recalculate automatically
- ✅ No data loss

### Scenario 2: New Budget Year/Period

When adding budgets for new periods (e.g., next fiscal year):

1. **Prepare INSERT CSV:**
   ```csv
   Account__c,Budget_Owner__c,Type__c,Service_Group__c,Period__c,Revenue__c,Gross_Margin__c
   001Sj00000By98eIAB,0051o00000AIeioAAD,KAM Budget,ALL,2026-03-01,10000,2000
   ```

2. **Fields to Include:**
   - Account__c (18-character Account ID)
   - Budget_Owner__c (18-character User ID)
   - Type__c (always "KAM Budget")
   - Service_Group__c (usually "ALL" for consolidated budgets)
   - Period__c (YYYY-MM-DD, first day of month)
   - Revenue__c (forecasted revenue)
   - Gross_Margin__c (forecasted margin in £)

3. **Fields to EXCLUDE:**
   - ❌ Id (cannot be specified in INSERT)
   - ❌ Name (auto-generated)
   - ❌ Actual_Revenue__c (will be populated by batch job)
   - ❌ Actual_Margin__c (will be populated by batch job)
   - ❌ Revenue_Variance__c (formula field)
   - ❌ Margin_Variance__c (formula field)
   - ❌ Any relationship fields (e.g., Account__r.Name, Budget_Owner__r.Name)

4. **Import:**
   ```bash
   sf data import bulk --sobject Management_Information__c --file new_budget.csv --target-org OldOrg --wait 10
   ```

### Scenario 3: Replacing Existing Budgets (Use with Caution)

Only use DELETE + INSERT if the budget structure has fundamentally changed (e.g., consolidating service groups).

**⚠️ WARNING:** This approach will temporarily lose Actual data until the batch job runs again.

1. **Create full backup first:**
   ```bash
   sf data query --query "SELECT Id, Name, Account__c, Account__r.Name, Budget_Owner__c, Budget_Owner__r.Name, Type__c, Service_Group__c, Period__c, Revenue__c, Actual_Revenue__c, Gross_Margin__c, Actual_Margin__c, Revenue_Variance__c, Margin_Variance__c FROM Management_Information__c WHERE Type__c = 'KAM Budget'" --target-org OldOrg --result-format csv > KAM_Budget_BACKUP_$(date +%Y%m%d_%H%M%S).csv
   ```

2. **Delete old records:**
   ```bash
   sf data delete bulk --sobject Management_Information__c --where "Type__c='KAM Budget' AND Budget_Owner__r.Name='Jan Ward' AND Period__c >= 2025-03-01" --target-org OldOrg
   ```

3. **Insert new records** (see Scenario 2)

4. **Wait for batch job** to repopulate Actual fields (runs at 8 AM, 12 PM, 4 PM on weekdays)

---

## What NOT to Do

### ❌ DO NOT Manually Set Actual Fields

**Never manually edit or import values for:**
- `Actual_Revenue__c`
- `Actual_Margin__c`

**Why:**
- These fields are managed by the `rlsBudgetManager` batch job
- Manual values will be overwritten within 4-8 hours (next batch run)
- Creates data inconsistency with Job__c source data

**Exception:**
- During data restoration from backup (see Restoration Procedures)

### ❌ DO NOT Include Formula Fields in Imports

**Never include these fields in CSV imports:**
- `Revenue_Variance__c`
- `Margin_Variance__c`
- `Budgeted_Gross__c`
- `Actual_Gross__c`
- `Account_ID__c`
- `Account_Owner__c`
- `Delivery_Date__c`

**Why:**
- Salesforce will reject the import with error: "Unable to create/update fields: [field_name]. Please check the security settings of this field and verify that it is read/write for your profile or permission set."
- Formula fields are read-only and auto-calculate

### ❌ DO NOT Delete Without Backup

**Always create a backup before deleting records:**

```bash
# Create timestamped backup
sf data query --query "SELECT Id, Name, Account__c, Account__r.Name, Budget_Owner__c, Budget_Owner__r.Name, Type__c, Service_Group__c, Period__c, Revenue__c, Actual_Revenue__c, Gross_Margin__c, Actual_Margin__c, Revenue_Variance__c, Margin_Variance__c FROM Management_Information__c WHERE Type__c = 'KAM Budget'" --target-org OldOrg --result-format csv > KAM_Budget_BACKUP_$(date +%Y%m%d_%H%M%S).csv
```

**Why:**
- Actual field data aggregated over months cannot be easily recreated
- The batch job only processes last 6 months
- Historical data older than 6 months would be permanently lost

### ❌ DO NOT Use DELETE + INSERT for Budget Updates

**Prefer UPDATE over DELETE + INSERT when refreshing budgets:**

**Bad Approach (DELETE + INSERT):**
```bash
# ❌ This will lose Actual data temporarily
sf data delete bulk --sobject Management_Information__c --where "Type__c='KAM Budget'"
sf data import bulk --sobject Management_Information__c --file new_budget.csv
```

**Good Approach (UPDATE):**
```bash
# ✅ This preserves Actual data
sf data upsert bulk --sobject Management_Information__c --file updated_budget_with_ids.csv --external-id Id
```

**Why:**
- DELETE + INSERT creates new records with blank Actual fields
- Users see incorrect dashboards showing zero actuals until batch job runs
- UPDATE preserves all existing Actual data

### ❌ DO NOT Mix Service Groups in Reports

**When creating reports, filter by Service_Group__c:**

**Bad:**
```sql
-- ❌ This will double-count if both detail and consolidated records exist
SELECT Account__r.Name, Period__c, SUM(Revenue__c)
FROM Management_Information__c
WHERE Type__c = 'KAM Budget'
GROUP BY Account__r.Name, Period__c
```

**Good:**
```sql
-- ✅ This shows only consolidated totals
SELECT Account__r.Name, Period__c, SUM(Revenue__c)
FROM Management_Information__c
WHERE Type__c = 'KAM Budget'
  AND Service_Group__c = 'ALL'
GROUP BY Account__r.Name, Period__c
```

**Why:**
- Old budget structure had multiple records per account/month (Skip, RO/RO, etc.)
- New budget structure uses single consolidated record (Service_Group__c = 'ALL')
- Without filtering, reports would show inflated totals if both exist

---

## Data Import from Excel Budgets

### Excel Budget File Structure

KAM budget files typically have this structure:

```
Row 1: Headers (Account names across columns)
Row 2: Month labels (Mar-25, Apr-25, etc.)
Row 3-14: Revenue section (12 months)
Row 16-27: Gross Profit section (12 months)
Row 29-40: Margin % section (12 months - for reference only)
```

### Automated Import Script

Use the provided Python script to convert Excel budgets to Salesforce CSV:

**Script:** `prepare_budget_import_FIXED.py`

**Usage:**
```bash
python3 prepare_budget_import_FIXED.py
```

**What it does:**
1. Reads Excel budget files from current directory
2. Extracts Revenue and Gross Profit (£) values
3. Maps Account names to Salesforce Account IDs
4. Converts to Salesforce import CSV format
5. Generates one row per Account × Month combination
6. Sets Period__c to first day of each month

**Input Files:**
- `JW FY26 Budget.xlsx` (Jan Ward)
- `KA FY26 Budget.xlsx` (Katie Alexander)

**Output Files:**
- `Jan_Ward_Budget_FY26_IMPORT_CORRECTED.csv`
- `Katie_Alexander_Budget_FY26_IMPORT_CORRECTED.csv`

**CSV Format:**
```csv
Account__c,Budget_Owner__c,Type__c,Service_Group__c,Period__c,Revenue__c,Gross_Margin__c
001Sj00000By98eIAB,0051o00000AIeioAAD,KAM Budget,ALL,2025-03-01,10000.00,2000.00
```

### Manual Account ID Lookup

If you need to find Account IDs manually:

```bash
sf data query --query "SELECT Id, Name FROM Account WHERE Name IN ('Vinci Holdings', 'Kier Group', 'Amey Group PLC')" --target-org OldOrg
```

### Manual User ID Lookup

To find Budget Owner User IDs:

```bash
sf data query --query "SELECT Id, Name FROM User WHERE Name IN ('Jan Ward', 'Katie Alexander', 'Elliot Harrison-Holt') AND IsActive = true" --target-org OldOrg
```

**Known User IDs:**
- Jan Ward: `0051o00000AIeioAAD`
- Katie Alexander: `005Sj000001u9xhIAA`
- Elliot Harrison-Holt: `005Sj000001SmE2IAK`

---

## Backup and Restoration Procedures

### Creating a Backup

**Full backup with all fields:**
```bash
sf data query --query "SELECT Id, Name, Account__c, Account__r.Name, Budget_Owner__c, Budget_Owner__r.Name, Type__c, Service_Group__c, Period__c, Revenue__c, Actual_Revenue__c, Gross_Margin__c, Actual_Margin__c, Revenue_Variance__c, Margin_Variance__c FROM Management_Information__c WHERE Type__c = 'KAM Budget' ORDER BY Id" --target-org OldOrg --result-format csv > KAM_Budget_BACKUP_$(date +%Y%m%d_%H%M%S).csv
```

**What's included:**
- All 6,000+ KAM Budget records
- Budget forecasts (Revenue__c, Gross_Margin__c)
- Actual performance (Actual_Revenue__c, Actual_Margin__c)
- Variance calculations
- Account and Owner relationships

### Restoring from Backup

**Scenario 1: Restore Specific Records (Recommended)**

If you need to restore specific Budget Owner or date ranges:

1. **Delete problematic records:**
   ```bash
   sf data delete bulk --sobject Management_Information__c --where "Type__c='KAM Budget' AND Budget_Owner__r.Name='Jan Ward' AND Period__c >= 2025-03-01" --target-org OldOrg
   ```

2. **Prepare import CSV from backup:**
   - Remove these columns: `Id`, `Name`, `Account__r.Name`, `Budget_Owner__r.Name`, `Revenue_Variance__c`, `Margin_Variance__c`
   - Keep: `Account__c`, `Budget_Owner__c`, `Type__c`, `Service_Group__c`, `Period__c`, `Revenue__c`, `Actual_Revenue__c`, `Gross_Margin__c`, `Actual_Margin__c`

   **Python cleanup script:**
   ```python
   import pandas as pd

   df = pd.read_csv('KAM_Budget_BACKUP_20251030_115341.csv')

   columns_to_remove = ['Id', 'Name', 'Account__r.Name',
                        'Budget_Owner__r.Name', 'Revenue_Variance__c',
                        'Margin_Variance__c']
   df_import = df.drop(columns=[col for col in columns_to_remove
                                 if col in df.columns])

   df_import.to_csv('KAM_Budget_RESTORE_FOR_IMPORT.csv', index=False)
   ```

3. **Import cleaned backup:**
   ```bash
   sf data import bulk --sobject Management_Information__c --file KAM_Budget_RESTORE_FOR_IMPORT.csv --target-org OldOrg --wait 10
   ```

**Scenario 2: Complete System Restore**

If you need to restore the entire KAM Budget dataset:

1. **Delete all KAM Budget records:**
   ```bash
   sf data delete bulk --sobject Management_Information__c --where "Type__c='KAM Budget'" --target-org OldOrg
   ```

2. **Clean backup CSV** (remove non-importable fields as shown above)

3. **Import complete backup:**
   ```bash
   sf data import bulk --sobject Management_Information__c --file KAM_Budget_RESTORE_FOR_IMPORT.csv --target-org OldOrg --wait 10
   ```

4. **Verify restoration:**
   ```bash
   # Check total count
   sf data query --query "SELECT COUNT(Id) FROM Management_Information__c WHERE Type__c = 'KAM Budget'" --target-org OldOrg

   # Expected: 6,004 (or your original count)

   # Check by owner
   sf data query --query "SELECT Budget_Owner__r.Name, COUNT(Id) FROM Management_Information__c WHERE Type__c = 'KAM Budget' GROUP BY Budget_Owner__r.Name" --target-org OldOrg
   ```

### Restoration Error Handling

**Error: "INVALID_FIELD_FOR_INSERT_UPDATE:cannot specify Id in an insert call"**

**Solution:** Remove `Id` and `Name` columns from CSV before import

**Error: "Unable to create/update fields: Revenue_Variance__c, Margin_Variance__c"**

**Solution:** Remove all formula fields from CSV (see cleanup script above)

**Error: "External ID not found"**

**Solution:** Ensure `Account__c` contains valid 18-character Salesforce Account IDs, not Account Names

---

## Reporting and Dashboards

### Recommended Report Structure

**Report Type:** Matrix Report
**Primary Object:** Management Information

**Groupings:**
- **Rows:** Account Name (Account__r.Name)
- **Columns:** Period (Period__c) - format as "MMM-YY"

**Fields to Display:**
- Budgeted Revenue (Revenue__c)
- Actual Revenue (Actual_Revenue__c)
- Revenue Variance % (Revenue_Variance__c)
- Budgeted Margin (Gross_Margin__c)
- Actual Margin (Actual_Margin__c)
- Margin Variance % (Margin_Variance__c)
- Budgeted Gross % (Budgeted_Gross__c)
- Actual Gross % (Actual_Gross__c)

**Filters:**
```
Type__c = "KAM Budget"
Service_Group__c = "ALL"
Budget_Owner__c = [Current User] (or specific KAM)
Period__c >= THIS_FISCAL_YEAR
```

**Summaries:**
- Row Total: SUM of all months per account
- Column Total: SUM of all accounts per month
- Grand Total: Total budget vs actual for the period

### Dashboard Components

**1. Revenue Performance Gauge**
```
Metric: SUM(Actual_Revenue__c) / SUM(Revenue__c)
Target: 100%
Green: >= 95%
Yellow: 80-94%
Red: < 80%
```

**2. Margin Performance Gauge**
```
Metric: SUM(Actual_Margin__c) / SUM(Gross_Margin__c)
Target: 100%
Green: >= 95%
Yellow: 80-94%
Red: < 80%
```

**3. Top 10 Performing Accounts**
```
Chart: Horizontal Bar
X-Axis: Revenue_Variance__c
Y-Axis: Account Name
Filter: Revenue_Variance__c > 0 (over-performing)
Sort: Revenue_Variance__c DESC
Limit: 10
```

**4. Underperforming Accounts Alert**
```
Chart: Table
Columns: Account Name, Budgeted Revenue, Actual Revenue, Variance %
Filter: Revenue_Variance__c < -20 (more than 20% under budget)
Sort: Revenue_Variance__c ASC
```

---

## Troubleshooting

### Issue: Actual Fields Show Zero

**Symptoms:**
- Actual_Revenue__c = 0 or blank
- Actual_Margin__c = 0 or blank
- Period__c is in the past (should have data)

**Possible Causes:**

1. **Batch job hasn't run yet**
   - Check: `SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = 'rlsBudgetManager'`
   - Solution: Wait for next scheduled run (8 AM, 12 PM, or 4 PM on weekdays)

2. **No Job deliveries for this Account + Period**
   - Check: `SELECT COUNT(Id), SUM(Sales_Total_F__c) FROM Job__c WHERE Account__c = 'XXX' AND Delivery_Date__c >= 2025-03-01 AND Delivery_Date__c < 2025-04-01`
   - Solution: Verify Jobs exist with correct Account and Delivery_Date__c

3. **Period is outside batch processing window**
   - Batch only processes last 6 months
   - Solution: Periods older than 6 months won't be updated automatically

4. **Account hierarchy issue**
   - Batch includes child accounts in aggregation
   - Check: Account parent-child relationships may affect results

### Issue: Dashboard Shows Doubled Numbers

**Symptoms:**
- Revenue totals appear twice as high as expected
- Multiple records per Account + Month visible

**Cause:**
- Both service-line detail records AND consolidated records exist
- Reports summing without Service_Group__c filter

**Solution:**
Add filter to reports:
```
Service_Group__c = "ALL"
```

Or delete old service-detail records if no longer needed.

### Issue: Import Fails with Field-Level Security Error

**Symptoms:**
- Error: "Unable to create/update fields: [field_name]"
- Import succeeds partially but fails on certain records

**Cause:**
- Formula fields included in import CSV
- Read-only fields in CSV

**Solution:**
Remove these columns from CSV:
- Revenue_Variance__c
- Margin_Variance__c
- Budgeted_Gross__c
- Actual_Gross__c
- Any field marked as Formula or Read-Only

### Issue: Dashboards Show Reduced Actuals After Import

**Symptoms:**
- Actual_Revenue__c decreased after importing new budgets
- Historical performance data appears lost

**Cause:**
- Used DELETE + INSERT approach instead of UPDATE
- New records imported with blank Actual fields

**Solution:**
1. Immediately restore from most recent backup (see Restoration Procedures)
2. Use UPDATE approach for future budget refreshes
3. Wait for batch job to repopulate Actual fields (may take 4-8 hours)

---

## Reference Files

### Source Documentation Files
Located in: `/home/john/Projects/Salesforce/deployment-execution/36-kam-budget-management/source-docs/`

- `KAM_BUDGET_BACKUP_README.txt` - Original backup documentation
- `KAM_BUDGET_IMPLEMENTATION_GUIDE.md` - Step-by-step implementation guide
- `JW FY26 Budget.xlsx` - Jan Ward's budget template
- `KA FY26 Budget.xlsx` - Katie Alexander's budget template

### Data Files
Located in: `/home/john/Projects/Salesforce/`

- `KAM_Budget_BACKUP_20251030_115341.csv` - Full system backup (6,004 records)
- `KAM_Budget_BACKUP_20251030_195700.csv` - Post-restoration backup
- `Jan_Ward_Budget_FY26_IMPORT_CORRECTED.csv` - Jan Ward import file (240 records)
- `Katie_Alexander_Budget_FY26_IMPORT_CORRECTED.csv` - Katie Alexander import file (240 records)

### Scripts
Located in: `/home/john/Projects/Salesforce/`

- `prepare_budget_import_FIXED.py` - Convert Excel budgets to Salesforce CSV format
- `delete_old_kam_budgets.sh` - Bulk delete script with safety confirmation

---

## System Statistics

**As of October 30, 2025:**

| Metric | Value |
|--------|-------|
| Total KAM Budget Records | 6,004 |
| Budget Owners | 3 (Elliot, Jan, Katie) |
| Elliot Harrison-Holt Records | 5,608 (93.4%) |
| Jan Ward Records | 396 (6.6%) |
| Katie Alexander Records | 0 (planned 240) |
| Period Coverage | Jan 2025 - Feb 2026 |
| Service Groups | ALL, Skip, RO/RO, Skips, etc. |
| Accounts with Budgets | ~100+ unique accounts |
| Batch Job Runs Per Day | 3 (weekdays only) |
| Last 6 Months Processing | Automated |
| Historical Data (>6 months) | Static (not updated) |

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-10-30 | Initial documentation created | John Shintu |
| 2025-10-30 | Full backup created (115341) | John Shintu |
| 2025-10-30 | Data restoration from backup completed | John Shintu |
| 2025-10-30 | Post-restoration backup created (195700) | John Shintu |
| 2025-10-30 | Comprehensive master documentation completed | John Shintu |

---

## Related Documentation

- **Salesforce_OldOrg_State Repository:** Complete org documentation and analysis
- **APEX_DEPLOYMENT_REFERENCE_GUIDE.md:** Apex class deployment procedures
- **FLS_VERIFICATION_GUIDE.md:** Field-Level Security setup guide

---

## Support

**For questions or assistance:**

**Technical Contact:** John Shintu
**Email:** shintu.john@recyclinglives-services.com
**Working Directory:** `/home/john/Projects/Salesforce/deployment-execution/36-kam-budget-management/`

**Business Owners:**
- Elliot Harrison-Holt (Primary KAM Budget Owner)
- Jan Ward (KAM)
- Katie Alexander (KAM)

---

**Last Updated:** October 30, 2025
**Document Version:** 1.0
**Status:** Complete
