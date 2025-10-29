/**
 * @description Test class for RLCSCreditInvoiceReallocateAction
 */

@IsTest
public with sharing class RLCSCreditInvoiceReallocateActionTest {
    private static Account customerAccount;
    private static Account vendorAccount;
    private static Map<String, RLCS_Charge__c> rlcsChargesByRef;
    private static final Date DEFAULT_DATE = Date.newInstance(2019,1,1);
    private static Map<String, Invoice__c> invoicesByRef;

    static {}

    private static void init() {
        // Get Customer record type for Account
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        
        // Create a client account
        customerAccount = new Account(
            Name = 'Big Company',
            RecordTypeId = customerRecordTypeId,
            comp_house__Company_Number__c = '12345678'
        );
        insert customerAccount;

        // Create a vendor account
        vendorAccount = new Account(
            Name = 'Vendor 1',
            Type = 'Supplier',
            comp_house__Company_Number__c = '87654321'
        );
        insert vendorAccount;

        // Create some sites (adapting from existing pattern)
        Map<String, Site__c> sitesByName = new Map<String, Site__c>();
        sitesByName.put('Site1', new Site__c(Name = 'Site 1', Account__c = customerAccount.Id));
        sitesByName.put('Site2', new Site__c(Name = 'Site 2', Account__c = customerAccount.Id));
        sitesByName.put('Site3', new Site__c(Name = 'Site 3', Account__c = customerAccount.Id));
        insert sitesByName.values();

        // Create a depot record (required by original test pattern)
        Depot__c depotRec = new Depot__c();
        depotRec.Name = 'Test Depot';
        depotRec.Permit_Reference__c = 'ZZ1234AA';
        insert depotRec;

        // Create Product and Order to satisfy trigger requirements
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Order testOrder = new Order(
            AccountId = customerAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;

        // Create RLCS Jobs with Order_Product relationship to prevent trigger errors
        Map<String, RLCS_Job__c> rlcsJobsByRef = new Map<String, RLCS_Job__c>();
        for (Integer i = 1; i <= 6; i++) {
            RLCS_Job__c rlcsJob = new RLCS_Job__c(
                Customer_Account__c = customerAccount.Id,
                Status__c = 'Open',
                Delivery_Date__c = DEFAULT_DATE,
                Order_Product__c = testOrderItem.Id
            );
            rlcsJobsByRef.put('RJob' + i, rlcsJob);
        }
        insert rlcsJobsByRef.values();

        // Create RLCS charges for reallocation testing
        rlcsChargesByRef = new Map<String, RLCS_Charge__c>();
        Map<Id, String> rlcsJobRefsById = new Map<Id, String>();
        
        for (String jobRef : rlcsJobsByRef.keySet()) {
            RLCS_Job__c rlcsJob = rlcsJobsByRef.get(jobRef);
            
            // Create manual charges
            RLCS_Charge__c manualCharge = new RLCS_Charge__c(
                RLCS_Job__c = rlcsJob.Id,
                Charge_Type__c = 'Transport',
                Date__c = DEFAULT_DATE,
                Sales_Price__c = 123.56,
                Cost__c = 200.56,
                Sales_Account__c = customerAccount.Id,
                Vendor_Account__c = vendorAccount.Id,
                Description__c = 'Test manual charge'
            );
            rlcsChargesByRef.put('MC_' + jobRef, manualCharge);
            
            // Create tonnage charges  
            RLCS_Charge__c tonnageCharge = new RLCS_Charge__c(
                RLCS_Job__c = rlcsJob.Id,
                Charge_Type__c = 'Transport',
                Date__c = DEFAULT_DATE,
                Sales_Price__c = 50.00,
                Cost__c = 30.00,
                Sales_Account__c = customerAccount.Id,
                Vendor_Account__c = vendorAccount.Id,
                Description__c = 'Test tonnage charge'
            );
            rlcsChargesByRef.put('TC_' + jobRef, tonnageCharge);
            
            // Create transport charges
            RLCS_Charge__c transportCharge = new RLCS_Charge__c(
                RLCS_Job__c = rlcsJob.Id,
                Charge_Type__c = 'Transport',
                Date__c = DEFAULT_DATE,
                Sales_Price__c = 75.00,
                Cost__c = 60.00,
                Sales_Account__c = customerAccount.Id,
                Vendor_Account__c = vendorAccount.Id,
                Description__c = 'Test transport charge'
            );
            rlcsChargesByRef.put('TR_' + jobRef, transportCharge);
            
            // Create rebate charges
            RLCS_Charge__c rebateCharge = new RLCS_Charge__c(
                RLCS_Job__c = rlcsJob.Id,
                Charge_Type__c = 'Transport',
                Date__c = DEFAULT_DATE,
                Sales_Price__c = 25.00,
                Cost__c = 20.00,
                Sales_Account__c = customerAccount.Id,
                Vendor_Account__c = vendorAccount.Id,
                Description__c = 'Test rebate charge'
            );
            rlcsChargesByRef.put('RB_' + jobRef, rebateCharge);
            
            rlcsJobRefsById.put(rlcsJob.Id, jobRef);
        }
        insert rlcsChargesByRef.values();

        // Create automatic RLCS Job charges using the service
        for (String jobRef : rlcsJobsByRef.keySet()) {
            RLCS_Job__c rlcsJob = rlcsJobsByRef.get(jobRef);
            RLCS_Charge__c autoJobCharge = RLCSChargeService.createAutoJobCharge(
                rlcsJob,
                RLCSChargeService.JOB_CHARGE_TYPE_JOB
            );
            autoJobCharge.Sales_Price__c = 250;
            autoJobCharge.Sales_Account__c = customerAccount.Id;
            autoJobCharge.Vendor_Account__c = vendorAccount.Id;
            rlcsChargesByRef.put('AC_' + jobRef, autoJobCharge);
        }
        
        // Insert the auto charges
        List<RLCS_Charge__c> autoCharges = new List<RLCS_Charge__c>();
        for (String key : rlcsChargesByRef.keySet()) {
            if (key.startsWith('AC_')) {
                autoCharges.add(rlcsChargesByRef.get(key));
            }
        }
        insert autoCharges;

        System.assertEquals(30, rlcsChargesByRef.size()); // 6 jobs * 5 charges each

        // Create some invoices. One draft and one sent.
        invoicesByRef = new Map<String, Invoice__c>();
        invoicesByRef.put('draft', new Invoice__c(
            Account__c = customerAccount.Id, 
            Raised_Date__c = System.today(),
            Status__c = 'Draft'
        ));
        invoicesByRef.put('sent', new Invoice__c(
            Account__c = customerAccount.Id, 
            Raised_Date__c = System.today(),
            Status__c = 'Sent'
        ));
        insert invoicesByRef.values();
    }

    @TestSetup 
    private static void setup() {}

    /**
     * @description Test the process of reallocating part of an invoice with RLCS charges
     */
    @IsTest
    static void testPartialInvoiceReallocation() {

        // Setup standard data
        init();

        // Allocate some of the RLCS charges to the sent invoice
        rlcsChargesByRef.get('MC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('AC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('TC_RJob2').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('TR_RJob3').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('RB_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        update rlcsChargesByRef.values();

        // Start the test
        Test.startTest();

        // Create the input parameters to reallocate RLCS charges
        RLCSCreditInvoiceReallocateAction.InputParameters inputParams = new RLCSCreditInvoiceReallocateAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.reallocateWholeInvoice = false;
        inputParams.selectedRLCSChargeIds = rlcsChargesByRef.get('MC_RJob1').Id + '; ' + rlcsChargesByRef.get('AC_RJob1').Id + '; ' + rlcsChargesByRef.get('TC_RJob2').Id;

        // Execute the reallocation action
        List<RLCSCreditInvoiceReallocateAction.ActionResults> actionResults = RLCSCreditInvoiceReallocateAction.createInvoiceCreditReallocationCharges(new List<RLCSCreditInvoiceReallocateAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Verify results
        System.assertEquals(1, actionResults.size());
        System.assertEquals(invoicesByRef.get('sent').Id, actionResults[0].invoiceId);
        System.assertEquals(true, actionResults[0].isSuccess);
        System.assertEquals(3, actionResults[0].jobChargeCount);
        
        // Calculate expected total: 123.56 + 250 + 50.00 = 423.56
        System.assertEquals(423.56, actionResults[0].reallocationTotal);

        // Verify that reallocation charges were created
        List<RLCS_Charge__c> newRLCSCharges = [SELECT Id, Sales_Price__c, Sales_Account__c, Vendor_Account__c, Charge_Type__c, RLCS_Job__c, Cost__c 
                                              FROM RLCS_Charge__c 
                                              WHERE Id NOT IN :rlcsChargesByRef.values()];
        System.assertEquals(3, newRLCSCharges.size());
        
        // Verify the reallocated charges have correct values
        for (RLCS_Charge__c newCharge : newRLCSCharges) {
            // Check charge type and account assignment based on original charge type logic
            if (newCharge.Charge_Type__c == 'Transport') {
                // Transport charges have swapped accounts
                System.assertEquals(vendorAccount.Id, newCharge.Sales_Account__c);
                System.assertEquals(customerAccount.Id, newCharge.Vendor_Account__c);
            } else if (newCharge.Charge_Type__c == 'RLCS Job') {
                // RLCS Job charges keep original account assignment
                System.assertEquals(customerAccount.Id, newCharge.Sales_Account__c);
                System.assertEquals(vendorAccount.Id, newCharge.Vendor_Account__c);
                System.assertEquals(0, newCharge.Cost__c); // Cost should be 0 for RLCS Job charges
            }
            
            // Verify prices based on the original test data
            System.assert(newCharge.Sales_Price__c == 123.56 || newCharge.Sales_Price__c == 250 || newCharge.Sales_Price__c == 50.00);
        }
    }

    /**
     * @description Test reallocating a whole invoice
     */
    @IsTest
    static void testWholeInvoiceReallocation() {
        
        // Setup standard data
        init();

        // Allocate multiple RLCS charges to the sent invoice
        rlcsChargesByRef.get('MC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('AC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('TC_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('TR_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('RB_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('MC_RJob2').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        update rlcsChargesByRef.values();

        // Start the test
        Test.startTest();

        // Create the input parameters to reallocate whole invoice
        RLCSCreditInvoiceReallocateAction.InputParameters inputParams = new RLCSCreditInvoiceReallocateAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.reallocateWholeInvoice = true;

        // Execute the reallocation action
        List<RLCSCreditInvoiceReallocateAction.ActionResults> actionResults = RLCSCreditInvoiceReallocateAction.createInvoiceCreditReallocationCharges(new List<RLCSCreditInvoiceReallocateAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Verify results
        System.assertEquals(1, actionResults.size());
        System.assertEquals(invoicesByRef.get('sent').Id, actionResults[0].invoiceId);
        System.assertEquals(true, actionResults[0].isSuccess);
        System.assertEquals(6, actionResults[0].jobChargeCount); // All 6 charges should be reallocated

        // Verify that reallocation charges were created
        List<RLCS_Charge__c> newRLCSCharges = [SELECT Id FROM RLCS_Charge__c WHERE Id NOT IN :rlcsChargesByRef.values()];
        System.assertEquals(6, newRLCSCharges.size());
    }

    /**
     * @description Test reallocation with rebate and transport charges (account swapping)
     */
    @IsTest
    static void testRebateAndTransportReallocation() {
        
        // Setup standard data
        init();

        // Allocate rebate and transport charges to the sent invoice
        rlcsChargesByRef.get('RB_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        rlcsChargesByRef.get('TR_RJob1').Sales_Invoice__c = invoicesByRef.get('sent').Id;
        update rlcsChargesByRef.values();

        // Start the test
        Test.startTest();

        // Create the input parameters to reallocate these specific charges
        RLCSCreditInvoiceReallocateAction.InputParameters inputParams = new RLCSCreditInvoiceReallocateAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.reallocateWholeInvoice = false;
        inputParams.selectedRLCSChargeIds = rlcsChargesByRef.get('RB_RJob1').Id + '; ' + rlcsChargesByRef.get('TR_RJob1').Id;

        // Execute the reallocation action
        List<RLCSCreditInvoiceReallocateAction.ActionResults> actionResults = RLCSCreditInvoiceReallocateAction.createInvoiceCreditReallocationCharges(new List<RLCSCreditInvoiceReallocateAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Verify results
        System.assertEquals(1, actionResults.size());
        System.assertEquals(2, actionResults[0].jobChargeCount);

        // Verify that reallocation charges were created with swapped accounts
        List<RLCS_Charge__c> newRLCSCharges = [SELECT Id, Sales_Price__c, Sales_Account__c, Vendor_Account__c, Charge_Type__c 
                                              FROM RLCS_Charge__c 
                                              WHERE Id NOT IN :rlcsChargesByRef.values()];
        System.assertEquals(2, newRLCSCharges.size());
        
        for (RLCS_Charge__c newCharge : newRLCSCharges) {
            System.assertEquals('Transport', newCharge.Charge_Type__c);
            // Since we're now using Trade for all types, verify the prices to identify which was originally which
            if (newCharge.Sales_Price__c == 25.00) {
                // This was originally a rebate charge, accounts should be swapped
                System.assertEquals(vendorAccount.Id, newCharge.Sales_Account__c);
                System.assertEquals(customerAccount.Id, newCharge.Vendor_Account__c);
            } else if (newCharge.Sales_Price__c == 75.00) {
                // This was originally a transport charge, accounts should be swapped
                System.assertEquals(vendorAccount.Id, newCharge.Sales_Account__c);
                System.assertEquals(customerAccount.Id, newCharge.Vendor_Account__c);
            }
        }
    }

    /**
     * @description Test with empty selection
     */
    @IsTest
    static void testEmptySelection() {
        
        // Setup standard data
        init();

        // Start the test
        Test.startTest();

        // Create the input parameters with no selections
        RLCSCreditInvoiceReallocateAction.InputParameters inputParams = new RLCSCreditInvoiceReallocateAction.InputParameters();
        inputParams.invoiceId = invoicesByRef.get('sent').Id;
        inputParams.reallocateWholeInvoice = false;
        inputParams.selectedRLCSChargeIds = null;

        // Execute the reallocation action
        List<RLCSCreditInvoiceReallocateAction.ActionResults> actionResults = RLCSCreditInvoiceReallocateAction.createInvoiceCreditReallocationCharges(new List<RLCSCreditInvoiceReallocateAction.InputParameters>{inputParams});
        
        // Stop the test
        Test.stopTest();

        // Should have no results since no charges were selected
        System.assertEquals(0, actionResults.size());
    }
}