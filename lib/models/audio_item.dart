/// 音频条目数据模型（对应B站单个视频的音频）
class AudioItem {
  final String bvid; // BV号
  final String title; // 视频标题
  final String author; // UP主
  final String coverUrl; // 封面URL
  final String? audioUrl; // 音频流地址（播放时实时获取）
  final int duration; // 时长（秒）
  final bool isAvailable; // 是否有效（未被和谐）

  AudioItem({
    required this.bvid,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.audioUrl,
    this.duration = 0,
    this.isAvailable = true,
  });

  factory AudioItem.fromJson(Map<String, dynamic> json) {
    // B站API返回的字段名可能不同
    return AudioItem(
      bvid: json['bvid'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ??
          (json['upper'] is Map
              ? (json['upper']['name'] ?? '')
              : (json['owner'] is Map ? (json['owner']['name'] ?? '') : '')),
      coverUrl: json['pic'] ?? json['cover'] ?? '',
      duration: json['duration'] ?? 0,
      isAvailable: json['state'] != null ? json['state'] == 0 : true,
    );
  }

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'audio_url': audioUrl,
        'duration': duration,
        'is_available': isAvailable,
      };

  /// 格式化为 "mm:ss" 时长字符串
  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'AudioItem($bvid, $title)';
}
