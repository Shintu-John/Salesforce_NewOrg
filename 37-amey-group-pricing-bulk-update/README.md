# Amey Group Pricing Bulk Update - Implementation Plan

**Created:** 2025-10-31
**Completed:** 2025-10-31
**Scenario Type:** 🚀 Deployment (Bulk Data Update)
**Scenario Number:** 37
**Target Organizations:** OldOrg ✅ COMPLETED | NewOrg ⏳ Pending
**Status:** ✅ OldOrg Update Complete

[![Type](https://img.shields.io/badge/Type-Deployment-blue)](https://github.com/Shintu-John/Salesforce_NewOrg)
[![Status](https://img.shields.io/badge/Status-Completed-green)](https://github.com/Shintu-John/Salesforce_NewOrg)

---

## Executive Summary

**What This Updates:** Bulk pricing update for 900 Order Products across 5 Amey Group accounts (OldOrg)

**Business Problem:** Annual pricing review requires updating sales prices, transport charges, and tonnage rates for all Amey Group contracts effective November 1, 2025.

**Solution:** Bulk data update using Data Loader to update OrderItem (Order Product) records in OldOrg with new pricing rates.

**⚠️ IMPORTANT NOTE:** NewOrg update is **PENDING** - Order Product Numbers differ between orgs. NewOrg requires composite key matching (PO Number + Site + Product) and will be handled in a separate future scenario.

**Business Impact:**
- Updates pricing for 900 Order Products across 281 Orders
- Affects 5 Amey Group accounts (AMEY RAIL, AMEY OW, Amey Infrastructure Wales, AMEY LG, Amey Public Services)
- Ensures accurate invoicing from November 1, 2025 onwards
- No service disruption - purely data update

**Deployment Timeline:** November 1, 2025 (before month-end billing cycle)

---

## ⚠️ OldOrg vs NewOrg Update Strategy

### Current Status (As of 2025-10-31 14:30)

**OldOrg:** ✅ UPDATE COMPLETE
- All 900 Order Products updated successfully (100% success rate)
- Bulk Job ID: 750Sj00000Ll865IAB
- Verification: 10 sample records confirmed correct pricing
- Execution time: ~10 seconds
- Zero failed records

**NewOrg:** ⏳ PENDING (Future Scenario)
- Only 265/900 Order Products exist (29.4%)
- Order Product Numbers **DIFFER** from OldOrg (auto-generated)
- Excel file Order Product Numbers match OldOrg, not NewOrg
- Requires **composite key matching** for the 265 that exist

### Why This Approach?

The master pricing report was generated from **OldOrg**, so all Order Product Numbers in the Excel file correspond to OldOrg records. When these same Orders were migrated to NewOrg, Salesforce generated **different** Order Product Numbers.

**Matching Strategy:**
- **OldOrg:** Use `OrderItemNumber` (direct match) ✅
- **NewOrg:** Requires composite key (`PO Number` + `Site Name` + `Product Name` + `Waste Type`) ⏳

### Next Steps for NewOrg

1. Wait for more Order Products to be migrated (currently 635 missing)
2. Create separate scenario with composite key matching logic
3. Query NewOrg using composite keys to find matching OrderItem IDs
4. Generate NewOrg-specific CSV with correct IDs
5. Apply pricing updates

**Estimated Effort:** Medium complexity (composite key matching + validation)

---

## Business Requirements

### Problem Statement

The Amey Group contracts require annual pricing updates effective November 1, 2025. A master pricing report has been generated containing updated rates for:
- Sales Price (primary service charge)
- Sales Transport (transport charges where applicable)
- Sales Tonnage charge thereafter (per-tonne charges for variable pricing)

These updates must be applied to both OldOrg (current production) and NewOrg (migration target) to ensure consistency during the migration period.

### Acceptance Criteria

**This update is successful when:**
- [ ] All 900 Order Products updated in OldOrg
- [ ] All 900 Order Products updated in NewOrg
- [ ] Pricing matches master pricing report exactly
- [ ] Verification queries confirm correct pricing
- [ ] No unintended records modified
- [ ] Backup/rollback data captured before update
- [ ] Audit trail documented in DEPLOYMENT_HISTORY.md

### Affected Users

**Who will be impacted:**
- **Finance Team:** Accurate invoicing with new rates from Nov 1
- **Account Managers:** Visibility into updated pricing for customer queries
- **Billing System:** Automatic calculation using new rates

**User Impact:**
- No UI changes - purely backend data update
- Existing Orders continue to function normally
- Reports and dashboards show updated pricing immediately

---

## Technical Design

### Data Update Scope

**Source File:** `/home/john/Projects/Salesforce/Documentation/Amey Group   Master Pricing Report-2025-10-31-12-57-26.xlsx`

**Records to Update:** 900 Order Products (OrderItem records)

**Accounts Affected:**
- AMEY RAIL LIMITED: 379 Order Products
- AMEY OW LIMITED: 289 Order Products
- Amey Infrastructure Wales Limited: 104 Order Products
- AMEY LG LIMITED: 80 Order Products
- Amey Public Services LLP: 48 Order Products

**Orders Affected:** 281 unique Orders (PO Numbers)

---

### Fields to Update

| Salesforce Field API Name | Label | Excel Column | Update Count | Type |
|---------------------------|-------|--------------|--------------|------|
| `Sales_Price__c` | Sales Price | New sales price Nov 1 | 900 records | Currency |
| `Sales_Transport__c` | Sales Transport | New Sales transpot Nov 1 | ~36 records | Currency |
| `Sales_Tonnage_charge_thereafter__c` | Sales Tonnage charge thereafter | New sales tonnage charge thereafter Nov 1 | ~236 records | Currency |

**Key Points:**
- All 900 records have updated `Sales_Price__c`
- Only subset have updated transport and tonnage charges (where applicable)
- Records identified by `Order Product Number` (matches OrderItem.Name in Salesforce)

---

### Pricing Methods Breakdown

| Pricing Method | Count | Description |
|---------------|-------|-------------|
| Fixed | 624 records | Fixed price per service |
| Variable | 239 records | Price varies by tonnage (uses tonnage charge) |
| Rebate | 37 records | Rebate pricing model |

---

## Gap Analysis

### Current State

**OldOrg & NewOrg Current Pricing:**
- Pricing effective prior to November 1, 2025
- Stored in OrderItem custom fields: `Sales_Price__c`, `Sales_Transport__c`, `Sales_Tonnage_charge_thereafter__c`

**Limitations:**
- Pricing out of date as of Nov 1, 2025
- Manual update required for 900+ records
- Risk of invoice calculation errors if not updated

---

### Desired State

**NewOrg & OldOrg Updated Pricing:**
- New pricing effective November 1, 2025
- All 900 Order Products reflect current rates
- Consistent pricing across both orgs during migration period

**Improvements:**
- Accurate billing from November 1 onwards
- Consistent pricing data in both environments
- Documented audit trail of pricing changes

---

### Changes Required

| Component | Current State | New State | Change Type |
|-----------|--------------|-----------|-------------|
| OrderItem.Sales_Price__c | Pre-Nov rates | Nov 1, 2025 rates | Bulk Update |
| OrderItem.Sales_Transport__c | Pre-Nov rates (where applicable) | Nov 1, 2025 rates | Bulk Update |
| OrderItem.Sales_Tonnage_charge_thereafter__c | Pre-Nov rates (where applicable) | Nov 1, 2025 rates | Bulk Update |

---

## Implementation Approach

### Phase 1: Data Preparation

**Tasks:**
- [x] Receive master pricing report (Excel)
- [x] Analyze data structure and validate counts
- [ ] Extract OrderItem data from OldOrg
- [ ] Extract OrderItem data from NewOrg
- [ ] Create CSV update files with new pricing
- [ ] Validate CSV format and field mapping
- [ ] Create backup CSV of current pricing

**Estimated Time:** 2 hours

**Output:**
- `data/amey-pricing-update-oldorg.csv` - Update file for OldOrg
- `data/amey-pricing-update-neworg.csv` - Update file for NewOrg
- `data/amey-pricing-backup-oldorg.csv` - Backup of current OldOrg pricing
- `data/amey-pricing-backup-neworg.csv` - Backup of current NewOrg pricing

---

### Phase 2: Data Validation

**Tasks:**
- [ ] Verify all 900 Order Product Numbers exist in both orgs
- [ ] Check for any missing or extra records
- [ ] Validate pricing values are numeric and reasonable
- [ ] Cross-check against master pricing report
- [ ] Review records with NULL transport/tonnage (expected behavior)
- [ ] Create validation queries for post-update verification

**Estimated Time:** 1 hour

**Validation Queries:**
```sql
-- Query to verify Order Product Numbers exist
SELECT Id, Name, Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c
FROM OrderItem
WHERE Name IN ('0000060338', '0000060339', ...) -- List from Excel

-- Count query
SELECT COUNT() FROM OrderItem WHERE Name IN (...)
```

---

### Phase 3: OldOrg Update (Test First)

**Tasks:**
- [ ] Backup current pricing data (CSV export)
- [ ] Review backup for completeness
- [ ] Load update CSV via Data Loader (OldOrg)
- [ ] Review Data Loader success/error logs
- [ ] Run verification queries
- [ ] Spot-check 10-20 records manually in UI
- [ ] Compare results against master pricing report
- [ ] Document any errors or discrepancies

**Command (Data Loader CLI):**
```bash
# Backup current data
sf data query --query "SELECT Id, Name, Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c FROM OrderItem WHERE Order.Account.Name LIKE 'AMEY%' OR Order.Account.Name LIKE 'Amey%'" --target-org OldOrg --result-format csv > data/amey-pricing-backup-oldorg.csv

# Update data
sf data import bulk:upsert --sobject OrderItem --file data/amey-pricing-update-oldorg.csv --external-id Id --target-org OldOrg
```

**Estimated Time:** 1 hour

---

### Phase 4: NewOrg Update (After OldOrg Verification)

**Tasks:**
- [ ] Verify OldOrg update was successful
- [ ] Backup current NewOrg pricing data (CSV export)
- [ ] Review backup for completeness
- [ ] Load update CSV via Data Loader (NewOrg)
- [ ] Review Data Loader success/error logs
- [ ] Run verification queries
- [ ] Spot-check 10-20 records manually in UI
- [ ] Compare results against master pricing report
- [ ] Document any errors or discrepancies

**Command (Data Loader CLI):**
```bash
# Backup current data
sf data query --query "SELECT Id, Name, Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c FROM OrderItem WHERE Order.Account.Name LIKE 'AMEY%' OR Order.Account.Name LIKE 'Amey%'" --target-org NewOrg --result-format csv > data/amey-pricing-backup-neworg.csv

# Update data
sf data import bulk:upsert --sobject OrderItem --file data/amey-pricing-update-neworg.csv --external-id Id --target-org NewOrg
```

**Estimated Time:** 1 hour

---

### Phase 5: Post-Update Verification

**Tasks:**
- [ ] Run comprehensive verification queries (both orgs)
- [ ] Generate verification report comparing Excel vs Salesforce
- [ ] Verify record counts match expected (900 records)
- [ ] Spot-check random sample of 20 records
- [ ] Check for any unintended updates to other accounts
- [ ] Verify Date fields not impacted (if any)
- [ ] Create summary of changes applied

**Verification Queries:**
```sql
-- Verify all Amey Group Order Products
SELECT COUNT() FROM OrderItem
WHERE Order.Account.Name LIKE 'AMEY%' OR Order.Account.Name LIKE 'Amey%'

-- Check specific Order Product
SELECT Name, Sales_Price__c, Sales_Transport__c, Sales_Tonnage_charge_thereafter__c, LastModifiedDate
FROM OrderItem
WHERE Name = '0000060338'

-- Find any recent updates to non-Amey accounts (should be 0)
SELECT COUNT() FROM OrderItem
WHERE LastModifiedDate = TODAY
AND Order.Account.Name NOT LIKE 'AMEY%'
AND Order.Account.Name NOT LIKE 'Amey%'
```

**Estimated Time:** 1 hour

---

### Phase 6: Documentation

**Tasks:**
- [ ] Complete DEPLOYMENT_HISTORY.md with update details
- [ ] Document verification results
- [ ] Update this README with final status
- [ ] Create summary report for stakeholders
- [ ] Update main README.md
- [ ] Commit all documentation to git

**Estimated Time:** 30 minutes

---

## Data Preparation Script

**Location:** `scripts/prepare_pricing_update.py`

**Purpose:**
- Reads master pricing Excel file
- Queries OldOrg and NewOrg for current OrderItem IDs
- Generates CSV files for Data Loader update
- Creates backup CSV files

**Usage:**
```bash
cd /home/john/Projects/Salesforce/deployment-execution/37-amey-group-pricing-bulk-update
python3 scripts/prepare_pricing_update.py
```

**Output:**
- Validation report showing matched/unmatched records
- CSV files ready for Data Loader import

---

## Testing Strategy

### Pre-Update Validation

**Validation Checks:**
- [ ] All 900 Order Product Numbers exist in both OldOrg and NewOrg
- [ ] No duplicate Order Product Numbers in update file
- [ ] All pricing values are positive numbers
- [ ] CSV file format matches Salesforce field requirements
- [ ] External ID (Id field) correctly mapped

---

### Post-Update Verification

**Test Scenarios:**

| # | Scenario | Expected Result | Verification Method |
|---|----------|----------------|---------------------|
| 1 | All 900 records updated | COUNT() = 900 for both orgs | SOQL query |
| 2 | Sales_Price__c updated correctly | Matches Excel "New sales price Nov 1" | Spot-check 20 records |
| 3 | Sales_Transport__c updated where applicable | Matches Excel where provided | Query records with transport |
| 4 | Sales_Tonnage_charge_thereafter__c updated | Matches Excel where provided | Query records with tonnage |
| 5 | No other accounts affected | LastModifiedDate check | SOQL query for non-Amey accounts |
| 6 | Record IDs unchanged | Id field same before/after | Compare backup vs current |

**Test Data:** Random sample of 20 Order Product Numbers for manual verification

---

## Risk Assessment

### Potential Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Order Product Number mismatch | Low | High | Pre-validate all IDs exist in both orgs before update |
| Incorrect pricing applied | Low | High | Automated validation script compares Excel vs CSV |
| Wrong records updated | Low | Critical | Filter by Order Product Number only (900 specific records) |
| Data Loader failure | Low | Medium | Have backup CSV ready for immediate rollback |
| Decimal precision issues | Low | Medium | Validate currency field precision (2 decimals) |
| Update during active billing cycle | Medium | High | Schedule update for off-peak hours, coordinate with Finance |

---

### Rollback Plan

**If update fails or incorrect pricing applied:**

**Step 1: Immediate Action**
- Stop any further updates
- Document the error/issue discovered
- Notify Finance team of potential impact

**Step 2: Rollback Procedure**
```bash
# Restore OldOrg from backup
sf data import bulk:upsert --sobject OrderItem --file data/amey-pricing-backup-oldorg.csv --external-id Id --target-org OldOrg

# Restore NewOrg from backup
sf data import bulk:upsert --sobject OrderItem --file data/amey-pricing-backup-neworg.csv --external-id Id --target-org NewOrg
```

**Step 3: Root Cause Analysis**
- Review Data Loader logs for errors
- Compare CSV files against master Excel
- Identify what went wrong
- Fix issue and re-run update

**Recovery Time:** ~30 minutes (time to restore from backup)

---

## Security Considerations

### Data Security

**Sensitive Data:**
- [x] NO deployment of code (data update only)
- [x] NO credential exposure (using sf CLI authentication)
- [x] Pricing data is business-sensitive but not PII
- [x] CSV files contain Order Product Numbers and pricing (business data)

**Access Control:**
- Update performed by System Administrator
- No changes to sharing rules or permissions
- OrderItem records inherit existing access controls

---

### Audit Trail

**Tracking Changes:**
- LastModifiedDate automatically updated on all records
- LastModifiedById will show who performed update
- Backup CSV files preserve pre-update state
- DEPLOYMENT_HISTORY.md documents full audit trail

---

## Performance Considerations

### Bulk Update Performance

**Data Loader Bulk API:**
- Handles 900 records efficiently
- Uses Bulk API 2.0 for optimal performance
- Expected completion time: < 5 minutes per org

**Governor Limits:**
- No Apex triggers involved (direct data update)
- No DML limits (Bulk API operates outside limits)
- No SOQL concerns (data loaded via CSV)

---

### Optimization

**Performance optimizations:**
- Using Bulk API 2.0 instead of SOAP API
- CSV batch size optimized for Data Loader
- Updates performed during off-peak hours
- Parallel updates (OldOrg first, then NewOrg)

---

## Timeline

| Phase | Duration | Depends On |
|-------|----------|------------|
| Data Preparation | 2 hours | Excel file provided |
| Data Validation | 1 hour | CSV files created |
| OldOrg Update | 1 hour | Validation complete |
| NewOrg Update | 1 hour | OldOrg verified |
| Post-Update Verification | 1 hour | Both updates complete |
| Documentation | 30 min | Verification complete |
| **TOTAL** | **6.5 hours** | |

**Target Deployment Date:** November 1, 2025 (before 10 AM)

---

## Success Criteria

**Update is complete when:**
- ✅ All 900 Order Products updated in OldOrg
- ✅ All 900 Order Products updated in NewOrg
- ✅ Verification queries confirm pricing matches Excel
- ✅ Spot-checks validate accuracy (20 random records)
- ✅ No unintended records modified
- ✅ Backup files created and verified
- ✅ Data Loader logs show 100% success
- ✅ Documentation complete (DEPLOYMENT_HISTORY.md)
- ✅ Git committed to feature branch
- ✅ Stakeholders notified of completion

---

## Post-Deployment

### Monitoring

**What to monitor after update:**
- Invoice generation on November 1 (verify correct pricing used)
- Finance team feedback on pricing accuracy
- Any customer inquiries about pricing changes
- System performance (should be unaffected)

**Monitoring Period:** First 2 weeks of November 2025

---

### Known Issues / Limitations

**Current known issues:**
- None at this time

**Future Enhancements:**
- Consider automated pricing update process for future annual reviews
- Explore Price Book integration for more maintainable pricing
- Evaluate need for pricing change audit history object

---

## Deployment Results Summary

### OldOrg Update - COMPLETED ✅

**Execution Date:** 2025-10-31 14:20
**Bulk Job ID:** 750Sj00000Ll865IAB
**Total Records:** 900 Order Products
**Success Rate:** 100% (900/900 records updated successfully)
**Failed Records:** 0
**Execution Time:** ~10 seconds

**Verification:** 10 sample records manually verified - all matched update CSV pricing exactly

**Key Files:**
- Backup: [data/amey-pricing-backup-oldorg.csv](data/amey-pricing-backup-oldorg.csv)
- Update: [data/amey-pricing-update-oldorg.csv](data/amey-pricing-update-oldorg.csv)

### NewOrg Update - PENDING ⏳

**Status:** Deferred to future scenario
**Reason:** Order Product Numbers differ between orgs (auto-generated by Salesforce)
**Solution Required:** Composite key matching (PO Number + Site + Product + Waste Type)
**Records Affected:** 265 Order Products (29.4% of 900 total)

---

## Related Documentation

- **Deployment History:** [DEPLOYMENT_HISTORY.md](./DEPLOYMENT_HISTORY.md) - Complete execution details and technical learnings
- **Verification Methodology:** [VERIFICATION_METHODOLOGY.md](./VERIFICATION_METHODOLOGY.md) - Verification guide for future bulk updates
- **Master Pricing Report:** `/home/john/Projects/Salesforce/Documentation/Amey Group   Master Pricing Report-2025-10-31-12-57-26.xlsx`
- **Data Preparation Script:** [scripts/prepare_pricing_update.py](./scripts/prepare_pricing_update.py)
- **Update CSV Files:** [data/](./data/) directory
- **New Scenario Guide:** [../Documentation/NEW_SCENARIO_GUIDE.md](../Documentation/NEW_SCENARIO_GUIDE.md)

---

## Contact

**Developer:** John Shintu
**Email:** shintu.john@recyclinglives.com
**Date Created:** October 31, 2025

---

## Status History

| Date | Status | Notes |
|------|--------|-------|
| 2025-10-31 13:15 | ⏳ Planning | Scenario created, analyzing master pricing report |
| 2025-10-31 13:30 | 🔨 Development | Data preparation script developed |
| 2025-10-31 14:00 | 🧪 Preparation | CSV files generated and pre-verified |
| 2025-10-31 14:20 | 🚀 Executing | Bulk update executed in OldOrg |
| 2025-10-31 14:25 | ✅ Verification | Post-update verification completed (10 samples) |
| 2025-10-31 14:30 | ✅ Complete | OldOrg update complete, documentation finished |

---

**End of Implementation Plan**
