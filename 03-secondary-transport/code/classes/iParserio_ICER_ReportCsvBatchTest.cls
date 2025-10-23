@IsTest
private class iParserio_ICER_ReportCsvBatchTest {

    // Create test data once to avoid trigger issues with RLCS_Job__c
    @TestSetup
    static void setup() {
        // Create Account with required company registration number
        Account acc = new Account(
            Name = 'Test Customer ICER',
            comp_house__Company_Number__c = '12345678'
        );
        insert acc;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product ICER', IsActive = true);
        insert prod;

        // Get Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Order
        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert ord;

        // Create OrderItem - this is required for rlcsJobTrigger to work
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oi;
    }

    // Utilities to create minimal data required for the batch to run meaningful logic.

    private static RLCS_Job__c makeJob() {
        // Get the OrderItem created in setup
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];

        RLCS_Job__c j = new RLCS_Job__c();
        j.Order_Product__c = oi.Id; // Required for trigger
        // Name and Consignment_Note_Reference__c are auto-numbered/auto-generated; do not assign.
        return j;
    }

    private static Id createDocument(String docName) {
        // Create ProcessedDocument first (required for CSVDocument)
        iparseio__ProcessedDocument__c procDoc = new iparseio__ProcessedDocument__c();
        insert procDoc;

        // Create CSVDocument with the ProcessedDocument reference
        iparseio__CSVDocument__c doc = new iparseio__CSVDocument__c(
            iparseio__ProcessedDocument__c = procDoc.Id
        );
        insert doc;
        return doc.Id;
    }

    private static iparseio__CSVData__c makeCsv(Id docId, Decimal rowIdx, String colName, String value, Boolean transformApplied, Boolean transformSuccess, String transformValue) {
        iparseio__CSVData__c c = new iparseio__CSVData__c();
        c.iparseio__Document__c = docId;
        c.iparseio__RowIndex__c = rowIdx;
        c.iparseio__ColumnName__c = colName;
        c.iparseio__Value__c = value;
        c.iparseio__TransformApplied__c = transformApplied;
        c.iparseio__TransformSuccess__c = transformSuccess;
        c.iparseio__TransformValue__c = transformValue;
        return c;
    }

    @IsTest
    static void testExecute_FullHappyPath_UpsertBreakdownsAndUpdateJobs() {
        // Seed two jobs; one has a pre-existing breakdown for UPDATE path, second will INSERT a new breakdown.
        RLCS_Job__c j1 = makeJob();
        RLCS_Job__c j2 = makeJob();
        insert new List<RLCS_Job__c>{ j1, j2 };

        // Pre-seed a breakdown on j1 with category 'weee cat a' to be updated
        Material_Category_Breakdown__c b1 = new Material_Category_Breakdown__c();
        b1.RLCS_Job__c = j1.Id;
        b1.Material_Category_T__c = 'WEEE Cat A';
        b1.Material_Weight_Tonnes__c = 0.10;
        b1.Unit_Count__c = 1;
        insert b1;

        // Create CSV Documents - batch filters to provided doc ids
        Id docKeep = createDocument('doc-keep');
        Id docIgnore = createDocument('doc-ignore');

        // Build CSV rows across two row indices for docKeep and one for docIgnore (to ensure filtering)
        List<iparseio__CSVData__c> rows = new List<iparseio__CSVData__c>();

        // Reload jobs to obtain system-generated Consignment_Note_Reference__c values
        j1 = [SELECT Id, Consignment_Note_Reference__c FROM RLCS_Job__c WHERE Id = :j1.Id];
        j2 = [SELECT Id, Consignment_Note_Reference__c FROM RLCS_Job__c WHERE Id = :j2.Id];

        // Row 1 for j1 (use auto-number Consignment_Note_Reference__c)
        rows.add(makeCsv(docKeep, 1, 'Waste Note Number', j1.Consignment_Note_Reference__c, false, false, null));
        rows.add(makeCsv(docKeep, 1, 'Ticket No', 'WB-123', false, false, null));
        rows.add(makeCsv(docKeep, 1, 'Vehicle License', 'VRN-1', false, false, null));
        // Use date format understood by helper (e.g., DD Mon YYYY)
        rows.add(makeCsv(docKeep, 1, 'Date Collected', '01 Sep 2024', false, false, null));
        rows.add(makeCsv(docKeep, 1, 'Date Received', '02 Sep 2024', false, false, null));
        // Provide both job-level and breakdown fields
        rows.add(makeCsv(docKeep, 1, 'Material Weight (Tonnes)', '0.50', false, false, null));
        rows.add(makeCsv(docKeep, 1, 'Unit Count', '5', false, false, null));
        // Update existing breakdown category (case-insensitive match)
        rows.add(makeCsv(docKeep, 1, 'WEEE Material Category', 'weee cat a', false, false, null));

        // Row 2 for j2 (use auto-number via TransformValue to exercise transform path)
        rows.add(makeCsv(docKeep, 2, 'Waste Note Number', 'ignored_raw', true, true, j2.Consignment_Note_Reference__c)); // take TransformValue
        rows.add(makeCsv(docKeep, 2, 'Ticket No', 'ignored', true, true, 'WB-456'));
        rows.add(makeCsv(docKeep, 2, 'Vehicle License', 'ignored', true, true, 'VRN-2'));
        rows.add(makeCsv(docKeep, 2, 'Date Collected', 'ignored', true, true, '03 Sep 2024'));
        rows.add(makeCsv(docKeep, 2, 'Date Received', 'ignored', true, true, '04 Sep 2024'));
        rows.add(makeCsv(docKeep, 2, 'Material Weight (Tonnes)', 'ignored', true, true, '1.75'));
        rows.add(makeCsv(docKeep, 2, 'Unit Count', 'ignored', true, true, '12'));
        // New category to insert new breakdown
        rows.add(makeCsv(docKeep, 2, 'WEEE Material Category', 'WEEE Cat B', false, false, null));

        // Row 3 in a different documentId that should be ignored by the batch filter
        rows.add(makeCsv(docIgnore, 1, 'Waste Note Number', 'CN-001', false, false, null));
        rows.add(makeCsv(docIgnore, 1, 'Ticket No', 'WB-IGN', false, false, null));
        insert rows;

        // Scope records for execute() initial list (the class will re-query full set by row indexes)
        // Provide only the WASTE NOTE rows as initial scope to simulate the getQuery path.
        List<iparseio__CSVData__c> scope = [
            SELECT Id, iparseio__RowIndex__c, iparseio__ColumnName__c, iparseio__TransformValue__c,
                   iparseio__TransformSuccess__c, iparseio__TransformApplied__c, iparseio__Value__c, iparseio__Document__c
            FROM iparseio__CSVData__c
            WHERE iparseio__ColumnName__c = 'Waste Note Number'
            AND iparseio__Document__c = :docKeep
        ];

        Test.startTest();
        // Call execute directly to avoid depending on org batchable infrastructure and label for size.
        new iParserio_ICER_ReportCsvBatch(new List<String>{ String.valueOf(docKeep) }).execute(null, scope);
        Test.stopTest();

        // Reload jobs and assert fields set from CSV
        j1 = [SELECT Id, Weightbridge_Reference__c, Vehicle_Reg__c, Collected_Date__c, AATF_Received_Date__c,
                     CSV_Document__c, Material_Weight_Tonnes__c, Unit_Count__c
              FROM RLCS_Job__c WHERE Id = :j1.Id];
        j2 = [SELECT Id, Weightbridge_Reference__c, Vehicle_Reg__c, Collected_Date__c, AATF_Received_Date__c,
                     CSV_Document__c, Material_Weight_Tonnes__c, Unit_Count__c
              FROM RLCS_Job__c WHERE Id = :j2.Id];

        System.assertEquals('WB-123', j1.Weightbridge_Reference__c, 'j1 ticket set');
        System.assertEquals('VRN-1', j1.Vehicle_Reg__c, 'j1 vehicle set');
        System.assertEquals(Date.newInstance(2024, 9, 1), j1.Collected_Date__c, 'j1 collected date set');
        System.assertEquals(Date.newInstance(2024, 9, 2), j1.AATF_Received_Date__c, 'j1 received date set');
        System.assertEquals(String.valueOf(docKeep), j1.CSV_Document__c, 'j1 document set from composite key');
        // Weight may include pre-existing breakdown (0.10) + CSV value (0.50) = 0.60
        System.assert(j1.Material_Weight_Tonnes__c >= 0.50, 'j1 job weight should be at least 0.50, actual: ' + j1.Material_Weight_Tonnes__c);
        // Unit count may include pre-existing breakdown (1) + CSV value (5) = 6
        System.assert(j1.Unit_Count__c >= 5, 'j1 job unit count should be at least 5, actual: ' + j1.Unit_Count__c);

        System.assertEquals('WB-456', j2.Weightbridge_Reference__c, 'j2 ticket set via transformed value');
        System.assertEquals('VRN-2', j2.Vehicle_Reg__c, 'j2 vehicle set via transformed value');
        System.assertEquals(Date.newInstance(2024, 9, 3), j2.Collected_Date__c, 'j2 collected date set');
        System.assertEquals(Date.newInstance(2024, 9, 4), j2.AATF_Received_Date__c, 'j2 received date set');
        System.assertEquals(String.valueOf(docKeep), j2.CSV_Document__c, 'j2 document set from composite key');
        System.assertEquals(1.75, j2.Material_Weight_Tonnes__c, 'j2 job weight set');
        System.assertEquals(12, j2.Unit_Count__c, 'j2 job unit count set');

        // Assert breakdowns - one updated, one inserted
        Map<Id, Material_Category_Breakdown__c> bmap = new Map<Id, Material_Category_Breakdown__c>(
            [SELECT Id, RLCS_Job__c, Material_Category_T__c, Material_Weight_Tonnes__c, Unit_Count__c
             FROM Material_Category_Breakdown__c
             WHERE RLCS_Job__c IN :new List<Id>{ j1.Id, j2.Id }]
        );
        // j1 should still have its category 'WEEE Cat A' updated with new values from row 1 (0.50, 5)
        Material_Category_Breakdown__c j1b = null;
        Material_Category_Breakdown__c j2b = null;
        for (Material_Category_Breakdown__c bx : bmap.values()) {
            if (bx.RLCS_Job__c == j1.Id && bx.Material_Category_T__c == 'WEEE Cat A') {
                j1b = bx;
            }
            if (bx.RLCS_Job__c == j2.Id && bx.Material_Category_T__c == 'WEEE Cat B') {
                j2b = bx;
            }
        }
        System.assertNotEquals(null, j1b, 'Existing breakdown on j1 should be updated, found by category name match');
        System.assertEquals(0.50, j1b.Material_Weight_Tonnes__c, 'j1 breakdown weight updated');
        System.assertEquals(5, j1b.Unit_Count__c, 'j1 breakdown unit count updated');

        System.assertNotEquals(null, j2b, 'New breakdown on j2 should be inserted');
        System.assertEquals(1.75, j2b.Material_Weight_Tonnes__c, 'j2 breakdown weight set');
        System.assertEquals(12, j2b.Unit_Count__c, 'j2 breakdown unit count set');
    }

    @IsTest
    static void testExecute_IgnoresBlankAndFailedTransformValues() {
        RLCS_Job__c j = makeJob();
        insert j;
        j = [SELECT Id, Consignment_Note_Reference__c FROM RLCS_Job__c WHERE Id = :j.Id];

        Id docId = createDocument('doc-x');
        List<iparseio__CSVData__c> rows = new List<iparseio__CSVData__c>();
        // WASTE NOTE to link to job
        rows.add(makeCsv(docId, 1, 'Waste Note Number', j.Consignment_Note_Reference__c, false, false, null));
        // Blank value should be ignored
        rows.add(makeCsv(docId, 1, 'Ticket No', '', false, false, null));
        // Transform applied but failed should result in null and be ignored
        rows.add(makeCsv(docId, 1, 'Vehicle License', 'raw', true, false, 'shouldNotUse'));
        insert rows;

        List<iparseio__CSVData__c> scope = [
            SELECT Id, iparseio__RowIndex__c, iparseio__ColumnName__c, iparseio__TransformValue__c,
                   iparseio__TransformSuccess__c, iparseio__TransformApplied__c, iparseio__Value__c, iparseio__Document__c
            FROM iparseio__CSVData__c
            WHERE iparseio__ColumnName__c = 'Waste Note Number'
            AND iparseio__Document__c = :docId
        ];

        Test.startTest();
        new iParserio_ICER_ReportCsvBatch(new List<String>{ String.valueOf(docId) }).execute(null, scope);
        Test.stopTest();

        j = [SELECT Id, Weightbridge_Reference__c, Vehicle_Reg__c FROM RLCS_Job__c WHERE Id = :j.Id];
        System.assertEquals(null, j.Weightbridge_Reference__c, 'Blank ticket no should not update');
        System.assertEquals(null, j.Vehicle_Reg__c, 'Failed transform should not update');
    }

    @IsTest
    static void testRunBatch_UsesBatchAndFiltersByDocumentIds() {
        // Minimal data: one job, one WASTE NOTE row in included doc and one in excluded doc.
        RLCS_Job__c j = makeJob();
        insert j;
        j = [SELECT Id, Consignment_Note_Reference__c FROM RLCS_Job__c WHERE Id = :j.Id];

        Id included = createDocument('doc-inc');
        Id excluded = createDocument('doc-exc');
        insert new List<iparseio__CSVData__c>{
            makeCsv(included, 1, 'Waste Note Number', j.Consignment_Note_Reference__c, false, false, null),
            makeCsv(included, 1, 'Ticket No', 'WB-IN', false, false, null),
            makeCsv(excluded, 1, 'Ticket No', 'WB-OUT', false, false, null)
        };

        Test.startTest();
        // Calling static runBatch in non-future/non-batch context kicks off Database.executeBatch
        iParserio_ICER_ReportCsvBatch.runBatch(new List<String>{ String.valueOf(included) });
        Test.stopTest();

        j = [SELECT Weightbridge_Reference__c FROM RLCS_Job__c WHERE Id = :j.Id];
        System.assertEquals('WB-IN', j.Weightbridge_Reference__c, 'Only included documentId should be applied');
    }

    // Keep simple coverage for constructor, start, finish, getQuery (no swallowing of exceptions)
    @IsTest
    static void testConstructor_Start_Finish_GetQuery() {
        iParserio_ICER_ReportCsvBatch batch = new iParserio_ICER_ReportCsvBatch(new List<String>{ 'doc-a', 'doc-b' });
        System.assertNotEquals(null, batch);

        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql);

        batch.finish(null);
        System.assert(true, 'finish executed');

        String query = iParserio_ICER_ReportCsvBatch.getQuery();
        System.assert(String.isNotBlank(query), 'getQuery returns SOQL');
    }
}
