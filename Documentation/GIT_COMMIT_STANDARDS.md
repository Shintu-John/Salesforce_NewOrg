# Git Commit Standards Checklist

Before committing to Salesforce_NewOrg repository, verify:

## 1. Git Configuration
```bash
git config user.name   # Must be: John Shintu
git config user.email  # Must be: shintu.john@recyclinglives-services.com
```

## 2. Pre-Commit Check
```bash
# Search for prohibited terms in staged changes
git diff --cached | grep -i "claude\|ai assistant\|co-authored"

# If found, fix before committing
```

## 3. Commit Message Format

### ✅ CORRECT Format:
```
Brief description of changes

Detailed Changes:
- Specific change 1
- Specific change 2
- Specific change 3

Impact/Results:
- What was achieved
- What was fixed
- What was improved

Next Steps (if applicable):
- Action item 1
- Action item 2
```

### ❌ INCORRECT - Never Include:
- 🤖 Generated with [Claude Code]
- Co-Authored-By: Claude <noreply@anthropic.com>
- Any AI assistant references
- Emoji attributions

## 4. Verification After Commit
```bash
# Check the last commit
git log -1 --format="%an <%ae>%n%B"

# Should show:
# John Shintu <shintu.john@recyclinglives-services.com>
# [Your commit message without AI references]
```

## 5. Before Pushing
```bash
# Final verification
git log origin/main..HEAD --format="%an <%ae>" | sort -u

# Should ONLY show:
# John Shintu <shintu.john@recyclinglives-services.com>
```

## 6. If You Made a Mistake

### If haven't pushed yet:
```bash
git commit --amend -m "Corrected commit message here"
```

### If already pushed (use with caution):
```bash
git commit --amend -m "Corrected commit message here"
git push --force-with-lease
```

## Common Scenarios

### Deployment Complete:
```
Deploy email-to-case-assignment scenario to NewOrg

Deployment Details:
- Deploy ID: 0AfSq000003nVNVKA2
- Components: 4 Apex classes, 1 Flow, 2 custom fields
- Test Results: 17/17 tests passed
- Manual Steps: Flow activation, FLS configuration

Status: Deployment complete and functional
```

### Documentation Update:
```
Update deployment documentation with test results

Changes:
- Added functional test results to FUNCTIONAL_TEST_RESULTS.md
- Updated DEPLOYMENT_HISTORY.md with production blocker details
- Corrected time threshold from 24 hours to 14 hours

Next Steps: CS team needs to log in for production readiness
```

### Bug Fix:
```
Fix Account validation rule in test classes

Issue: Test classes failed due to missing comp_house__Company_Number__c
Solution: Updated all 14 Account creation statements
Result: All tests now passing (17/17)
```
