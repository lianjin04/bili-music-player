import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/bilibili_api_service.dart';
import '../models/favorite_folder.dart';
import '../models/audio_item.dart';

/// 收藏夹详情页面
/// 展示收藏夹内的所有视频（音频）列表
class FavoriteDetailPage extends StatefulWidget {
  final BilibiliApiService apiService;

  const FavoriteDetailPage({super.key, required this.apiService});

  @override
  State<FavoriteDetailPage> createState() => _FavoriteDetailPageState();
}

class _FavoriteDetailPageState extends State<FavoriteDetailPage> {
  List<AudioItem> _items = [];
  bool _isLoading = true;
  String? _error;
  late FavoriteFolder _folder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _folder = ModalRoute.of(context)!.settings.arguments as FavoriteFolder;
    if (_items.isEmpty) {
      _loadVideos();
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final videos = await widget.apiService.getFavoriteVideos(_folder.mediaId);
      if (mounted) {
        setState(() {
          _items = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_folder.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 收藏夹头部统计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.music_note, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_items.length} / ${_folder.mediaCount} 个视频',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                if (_items.isNotEmpty)
                  TextButton.icon(
                    onPressed: _playAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                  ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVideos, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('收藏夹为空或所有视频已失效'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildAudioItem(_items[index]),
      ),
    );
  }

  Widget _buildAudioItem(AudioItem item) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: item.isAvailable ? null : TextDecoration.lineThrough,
          color: item.isAvailable ? null : Colors.grey,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            item.author,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          if (!item.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '已失效',
                style: TextStyle(fontSize: 10, color: Colors.red[400]),
              ),
            ),
          const Spacer(),
          Text(
            item.durationText,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      enabled: item.isAvailable,
      onTap: item.isAvailable ? () => _playItem(index) : null,
    );
  }

  void _playAll() {
    Navigator.of(context).pushNamed(
      '/player',
      arguments: {
        'playlist': _items.where((e) => e.isAvailable).toList(),
        'startIndex': 0,
      },
    );
  }

  void _playItem(int index) {
    Navigator.of(context).pushNamed(
      '/player',
      arguments: {
        'playlist': _items.where((e) => e.isAvailable).toList(),
        'startIndex': index,
      },
    );
  }
}
