public with sharing class BoxAPIManager {
  // ここでは簡易的にソースコードに記述する
  public static String BOX_CLIENT_ID = 'zy66qkn5l0yjkvh7wx8pig2ft5fxbwdf';
  public static String BOX_CLIENT_SECRET = 'UsLgnDEyXA3owrwQrF4AXxDRWI2KawoF';
  public static String BOX_ENTERPRISE_ID = '985647265';
  public static String BOX_API_ENDPOINT_BASE = 'https://api.box.com/2.0/';
  public static String BOX_PROJECT_ROOT_FOLDER = '274077613826';

  public String accessToken { get; set; }

  public BoxAPIManager() {
    login();
  }

  public BoxAPIManager(String userId) {
    login(userId);
  }

  public void login() {
    loginCommon('enterprise', BOX_ENTERPRISE_ID);
  }

  private void login(String userId) {
    loginCommon('user', userId);
  }

  private void loginCommon(String subjectType, String subjectId) {
    try {
      HttpRequest request = new HttpRequest();

      Map<String, String> bodyMap = new Map<String, String>();
      bodyMap.put('client_id', BOX_CLIENT_ID);
      bodyMap.put('client_secret', BOX_CLIENT_SECRET);
      bodyMap.put('grant_type', 'client_credentials');
      bodyMap.put('box_subject_type', subjectType);
      bodyMap.put('box_subject_id', subjectId);

      request.setMethod('POST');
      request.setEndpoint('https://api.box.com/oauth2/token');
      request.setHeader('Content-Type', 'application/json');
      request.setBody(JSON.serialize(bodyMap));

      Http http = new Http();
      HttpResponse response = http.send(request);
      Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );

      this.accessToken = (String) results.get('access_token');
    } catch (Exception e) {
      System.debug('Error logging in to Box: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  public String createCollaboration(
    String groupId,
    String folderId,
    String role
  ) {
    Map<String, Object> itemMap = new Map<String, Object>();
    itemMap.put('type', 'folder');
    itemMap.put('id', folderId);

    Map<String, Object> accessibleByMap = new Map<String, Object>();
    accessibleByMap.put('type', 'group');
    accessibleByMap.put('id', groupId);

    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('item', itemMap);
    bodyMap.put('accessible_by', accessibleByMap);
    bodyMap.put('role', role);

    Map<String, Object> results = send('POST', 'collaborations', bodyMap);

    return (String) results.get('id');
  }

  public String deleteCollaboration(String collaborationId) {
    Map<String, Object> results = send(
      'DELETE',
      'collaborations/' + collaborationId,
      null
    );

    return (String) results.get('id');
  }

  public String createAppUser(String name, String sfdcUserId) {
    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('external_app_user_id', sfdcUserId);
    bodyMap.put('is_platform_access_only', true);
    bodyMap.put('name', name);

    Map<String, Object> results = send('POST', 'users', bodyMap);

    return (String) results.get('id');
  }

  public BoxItem createFolder(String parentId, String name) {
    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('name', name);

    Map<String, String> parentMap = new Map<String, String>();
    parentMap.put('id', parentId);
    bodyMap.put('parent', parentMap);

    Map<String, Object> results = send('POST', 'folders', bodyMap);

    BoxItem folder = new BoxItem();
    folder.id = (String) results.get('id');
    folder.name = (String) results.get('name');
    return folder;
  }

  public BoxItem moveFile(String fileId, String parentId) {
    Map<String, Object> bodyMap = new Map<String, Object>();

    Map<String, String> parentMap = new Map<String, String>();
    parentMap.put('id', parentId);
    bodyMap.put('parent', parentMap);

    Map<String, Object> results = send('PUT', 'files/' + fileId, bodyMap);

    BoxItem file = new BoxItem();
    file.id = (String) results.get('id');
    file.name = (String) results.get('name');
    return file;
  }

  public BoxItem putSharedLinkToFolder(String folderId) {
    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('fields', 'shared_link');

    Map<String, String> sharedLinkMap = new Map<String, String>();
    sharedLinkMap.put('access', 'open');
    bodyMap.put('shared_link', sharedLinkMap);

    Map<String, Object> results = (Map<String, Object>) send(
      'PUT',
      'folders/' + folderId,
      bodyMap
    );

    BoxItem folder = new BoxItem();
    Map<String, Object> resultSharedLink = (Map<String, Object>) results.get(
      'shared_link'
    );

    folder.sharedLinkUrl = (String) resultSharedLink.get('url');
    return folder;
  }

  public BoxItem putSharedLinkToFile(String fileId) {
    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('fields', 'shared_link');

    Map<String, String> sharedLinkMap = new Map<String, String>();
    sharedLinkMap.put('access', 'open');
    bodyMap.put('shared_link', sharedLinkMap);

    Map<String, Object> results = (Map<String, Object>) send(
      'PUT',
      'files/' + fileId,
      bodyMap
    );

    BoxItem folder = new BoxItem();
    Map<String, Object> resultSharedLink = (Map<String, Object>) results.get(
      'shared_link'
    );

    folder.sharedLinkUrl = (String) resultSharedLink.get('url');
    return folder;
  }

  public BoxItem removeSharedLinkToFile(String fileId) {
    Map<String, Object> bodyMap = new Map<String, Object>();
    bodyMap.put('fields', 'shared_link');
    bodyMap.put('shared_link', null);

    Map<String, Object> results = (Map<String, Object>) send(
      'PUT',
      'files/' + fileId,
      bodyMap
    );

    BoxItem folder = new BoxItem();
    Map<String, Object> resultSharedLink = (Map<String, Object>) results.get(
      'shared_link'
    );

    folder.sharedLinkUrl = (String) resultSharedLink.get('url');
    return folder;
  }

  private Map<String, Object> send(
    String method,
    String path,
    Map<String, Object> bodyMap
  ) {
    HttpRequest request = new HttpRequest();
    request.setMethod(method);
    request.setEndpoint(BOX_API_ENDPOINT_BASE + path);
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('authorization', 'Bearer ' + this.accessToken);

    if (bodyMap != null) {
      String body = JSON.serialize(bodyMap);
      request.setBody(body);
    }

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() >= 400) {
      Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      String errorMessage =
        'Error creating folder in Box: ' + errorResponse.get('message');
      System.debug(errorMessage);
      throw new AuraHandledException(errorMessage);
    }

    Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
      response.getBody()
    );
    return results;
  }
}
