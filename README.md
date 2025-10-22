# Salesforce NewOrg Migration Repository

**Target Organization**: NewOrg (Recycling Lives Group)
**Source Organization**: OldOrg (Recycling Lives Service)
**Purpose**: Migration plans and deployment-ready packages for migrating from OldOrg to NewOrg
**Created**: October 22, 2025
**Status**: 🚀 Ready for Migration

---

## Repository Purpose

This repository contains **migration plans and deployment packages** for migrating all customizations and features from **OldOrg** (legacy system) to **NewOrg** (future production system).

### Why This Repository Exists

1. **Migration Execution**: Provides step-by-step deployment instructions for each scenario
2. **Gap Analysis**: Documents differences between OldOrg and NewOrg
3. **Deployment Scripts**: Contains ready-to-execute commands for migration
4. **Risk Management**: Includes rollback plans and risk mitigation strategies
5. **Quality Assurance**: Provides comprehensive testing and verification procedures

### What This Repository Contains

- **Migration plans** for each scenario (gap analysis, deployment steps, verification)
- **Deployment-ready code** (same code as OldOrg, ready to deploy to NewOrg)
- **Bash deployment scripts** with all commands ready to execute
- **Rollback procedures** for each migration
- **Testing plans** for post-deployment verification
- **Risk assessments** and mitigation strategies

---

## Repository Structure

```
Salesforce_NewOrg/
├── README.md (this file)
├── email-to-case-assignment/           ← Each scenario gets its own folder
│   ├── README.md                        ← Complete migration plan
│   └── code/                            ← Deployment-ready code
│       ├── classes/
│       ├── triggers/
│       ├── flows/
│       └── objects/
├── producer-portal/                     ← Another scenario
│   ├── README.md
│   └── code/
├── secondary-transport/                 ← Another scenario
│   ├── README.md
│   └── code/
└── [more scenarios...]
```

### Folder Naming Convention

- **Matches OldOrg State repo**: Same folder names for easy cross-reference
- **Flat structure**: All scenarios at root level
- **Kebab-case names**: `email-to-case-assignment`, `producer-portal`
- **Consolidated**: Related features grouped together

---

## Migration Scenarios

### Status Legend
- ✅ **Ready for Deployment**: Migration plan reviewed and approved, ready to execute
- 🔄 **In Progress**: Migration plan being prepared
- 📋 **Planned**: Not yet started
- 🚀 **Deployed**: Successfully deployed to NewOrg
- ⏸️ **On Hold**: Waiting for dependencies or prerequisites

### Batch 1: High Priority Scenarios (5/5 Ready ✅)

| Scenario | Status | Priority | Estimated Time | Notes |
|----------|--------|----------|----------------|-------|
| [email-to-case-assignment](email-to-case-assignment/) | ✅ Ready | 🔴 High | 45-60 min | Migration plan complete |
| [producer-portal](producer-portal/) | ✅ Ready | 🔴 High | 2-3 hours | Migration plan complete - V3 with all fixes |
| [sage-api-integration](sage-api-integration/) | ✅ Ready | 🔴 High | 3-4 hours | Migration plan complete - OAuth + RLCS fixes |
| [secondary-transport](secondary-transport/) | ✅ Ready | 🔴 High | 2-3 hours | Migration plan complete - V4 bug fixes critical |
| [daily-reminder-emails](daily-reminder-emails/) | ✅ Ready | 🔴 High | 2 hours | Migration plan complete - Two-tier consolidated reporting (99.6% email reduction) |

### Batch 2: Medium Priority Scenarios (4/6 Ready)

| Scenario | Status | Priority | Estimated Time | Notes |
|----------|--------|----------|----------------|-------|
| [cs-invoicing](cs-invoicing/) | ✅ Ready | 🟡 Medium | 2-3 hours | Migration plan complete - Date/Description auto-population (Oct 10-15, 2025) |
| [portal-exchange-email](portal-exchange-email/) | ✅ Ready | 🟡 Medium | 2-3 hours | Migration plan complete - SPF/DMARC fix (Oct 16, 2025) |
| [transport-charges](transport-charges/) | ✅ Ready | 🔴 Critical | 3-4 hours | Migration plan complete - Bug fixes for missing & incorrect charges (Oct 14-15, 2025) |
| [smartwaste-integration](smartwaste-integration/) | ✅ Ready | 🟡 Medium | 3-4 hours | Migration plan complete - Configuration-only (activate flows + schedule jobs) |
| quote-management | 📋 Planned | 🟡 Medium | TBD | Quote management improvements |
| [more coming...] | 📋 Planned | - | TBD | Additional scenarios |

