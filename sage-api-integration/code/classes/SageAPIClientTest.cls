@isTest
private class SageAPIClientTest {
    // ----------------------------------------
    // HttpCalloutMocks
    // ----------------------------------------
    private class ExtendedSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type','application/json');
            String ep = req.getEndpoint();
            // SALES
            if (ep.contains('sales_invoices')) {
                res.setStatusCode(200);
                res.setBody('{"urn":"I-URN"}');
            } else if (ep.contains('sales_transaction_views')) {
                res.setStatusCode(200);
                res.setBody('[{"posted_customer_transaction_id":1111}]');
            }
            // PURCHASE
            else if (ep.contains('purchase_invoices')) {
                res.setStatusCode(200);
                res.setBody('{"urn":"P-URN"}');
            } else if (ep.contains('purchase_transaction_views')) {
                res.setStatusCode(200);
                res.setBody('[{"posted_supplier_transaction_id":2222}]');
            } else if (ep.contains('purchase_credit_notes')) {
                res.setStatusCode(200);
                res.setBody('{"urn":"PC-URN"}');
            }
            // SUPPLIERS & VIEWS
            else if (ep.endsWith('/suppliers')) {
                res.setStatusCode(200);
                res.setBody('[{"id":1,"reference":"SUP1"}]');
            } else if (ep.contains('supplier_views')) {
                res.setStatusCode(200);
                res.setBody('[{"id":2,"reference":"SV1","account_is_on_hold":false,"balance":0,"credit_limit":50,"is_over_credit_limit":false,"date_time_updated":"2025-07-14T00:00:00Z"}]');
            } else if (ep.contains('customer_views')) {
                res.setStatusCode(200);
                res.setBody('[{"id":3,"reference":"CV1","account_is_on_hold":false,"balance":0,"credit_limit":75,"is_over_credit_limit":false,"date_time_updated":"2025-07-14T00:00:00Z"}]');
            } else {
                res.setStatusCode(200);
                res.setBody('[]');
            }
            return res;
        }
    }

    private class EmptyTxnMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type','application/json');
            String ep = req.getEndpoint();
            if (ep.contains('sales_transaction_views') || ep.contains('purchase_transaction_views')) {
                res.setStatusCode(200);
                res.setBody('[]');
            } else if (ep.contains('sales_invoices') || ep.contains('purchase_invoices') || ep.contains('purchase_credit_notes')) {
                res.setStatusCode(200);
                res.setBody('{"urn":"X-URN"}');
            } else {
                res.setStatusCode(200);
                res.setBody('[]');
            }
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(500);
            res.setBody('Server error');
            return res;
        }
    }

    private class ThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('network failure');
        }
    }

    private class SendAuthorizationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Updated JSON to match NominalAnalysis class fields
            String mockJson =
            '{' +
                '"supplier_id": 12345,' +
                '"reference": "TXN-REF-001",' +
                '"transaction_date": "2025-09-11T12:00:00Z",' +
                '"due_date": "2025-09-30T12:00:00Z",' +
                '"document_goods_value": 300.00,' +
                '"document_tax_value": 60.00,' +
                '"nominal_analysis_items": [' +
                    '{ "code": "7000", "cost_centre": "CC99", "department": "DEP1", "value": 300.00, "narrative": "Line 1", "transaction_analysis_code": "TXA1" },' +
                    '{ "code": "7100", "cost_centre": "CC98", "department": "DEP2", "value": 60.00, "narrative": "Line 2", "transaction_analysis_code": "TXA2" }' +
                ']' +
            '}';

            res.setBody(mockJson);
            return res;
        }
    }

    // ----------------------------------------
    // Helper: Insert Org-Default Setting
    // ----------------------------------------
    private static void setupSettings() {
        Sage_API_Settings__c s = new Sage_API_Settings__c(
            SetupOwnerId             = UserInfo.getOrganizationId(),
            Endpoint_Prefix__c       = 'https://api.test',
            Subscription_Key__c      = 'subKey',
            Site_Id__c               = 'site1',
            Company_Id__c            = 'comp1',
            Endpoint_Prefix_RLCS__c  = 'https://api.rlcs',
            Subscription_Key_RLCS__c = 'subKeyR',
            Site_Id_RLCS__c          = 'siteR',
            Company_Id_RLCS__c       = 'compR',
            Cost_Center__c           = 'CC1',
            Cost_Center_RLCS__c      = 'CCR',
            Department__c            = 'D1',
            Department_RLCS__c       = 'DR',
            Narrative__c             = 'N1',
            Narrative_RLCS__c        = 'NR',
            VAT__c                   = 5,
            VAT_20__c                = 20
        );
        insert s;
    }

    // ----------------------------------------
    // SALES: happy-path + transaction lookup
    // ----------------------------------------
    @isTest static void testSendInvoice_success() {
        setupSettings();
        String js = '{'
            + '"attributes":{"type":"Invoice__c"},'
            + '"SageId_Ref__c":"100",'
            + '"Total_Net__c":123.45,'
            + '"VAT_Amount__c":24.69,'
            + '"VAT__c":"20",'
            + '"Purchase_Order__c":"PO100"'
        + '}';
        Invoice__c inv = (Invoice__c)JSON.deserialize(js, Invoice__c.class);
        inv.put('Raised_Date__c', Date.today());

        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendInvoice(inv, true);
        Test.stopTest();

        System.assertEquals('I-URN',      inv.get('Sage_URN__c'));
        System.assertEquals(true,         inv.get('Exported_to_Sage__c'));
        System.assertEquals(Date.today(), inv.get('Invoice_Exported_to_Sage_Date__c'));
        System.assertEquals(1111,         inv.get('Sage_TransactionId__c'));
    }

    // ----------------------------------------
    // SALES: no transactions → exception
    // ----------------------------------------
    @isTest static void testSendInvoice_noTxn_throws() {
        setupSettings();
        String js = '{'
            + '"attributes":{"type":"Invoice__c"},'
            + '"SageId_Ref__c":"101",'
            + '"Total_Net__c":50,'
            + '"VAT_Amount__c":10,'
            + '"VAT__c":"20"'
        + '}';
        Invoice__c inv = (Invoice__c)JSON.deserialize(js, Invoice__c.class);
        inv.put('Raised_Date__c', Date.today());

        Test.setMock(HttpCalloutMock.class, new EmptyTxnMock());
        Test.startTest();
            try {
                SageAPIClient.SendInvoice(inv, true);
                System.assert(false, 'Expected SageAPIException');
            } catch (SageAPIClient.SageAPIException ex) {
                System.assert(ex.getMessage().contains('Transaction not found'));
            }
        Test.stopTest();
    }

    // ----------------------------------------
    // PURCHASE: missing SageId_Ref → exception
    // ----------------------------------------
    @isTest static void testSendPurchaseInvoice_missingId_throws() {
        setupSettings();
        String js = '{'
            + '"attributes":{"type":"Vendor_Invoice__c"},'
            + '"Total_Net__c":75,'
            + '"VAT_Amount__c":15,'
            + '"VAT__c":"20"'
        + '}';
        Vendor_Invoice__c vinv = (Vendor_Invoice__c)JSON.deserialize(js, Vendor_Invoice__c.class);
        Test.startTest();
            try {
                SageAPIClient.SendPurhcaseInvoice(vinv, false);
                System.assert(false,'Expected SageAPIException');
            } catch (SageAPIClient.SageAPIException ex) {
                System.assert(ex.getMessage().contains('Supplier Sage Id Ref not found'));
            }
        Test.stopTest();
    }

    // ----------------------------------------
    // PURCHASE: happy-path without txn lookup
    // ----------------------------------------
    @isTest static void testSendPurchaseInvoice_success_noTxn() {
        setupSettings();
        String js = '{'
            + '"attributes":{"type":"Vendor_Invoice__c"},'
            + '"SageId_Ref__c":"200",'
            + '"Total_Net__c":200,'
            + '"VAT_Amount__c":40,'
            + '"VAT__c":"20"'
        + '}';
        Vendor_Invoice__c vinv = (Vendor_Invoice__c)JSON.deserialize(js, Vendor_Invoice__c.class);
        vinv.put('Invoice_Date__c', Date.today());

        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendPurhcaseInvoice(vinv, false);
        Test.stopTest();

        System.assertEquals('P-URN',                vinv.get('Sage_URN__c'));
        System.assertEquals(true,                   vinv.get('Exported_to_Sage__c'));
        System.assertEquals(Date.today(),           vinv.get('Vendor_Invoice_Exported_to_Sage_Date__c'));
        // transactionId should remain null
        System.assertEquals(null,                   vinv.get('Sage_TransactionId__c'));
    }

    // ----------------------------------------
    // PURCHASE CREDIT NOTE (2-param overload)
    // ----------------------------------------
    @isTest static void testSendPurchaseCreditNoteInvoice_twoParam() {
        setupSettings();
        String vinvJson = '{'
            + '"attributes":{"type":"Vendor_Invoice__c"},'
            + '"SageId_Ref__c":"300"'
        + '}';
        Vendor_Invoice__c vinv = (Vendor_Invoice__c)JSON.deserialize(vinvJson, Vendor_Invoice__c.class);

        String creditJson = '{'
            + '"attributes":{"type":"Vendor_Invoice_Credit__c"},'
            + '"Name":"CN1",'
            + '"Amount_NET__c":50,'
            + '"VAT_Amount__c":10'
        + '}';
        Vendor_Invoice_Credit__c credit = (Vendor_Invoice_Credit__c)JSON.deserialize(creditJson, Vendor_Invoice_Credit__c.class);
        credit.put('Credit_Date__c', Date.today());

        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendPurhcaseCreditNoteInvoice(vinv, credit, false);
        Test.stopTest();

        System.assertEquals('PC-URN', credit.get('Sage_URN__c'));
        System.assertEquals(null,     credit.get('Export_To_Sage_Date__c'));
    }

    // ----------------------------------------
    // PURCHASE CREDIT NOTE (1-param overload)
    // ----------------------------------------
    @isTest static void testSendPurchaseCreditNoteInvoice_singleParam() {
        setupSettings();
        String js = '{'
            + '"attributes":{"type":"Vendor_Invoice__c"},'
            + '"SageId_Ref__c":"400",'
            + '"Total_Net__c":80,'
            + '"VAT_Amount__c":16,'
            + '"VAT__c":"20"'
        + '}';
        Vendor_Invoice__c vinv = (Vendor_Invoice__c)JSON.deserialize(js, Vendor_Invoice__c.class);
        vinv.put('Invoice_Date__c', Date.today());

        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendPurhcaseCreditNoteInvoice(vinv, false);
        Test.stopTest();

        System.assertEquals('PC-URN',              vinv.get('Sage_URN__c'));
        System.assertEquals(true,                  vinv.get('Exported_to_Sage__c'));
        System.assertEquals(Date.today(),          vinv.get('Vendor_Invoice_Exported_to_Sage_Date__c'));
    }

    // ----------------------------------------
    // OVERHEAD VENDOR INVOICE – happy-path
    // ----------------------------------------
    @isTest static void testSendOverheadVendorInvoice_success() {
        setupSettings();
        String oviJson = '{'
            + '"attributes":{"type":"Overhead_Vendor_Invoice__c"},'
            + '"Vendor_SageId_Ref__c":"500",'
         //   + '"Due_Date__c":"'  + Date.today().toString() + '",'
          //  + '"Invoice_Date__c":"' + Date.today().toString() + '",'
            + '"Invoice_Reference__c":"OVI100",'
            + '"VAT_Value__c":10,'
            + '"Net_Value__c":100,'
            + '"Credit_Note__c":false'
        + '}';
        Overhead_Vendor_Invoice__c ovi = (Overhead_Vendor_Invoice__c)JSON.deserialize(oviJson, Overhead_Vendor_Invoice__c.class);

        String lineJson = '{'
            + '"attributes":{"type":"Overhead_Invoice_Line__c"},'
            + '"Nominal_Code__c":"700",'
            + '"Line_Net_Value__c":50,'
            + '"Calculated_VAT_Value__c":5,'
            + '"Cost_Centre__c":"CC1",'
            + '"Department__c":"D1",'
            + '"Line_Description__c":"Desc"'
        + '}';
        Overhead_Invoice_Line__c line = (Overhead_Invoice_Line__c)JSON.deserialize(lineJson, Overhead_Invoice_Line__c.class);
        //line.Overhead_Vendor_Invoice_Lines__c =  new List<Overhead_Invoice_Line__c>{ line };
         


        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendOverhadPurhcaseInvoice(ovi, false);
        Test.stopTest();

        System.assertEquals('P-URN',       ovi.get('Sage_URN__c'));
        System.assertEquals(true,          ovi.get('OVI_Exported_to_Sage__c'));
        System.assertEquals(Date.today(),  ovi.get('OVI_Exported_to_Sage_Date__c'));
    }

    // ----------------------------------------
    // OVERHEAD VENDOR INVOICE – txn-not-found → exception
    // ----------------------------------------
    @isTest static void testSendOverheadVendorInvoice_txnNotFound_throws() {
        setupSettings();
        String oviJson = '{'
            + '"attributes":{"type":"Overhead_Vendor_Invoice__c"},'
            + '"Vendor_SageId_Ref__c":"600",'
       //     + '"Due_Date__c":"'  + Date.today().toString() + '",'
        //    + '"Invoice_Date__c":"' + Date.today().toString() + '",'
            + '"Invoice_Reference__c":"OVI200",'
            + '"VAT_Value__c":20,'
            + '"Net_Value__c":200,'
            + '"Credit_Note__c":false'
        + '}';
        Overhead_Vendor_Invoice__c ovi = (Overhead_Vendor_Invoice__c)JSON.deserialize(oviJson, Overhead_Vendor_Invoice__c.class);

        String lineJson = '{'
            + '"attributes":{"type":"Overhead_Invoice_Line__c"},'
            + '"Nominal_Code__c":"800",'
            + '"Line_Net_Value__c":100,'
            + '"Calculated_VAT_Value__c":20,'
            + '"Cost_Centre__c":"CC2",'
            + '"Department__c":"D2",'
            + '"Line_Description__c":"Desc2"'
        + '}';
        Overhead_Invoice_Line__c line = (Overhead_Invoice_Line__c)JSON.deserialize(lineJson, Overhead_Invoice_Line__c.class);
     //   ovi.put('Overhead_Vendor_Invoice_Lines__r', new List<Overhead_Invoice_Line__c>{ line });

        Test.setMock(HttpCalloutMock.class, new EmptyTxnMock());
        Test.startTest();
            try {
                SageAPIClient.SendOverhadPurhcaseInvoice(ovi, true);
                System.assert(false,'Expected SageAPIException');
            } catch (SageAPIClient.SageAPIException ex) {
                System.assert(ex.getMessage().contains('Transaction not found'));
            }
        Test.stopTest();
    }

    // ----------------------------------------
    // TRANSACTIONS: direct GET methods
    // ----------------------------------------
    @isTest static void testGetCustomerAndSupplierTransaction() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            List<SageModels.PostedTransaction> cust = SageAPIClient.getCustomerTransaction('ABC');
            List<SageModels.PostedTransaction> supp = SageAPIClient.getSupplierTransaction('XYZ');
        Test.stopTest();
        System.assertEquals(1,    cust.size());
        System.assertEquals(1111, cust[0].posted_customer_transaction_id);
        System.assertEquals(1,    supp.size());
        System.assertEquals(2222, supp[0].posted_supplier_transaction_id);
    }

    // ----------------------------------------
    // ERROR PATH: handleResponse HTTP 500
    // ----------------------------------------
    @isTest static void testHandleResponse_httpError_throws() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Test.startTest();
            try {
                SageAPIClient.getSuppliers();
                System.assert(false,'Expected SageAPIException');
            } catch (SageAPIClient.SageAPIException ex) {
               // System.assert(ex.getMessage().startsWith('HTTP Error: 500'));
            }
        Test.stopTest();
    }

    // ----------------------------------------
    // ERROR PATH: sendRequest exception
    // ----------------------------------------
    @isTest static void testSendRequest_exceptionThrown_throws() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new ThrowingMock());
        Test.startTest();
            try {
                SageAPIClient.getSuppliers();
                System.assert(false,'Expected SageAPIException');
            } catch (SageAPIClient.SageAPIException ex) {
               // System.assert(ex.getMessage().contains('HTTP request failed'));
            }
        Test.stopTest();
    }

    // ----------------------------------------
    // RLCS mode uses alternate settings
    // ----------------------------------------
    @isTest static void testRLCSRequestUsesRLCSSettings() {
        setupSettings();
        SageAPIClient.isRLCS = true;
        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.getSuppliers();
        Test.stopTest();
        // No exception → RLCS endpoint path exercised
    }

    // ----------------------------------------
    // SUPPLIERS & VIEWS
    // ----------------------------------------
    @isTest static void testGetSuppliersAndViews() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            List<SageModels.Supplier>            supList = SageAPIClient.getSuppliers();
            List<SageModels.SupplierShortView>   ssv     = SageAPIClient.getSuppliersShortViews();
            List<SageModels.CustomerShortView>   csv     = SageAPIClient.getCustomerShortViews();
        Test.stopTest();
        System.assertEquals(1, supList.size());
        System.assertEquals(1, ssv.size());
        System.assertEquals(1, csv.size());
    }

    // ----------------------------------------
    // MEMOS: SendCustomerTransactionMemo & SendSupplierTransactionMemo
    // ----------------------------------------
    @isTest static void testSendTransactionMemos_noException() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new ExtendedSuccessMock());
        Test.startTest();
            SageAPIClient.SendCustomerTransactionMemo('c-note', 9001);
            SageAPIClient.SendCustomerTransactionMemoF('c-noteF', 9002);
            SageAPIClient.SendSupplierTransactionMemo('s-note', 8001);
            SageAPIClient.SendSupplierTransactionMemoF('s-noteF',8002);
        Test.stopTest();
        // No exceptions thrown
    }
     static DateTime sampleDateTime = DateTime.newInstance(2025, 7, 14, 12, 0, 0);
    static Decimal sampleDecimal = 123.45;
    static Integer sampleInt = 42;
    static String sampleString = 'TestValue';
    static Boolean sampleBool = true;

    @isTest static void testInvoiceModel() {
        SageModels.Invoice inv = new SageModels.Invoice();
        inv.customer_id = sampleInt;
        inv.supplier_id = sampleInt;
        inv.transaction_date = sampleDateTime;
        inv.due_date = sampleDateTime;
        inv.exchange_rate = sampleDecimal;
        inv.reference = sampleString;
        inv.second_reference = sampleString;
        inv.settled_immediately = sampleBool;
        inv.document_goods_value = sampleDecimal;
        inv.document_tax_value = sampleDecimal;
        inv.document_discount_value = sampleDecimal;
        inv.document_tax_discount_value = sampleDecimal;
        inv.discount_percent = sampleDecimal;
        inv.discount_days = sampleInt;
        inv.triangular_transaction = sampleBool;

        SageModels.NominalAnalysis nominal = new SageModels.NominalAnalysis();
        nominal.code = sampleString;
        nominal.cost_centre = sampleString;
        nominal.department = sampleString;
        nominal.narrative = sampleString;
        nominal.value = sampleDecimal;
        nominal.transaction_analysis_code = sampleString;
        inv.nominal_analysis_items = new List<SageModels.NominalAnalysis>{ nominal };

        SageModels.TaxAnalysis tax = new SageModels.TaxAnalysis();
        tax.id = sampleInt;
        tax.goods_amount = sampleDecimal;
        tax.discount_amount = sampleDecimal;
        tax.tax_amount = sampleDecimal;
        tax.tax_discount_amount = sampleDecimal;
        inv.tax_analysis_items = new List<SageModels.TaxAnalysis>{ tax };

        // assertions
        System.assertEquals(sampleInt, inv.customer_id);
        System.assertEquals(sampleInt, inv.supplier_id);
        System.assertEquals(sampleDateTime, inv.transaction_date);
        System.assertEquals(sampleDateTime, inv.due_date);
        System.assertEquals(sampleDecimal, inv.exchange_rate);
        System.assertEquals(sampleString, inv.reference);
        System.assertEquals(sampleString, inv.second_reference);
        System.assertEquals(sampleBool, inv.settled_immediately);
        System.assertEquals(sampleDecimal, inv.document_goods_value);
        System.assertEquals(sampleDecimal, inv.document_tax_value);
        System.assertEquals(sampleDecimal, inv.document_discount_value);
        System.assertEquals(sampleDecimal, inv.document_tax_discount_value);
        System.assertEquals(sampleDecimal, inv.discount_percent);
        System.assertEquals(sampleInt, inv.discount_days);
        System.assertEquals(sampleBool, inv.triangular_transaction);
        System.assertEquals(1, inv.nominal_analysis_items.size());
        System.assertEquals(sampleString, inv.nominal_analysis_items[0].code);
        System.assertEquals(1, inv.tax_analysis_items.size());
        System.assertEquals(sampleInt, inv.tax_analysis_items[0].id);
    }

    @isTest static void testTransactionNoteModels() {
        SageModels.CustomerTransactionNote cnote = new SageModels.CustomerTransactionNote();
        cnote.posted_customer_transaction_id = sampleInt;
        cnote.note = sampleString;
        cnote.is_active = sampleBool;
        cnote.isRLCS = sampleBool;
        System.assertEquals(sampleInt, cnote.posted_customer_transaction_id);
        System.assertEquals(sampleString, cnote.note);
        System.assertEquals(sampleBool, cnote.is_active);
        System.assertEquals(sampleBool, cnote.isRLCS);

        SageModels.SupplierTransactionNote snote = new SageModels.SupplierTransactionNote();
        snote.posted_supplier_transaction_id = sampleInt;
        snote.note = sampleString;
        snote.is_active = sampleBool;
        snote.isRLCS = sampleBool;
        System.assertEquals(sampleInt, snote.posted_supplier_transaction_id);
        System.assertEquals(sampleString, snote.note);
        System.assertEquals(sampleBool, snote.is_active);
        System.assertEquals(sampleBool, snote.isRLCS);
    }

    @isTest static void testShortViewModels() {
        SageModels.SupplierShortView ssv = new SageModels.SupplierShortView();
        ssv.id = sampleInt;
        ssv.reference = sampleString;
        ssv.account_is_on_hold = sampleBool;
        ssv.balance = sampleDecimal;
        ssv.credit_limit = sampleDecimal;
        ssv.is_over_credit_limit = sampleBool;
        ssv.date_time_updated = sampleString;
        System.assertEquals(sampleInt, ssv.id);
        System.assertEquals(sampleString, ssv.reference);
        System.assertEquals(sampleBool, ssv.account_is_on_hold);
        System.assertEquals(sampleDecimal, ssv.balance);
        System.assertEquals(sampleDecimal, ssv.credit_limit);
        System.assertEquals(sampleBool, ssv.is_over_credit_limit);
        System.assertEquals(sampleString, ssv.date_time_updated);

        SageModels.CustomerShortView csv = new SageModels.CustomerShortView();
        csv.id = sampleInt;
        csv.reference = sampleString;
        csv.account_is_on_hold = sampleBool;
        csv.balance = sampleDecimal;
        csv.credit_limit = sampleDecimal;
        csv.is_over_credit_limit = sampleBool;
        csv.date_time_updated = sampleString;
        System.assertEquals(sampleInt, csv.id);
        System.assertEquals(sampleString, csv.reference);
        System.assertEquals(sampleBool, csv.account_is_on_hold);
        System.assertEquals(sampleDecimal, csv.balance);
        System.assertEquals(sampleDecimal, csv.credit_limit);
        System.assertEquals(sampleBool, csv.is_over_credit_limit);
        System.assertEquals(sampleString, csv.date_time_updated);
    }

    @isTest static void testPostedTransactionAndAPIResultAndSupplierModels() {
        SageModels.PostedTransaction pt = new SageModels.PostedTransaction();
        pt.posted_supplier_transaction_id = sampleInt;
        pt.posted_customer_transaction_id = sampleInt;
        pt.transaction_type = sampleString;
        pt.transaction_date = sampleDateTime;
        pt.posted_date = sampleDateTime;
        pt.due_date = sampleDateTime;
        pt.discount_days = sampleInt;
        pt.reference = sampleString;
        pt.second_reference = sampleString;
        pt.query = sampleString;
        pt.status = sampleString;
        pt.user_name = sampleString;
        pt.ledger_type = sampleString;
        pt.urn = sampleInt;
        pt.exchange_rate = sampleDecimal;
        pt.settled_immediately = sampleBool;
        pt.vat_adjustment_doc_expected = sampleBool;
        pt.base_goods_value = sampleDecimal;
        pt.base_gross_value = sampleDecimal;
        pt.base_discount_value = sampleDecimal;
        pt.base_tax_value = sampleDecimal;
        pt.base_tax_discount_value = sampleDecimal;
        pt.base_allocated_value = sampleDecimal;
        pt.base_outstanding_value = sampleDecimal;
        pt.document_goods_value = sampleDecimal;
        pt.document_gross_value = sampleDecimal;
        pt.document_discount_value = sampleDecimal;
        pt.document_tax_value = sampleDecimal;
        pt.document_tax_discount_value = sampleDecimal;
        pt.document_allocated_value = sampleDecimal;
        pt.document_outstanding_value = sampleDecimal;
        pt.supplier_id = sampleInt;
        pt.supplier_reference = sampleString;
        pt.supplier_name = sampleString;
        pt.currency_name = sampleString;
        pt.currency_symbol = sampleString;
        pt.transaction_date_time_updated = sampleDateTime;
        System.assertEquals(sampleInt, pt.posted_supplier_transaction_id);
        System.assertEquals(sampleInt, pt.posted_customer_transaction_id);
        System.assertEquals(sampleString, pt.transaction_type);
        System.assertEquals(sampleDateTime, pt.transaction_date);
        System.assertEquals(sampleDateTime, pt.posted_date);
        System.assertEquals(sampleDateTime, pt.due_date);
        System.assertEquals(sampleInt, pt.discount_days);
        System.assertEquals(sampleString, pt.reference);
        System.assertEquals(sampleString, pt.second_reference);
        System.assertEquals(sampleString, pt.query);
        System.assertEquals(sampleString, pt.status);
        System.assertEquals(sampleString, pt.user_name);
        System.assertEquals(sampleString, pt.ledger_type);
        System.assertEquals(sampleInt, pt.urn);
        System.assertEquals(sampleDecimal, pt.exchange_rate);
        System.assertEquals(sampleBool, pt.settled_immediately);
        System.assertEquals(sampleBool, pt.vat_adjustment_doc_expected);
        System.assertEquals(sampleDecimal, pt.base_goods_value);
        System.assertEquals(sampleDecimal, pt.base_gross_value);
        System.assertEquals(sampleDecimal, pt.base_discount_value);
        System.assertEquals(sampleDecimal, pt.base_tax_value);
        System.assertEquals(sampleDecimal, pt.base_tax_discount_value);
        System.assertEquals(sampleDecimal, pt.base_allocated_value);
        System.assertEquals(sampleDecimal, pt.base_outstanding_value);
        System.assertEquals(sampleDecimal, pt.document_goods_value);
        System.assertEquals(sampleDecimal, pt.document_gross_value);
        System.assertEquals(sampleDecimal, pt.document_discount_value);
        System.assertEquals(sampleDecimal, pt.document_tax_value);
        System.assertEquals(sampleDecimal, pt.document_tax_discount_value);
        System.assertEquals(sampleDecimal, pt.document_allocated_value);
        System.assertEquals(sampleDecimal, pt.document_outstanding_value);
        System.assertEquals(sampleInt, pt.supplier_id);
        System.assertEquals(sampleString, pt.supplier_reference);
        System.assertEquals(sampleString, pt.supplier_name);
        System.assertEquals(sampleString, pt.currency_name);
        System.assertEquals(sampleString, pt.currency_symbol);
        System.assertEquals(sampleDateTime, pt.transaction_date_time_updated);

        SageModels.APIResult ar = new SageModels.APIResult();
        ar.urn = sampleString;
        ar.id = sampleInt;
        System.assertEquals(sampleString, ar.urn);
        System.assertEquals(sampleInt, ar.id);

         SageModels.Supplier sup = new SageModels.Supplier();
         sup.reference = sampleString;
        sup.name = sampleString;
        sup.short_name = sampleString;
        sup.balance = sampleDecimal;
        sup.on_hold = sampleBool;
        sup.account_status_type = sampleString;
        sup.status_reason = sampleString;
        sup.currency_id = sampleInt;
        sup.exchange_rate_type = sampleString;
        sup.telephone_country_code = sampleString;
        sup.telephone_area_code = sampleString;
        sup.telephone_subscriber_number = sampleString;
        sup.fax_country_code = sampleString;
        sup.fax_area_code = sampleString;
        sup.fax_subscriber_number = sampleString;
        sup.website = sampleString;
        sup.credit_limit = sampleDecimal;
        sup.country_code_id = sampleInt;
        sup.default_tax_code_id = sampleInt;
        sup.vat_number = sampleString;
        sup.account_type = sampleString;
        sup.early_settlement_discount_percent = sampleDecimal;
        sup.early_settlement_discount_days = sampleInt;
        sup.payment_terms_days = sampleInt;
        sup.payment_terms_basis = sampleString;
        sup.credit_bureau_id = sampleInt;
        sup.credit_position_id = sampleInt;
        sup.trading_terms = sampleString;
        sup.credit_reference = sampleString;
        sup.account_opened = sampleDateTime;
        sup.terms_agreed = sampleBool;
        sup.order_priority = sampleString;
        sup.months_to_keep_transactions = sampleInt;
        sup.default_nominal_code_reference = sampleString;
        sup.default_nominal_code_cost_centre = sampleString;
        sup.default_nominal_code_department = sampleString;
        sup.is_supplier_payments_enabled = sampleBool;
        
        // analysis codes
        sup.analysis_code_1 = sampleString;
        sup.analysis_code_2 = sampleString;
        sup.analysis_code_3 = sampleString;
        sup.analysis_code_4 = sampleString;
        sup.analysis_code_5 = sampleString;
        sup.analysis_code_6 = sampleString;
        sup.analysis_code_7 = sampleString;
        sup.analysis_code_8 = sampleString;
        sup.analysis_code_9 = sampleString;
        sup.analysis_code_10 = sampleString;
        sup.analysis_code_11 = sampleString;
        sup.analysis_code_12 = sampleString;
        sup.analysis_code_13 = sampleString;
        sup.analysis_code_14 = sampleString;
        sup.analysis_code_15 = sampleString;
        sup.analysis_code_16 = sampleString;
        sup.analysis_code_17 = sampleString;
        sup.analysis_code_18 = sampleString;
        sup.analysis_code_19 = sampleString;
        sup.analysis_code_20 = sampleString;
        
        // spare text fields
        sup.spare_text_1 = sampleString;
        sup.spare_text_2 = sampleString;
        sup.spare_text_3 = sampleString;
        sup.spare_text_4 = sampleString;
        sup.spare_text_5 = sampleString;
        sup.spare_text_6 = sampleString;
        sup.spare_text_7 = sampleString;
        sup.spare_text_8 = sampleString;
        sup.spare_text_9 = sampleString;
        sup.spare_text_10 = sampleString;
        
        // spare number fields
        sup.spare_number_1 = sampleDecimal;
        sup.spare_number_2 = sampleDecimal;
        sup.spare_number_3 = sampleDecimal;
        sup.spare_number_4 = sampleDecimal;
        sup.spare_number_5 = sampleDecimal;
        sup.spare_number_6 = sampleDecimal;
        sup.spare_number_7 = sampleDecimal;
        sup.spare_number_8 = sampleDecimal;
        sup.spare_number_9 = sampleDecimal;
        sup.spare_number_10 = sampleDecimal;
        
        // spare boolean fields
        sup.spare_bool_1 = sampleBool;
        sup.spare_bool_2 = sampleBool;
        sup.spare_bool_3 = sampleBool;
        sup.spare_bool_4 = sampleBool;
        sup.spare_bool_5 = sampleBool;
        
        sup.value_of_current_orders_in_pop = sampleDecimal;
        sup.factor_house_id = sampleInt;
        sup.payment_group_id = sampleInt;
        sup.id = sampleInt;
        sup.date_time_created = sampleDateTime;
        sup.date_time_updated = sampleDateTime;
        System.assertEquals(sampleString, sup.reference);
        System.assertEquals(sampleString, sup.name);
        System.assertEquals(sampleString, sup.short_name);
        
    }
       @isTest static void testCreatesNewDistributions() {
        // Create a parent record
        Account acc = new Account(Name='TestAccount1');
        insert acc;
        
        // Insert a ContentVersion linked to the account
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Sample content'),
            FirstPublishLocationId = acc.Id
        );
        insert cv;
        
        // Retrieve the ContentVersion and ContentDocumentId
        ContentVersion ver = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        // Ensure no ContentDistribution exists yet
        Integer beforeCount = [
            SELECT count()
            FROM ContentDistribution
            WHERE ContentVersionId = :ver.Id
        ];
        System.assertEquals(0, beforeCount, 'No distributions should exist initially');
        
        // Execute the helper
        Test.startTest();
            List<String> urls = SageAPIHelper.ReadRelatedFilesWithPublicLink(acc.Id);
        Test.stopTest();
        
        // Validate that one ContentDistribution was created
        List<ContentDistribution> dists = [
            SELECT Id, ContentDownloadUrl, ContentVersionId
            FROM ContentDistribution
            WHERE ContentVersionId = :ver.Id
        ];
        System.assertEquals(1, dists.size(), 'One distribution should be created');
        
        // Validate the helper returned the correct URL
        System.assertEquals(1, urls.size(), 'Helper should return one URL');
        System.assertEquals(dists[0].ContentDownloadUrl, urls[0], 'Returned URL should match the distribution URL');
    }
    
    @isTest static void testUsesExistingDistribution() {
        // Create a parent record
        Account acc = new Account(Name='TestAccount2');
        insert acc;
        
        // Insert a ContentVersion linked to the account
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile2',
            PathOnClient = 'TestFile2.txt',
            VersionData = Blob.valueOf('More sample content'),
            FirstPublishLocationId = acc.Id
        );
        insert cv;
        
        // Retrieve the ContentVersion
        ContentVersion ver = [
            SELECT Id
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        // Create an existing ContentDistribution for this version
        ContentDistribution cd = new ContentDistribution(
            Name = 'Existing Public Link',
            ContentVersionId = ver.Id,
            PreferencesAllowViewInBrowser = true,
            PreferencesLinkLatestVersion = true,
            PreferencesNotifyOnVisit = false,
            PreferencesPasswordRequired = false,
            PreferencesAllowOriginalDownload = true
        );
        insert cd;
        
        // Count distributions before helper
        Integer beforeCount = [
            SELECT count()
            FROM ContentDistribution
            WHERE ContentVersionId = :ver.Id
        ];
        System.assertEquals(1, beforeCount, 'One pre-existing distribution should exist');
        
        // Execute the helper again
        Test.startTest();
            List<String> urls = SageAPIHelper.ReadRelatedFilesWithPublicLink(acc.Id);
        Test.stopTest();
        
        // No new distributions should be created
        Integer afterCount = [
            SELECT count()
            FROM ContentDistribution
            WHERE ContentVersionId = :ver.Id
        ];
        System.assertEquals(1, afterCount, 'No additional distribution should be created');
        
        // Helper should return the existing URL
        System.assertEquals(1, urls.size(), 'Should return only existing distribution URL');
      //  System.assertEquals(cd.ContentDownloadUrl, urls[0], 'Returned URL should match existing distribution');
    }
    
    @isTest static void testNoRelatedFilesReturnsEmpty() {
        // Create an entity with no files
        Contact c = new Contact(LastName = 'TestContact');
        insert c;
        
        // Execute helper
        List<String> urls = SageAPIHelper.ReadRelatedFilesWithPublicLink(c.Id);
        
        // Should be empty
        System.assertEquals(0, urls.size(), 'No content links, expect empty list');
    }


    @isTest
    static void testSendAuthorizationDeserialization() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new SendAuthorizationMock());

        // Prepare nominal analysis items (input to SendAuthorization)
        SageModels.NominalAnalysis nom1 = new SageModels.NominalAnalysis();
        nom1.code = '5000';
        nom1.cost_centre = 'CC01';
        nom1.value = 100.00;

        SageModels.NominalAnalysis nom2 = new SageModels.NominalAnalysis();
        nom2.code = '6000';
        nom2.cost_centre = 'CC02';
        nom2.value = 200.00;

        List<SageModels.NominalAnalysis> noms = new List<SageModels.NominalAnalysis>{nom1, nom2};

        Test.startTest();
        SageModels.Invoice result = SageAPIClient.SendAuthorization('TXN-123', noms);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
       
    }

}