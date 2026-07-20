import 'package:uuid/uuid.dart';

/// 播放模式枚举
enum PlayMode {
  sequential, // 顺序播放
  shuffle, // 随机播放
  repeatOne, // 单曲循环
  repeatAll, // 列表循环
}

/// 播放状态
class PlayerSession {
  final List<String> playlist; // 当前播放列表 (BVID列表)
  final int currentIndex; // 当前播放位置
  final int position; // 当前进度（秒）
  final PlayMode playMode; // 播放模式
  final DateTime lastPlayedAt; // 最后播放时间

  PlayerSession({
    required this.playlist,
    required this.currentIndex,
    required this.position,
    required this.playMode,
    DateTime? lastPlayedAt,
  }) : lastPlayedAt = lastPlayedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'playlist': playlist,
        'current_index': currentIndex,
        'position': position,
        'play_mode': playMode.index,
        'last_played_at': lastPlayedAt.toIso8601String(),
      };

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    return PlayerSession(
      playlist: List<String>.from(json['playlist'] ?? []),
      currentIndex: json['current_index'] ?? 0,
      position: json['position'] ?? 0,
      playMode: PlayMode.values[json['play_mode'] ?? 0],
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'])
          : null,
    );
  }
}

/// 歌单数据模型
class Playlist {
  final String id; // 歌单唯一ID (UUID)
  String name; // 歌单名称
  List<String> audioIds; // 歌单内的音频BVID列表
  final DateTime createdAt; // 创建时间
  DateTime updatedAt; // 最后修改时间

  Playlist({
    String? id,
    required this.name,
    List<String>? audioIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        audioIds = audioIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'audio_ids': audioIds,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'] ?? '',
      audioIds: List<String>.from(json['audio_ids'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  @override
  String toString() => 'Playlist($name, ${audioIds.length} songs)';
}

/// 播放历史记录
class PlayHistoryEntry {
  final String bvid;
  final String title;
  final int progress; // 播放进度（秒）
  final DateTime playedAt;

  PlayHistoryEntry({
    required this.bvid,
    required this.title,
    this.progress = 0,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'title': title,
        'progress': progress,
        'played_at': playedAt.toIso8601String(),
      };

  factory PlayHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PlayHistoryEntry(
      bvid: json['bvid'] ?? '',
      title: json['title'] ?? '',
      progress: json['progress'] ?? 0,
      playedAt: json['played_at'] != null
          ? DateTime.parse(json['played_at'])
          : null,
    );
  }
}
