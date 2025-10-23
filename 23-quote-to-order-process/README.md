# Quote to Order Process - NewOrg User Training Guide

⚠️ **SCENARIO TYPE: PROCESS DOCUMENTATION/USER TRAINING - NOT A DEPLOYMENT**

## ⚠️ Important: This is NOT a Deployment Scenario

**What This Document Is**:
- User training guide for NewOrg Quote-to-Order process
- Best practices for adding Quote Line Items to existing Orders
- Common pitfalls and how to avoid them
- Process documentation for onboarding new users

**What This Is NOT**:
- NOT code to deploy
- NOT system configuration changes
- NOT new functionality to build

**Purpose**: Ensure NewOrg users understand correct Quote-to-Order process to avoid common errors

---

## NewOrg User Training: Quote-to-Order Process

### Process Overview

When adding new Quote Line Items to existing Orders in NewOrg, follow this process:

**Goal**: Add new products to an existing Order without creating duplicate Orders

**Method**: Use "Generate Order" button with existing PO selection

**Critical Step**: Selecting the correct Purchase Order from dropdown

---

## Step-by-Step Guide

### Step 1: Add Quote Line Item

1. Open Quote record in NewOrg
2. Navigate to Quote Line Items related list
3. Click "Add Product" or "New Quote Line Item"
4. Fill in:
   - Product
   - Quantity
   - Price
   - Description
   - Any other required fields
5. **Save** the Quote Line Item

### Step 2: Initiate "Generate Order" Flow

1. Return to Quote record page view
2. Locate **"Generate Order"** button (top-right action buttons)
3. Click **"Generate Order"**
4. Flow screen appears

### Step 3: Select Existing PO (⚠️ MOST IMPORTANT)

**Flow Screen: "Quote Details" or "Select Purchase Order"**

**What You'll See**:
- Dropdown list showing existing Orders for this Account
- Each option shows PO Number (e.g., "PO-001234")
- May show additional info (department, status, etc.)

**⚠️ CRITICAL DECISION POINT**:

**BEFORE selecting from dropdown**:
1. Know which Order you want to update
2. Have the correct PO Number ready (write it down if needed)
3. Understand Account's PO structure:
   - **ES** = Environmental Services
   - **CS** = Commercial Services
   - **LS** = Logistics
   - Other department codes

**How to Select Correct PO**:
```
Example Scenario:
- Account: Sheffield City Council
- Existing Orders:
  • Order #12345 - PO-ES-001 (Environmental Services)
  • Order #12346 - PO-CS-002 (Commercial Services)
  • Order #12347 - PO-LS-003 (Logistics)

Question: Which Order should receive the new Quote Line Item?
Answer: Depends on which service the Quote Line Item relates to

If Quote Line Item is for waste collection → Select PO-ES-001
If Quote Line Item is for commercial service → Select PO-CS-002
```

**Double-Check Before Proceeding**:
- ✅ PO Number matches intended Order
- ✅ Department code is correct (ES vs CS vs LS)
- ✅ No other similar PO Numbers confused
- ✅ If unsure, cancel and verify with supervisor

### Step 4: Select Quote Line Items to Add

**Flow Screen: "Select Quote Line Items"**

**What You'll See**:
- List of Quote Line Items not yet "Generated"
- Checkboxes to select which items to add
- May show all available items or only new ones

**Actions**:
1. Review list of available Quote Line Items
2. Select (check) the items you want to add to Order
3. Verify quantities and prices look correct
4. Click **Next** or **Continue**

### Step 5: Review Summary

**Flow Screen: "Summary" or "Confirm"**

**What You'll See**:
- Summary of changes to be made
- Order Number that will receive products
- List of Quote Line Items being added
- Quantities and prices

**Actions**:
1. **Verify** Order Number is correct
2. **Verify** Quote Line Items match what you selected
3. **Verify** quantities are correct
4. If everything correct: Click **Finish** or **Submit**
5. If something wrong: Click **Back** to change selections or **Cancel** to start over

### Step 6: Verify Results

**After Flow Completes**:

1. Flow redirects to Order record
2. Navigate to **Order Products** related list
3. **Verify** new products appear in list
4. **Check** quantities match Quote Line Items
5. **Check** prices are correct
6. **Check** product names match Quote

**If Products Missing**:
1. Check other Orders for same Account (may have selected wrong PO)
2. Check Quote Line Items - verify "Generated" checkbox is TRUE
3. Contact supervisor if unable to locate products

---

## Common Mistakes and How to Avoid Them

### Mistake #1: Selecting Wrong PO

**Symptoms**:
- Products don't appear on expected Order
- Found products on different Order for same Account

**Root Cause**: Selected wrong PO from dropdown (especially when Account has multiple POs)

**Prevention**:
1. **Write down** correct PO Number before starting Flow
2. **Match exactly** in dropdown (character by character)
3. **Understand** department codes (ES, CS, LS, etc.)
4. **Double-check** before clicking Next
5. **If unsure**, cancel and ask supervisor

**Recovery**:
- Manually add products to correct Order
- Or delete from wrong Order and re-run Flow with correct PO

### Mistake #2: Selecting Wrong Quote Line Items

**Symptoms**:
- Wrong products added to Order
- Products missing from Order

**Root Cause**: Checked wrong items in Quote Line Item selection screen

**Prevention**:
1. **Review carefully** each item before checking
2. **Verify** product names match what you intend to add
3. **Check quantities** match expectations
4. **Read twice**, click once