---

## Migration Workflow

### Step-by-Step Process

```
1. Review OldOrg State
   ↓
   Read documentation in Salesforce_OldOrg_State repository
   Understand current implementation and business logic

2. Review NewOrg Migration Plan
   ↓
   Read README.md in this repository for the scenario
   Review gap analysis and deployment steps

3. Approval
   ↓
   User reviews migration plan
   User approves deployment approach
   Deployment date/time confirmed

4. Pre-Deployment Checks
   ↓
   Verify all prerequisites met
   Confirm dependencies satisfied
   Prepare rollback plan

5. Execute Deployment
   ↓
   Follow deployment steps in order
   Execute commands as documented
   Monitor for errors

6. Post-Deployment Verification
   ↓
   Run all verification tests
   Confirm components deployed correctly
   Validate business logic works

7. Monitoring
   ↓
   Monitor system for 24-48 hours
   Gather user feedback
   Address any issues

8. Complete
   ↓
   Update scenario status to "Deployed"
   Document any deviations or issues
   Move to next scenario
```

---

## Migration Plan Structure

Each scenario folder contains:

### README.md Structure

1. **Executive Summary**: What's being migrated, expected benefits
2. **Gap Analysis**: Detailed comparison of OldOrg vs NewOrg
   - Component-by-component comparison table
   - Missing features identified
   - Version mismatches noted
3. **Migration Strategy**: Approach and deployment order
4. **Pre-Deployment Checklist**: Prerequisites to verify before starting
5. **Deployment Steps**: Phase-by-phase instructions with commands
   - Phase 1: Foundation (Custom Objects & Fields)
   - Phase 2: Apex Code
   - Phase 3: Flows
   - Phase 4: Configuration & Activation
   - Phase 5: Verification
6. **Post-Deployment Verification**: Test cases to run after deployment
7. **Rollback Plan**: How to undo deployment if issues arise
8. **Testing Plan**: Comprehensive testing procedures
9. **Known Issues & Risks**: Potential problems and mitigation strategies

### Code Folder

- **Exact same structure as OldOrg State repo**
- Contains deployment-ready code
- Can be deployed directly using `sf project deploy` commands
- Matches OldOrg V3 (or latest version) exactly

---

## Deployment Approach

### Deployment Method

**Option Selected**: Document everything + Deploy after user review and approval

**What This Means:**
1. All deployment steps are fully documented with exact commands
2. User reviews migration plan for each scenario
3. User approves deployment (gives explicit go-ahead)
4. AI Assistant executes deployment following documented steps
5. User verifies results after deployment

### Deployment Best Practices

1. **Deploy in Order**: Follow Phase 1 → 2 → 3 → 4 → 5 sequence
2. **Verify Each Phase**: Don't proceed if verification fails
3. **Test Before Activating**: Deploy components inactive, test, then activate
4. **Monitor Closely**: Watch debug logs during first deployments
5. **Have Rollback Ready**: Be prepared to deactivate/remove if issues arise

### Using Deployment Commands

All deployment commands are provided in a copy-paste ready format:

```bash
# Example:
sf project deploy start \
  --source-dir "email-to-case-assignment/code/classes" \
  --target-org NewOrg \
  --test-level RunSpecifiedTests \
  --tests "rlsServiceCaseAutoAssignTest" \
  --wait 10
```

**To Execute:**
1. Copy the command from the migration plan README
2. Ensure you're in the correct directory (this repo root)
3. Paste and execute in terminal
4. Verify expected output matches documentation

---

## Gap Analysis Process

For each scenario, we document:

### Current State Comparison

| Component | OldOrg | NewOrg | Gap | Action |
|-----------|--------|--------|-----|--------|
| Component Name | Version/Status in OldOrg | Version/Status in NewOrg | What's missing | What to do |

### Categories of Gaps

1. **🚨 Critical Missing**: Component completely absent in NewOrg
2. **⚠️ Outdated Version**: Component exists but is old version
3. **❌ Inactive**: Component exists but not activated
4. **📝 Configuration**: Settings/data not configured

---

## Pre-Deployment Considerations

### NewOrg Deactivated Triggers

