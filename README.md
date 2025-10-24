# Salesforce NewOrg Migration

> **Production deployment repository** for migrating customizations from OldOrg (Recycling Lives Service) to NewOrg (Recycling Lives Group)

[![Deployment Progress](https://img.shields.io/badge/Deployed-5%2F12%20(42%25)-yellow)](https://github.com/Shintu-John/Salesforce_NewOrg)
[![Last Deployment](https://img.shields.io/badge/Last%20Deployment-Oct%2024%2C%202025-green)](https://github.com/Shintu-John/Salesforce_NewOrg)
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

**Overall:** 5 of 12 scenarios deployed (42%)
**Status:** ✅ Active deployment phase
**Target Org:** NewOrg (Production)
**Latest:** Producer Portal COMPLETE - 100% test coverage, all flows active (Oct 24)

### ✅ Completed Deployments

| # | Scenario | Date | Deploy ID | Impact | Docs |
|---|----------|------|-----------|--------|------|
| 01 | [cs-invoicing](01-cs-invoicing/) | Oct 23 | `0AfSq000003nOU5KAM` | CS invoice automation | [📊](01-cs-invoicing/DEPLOYMENT_HISTORY.md) |
| 02 | [transport-charges](02-transport-charges/) | Oct 23 | `0AfSq000003nQO7KAM` | £1.7M+ financial protection | [📊](02-transport-charges/DEPLOYMENT_HISTORY.md) |
| 03 | [secondary-transport](03-secondary-transport/) | Oct 23 | `0AfSq000003nQR3KAM` | Fixed £19K-£29K CSV bug | [📊](03-secondary-transport/DEPLOYMENT_HISTORY.md) |
| 05 | [email-to-case-assignment](05-email-to-case-assignment/) | Oct 23 | `0AfSq000003nVNVKA2` | Automated case assignment | [📊](05-email-to-case-assignment/DEPLOYMENT_HISTORY.md) |
| 06 | [producer-portal](06-producer-portal/) | Oct 24 | `0AfSq000003ncvFKAQ` | **P0 CRITICAL** bugs fixed | [📊](06-producer-portal/DEPLOYMENT_HISTORY.md) |

### 📋 Pending Deployments (6 scenarios)

<details>
<summary><b>View Pending Scenarios</b></summary>

#### High Priority
| # | Scenario | Description | Status |
|---|----------|-------------|--------|
| 04 | [portal-exchange-email](04-portal-exchange-email/) | Email exchange workflow fixes | ⏳ Awaiting email verification |
| 07 | [sage-api-integration](07-sage-api-integration/) | Sage API authentication fixes | 📋 Ready to deploy |

#### Medium Priority
| # | Scenario | Description |
|---|----------|-------------|
| 08 | [daily-reminder-emails](08-daily-reminder-emails/) | Daily email reminder system |
| 09 | [po-consumption-emails](09-po-consumption-emails/) | PO consumption notifications |
| 10 | [invoice-email-portal-access](10-invoice-email-portal-access/) | Invoice email access controls |
| 11 | [job-charge-credit-on-account](11-job-charge-credit-on-account/) | Job charge credit logic |

#### Low Priority
| # | Scenario | Description |
|---|----------|-------------|
| 12 | [smartwaste-integration](12-smartwaste-integration/) | SmartWaste integration analysis |

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
