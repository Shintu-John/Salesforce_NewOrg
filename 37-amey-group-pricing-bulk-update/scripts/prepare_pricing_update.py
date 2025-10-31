#!/usr/bin/env python3
"""
Amey Group Pricing Update - Data Preparation Script

This script:
1. Reads the master pricing Excel file
2. Queries OldOrg and NewOrg for current OrderItem records
3. Generates CSV files for Data Loader bulk update
4. Creates backup CSV files of current pricing
5. Validates data and generates report

Usage:
    python3 prepare_pricing_update.py

Author: John Shintu
Date: 2025-10-31
"""

import pandas as pd
import subprocess
import json
import sys
from datetime import datetime
from pathlib import Path

# Configuration
EXCEL_FILE = "/home/john/Projects/Salesforce/Documentation/Amey Group   Master Pricing Report-2025-10-31-12-57-26.xlsx"
DATA_DIR = Path(__file__).parent.parent / "data"
OLDORG_ALIAS = "OldOrg"
NEWORG_ALIAS = "NewOrg"

# Field mapping
FIELDS_TO_UPDATE = {
    'Sales_Price__c': 'New sales price Nov 1',
    'Sales_Transport__c': 'New Sales transpot Nov 1',
    'Sales_Tonnage_charge_thereafter__c': 'New sales tonnage charge thereafter Nov 1'
}


def print_section(title):
    """Print formatted section header"""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print(f"{'='*70}\n")


def load_excel_data():
    """Load and parse the master pricing Excel file"""
    print_section("STEP 1: Loading Master Pricing Excel File")

    try:
        # Read Excel file (header is on row 1, 0-indexed)
        df = pd.read_excel(EXCEL_FILE, sheet_name=0, header=0)

        print(f"✓ Loaded Excel file: {EXCEL_FILE}")
        print(f"✓ Total rows: {len(df)}")
        print(f"✓ Columns: {list(df.columns)}")

        # Validate expected columns exist
        required_cols = ['Order Product Number'] + list(FIELDS_TO_UPDATE.values())
        missing_cols = [col for col in required_cols if col not in df.columns]

        if missing_cols:
            print(f"\n❌ ERROR: Missing required columns: {missing_cols}")
            sys.exit(1)

        # Filter out any rows with NULL Order Product Number
        valid_df = df[df['Order Product Number'].notna()].copy()

        print(f"✓ Valid Order Products: {len(valid_df)}")
        print(f"✓ Expected: 900 Order Products")

        if len(valid_df) != 900:
            print(f"\n⚠️  WARNING: Expected 900 records, found {len(valid_df)}")

        return valid_df

    except Exception as e:
        print(f"\n❌ ERROR loading Excel file: {e}")
        sys.exit(1)


def query_salesforce_org(org_alias, order_product_numbers):
    """Query Salesforce org for OrderItem records"""
    print(f"\n  Querying {org_alias}...")

    # Build SOQL query with IN clause for Order Product Numbers
    order_product_list = "','".join([str(num) for num in order_product_numbers])

    query = f"""
    SELECT Id, Name, Sales_Price__c, Sales_Transport__c,
           Sales_Tonnage_charge_thereafter__c, Order.Account.Name
    FROM OrderItem
    WHERE Name IN ('{order_product_list}')
    """

    try:
        # Execute query using sf CLI
        result = subprocess.run(
            ['sf', 'data', 'query', '--query', query, '--target-org', org_alias, '--json'],
            capture_output=True,
            text=True,
            timeout=120
        )

        if result.returncode != 0:
            print(f"  ❌ ERROR querying {org_alias}: {result.stderr}")
            return None

        # Parse JSON response
        data = json.loads(result.stdout)

        if data['status'] != 0:
            print(f"  ❌ ERROR: Query failed with status {data['status']}")
            return None

        records = data['result']['records']

        print(f"  ✓ Found {len(records)} records in {org_alias}")

        # Convert to DataFrame
        df = pd.DataFrame(records)

        # Remove 'attributes' column if it exists
        if 'attributes' in df.columns:
            df = df.drop('attributes', axis=1)

        return df

    except subprocess.TimeoutExpired:
        print(f"  ❌ ERROR: Query timed out for {org_alias}")
        return None
    except Exception as e:
        print(f"  ❌ ERROR querying {org_alias}: {e}")
        return None


def fetch_current_pricing(excel_df):
    """Fetch current pricing from both OldOrg and NewOrg"""
    print_section("STEP 2: Fetching Current Pricing from Salesforce")

    order_product_numbers = excel_df['Order Product Number'].tolist()

    print(f"Querying for {len(order_product_numbers)} Order Products...")

    # Query both orgs
    oldorg_df = query_salesforce_org(OLDORG_ALIAS, order_product_numbers)
    neworg_df = query_salesforce_org(NEWORG_ALIAS, order_product_numbers)

    if oldorg_df is None or neworg_df is None:
        print("\n❌ ERROR: Failed to fetch data from one or both orgs")
        sys.exit(1)

    print(f"\n✓ OldOrg: {len(oldorg_df)} records retrieved")
    print(f"✓ NewOrg: {len(neworg_df)} records retrieved")

    return oldorg_df, neworg_df


