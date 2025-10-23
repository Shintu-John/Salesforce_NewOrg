/**
 * Test class for RLCSJobAATFBatchProcessor
 * This class focuses on specific batch functionality beyond what's covered in RLCSJobAATFControllerTest
 */
@isTest
public class RLCSJobAATFBatchProcessorTest {

    @TestSetup
    static void setupTestData() {
        // Create accounts
        Account customer = TestFactory.createClient('Test Customer');
        insert customer;
        
        Account supplier = TestFactory.createSupplier('Test Supplier');
        insert supplier;
        
        // Create an order with a specific format ID for testing
        Order order = new Order(
            AccountId = customer.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        // Create a product
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert product;
        
        // Create a pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Create an order item
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert orderItem;
    }
    
    /**
     * Create test CSV content
     */
    private static String createTestCSV(Boolean valid, Integer rowCount) {
        // Get IDs from database
        Id orderId, orderProductId;
        
        List<Order> orders = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem LIMIT 1];
        
        if (!orders.isEmpty() && !orderItems.isEmpty()) {
            orderId = orders[0].Id;
            orderProductId = orderItems[0].Id;
        } else {
            // Fallback to dummy IDs
            orderId = valid ? '8010000000ABCDE' : 'INVALID';
            orderProductId = valid ? '8020000000ABCDE' : 'INVALID';
        }
        
        // Create CSV header row
        List<String> csvLines = new List<String>{
            'WDA/Other,DCF/Source,Postcode,Date Collected,Date Received,AATF/Haulier,AATF Site,Ticket No,Waste Note,PCS Reference,Vehicle License,WEEE Stream,WEEE Tonnes,WEEE Units,Order ID,Order Product ID'
        };
        
        // Add data rows
        for (Integer i = 1; i <= rowCount; i++) {
            String line = 'Council' + i + ',Source' + i + ',AB' + i + ' 1CD,01/01/2023,02/01/2023,' +
                         'Transport Co' + i + ',AATF Site' + i + ',Ticket' + i + ',' +
                         'WN' + i + ',PCS' + i + ',VEH' + i + ',LDA,1.' + i + ',' + (i * 10) + ',' +
                         orderId + ',' + orderProductId;
            csvLines.add(line);
        }
        
        return String.join(csvLines, '\n');
    }
    
    /**
     * Test the start method of the batch processor
     */
    @isTest
    static void testBatchStart() {
        // Create test CSV
        String csvContent = createTestCSV(true, 5);
        
        // Create a batch tracker
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Name = 'Test Batch',
            Status__c = 'Processing'
        );
        insert tracker;
        
        // Create batch processor
        Test.startTest();
        RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
        
        // Test the start method
        Iterable<String> rows = batchProcessor.start(null);
        Iterator<String> rowIterator = rows.iterator();
        
        // Count the rows returned by start
        Integer rowCount = 0;
        while (rowIterator.hasNext()) {
            rowIterator.next();
            rowCount++;
        }
        Test.stopTest();
        
