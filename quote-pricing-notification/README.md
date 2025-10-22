# Quote Pricing Notification Email Issue - NewOrg Configuration Guide

⚠️ **SCENARIO TYPE: CONFIGURATION GUIDANCE ONLY - NOT A CODE DEPLOYMENT**

## ⚠️ Important: This is NOT a Deployment Scenario

**What This Document Is**:
- Configuration guidance for NewOrg setup
- Lessons learned from OldOrg email failure
- Recommendations to prevent similar issues
- Org-wide email address setup checklist

**What This Is NOT**:
- NOT code to deploy
- NOT new functionality to build
- NOT Apex/Trigger/Flow deployment

**Purpose**: Ensure NewOrg has proper email configuration to avoid silent failures

---

## Configuration Checklist for NewOrg

### Pre-Deployment: Org-Wide Email Address Setup

Before migrating workflow email alerts to NewOrg, ensure proper org-wide email configuration:

#### Step 1: Create Org-Wide Email Addresses

**Required Addresses** (based on OldOrg analysis):

1. **no-reply@recyclinglives-services.com**
   - Purpose: Email alerts for automated notifications
   - Usage: Workflow email alerts, quote pricing notifications
   - Recommended Purpose: `UserSelection` (with All Profiles)

2. **customerservice@recyclinglives-services.com**
   - Purpose: Customer service notifications, Email-to-Case
   - Usage: General notifications, case management
   - Recommended Purpose: `UserSelectionAndDefaultNoReply`

#### Step 2: Configure no-reply@ Org-Wide Address

**Setup Steps**:
1. Navigate to: Setup → Organization-Wide Addresses
2. Click: **New**
3. Fill in:
   - **Email**: `no-reply@recyclinglives-services.com`
   - **Display Name**: `Recycling Lives No-Reply`
   - **Allow All Profiles**: ☑ (checked initially)
4. Click: **Save**
5. Check email inbox for verification message
6. Click verification link
7. Return to Salesforce - status should show "Verified"

**After Verification - Apply Profile Restrictions**:

Restrict to 6 profiles covering 99.9% of actual usage:

1. Edit `no-reply@` org-wide address
2. Uncheck "Allow All Profiles"
3. Select these 6 profiles:
   - 1.0 Supply Chain (85.7% of triggers)
   - 1.0 Supply Chain Manager (10.2%)
   - 2.0 Customer Service (1.7%)
   - 2.0 Commercial Sales (1.2%)
   - 2.0 Internal Sales (0.5%)
   - System Administrator (0.5%)
4. Save

**Why These Profiles**: Based on OldOrg analysis of 980 actual workflow triggers

---

## Configuration Recommendations

### 1. Org-Wide Address Purpose Settings

**Critical Understanding**: Purpose setting determines what recipient types work

| Purpose | Dynamic Recipients (accountOwner) | Hardcoded Emails | Use Case |
|---------|----------------------------------|------------------|----------|
| UserSelection | ❌ NO | ✅ YES | Limited use |
| UserSelectionAndDefaultNoReply | ✅ YES | ✅ YES | **Recommended** |

**Recommendation for NewOrg**:
- **no-reply@**: Try to use `UserSelectionAndDefaultNoReply` if possible
- **Limitation**: Only ONE org-wide address can have this Purpose
- **If limited**: Use `UserSelection` with "All Profiles" for broader compatibility

### 2. Workflow Email Alert Best Practices

**When configuring email alerts in NewOrg**:

1. **Test Dynamic Recipients**: Ensure accountOwner, opportunityOwner fields work
2. **Verify Delivery**: Don't rely on task creation alone
3. **Check Actual Inboxes**: Manually verify email received
4. **Monitor Logs**: Watch for silent failures

### 3. Testing Checklist

Before go-live in NewOrg, test:

- [ ] Workflow email alert sends successfully
- [ ] Email appears in recipient inbox (not just task created)
- [ ] Dynamic recipients (accountOwner) receive email
- [ ] Hardcoded recipients receive email
- [ ] Email appears from correct sender (no-reply@)
- [ ] No errors in debug logs
- [ ] EmailMessage record created (if using Apex email)

---

## Lessons Learned from OldOrg

### Issue That Occurred

