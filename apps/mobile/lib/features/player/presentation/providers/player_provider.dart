import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
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

    final url = '${baseUrl.replaceAll('/api/v1', '')}/${track.audioUrl}';
    await player.setUrl(url);
    await player.play();

    // increment play count
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/tracks/${track.id}/play').catchError((_) {});
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    final player = _ref.read(audioPlayerProvider);
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _ref.read(audioPlayerProvider).seek(position);
  }
}
