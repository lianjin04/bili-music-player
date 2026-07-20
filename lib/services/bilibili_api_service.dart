import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/favorite_folder.dart';
import '../models/audio_item.dart';

/// B站 API 服务
/// 负责所有B站接口的调用、Cookie认证、请求频率控制
class BilibiliApiService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  DateTime _lastRequestTime = DateTime.now();

  static const String _cookieKey = 'bilibili_cookie';
  static const String _csrfKey = 'bilibili_csrf';

  BilibiliApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: Map<String, String>.from(ApiConfig.defaultHeaders),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加Cookie
        final cookie = _cookie;
        if (cookie.isNotEmpty) {
          options.headers['Cookie'] = cookie;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 412) {
          print('[BiliAPI] 412 Precondition Failed - 请求过于频繁');
        }
        handler.next(error);
      },
    ));
  }

  // ======== Cookie 管理 ========

  String _cookie = '';

  /// 获取保存的Cookie
  String get cookie => _cookie;

  /// 是否有有效的Cookie
  bool get hasCookie => _cookie.isNotEmpty;

  /// 设置Cookie
  Future<void> setCookie(String cookie) async {
    _cookie = cookie.trim();
    await _secureStorage.write(key: _cookieKey, value: _cookie);

    // 尝试从Cookie中提取bili_jct作为csrf
    final match = RegExp(r'bili_jct=([^;]+)').firstMatch(_cookie);
    if (match != null) {
      await _secureStorage.write(key: _csrfKey, value: match.group(1)!);
    }
  }

  /// 从本地加载Cookie
  Future<bool> loadCookie() async {
    final cookie = await _secureStorage.read(key: _cookieKey);
    if (cookie != null && cookie.isNotEmpty) {
      _cookie = cookie;
      return true;
    }
    return false;
  }

  /// 清除Cookie
  Future<void> clearCookie() async {
    _cookie = '';
    await _secureStorage.delete(key: _cookieKey);
    await _secureStorage.delete(key: _csrfKey);
  }

  // ======== 请求频率控制 ========

  /// 等待到允许下一次请求的时间
  Future<void> _throttle() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime).inMilliseconds;
    if (elapsed < ApiConfig.requestIntervalMs) {
      await Future.delayed(
          Duration(milliseconds: ApiConfig.requestIntervalMs - elapsed));
    }
    _lastRequestTime = DateTime.now();
  }

  // ======== 用户信息 ========

  /// 获取当前登录用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    await _throttle();
    try {
      final response = await _dio.get(ApiConfig.userInfo);
      if (response.data['code'] == 0) {
        return response.data['data'];
      }
      print('[BiliAPI] 获取用户信息失败: ${response.data['message']}');
      return null;
    } catch (e) {
      print('[BiliAPI] 获取用户信息异常: $e');
      return null;
    }
  }

  // ======== 收藏夹 ========

  /// 获取当前用户的所有收藏夹列表
  Future<List<FavoriteFolder>> getFavoriteFolders() async {
    await _throttle();
    try {
      final response = await _dio.get(
        ApiConfig.favFolderList,
        queryParameters: {'up_mid': await _getMyMid()},
      );

      if (response.data['code'] == 0) {
        final list = response.data['data']['list'] as List? ?? [];
        return list.map((e) => FavoriteFolder.fromJson(e)).toList();
      }
      print('[BiliAPI] 获取收藏夹列表失败: ${response.data['message']}');
      return [];
    } catch (e) {
      print('[BiliAPI] 获取收藏夹列表异常: $e');
      return [];
    }
  }

  /// 获取收藏夹内的所有视频列表
  Future<List<AudioItem>> getFavoriteVideos(int mediaId,
      {int page = 1, int pageSize = 100}) async {
    await _throttle();
    try {
      final response = await _dio.get(
        ApiConfig.favResourceList,
        queryParameters: {
          'media_id': mediaId,
          'pn': page,
          'ps': pageSize,
          'platform': 'web',
        },
      );

      if (response.data['code'] == 0) {
        final list = response.data['data']['medias'] as List? ?? [];
        return list
            .map((e) => AudioItem(
                  bvid: e['bvid'] ?? '',
                  title: e['title'] ?? '',
                  author: e['upper'] is Map ? (e['upper']['name'] ?? '') : '',
                  coverUrl: e['cover'] ?? e['pic'] ?? '',
                  duration: e['duration'] ?? 0,
                  isAvailable: (e['attr'] ?? 0) != 1,
                ))
            .toList();
      }
      print('[BiliAPI] 获取收藏夹视频失败: ${response.data['message']}');
      return [];
    } catch (e) {
      print('[BiliAPI] 获取收藏夹视频异常: $e');
      return [];
    }
  }

  // ======== 音频流 ========

  /// 获取视频的音频流地址
  Future<String?> getAudioUrl(String bvid) async {
    await _throttle();

    // 第一步：获取视频信息（含cid）
    try {
      final infoResp = await _dio.get(
        ApiConfig.videoInfo,
        queryParameters: {'bvid': bvid},
      );
      if (infoResp.data['code'] != 0) return null;

      final data = infoResp.data['data'];
      final cid = data['cid'] ?? 0;

      // 第二步：获取播放信息（含音频流地址）
      final playResp = await _dio.get(
        ApiConfig.videoPlayUrl,
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'qn': 128,
          'fnver': 0,
          'fnval': 4048,
          'platform': 'web',
          'otype': 'json',
        },
      );

      if (playResp.data['code'] == 0) {
        final dash = playResp.data['data']['dash'];
        if (dash != null && dash['audio'] != null && dash['audio'].isNotEmpty) {
          // 获取最高音质的音频流
          final audios = List<Map<String, dynamic>>.from(dash['audio']);
          audios.sort((a, b) => (b['bandwidth'] ?? 0) - (a['bandwidth'] ?? 0));
          return audios.first['baseUrl'] ??
              audios.first['base_url'] ??
              audios.first['backupUrl']?.first ??
              audios.first['backup_url']?.first;
        }
      }
      return null;
    } catch (e) {
      print('[BiliAPI] 获取音频流地址异常: $e');
      return null;
    }
  }

  // ======== 辅助方法 ========

  /// 获取当前用户mid
  Future<int> _getMyMid() async {
    final info = await getUserInfo();
    return info?['mid'] ?? 0;
  }
}
