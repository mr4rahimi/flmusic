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

class MusicAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  List<AudioQueueItem> _queue = [];
  int _currentIndex = 0;
  bool _playlistSet = false;

  void Function(int index)? _onIndexChanged;

  MusicAudioHandler() {
    _configureAudioSession();
    _player.setLoopMode(LoopMode.all);

    // Notify UI when just_audio auto-advances (ConcatenatingAudioSource)
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        _onIndexChanged?.call(index);
      }
    });
  }

  AudioPlayer get player => _player;

  void setOnIndexChanged(void Function(int index) callback) {
    _onIndexChanged = callback;
  }

  void updateRepeatMode(RepeatMode mode) {
    _player.setLoopMode(switch (mode) {
      RepeatMode.none => LoopMode.off,
      RepeatMode.one  => LoopMode.one,
      RepeatMode.all  => LoopMode.all,
    });
  }

  Future<void> syncQueue(List<AudioQueueItem> items, int startIndex) async {
    _queue = List.of(items);
    _currentIndex = startIndex;
    _playlistSet = false;

    // Map tags: just_audio 0.10.x passes these to media3 MediaMetadata
    // which powers the system notification title/artist/artwork
    final sources = items.map((item) => AudioSource.uri(
      Uri.parse(item.url),
      tag: {
        'id': item.id,
        'title': item.title,
        'artist': item.artist,
        'artUri': item.artUri,
        'duration': item.duration?.inMilliseconds,
      },
    )).toList();

    await _playlist.clear();
    await _playlist.addAll(sources);
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
    if (!_playlistSet) {
      _playlistSet = true;
      await _player.setAudioSource(_playlist, initialIndex: queueIndex);
    } else {
      await _player.seek(Duration.zero, index: queueIndex);
    }
    await _player.play();
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_playlist.length > 0) {
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_playlist.length > 0) {
      await _player.seek(Duration.zero, index: _playlist.length - 1);
      await _player.play();
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) pause();
      else if (event.type == AudioInterruptionType.pause) play();
    });
  }
}
