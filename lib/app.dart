import 'package:flutter/material.dart';
import 'services/bilibili_api_service.dart';
import 'services/storage_service.dart';
import 'services/cache_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/favorite_detail_page.dart';
import 'pages/player_page.dart';

/// 应用根组件
class BiliMusicApp extends StatelessWidget {
  final BilibiliApiService apiService;
  final StorageService storageService;
  final CacheService cacheService;

  const BiliMusicApp({
    super.key,
    required this.apiService,
    required this.storageService,
    required this.cacheService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B站音乐播放器',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginPage(apiService: apiService),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomePage(
                apiService: apiService,
                storageService: storageService,
              ),
            );
          case '/favorite-detail':
            return MaterialPageRoute(
              builder: (_) =>
                  FavoriteDetailPage(apiService: apiService),
            );
          case '/player':
            return MaterialPageRoute(
              builder: (_) => const PlayerPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => LoginPage(apiService: apiService),
            );
        }
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
