# Domestic Customer Email - NewOrg Prevention Guide

**Created**: October 23, 2025
**Scenario Type**: 📋 **Prevention Guide**
**Target Organization**: NewOrg
**Status**: 📋 Checklist Ready

## What to Check in NewOrg

**Verify Person Account Page Layouts**:

1. Navigate to **Setup** → **Object Manager** → **Account**
2. Click **Page Layouts** → **Domestic Customer Layout**
3. Verify **PersonEmail** field is present in **Account Information** section
4. Verify field behavior = **Edit** (not Read-only)

## Test Procedure

1. Create test Person Account (Record Type = Domestic Customer)
2. Try to edit PersonEmail field
3. **Verify**: Field is editable and saves successfully

**Expected**: ✅ Email field visible and editable

## OldOrg Incident Reference

See: [OldOrg Incident](https://github.com/Shintu-John/Salesforce_OldOrg_State/tree/main/domestic-customer-email)

**Last Updated**: October 23, 2025
