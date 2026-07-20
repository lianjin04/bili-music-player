/// B站收藏夹数据模型
class FavoriteFolder {
  final int mediaId; // 收藏夹ID
  final String title; // 收藏夹名称
  final String cover; // 封面URL
  final int mediaCount; // 视频数量
  final String upperName; // UP主名称
  final DateTime syncedAt; // 最后同步时间

  FavoriteFolder({
    required this.mediaId,
    required this.title,
    required this.cover,
    required this.mediaCount,
    required this.upperName,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory FavoriteFolder.fromJson(Map<String, dynamic> json) {
    return FavoriteFolder(
      mediaId: json['id'] ?? json['media_id'] ?? 0,
      title: json['title'] ?? '',
      cover: json['cover'] ?? '',
      mediaCount: json['media_count'] ?? 0,
      upperName: json['upper'] is Map
          ? (json['upper']['name'] ?? '')
          : (json['upper_name'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'media_id': mediaId,
        'title': title,
        'cover': cover,
        'media_count': mediaCount,
        'upper_name': upperName,
        'synced_at': syncedAt.toIso8601String(),
      };

  @override
  String toString() => 'FavoriteFolder($title, $mediaCount videos)';
}
