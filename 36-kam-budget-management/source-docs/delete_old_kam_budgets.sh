#!/bin/bash

# Script to delete old KAM Budget records before importing FY25/26 reforecast
# Date: 2025-10-30

echo "=========================================="
echo "DELETE OLD KAM BUDGET RECORDS"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete existing KAM Budget records."
echo "Backup file: KAM_Budget_BACKUP_20251030_115341.xlsx"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deletion cancelled."
    exit 0
fi

echo ""
echo "Step 1: Deleting Jan Ward's 396 KAM Budget records..."
echo "Date range: 2025-03-01 to 2026-02-01"

sf data query --query "SELECT Id FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Jan Ward' AND Period__c >= 2025-03-01 AND Period__c <= 2026-02-01" --target-org OldOrg --result-format csv > /tmp/jan_ward_delete_ids.csv

# Count records to delete
JAN_COUNT=$(tail -n +2 /tmp/jan_ward_delete_ids.csv | wc -l)
echo "Found $JAN_COUNT records to delete for Jan Ward"

if [ $JAN_COUNT -gt 0 ]; then
    sf data delete bulk --file /tmp/jan_ward_delete_ids.csv --sobject Management_Information__c --target-org OldOrg --wait 10
    echo "✅ Jan Ward records deleted"
else
    echo "⚠️  No Jan Ward records found to delete"
fi

echo ""
echo "Step 2: Deleting Katie Alexander's accounts (648 records currently under Elliot)..."
echo "Accounts: Amey Group PLC, OPENREACH LIMITED, CBRE, Citizen, BAM Nuttall, etc."
echo "Date range: 2025-01-01 to 2026-02-01"

sf data query --query "SELECT Id FROM Management_Information__c WHERE Type__c = 'KAM Budget' AND Budget_Owner__r.Name = 'Elliot Harrison-Holt' AND Period__c >= 2025-01-01 AND Period__c <= 2026-02-01 AND Account__r.Name IN ('Amey Group PLC','OPENREACH LIMITED','CBRE MANAGED SERVICES LIMITED','Citizen','BAM Nuttall','Amey Infrastructure Wales Limited','Novus Property Solutions','Aureos Group','SIGMA RETAIL SOLUTIONS LIMITED')" --target-org OldOrg --result-format csv > /tmp/katie_accounts_delete_ids.csv

# Count records to delete
KATIE_COUNT=$(tail -n +2 /tmp/katie_accounts_delete_ids.csv | wc -l)
echo "Found $KATIE_COUNT records to delete for Katie's accounts"

if [ $KATIE_COUNT -gt 0 ]; then
    sf data delete bulk --file /tmp/katie_accounts_delete_ids.csv --sobject Management_Information__c --target-org OldOrg --wait 10
    echo "✅ Katie's account records deleted"
else
    echo "⚠️  No Katie account records found to delete"
fi

echo ""
echo "=========================================="
echo "DELETION COMPLETE"
echo "=========================================="
echo "Jan Ward records deleted: $JAN_COUNT"
echo "Katie account records deleted: $KATIE_COUNT"
echo "Total deleted: $((JAN_COUNT + KATIE_COUNT))"
echo ""
echo "✅ Ready for new budget import!"
echo "Next step: Run prepare_budget_import.py"

