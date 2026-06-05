import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final likeStatusProvider =
    StateNotifierProvider.family<LikeNotifier, bool?, String>((ref, trackId) {
      ref.keepAlive();
      return LikeNotifier(ref, trackId);
    });

class LikeNotifier extends StateNotifier<bool?> {
  final Ref _ref;
  final String _trackId;
  bool _isToggling = false;

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

  Future<bool> toggle() async {
    if (_isToggling) return false;
    _isToggling = true;

    final current = state ?? false;
    final next = !current;
    state = next;

    try {
      final dio = _ref.read(dioProvider);
      if (current) {
        await dio.delete('/tracks/$_trackId/like');
      } else {
        await dio.post('/tracks/$_trackId/like');
      }
      return true;
    } catch (_) {
      if (mounted) state = current;
      return false;
    } finally {
      _isToggling = false;
    }
  }
}

final likesCountProvider = StateProvider.family<int, String>((ref, trackId) {
  ref.keepAlive();
  return -1;
});
