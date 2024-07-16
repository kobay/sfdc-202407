trigger ConstAccountAssocTrigger on ConstAccountAssoc__c(
  after insert,
  before delete
) {
  if (Trigger.isInsert) {
    ConstAccountAssocHandler.handle(Trigger.newMap, true);
  } else if (Trigger.isDelete) {
    ConstAccountAssocHandler.handle(Trigger.oldMap, false);
  }
}
