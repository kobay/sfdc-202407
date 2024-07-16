public class ConstAccountAssocHandler {
  public static void handle(
    // List<ConstAccountAssoc__c> records,
    Map<ID, ConstAccountAssoc__c> recordsMap,
    Boolean isCreate
  ) {
    Set<Id> accountIds = new Set<Id>();
    // Set<Id> constructionIds = new Set<Id>();

    // Setにいれて重複排除
    for (ConstAccountAssoc__c assoc : recordsMap.values()) {
      accountIds.add(assoc.Account__c);
      //   constructionIds.add(assoc.Construction__c);
    }

    Map<Id, Account> accounts = new Map<Id, Account>(
      [SELECT Id, Box_Group_Id__c FROM Account WHERE Id IN :accountIds]
    );
    System.debug('■■■ accounts ' + JSON.serializePretty(accounts));

    box.Toolkit toolkit = new box.Toolkit();

    // ConstAccountAssoc（追加または削除）対象レコードをループ
    for (Id constAccountAssocId : recordsMap.keySet()) {
      // 工事IDを取得
      Id constructionId = recordsMap.get(constAccountAssocId).Construction__c;
      Id accountId = recordsMap.get(constAccountAssocId).Account__c;
      String boxCollaborationId = recordsMap.get(constAccountAssocId)
        .Box_Collaboration_Id__c;

      System.debug('■■■ constructionId ' + constructionId);
      System.debug('■■■ accountId ' + accountId);
      System.debug('■■■ boxCollaborationId ' + boxCollaborationId);

      // 工事についてるBoxのフォルダIDを取得
      String boxFolderId = toolkit.getFolderIdByRecordId(constructionId);
      System.debug('■■■ boxFolderId ' + boxFolderId);
      if (boxFolderId == null) {
        continue;
      }

      // グループを取得
      String boxGroupId = accounts.get(accountId).Box_Group_Id__c;
      System.debug('■■■ boxGroupId ' + boxGroupId);
      if (boxGroupId == null) {
        System.debug('■■■ accountId: ' + accountId + ' has no box group id ');
        continue;
      }
      if (isCreate) {
        // futureを非同期でコール
        createCollaboration(boxGroupId, boxFolderId, constAccountAssocId);
      } else {
        if (boxCollaborationId != null) {
          deleteCollaboration(boxCollaborationId);
        } else {
          System.debug('■■■ boxCollaborationId is null');
        }
      }
    }
  }

  @future(callout=true)
  private static void createCollaboration(
    String boxGroupId,
    String boxFolderId,
    Id constAccountAssocId
  ) {
    try {
      System.debug(
        '■■■ createCollaboration start boxGroupId: ' +
          boxGroupId +
          ' boxFolderId: ' +
          boxFolderId +
          ' constAccountAssocId: ' +
          constAccountAssocId
      );
      BoxAPIManager boxAPIManager = new BoxAPIManager();
      String boxCollaborationId = boxAPIManager.createCollaboration(
        boxGroupId,
        boxFolderId,
        'editor'
      );

      ConstAccountAssoc__c assoc = new ConstAccountAssoc__c(
        Id = constAccountAssocId,
        Box_Collaboration_Id__c = boxCollaborationId
      );
      update assoc;
    } catch (Exception e) {
      System.debug(
        '■■■ Error from boxAPIManager.createCollaboration: ' + e.getMessage()
      );
    }
  }

  @future(callout=true)
  private static void deleteCollaboration(String boxCollaborationId) {
    try {
      System.debug(
        '■■■ deleteCollaboration start boxCollaborationId: ' +
        boxCollaborationId
      );
      BoxAPIManager boxAPIManager = new BoxAPIManager();
      boxAPIManager.deleteCollaboration(boxCollaborationId);
    } catch (Exception e) {
      System.debug(
        '■■■ Error from boxAPIManager.createCollaboration: ' + e.getMessage()
      );
    }
  }
}
