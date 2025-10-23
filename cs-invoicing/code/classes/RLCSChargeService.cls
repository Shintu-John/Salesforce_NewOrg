public class RLCSChargeService {
    
    public static final String JOB_CHARGE_TYPE_JOB = 'RLCS Job';
    public static final String JOB_CHARGE_TYPE_TONNAGE = 'Tonnage';
    public static final String JOB_CHARGE_TYPE_REBATE = 'Rebate';
    public static final String JOB_CHARGE_TYPE_TRANSPORT = 'Transport';
    public static final String JOB_CHARGE_TYPE_SECONDARY_TRANSPORT = 'Secondary Transport';
    public static final String JOB_CHARGE_TYPE_CREDIT = 'Credit';
    
    public static final String JOB_CHARGE_RECORD_TYPE_AUTO = 'Automatic';
    public static final String JOB_CHARGE_RECORD_TYPE_MANUAL = 'Manual';
    
    public static RLCS_Charge__c createAutoJobCharge(Id jobId, String chargeType) {
        RLCS_Charge__c jobCharge = new RLCS_Charge__c();
        jobCharge.RLCS_Job__c = jobId;
        jobCharge.Charge_Type__c = chargeType;
        jobCharge.RecordTypeId = Schema.SObjectType.RLCS_Charge__c.getRecordTypeInfosByDeveloperName().get(JOB_CHARGE_RECORD_TYPE_AUTO)?.getRecordTypeId();
        jobCharge.Sales_Price__c = 0;
        jobCharge.Cost__c = 0;
        jobCharge.VAT__C = '0';

        // Query Job to get date and description fields
        if (jobId != null) {
            List<RLCS_Job__c> jobs = [SELECT Id, Collected_Date__c, Waste_Type__c, Product_Name__c, EWC__c
                                       FROM RLCS_Job__c
                                       WHERE Id = :jobId
                                       LIMIT 1];
            if (!jobs.isEmpty()) {
                RLCS_Job__c job = jobs[0];

                // Set date from Job collected date
                if (job.Collected_Date__c != null) {
                    jobCharge.Date__c = job.Collected_Date__c;
                }

                // Set description from Job fields
                jobCharge.Description__c = buildChargeDescription(job);
            }
        }

        return jobCharge;
    }

    private static String buildChargeDescription(RLCS_Job__c job) {
        List<String> parts = new List<String>();

        if (String.isNotBlank(job.Waste_Type__c)) {
            parts.add('Waste Type: ' + job.Waste_Type__c);
        }
        if (String.isNotBlank(job.Product_Name__c)) {
            parts.add('Product: ' + job.Product_Name__c);
        }
        if (String.isNotBlank(job.EWC__c)) {
            parts.add('EWC: ' + job.EWC__c);
        }

        return String.join(parts, ', ');
    }
    
    public static RLCS_Charge__c updateJobCharge(RLCS_Charge__c jobCharge, Decimal chargeCost, Decimal chargeSalesPrice, Id salesAccountId, Id vendorAccountId, Id haulierAccountId, String vat) {
        Boolean jobChargeUpdated = false;
        if (jobCharge.Cost__c != chargeCost) {
            jobCharge.Cost__c = chargeCost;
            jobChargeUpdated = true;
        }
        
        if (jobCharge.Sales_Price__c != chargeSalesPrice) {
            jobCharge.Sales_Price__c = chargeSalesPrice;
            jobChargeUpdated = true;
        }
        
        if (jobCharge.Vendor_Account__c != vendorAccountId) {
            jobCharge.Vendor_Account__c = vendorAccountId;
            jobChargeUpdated = true;
        }
        
        if (jobCharge.Sales_Account__c != salesAccountId) {
            jobCharge.Sales_Account__c = salesAccountId;
            jobChargeUpdated = true;
        }
        
        if (jobCharge.Haulier__c != haulierAccountId) {
            jobCharge.Haulier__c = haulierAccountId;
            jobChargeUpdated = true;
        }
        if (jobCharge.VAT__c != vat) {
            jobCharge.VAT__c = vat;
            jobChargeUpdated = true;
        }
        
        if (jobChargeUpdated == true) {
            return jobCharge;
        } else {
            return null;
        }
        
    }
}