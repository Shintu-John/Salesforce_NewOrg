public with sharing class SageAPIClient {

    public static Boolean isRLCS=false;
    private static final Sage_API_Settings__c settings = Sage_API_Settings__c.getOrgDefaults();
    public class SageAPIException extends Exception {
    }
    public SageAPIClient() {
    }
    private static HttpResponse sendRequest(HttpRequest req) {
        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);
            return handleResponse(res);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new SageAPIException('HTTP request failed: ' + e.getMessage());
        }
    }

    private static HttpResponse handleResponse(HttpResponse res) {
        System.debug('HTTP Response Code: ' + res.getStatusCode());
        System.debug('HTTP Response Body: ' + res.getBody());

        if (res.getStatusCode() != 200) {
            throw new SageAPIException('HTTP Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        return res;
    }
	
    private static HttpRequest getRequest(string method,string url)
    {
       

        HttpRequest req = new HttpRequest();
        if(isRLCS==null || isRLCS == false)
        {
            req.setEndpoint( 'callout:'+settings.Endpoint_Prefix__c+'/'+url);    
            req.setHeader('ocp-apim-subscription-key', settings.Subscription_Key__c);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Site', settings.Site_Id__c);
            req.setHeader('X-Company', settings.Company_Id__c);
            
        }
        else {
            req.setEndpoint('callout:'+settings.Endpoint_Prefix_RLCS__c	+'/'+url);
           req.setHeader('ocp-apim-subscription-key', settings.Subscription_Key_RLCS__c);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Site', settings.Site_Id_RLCS__c);
            req.setHeader('X-Company', settings.Company_Id_RLCS__c);
        }
        
        req.setMethod(method);
        System.debug('endpoint: '+ req.getEndpoint());
        // Set headers
      
    
        return req;
    }
       
    public static void SendInvoice(Invoice__c invoiceRec,Boolean readTransactionId)
    {

        SageModels.Invoice invoice = new SageModels.Invoice();
        String row = '\n';
        //AccountNumber
        invoice.customer_id= integer.valueOf(invoiceRec.SageId_Ref__c);// invoiceRec.Sage_Ref__c;
        invoice.document_goods_value=math.abs(invoiceRec.Total_Net__c);
        invoice.reference=invoiceRec.Name;
        invoice.second_reference=invoiceRec.Purchase_Order__c != null ? invoiceRec.Purchase_Order__c.left(20) : null;
        invoice.transaction_date=invoiceRec.Raised_Date__c;
        invoice.document_tax_value=Math.abs(invoiceRec.VAT_Amount__c);
        
        SageModels.NominalAnalysis nominalAnalysis = new SageModels.NominalAnalysis();  
        nominalAnalysis.code = (isRLCS?invoiceRec.RLCS_Nominal_Code__c: invoiceRec.Nominal_Code__c);
        nominalAnalysis.value=Math.abs(invoiceRec.Total_Net__c);
        nominalAnalysis.cost_centre=isRLCS? String.isBlank(invoiceRec.RLCS_Cost_Centre__c) ? settings.Cost_Center_RLCS__c : invoiceRec.RLCS_Cost_Centre__c:settings.Cost_Center__c;
        nominalAnalysis.department=isRLCS? settings.Department_RLCS__c: settings.Department__c;	 
        nominalAnalysis.narrative=isRLCS? settings.Narrative_RLCS__c : settings.Narrative__c	;
        
        invoice.nominal_analysis_items = new List<SageModels.NominalAnalysis>();
        invoice.nominal_analysis_items.add(nominalAnalysis);

        SageModels.TaxAnalysis taxAnalysis = new SageModels.TaxAnalysis();  
        if(isRLCS)
        {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20_RLCS__c.intValue() : settings.VAT_RLCS__c.intValue()); 
        }
        else {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20__c.intValue() : settings.VAT__c.intValue());     
        }
        
        taxAnalysis.goods_amount =math.abs(invoiceRec.Total_Net__c);
        taxAnalysis.tax_amount = math.abs(invoiceRec.VAT_Amount__c);
        invoice.tax_analysis_items = new List<SageModels.TaxAnalysis>();
        invoice.tax_analysis_items.add(taxAnalysis);

        if(invoiceRec.Credit_Note__c)
        {
            String urn = SendCreditNote(invoice);
            invoiceRec.Sage_URN__c = urn;    
        }
        else {
            String urn = SendInvoice(invoice);
            invoiceRec.Sage_URN__c = urn;    
        }
        if(invoiceRec.Sage_URN__c !=  null)
        {       invoiceRec.Exported_to_Sage__c = true;
                invoiceRec.Invoice_Exported_to_Sage_Date__c = System.now().date();
                if(readTransactionId)
                {
                    List<SageModels.PostedTransaction>  transactions= getCustomerTransaction(invoiceRec.Sage_URN__c);
                    if(transactions.size() == 1){
                        invoiceRec.Sage_TransactionId__c = transactions[0].posted_customer_transaction_id;
                        
                    }
                    else {
                     throw new SageAPIException('Error: ' + 'Transaction not found');
                        
                    }
                }
              
        }
        
    }
    public static void SendPurhcaseInvoice(Vendor_Invoice__c invoiceRec,Boolean readTransactionId)
    {

        SageModels.Invoice invoice = new SageModels.Invoice();
        
        //AccountNumber
        //invoice.supplier_id = Integer.valueOf(invoiceRec.Sage_Ref__c);
        if(invoiceRec.SageId_Ref__c == null)
        {
            throw new SageAPIException('Supplier Sage Id Ref not found for Invoice: ' + invoiceRec.Name);
            
        }
        invoice.supplier_id = Integer.valueOf(invoiceRec.SageId_Ref__c);

        invoice.document_goods_value=math.abs(invoiceRec.Total_Net__c);
        invoice.reference=invoiceRec.Name;
        invoice.second_reference=invoiceRec.Vendor_Invoice_URN__c;
        invoice.transaction_date=invoiceRec.Invoice_Date__c;
        invoice.document_tax_value=Math.abs(invoiceRec.VAT_Amount__c);
        
        SageModels.NominalAnalysis nominalAnalysis = new SageModels.NominalAnalysis();  
        if(isRLCS)
        {
            nominalAnalysis.code =  String.isNotBlank(invoiceRec.RLCS_Nominal_Code__c) ?  invoiceRec.RLCS_Nominal_Code__c:null;    
        }
        else {
            nominalAnalysis.code = String.valueOf(invoiceRec.Nominal_Code__c);    
        }
        
        nominalAnalysis.value=Math.abs(invoiceRec.Total_Net__c);
        if(isRLCS)
        {
            nominalAnalysis.cost_centre= (String.isBlank(invoiceRec.RLCS_Cost_Centre__c) ? settings.Cost_Center_RLCS__c : invoiceRec.RLCS_Cost_Centre__c);
            nominalAnalysis.department=settings.Department_RLCS__c;
        }
        else {
            nominalAnalysis.cost_centre=settings.Cost_Center__c;    
            nominalAnalysis.department=settings.Department__c;
        }
        
        
        nominalAnalysis.narrative=invoiceRec.Name;
        
        invoice.nominal_analysis_items = new List<SageModels.NominalAnalysis>();
        invoice.nominal_analysis_items.add(nominalAnalysis);

        SageModels.TaxAnalysis taxAnalysis = new SageModels.TaxAnalysis();  
        
        if(isRLCS)
        {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20_RLCS__c.intValue() : settings.VAT_RLCS__c.intValue()); 
        }
        else {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20__c.intValue() : settings.VAT__c.intValue());     
        }

        taxAnalysis.goods_amount =math.abs(invoiceRec.Total_Net__c);
        taxAnalysis.tax_amount = math.abs(invoiceRec.VAT_Amount__c);
        invoice.tax_analysis_items = new List<SageModels.TaxAnalysis>();
        invoice.tax_analysis_items.add(taxAnalysis);

     
            String urn = SendPurchaseInvoice(invoice);
            invoiceRec.Sage_URN__c = urn;    
       
        if(invoiceRec.Sage_URN__c !=  null)
        {       invoiceRec.Exported_to_Sage__c = true;
                invoiceRec.Vendor_Invoice_Exported_to_Sage_Date__c = System.now().date();
                if(readTransactionId)
                {
                    List<SageModels.PostedTransaction>  transactions= getSupplierTransaction(urn);
                    if(transactions.size() == 1){
                        invoiceRec.Sage_TransactionId__c = transactions[0].posted_supplier_transaction_id;
                        if(isRLCS)
                        {
                            SageModels.Invoice inv=SendAuthorization(String.valueOf(invoiceRec.Sage_TransactionId__c), invoice.nominal_analysis_items);
                        }
                    }
                    else {
                        throw new SageAPIException('Error: ' + 'Transaction not found');
                    }
                }
              
        }
        
    }
    public static void SendPurhcaseCreditNoteInvoice(Vendor_Invoice__c invoiceRec, Vendor_Invoice_Credit__c creditinvoiceRec,Boolean readTransactionId)
    {

        SageModels.Invoice invoice = new SageModels.Invoice();
        
        //AccountNumber
        //invoice.supplier_id = Integer.valueOf(invoiceRec.Sage_Ref__c);
        invoice.supplier_id = Integer.valueOf(invoiceRec.SageId_Ref__c);//delete

        invoice.document_goods_value=math.abs(creditinvoiceRec.Amount_NET__c);//math.abs(invoiceRec.Credit_Total__c); Glen suggested.
        invoice.reference=creditinvoiceRec.Name;
        invoice.second_reference=invoiceRec.Vendor_Invoice_URN__c;
        invoice.transaction_date=creditinvoiceRec.Credit_Date__c;
        invoice.document_tax_value=Math.abs(creditinvoiceRec.VAT_Amount__c);
        
        SageModels.NominalAnalysis nominalAnalysis = new SageModels.NominalAnalysis();  
         
        nominalAnalysis.code = (isRLCS?invoiceRec.RLCS_Nominal_Code__c: String.valueof(invoiceRec.Nominal_Code__c));
        nominalAnalysis.value=Math.abs(creditinvoiceRec.Amount_NET__c);
        if(isRLCS)
        {
          nominalAnalysis.cost_centre= (String.isBlank(invoiceRec.RLCS_Cost_Centre__c) ? settings.Cost_Center_RLCS__c : invoiceRec.RLCS_Cost_Centre__c);
          nominalAnalysis.department=settings.Department_RLCS__c;
           
        
        }
        
        else {
            nominalAnalysis.cost_centre=settings.Cost_Center__c;    
            nominalAnalysis.department= settings.Department__c;
        }
        
        nominalAnalysis.narrative=creditinvoiceRec.Name;
        
        invoice.nominal_analysis_items = new List<SageModels.NominalAnalysis>();
        invoice.nominal_analysis_items.add(nominalAnalysis);

        SageModels.TaxAnalysis taxAnalysis = new SageModels.TaxAnalysis();  
        if(isRLCS)
        {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20_RLCS__c.intValue() : settings.VAT_RLCS__c.intValue()); 
        }
        else {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20__c.intValue() : settings.VAT__c.intValue());     
        }
        
        taxAnalysis.goods_amount =math.abs(creditinvoiceRec.Amount_NET__c);
        taxAnalysis.tax_amount = math.abs(creditinvoiceRec.VAT_Amount__c);
        invoice.tax_analysis_items = new List<SageModels.TaxAnalysis>();
        invoice.tax_analysis_items.add(taxAnalysis);

      
            String urn = SendPurchaseCreditNote(invoice);
            creditinvoiceRec.Sage_URN__c = urn;    
       
        if(invoiceRec.Sage_URN__c !=  null){
        
                creditinvoiceRec.Export_To_Sage_Date__c = System.now().date();
                if(readTransactionId)
                {
                    List<SageModels.PostedTransaction>  transactions= getSupplierTransaction(urn);
                    if(transactions.size() == 1){
                        creditinvoiceRec.Sage_TransactionId__c = transactions[0].posted_supplier_transaction_id;
                    }
                    else {
                        throw new SageAPIException('Error: ' + 'Transaction not found');
                    }
                }
             
        }
        
    }
    public static void SendPurhcaseCreditNoteInvoice(Vendor_Invoice__c invoiceRec, Boolean readTransactionId)
    {

        SageModels.Invoice invoice = new SageModels.Invoice();
        
        //AccountNumber
        //invoice.supplier_id = Integer.valueOf(invoiceRec.Sage_Ref__c);
        if(String.isEmpty(invoiceRec.SageId_Ref__c))
        {
            throw new SageAPIException('Error: ' + 'Supplier Sage Id is not found for sending purchase credit note invoice.');
        }
        invoice.supplier_id = Integer.valueOf(invoiceRec.SageId_Ref__c);//delete
        if(invoiceRec.Total_Net__c == null)
        {
            throw new SageAPIException('Error: ' + 'No net value found for this purchase credit note invoice.');
        }
        invoice.document_goods_value=math.abs(invoiceRec.Total_Net__c);
        invoice.reference=invoiceRec.Name;
        invoice.second_reference=invoiceRec.Vendor_Invoice_URN__c;
        invoice.transaction_date=invoiceRec.Invoice_Date__c;
        invoice.document_tax_value=Math.abs(invoiceRec.VAT_Amount__c);
        
        SageModels.NominalAnalysis nominalAnalysis = new SageModels.NominalAnalysis();  
        nominalAnalysis.code = (isRLCS?invoiceRec.RLCS_Nominal_Code__c: String.valueOf(invoiceRec.Nominal_Code__c));
        nominalAnalysis.value=Math.abs(invoiceRec.Total_Net__c);
        nominalAnalysis.cost_centre=settings.Cost_Center__c;
        nominalAnalysis.department='BRO';
        nominalAnalysis.narrative=invoiceRec.Name;
        
        invoice.nominal_analysis_items = new List<SageModels.NominalAnalysis>();
        invoice.nominal_analysis_items.add(nominalAnalysis);

        SageModels.TaxAnalysis taxAnalysis = new SageModels.TaxAnalysis();  
        if(isRLCS)
        {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20_RLCS__c.intValue() : settings.VAT_RLCS__c.intValue()); 
        }
        else {
            taxAnalysis.id =  (invoiceRec.VAT__c == '20' ? settings.VAT_20__c.intValue() : settings.VAT__c.intValue());     
        }
        
        taxAnalysis.goods_amount =math.abs(invoiceRec.Total_Net__c);
        taxAnalysis.tax_amount = math.abs(invoiceRec.VAT_Amount__c);
        invoice.tax_analysis_items = new List<SageModels.TaxAnalysis>();
        invoice.tax_analysis_items.add(taxAnalysis);

     
            String urn = SendPurchaseCreditNote(invoice);
            invoiceRec.Sage_URN__c = urn;    
       
            if(invoiceRec.Sage_URN__c !=  null)
            {       invoiceRec.Exported_to_Sage__c = true;
                    invoiceRec.Vendor_Invoice_Exported_to_Sage_Date__c = System.now().date();
                    if(readTransactionId)
                    {
                        List<SageModels.PostedTransaction>  transactions= getSupplierTransaction(urn);
                        if(transactions.size() == 1){
                            invoiceRec.Sage_TransactionId__c = transactions[0].posted_supplier_transaction_id;
                        }
                        else {
                            throw new SageAPIException('Error: ' + 'Transaction not found');
                        }
                    }
                  
            }
        
    }
    public static void SendOverhadPurhcaseInvoice(Overhead_Vendor_Invoice__c invoiceRec,Boolean readTransactionId)
    {

        SageModels.Invoice invoice = new SageModels.Invoice();
        
        
      //  invoice.supplier_id = Integer.valueOf(invoiceRec.Vendor_Sage_Ref__c);
        invoice.supplier_id = Integer.valueOf(invoiceRec.Vendor_SageId_Ref__c);//delete
        invoice.due_date=invoiceRec.Due_Date__c;
        invoice.transaction_date=invoiceRec.Invoice_Date__c;
        invoice.reference=invoiceRec.Invoice_Reference__c;
        invoice.document_tax_value=Math.abs(invoiceRec.VAT_Value__c);
        invoice.document_goods_value=math.abs(invoiceRec.Net_Value__c);

        invoice.nominal_analysis_items = new List<SageModels.NominalAnalysis>();
        invoice.tax_analysis_items = new List<SageModels.TaxAnalysis>();
        
      
        
        
        for(Overhead_Invoice_Line__c line : invoiceRec.Overhead_Vendor_Invoice_Lines__r)
        {
            SageModels.NominalAnalysis nominalAnalysis = new SageModels.NominalAnalysis();  
            nominalAnalysis.code = line.Nominal_Code__c;
            nominalAnalysis.value=Math.abs(line.Line_Net_Value__c);
            nominalAnalysis.cost_centre=line.Cost_Centre__c;
            nominalAnalysis.department=line.Department__c;
            nominalAnalysis.narrative=line.Line_Description__c;
            invoice.nominal_analysis_items.add(nominalAnalysis);

            SageModels.TaxAnalysis taxAnalysis = new SageModels.TaxAnalysis();
            taxAnalysis.id =  (line?.Line_Net_Value__c > 0 ? settings.VAT_20__c.intValue() : settings.VAT__c.intValue());
            taxAnalysis.goods_amount =math.abs(line.Line_Net_Value__c);
            taxAnalysis.tax_amount = math.abs(line.Calculated_VAT_Value__c);
       
            invoice.tax_analysis_items.add(taxAnalysis);

        }
        

        if(invoiceRec.Credit_Note__c)
        {
            String urn = SendPurchaseCreditNote(invoice);
            invoiceRec.Sage_URN__c = urn;    
        }
        else {
            String urn = SendPurchaseInvoice(invoice);
            invoiceRec.Sage_URN__c = urn;    
        }
        if(invoiceRec.Sage_URN__c !=  null)
        {       invoiceRec.OVI_Exported_to_Sage__c = true;
                invoiceRec.OVI_Exported_to_Sage_Date__c = System.now().date();
                if(readTransactionId)
                {
                    List<SageModels.PostedTransaction>  transactions= getSupplierTransaction(invoiceRec.Sage_URN__c);
                    if(transactions.size() == 1){
                        invoiceRec.Sage_TransactionId__c = transactions[0].posted_supplier_transaction_id;
                    }
                    else {
                        throw new SageAPIException('Error: ' + 'Transaction not found'); 
                    }
                }
               
        }
        
    }

    public static List<SageModels.PostedTransaction> getSupplierTransaction(string urn) {
        HttpRequest req = getRequest('GET', 'purchase_transaction_views?$filter=urn%20eq%20' + urn);
        HttpResponse res = sendRequest(req);

        return (List<SageModels.PostedTransaction>) JSON.deserialize(res.getBody(), List<SageModels.PostedTransaction>.class);
    }

    public static List<SageModels.PostedTransaction> getCustomerTransaction(string urn) {
        HttpRequest req = getRequest('GET', 'sales_transaction_views?$filter=urn%20eq%20' + urn);
        HttpResponse res = sendRequest(req);

        return (List<SageModels.PostedTransaction>) JSON.deserialize(res.getBody(), List<SageModels.PostedTransaction>.class);
    }

    public static List<SageModels.Supplier> getSuppliers() {
        HttpRequest req = getRequest('GET', 'suppliers');
        HttpResponse res = sendRequest(req);

        return (List<SageModels.Supplier>) JSON.deserialize(res.getBody(), List<SageModels.Supplier>.class);
    }

    public static List<SageModels.SupplierShortView> getSuppliersShortViews() {
        HttpRequest req = getRequest('GET', 'supplier_views/?$select=id,reference,account_is_on_hold,balance,credit_limit,is_over_credit_limit,date_time_updated&$orderby=date_time_updated%20desc&$top=5000');
        HttpResponse res = sendRequest(req);

        return (List<SageModels.SupplierShortView>) JSON.deserialize(res.getBody(), List<SageModels.SupplierShortView>.class);
    }

    public static List<SageModels.CustomerShortView> getCustomerShortViews() {
        HttpRequest req = getRequest('GET', 'customer_views/?$select=id,reference,account_is_on_hold,balance,credit_limit,is_over_credit_limit,date_time_updated&$orderby=date_time_updated%20desc&$top=5000');
        HttpResponse res = sendRequest(req);

        return (List<SageModels.CustomerShortView>) JSON.deserialize(res.getBody(), List<SageModels.CustomerShortView>.class);
    }

    private static string SendInvoice(SageModels.Invoice invoice) {
        HttpRequest req = getRequest('POST', 'sales_invoices');

        System.debug('Send Invoice :'+invoice);
        req.setBody(JSON.serialize(invoice, true));

        HttpResponse res = sendRequest(req);
        SageModels.APIResult result = (SageModels.APIResult) JSON.deserialize(res.getBody(), SageModels.APIResult.class);

        return result.urn;
    }
    public static SageModels.Invoice SendAuthorization(string transactionId, List<SageModels.NominalAnalysis> noms)
    {
        
        HttpRequest req = getRequest('PUT', 'purchase_authorisations/'+transactionId);
        SageModels.Invoice invoice = new SageModels.Invoice();
        invoice.nominal_analysis_items=noms;
        String body = JSON.serialize(invoice, true);
        System.debug('Send Authorization for tranid '+transactionId +':'+body);
        req.setBody(body);

        HttpResponse res = sendRequest(req);
        SageModels.Invoice result = (SageModels.Invoice) JSON.deserialize(res.getBody(), SageModels.Invoice.class);
        System.debug('Send Authorization Response:'+res.getBody());
        return invoice;
    }

    private static string SendCreditNote(SageModels.Invoice invoice) {
        HttpRequest req = getRequest('POST', 'sales_credit_notes');
        String body = JSON.serialize(invoice, true);
        System.debug('Send Credit Note :'+body);
        req.setBody(body);

        HttpResponse res = sendRequest(req);
        SageModels.APIResult result = (SageModels.APIResult) JSON.deserialize(res.getBody(), SageModels.APIResult.class);

        return result.urn;
    }

    private static String SendPurchaseCreditNote(SageModels.Invoice invoice) {
        HttpRequest req = getRequest('POST', 'purchase_credit_notes'); 
        String body = JSON.serialize(invoice, true);
        System.debug('Send Purchase Credit Note :'+body);
        req.setBody(body);

        HttpResponse res = sendRequest(req);
        SageModels.APIResult result = (SageModels.APIResult) JSON.deserialize(res.getBody(), SageModels.APIResult.class);

        return result.urn;
    }

    private static String SendPurchaseInvoice(SageModels.Invoice invoice) {
        HttpRequest req = getRequest('POST', 'purchase_invoices');
        String body = JSON.serialize(invoice, true);
        System.debug('Send Purchase Invoice :'+body);
        req.setBody(body);

        HttpResponse res = sendRequest(req);
        SageModels.APIResult result = (SageModels.APIResult) JSON.deserialize(res.getBody(), SageModels.APIResult.class);

        return result.urn;
    }

    
    public static void SendCustomerTransactionMemo(String notes, Integer transactionId) {
        SageModels.CustomerTransactionNote note = new SageModels.CustomerTransactionNote();
        note.posted_customer_transaction_id = transactionId;
        note.note = notes;
        note.is_active = true;

        HttpRequest req = getRequest('POST', 'sales_posted_transaction_memos');
        req.setBody(JSON.serialize(note, true));

        sendRequest(req);
    }
    @future(callout = true)
    public static void SendCustomerTransactionMemoF(String notes, Integer transactionId) {
        System.debug('Sending Customer Transaction Memo');
        SageModels.CustomerTransactionNote note = new SageModels.CustomerTransactionNote();
        note.posted_customer_transaction_id = transactionId;
        note.note = notes;
        note.is_active = true;

        HttpRequest req = getRequest('POST', 'sales_posted_transaction_memos');
        req.setBody(JSON.serialize(note, true));

        sendRequest(req);
    }

    
    public static void SendSupplierTransactionMemo(String notes, Integer transactionId) {
        SageModels.SupplierTransactionNote note = new SageModels.SupplierTransactionNote();
        note.posted_supplier_transaction_id = transactionId;
        note.note = notes;
        note.is_active = true;

        HttpRequest req = getRequest('POST', 'purchase_posted_transaction_memos');
        req.setBody(JSON.serialize(note, true));

        sendRequest(req);
    }
    @future(callout = true)
    public static void SendSupplierTransactionMemoF(String notes, Integer transactionId) {
        SageModels.SupplierTransactionNote note = new SageModels.SupplierTransactionNote();
        note.posted_supplier_transaction_id = transactionId;
        note.note = notes;
        note.is_active = true;

        HttpRequest req = getRequest('POST', 'purchase_posted_transaction_memos');
        req.setBody(JSON.serialize(note, true));

        sendRequest(req);
    }
  
	
}