def validate_data(excel_df, oldorg_df, neworg_df):
    """Validate that all Order Products exist in both orgs"""
    print_section("STEP 3: Validating Data")

    excel_products = set(excel_df['Order Product Number'].astype(str))
    oldorg_products = set(oldorg_df['Name'].astype(str))
    neworg_products = set(neworg_df['Name'].astype(str))

    print(f"Excel Order Products: {len(excel_products)}")
    print(f"OldOrg Order Products: {len(oldorg_products)}")
    print(f"NewOrg Order Products: {len(neworg_products)}")

    # Check for missing in OldOrg
    missing_oldorg = excel_products - oldorg_products
    if missing_oldorg:
        print(f"\n⚠️  WARNING: {len(missing_oldorg)} Order Products NOT FOUND in OldOrg:")
        for op in list(missing_oldorg)[:10]:  # Show first 10
            print(f"    - {op}")
        if len(missing_oldorg) > 10:
            print(f"    ... and {len(missing_oldorg) - 10} more")

    # Check for missing in NewOrg
    missing_neworg = excel_products - neworg_products
    if missing_neworg:
        print(f"\n⚠️  WARNING: {len(missing_neworg)} Order Products NOT FOUND in NewOrg:")
        for op in list(missing_neworg)[:10]:  # Show first 10
            print(f"    - {op}")
        if len(missing_neworg) > 10:
            print(f"    ... and {len(missing_neworg) - 10} more")

    # Check for extra in Salesforce (shouldn't happen)
    extra_oldorg = oldorg_products - excel_products
    extra_neworg = neworg_products - excel_products

    if extra_oldorg:
        print(f"\n⚠️  WARNING: {len(extra_oldorg)} extra Order Products in OldOrg (not in Excel)")

    if extra_neworg:
        print(f"\n⚠️  WARNING: {len(extra_neworg)} extra Order Products in NewOrg (not in Excel)")

    # Summary
    matched_oldorg = len(excel_products & oldorg_products)
    matched_neworg = len(excel_products & neworg_products)

    print(f"\n{'─'*70}")
    print(f"VALIDATION SUMMARY:")
    print(f"  OldOrg: {matched_oldorg}/{len(excel_products)} matched ({matched_oldorg/len(excel_products)*100:.1f}%)")
    print(f"  NewOrg: {matched_neworg}/{len(excel_products)} matched ({matched_neworg/len(excel_products)*100:.1f}%)")
    print(f"{'─'*70}")

    if matched_oldorg < len(excel_products) or matched_neworg < len(excel_products):
        print("\n⚠️  WARNING: Not all Order Products found in both orgs!")
        response = input("Continue anyway? (yes/no): ")
        if response.lower() != 'yes':
            print("Aborted by user")
            sys.exit(0)
    else:
        print("\n✓ All Order Products validated successfully!")

    return missing_oldorg, missing_neworg


def create_update_csv(excel_df, salesforce_df, org_alias):
    """Create CSV file for Data Loader update"""
    print(f"\n  Creating update CSV for {org_alias}...")

    # Merge Excel data with Salesforce IDs
    merged_df = salesforce_df.merge(
        excel_df,
        left_on='Name',
        right_on='Order Product Number',
        how='inner'
    )

    print(f"  ✓ Matched {len(merged_df)} records")

    # Create update DataFrame with Id and new pricing fields
    update_df = pd.DataFrame()
    update_df['Id'] = merged_df['Id']

    # Map pricing fields from Excel to Salesforce field names
    for sf_field, excel_col in FIELDS_TO_UPDATE.items():
        update_df[sf_field] = merged_df[excel_col]

    # Count non-null updates per field
    print(f"  Fields to update:")
    for sf_field in FIELDS_TO_UPDATE.keys():
        non_null_count = update_df[sf_field].notna().sum()
        print(f"    - {sf_field}: {non_null_count} records")

    # Save CSV
    csv_filename = DATA_DIR / f"amey-pricing-update-{org_alias.lower()}.csv"
    update_df.to_csv(csv_filename, index=False)

    print(f"  ✓ Saved: {csv_filename}")

    return csv_filename


def create_backup_csv(salesforce_df, org_alias):
    """Create backup CSV of current pricing"""
    print(f"\n  Creating backup CSV for {org_alias}...")

    # Select relevant fields
    backup_df = salesforce_df[['Id', 'Name', 'Sales_Price__c',
                                'Sales_Transport__c',
                                'Sales_Tonnage_charge_thereafter__c']].copy()

    # Save CSV
    csv_filename = DATA_DIR / f"amey-pricing-backup-{org_alias.lower()}.csv"
    backup_df.to_csv(csv_filename, index=False)

    print(f"  ✓ Saved: {csv_filename}")
    print(f"  ✓ Backed up {len(backup_df)} records")

    return csv_filename


