# Salesforce NewOrg Migration Repository

**Target Organization**: NewOrg (Recycling Lives Group)
**Source Organization**: OldOrg (Recycling Lives Service)
**Purpose**: Migration plans and deployment-ready packages for migrating from OldOrg to NewOrg
**Created**: October 22, 2025
**Status**: 🔄 Fresh Start - Enhanced Workflow Implementation

---

## Repository Purpose

This repository contains **migration plans and deployment packages** for migrating all customizations and features from **OldOrg** (legacy system) to **NewOrg** (future production system).

### Why This Repository Exists

1. **Migration Execution**: Provides step-by-step deployment instructions for each scenario
2. **Gap Analysis**: Documents differences between OldOrg and NewOrg
3. **Deployment Scripts**: Contains ready-to-execute commands for migration (CLI and Manual UI)
4. **Risk Management**: Includes rollback plans and risk mitigation strategies
5. **Quality Assurance**: Provides comprehensive testing and verification procedures

### What This Repository Contains

- **Migration plans** for each scenario (gap analysis, deployment steps, verification)
- **Deployment-ready code** (verified code from OldOrg, ready to deploy to NewOrg)
- **CLI deployment commands** with exact syntax
- **Manual UI instructions** for steps that can't be automated
- **Rollback procedures** for each migration
- **Testing plans** for post-deployment verification
- **Working links** to OldOrg State documentation

---

## Repository Structure

```
Salesforce_NewOrg/
├── README.md (this file)
├── producer-portal/                     ← Each scenario gets its own folder
│   ├── README.md                        ← Complete migration plan with gap analysis
│   ├── source-docs/                     ← Original documentation (archived)
│   │   └── ORIGINAL_DOCS.md
│   └── code/                            ← Deployment-ready code (verified)
│       ├── classes/
│       ├── triggers/
│       ├── flows/
│       └── objects/
├── email-to-case-assignment/            ← Another scenario
│   ├── README.md
│   ├── source-docs/
│   └── code/
└── [more scenarios...]
```

### Folder Naming Convention

- **Matches OldOrg State repo**: Same folder names for easy cross-reference
- **Flat structure**: All scenarios at root level
- **Kebab-case names**: `email-to-case-assignment`, `producer-portal`
- **README.md standard**: Always use README.md (never DEPLOYMENT_VERIFICATION.md or GAP_ANALYSIS.md)

---

## Migration Scenarios

### Status Legend
- ✅ **Ready for Deployment**: Migration plan reviewed and approved, ready to execute
- 🔄 **In Progress**: Migration plan being prepared
- 📋 **Planned**: Not yet started
- 🚀 **Deployed**: Successfully deployed to NewOrg
- ⏸️ **On Hold**: Waiting for dependencies or prerequisites

### Scenario Type Legend
- **Deployment Scenarios**: Code to deploy from OldOrg to NewOrg (bug fixes, new features, enhancements)
- ⚠️ **Configuration Scenarios**: Existing code needs activation/configuration only (NOT new deployments)

---

## Current Scenarios (Fresh Start - Oct 22, 2025)

### Configuration Scenarios (5 Complete ✅)

**Purpose**: Configuration guides for existing systems (NOT code deployments)

| Scenario | Status | Last Updated | Type | Description |
|----------|--------|--------------|------|-------------|
| [smartwaste-integration](smartwaste-integration/) | ✅ Complete | Oct 22, 2025 | Configuration | SmartWaste configuration guide - Activate flows, schedule jobs. No code deployment needed |
| [quote-pricing-notification](quote-pricing-notification/) | ✅ Complete | Oct 22, 2025 | Configuration | Email notification configuration - Manual UI setup for org-wide email address |
| [quote-to-order-process](quote-to-order-process/) | ✅ Complete | Oct 22, 2025 | Training | Quote-to-Order user training - No configuration changes needed |
| [fred-certificate-renewal](fred-certificate-renewal/) | ✅ Complete | Oct 22, 2025 | Configuration | FRED Integration certificate renewal procedure - Certificate management guide |
| [sage-api-integration](sage-api-integration/) | ✅ Complete | Oct 23, 2025 | Configuration/OAuth | Sage API OAuth authentication configuration - Setup → Named Credentials → SIA → Authenticate with NewOrg Sage credentials. Use NewOrg-specific subscription keys, site IDs, company IDs. Test with Anonymous Apex. 60-day re-authentication cycle. Est: 30-45 minutes |

### Deployment Scenarios (12 Ready ✅)

**Purpose**: Deploy code from OldOrg to NewOrg (bug fixes, new features, enhancements).

