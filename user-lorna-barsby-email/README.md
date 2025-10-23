# User Email Correction - NewOrg Guide

**Created**: October 23, 2025
**Scenario Type**: 📋 **User Management Guide**
**Target Organization**: NewOrg
**Status**: 📋 Procedure Ready

## Prevention

**Before Creating Users in NewOrg**:
- [ ] Verify email address is correct
- [ ] Check email domain is valid company domain
- [ ] Test verification email delivery in sandbox first

## If Email Correction Needed

**For Unverified Users** (never logged in):
1. **Cannot** update email via standard edit
2. **Cannot** delete User record
3. **Solution**: Deactivate old user + Create new user with correct email

**Commands**:
```bash
# Deactivate old user
sf data update record --sobject User --record-id <old_user_id> --values "IsActive=false" --target-org NewOrg

# Create new user (use Apex or Setup UI)
```

## OldOrg Incident Reference

See: [OldOrg Incident](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/user-lorna-barsby-email)

**Last Updated**: October 23, 2025
