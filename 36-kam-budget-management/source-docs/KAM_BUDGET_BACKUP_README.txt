============================================================
KAM BUDGET DATA BACKUP - BEFORE REFORECAST UPDATE
============================================================
Date: 2025-10-30
Backup File: KAM_Budget_BACKUP_20251030_115341.xlsx / .csv

PURPOSE:
--------
This is a complete backup of all KAM Budget records before updating 
with the FY25/26 reforecast data from the new Excel budgets.

CURRENT DATA SUMMARY:
--------------------
Total Records: 6,004 KAM Budget records

By Budget Owner:
- Elliot Harrison-Holt: 5,608 records
  └─ Includes 648 records for Katie Alexander's accounts
  └─ Katie's accounts: Amey Group PLC, OPENREACH LIMITED, CBRE MANAGED SERVICES LIMITED,
     Citizen, BAM Nuttall, Amey Infrastructure Wales Limited, Novus Property Solutions,
     Aureos Group, SIGMA RETAIL SOLUTIONS LIMITED

- Jan Ward: 396 records
  └─ Covers: Mar 2025 - Feb 2026
  └─ 13 unique accounts with service line breakdown

PLANNED CHANGES:
---------------
1. DELETE Jan Ward's 396 existing records (old budget)
   - Old data shows higher values (e.g., Vinci £120k vs new £94k)
   - Reforecast has revised targets without service line breakdown

2. UPDATE Budget Owner for Katie Alexander's 648 records
   - Change from "Elliot Harrison-Holt" to "Katie Alexander"
   - OR DELETE and re-import with Katie as owner

3. IMPORT new budget data:
   - Jan Ward: 156 new records (13 accounts × 12 months, Service_Group = 'ALL')
   - Katie Alexander: 312 new records (26 accounts × 12 months, Service_Group = 'ALL')

WHY DELETE INSTEAD OF UPDATE:
-----------------------------
- Existing reports have NO Service Group filter
- Reports SUM all records per account/month
- Current data: Multiple service records per account (Skip, RO/RO, etc.)
- New data: Single consolidated total per account
- Adding without deleting would cause DOUBLE COUNTING

RESTORATION:
-----------
If you need to restore the old data, use this backup file with Data Loader:
1. Delete the new records
2. Import this backup CSV file
3. All record IDs and relationships will be restored

CONTACT:
--------
For questions about this backup, contact:
- John Shintu (john.shintu@recyclinglives-services.com)
- Elliot Harrison-Holt (original requestor)

============================================================
