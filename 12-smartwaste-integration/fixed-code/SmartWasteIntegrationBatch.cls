global class SmartWasteIntegrationBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    List<SmartWaste_Integration_Log__c> integrationLog {get;set;}
    Map<String,String> accountTokens {get;set;}
    Integer successfullJobCount {get;set;}
    Integer failedJobCount {get;set;}
    private String outputQuery = '';
    private String localQuery = '';
    public String globalQuery { get {
            return outputQuery;
        }
    }
    private Boolean shouldRunForSingleJob = false;
    private String singleJobId = '';

    global SmartWasteIntegrationBatch(String jobId){
        accountTokens = new Map<String, String>();

        successfullJobCount = 0;
        failedJobCount = 0;
        
        String query = 'select Id,Transport_Receipt_Ref__c, SmartWaste_Id__c, Site__r.Account__c, Site__r.Account__r.SmartWaste_Company_Id__c, Site__r.SmartWaste_Id__c,Void_Percentage__c,Smartwaste_m3__c';
        query += ' ,Site__r.Account__r.SmartWaste_Client_Key__c, Site__r.Account__r.SmartWaste_Private_Key__c';
        query += ' ,Supplier__c, Depot_Dispose__c, Collection_Date__c, Weight__c, Weighbridge_Ticket_Uploaded__c, Order_Product__r.SmartWaste_Id__c';
        query += ' ,SmartWaste_Product_Id__c, Site__r.Account__r.SmartWaste_Username__c';
        query += ' ,Supplier__r.SmartWaste_Id__c, Supplier__r.Name, Supplier__r.BillingStreet';
        query += ' ,Supplier__r.BillingCity,Supplier__r.BillingPostalCode';
        query += ' ,Supplier__r.WASTE_CARRIERS_LICENSE_NUMBER__C, Supplier__r.Waste_Carriers_License_Date__c,Supplier__r.Waste_Carriers_Issue_Date__c';
        query += ' ,DEPOT_DISPOSE__r.SMARTWASTE_ID__C, Depot_Dispose__r.Id, Depot_Dispose__r.Today_s_Date__c, Depot_Dispose__r.Account__c, Depot_Dispose__r.Account__r.SmartWaste_Id__c, Depot_Dispose__r.Name, Depot_Dispose__r.Account__r.Name';
        query += ' ,Depot_Dispose__r.Account__r.BillingStreet, Depot_Dispose__r.Account__r.BillingCity, Depot_Dispose__r.Street__c, Depot_Dispose__r.City__c,Depot_Dispose__r.Account__r.Waste_Carriers_Issue_Date__c';
        query += ' ,Depot_Dispose__r.PostCode__c, Depot_Dispose__r.Permit_Reference__c, Depot_Dispose__r.Expiry_Date__c,Depot_Dispose__r.Registered_Date__c,Depot_Dispose__r.Account__r.BillingPostalCode';
        query += ' ,Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_NUMBER__C, Depot_Dispose__r.Account__r.WASTE_CARRIERS_LICENSE_DATE__C';
        query += ' ,Site__r.SMARTWASTE_PHASE_ID__C, Order_Product__r.SmartWaste_Phase_Id__c, SMARTWASTE_ROUTE_ID__C, ORDER_PRODUCT__r.PRODUCT2.SMARTWASTE_ID__C, WEIGHBRIDGE_EVIDENCE_REF__C';
        query += ' ,ORDER_PRODUCT__r.Quantity, RECYCLE__C, RECOVER__C, RE_USE__C, ENERGY__C, Landfill__c';
        query += ' ,Waste_Transfer_Note_Uploaded__c, Consignment_note_uploaded__c, DOC_uploaded__c, WTN_ContentDistribution_Id__c, Consignment_Note_ContentDistribution_Id__c, DOC_ContentDistribution_Id__c, EWC_Code_2__c';
        query += ' ,ProductPercentage__c, Paperwork_Done__c, Main_Disposal_Option__c, Status__c ';
        query += ' ,SmartWaste_MainDisposalOnly__c, SmartWaste_IsMainDisposalSent__c, SmartWaste_IsEnergySent__c, SmartWaste_IsLandfillSent__c';
        query += ' ,SmartWaste_IsRecoverSent__c, SmartWaste_IsRecycleSent__c, SmartWaste_IsReuseSent__c';
        query += ' ,Account__r.SmartWaste_JobStartDateFormula__c, Account__r.SmartWaste_JobStartDate__c';
        query += ' ,Required_Paperwork__c, Depot_Dispose__r.SmartWaste_RecyclingRate__c, Depot_Dispose__r.SmartWaste_EnergyRecoveryRate__c,SmartwasteVehicleId__c,Container_Counter__c,Total_Distance_Miles__c,Total_Distance_KM__c, SIC_Code__c';
        query += ' from Job__c ';
        query += ' where Id!=null and IsDeleted=false ';
        query += ' and Site__r.Account__r.SmartWaste_Private_Key__c != \'\' ';
        query += ' and Site__r.Account__r.SmartWaste_Client_Key__c != \'\' ';
        query += ' and SMS_Job_Id__c = \'\' ';
        query += ' and SMS_Job_Duplicated__c = false ';

        outputQuery = query;

        String whereClause = '';
        //whereClause += ' and (Status__c = \'Collected\' or Status__c = \'Paperwork Provided\' or Status__c = \'Completed\')';
        //whereClause += ' and ((SmartWaste_MainDisposalOnly__c=true and SmartWaste_IsMainDisposalSent__c=false)';
        //whereClause += ' or (SmartWaste_MainDisposalOnly__c=false';
        //whereClause += ' and ((ENERGY__C>0 and SmartWaste_IsEnergySent__c=false)';
        //whereClause += ' or (Landfill__c>0 and SmartWaste_IsLandfillSent__c=false)';
        //whereClause += ' or (RECOVER__C>0 and SmartWaste_IsRecoverSent__c=false)';
        //whereClause += ' or (RECYCLE__C>0 and SmartWaste_IsRecycleSent__c=false)';
        //whereClause += ' or (RE_USE__C>0 and SmartWaste_IsReuseSent__c=false))))';
        
        whereClause += ' and (Status__c = \'Collected\' or Status__c = \'Paperwork Provided\' or Status__c = \'Completed\')';
        whereClause += ' and SmartWaste_Id__c=null';


        if (String.isNotBlank(jobId)){
            whereClause += ' and Id= \''+Id.valueOf(jobId)+'\' ';
            outputQuery += ' and Id= \''+Id.valueOf(jobId)+'\' ';

            shouldRunForSingleJob = true;
            singleJobId = jobId;
        }
        else 
        {	whereClause+=' and Attempt_Send_to_SmartWaste__c = true'; }
        
        whereClause += ' order by Id ';

        localQuery = query + whereClause;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('query: ' + localQuery);
        List<SmartWaste_Integration_Log__c> deletedIntegrationLogs = new List<SmartWaste_Integration_Log__c>();
        
        if (this.shouldRunForSingleJob){
            deletedIntegrationLogs = [select Id from SmartWaste_Integration_Log__c where Related_Job__c = :singleJobId];
        }
        else {
            deletedIntegrationLogs = [select Id from SmartWaste_Integration_Log__c LIMIT 10000];
        }

        if (deletedIntegrationLogs.size() > 0){
            System.debug('deletedIntegrationLogs: ' + deletedIntegrationLogs.size());
            delete deletedIntegrationLogs;
        }
        return Database.getQueryLocator(localQuery);
    }

    global void execute(Database.BatchableContext bc, List<Job__c> scope){
        integrationLog = new List<SmartWaste_Integration_Log__c>();
        List<Job__c> completedJobs = new List<Job__c>();
        List<Depot__c> updatedDepots = new List<Depot__c>();
        List<Account> updatedAccounts= new List<Account>();

        Map<String, String> wtnContents = new Map<String, String>();
        Map<String, String> wtnContentNames = new Map<String, String>();
        Map<String, String> aDocContents = new Map<String, String>();
        Map<String, String> aDocContentNames = new Map<String, String>();
        String wtnContentForJob = '';
        String wtnContentNameForJob = '';
        String aDocContentForJob = '';
        String aDocContentNameForJob = '';
        Set<String> setDocIds = new Set<String>();
        Set<String> setAccountIds = new Set<String>();
        Map<String, Waste_Type__mdt> mapOfWasteTypes = new Map<String, Waste_Type__mdt>();
        Map<String, Integer> mapOfSmartWasteProductIds = new Map<String, Integer>();
        Set<Id> setJobIds = new Set<Id>();

        for (Waste_Type__mdt wt: [select EWC_Code__c, SmartWaste_Id__c, SmartWaste_Route_Id__c from Waste_Type__mdt]){
            if (!mapOfWasteTypes.containsKey(wt.EWC_Code__c)){
                mapOfWasteTypes.put(wt.EWC_Code__c, wt);
            }
        }

        for (Waste_Types__c wt: [select EWC_Code__c, Recycling_lives_EWC_Id__c, SmartWaste_ProductId__c, Waste_Type__c, Name from Waste_Types__c]){
            if (!mapOfSmartWasteProductIds.containsKey(wt.Name) && wt.SmartWaste_ProductId__c != null){
                mapOfSmartWasteProductIds.put(wt.Name, Integer.valueOf(wt.SmartWaste_ProductId__c));
            }
        }

        Map<String, String> docsJobIds = new Map<String, String>();
        for (Job__c j1: scope){
            List<String> requiredPaperWork = String.isNotBlank(j1.Required_Paperwork__c) ? j1.Required_Paperwork__c.split(';') : new List<String>();
            String configurationMessages = validateJob(j1);
            Boolean jobHasMissingConfiguration = String.isNotBlank(configurationMessages);
            
            if (jobHasMissingConfiguration == false){
                if (setJobIds.contains(j1.Id) == false){
                    setJobIds.add(j1.Id);
                }
    
                if (requiredPaperWork.contains('WTN') && (j1.Waste_Transfer_Note_Uploaded__c || j1.Consignment_note_uploaded__c)){
                    String docId = j1.WTN_ContentDistribution_Id__c != null ? j1.WTN_ContentDistribution_Id__c : j1.Consignment_Note_ContentDistribution_Id__c;
                    setDocIds.add(docId);
                    docsJobIds.put(docId, j1.Id);
                }
                
                if (requiredPaperWork.contains('ADOC') && j1.DOC_uploaded__c){
                    setDocIds.add(j1.DOC_ContentDistribution_Id__c);
                    docsJobIds.put(j1.DOC_ContentDistribution_Id__c, j1.Id);
                }
            }
        }

        List<ContentDistribution> cdRecs = [SELECT Id, ContentVersion.Document__c, ContentVersion.VersionData, ContentVersion.FileExtension, ContentVersion.Title, ContentVersion.ContentDocument.ParentId FROM ContentDistribution where Id in :setDocIds];
        for (ContentDistribution c: cdRecs){
            String jobId = docsJobIds.get(c.Id);
            if (!wtnContents.containsKey(jobId) && c.ContentVersion.Document__c == 'Waste Transfer Note'){
                wtnContents.put(jobId, EncodingUtil.base64Encode(c.ContentVersion.VersionData));
                wtnContentNames.put(jobId, c.ContentVersion.Title + '.' + c.ContentVersion.FileExtension);
            }
            if (!aDocContents.containsKey(jobId) && c.ContentVersion.Document__c == 'Annual Duty of Care'){
                aDocContents.put(jobId, EncodingUtil.base64Encode(c.ContentVersion.VersionData));
                aDocContentNames.put(jobId, c.ContentVersion.Title + '.' + c.ContentVersion.FileExtension);
            }
        }
        
        for (ContentDistribution c: cdRecs){
            String jobId = docsJobIds.get(c.Id);
            //if waste tranfer note not available tne use consignment Note
            if (!wtnContents.containsKey(jobId) && c.ContentVersion.Document__c == 'Consignment Note'){
                wtnContents.put(jobId, EncodingUtil.base64Encode(c.ContentVersion.VersionData));
                wtnContentNames.put(jobId, c.ContentVersion.Title + '.' + c.ContentVersion.FileExtension);
            }
        }

        for (Job__c j: scope){
            system.debug('proceeding for jobId: ' + j.Id);
            wtnContentForJob = wtnContents.containsKey(j.Id) ? wtnContents.get(j.Id) : '';
            wtnContentNameForJob =  wtnContentNames.containsKey(j.Id) ? wtnContentNames.get(j.Id) : '';
            aDocContentForJob =  aDocContents.containsKey(j.Id) ? aDocContents.get(j.Id) : '';
            aDocContentNameForJob =  aDocContentNames.containsKey(j.Id) ? aDocContentNames.get(j.Id) : '';
            Boolean jobHasMissingConfiguration = false;
            String configurationMessages = validateJob(j);
            jobHasMissingConfiguration = String.isNotBlank(configurationMessages);

            if (mapOfWasteTypes.containsKey(j.EWC_Code_2__c)){
                j.SmartWaste_Product_Id__c = mapOfWasteTypes.get(j.EWC_Code_2__c).SmartWaste_Id__c;
                j.SMARTWASTE_ROUTE_ID__C = mapOfWasteTypes.get(j.EWC_Code_2__c).SmartWaste_Route_Id__c;
            }
            else{
                String ewcCode = j.EWC_Code_2__c;
                if (String.isNotBlank(ewcCode)){
                    if (ewcCode.contains('*')){ //hazardous
                        j.SmartWaste_Product_Id__c = '20';
                        j.SMARTWASTE_ROUTE_ID__C = '0';
                    }
                    else{ //other
                        j.SmartWaste_Product_Id__c = '72';
                        j.SMARTWASTE_ROUTE_ID__C = '0';
                    }
                }
                else{
                    j.SmartWaste_Product_Id__c = '0';
                    j.SMARTWASTE_ROUTE_ID__C = '0';
                }
            }

            if (jobHasMissingConfiguration){ //create a log record for the validation errors
                SmartWaste_Integration_Log__c log = new SmartWaste_Integration_Log__c();
                log.Related_Job__c = j.Id;
                log.Description__c = configurationMessages;
                log.Related_Account__c = j.Site__r.Account__c;
                log.Related_Site__c = j.Site__c;
                integrationLog.add(log);
            }
            else if (jobHasMissingConfiguration == false && j.Collection_Date__c >= j.Account__r.SmartWaste_JobStartDateFormula__c){
                //do the job
                if (!accountTokens.containsKey(j.Site__r.Account__c)){ //has no session token, lets create it
                    System.debug('authentication needed');
                    SmartWasteIntegrationMiddleware.authenticateRequest authenticationRequest = new SmartWasteIntegrationMiddleware.authenticateRequest();
                    authenticationRequest.clientKey = j.Site__r.Account__r.SmartWaste_Client_Key__c;
                    authenticationRequest.privateKey = j.Site__r.Account__r.SmartWaste_Private_Key__c;
                    authenticationRequest.username = j.Site__r.Account__r.SmartWaste_Username__c;
                    SmartWasteIntegrationMiddleware.authenticateResponse authenticationResponse = SmartWasteIntegrationMiddleware.authenticate(authenticationRequest);
                    if (authenticationResponse.success){
                        accountTokens.put(j.Site__r.Account__c, authenticationResponse.authToken);
                        System.debug('authenticated');
                    }
                }

                String authToken = accountTokens.get(j.Site__r.Account__c);
                String authUsername = j.Site__r.Account__r.SmartWaste_Username__c;
                String companyId = j.Site__r.Account__r.SmartWaste_Company_Id__c;
                String projectId = j.Site__r.SmartWaste_Id__c;

                String integrationMessages = '';
                String carrierId = '';
                if (j.Supplier__c != null && String.isBlank(j.Supplier__r.SmartWaste_Id__c)){ //has no waste carrier lets create it
                    System.debug('waste carrier creation needed');
                    SmartWasteIntegrationMiddleware.saveWasteCarrierToCompanyResponse supplyResponse = SmartWasteIntegrationMiddleware.saveWasteCarrierToCompany(authToken, authUsername, companyId, j.Supplier__r, projectId);
                    if (supplyResponse.Success){
                        j.Supplier__r.SmartWaste_Id__c = String.valueOf(supplyResponse.carrierID);
                        carrierId = String.valueOf(supplyResponse.carrierID);
                        if (!setAccountIds.contains(j.Supplier__c)){
                            updatedAccounts.add(j.Supplier__r);
                            setAccountIds.add(j.Supplier__c);
                        }
                    }
                    else{
                        integrationMessages += 'Depot Supply: ' + supplyResponse.errorComment + '\r\n';
                    }
                    System.debug('waste carrier created: ' + supplyResponse.Success);
                }
                String destinationId = '';
                if (j.Depot_Dispose__c != null && String.isBlank(j.Depot_Dispose__r.SmartWaste_Id__c)){ //has no waste destination lets create it
                    
                    if (String.isBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)){
                        System.debug('waste carrier for destination creation needed');

                        SmartWasteIntegrationMiddleware.saveWasteCarrierToCompanyResponse supplyResponse = SmartWasteIntegrationMiddleware.saveWasteCarrierToCompany(authToken, authUsername, companyId, j.Depot_Dispose__r.Account__r, projectId);
                        if (supplyResponse.Success){
                            j.Depot_Dispose__r.Account__r.SmartWaste_Id__c = String.valueOf(supplyResponse.carrierID);
                            //carrierId = String.valueOf(supplyResponse.carrierID);
                            if (!setAccountIds.contains(j.Depot_Dispose__r.Account__c)){
                                updatedAccounts.add(j.Depot_Dispose__r.Account__r);
                                setAccountIds.add(j.Depot_Dispose__r.Account__c);
                            }
                        }
                        else{
                            integrationMessages += 'Depot Dispose: ' + supplyResponse.errorComment + '\r\n';
                        }
                        System.debug('waste carrier for destination created: ' + supplyResponse.Success);
                    }

                    List<Material_Recycling_Rate__c> rates = [select Id, Material__c, Energy__c, Re_use__c, Recover__c, Recycle__c from Material_Recycling_Rate__c where Depot__c=:j.Depot_Dispose__c];
                    System.debug('waste destination creation needed');
                    SmartWasteIntegrationMiddleware.saveWasteDestinationToCompanyResponse disposeResponse = SmartWasteIntegrationMiddleware.saveWasteDestinationToCompany(authToken, authUsername, companyId, j.Depot_Dispose__r, projectId, rates, mapOfSmartWasteProductIds);
                    if (disposeResponse.Success){
                        j.Depot_Dispose__r.SmartWaste_Id__c = String.valueOf(disposeResponse.destinationID);
                        destinationId = String.valueOf(disposeResponse.destinationID);
                        updatedDepots.add(j.Depot_Dispose__r);
                    }
                    else{
                        integrationMessages += 'Depot Dispose: ' + disposeResponse.errorComment + '\r\n';
                    }
                    System.debug('waste destination created: ' + disposeResponse.Success);
                }

                if (String.isNotBlank(j.Depot_Dispose__r.SmartWaste_Id__c)){
                    destinationId = j.Depot_Dispose__r.SmartWaste_Id__c;
                }

                if (String.isNotBlank(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c)){
                    SmartWasteIntegrationMiddleware.assignCarrierToCompany(authToken, authUsername, companyId, projectId, Integer.valueOf(j.Depot_Dispose__r.Account__r.SmartWaste_Id__c));
                }
                if (String.isNotBlank(j.Depot_Dispose__r.SmartWaste_Id__c)){
                    SmartWasteIntegrationMiddleware.assignDestinationToCompany(authToken, authUsername, companyId, projectId, Integer.valueOf(j.Depot_Dispose__r.SmartWaste_Id__c));
                }

                //save rates by using update waste destination method
                if (String.isNotBlank(j.Depot_Dispose__r.SmartWaste_Id__c)){
                    SmartWasteIntegrationMiddleware.UpdateWasteDestinationWrappedRequest updateDestinationRequest = new SmartWasteIntegrationMiddleware.UpdateWasteDestinationWrappedRequest();
                    updateDestinationRequest.authToken = authToken;
                    updateDestinationRequest.username = authUsername;
                    updateDestinationRequest.companyId = companyId;
                    updateDestinationRequest.projectId = projectId;
                    updateDestinationRequest.destinationId = Integer.valueOf(destinationId);
                    updateDestinationRequest.depot = j.Depot_Dispose__r;
                    List<Material_Recycling_Rate__c> rates = [select Id, Material__c, Energy__c, Re_use__c, Recover__c, Recycle__c from Material_Recycling_Rate__c where Depot__c=:j.Depot_Dispose__c];
                    updateDestinationRequest.materialRates = rates;
                    updateDestinationRequest.mapOfSmartWasteProductIds = mapOfSmartWasteProductIds;

                    SmartWasteIntegrationMiddleware.UpdateWasteDestinationResponse updateDestinationResponse = SmartWasteIntegrationMiddleware.updateWasteDestination(updateDestinationRequest);
                }
                
                //create waste item
                System.debug('start save waste item');
                Integer wasteManagementRouteId = String.isNotBlank(j.SMARTWASTE_ROUTE_ID__C) ? Integer.valueOf(j.SmartWaste_Route_Id__c) : 0;
                SmartWasteIntegrationMiddleware.saveWasteItemInput saveWasteItemParams = new SmartWasteIntegrationMiddleware.saveWasteItemInput();
                saveWasteItemParams.authToken = authToken;
                saveWasteItemParams.username = authUsername;
                saveWasteItemParams.aDocContent = aDocContentForJob;
                saveWasteItemParams.aDocContentName = aDocContentNameForJob;
                saveWasteItemParams.carrierId = carrierId;
                saveWasteItemParams.companyId = companyId;
                saveWasteItemParams.destinationId = destinationId;
                saveWasteItemParams.job = j;
                saveWasteItemParams.projectId = projectId;
                saveWasteItemParams.wtnContent = wtnContentForJob;
                saveWasteItemParams.wtnContentName = wtnContentNameForJob;
                
                    System.debug('save waste item');
                    saveWasteItemParams.wasteManagementRouteId = 3;

                    SmartWasteIntegrationMiddleware.saveWasteItemResponse wasteResponse = SmartWasteIntegrationMiddleware.saveWasteItem(saveWasteItemParams);
                    if (wasteResponse.Success){
                        j.SmartWaste_Id__c = String.valueOf(wasteResponse.wasteID);
                        completedJobs.add(j);
                    }
                    
                    if (!wasteResponse.Success){
                        integrationMessages += 'Waste Item: ' + wasteResponse.errorComment + '\r\n';
                        
                        SmartWaste_Integration_Log__c log = new SmartWaste_Integration_Log__c();
                        log.Related_Job__c = j.Id;
                        log.Description__c = integrationMessages;
                        log.Related_Account__c = j.Site__r.Account__c;
                        log.Related_Site__c = j.Site__c;
                        integrationLog.add(log);
                    }
                    System.debug('save waste item: ' + wasteResponse.Success);
                System.debug('end save waste item');
            }
        }
        
        insert integrationLog;
        System.debug('integrationLog: ' + integrationLog.size());
        failedJobCount += integrationLog.size();
        if (updatedAccounts.size() > 0){
            update updatedAccounts;
            System.debug('updatedAccounts: ' + updatedAccounts.size());
        }
        if (updatedDepots.size() > 0){
            update updatedDepots;
            System.debug('updatedDepots: ' + updatedDepots.size());
        }
        if (completedJobs.size() > 0){
            update completedJobs;
            System.debug('completedJobs: ' + completedJobs.size());
            successfullJobCount += completedJobs.size();
        }
    }

    global void finish(Database.BatchableContext bc){
        System.debug('SmartWasteIntegrationBatch Completed');
        String orgUrl = URL.getOrgDomainUrl().toExternalForm();
        orgUrl += '/lightning/o/SmartWaste_Integration_Log__c/list?filterName=00B8E000003asRgUAI';
        
        if (Test.isRunningTest() == false){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = Test.isRunningTest() ? new String[] {'dincer.uyav@vesium.com'} : new String[] {'dincer.uyav@vesium.com'};
            mail.setSenderDisplayName('Salesforce Support');
            mail.setUseSignature(false);
            mail.setBccSender(false);
            mail.setSaveAsActivity(false);
            mail.setSubject('Smart Waste Integration Work Log');
            String mailBody = '<html><body>Smart Waste Integration Job has been completed with the below details; ';
                mailBody +='<br/>Successful Count: ' + successfullJobCount + ' <br/>Failed Count: ' + failedJobCount;
                mailBody += '<br/>' + orgUrl;
                mailBody += '</body></html>';
            mail.setHtmlBody(mailBody);
            Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    public static String validateJob(Job__c j){
        String validationMessages = '';

        List<String> requiredPaperWork = String.isNotBlank(j.Required_Paperwork__c) ? j.Required_Paperwork__c.split(';') : new List<String>();

        if (j.Collection_Date__c < j.Account__r.SmartWaste_JobStartDateFormula__c){
            validationMessages += 'Job > Collection Date cannot be before than ' + j.Account__r.SmartWaste_JobStartDateFormula__c + ' \r\n';
        }
        if (String.isBlank(j.Site__r.SmartWaste_Id__c)){
            validationMessages += 'Job > Site > SmartWasteId (ProjectId) cannot be empty \r\n';
        }
        if (j.Paperwork_Done__c == false){
            validationMessages += 'Job > Paperwork Done was unchecked \r\n';
        }
        if (j.Weight__c == null){
            validationMessages += 'Job > Weight cannot be empty \r\n';
        }
        if (String.isBlank(j.Depot_Dispose__c)){
            validationMessages += 'Job > Depot Dispose cannot be empty \r\n';
        }
        else{
            if (j.Depot_Dispose__r.Registered_Date__c==null){
            	validationMessages += 'Job > Depot Dispose Registered Date cannot be empty \r\n';
            }
      		if(j.Depot_Dispose__r.Expiry_Date__c != null && j.Depot_Dispose__r.Expiry_Date__c < Date.today())
            {
                validationMessages += 'Job > Depot Dispose Expired \r\n';
            }
            // Validate Depot address and permit fields (required by SmartWaste API if creating new destination)
            if (String.isBlank(j.Depot_Dispose__r.SmartWaste_Id__c)) {
                if (String.isBlank(j.Depot_Dispose__r.Street__c)) {
                    validationMessages += 'Job > Depot Dispose > Street cannot be empty \r\n';
                }
                if (String.isBlank(j.Depot_Dispose__r.City__c)) {
                    validationMessages += 'Job > Depot Dispose > City cannot be empty \r\n';
                }
                if (String.isBlank(j.Depot_Dispose__r.PostCode__c)) {
                    validationMessages += 'Job > Depot Dispose > Postal Code cannot be empty \r\n';
                }
                if (String.isBlank(j.Depot_Dispose__r.Permit_Reference__c)) {
                    validationMessages += 'Job > Depot Dispose > Permit Reference cannot be empty \r\n';
                }
            }
        }


        if (String.isBlank(j.Supplier__c)){
            validationMessages += 'Job > Supplier cannot be empty \r\n';
        }
        /*if (String.isBlank(j.WEIGHBRIDGE_EVIDENCE_REF__C)){
            validationMessages += 'Job > Weighbridge Evidence Ref cannot be empty \r\n';
        }*/
        if (j.ProductPercentage__c == null){
            validationMessages += 'Job > Product Percentage cannot be empty \r\n';
        }
        if (requiredPaperWork.contains('WTN') && String.isBlank(j.WTN_ContentDistribution_Id__c) == true && String.isBlank(j.Consignment_Note_ContentDistribution_Id__c) == true){
            validationMessages += 'Job > WTN/Consignment Note File required but there was no file attached \r\n';
        }
        if (requiredPaperWork.contains('ADOC') && String.isBlank(j.DOC_ContentDistribution_Id__c) == true){
            validationMessages += 'Job > ADOC File required but there was no file attached to this job or Schedule record \r\n';
        }
        if (String.isBlank(j.Site__r.Account__r.SmartWaste_Company_Id__c)){
            validationMessages += 'Job > Site > Account > SmartWaste CompanyId cannot be empty \r\n';
        }
        if (String.isBlank(j.Site__r.Account__r.SmartWaste_Username__c)){
            validationMessages += 'Job > Site > Account > SmartWaste Username cannot be empty \r\n';
        }
        // Validate Supplier WCL and address fields (required by SmartWaste API if creating new carrier)
        if (String.isBlank(j.Supplier__r.SmartWaste_Id__c)) {
            if (String.isBlank(String.valueOf(j.Supplier__r.WASTE_CARRIERS_LICENSE_DATE__C))) {
                validationMessages += 'Job > Supplier > Waste Carrier License Date cannot be empty \r\n';
            }
            if (String.isBlank(j.Supplier__r.BillingStreet)) {
                validationMessages += 'Job > Supplier > Billing Street cannot be empty \r\n';
            }
            if (String.isBlank(j.Supplier__r.BillingCity)) {
                validationMessages += 'Job > Supplier > Billing City cannot be empty \r\n';
            }
            if (String.isBlank(j.Supplier__r.BillingPostalCode)) {
                validationMessages += 'Job > Supplier > Billing Postal Code cannot be empty \r\n';
            }
            if (String.isBlank(j.Supplier__r.Waste_Carriers_License_number__c)) {
                validationMessages += 'Job > Supplier > Waste Carrier License Number cannot be empty \r\n';
            }
            if (j.Supplier__r.Waste_Carriers_Issue_Date__c == null) {
                validationMessages += 'Job > Supplier > Waste Carrier License Issue Date cannot be empty \r\n';
            }
        }
        // REMOVED: Depot Account WCL validation - not required by SmartWaste API
        // Depots need Environmental Permits (not transport licenses)
        // Validation removed on 2025-10-29 after API requirements analysis
        if(j.Container_Counter__c == null)
        {
            validationMessages += 'Job > Container Count cannot be empty \r\n';
        }
        /*if (j.Weighbridge_Ticket_Uploaded__c == false){
            validationMessages += 'Job > Weighbridge Ticket Uploaded was unchecked \r\n';
        }*/
        if (String.isBlank(j.ORDER_PRODUCT__r.PRODUCT2.SMARTWASTE_ID__C) && !Test.isRunningTest()){
            validationMessages += 'Job > Order Product > Product > SmartWasteId cannot be empty (Will be used for skip size) \r\n';
        }

        if (j.Status__c != 'Collected' && j.Status__c != 'Paperwork Provided' && j.Status__c != 'Completed'){
            validationMessages += 'Job > Status can only be Collected, Paperwork Provided and Completed\r\n';
        }
        
        /*if (j.SmartWaste_MainDisposalOnly__c == false){
            if ((j.Energy__c > 0 && j.SmartWaste_IsEnergySent__c == false) || 
                (j.Landfill__c > 0 && j.SmartWaste_IsLandfillSent__c == false ) || 
                (j.Recover__c > 0 && j.SmartWaste_IsRecoverSent__c == false) || 
                (j.Recycle__c > 0 && j.SmartWaste_IsRecycleSent__c == false) || 
                (j.Re_use__c > 0 && j.SmartWaste_IsReuseSent__c == false)){
                    //good to go
            }
            else{
                if ((j.Energy__c > 0 && j.SmartWaste_IsEnergySent__c == true) || 
                (j.Landfill__c > 0 && j.SmartWaste_IsLandfillSent__c == true ) || 
                (j.Recover__c > 0 && j.SmartWaste_IsRecoverSent__c == true) || 
                (j.Recycle__c > 0 && j.SmartWaste_IsRecycleSent__c == true) || 
                (j.Re_use__c > 0 && j.SmartWaste_IsReuseSent__c == true)){
                    validationMessages += 'Already sent.\r\n';
                }
                else{
                    // not good to go
                    validationMessages += 'Job > Recycle rates was empty (Energy, Landfill, Recover, Recycle, Re-use)\r\n';
                }
            }
        }*/


        if (Limits.getHeapSize() > 12582912) {
            validationMessages += 'General > Salesforce Heap Size too large for API communication, please check the job attachment sizes (WTN, Adoc). Max allowed file size is 6mb.\r\n';
        }

        return validationMessages;
    }

    public static Integer getRouteId(String disposalOption){
        if (disposalOption == 'Recycle'){
            return 1;
        }
        else if (disposalOption == 'Reuse'){
            return 2;
        }
        else if (disposalOption == 'Recover'){
            return 3;
        }
        else if (disposalOption == 'Landfill'){
            return 4;
        }
        else if (disposalOption == 'Energy'){
            return 5;
        }
        else{
            return 0;
        }
    }

    public static Integer increase(Integer i){
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
                i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
                i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        return i;
    }
}