**Recovery**:
- Delete incorrect Order Products
- Add correct products manually or re-run Flow

### Mistake #3: Not Verifying After Completion

**Symptoms**:
- User assumes Flow worked correctly
- Discovers issues later (customer complaint, billing error)

**Root Cause**: Did not verify Order Products after Flow completion

**Prevention**:
1. **Always** navigate to Order after Flow
2. **Always** check Order Products related list
3. **Always** verify quantities and prices
4. Make verification a habit (muscle memory)

**Recovery**:
- Catch errors early before customer impact
- Fix immediately rather than later

---

## Training Checklist for New Users

### Before First Use

- [ ] Read this complete guide
- [ ] Understand Account PO structure (ES vs CS vs LS)
- [ ] Know how to find correct PO Number
- [ ] Understand Quote Line Item "Generated" checkbox
- [ ] Know where "Generate Order" button is located

### During First Use (Supervisor Present)

- [ ] Supervisor confirms correct PO selected
- [ ] User verifies each screen before clicking Next
- [ ] User explains their selections out loud
- [ ] Supervisor confirms final results correct

### After First Use

- [ ] User independently verifies Order Products
- [ ] User documents any questions/confusion
- [ ] Supervisor follows up within 24 hours

### Ongoing Competency

- [ ] User completes 5+ successful additions without errors
- [ ] User can explain process to another new user
- [ ] User knows who to contact for help

---

## Best Practices for NewOrg

### For Individual Users

1. **Keep PO reference handy**: Have Order record open in another tab
2. **Use consistent naming**: PO Numbers should be clear and unambiguous
3. **Document decisions**: Note which PO used for which Quote (in notes)
4. **Ask when unsure**: Better to ask than add to wrong Order
5. **Verify immediately**: Check Order Products right after Flow completes

### For Supervisors

1. **Train thoroughly**: Don't rush through training
2. **Monitor new users**: First 5 uses supervised
3. **Provide quick reference**: Laminated card with step-by-step process
4. **Clear escalation path**: Who to contact for issues
5. **Regular audits**: Spot-check Order Products match Quotes

### For Administrators

1. **Clear PO naming convention**: ES-001, CS-002, etc.
2. **Limit POs per Account**: Reduce confusion
3. **Document PO usage rules**: When to use ES vs CS
4. **Flow error handling**: Ensure clear error messages
5. **Training documentation**: Keep this guide updated

---

## Troubleshooting Guide

### Issue: "I can't find the Generate Order button"

**Solution**:
1. Check you're on Quote record page (not Quote Line Item)
2. Check button may be in different location (check actions menu)
3. Verify your user profile has permission to use Flow
4. Contact administrator if button missing

### Issue: "Dropdown doesn't show the Order I need"

**Possible Causes**:
1. Order is for different Account than Quote
2. Order is in Draft status (may not show)
3. Order is already closed/completed
4. Order doesn't have associated PO Number

**Solution**:
1. Verify Quote Account matches Order Account
2. Check Order status - may need to activate first
3. Create new Order if needed
4. Contact administrator if PO Number missing

### Issue: "Products added to wrong Order"

**Root Cause**: Selected wrong PO in dropdown

**Solution**:
1. Navigate to wrong Order
2. Delete incorrect Order Products
3. Navigate to correct Order
4. Manually add products OR re-run Flow with correct PO

### Issue: "Quote Line Items not showing in selection screen"

**Possible Causes**:
1. Quote Line Items already "Generated"
2. Quote Line Items in Draft status
3. Flow filter excluding certain products

**Solution**:
1. Check "Generated" checkbox on Quote Line Items
2. Verify Quote Line Items are not in Draft
3. Contact administrator if Filter issues

---

## Migration Notes for NewOrg

### No Code Migration Required

**This is process documentation only** - no technical components to migrate.

**Training Materials to Create**:
1. Quick reference card (1-page laminated)
2. Video walkthrough (5 minutes)
3. FAQ document
4. Supervisor training checklist

### NewOrg-Specific Considerations

**Verify in NewOrg**:
1. "Generate Order" button location (may differ from OldOrg)
2. Flow screen layouts (may have different fields)
3. PO Number format (ensure consistent naming)
4. User permissions (all sales reps can access Flow)

**Testing in NewOrg**:
1. Test with Account that has multiple POs
2. Verify correct PO selection works
3. Verify wrong PO selection can be recovered
4. Ensure error messages are clear

---

## Success Metrics

### Individual User Success

- ✅ 100% of Quote Line Items added to correct Orders
- ✅ Zero escalations due to wrong PO selection
- ✅ User completes process in under 2 minutes
- ✅ User verifies Order Products after every Flow execution

### Team Success

- ✅ Zero customer complaints about wrong products
- ✅ Zero billing errors from wrong Order Products
- ✅ 100% of new users trained within first week
- ✅ Supervisor spot-checks show 100% accuracy

### System Success

- ✅ All Quote Line Items marked "Generated" correctly
- ✅ All Order Products match Quote Line Items
- ✅ No orphaned Quote Line Items
- ✅ Clear audit trail of who added what when

---

## Related Documentation

**Source**: OldOrg user training issue (Oct 10, 2025)

**Type**: Process documentation / user training

**No Code Components**: This is training material only

---

**Document Version**: 1.0
**Last Updated**: October 22, 2025
**Maintained By**: Training Team