| Scenario | Status | Last Updated | Gap Analysis | Critical Issues |
|----------|--------|--------------|--------------|-----------------|
| [producer-portal](producer-portal/) | ✅ Ready (⚠️ **CRITICAL**) | Oct 22, 2025 | **15 components analyzed** | 🚨 **NewOrg has OLD BUGGY VERSION** - ProducerPlacedOnMarketTriggerHelper is 35 days out of date (Sept 19 vs Oct 21). **Missing ALL 5 fixes**. 8 components MISSING (sharing solution). **MUST deploy before go-live.** |
| [email-to-case-assignment](email-to-case-assignment/) | ✅ Ready (⚠️ **VERSION MISMATCH**) | Oct 23, 2025 | **13 components analyzed** | ⚠️ **NewOrg has OLD VERSION** - Apex classes are pre-V3 (434 vs 631 lines). Missing SOQL caching, recursion prevention, Kaylie Morris exemption. **3 components MISSING** (Custom Setting, Case field, Flow). **Customer Service workload management - deploy soon.** |
| [invoice-email-portal-access](invoice-email-portal-access/) | ✅ Ready (⚠️ **OUTDATED**) | Oct 23, 2025 | **5 components analyzed** | ⚠️ **NewOrg has OLD VERSION** - 4 of 5 components outdated (Sept 2025 vs Oct 9). InvoiceFileListController missing invoice PDF logic (71 lines). **ContentDistributionHelper already current** (Oct 10). Customers cannot access invoice PDFs on portal. |
| [daily-reminder-emails](daily-reminder-emails/) | ✅ Ready (⚠️ **SEVERELY OUTDATED**) | Oct 23, 2025 | **4 components analyzed** | 🚨 **NewOrg has VERY OLD VERSION** - Sept 17 version (52 lines vs 245 lines). **Entire Tier 1 system MISSING** (JobDeliveryConfirmationReminderBatch). Missing Delivery_Confirmed__c filter, HTML reporting, prioritization. **Sends 556 emails daily instead of 2 reports.** Record locking risk. |
| [portal-exchange-email](portal-exchange-email/) | ✅ Ready (⚠️ **OUTDATED**) | Oct 23, 2025 | **6 components analyzed** | ⚠️ **NewOrg has OUTDATED CODE** - Handler from Oct 2 (14 days old), test from Sept 17 (29 days old). 6 flows need verification for fromEmailAddress parameter. **Customers with strict SPF policies (Amey Highways) cannot submit portal requests.** Emails rejected, no Cases created. |
| [transport-charges](transport-charges/) | ✅ Ready (🚨 **CRITICAL**) | Oct 23, 2025 | **3 bugs + 244 missing lines** | 🚨 **NewOrg has SEVERELY OUTDATED CODE** - Oct 10 version (575 lines vs 819 lines, 5 days behind). **MISSING BOTH CRITICAL FIXES**: Issue 1 missing charges (£919K impact), Issue 3 hybrid calculation bug (£870K impact). Missing secondary transport feature (244 lines). **Financial risk: £1.7M+ if not deployed before go-live.** |
| [cs-invoicing](cs-invoicing/) | ✅ Ready (⚠️ **OUTDATED**) | Oct 23, 2025 | **3 classes + 1 field** | ⚠️ **NewOrg has OLD VERSION** - RLCSChargeService 97 lines (vs 142, 31.7% missing). rlcsJobService 575 lines (vs 819, 29.8% missing). **Collection_Date__c field MISSING**. Missing buildChargeDescription(), inline SOQL performance issue. **Depends on transport-charges** (shared rlcsJobService). CS Invoicing team missing automatic date/description visibility. |
| [secondary-transport](secondary-transport/) | ✅ Ready (🚨 **CRITICAL**) | Oct 23, 2025 | **4 classes + 3 fields + 1 validation** | 🚨 **NewOrg has SEVERELY OUTDATED CODE** - Oct 10 version (575 lines vs 819 lines). **MISSING ALL SECONDARY TRANSPORT LOGIC** (244 lines, 29.8%). Phase 2 CSV mapping fixes MISSING in 3 components (BatchProcessor, Controller, iParserio batch). **CSV columns 14-15 issue - 97 invalid Jobs (£19K-£29K).** NULL weight/units from uploads. **Depends on transport-charges + cs-invoicing** (shared rlcsJobService). |
| [po-consumption-emails](po-consumption-emails/) | ✅ Ready (✅ **CLEAN SLATE**) | Oct 23, 2025 | **13 components analyzed** | ✅ **NewOrg COMPLETELY CLEAN** - 12 of 13 components missing (only pre-existing Order consumption fields exist). **No version conflicts, no outdated code.** Fresh deployment. System currently non-functional in NewOrg. Low risk deployment. |
| [job-charge-credit-on-account](job-charge-credit-on-account/) | ✅ Ready (⚠️ **BUGGY + INACTIVE**) | Oct 23, 2025 | **1 flow + 11 dependencies** | ⚠️ **NewOrg has BUGGY VERSION** - Oct 19 pre-fix version (3 days old). filterLogic shows "1 AND (2 OR 3)" with "Credit on Account" still in filter (line 214). **Flow currently INACTIVE** (IsActive = false) - bug not causing issues yet. **Account IDs updated in deployment package** (3 ID mappings OldOrg→NewOrg). Deploy fix BEFORE activating flow to prevent Cost__c corruption on 263 Credit on Account charges. Low risk - flow inactive. |
| [rlcs-vendor-invoice-sage](rlcs-vendor-invoice-sage/) | ✅ Ready (✅ **ALREADY DEPLOYED**) | Oct 23, 2025 | **2 components + 34 dependencies** | ✅ **NewOrg ALREADY HAS FIX** - Deployed Oct 6, 2025 at 15:34 UTC (45 minutes BEFORE OldOrg). **Test-first deployment strategy.** Both components IDENTICAL to OldOrg. RLCS fields in SOQL query (line 21), CSV button unrestricted (lines 167-179). **1,322 RLCS invoices processed successfully.** Proven stable over 17 days. **NO DEPLOYMENT NEEDED** - documentation serves as historical reference and validates test-first strategy. Zero gap between orgs. |
| [bam-construct-portal-license](bam-construct-portal-license/) | ✅ Ready (⏳ **PENDING**) | Oct 23, 2025 | **4 components analyzed** | ⏳ **NewOrg MISSING ALL COMPONENTS** - Formula field Waste_Carrier_License_Expiry__c MISSING. Job portal layout exists but missing license fields (lines 96-100). Utility_Community.cls exists but missing license SOQL (lines 23, 40-41). depotViewCommunity LWC exists but missing license columns (lines 40-41, 64-72). **4-phase deployment**: CLI field/layout/code + Manual UI user config (Community_Role__c, sharing records). **137 HQ users need compliance visibility.** Risk: LOW (read-only fields). Est: 1.5-2 hours. |

