@isTest
public class InvoiceTriggerTest {
        private static Account clientAcc;
    private static OrderItem orderProduct;
    private static Account supplierAcc;
    private static Invoice__c salesInvoice;

    
    static {}

    private static void init() {
        // Create a client
        clientAcc = TestFactory.createClient('Building Co Ltd');
        insert clientAcc;

        // Create a supplier
        supplierAcc = TestFactory.createSupplier('Skips R Us');
        insert supplierAcc;

        // Create an order
        Order ord = TestFactory.createOrder('Order 1',supplierAcc.Id);
        insert ord;

        // Create a product
        Product2 prod = TestFactory.createProduct('Test Product');
        insert prod;

        // Create a price book entry
        PricebookEntry pbe = TestFactory.createPricebookEntry(prod.Id,Test.getStandardPricebookId(),123.45);
        insert pbe;
        
        Depot__c depotRec = new Depot__c(
            Name = 'Test Depot',
            Permit_Reference__c = 'JK1234LM'
        );
        insert depotRec;

        // Create an order line
        orderProduct = TestFactory.createOrderProduct(ord.Id,supplierAcc.Id,prod.Id,pbe.Id, 200,250, 100, 15, 20);
        orderProduct.Sales_Tonnage_incl__c = 1;
        orderProduct.Depot_Dispose__c = depotRec.Id;
        insert orderProduct;

        Payment_Run__c paymentRun = TestFactory.createPaymentRun(1843.21,Date.today() ,null);
        insert paymentRun;

        salesInvoice = TestFactory.createInvoice(clientAcc.Id, System.today(),TestFactory.INVOICE_STATUS_DRAFT);
        insert salesInvoice;
        
        salesInvoice.Payment_Run__c = paymentRun.Id;
        update salesInvoice;

       
    }
    public static testmethod void testInvoiceTrigger(){
         init();

        // Start the test
        Test.startTest();
        Account accountRec = new Account();
        accountRec.Name = 'Test Account';
        insert accountRec;
        
        Site__c siteRec = new Site__c();
        siteRec.Name = 'Test Site';
        siteRec.Account__c = accountRec.Id;
        insert siteRec;  
        
        Invoice__c invoiceRec = new Invoice__c(); 
        invoiceRec.Site__c = siteRec.Id;
        invoiceRec.Account__c = accountRec.Id;
        insert invoiceRec;
        
        
        invoiceRec.Site__c = null;
        update invoiceRec;
        
        
        invoiceRec.Site__c = siteRec.Id;
        update invoiceRec;
        
        Job__c job = TestFactory.createJob(clientAcc.Id,'Open','Variable', orderProduct.Id);
        job.Partner_Tonnage_charge_thereafter__c = 15;
        job.Sales_Tonnage_charge_thereafter__c = 20;
        job.Supplier_Price__c = 443.21;
        job.Sales_Price__c = 300;
        job.Waste_Type_2__c = 'Glass';
        insert job;

        // Get the Job Charges for the
        List<Job_Charge__c> jobCharges = [SELECT Id, RecordType.DeveloperName, Cost__c, Sales_Price__c, Charge_Type__c FROM Job_Charge__c WHERE Job__c=:job.Id];
        Job_Charge__c charge=  jobCharges[0];
        charge.Invoice__c=invoiceRec.Id;
        update charge;
        
        delete invoiceRec;
        Test.stopTest();
        
        
    }
}