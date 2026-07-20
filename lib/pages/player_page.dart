import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/audio_item.dart';
import '../models/playlist.dart';

/// 播放器页面
/// 完整的音乐播放界面
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late List<AudioItem> _playlist;
  late int _currentIndex;
  PlayMode _playMode = PlayMode.sequential;

  // 模拟播放状态（实际会通过Provider连接到AudioPlayerService）
  bool _isPlaying = false;
  double _progress = 0.0;
  double _duration = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _playlist = args['playlist'] as List<AudioItem>;
    _currentIndex = args['startIndex'] as int? ?? 0;
  }

  AudioItem get _currentItem => _playlist[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            _buildAppBar(),
            // 封面
            Expanded(child: _buildCover()),
            // 歌曲信息
            _buildSongInfo(),
            // 进度条
            _buildProgressBar(),
            // 控制按钮
            _buildControls(),
            // 播放模式 & 列表
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            '正在播放',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: _showPlaylist,
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: _currentItem.coverUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.music_note, size: 64, color: Colors.grey),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.music_note, size: 64, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            _currentItem.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _currentItem.author,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _progress,
              max: _duration > 0 ? _duration : 1.0,
              onChanged: (v) {
                setState(() => _progress = v);
                // TODO: seek to position via AudioPlayerService
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_progress),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 播放模式
          IconButton(
            icon: Icon(
              _getPlayModeIcon(),
              size: 28,
            ),
            onPressed: _togglePlayMode,
          ),
          // 上一首
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 36),
            onPressed: _previous,
          ),
          // 播放/暂停
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _togglePlay,
            ),
          ),
          // 下一首
          IconButton(
            icon: const Icon(Icons.skip_next, size: 36),
            onPressed: _next,
          ),
          // 喜欢
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              size: 28,
              color: Colors.grey[400],
            ),
            onPressed: () {
              // TODO: toggle liked
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentIndex + 1} / ${_playlist.length}',
            style: TextStyle(color: Colors.grey[500]),
          ),
          TextButton.icon(
            onPressed: _showPlaylist,
            icon: const Icon(Icons.list, size: 20),
            label: Text('查看列表 (${_playlist.length})'),
          ),
        ],
      ),
    );
  }

  // ======== 方法 ========

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _next() {
    if (_currentIndex < _playlist.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0;
      });
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0;
      });
    }
  }

  void _togglePlayMode() {
    setState(() {
      final modes = PlayMode.values;
      _playMode = modes[(_playMode.index + 1) % modes.length];
    });
    _showPlayModeSnackBar();
  }

  IconData _getPlayModeIcon() {
    switch (_playMode) {
      case PlayMode.sequential:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
      case PlayMode.repeatAll:
        return Icons.repeat_on;
    }
  }

  String _getPlayModeText() {
    switch (_playMode) {
      case PlayMode.sequential:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.repeatOne:
        return '单曲循环';
      case PlayMode.repeatAll:
        return '列表循环';
    }
  }

  void _showPlayModeSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getPlayModeText()),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final min = seconds ~/ 60;
    final sec = seconds.toInt() % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    '播放列表',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text('${_playlist.length} 首'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _playlist.length,
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: _playlist[i].coverUrl.isNotEmpty
                        ? NetworkImage(_playlist[i].coverUrl)
                        : null,
                    child: _playlist[i].coverUrl.isEmpty
                        ? const Icon(Icons.music_note, size: 16)
                        : null,
                  ),
                  title: Text(
                    _playlist[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: i == _currentIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  subtitle: Text(_playlist[i].author),
                  trailing: i == _currentIndex
                      ? Icon(Icons.play_arrow,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _currentIndex = i;
                      _progress = 0;
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
