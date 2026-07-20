import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/audio_item.dart';

/// 音频列表项组件
/// 在收藏夹详情、播放列表等场景中复用
class AudioListTile extends StatelessWidget {
  final AudioItem item;
  final int index;
  final bool isCurrentPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const AudioListTile({
    super.key,
    required this.item,
    required this.index,
    this.isCurrentPlaying = false,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CachedNetworkImage(
                imageUrl: item.coverUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.music_note, size: 20),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 20),
                ),
              ),
            ),
          ),
          if (isCurrentPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
          color: isCurrentPlaying
              ? Theme.of(context).colorScheme.primary
              : (item.isAvailable ? null : Colors.grey),
          decoration: item.isAvailable ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              item.author,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!item.isAvailable)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '失效',
                style: TextStyle(fontSize: 10, color: Colors.red[400]),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            item.durationText,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: trailing,
      enabled: item.isAvailable,
      onTap: item.isAvailable ? onTap : null,
      onLongPress: onLongPress,
    );
  }
}