---

## Fresh Start - Enhanced Workflow (Oct 22, 2025)

### Why Fresh Start?

Previous migration plans lacked critical elements:
- ❌ No gap analysis (OldOrg vs NewOrg comparison)
- ❌ No CLI vs Manual UI step distinction
- ❌ Missing pre-deployment environment verification
- ❌ Inconsistent file naming conventions
- ❌ No cross-repo documentation links

### Enhanced Workflow Now Includes

✅ **Complete Gap Analysis**
- Compare OldOrg vs NewOrg for each component
- Identify missing components in NewOrg
- Document version mismatches
- Plan deployment order based on dependencies

✅ **Deployment Step Clarity**
- **✅ CLI Steps**: Exact commands with verification queries
- **⚠️ Manual UI Steps**: Step-by-step UI instructions with screenshots/verification

✅ **Pre-Deployment Verification**
- Environment checks before deployment
- Prerequisite validation
- Data backup recommendations

✅ **Professional Documentation Standards**
- ALWAYS use README.md (never DEPLOYMENT_VERIFICATION.md or GAP_ANALYSIS.md)
- No AI references in commits or documentation
- Working GitHub links to OldOrg State documentation
- Clear rollback procedures

✅ **Verified Deployment-Ready Code**
- Code verified line-by-line against OldOrg
- Complete dependency analysis
- All referenced components included

---

## How to Use This Repository

### For Migration Execution

1. **Review OldOrg State**: Check companion repo to understand current implementation
2. **Review Migration Plan**: Read scenario README.md for gap analysis and steps
3. **Pre-Deployment Verification**: Run environment checks
4. **Execute CLI Steps**: Run automated deployment commands
5. **Execute Manual UI Steps**: Follow step-by-step UI instructions
6. **Post-Deployment Testing**: Verify deployment success
7. **Update Progress**: Mark scenario as deployed

### For Gap Analysis

1. Review "Gap Analysis" section in each README
2. Identify components missing in NewOrg
3. Plan prerequisite deployments
4. Understand environment differences

### For Rollback

1. Check "Rollback Procedure" section in each README
2. Follow step-by-step rollback instructions
3. Verify rollback success

---

## Migration Plan Documentation Standard

Each scenario folder contains:

### Folder Structure

```
scenario-name/
├── README.md                        ← Complete migration plan
├── source-docs/                     ← Original documentation (archived)
│   └── ORIGINAL_DOCS.md
└── code/                            ← Deployment-ready verified code
    ├── classes/
    ├── triggers/
    ├── flows/
    └── objects/
```

### README.md Structure

