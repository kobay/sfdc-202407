trigger ConstAccountAssocTrigger on ConstAccountAssoc__c(
  after insert,
  before delete
) {
  if (Trigger.isInsert) {
    ConstAccountAssocHandler.handleCreate(Trigger.newMap);
  } else if (Trigger.isDelete) {
    ConstAccountAssocHandler.handleDelete(Trigger.oldMap);
  }
}