⚠️ **IMPORTANT**: NewOrg has 17 triggers that must remain deactivated during migration.

**Before deploying any scenario:**
1. Check if scenario requires any of the deactivated triggers
2. If yes, consult user about activation plan
3. Document reason for activation if approved
4. Update deactivated triggers list

**Reference**: See `/Documentation/NEWORG_DEACTIVATED_TRIGGERS.md` in main project

### Dependencies Between Scenarios

Some scenarios depend on others:

**Example Dependencies:**
- Email-to-Case Assignment → Requires Email-to-Case configuration
- Producer Portal → Requires User provisioning and Communities setup
- Sage API Integration → Requires API credentials and authentication

**Migration Order Considerations:**
- Deploy foundation scenarios first (custom settings, utility classes)
- Deploy dependent scenarios after their prerequisites
- Group related scenarios together when possible

---

## Testing Strategy

### Testing Levels

1. **Unit Testing** (Deployment Time)
   - Apex test classes must pass
   - Minimum 75% code coverage required
   - All test methods must succeed

2. **Integration Testing** (Post-Deployment)
   - Verify components work together
   - Test trigger → class → flow sequences
   - Validate data flows correctly

3. **User Acceptance Testing** (First Week)
   - CS team tests real scenarios
   - Monitor case assignment patterns
   - Gather feedback on functionality

4. **Performance Testing** (First Month)
   - Monitor SOQL query usage
   - Check for governor limit issues
   - Verify system scales with load

### Verification Test Structure

Each migration plan includes 5 verification tests:

1. **Test 1**: Basic functionality (Quick smoke test)
2. **Test 2**: Core business logic (Threshold, workload distribution)
3. **Test 3**: Special cases (Key accounts, exemptions)
4. **Test 4**: Integration (Flow triggering, related systems)
5. **Test 5**: Configuration (Settings, active versions)

---

## Rollback Procedures

Every migration plan includes three rollback levels:

### Immediate Rollback (2-5 minutes)
- Deactivate trigger only
- Stops automation immediately
- Least disruptive
- **Use when**: Minor issues that need quick fix

### Partial Rollback (10-15 minutes)
- Deactivate triggers + flows
- Stops entire feature
- Returns to manual operation
- **Use when**: Moderate issues affecting multiple components

### Full Rollback (30-60 minutes)
- Remove all deployed components
- Complete cleanup
- Most disruptive
- **Use when**: Fundamental issues require complete removal

---

## Risk Management

### Risk Assessment

Each migration plan includes:

1. **Known Limitations**: Features that have constraints
2. **Potential Risks**: What could go wrong
3. **Risk Likelihood**: Low / Medium / High
4. **Risk Impact**: Low / Medium / High
5. **Mitigation Strategies**: How to prevent or minimize risk

### Common Risks Across Migrations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Dependency mismatch (queue names, record types) | Medium | High | Verify before deployment |
| Flow version confusion | Low | High | Check active version post-deployment |
| Test failures due to org differences | Medium | Medium | Review failures, adjust tests if needed |
| User profile permission issues | Low | Medium | Verify permissions in pre-deployment checklist |
| High-volume data scenarios | Low | Medium | Monitor debug logs, check governor limits |

---

## Monitoring & Support

### Post-Deployment Monitoring

**First 24 Hours:**
- Check every 2-3 hours
- Review debug logs for errors
- Monitor case assignment (for email-to-case scenario)
- Respond quickly to user reports

**First Week:**
- Daily checks
- User feedback collection
- Performance monitoring
- Minor adjustments via configuration

**First Month:**
- Weekly reviews
- Pattern analysis
- Optimization opportunities
- Documentation updates

### Support Resources

**During Migration:**
- This repository (deployment steps)
- OldOrg State repository (reference implementation)
- Salesforce debug logs
- Test execution results

**Post-Migration:**
- User feedback
- Debug logs
- Monitoring queries
- Performance metrics

---

## Migration Progress Tracking

### Overall Migration Status

**Total Scenarios**: 40+ to migrate
**Completed**: 0
**Ready for Deployment**: 5 (Batch 1 complete)
**Planned**: 40+

**Target Completion Date**: TBD

### Tracking Individual Scenarios

Each scenario README includes:

