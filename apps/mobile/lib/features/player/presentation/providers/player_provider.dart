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

final playerActionsProvider = Provider<PlayerActions>((ref) {
  return PlayerActions(ref);
});

class PlayerActions {
  final Ref _ref;
  PlayerActions(this._ref);

  Future<void> playTrack(PlayerTrack track) async {
    final player = _ref.read(audioPlayerProvider);
    _ref.read(currentTrackProvider.notifier).state = track;

    if (track.audioUrl == null) return;

    final base = baseUrl.replaceAll('/api/v1', '');
    final audioUrl = track.audioUrl!;
    final url = audioUrl.startsWith('http') ? audioUrl : '$base/$audioUrl';

    try {
      await player.play(UrlSource(url));
    } catch (e) {
      // ignore
    }

    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/tracks/${track.id}/play').catchError((_) {});
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    final player = _ref.read(audioPlayerProvider);
    final state = player.state;
    if (state == PlayerState.playing) {
      await player.pause();
    } else {
      await player.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _ref.read(audioPlayerProvider).seek(position);
  }
}
