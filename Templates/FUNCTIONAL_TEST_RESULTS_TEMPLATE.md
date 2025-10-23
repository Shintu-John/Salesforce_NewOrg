# Functional Test Results: [Scenario Name]

**Scenario:** [scenario-name]
**Deploy ID:** [Deploy-ID]
**Test Date:** [Date]
**Tested By:** [Your Name / Automated]
**Test Script:** `tests/test_[scenario].apex`
**Status:** [✅ ALL TESTS PASSED / ⚠️ PARTIAL / ❌ FAILED]

---

## Executive Summary

[Brief summary of test results - what was tested and overall outcome]

**Test Coverage:**
- Unit Tests: [X/X passed (100%)]
- Functional Tests: [X/X passed (100%)]
- Integration Tests: [X/X passed (100%)]

**Key Findings:**
- ✅ [Key success point 1]
- ✅ [Key success point 2]
- ⚠️ [Any warnings or minor issues]

---

## Test Environment Setup

### Prerequisites Met
- ✅ [Prerequisite 1]
- ✅ [Prerequisite 2]
- ✅ [Manual Configuration (FLS, Page Layouts)]

### Test Data Hierarchy
```
[Parent Object]
  └─> [Child Object]
       └─> [Grandchild Object]
```

### Manual Configuration Verified
- ✅ Field-Level Security set for [X] custom fields
- ✅ Page layouts updated with [X] custom fields
- ✅ Fields accessible via Anonymous Apex

---

## Test Results

### TEST 1: [Test Name]

**Purpose:** [What this test validates]

**Test Setup:**
```apex
[Key setup code or description]
```

**Expected Result:**
- [Expected outcome 1]
- [Expected outcome 2]

**Actual Result:**
```
[Actual output from test]
```

**Verification:**
- [✅ Verification point 1]
- [✅ Verification point 2]

**Status:** ✅ PASSED / ❌ FAILED / ⚠️ PARTIAL

**Notes:** [Any additional observations]

---

### TEST 2: [Test Name]

**Purpose:** [What this test validates]

**Test Setup:**
```apex
[Key setup code or description]
```

**Expected Result:**
- [Expected outcome]

**Actual Result:**
```
[Actual output]
```

**Verification:**
- [✅ Verification point]

**Status:** ✅ PASSED / ❌ FAILED

---

### TEST 3: [Edge Case Name]

**Purpose:** [What edge case this tests]

**Test Setup:**
```apex
[Edge case setup]
```

**Expected Result:**
- [How system should handle edge case]

**Actual Result:**
```
[Actual behavior]
```

**Verification:**
- [✅ System handled edge case correctly]

**Status:** ✅ PASSED / ❌ FAILED

---

## Test Coverage Summary

| Test # | Test Name | Purpose | Status | Notes |
|--------|-----------|---------|--------|-------|
| 1 | [Name] | [Purpose] | ✅ PASSED | [Notes] |
| 2 | [Name] | [Purpose] | ✅ PASSED | [Notes] |
| 3 | [Name] | [Purpose] | ✅ PASSED | [Notes] |

**Overall Result:** ✅ [X/X] tests passed (100%)

---

## Integration Testing

### Cross-Scenario Integration

**Scenarios Tested Together:**
1. [Scenario A] - [How it integrates]
2. [Scenario B] - [How it integrates]

**Integration Test Results:**
- ✅ [Integration point 1 verified]
- ✅ [Integration point 2 verified]

---

## Manual Configuration Verification

### Field-Level Security (FLS) Verification

**Method:** Metadata retrieval + Anonymous Apex test

**Fields Verified:**
| Field API Name | Readable | Editable | Status |
|---------------|----------|----------|--------|
| [Field__c] | ✅ Yes | ✅ Yes | ✅ Verified |

**Verification Command:**
```bash
sf project retrieve start \
  --manifest manifest/package-fls-check.xml \
  --target-org NewOrg

grep -A 2 "[Field__c]" fls-verify/profiles/Admin.profile-meta.xml
```

