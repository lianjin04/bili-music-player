import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/bilibili_api_service.dart';
import 'services/storage_service.dart';
import 'services/cache_service.dart';

/// B站收藏夹音乐播放器 - 主入口
///
/// 功能：将B站个人收藏夹当歌单听歌
/// 平台：Windows + Android (Flutter跨平台)
///
/// 核心流程：
/// 1. 用户输入B站Cookie登录
/// 2. 获取收藏夹列表
/// 3. 选择收藏夹查看视频列表
/// 4. 点击视频播放音频（B站DASH协议音视频分离，直接取音频流）
/// 5. 支持在线播放、本地缓存、歌单管理
Future<void> main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置为竖屏锁定（音乐播放器不需要横屏）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化服务
  final storageService = StorageService();
  await storageService.init();

  final cacheService = CacheService();
  await cacheService.init();

  final apiService = BilibiliApiService();

  // 尝试自动加载已保存的Cookie
  final hasCookie = await apiService.loadCookie();

  // 运行应用
  runApp(BiliMusicApp(
    apiService: apiService,
    storageService: storageService,
    cacheService: cacheService,
  ));

  // 如果已有Cookie，自动跳转到主页
  if (hasCookie) {
    // 注意：实际路由跳转需要NavigatorKey，这里简化处理
    // 在app.dart中可以通过initialRoute逻辑处理
  }
}
