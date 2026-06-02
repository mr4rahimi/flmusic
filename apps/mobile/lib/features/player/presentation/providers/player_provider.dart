import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/player_models.dart';
import '../../../../core/api/api_client.dart';

// ── State ──────────────────────────────────────────────────────────────────

final currentTrackProvider = StateProvider<PlayerTrack?>((ref) => null);
final queueProvider        = StateProvider<List<PlayerTrack>>((ref) => []);
final currentIndexProvider = StateProvider<int>((ref) => 0);
final repeatModeProvider   = StateProvider<RepeatMode>((ref) => RepeatMode.all);
final isPlayingProvider    = StateProvider<bool>((ref) => false);
final isLoadingProvider    = StateProvider<bool>((ref) => false);

// ── Single AudioPlayer instance ────────────────────────────────────────────

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

// ── Controller ────────────────────────────────────────────────────────────

final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class PlayerController {
  final Ref _ref;
  final List<void Function()> _disposers = [];

  PlayerController(this._ref) {
    _init();
  }

  void _init() {
    final player = _ref.read(audioPlayerProvider);

    // sync isPlaying با state واقعی player
    final s1 = player.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;
      _ref.read(isPlayingProvider.notifier).state = isPlaying;
      if (state == PlayerState.playing || state == PlayerState.paused) {
        _ref.read(isLoadingProvider.notifier).state = false;
      }
    });

    // auto next on complete
    final s2 = player.onPlayerComplete.listen((_) {
      _ref.read(isPlayingProvider.notifier).state = false;
      final repeat = _ref.read(repeatModeProvider);
      if (repeat == RepeatMode.one) {
        _replay();
      } else {
        _autoNext();
      }
    });

    _disposers.add(s1.cancel);
    _disposers.add(s2.cancel);
  }

  void dispose() {
    for (final d in _disposers) d();
  }

  Future<void> _replay() async {
    final player = _ref.read(audioPlayerProvider);
    await player.seek(Duration.zero);
    await player.resume();
  }

  Future<void> _autoNext() async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) return;
    final index = _ref.read(currentIndexProvider);
    final repeat = _ref.read(repeatModeProvider);
    if (repeat == RepeatMode.none && index >= queue.length - 1) return;
    final next = (index + 1) % queue.length;
    _ref.read(currentIndexProvider.notifier).state = next;
    await _playTrack(queue[next]);
  }

  Future<void> setQueue(List<PlayerTrack> tracks, int startIndex) async {
    _ref.read(queueProvider.notifier).state = tracks;
    _ref.read(currentIndexProvider.notifier).state = startIndex;
    await _playTrack(tracks[startIndex]);
  }

  Future<void> _playTrack(PlayerTrack track) async {
    if (track.audioUrl == null) return;

    _ref.read(currentTrackProvider.notifier).state = track;
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(isPlayingProvider.notifier).state = false;

    final player = _ref.read(audioPlayerProvider);
    await player.stop();

    final base = baseUrl.replaceAll('/api/v1', '');
    final audioUrl = track.audioUrl!;
    final url = audioUrl.startsWith('http') ? audioUrl : '$base/$audioUrl';

    try {
      await player.play(UrlSource(url));
      // play count
      try {
        final dio = _ref.read(dioProvider);
        await dio.post('/tracks/${track.id}/play').catchError((_) {});
      } catch (_) {}
    } catch (e) {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> togglePlayPause() async {
    final player = _ref.read(audioPlayerProvider);
    final isPlaying = _ref.read(isPlayingProvider);

    if (isPlaying) {
      await player.pause();
    } else {
      final state = player.state;
      if (state == PlayerState.paused) {
        await player.resume();
      } else {
        // اگه track انتخاب شده ولی player هنوز شروع نکرده
        final track = _ref.read(currentTrackProvider);
        if (track != null) await _playTrack(track);
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _ref.read(audioPlayerProvider).seek(position);
  }

  Future<void> playNext() async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) return;
    final index = _ref.read(currentIndexProvider);
    final next = (index + 1) % queue.length;
    _ref.read(currentIndexProvider.notifier).state = next;
    await _playTrack(queue[next]);
  }

  Future<void> playPrevious() async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) return;

    final player = _ref.read(audioPlayerProvider);
    final position = await player.getCurrentPosition();
    if (position != null && position.inSeconds > 3) {
      await player.seek(Duration.zero);
      return;
    }

    final index = _ref.read(currentIndexProvider);
    final prev = index > 0 ? index - 1 : queue.length - 1;
    _ref.read(currentIndexProvider.notifier).state = prev;
    await _playTrack(queue[prev]);
  }

  void cycleRepeatMode() {
    final current = _ref.read(repeatModeProvider);
    _ref.read(repeatModeProvider.notifier).state = switch (current) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all  => RepeatMode.one,
      RepeatMode.one  => RepeatMode.none,
    };
  }
}

// ── backward compat aliases ────────────────────────────────────────────────

final playerActionsProvider = Provider<_Compat>((ref) => _Compat(ref));

class _Compat {
  final Ref _ref;
  _Compat(this._ref);
  PlayerController get _c => _ref.read(playerControllerProvider);
  Future<void> setQueue(List<PlayerTrack> t, int i) => _c.setQueue(t, i);
  Future<void> togglePlayPause() => _c.togglePlayPause();
  Future<void> seek(Duration d) => _c.seek(d);
  Future<void> playNext() => _c.playNext();
  Future<void> playPrevious() => _c.playPrevious();
  Future<void> playTrack(PlayerTrack t) => _c._playTrack(t);
  void cycleRepeatMode() => _c.cycleRepeatMode();
}
