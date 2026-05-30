import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/player_models.dart';
import '../../../../core/api/api_client.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

final currentTrackProvider = StateProvider<PlayerTrack?>((ref) => null);
final queueProvider = StateProvider<List<PlayerTrack>>((ref) => []);
final currentIndexProvider = StateProvider<int>((ref) => 0);
final repeatModeProvider = StateProvider<RepeatMode>((ref) => RepeatMode.all);

final playerActionsProvider = Provider<PlayerActions>((ref) {
  return PlayerActions(ref);
});

class PlayerActions {
  final Ref _ref;
  PlayerActions(this._ref) {
    _setupCompletionListener();
  }

  void _setupCompletionListener() {
    final player = _ref.read(audioPlayerProvider);
    player.onPlayerComplete.listen((_) {
      final repeat = _ref.read(repeatModeProvider);
      switch (repeat) {
        case RepeatMode.one:
          _replay();
        case RepeatMode.all:
        case RepeatMode.none:
          _playNext(fromCompletion: true);
      }
    });
  }

  Future<void> _replay() async {
    final player = _ref.read(audioPlayerProvider);
    await player.seek(Duration.zero);
    await player.resume();
  }

  Future<void> setQueue(List<PlayerTrack> tracks, int startIndex) async {
    _ref.read(queueProvider.notifier).state = tracks;
    _ref.read(currentIndexProvider.notifier).state = startIndex;
    await playTrack(tracks[startIndex]);
  }

  Future<void> playTrack(PlayerTrack track) async {
    final player = _ref.read(audioPlayerProvider);
    _ref.read(currentTrackProvider.notifier).state = track;

    if (track.audioUrl == null) return;

    final base = baseUrl.replaceAll('/api/v1', '');
    final audioUrl = track.audioUrl!;
    final url = audioUrl.startsWith('http') ? audioUrl : '$base/$audioUrl';

    try {
      await player.play(UrlSource(url));
    } catch (_) {}

    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/tracks/${track.id}/play').catchError((_) {});
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    final player = _ref.read(audioPlayerProvider);
    if (player.state == PlayerState.playing) {
      await player.pause();
    } else {
      await player.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _ref.read(audioPlayerProvider).seek(position);
  }

  Future<void> _playNext({bool fromCompletion = false}) async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) return;

    final currentIndex = _ref.read(currentIndexProvider);
    final repeatMode = _ref.read(repeatModeProvider);

    if (fromCompletion && repeatMode == RepeatMode.none &&
        currentIndex >= queue.length - 1) {
      return; // آخرین آهنگ بود و repeat خاموشه
    }

    final nextIndex = (currentIndex + 1) % queue.length;
    _ref.read(currentIndexProvider.notifier).state = nextIndex;
    await playTrack(queue[nextIndex]);
  }

  Future<void> playNext() async {
    await _playNext();
  }

  Future<void> playPrevious() async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) return;

    final player = _ref.read(audioPlayerProvider);
    final position = await player.getCurrentPosition();

    // اگه بیشتر از ۳ ثانیه گذشته، از اول پخش کن
    if (position != null && position.inSeconds > 3) {
      await player.seek(Duration.zero);
      return;
    }

    final currentIndex = _ref.read(currentIndexProvider);
    final prevIndex =
        currentIndex > 0 ? currentIndex - 1 : queue.length - 1;
    _ref.read(currentIndexProvider.notifier).state = prevIndex;
    await playTrack(queue[prevIndex]);
  }

  void cycleRepeatMode() {
    final current = _ref.read(repeatModeProvider);
    final next = switch (current) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.none,
    };
    _ref.read(repeatModeProvider.notifier).state = next;
  }
}
