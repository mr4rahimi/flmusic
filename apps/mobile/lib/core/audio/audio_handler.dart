import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

export 'package:just_audio/just_audio.dart' show ProcessingState;

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

/// این کلاس باید حتماً BaseAudioHandler رو extend کنه.
/// audio_service از روی همین، MediaSession سیستمی می‌سازه که
/// نوتیفیکیشن + کنترل‌های لاک‌اسکرین + دکمه‌های هدفون رو راه می‌اندازه.
class MusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  List<AudioQueueItem> _queue = [];
  void Function(int index)? _onIndexChanged;

  MusicAudioHandler() {
    _configureAudioSession();
    _player.setLoopMode(LoopMode.all);

    // هر تغییری در وضعیت پخش -> به سیستم اعلام کن (نوتیف/لاک‌اسکرین از این تغذیه می‌شه)
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        playbackState.add(
          playbackState.value.copyWith(processingState: AudioProcessingState.error),
        );
      },
    );

    // وقتی just_audio خودش به ترک بعدی می‌ره
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      final items = queue.value;
      if (index >= 0 && index < items.length) {
        mediaItem.add(items[index]);
      }
      _onIndexChanged?.call(index);
    });
  }

  AudioPlayer get player => _player;

  void setOnIndexChanged(void Function(int index) callback) {
    _onIndexChanged = callback;
  }

  void updateRepeatMode(RepeatMode mode) {
    _player.setLoopMode(switch (mode) {
      RepeatMode.none => LoopMode.off,
      RepeatMode.one => LoopMode.one,
      RepeatMode.all => LoopMode.all,
    });
  }

  // ── وضعیت را به سیستم عامل broadcast کن ────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        // این سه تا در حالت جمع‌شده‌ی نوتیف نشان داده می‌شوند
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
        queueIndex: event.currentIndex,
      ),
    );
  }

  MediaItem _toMediaItem(AudioQueueItem item) => MediaItem(
        id: item.id,
        title: item.title,
        artist: item.artist,
        duration: item.duration,
        artUri: (item.artUri != null && item.artUri!.isNotEmpty)
            ? Uri.tryParse(item.artUri!)
            : null,
      );

  // ── مدیریت صف ──────────────────────────────────────────────────────────

  Future<void> syncQueue(List<AudioQueueItem> items, int startIndex) async {
    if (items.isEmpty) return;

    _queue = List.of(items);
    final mediaItems = items.map(_toMediaItem).toList();

    // صف را به audio_service بده (لاک‌اسکرین از این عنوان/آرت‌ورک می‌خواند)
    queue.add(mediaItems);

    final safeIndex = startIndex.clamp(0, mediaItems.length - 1);
    mediaItem.add(mediaItems[safeIndex]);

    final sources = items
        .map((i) => AudioSource.uri(Uri.parse(i.url), tag: _toMediaItem(i)))
        .toList();

    await _player.setAudioSources(
      sources,
      initialIndex: safeIndex,
      initialPosition: Duration.zero,
    );
  }

  /// امضای قبلی حفظ شده تا player_provider تغییر نکند.
  Future<void> playUrl({
    required int queueIndex,
    required String id,
    required String url,
    required String title,
    required String artist,
    String? artUri,
    Duration? duration,
  }) async {
    // اگر ترک خارج از صف فعلی است، صف را با همان یک ترک بساز
    if (queueIndex < 0 || queueIndex >= _queue.length || _queue[queueIndex].id != id) {
      await syncQueue([
        AudioQueueItem(
          id: id,
          url: url,
          title: title,
          artist: artist,
          artUri: artUri,
          duration: duration,
        )
      ], 0);
    } else if (_player.currentIndex != queueIndex) {
      await _player.seek(Duration.zero, index: queueIndex);
      mediaItem.add(queue.value[queueIndex]);
    }

    await _player.play();
  }

  // ── override های BaseAudioHandler (نوتیف/لاک‌اسکرین اینها را صدا می‌زنند) ──

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(queue.value[index]);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (queue.value.isNotEmpty) {
      await skipToQueueItem(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (queue.value.isNotEmpty) {
      await skipToQueueItem(queue.value.length - 1);
    }
  }

  // ── audio session ──────────────────────────────────────────────────────

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _player.pause();
      } else if (event.type == AudioInterruptionType.pause) {
        _player.play();
      }
    });
  }
}