def generate_csvs(excel_df, oldorg_df, neworg_df):
    """Generate all CSV files for update and backup"""
    print_section("STEP 4: Generating CSV Files")

    # Ensure data directory exists
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # Create backup CSVs
    print("Creating backup files...")
    oldorg_backup = create_backup_csv(oldorg_df, OLDORG_ALIAS)
    neworg_backup = create_backup_csv(neworg_df, NEWORG_ALIAS)

    # Create update CSVs
    print("\nCreating update files...")
    oldorg_update = create_update_csv(excel_df, oldorg_df, OLDORG_ALIAS)
    neworg_update = create_update_csv(excel_df, neworg_df, NEWORG_ALIAS)

    print(f"\n{'─'*70}")
    print("CSV FILES GENERATED:")
    print(f"  Backup Files:")
    print(f"    - {oldorg_backup}")
    print(f"    - {neworg_backup}")
    print(f"  Update Files:")
    print(f"    - {oldorg_update}")
    print(f"    - {neworg_update}")
    print(f"{'─'*70}")

    return {
        'oldorg_backup': oldorg_backup,
        'neworg_backup': neworg_backup,
        'oldorg_update': oldorg_update,
        'neworg_update': neworg_update
    }


def generate_summary_report(excel_df, oldorg_df, neworg_df, csv_files):
    """Generate summary report"""
    print_section("STEP 5: Summary Report")

    report_file = DATA_DIR / f"pricing-update-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"

    with open(report_file, 'w') as f:
        f.write("AMEY GROUP PRICING UPDATE - PREPARATION REPORT\n")
        f.write("=" * 70 + "\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Excel Source: {EXCEL_FILE}\n\n")

        f.write("DATA SUMMARY:\n")
        f.write(f"  Excel Order Products: {len(excel_df)}\n")
        f.write(f"  OldOrg Records Found: {len(oldorg_df)}\n")
        f.write(f"  NewOrg Records Found: {len(neworg_df)}\n\n")

        f.write("FIELDS TO UPDATE:\n")
        for sf_field, excel_col in FIELDS_TO_UPDATE.items():
            non_null = excel_df[excel_col].notna().sum()
            f.write(f"  {sf_field}: {non_null} records\n")

        f.write("\nACCOUNT BREAKDOWN:\n")
        if 'Order Product : Order : Account Name' in excel_df.columns:
            account_counts = excel_df['Order Product : Order : Account Name'].value_counts()
            for account, count in account_counts.items():
                f.write(f"  {account}: {count} Order Products\n")

        f.write("\nFILES GENERATED:\n")
        for key, filepath in csv_files.items():
            f.write(f"  {key}: {filepath}\n")

        f.write("\nNEXT STEPS:\n")
        f.write("  1. Review generated CSV files\n")
        f.write("  2. Verify backup files contain current pricing\n")
        f.write("  3. Test update in OldOrg first\n")
        f.write("  4. After OldOrg verification, update NewOrg\n")
        f.write("  5. Run post-update verification queries\n")
        f.write("  6. Document results in DEPLOYMENT_HISTORY.md\n")

        f.write("\nDATA LOADER COMMANDS:\n")
        f.write(f"  # Update OldOrg:\n")
        f.write(f"  sf data import bulk:upsert --sobject OrderItem \\\n")
        f.write(f"    --file {csv_files['oldorg_update']} \\\n")
        f.write(f"    --external-id Id \\\n")
        f.write(f"    --target-org {OLDORG_ALIAS}\n\n")

        f.write(f"  # Update NewOrg:\n")
        f.write(f"  sf data import bulk:upsert --sobject OrderItem \\\n")
        f.write(f"    --file {csv_files['neworg_update']} \\\n")
        f.write(f"    --external-id Id \\\n")
        f.write(f"    --target-org {NEWORG_ALIAS}\n")

    print(f"✓ Summary report saved: {report_file}")

    # Also print to console
    with open(report_file, 'r') as f:
        print("\n" + f.read())


def main():
    """Main execution function"""
    print("\n" + "="*70)
    print("  AMEY GROUP PRICING UPDATE - DATA PREPARATION")
    print("="*70)
    print(f"  Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*70)

    try:
        # Step 1: Load Excel
        excel_df = load_excel_data()

        # Step 2: Fetch current pricing
        oldorg_df, neworg_df = fetch_current_pricing(excel_df)

        # Step 3: Validate
        validate_data(excel_df, oldorg_df, neworg_df)

        # Step 4: Generate CSVs
        csv_files = generate_csvs(excel_df, oldorg_df, neworg_df)

        # Step 5: Summary report
        generate_summary_report(excel_df, oldorg_df, neworg_df, csv_files)

        print_section("✓ DATA PREPARATION COMPLETE")
        print("Review the generated files and proceed with the update when ready.")
        print("\nIMPORTANT: Test in OldOrg first, then update NewOrg after verification!")

    except KeyboardInterrupt:
        print("\n\n❌ Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ UNEXPECTED ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