**Result:**
```xml
<editable>true</editable>
<field>[Object].[Field__c]</field>
<readable>true</readable>
```

✅ **FLS Verified**: All fields readable and editable

---

### Page Layout Verification

**Method:** UI verification in NewOrg

**Layouts Verified:**
| Object | Layout Name | Fields Added | Visible in UI |
|--------|------------|--------------|---------------|
| [Object] | [Layout] | [X] fields | ✅ Yes |

**UI Navigation Path:**
1. Setup → Object Manager → [Object]
2. Page Layouts → [Layout Name]
3. Verify fields present in [Section Name]

✅ **Page Layouts Verified**: All fields visible on layouts

---

## Business Logic Verification

### Feature 1: [Feature Name]

**Business Rule:** [Description of business rule]

**Test Scenario:**
1. [Step 1]
2. [Step 2]
3. [Expected outcome]

**Result:** ✅ Business rule enforced correctly

---

### Feature 2: [Feature Name]

**Business Rule:** [Description]

**Test Scenario:**
1. [Steps]

**Result:** ✅ Business rule working as expected

---

## Performance Testing

### Test 1: [Performance Test]

**Scenario:** [What was tested]

**Results:**
- Execution Time: [X seconds]
- SOQL Queries: [X] out of 100
- DML Statements: [X] out of 150
- CPU Time: [X ms] out of 10,000 ms

**Status:** ✅ Performance acceptable

---

## Known Issues / Limitations

| # | Issue | Severity | Status | Workaround |
|---|-------|----------|--------|------------|
| 1 | [Issue] | [🟢 Low / ⚠️ Medium / 🚨 High] | [Open / Resolved] | [Workaround if any] |

---

## Recommendations

### For Production Use
1. [Recommendation 1]
2. [Recommendation 2]

### For Future Deployments
1. [Lesson learned 1]
2. [Lesson learned 2]

---

## Test Script Details

**Script Location:** `tests/test_[scenario].apex`

**Script Size:** [X] lines

**Execution Method:** Anonymous Apex via Developer Console or `sf apex run`

**Test Data Created:**
- [X] [Object] records
- [X] [Related Object] records

**Execution Time:** [X] seconds

**Debug Log Output:** [Summary of key debug statements]

---

## Deployment Validation Checklist

### Pre-Deployment ✅
- [x] Unit tests pass ([X/X])
- [x] Test coverage meets requirements (75%+)
- [x] Code review completed

### Deployment ✅
- [x] Deployment succeeded (Deploy ID: [ID])
- [x] All components deployed
- [x] No deployment errors

### Post-Deployment Configuration ✅
- [x] Field-Level Security set
- [x] Page layouts updated
- [x] Fields visible in UI

### Functional Testing ✅
- [x] All functional tests passed ([X/X])
- [x] Edge cases tested
- [x] Integration verified

### Documentation ✅
- [x] DEPLOYMENT_HISTORY.md created
- [x] FUNCTIONAL_TEST_RESULTS.md created (this document)
- [x] Scenario README updated

---

## Related Documentation

- **Deployment History:** [DEPLOYMENT_HISTORY.md](./DEPLOYMENT_HISTORY.md)
- **Scenario README:** [README.md](./README.md)
- **Test Script:** [tests/test_[scenario].apex](./tests/test_[scenario].apex)
- **OldOrg State:** `/tmp/Salesforce_OldOrg_State/[scenario-name]/README.md`

---

## Conclusion

[Summary paragraph about deployment success, any outstanding items, and production readiness]

### Production Readiness Checklist
- ✅ All tests passing
- ✅ Manual configuration complete
- ✅ Documentation complete
- ✅ No known blockers

**Status:** ✅ READY FOR PRODUCTION USE

---

**Document Version:** 1.0
**Last Updated:** [Date]
**Reviewed By:** [Reviewer if applicable]
