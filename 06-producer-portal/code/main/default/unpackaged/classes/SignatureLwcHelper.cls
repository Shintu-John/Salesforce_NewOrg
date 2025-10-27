public with sharing class SignatureLwcHelper {
    
    @AuraEnabled
    public static String saveSignature(String ContentVersionData, Id recordId, String docIdField){
		List<Folder> signFolder = [SELECT Id, Name FROM Folder WHERE Name = 'signature' limit 1];
		// Insert Blob as Document in salesforce
		blob file = EncodingUtil.base64Decode(ContentVersionData);
		Document doc = new Document();
		doc.body = file;
		doc.name = 'Signature_'+ recordId +'_'+String.valueOf(System.today());
		doc.ContentType= 'image/jpg';
		doc.isPublic = true;
		doc.FolderId = signFolder.size() > 0 ? signFolder[0].Id : UserInfo.getUserId();
		insert doc;

		Schema.SObjectType sObjectType = recordId.getSObjectType();
        sObject record = sObjectType.newSObject(recordId);
		if(docIdField != null){
			record.put(docIdField, doc.Id);
		}
		update record;

        return doc.Id;
    }
}