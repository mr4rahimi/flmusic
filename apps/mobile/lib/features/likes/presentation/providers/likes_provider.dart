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
  bool _isToggling = false;  // ← این خط اضافه شه

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
    if (_isToggling) return;  // ← اگه در حال toggle هست، ignore کن
    _isToggling = true;

    final current = state ?? false;
    state = !current;  // optimistic update

    try {
      final dio = _ref.read(dioProvider);
      if (current) {
        await dio.delete('/tracks/$_trackId/like');
      } else {
        await dio.post('/tracks/$_trackId/like');
      }
    } catch (_) {
      if (mounted) state = current;  // revert
    } finally {
      _isToggling = false;  // ← آزاد کن
    }
  }
}

final likesCountProvider =
    StateProvider.family<int, String>((ref, trackId) {
  ref.keepAlive();
  return -1;
});
