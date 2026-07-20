import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 音频缓存服务
/// 管理音频文件的本地缓存，支持LRU淘汰策略
class CacheService {
  static const String _cacheDirName = 'audio_cache';
  static const int _defaultMaxSize = 2 * 1024 * 1024 * 1024; // 2GB

  late final String _cachePath;
  int _maxSize;
  final Map<String, CacheEntry> _index = {};

  CacheService({int? maxSize}) : _maxSize = maxSize ?? _defaultMaxSize;

  /// 初始化缓存服务
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _cachePath = '${dir.path}/$_cacheDirName';
    final cacheDir = Directory(_cachePath);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    await _rebuildIndex();
  }

  /// 获取缓存的音频文件路径
  /// 如果缓存已存在则直接返回路径，否则返回null
  Future<String?> getCachedPath(String bvid) async {
    final entry = _index[bvid];
    if (entry == null) return null;

    final file = File(entry.path);
    if (await file.exists()) {
      // 更新最后访问时间
      entry.lastAccess = DateTime.now();
      return entry.path;
    }
    _index.remove(bvid);
    return null;
  }

  /// 缓存音频文件
  Future<String> cacheAudio(String bvid, String sourceUrl,
      {required Future<File> Function(String url, String savePath) downloader}) async {
    // 先检查是否已缓存
    final existing = await getCachedPath(bvid);
    if (existing != null) return existing;

    final savePath = '$_cachePath/$bvid.m4a';

    try {
      // 下载文件
      final file = await downloader(sourceUrl, savePath);
      final length = await file.length();

      // 记录缓存索引
      _index[bvid] = CacheEntry(
        bvid: bvid,
        path: savePath,
        size: length,
        lastAccess: DateTime.now(),
        cachedAt: DateTime.now(),
      );

      // 检查是否需要淘汰
      await _evictIfNeeded();

      return savePath;
    } catch (e) {
      print('[Cache] 缓存音频失败: $e');
      rethrow;
    }
  }

  /// 检查音频是否已缓存
  Future<bool> isCached(String bvid) async {
    final entry = _index[bvid];
    if (entry == null) return false;
    final file = File(entry.path);
    if (!await file.exists()) {
      _index.remove(bvid);
      return false;
    }
    return true;
  }

  /// 获取缓存统计信息
  Future<CacheStats> getStats() async {
    int totalSize = 0;
    int fileCount = 0;

    for (final entry in _index.values) {
      final file = File(entry.path);
      if (await file.exists()) {
        totalSize += entry.size;
        fileCount++;
      }
    }

    return CacheStats(
      totalSize: totalSize,
      fileCount: fileCount,
      maxSize: _maxSize,
    );
  }

  /// 删除指定音频的缓存
  Future<void> clearCache(String bvid) async {
    final entry = _index.remove(bvid);
    if (entry != null) {
      final file = File(entry.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    final cacheDir = Directory(_cachePath);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    }
    _index.clear();
  }

  /// 设置缓存上限
  Future<void> setMaxSize(int size) async {
    _maxSize = size;
    await _evictIfNeeded();
  }

  // ======== 内部方法 ========

  /// 重建缓存索引
  Future<void> _rebuildIndex() async {
    _index.clear();
    final cacheDir = Directory(_cachePath);
    if (!await cacheDir.exists()) return;

    await for (final entity in cacheDir.list()) {
      if (entity is File && entity.path.endsWith('.m4a')) {
        final bvid = entity.uri.pathSegments.last.replaceAll('.m4a', '');
        final stat = await entity.stat();
        _index[bvid] = CacheEntry(
          bvid: bvid,
          path: entity.path,
          size: stat.size,
          lastAccess: stat.accessed,
          cachedAt: stat.modified,
        );
      }
    }
  }

  /// LRU淘汰：超过上限时删除最久未访问的文件
  Future<void> _evictIfNeeded() async {
    int totalSize = 0;
    for (final entry in _index.values) {
      totalSize += entry.size;
    }

    if (totalSize <= _maxSize) return;

    // 按最后访问时间排序
    final sorted = _index.values.toList()
      ..sort((a, b) => a.lastAccess.compareTo(b.lastAccess));

    final targetSize = (_maxSize * 0.8).toInt(); // 降到80%
    for (final entry in sorted) {
      if (totalSize <= targetSize) break;
      final file = File(entry.path);
      if (await file.exists()) {
        await file.delete();
        totalSize -= entry.size;
      }
      _index.remove(entry.bvid);
    }
  }
}

/// 缓存条目
class CacheEntry {
  final String bvid;
  final String path;
  final int size;
  DateTime lastAccess;
  final DateTime cachedAt;

  CacheEntry({
    required this.bvid,
    required this.path,
    required this.size,
    required this.lastAccess,
    required this.cachedAt,
  });
}

/// 缓存统计信息
class CacheStats {
  final int totalSize;
  final int fileCount;
  final int maxSize;

  CacheStats({
    required this.totalSize,
    required this.fileCount,
    required this.maxSize,
  });

  /// 缓存使用率（0.0 ~ 1.0）
  double get usageRatio => maxSize > 0 ? totalSize / maxSize : 0;

  /// 格式化大小显示
  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 格式化上限大小
  String get formattedMaxSize {
    if (maxSize < 1024 * 1024) return '${(maxSize / 1024).toStringAsFixed(0)} KB';
    if (maxSize < 1024 * 1024 * 1024) {
      return '${(maxSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(maxSize / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB';
  }
}
