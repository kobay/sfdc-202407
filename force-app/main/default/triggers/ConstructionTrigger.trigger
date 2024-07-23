trigger ConstructionTrigger on Construction__c(after update) {
  if (Trigger.isAfter && Trigger.isUpdate) {
    ConstructionTriggerHandler.handleFinishedConstructions(
      Trigger.new,
      Trigger.oldMap
    );
  }
}
