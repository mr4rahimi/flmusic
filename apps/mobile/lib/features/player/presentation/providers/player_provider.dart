import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/player_models.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/audio/audio_handler.dart';

// ── State ──────────────────────────────────────────────────────────────────

final currentTrackProvider = StateProvider<PlayerTrack?>((ref) => null);
final queueProvider        = StateProvider<List<PlayerTrack>>((ref) => []);
final currentIndexProvider = StateProvider<int>((ref) => 0);
final repeatModeProvider   = StateProvider<RepeatMode>((ref) => RepeatMode.all);
final isPlayingProvider    = StateProvider<bool>((ref) => false);
final isLoadingProvider    = StateProvider<bool>((ref) => false);

// ── AudioHandler provider — overridden with real instance in main.dart ─────

final audioHandlerProvider = Provider<MusicAudioHandler>(
  (ref) => throw UnimplementedError('Override audioHandlerProvider in main'),
);

// ── Controller ─────────────────────────────────────────────────────────────

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

  MusicAudioHandler get _handler => _ref.read(audioHandlerProvider);

  void _init() {
    final sub = player.playerStateStream.listen((state) {
      final ps = state.processingState;

      _ref.read(isPlayingProvider.notifier).state =
          state.playing && ps != ProcessingState.completed;

      _ref.read(isLoadingProvider.notifier).state =
          ps == ProcessingState.loading ||
          (ps == ProcessingState.buffering && !state.playing);
    });

    // When handler auto-advances (notification/lock screen/auto-next),
    // sync UI state without calling playUrl again
    _handler.setOnIndexChanged((index) {
      final queue = _ref.read(queueProvider);
      if (index >= 0 && index < queue.length) {
        _ref.read(currentIndexProvider.notifier).state = index;
        _ref.read(currentTrackProvider.notifier).state = queue[index];
        _postPlayCount(queue[index].id);
      }
    });

    _disposers.add(sub.cancel);
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }

  String? _lastCountedId;
  DateTime? _lastCountedAt;

  Future<void> _postPlayCount(String trackId) async {
    final now = DateTime.now();
    if (_lastCountedId == trackId &&
        _lastCountedAt != null &&
        now.difference(_lastCountedAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastCountedId = trackId;
    _lastCountedAt = now;
    try {
      await _ref.read(dioProvider).post('/tracks/$trackId/play');
    } catch (_) {}
  }

  Future<void> setQueue(List<PlayerTrack> tracks, int startIndex) async {
    _ref.read(queueProvider.notifier).state = tracks;
    _ref.read(currentIndexProvider.notifier).state = startIndex;

    // Sync full queue to handler so notification/lock screen next/prev works
    final base = baseUrl.replaceAll('/api/v1', '');
    final audioItems = tracks.map((t) {
      final rawUrl = t.audioUrl ?? '';
      final url = rawUrl.startsWith('http') ? rawUrl : '$base/$rawUrl';
      String? artUri;
      if (t.coverUrl != null) {
        final c = t.coverUrl!;
        artUri = c.startsWith('http') ? c : '$base/$c';
      }
      return AudioQueueItem(
        id: t.id,
        url: url,
        title: t.title,
        artist: t.username,
        artUri: artUri,
        duration: t.duration != null ? Duration(seconds: t.duration!) : null,
      );
    }).toList();
    await _handler.syncQueue(audioItems, startIndex);

    await _playTrack(tracks[startIndex]);
  }

  Future<void> _playTrack(PlayerTrack track) async {
    if (track.audioUrl == null) return;

    final queueIndex = _ref.read(currentIndexProvider);
    _ref.read(currentTrackProvider.notifier).state = track;

    final base = baseUrl.replaceAll('/api/v1', '');
    final audioUrl = track.audioUrl!;
    final url = audioUrl.startsWith('http') ? audioUrl : '$base/$audioUrl';

    String? artUri;
    if (track.coverUrl != null) {
      final c = track.coverUrl!;
      artUri = c.startsWith('http') ? c : '$base/$c';
    }

    try {
      await _handler.playUrl(
        queueIndex: queueIndex,
        id: track.id,
        url: url,
        title: track.title,
        artist: track.username,
        artUri: artUri,
        duration: track.duration != null ? Duration(seconds: track.duration!) : null,
      );
      await _postPlayCount(track.id);
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    final isPlaying = _ref.read(isPlayingProvider);
    if (isPlaying) {
      await _handler.pause();
    } else {
      final p = _handler.player.processingState;
      if (p == ProcessingState.ready || p == ProcessingState.buffering) {
        await _handler.play();
      } else {
        final track = _ref.read(currentTrackProvider);
        if (track != null) await _playTrack(track);
      }
    }
  }

  Future<void> seek(Duration position) => _handler.seek(position);

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
    if (_handler.player.position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
      return;
    }
    final index = _ref.read(currentIndexProvider);
    final prev = index > 0 ? index - 1 : queue.length - 1;
    _ref.read(currentIndexProvider.notifier).state = prev;
    await _playTrack(queue[prev]);
  }

  void cycleRepeatMode() {
    final current = _ref.read(repeatModeProvider);
    final next = switch (current) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all  => RepeatMode.one,
      RepeatMode.one  => RepeatMode.none,
    };
    _ref.read(repeatModeProvider.notifier).state = next;
    _handler.updateRepeatMode(next);
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