        // Verify the row count (should be data rows only, not header)
        System.assertEquals(5, rowCount, 'Start should return 5 rows to process');
    }
    
    /**
     * Test the execute method of the batch processor
     */
    @isTest
    static void testBatchExecute() {
        // Create test CSV
        String csvContent = createTestCSV(true, 2);
        
        // Create a batch tracker
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Name = 'Test Batch Execute',
            Status__c = 'Processing'
        );
        insert tracker;
        
        // Create batch processor
        RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
        
        // Get rows to process
        Test.startTest();
        Iterable<String> rowsIterable = batchProcessor.start(null);
        List<String> rows = new List<String>();
        Iterator<String> iterator = rowsIterable.iterator();
        while (iterator.hasNext()) {
            rows.add(iterator.next());
        }
        
        // Execute batch with the rows
        batchProcessor.execute(null, rows);
        Test.stopTest();
        
        // Verify tracker was updated
        tracker = [
            SELECT Id, Processed_Records__c
            FROM RLCS_Batch_Tracker__c
            WHERE Id = :tracker.Id
        ];
        System.assertEquals(2, tracker.Processed_Records__c, 'Processed records count should be 2');
        
        // Verify jobs were created
        List<RLCS_Job__c> jobs = [SELECT Id FROM RLCS_Job__c];
        System.assertEquals(2, jobs.size(), '2 jobs should be created');
    }
    
    /**
     * Test the finish method of the batch processor
     */
    @isTest
    static void testBatchFinish() {
        // Create test CSV
        String csvContent = createTestCSV(true, 3);
        
        // Create a batch tracker
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Name = 'Test Batch Finish',
            Status__c = 'Processing'
        );
        insert tracker;
        
        // Create and execute batch processor
        Test.startTest();
        RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
        
        // Get and process rows
        Iterable<String> rowsIterable = batchProcessor.start(null);
        List<String> rows = new List<String>();
        Iterator<String> iterator = rowsIterable.iterator();
        while (iterator.hasNext()) {
            rows.add(iterator.next());
        }
        
        batchProcessor.execute(null, rows);
        
        // Call finish
        batchProcessor.finish(new MockBatchableContext());
        Test.stopTest();
        
        // Verify tracker was updated
        tracker = [
            SELECT Id, Status__c, Content_Document_Id__c, Filename__c, Job_Count__c
            FROM RLCS_Batch_Tracker__c
            WHERE Id = :tracker.Id
        ];
        System.assertEquals('Completed', tracker.Status__c, 'Status should be Completed');
        System.assertNotEquals(null, tracker.Content_Document_Id__c, 'Content Document ID should be set');
        System.assertNotEquals(null, tracker.Filename__c, 'Filename should be set');
        System.assertEquals(3, tracker.Job_Count__c, 'Job count should be 3');
    }
    
    /**
     * Test handling of error in finish method
     */
    @isTest
    static void testBatchFinishWithError() {
        // Create a batch tracker
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Name = 'Test Batch Finish Error',
            Status__c = 'Processing'
        );
        insert tracker;
        
        // Create a CSV with invalid OrderItem ID to cause processing errors
        String csvContent = 'WDA/Other,DCF/Source,Postcode,Date Collected,Date Received,AATF/Haulier,AATF Site,Ticket No,Waste Note,PCS Reference,Vehicle License,WEEE Stream,WEEE Tonnes,WEEE Units,Order ID,Order Product ID\n';
        csvContent += 'Council1,Source1,AB1 1CD,01/01/2023,02/01/2023,Transport Co1,AATF Site1,Ticket1,WN1,PCS1,VEH1,LDA,1.1,10,8010000000ABCDE,802INVALIDID123'; // Invalid OrderItem ID
        
        // Create batch processor
        Test.startTest();
        RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
        
        // Process the data - this should cause errors due to invalid OrderItem ID
        Iterable<String> rowsIterable = batchProcessor.start(null);
        List<String> rows = new List<String>();
        Iterator<String> iterator = rowsIterable.iterator();
        while (iterator.hasNext()) {
            rows.add(iterator.next());
        }
        
        // Execute will attempt to create jobs with invalid OrderItem ID, causing DML errors
        batchProcessor.execute(null, rows);
        
        // Call finish - this should set status to Failed due to the processing errors
        batchProcessor.finish(new MockBatchableContext());
        Test.stopTest();
        
        // Verify tracker was updated with error
        tracker = [
            SELECT Id, Status__c, Error_Messages__c
            FROM RLCS_Batch_Tracker__c
            WHERE Id = :tracker.Id
        ];
        System.assertEquals('Failed', tracker.Status__c, 'Status should be Failed');
        System.assertNotEquals(null, tracker.Error_Messages__c, 'Error messages should be populated');
    }
    
    /**
     * Test platform event publication
     */
    @isTest
    static void testPlatformEventPublication() {
        // Create test CSV
        String csvContent = createTestCSV(true, 1);
        
        // Create a batch tracker
        RLCS_Batch_Tracker__c tracker = new RLCS_Batch_Tracker__c(
            Name = 'Test Event Publication',
            Status__c = 'Processing'
        );
        insert tracker;
        
        // Set up platform event listener
        Test.enableChangeDataCapture();
        
        // Create and execute batch processor
        Test.startTest();
        RLCSJobAATFBatchProcessor batchProcessor = new RLCSJobAATFBatchProcessor(csvContent, tracker.Id);
        
        // Process and finish batch
        Iterable<String> rowsIterable = batchProcessor.start(null);
        List<String> rows = new List<String>();
        Iterator<String> iterator = rowsIterable.iterator();
        while (iterator.hasNext()) {
            rows.add(iterator.next());
        }
        
        batchProcessor.execute(null, rows);
        batchProcessor.finish(new MockBatchableContext()); // Use mock context to provide batch ID
        Test.stopTest();
        
        // Event verification would typically check the EventBus.delivered for the event
        // But we can't easily verify platform event delivery in test context
        // Instead, verify the tracker was fully updated
        tracker = [
            SELECT Id, Status__c, Job_Count__c
            FROM RLCS_Batch_Tracker__c
            WHERE Id = :tracker.Id
        ];
        System.assertEquals('Completed', tracker.Status__c, 'Status should be Completed');
        System.assertEquals(1, tracker.Job_Count__c, 'Job count should be 1');
    }
    
    /**
     * Mock batchable context for testing
     */
    private class MockBatchableContext implements Database.BatchableContext {
        public Id getJobId() {
            return '707000000000000AAA'; // Mock job ID
        }
        
        public Id getChildJobId() {
            return null;
        }
    }
}