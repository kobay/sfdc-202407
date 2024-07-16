public without sharing class ConstAccountAssocHandler {
  public static void handleCreate(Map<ID, ConstAccountAssoc__c> recordsMap) {
    Set<Id> accountIds = new Set<Id>();

    // Setにいれて重複排除
    for (ConstAccountAssoc__c assoc : recordsMap.values()) {
      accountIds.add(assoc.Account__c);
    }

    Map<Id, Account> accounts = new Map<Id, Account>(
      [SELECT Id, Box_Group_Id__c FROM Account WHERE Id IN :accountIds]
    );
    System.debug('■■■ accounts ' + JSON.serializePretty(accounts));

    // 共有設定を作る
    Map<Id, Set<Id>> accountToPartnerUserIds = getPartnerUsersByAccount(
      accountIds
    );
    System.debug(
      '■■■ accountToPartnerUserIds ' +
      JSON.serializePretty(accountToPartnerUserIds)
    );

    List<Construction__Share> sharesToInsert = new List<Construction__Share>();

    for (ConstAccountAssoc__c assoc : recordsMap.values()) {
      Set<Id> partnerUserIds = accountToPartnerUserIds.get(assoc.Account__c);
      if (partnerUserIds != null && !partnerUserIds.isEmpty()) {
        for (Id userId : partnerUserIds) {
          Construction__Share share = new Construction__Share();
          share.ParentId = assoc.Construction__c;
          share.UserOrGroupId = userId;
          share.AccessLevel = 'Read';
          sharesToInsert.add(share);
        }
      }
    }
    System.debug('■■■ sharesToInsert ' + JSON.serializePretty(sharesToInsert));
    if (!sharesToInsert.isEmpty()) {
      Database.insert(sharesToInsert, false);
    }

    // Box上にコラボレーションを作成
    box.Toolkit toolkit = new box.Toolkit();

    for (Id constAccountAssocId : recordsMap.keySet()) {
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

      // futureを非同期でコール
      createCollaboration(boxGroupId, boxFolderId, constAccountAssocId);
    }
  }

  public static void handleDelete(Map<ID, ConstAccountAssoc__c> recordsMap) {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> constructionIds = new Set<Id>();

    // Setにいれて重複排除
    for (ConstAccountAssoc__c assoc : recordsMap.values()) {
      accountIds.add(assoc.Account__c);
      constructionIds.add(assoc.Construction__c);
    }

    // 関連するパートナーユーザーを取得
    Map<Id, Set<Id>> accountToPartnerUserIds = getPartnerUsersByAccount(
      accountIds
    );

    System.debug(
      '■■■ accountToPartnerUserIds ' +
      JSON.serializePretty(accountToPartnerUserIds)
    );

    Set<Id> partnerUserIds = new Set<Id>();
    for (Set<Id> ids : accountToPartnerUserIds.values()) {
      partnerUserIds.addAll(ids);
    }

    // 削除すべき共有レコードを特定
    List<Construction__Share> sharesToDelete = [
      SELECT Id, ParentId
      FROM Construction__Share
      WHERE
        ParentId IN :constructionIds
        AND UserOrGroupId IN :partnerUserIds
        AND RowCause = 'Manual'
    ];

    System.debug('■■■ sharesToDelete ' + JSON.serializePretty(sharesToDelete));

    if (!sharesToDelete.isEmpty()) {
      Database.delete(sharesToDelete, false);
    }

    // Box上のコラボレーションを削除
    for (Id constAccountAssocId : recordsMap.keySet()) {
      String boxCollaborationId = recordsMap.get(constAccountAssocId)
        .Box_Collaboration_Id__c;

      System.debug('■■■ boxCollaborationId ' + boxCollaborationId);

      if (boxCollaborationId != null) {
        deleteCollaboration(boxCollaborationId);
      } else {
        System.debug('■■■ boxCollaborationId is null');
      }
    }
  }

  private static Map<Id, Set<Id>> getPartnerUsersByAccount(Set<Id> accountIds) {
    Map<Id, Set<Id>> accountToPartnerUserIds = new Map<Id, Set<Id>>();

    for (User u : [
      SELECT ContactId, Contact.AccountId
      FROM User
      WHERE
        Contact.AccountId IN :accountIds
        AND IsActive = TRUE
        AND UserType = 'PowerPartner'
    ]) {
      if (!accountToPartnerUserIds.containsKey(u.Contact.AccountId)) {
        accountToPartnerUserIds.put(u.Contact.AccountId, new Set<Id>());
      }
      accountToPartnerUserIds.get(u.Contact.AccountId).add(u.Id);
    }

    return accountToPartnerUserIds;
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