**Problem**: Org-wide email address `no-reply@` deleted during troubleshooting
**Impact**: 21 days, 205+ quotes, 0 emails delivered
**Root Cause**: Wrong Purpose setting + accidental deletion

### How to Prevent in NewOrg

1. **Document Org-Wide Addresses**: Maintain list of all addresses and purposes
2. **Backup Configuration**: Export org-wide address settings before changes
3. **Test Before Changing**: Never modify email settings without test plan
4. **Monitor Email Delivery**: Set up alerts if no emails sent for 24 hours

### Silent Failure Indicators

**Warning Signs** (from OldOrg experience):
- Workflow tasks created with "email sent" subject
- No EmailMessage records appear
- Recipients report not receiving emails
- Debug logs show no errors

**How to Detect**:
- Manually check recipient inboxes
- Query EmailMessage object (if using Apex)
- Review org-wide address "Last Used" date
- Monitor email delivery metrics

---

## Migration Notes

### What to Migrate

**Configuration Only** (no code deployment):
- Org-wide email address settings
- Workflow email alert configuration
- Profile access permissions

**No Code Components**:
- No Apex classes
- No Triggers
- No Flows to deploy

### Migration Steps for NewOrg

1. **Create org-wide addresses** (Setup UI)
2. **Configure workflow email alerts** (Setup UI)
3. **Test email delivery** (manual testing)
4. **Apply profile restrictions** (Setup UI)
5. **Monitor for 1 week** (verify working)

**Estimated Time**: 2 hours (setup + testing)

---

## Monitoring and Maintenance

### Post-Migration Monitoring

**First Week**:
- Check email delivery daily
- Verify recipients receiving notifications
- Review debug logs for errors
- Monitor org-wide address usage

**Ongoing**:
- Weekly spot-check email delivery
- Monthly review of org-wide address access
- Quarterly audit of workflow email alerts

### Documentation to Maintain

**Create in NewOrg documentation**:
1. **Org-Wide Address Inventory**
   - Which addresses exist
   - Purpose of each
   - Which workflows use each
   - Profile access restrictions

2. **Email Alert Catalog**
   - All workflow email alerts
   - Which org-wide address each uses
   - Expected recipients
   - Trigger conditions

3. **Troubleshooting Runbook**
   - How to test email delivery
   - Common failure modes
   - How to recreate deleted addresses
   - Who to contact for mail server issues

---

## Testing Procedures

### Email Delivery Test Plan

**Test 1: Workflow Email Alert with Dynamic Recipient**

1. Trigger Quote_Process_1 workflow
2. Expected: Email sent to Quote.Account.Owner
3. Verify: Check recipient inbox
4. Expected sender: no-reply@recyclinglives-services.com

**Test 2: Workflow Email Alert with Hardcoded Recipient**

1. Trigger LMJ_Email_Alert workflow
2. Expected: Email sent to hardcoded addresses
3. Verify: Check all recipient inboxes
4. Expected sender: no-reply@recyclinglives-services.com

**Test 3: Multiple Recipients**

1. Trigger workflow with 3+ recipients
2. Verify ALL receive email
3. Check for any delivery failures

**Test 4: Mailbox Rule Impact**

1. Ask recipients to check ALL folders (including auto-filed)
2. Verify email not hidden by Outlook rules
3. Document any auto-filing that occurs

---

## Rollback Plan

**Not Applicable**: This is configuration-only, no code to roll back

If issues occur:
1. Change workflow email alerts to use `customerservice@` temporarily
2. Investigate org-wide address configuration
3. Fix and test
4. Revert back to `no-reply@`

---

## Success Criteria

**NewOrg Email Configuration is Successful When**:

- ✅ All org-wide addresses created and verified
- ✅ Profile access restrictions applied
- ✅ Workflow email alerts configured correctly
- ✅ Test emails delivered to all recipients
- ✅ No silent failures detected
- ✅ Debug logs show successful delivery
- ✅ Documentation created and maintained
- ✅ Monitoring alerts configured

---

## Related Documentation

**Source Analysis**: OldOrg Quote Pricing Notification troubleshooting (Oct 15-16, 2025)

**No Related Code**: This is configuration guidance only

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Maintained By**: Migration Team
