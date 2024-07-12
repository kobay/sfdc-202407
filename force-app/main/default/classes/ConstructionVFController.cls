public with sharing class ConstructionVFController {
  public String recordId { get; set; }
  public String accessToken { get; set; }
  public String folderId { get; set; }

  public ConstructionVFController(ApexPages.StandardController stdController) {
    recordId = stdController.getId();

    box.Toolkit toolkit = new box.Toolkit();
    folderId = toolkit.getFolderIdByRecordId(recordId);

    if (folderId != null) {
      // BoxAPIManagerをインスタンス化
      BoxAPIManager boxAPIManager = new BoxAPIManager();
      accessToken = boxAPIManager.accessToken;
    }
  }
}