1. **Executive Summary**: What's being migrated, key changes
2. **Source Documentation**: Links to OldOrg State and source docs
3. **Gap Analysis**: OldOrg vs NewOrg comparison
   - Components in OldOrg (with verification)
   - Components in NewOrg (current state)
   - Missing components
   - Version mismatches
4. **Pre-Deployment Verification**: Environment checks
5. **Deployment Steps**:
   - ✅ CLI Steps (automated with exact commands)
   - ⚠️ Manual UI Steps (with detailed instructions)
6. **Post-Deployment Verification**: Testing and validation
7. **Rollback Procedure**: How to undo the migration
8. **Related Documentation**: Links to OldOrg State, source docs, related scenarios
9. **Risk Assessment**: Potential issues and mitigation

---

## Deployment Step Standards

### ✅ CLI Steps (Automated)

Each CLI step includes:
- **Exact command** ready to copy/paste
- **Expected output** (what success looks like)
- **Verification query** (confirm deployment)
- **Error handling** (what to do if it fails)

Example:
```bash
# Step 1.1: Deploy Apex Class
sf project deploy start \
  --source-dir "scenario-name/code/classes/ClassName.cls" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests ClassNameTest \
  --wait 10

# Verification:
sf data query --query "SELECT Name, Status FROM ApexClass WHERE Name = 'ClassName'" --target-org NewOrg --use-tooling-api
```

### ⚠️ Manual UI Steps (User Performs)

Each manual step includes:
- **Why manual**: Explanation of why CLI can't handle this
- **Step-by-step instructions**: Navigate to X > Click Y > Enter Z
- **Screenshots/Details**: Visual or detailed description
- **Verification query**: Confirm configuration via CLI

Example:
```
Step 2.1: Activate Flow (⚠️ Manual UI Step)

Why Manual: Flows always deploy as Inactive. Must be manually activated.

Instructions:
1. Navigate to: Setup > Flows > [Flow Name]
2. Click "Activate"
3. Confirm activation

Verification:
sf data query --query "SELECT Definition.DeveloperName, Status FROM Flow WHERE Definition.DeveloperName = 'FlowName' AND Status = 'Active'" --target-org NewOrg --use-tooling-api
```

---

## Migration Context

### OldOrg → NewOrg Migration

**OldOrg (Source)**:
- Organization: Recycling Lives Service
- URL: recyclinglives.my.salesforce.com
- Status: Current production system
- Role: Source of all customizations to migrate

**NewOrg (Target)**:
- Organization: Recycling Lives Group
- Status: Future production system undergoing migration
- Role: Target for all migrated customizations

**This Repository's Role**:
- Contains **deployment packages** ready for NewOrg
- Provides **step-by-step migration instructions**
- Documents **gap analysis** and environment differences
- Offers **rollback plans** for each migration

---

## Related Repositories

### Companion Repository

**Salesforce_OldOrg_State** (https://github.com/Shintu-John/Salesforce_OldOrg_State.git)
- Documents **current state** of OldOrg implementations
- Contains **verified code** with line-by-line confirmation
- Provides **business logic** and configuration details
- Maintains **historical record** of implementations

**Use Together**:
1. Review OldOrg state documentation (OldOrg_State repo)
2. Review migration plan (this repo)
3. Execute deployment (this repo)
4. Update progress tracking

---

## Important Notes

### Pre-Deployment Checklist

Before deploying any scenario:

1. ✅ **Backup NewOrg**: Create backup of affected components
2. ✅ **Review Gap Analysis**: Understand what's missing/different
3. ✅ **Check Dependencies**: Ensure prerequisites are met
4. ✅ **Review Rollback Plan**: Know how to undo changes
5. ✅ **Schedule Deployment**: Choose appropriate maintenance window
6. ✅ **Notify Stakeholders**: Inform affected users

### Post-Deployment Checklist

After deploying any scenario:

1. ✅ **Run Verification Queries**: Confirm deployment success
2. ✅ **Test Functionality**: Verify feature works as expected
3. ✅ **Check Logs**: Review deployment logs for warnings
4. ✅ **Update Progress**: Mark scenario as deployed
5. ✅ **Document Issues**: Record any problems encountered
6. ✅ **Notify Stakeholders**: Confirm successful deployment

---

## Support Information

**Documentation Owner**: John Shintu
**Organization Admins**: [NewOrg Administrators]
**Migration Project**: OldOrg → NewOrg Migration (2025)

**For Questions**:
- Scenario-specific: See individual README files
- OldOrg state: See Salesforce_OldOrg_State repository
- General: Contact organization administrators

---

## Quick Links

- [OldOrg State Documentation](https://github.com/Shintu-John/Salesforce_OldOrg_State.git)

---
