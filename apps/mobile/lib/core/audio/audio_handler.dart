import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  void Function()? _onSkipNext;
  void Function()? _onSkipPrevious;

  MusicAudioHandler() {
    _configureAudioSession();
    _player.playbackEventStream.listen((_) => _broadcastState(), onError: (_, __) {});
    _player.playerStateStream.listen((_) => _broadcastState());
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        pause();
      } else if (event.type == AudioInterruptionType.pause) {
        play();
      }
    });
  }

  void setSkipCallbacks({
    required void Function() onNext,
    required void Function() onPrevious,
  }) {
    _onSkipNext = onNext;
    _onSkipPrevious = onPrevious;
  }

  Future<void> playUrl({
    required String id,
    required String url,
    required String title,
    required String artist,
    String? artUri,
    Duration? duration,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      artUri: artUri != null ? Uri.tryParse(artUri) : null,
      duration: duration,
    );
    mediaItem.add(item);
    await _player.setUrl(url);
    await _player.play();
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
  Future<void> skipToNext() async => _onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => _onSkipPrevious?.call();

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    return super.onTaskRemoved();
  }

  AudioPlayer get player => _player;

  void _broadcastState() {
    final playing = _player.playing;
    final processingState = _mapProcessingState(_player.processingState);

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }
}
