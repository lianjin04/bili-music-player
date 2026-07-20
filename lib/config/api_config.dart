/// B站 API 配置
class ApiConfig {
  ApiConfig._();

  // ======== 基础域名 ========
  static const String baseUrl = 'https://api.bilibili.com';

  // ======== 请求头 ========
  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com/',
  };

  // ======== API 端点 ========
  static const String userInfo = '/x/space/myinfo';
  static const String favFolderList = '/x/v3/fav/folder/list';
  static const String favFolderInfo = '/x/v3/fav/folder/info';
  static const String favResourceList = '/x/v3/fav/resource/list';
  static const String medialistResource = '/x/v1/medialist/resource/list';
  static const String videoInfo = '/x/web-interface/view';
  static const String videoPlayer = '/x/player/wbi/v2';
  static const String audioStreamUrl = '/audio/music-service-c/url';

  // ======== 请求控制 ========
  /// 请求间隔（毫秒），防412风控
  static const int requestIntervalMs = 500;

  /// 每页数量上限
  static const int pageSize = 100;
}
