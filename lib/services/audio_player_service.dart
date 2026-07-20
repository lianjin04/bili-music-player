import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod/riverpod.dart';
import '../models/audio_item.dart';
import '../models/playlist.dart';

/// 音频播放器服务
/// 封装 just_audio，提供统一的播放控制接口
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final BilibiliApiServiceForPlayer _apiService;

  List<AudioItem> _playlist = [];
  int _currentIndex = 0;
  PlayMode _playMode = PlayMode.sequential;

  // 状态流
  final _currentIndexController = StreamController<int>.broadcast();
  final _playModeController = StreamController<PlayMode>.broadcast();
  final _playlistController = StreamController<List<AudioItem>>.broadcast();

  AudioPlayerService(this._apiService) {
    // 监听播放完成事件，自动下一首
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onAudioComplete();
      }
    });
  }

  // ======== 公开流 ========

  /// 播放器状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// 播放进度流
  Stream<Duration> get positionStream => _player.positionStream;

  /// 音频时长流
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 当前播放索引流
  Stream<int> get currentIndexStream => _currentIndexController.stream;

  /// 播放模式流
  Stream<PlayMode> get playModeStream => _playModeController.stream;

  /// 播放列表流
  Stream<List<AudioItem>> get playlistStream => _playlistController.stream;

  /// 当前播放状态
  PlayerState? get currentState => _player.playerState;

  /// 当前音量
  double get volume => _player.volume;

  /// 当前播放索引
  int get currentIndex => _currentIndex;

  /// 当前播放歌曲
  AudioItem? get currentItem =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  /// 播放列表
  List<AudioItem> get playlist => List.unmodifiable(_playlist);

  /// 当前播放模式
  PlayMode get playMode => _playMode;

  // ======== 播放控制 ========

  /// 设置播放列表
  Future<void> setPlaylist(List<AudioItem> items, {int startIndex = 0}) async {
    _playlist = List.from(items);
    _currentIndex = startIndex;
    _playlistController.add(_playlist);
    await _playCurrent();
  }

  /// 播放指定索引的歌曲
  Future<void> playAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    _currentIndexController.add(_currentIndex);
    await _playCurrent();
  }

  /// 播放/暂停切换
  Future<void> togglePlayPause() async {
    if (_player.playerState.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// 播放
  Future<void> play() async {
    if (_playlist.isEmpty) return;
    if (_player.playerState.processingState == ProcessingState.idle) {
      await _playCurrent();
    } else {
      await _player.play();
    }
  }

  /// 暂停
  Future<void> pause() async => await _player.pause();

  /// 下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    int nextIndex;
    if (_playMode == PlayMode.shuffle) {
      nextIndex = _getRandomIndex();
    } else {
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }
    await playAt(nextIndex);
  }

  /// 上一首
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    int prevIndex;
    if (_playMode == PlayMode.shuffle) {
      prevIndex = _getRandomIndex();
    } else {
      prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }
    await playAt(prevIndex);
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async => await _player.seek(position);

  /// 设置音量
  Future<void> setVolume(double vol) async => await _player.setVolume(vol);

  /// 切换播放模式
  Future<void> togglePlayMode() async {
    final modes = PlayMode.values;
    final nextIndex = (_playMode.index + 1) % modes.length;
    _playMode = modes[nextIndex];
    _playModeController.add(_playMode);
  }

  /// 设置播放模式
  Future<void> setPlayMode(PlayMode mode) async {
    _playMode = mode;
    _playModeController.add(_playMode);
  }

  // ======== 内部方法 ========

  /// 播放当前索引的歌曲
  Future<void> _playCurrent() async {
    if (_currentIndex >= _playlist.length) return;
    final item = _playlist[_currentIndex];

    // 获取音频流地址
    String? url = item.audioUrl;
    if (url == null || url.isEmpty) {
      url = await _apiService.getAudioUrl(item.bvid);
    }

    if (url != null && url.isNotEmpty) {
      try {
        await _player.setAudioSource(AudioSource.uri(
          Uri.parse(url),
          headers: {
            'Referer': 'https://www.bilibili.com/',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ));
        await _player.play();
      } catch (e) {
        print('[Player] 播放失败: $e');
      }
    }
  }

  /// 播放完成回调
  void _onAudioComplete() {
    if (_playMode == PlayMode.repeatOne) {
      // 单曲循环：重新播放当前
      _playCurrent();
    } else if (_playMode == PlayMode.repeatAll ||
        _playMode == PlayMode.shuffle) {
      // 列表循环或随机：播放下一首
      next();
    }
    // 顺序播放：播放完成自然停止
  }

  /// 随机获取一个索引（不与当前相同）
  int _getRandomIndex() {
    if (_playlist.length <= 1) return 0;
    int index;
    do {
      index = DateTime.now().microsecondsSinceEpoch % _playlist.length;
    } while (index == _currentIndex);
    return index;
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
    _currentIndexController.close();
    _playModeController.close();
    _playlistController.close();
  }
}

/// 用于Player Service内部调用的简化API服务接口
/// 避免循环依赖，只取所需方法
class BilibiliApiServiceForPlayer {
  final String Function(String bvid) _getAudioUrl;

  BilibiliApiServiceForPlayer(this._getAudioUrl);

  Future<String?> getAudioUrl(String bvid) async => _getAudioUrl(bvid);
}