```markdown
**Status**: 📋 Ready for Review / 🚀 Deployed / ⏸️ On Hold / ❌ Blocked
**Priority**: 🔴 High / 🟡 Medium / 🟢 Low
**Estimated Time**: X-Y minutes
**Deployment Date**: YYYY-MM-DD (once deployed)
**Deploy ID**: [Salesforce Deploy ID] (once deployed)
```

---

## Best Practices

### Before Starting Any Migration

1. ✅ Read OldOrg State documentation thoroughly
2. ✅ Review NewOrg migration plan completely
3. ✅ Verify all prerequisites
4. ✅ Prepare test data
5. ✅ Have rollback plan ready
6. ✅ Notify stakeholders

### During Deployment

1. ✅ Follow phases in exact order
2. ✅ Verify after each phase
3. ✅ Don't skip verification steps
4. ✅ Stop if any verification fails
5. ✅ Monitor debug logs
6. ✅ Document any deviations

### After Deployment

1. ✅ Run all verification tests
2. ✅ Update scenario status
3. ✅ Document Deploy IDs
4. ✅ Notify users
5. ✅ Monitor closely
6. ✅ Gather feedback

---

## Related Resources

### Companion Repository

**Salesforce_OldOrg_State** (https://github.com/Shintu-John/Salesforce_OldOrg_State.git)
- **OldOrg current state documentation**
- **Verification data** from OldOrg
- **Business logic explanations**
- **Historical context**

**Use Together:**
1. Review OldOrg State → Understand what exists
2. Review NewOrg Migration Plan → Understand what's missing
3. Execute deployment → Bridge the gap
4. Verify → Confirm migration success

### Project Documentation

Main Salesforce project: `/home/john/Projects/Salesforce/`
- `/Documentation/` - Detailed scenario guides
- `/Backup/` - Code backups from OldOrg
- `CLAUDE_WORKFLOW_RULES.md` - Migration workflow standards

---

## Quick Start Guide

### Deploying First Scenario (Example: Email-to-Case)

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Shintu-John/Salesforce_NewOrg.git
   cd Salesforce_NewOrg
   ```

2. **Read the migration plan:**
   ```bash
   cat email-to-case-assignment/README.md
   ```

3. **Review gap analysis section**
   - Understand what's missing in NewOrg
   - Review deployment phases

4. **Run pre-deployment checklist**
   - Verify prerequisites
   - Confirm org access

5. **Execute Phase 1 deployment**
   - Copy commands from README
   - Execute in terminal
   - Verify results

6. **Continue through all phases**
   - Phase 2: Apex Code
   - Phase 3: Flows
   - Phase 4: Activation
   - Phase 5: Verification

7. **Post-deployment monitoring**
   - Run verification tests
   - Monitor for 24-48 hours
   - Gather feedback

---

## Support Information

**Migration Project Owner**: John Shintu
**Organization**: Recycling Lives Group

**For Questions:**
- Migration planning: Review this repository
- Current state reference: Check Salesforce_OldOrg_State repository
- Deployment issues: Review rollback plans and debug logs
- Business logic: See OldOrg State documentation

---

## Important Notes

### This is for Deployment to NewOrg Only

⚠️ **Do not deploy to OldOrg from this repository**

- This repo is for migrating **TO NewOrg**
- OldOrg remains the source of truth until migration complete
- After migration, NewOrg becomes primary

### Code is Read-Only Until Deployment

- Code in this repo matches OldOrg exactly
- Do not modify code here
- Modifications should be made in NewOrg after deployment
- Keep this repo as reference for migration

---

## Quick Links

- [Email-to-Case Migration Plan](email-to-case-assignment/README.md)
- [OldOrg State Repository](https://github.com/Shintu-John/Salesforce_OldOrg_State.git)
- [Main Project Documentation](../Documentation/)
- [NewOrg Deactivated Triggers List](../Documentation/NEWORG_DEACTIVATED_TRIGGERS.md)

---

**Repository Status**: 🚀 Ready for Migration
**Last Updated**: October 22, 2025
**Next Steps**:
1. User reviews migration plans for ready scenarios
2. User approves deployment for each scenario
3. Execute deployments to NewOrg in priority order
4. Continue with remaining scenarios

**Total Scenarios to Migrate**: 40+
**Current Progress**: 9 scenarios ready for deployment

**Batch 1 Progress**: 5/5 migration plans complete ✅
**Batch 2 Progress**: 4/6 migration plans complete (CS Invoicing, Portal Exchange Email, Transport Charges, SmartWaste Integration)
