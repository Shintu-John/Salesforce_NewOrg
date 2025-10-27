@isTest
public class SignatureLwcHelperTest {
    public static testmethod void testSignatureLwcHelper(){
        String ContentVersionData = 'test';
        String recordId = UserInfo.getUserId();
        String docIdField = null;
        SignatureLwcHelper.saveSignature(ContentVersionData, recordId, docIdField);
    }
}