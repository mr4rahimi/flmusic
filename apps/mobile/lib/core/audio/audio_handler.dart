import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

enum RepeatMode { none, one, all }

class AudioQueueItem {
  final String id;
  final String url;
  final String title;
  final String artist;
  final String? artUri;
  final Duration? duration;

  const AudioQueueItem({
    required this.id,
    required this.url,
    required this.title,
    required this.artist,
    this.artUri,
    this.duration,
  });
}

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  List<AudioQueueItem> _queue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.all;

  void Function(int index)? _onIndexChanged;

  MusicAudioHandler() {
    _configureAudioSession();
    _notifyPlaybackEvents();
    _listenForCompletion();
    _listenForDurationChanges();
  }

  // Pattern from audio_service official example: pipe events directly
  void _notifyPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    }, onError: (_, __) {});
  }

  void _listenForCompletion() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleCompleted();
      }
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  void syncQueue(List<AudioQueueItem> items, int startIndex) {
    _queue = List.of(items);
    _currentIndex = startIndex;
  }

  void updateRepeatMode(RepeatMode mode) => _repeatMode = mode;

  void setOnIndexChanged(void Function(int index) callback) {
    _onIndexChanged = callback;
  }

  Future<void> playUrl({
    required int queueIndex,
    required String id,
    required String url,
    required String title,
    required String artist,
    String? artUri,
    Duration? duration,
  }) async {
    _currentIndex = queueIndex;
    mediaItem.add(MediaItem(
      id: id,
      title: title,
      artist: artist,
      artUri: artUri != null ? Uri.tryParse(artUri) : null,
      duration: duration,
    ));
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> _handleCompleted() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    if (_repeatMode == RepeatMode.none && _currentIndex >= _queue.length - 1) {
      return;
    }
    await _skipToIndex((_currentIndex + 1) % _queue.length);
  }

  Future<void> _skipToIndex(int index) async {
    _currentIndex = index;
    final item = _queue[index];
    mediaItem.add(MediaItem(
      id: item.id,
      title: item.title,
      artist: item.artist,
      artUri: item.artUri != null ? Uri.tryParse(item.artUri!) : null,
      duration: item.duration,
    ));
    _onIndexChanged?.call(index);
    await _player.setUrl(item.url);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    await _skipToIndex((_currentIndex + 1) % _queue.length);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = _currentIndex > 0 ? _currentIndex - 1 : _queue.length - 1;
    await _skipToIndex(prev);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    return super.onTaskRemoved();
  }

  AudioPlayer get player => _player;

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) pause();
      else if (event.type == AudioInterruptionType.pause) play();
    });
  }
}
