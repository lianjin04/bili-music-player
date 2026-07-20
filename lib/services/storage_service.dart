import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';
import '../models/favorite_folder.dart';
import '../models/audio_item.dart';

/// 本地存储服务
/// 使用 Hive 管理所有本地数据的持久化
class StorageService {
  static const String _playlistsBox = 'playlists';
  static const String _favoritesBox = 'favorites';
  static const String _historyBox = 'history';
  static const String _likedBox = 'liked';
  static const String _sessionBox = 'session';
  static const int _maxHistory = 50;

  late Box<String> _playlistsBoxRef;
  late Box<String> _favoritesBoxRef;
  late Box<String> _historyBoxRef;
  late Box<String> _likedBoxRef;
  late Box<String> _sessionBoxRef;

  /// 初始化存储服务
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    _playlistsBoxRef = await Hive.openBox<String>(_playlistsBox);
    _favoritesBoxRef = await Hive.openBox<String>(_favoritesBox);
    _historyBoxRef = await Hive.openBox<String>(_historyBox);
    _likedBoxRef = await Hive.openBox<String>(_likedBox);
    _sessionBoxRef = await Hive.openBox<String>(_sessionBox);
  }

  // ======== 收藏夹 ========

  /// 保存收藏夹列表
  Future<void> saveFavoriteFolders(List<FavoriteFolder> folders) async {
    await _favoritesBoxRef.clear();
    for (final folder in folders) {
      await _favoritesBoxRef.put(
        folder.mediaId.toString(),
        jsonEncode(folder.toJson()),
      );
    }
  }

  /// 读取收藏夹列表
  List<FavoriteFolder> getFavoriteFolders() {
    return _favoritesBoxRef.values.map((v) {
      return FavoriteFolder.fromJson(jsonDecode(v));
    }).toList();
  }

  // ======== 歌单 ========

  /// 保存歌单
  Future<void> savePlaylist(Playlist playlist) async {
    await _playlistsBoxRef.put(playlist.id, jsonEncode(playlist.toJson()));
  }

  /// 删除歌单
  Future<void> deletePlaylist(String id) async {
    await _playlistsBoxRef.delete(id);
  }

  /// 获取所有歌单
  List<Playlist> getAllPlaylists() {
    return _playlistsBoxRef.values.map((v) {
      return Playlist.fromJson(jsonDecode(v));
    }).toList();
  }

  /// 获取单个歌单
  Playlist? getPlaylist(String id) {
    final data = _playlistsBoxRef.get(id);
    if (data == null) return null;
    return Playlist.fromJson(jsonDecode(data));
  }

  /// 向歌单添加歌曲
  Future<void> addToPlaylist(String playlistId, String bvid) async {
    final playlist = getPlaylist(playlistId);
    if (playlist == null) return;
    if (!playlist.audioIds.contains(bvid)) {
      playlist.audioIds.add(bvid);
      playlist.updatedAt = DateTime.now();
      await savePlaylist(playlist);
    }
  }

  /// 从歌单移除歌曲
  Future<void> removeFromPlaylist(String playlistId, String bvid) async {
    final playlist = getPlaylist(playlistId);
    if (playlist == null) return;
    playlist.audioIds.remove(bvid);
    playlist.updatedAt = DateTime.now();
    await savePlaylist(playlist);
  }

  // ======== 播放历史 ========

  /// 添加播放历史
  Future<void> addPlayHistory(PlayHistoryEntry entry) async {
    final key = entry.bvid;
    // 如果已存在，先删除（移动到最新）
    if (_historyBoxRef.containsKey(key)) {
      await _historyBoxRef.delete(key);
    }
    await _historyBoxRef.put(key, jsonEncode(entry.toJson()));

    // 超过上限时删除最旧的
    if (_historyBoxRef.length > _maxHistory) {
      final keys = _historyBoxRef.keys.toList();
      final oldestKey = keys.reduce((a, b) {
        final aEntry = PlayHistoryEntry.fromJson(
            jsonDecode(_historyBoxRef.get(a)!));
        final bEntry = PlayHistoryEntry.fromJson(
            jsonDecode(_historyBoxRef.get(b)!));
        return aEntry.playedAt.isBefore(bEntry.playedAt) ? a : b;
      });
      await _historyBoxRef.delete(oldestKey);
    }
  }

  /// 获取播放历史
  List<PlayHistoryEntry> getPlayHistory() {
    final entries = _historyBoxRef.values.map((v) {
      return PlayHistoryEntry.fromJson(jsonDecode(v));
    }).toList();
    entries.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return entries;
  }

  // ======== 我的喜欢 ========

  /// 添加喜欢
  Future<void> addLiked(String bvid) async {
    await _likedBoxRef.put(bvid, DateTime.now().toIso8601String());
  }

  /// 取消喜欢
  Future<void> removeLiked(String bvid) async {
    await _likedBoxRef.delete(bvid);
  }

  /// 是否已喜欢
  bool isLiked(String bvid) => _likedBoxRef.containsKey(bvid);

  /// 获取所有喜欢的BVID列表
  List<String> getLikedList() => _likedBoxRef.keys.toList();

  // ======== 播放状态持久化 ========

  /// 保存当前播放会话
  Future<void> savePlayerSession(PlayerSession session) async {
    await _sessionBoxRef.put('current', jsonEncode(session.toJson()));
  }

  /// 恢复播放会话
  PlayerSession? restorePlayerSession() {
    final data = _sessionBoxRef.get('current');
    if (data == null) return null;
    return PlayerSession.fromJson(jsonDecode(data));
  }

  /// 清除播放会话
  Future<void> clearPlayerSession() async {
    await _sessionBoxRef.delete('current');
  }
}
