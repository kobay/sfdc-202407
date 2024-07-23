public class ConstructionTriggerHandler {
  public static void handleFinishedConstructions(
    List<Construction__c> newConstructions,
    Map<Id, Construction__c> oldConstructionsMap
  ) {
    Set<Id> finishedConstructionIds = new Set<Id>();
    Set<Id> unfinishedConstructionIds = new Set<Id>();

    System.debug(
      '■■■ ConstructionTriggerHandler ' + JSON.serializePretty(newConstructions)
    );

    for (Construction__c newConstruction : newConstructions) {
      Construction__c oldConstruction = oldConstructionsMap.get(
        newConstruction.Id
      );
      System.debug('■■■ Check Loop ');

      if (
        newConstruction.status__c == '工事完了' &&
        oldConstruction.status__c != '工事完了'
      ) {
        System.debug('■■■ Check Loop 工事完了になった。');
        finishedConstructionIds.add(newConstruction.Id);
      }
      if (
        newConstruction.status__c != '工事完了' &&
        oldConstruction.status__c == '工事完了'
      ) {
        System.debug('■■■ Check Loop 工事完了でなくなった。');
        unfinishedConstructionIds.add(newConstruction.Id);
      }
    }

    if (!finishedConstructionIds.isEmpty()) {
      System.debug(
        '■■■ finishedConstructionIds.size()  ' + finishedConstructionIds.size()
      );
      updateBoxCollaborations(finishedConstructionIds, 'previewer');
    }
    if (!unfinishedConstructionIds.isEmpty()) {
      System.debug(
        '■■■ unfinishedConstructionIds.size() ' +
        unfinishedConstructionIds.size()
      );
      updateBoxCollaborations(unfinishedConstructionIds, 'editor');
    }
  }

  private static void updateBoxCollaborations(
    Set<Id> constructionIds,
    String role
  ) {
    List<ConstAccountAssoc__c> associations = [
      SELECT Box_Collaboration_Id__c
      FROM ConstAccountAssoc__c
      WHERE
        Construction__c IN :constructionIds
        AND Box_Collaboration_Id__c != NULL
    ];

    System.debug('■■■ associations ' + JSON.serializePretty(associations));
    for (ConstAccountAssoc__c assoc : associations) {
      updateCollaboration(assoc.Box_Collaboration_Id__c, role);
    }
  }

  @future(callout=true)
  private static void updateCollaboration(
    String boxCollaborationId,
    String role
  ) {
    try {
      System.debug(
        '■■■ updateCollaboration start boxCollaborationId: ' +
        boxCollaborationId
      );
      BoxAPIManager boxAPIManager = new BoxAPIManager();
      boxAPIManager.updateCollaboration(boxCollaborationId, role);
    } catch (Exception e) {
      System.debug(
        '■■■ Error from boxAPIManager.updateCollaboration: ' + e.getMessage()
      );
    }
  }
}
