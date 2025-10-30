# Salesforce NewOrg Migration

> **Production deployment repository** for migrating customizations from OldOrg (Recycling Lives Service) to NewOrg (Recycling Lives Group)

[![Deployment Progress](https://img.shields.io/badge/Deployed-11%2F12%20(92%25)-brightgreen)](https://github.com/Shintu-John/Salesforce_NewOrg)
[![Last Deployment](https://img.shields.io/badge/Last%20Deployment-Oct%2029%2C%202025-green)](https://github.com/Shintu-John/Salesforce_NewOrg)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen)](https://github.com/Shintu-John/Salesforce_NewOrg)

---

## 🚀 Quick Start

### For New Deployments
```bash
# 1. Copy templates (use next available number, e.g., 04-scenario-name)
cp Templates/DEPLOYMENT_HISTORY_TEMPLATE.md 04-scenario-name/DEPLOYMENT_HISTORY.md

# 2. Deploy code
sf project deploy start -d 04-scenario-name/code -o NewOrg --test-level RunLocalTests

# 3. Verify Field-Level Security (Critical!)
./Scripts/verify-fls.sh 04-scenario-name ObjectName

# 4. Run functional tests
sf apex run -f 04-scenario-name/tests/test_scenario.apex -o NewOrg
```

### Key Resources
- 🔐 **[FLS Verification Guide](Documentation/Guides/FLS_VERIFICATION_GUIDE.md)** - Field-Level Security setup
- 📋 **[Templates](Templates/)** - Reusable deployment templates
- 🤖 **[Scripts](Scripts/)** - Automation tools

---

## 📊 Deployment Progress

**Total Scenarios:** 36 (11 deployed, 2 pending, 6 configuration, 17 reference)
**Deployment Rate:** 11 of 13 code scenarios deployed (85%)
**Status:** ✅ Active deployment phase
**Target Org:** NewOrg (Production)
**Latest:** SmartWaste Validation Fix DEPLOYED - Critical bug fix unblocking 149 jobs (Oct 29)

### ✅ Completed Deployments

| # | Scenario | Date | Deploy ID | Impact | Docs |
|---|----------|------|-----------|--------|------|
| 01 | [cs-invoicing](01-cs-invoicing/) | Oct 23 | `0AfSq000003nOU5KAM` | CS invoice automation | [📊](01-cs-invoicing/DEPLOYMENT_HISTORY.md) |
| 02 | [transport-charges](02-transport-charges/) | Oct 23 | `0AfSq000003nQO7KAM` | £1.7M+ financial protection | [📊](02-transport-charges/DEPLOYMENT_HISTORY.md) |
| 03 | [secondary-transport](03-secondary-transport/) | Oct 23 | `0AfSq000003nQR3KAM` | Fixed £19K-£29K CSV bug | [📊](03-secondary-transport/DEPLOYMENT_HISTORY.md) |
| 04 | [portal-exchange-email](04-portal-exchange-email/) | Oct 29 | `0AfSq000003pK9RKAU` | Portal SPF/DMARC fix | [📊](04-portal-exchange-email/DEPLOYMENT_HISTORY.md) |
| 05 | [email-to-case-assignment](05-email-to-case-assignment/) | Oct 23 | `0AfSq000003nVNVKA2` | Automated case assignment | [📊](05-email-to-case-assignment/DEPLOYMENT_HISTORY.md) |
| 06 | [producer-portal](06-producer-portal/) | Oct 24-28 | `0AfSj000000zMrdKAE` | **P0 CRITICAL** - Signature + profile fix | [📊](06-producer-portal/DEPLOYMENT_HISTORY.md) |
| 08 | [daily-reminder-emails](08-daily-reminder-emails/) | Oct 29 | `0AfSq000003pNP3KAM` | Prevents 556 daily emails, two-tier system | [📊](08-daily-reminder-emails/DEPLOYMENT_HISTORY.md) |
| 09 | [po-consumption-emails](09-po-consumption-emails/) | Oct 29 | `0AfSq000003pOPMKA2` | Multi-threshold PO monitoring (50%, 75%, 90%) | [📊](09-po-consumption-emails/DEPLOYMENT_HISTORY.md) |
| 10 | [invoice-email-portal-access](10-invoice-email-portal-access/) | Oct 29 | `0AfSq000003pQhvKAE` | Invoice PDF portal access via ContentDistribution | [📊](10-invoice-email-portal-access/DEPLOYMENT_HISTORY.md) |
| 11 | [job-charge-credit-on-account](11-job-charge-credit-on-account/) | Oct 29 | `0AfSq000003pNyXKAU` | **CRITICAL BUGFIX** - Prevents Cost__c corruption on 263 COA charges | [📊](11-job-charge-credit-on-account/DEPLOYMENT_HISTORY.md) |
| 12 | [smartwaste-integration](12-smartwaste-integration/) | Oct 29 | `0AfSq000003pUqLKAU` | **CRITICAL BUGFIX** - Removed incorrect Depot WCL validation (unblocks 149 jobs) | [📊](12-smartwaste-integration/DEPLOYMENT_HISTORY.md) |

### 📋 Pending Deployments (1 scenario)

| # | Scenario | Description | Priority |
|---|----------|-------------|----------|
| 13 | [bam-construct-portal-license](13-bam-construct-portal-license/) | BAM Construct Portal License Visibility | 🟡 Medium |

<details>
<summary><b>View Low Priority / On-Hold Deployments (1 scenario)</b></summary>

| # | Scenario | Description | Status |
|---|----------|-------------|--------|
| 26 | [rlcs-vendor-invoice-sage](26-rlcs-vendor-invoice-sage/) | RLCS Vendor Invoice - Sage Export Fix | ⏸️ On Hold |

</details>

### 📚 Configuration & System Documentation (7 scenarios)

These scenarios document configuration procedures, OAuth authentication, certificate management, and system architecture.

| # | Scenario | Description | Type |
|---|----------|-------------|------|
| 07 | [sage-api-integration](07-sage-api-integration/) | Sage API OAuth re-authentication (60-day cycle) | ⚙️ Configuration |
| 17 | [fred-certificate-renewal](17-fred-certificate-renewal/) | FRED integration certificate renewal procedure | 🔐 Certificate |
| 22 | [quote-pricing-notification](22-quote-pricing-notification/) | Quote pricing notification email configuration | ⚙️ Configuration |
| 33 | [user-lorna-barsby-email](33-user-lorna-barsby-email/) | User email correction procedure | 📝 User Admin |
| 35 | [smartwaste-new-site-setup](35-smartwaste-new-site-setup/) | SmartWaste integration configuration for new accounts/sites | 📖 Setup Guide |
| 36 | [kam-budget-management](36-kam-budget-management/) | KAM Budget system: object structure, automation, data management | 📖 System Docs |

### 📖 Reference Documentation & Guides (22 scenarios)

These scenarios document incidents, troubleshooting procedures, user training, and system analysis for reference purposes.

<details>
<summary><b>View All Reference Scenarios</b></summary>

#### Incident Prevention & Troubleshooting
| # | Scenario | Description |
|---|----------|-------------|
| 14 | [case-reopening-incident](14-case-reopening-incident/) | Case reopening incident prevention guide |
| 16 | [domestic-customer-email](16-domestic-customer-email/) | Domestic customer email issue prevention |
| 21 | [producer-portal-troubleshooting](21-producer-portal-troubleshooting/) | Producer Portal troubleshooting guide |
| 32 | [test-failure-guide](32-test-failure-guide/) | Test failure fix guide and best practices |

#### Data Model & System Analysis
| # | Scenario | Description |
|---|----------|-------------|
| 19 | [orderitem-data-model](19-orderitem-data-model/) | OrderItem data model analysis and reference |
| 30 | [si13024-rollup](30-si13024-rollup/) | SI13024 rollup issue analysis and resolution |
| 34 | [waste-vapes-analysis](34-waste-vapes-analysis/) | Waste vapes stream analysis |

#### User Training & Process Documentation
| # | Scenario | Description |
|---|----------|-------------|
| 23 | [quote-to-order-process](23-quote-to-order-process/) | Quote to Order process - user training guide |

#### Dashboard & Reporting Access
| # | Scenario | Description |
|---|----------|-------------|
| 15 | [dashboard-access](15-dashboard-access/) | Dashboard access configuration reference |

#### Integration & External System Reference
| # | Scenario | Description |
|---|----------|-------------|
| 20 | [outlook-email-sync](20-outlook-email-sync/) | Outlook email sync reference |
| 27 | [sharepoint-file-access](27-sharepoint-file-access/) | SharePoint file access reference |
| 28 | [sharepoint-file-sync](28-sharepoint-file-sync/) | SharePoint file sync reference |

#### Contact & Supplier Management
| # | Scenario | Description |
|---|----------|-------------|
| 31 | [supplier-contact-access](31-supplier-contact-access/) | Supplier contact access reference |

#### User-Specific Issue Reference
| # | Scenario | Description |
|---|----------|-------------|
| 18 | [nathan-blake-adoc](18-nathan-blake-adoc/) | Nathan Blake ADOC reference |
| 24 | [rebekah-stewart-quote](24-rebekah-stewart-quote/) | Rebekah Stewart quote reference |
| 25 | [rebekah-stewart-smartwaste](25-rebekah-stewart-smartwaste/) | Rebekah Stewart SmartWaste reference |
| 29 | [shn-website-quotes](29-shn-website-quotes/) | SHN website quotes reference |

</details>

---

## 📁 Repository Structure

```
deployment-execution/
├── 📋 Templates/              # Reusable deployment templates
│   ├── DEPLOYMENT_HISTORY_TEMPLATE.md
│   ├── FUNCTIONAL_TEST_TEMPLATE.apex
│   └── FUNCTIONAL_TEST_RESULTS_TEMPLATE.md
│
├── 🤖 Scripts/                # Automation tools
│   ├── verify-fls.sh          # FLS verification
│   └── generate-deployment-summary.sh
│
├── 📚 Documentation/          # Guides and workflows
│   ├── ACTIVATED_TRIGGERS_TEST_CLASSES.md
│   └── Guides/
│       └── FLS_VERIFICATION_GUIDE.md
│
└── 📦 [##-scenario-name]/    # Individual deployments (numbered by priority)
    ├── README.md              # Gap analysis & plan
    ├── DEPLOYMENT_HISTORY.md  # Deployment log
    ├── FUNCTIONAL_TEST_RESULTS.md
    ├── code/                  # Deployed Apex/metadata
    └── tests/                 # Functional tests
```

**Folder Numbering Convention:**
- `01-03`: Completed deployments (in deployment order)
- `04-07`: High priority pending scenarios
- `08-11`: Medium priority pending scenarios
- `12+`: Low priority / reference scenarios

---

## 🛠️ How to Deploy

### Standard Deployment Workflow

1. **Review Gap Analysis**
   ```bash
   # Check OldOrg State for scenario details
   cat /tmp/Salesforce_OldOrg_State/scenario-name/README.md
   ```

2. **Prepare Deployment**
   ```bash
   # Copy templates
   cp Templates/DEPLOYMENT_HISTORY_TEMPLATE.md scenario/
   cp Templates/FUNCTIONAL_TEST_TEMPLATE.apex scenario/tests/
   ```

3. **Deploy to NewOrg**
   ```bash
   sf project deploy start \
     -d scenario/code \
     -o NewOrg \
     --test-level RunLocalTests
   ```

4. **🚨 Critical: Set Field-Level Security**
   ```bash
   # Automated verification
   ./Scripts/verify-fls.sh scenario ObjectName

   # Manual UI steps if needed
   # See: Documentation/Guides/FLS_VERIFICATION_GUIDE.md
   ```

5. **Run Functional Tests**
   ```bash
   sf apex run -f scenario/tests/test_scenario.apex -o NewOrg
   ```

6. **Document & Commit**
   ```bash
   # Complete DEPLOYMENT_HISTORY.md
   # Update this README with deployment progress
   git add scenario/ README.md
   git commit -m "Deploy scenario: [description]"
   git push
   ```

**For detailed deployment steps:** See individual scenario DEPLOYMENT_HISTORY.md files for real-world examples

---

## 🔧 Tools & Automation

### FLS Verification Script
Automatically check Field-Level Security after deployment:

```bash
./Scripts/verify-fls.sh scenario-name ObjectName

# Example output:
# | Field API Name                    | Readable | Editable | Status      |
# |-----------------------------------|----------|----------|-------------|
# | Custom_Field__c                   | ✅ Yes   | ✅ Yes   | ✅ CORRECT  |
# | Another_Field__c                  | ✅ Yes   | ⚠️  No   | ⚠️  READ-ONLY|
```

**Why this matters:** Custom fields deploy WITHOUT Field-Level Security by default!

**Guide:** [FLS_VERIFICATION_GUIDE.md](Documentation/Guides/FLS_VERIFICATION_GUIDE.md)

### Deployment Summary Generator
Generate concise deployment summaries:

```bash
./Scripts/generate-deployment-summary.sh scenario-name
```

---

## 🎯 Key Learnings from Deployments

### Critical Post-Deployment Steps

1. **🚨 Set Field-Level Security**
   - Custom fields deploy WITHOUT FLS
   - Always run `./Scripts/verify-fls.sh` after deployment
   - Fields must be both Visible AND Editable (not Read-Only)

2. **🚨 Update Page Layouts**
   - Custom fields do NOT auto-appear on layouts
   - Manually add fields via Setup → Object Manager → Page Layouts

3. **Test Coverage Requirements**
   - Production orgs require 75% minimum coverage
   - Shallow smoke tests are insufficient
   - May need to rewrite test classes comprehensively

### Best Practices

- ✅ Always use templates for consistency
- ✅ Verify FLS before functional testing
- ✅ Document all manual configuration steps
- ✅ Run functional tests beyond unit tests
- ✅ Commit deployment history immediately

---

## 📚 Documentation

### Essential Guides
- **[FLS Verification Guide](Documentation/Guides/FLS_VERIFICATION_GUIDE.md)** - Field-Level Security setup and troubleshooting

### Reference Documents
- **[Activated Triggers](Documentation/ACTIVATED_TRIGGERS_TEST_CLASSES.md)** - Triggers activated during deployments
- **[FLS Status Report](FLS_STATUS_REPORT.md)** - FLS analysis from secondary-transport deployment
- **[Repo Improvements Summary](REPO_IMPROVEMENTS_SUMMARY.md)** - Repository enhancement details

### Templates
- **[DEPLOYMENT_HISTORY_TEMPLATE.md](Templates/DEPLOYMENT_HISTORY_TEMPLATE.md)** - Standard deployment documentation
- **[FUNCTIONAL_TEST_TEMPLATE.apex](Templates/FUNCTIONAL_TEST_TEMPLATE.apex)** - Reusable test script structure
- **[FUNCTIONAL_TEST_RESULTS_TEMPLATE.md](Templates/FUNCTIONAL_TEST_RESULTS_TEMPLATE.md)** - Test results documentation

---

## 🔗 Related Repositories

- **[Salesforce_OldOrg_State](https://github.com/Shintu-John/Salesforce_OldOrg_State)** - Source org documentation (READ-ONLY reference)

---

## 📞 Support

**Project Lead:** John Shintu
**Email:** shintu.john@recyclinglives.com
**Working Directory:** `/home/john/Projects/Salesforce/deployment-execution`

### Getting Help

1. **FLS Problems:** See [FLS_VERIFICATION_GUIDE.md](Documentation/Guides/FLS_VERIFICATION_GUIDE.md)
2. **Scenario-Specific:** Review scenario's DEPLOYMENT_HISTORY.md
3. **General Deployment:** Check completed scenarios (01-05) for working examples

---

## 📜 License

Internal use - Recycling Lives Group

---

<div align="center">

**Last Updated:** October 23, 2025
**Repository Version:** 2.0 (Template-based deployment workflow)
**Next Milestone:** 6/12 scenarios (50%) by end of October 2025

</div>
