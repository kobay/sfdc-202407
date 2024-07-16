public without sharing class ConstructionVFController {
  public String recordId { get; set; }
  public String accessToken { get; set; }
  public String folderId { get; set; }
  public String message { get; set; }

  public ConstructionVFController(ApexPages.StandardController stdController) {
    recordId = stdController.getId();

    folderId = getFolderIdByRecordId(recordId);
    System.debug('■■■ recordId: ' + recordId);
    System.debug('■■■ folderId: ' + folderId);

    if (folderId == null) {
      message = 'Boxのフォルダが未作成です。';
      System.debug('■■■ folderId is null');
      return;
    }

    // App User IDをとりだす
    User currentUser = [
      SELECT Id, Name, Box_App_User_Id__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    String boxUserId = currentUser.Box_App_User_Id__c;
    if (boxUserId == null) {
      message = 'UserオブジェクトにAppUserIdの紐づけがされていません。';
      System.debug('■■■ boxUserId is null');
      return;
    }
    BoxAPIManager boxAPIManager = new BoxAPIManager(boxUserId);
    accessToken = boxAPIManager.accessToken;
    if (accessToken == null) {
      message = 'ユーザーのアクセストークンが取得できませんでした。';
      System.debug('■■■ accessToken is null');
    }

    message = 'OK';
  }

  private String getFolderIdByRecordId(Id recordId) {
    if (recordId == null) {
      System.debug('■■■ recordId is null');
      return null;
    }
    String searchPrefix = String.valueOf(recordId) + '%';
    box__FRUP__c frup = [
      SELECT
        Id,
        Name,
        CreatedDate,
        CreatedById,
        LastModifiedDate,
        box__Object_Name__c,
        box__Folder_ID__c,
        box__Record_ID_Indexed__c
      FROM box__FRUP__c
      WHERE
        box__Object_Name__c = 'Construction__c'
        AND box__Record_ID_Indexed__c LIKE :searchPrefix
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    if (frup == null) {
      System.debug('■■■ frup is null');
      return null;
    }
    if (frup.box__Folder_ID__c == null) {
      System.debug('■■■ frup.box__Folder_ID__c is null');
      return null;
    }
    return frup.box__Folder_ID__c;
  }
}
