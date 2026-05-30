import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final likeStatusProvider =
    StateNotifierProvider.family<LikeNotifier, bool?, String>((ref, trackId) {
  return LikeNotifier(ref, trackId);
});

class LikeNotifier extends StateNotifier<bool?> {
  final Ref _ref;
  final String _trackId;

  LikeNotifier(this._ref, this._trackId) : super(null) {
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/tracks/$_trackId/liked');
      if (mounted) state = response.data == true;
    } catch (_) {
      if (mounted) state = false;
    }
  }

  Future<void> toggle() async {
    final current = state ?? false;
    state = !current;
    try {
      final dio = _ref.read(dioProvider);
      if (current) {
        await dio.delete('/tracks/$_trackId/like');
      } else {
        await dio.post('/tracks/$_trackId/like');
      }
    } catch (_) {
      state = current;
    }
  }
}

final likesCountProvider =
    StateProvider.family<int, String>((ref, trackId) => -1);
