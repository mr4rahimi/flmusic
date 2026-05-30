import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/comment_models.dart';
import '../../../../core/api/api_client.dart';

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final Ref _ref;
  final String _trackId;

  CommentsNotifier(this._ref, this._trackId)
      : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    try {
      state = const AsyncValue.loading();
      final dio = _ref.read(dioProvider);
      final response = await dio.get(
        '/tracks/$_trackId/comments',
        queryParameters: {'limit': 50},
      );
      final result = CommentsResponse.fromJson(response.data);
      state = AsyncValue.data(result.data);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<bool> addComment(String content) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        '/tracks/$_trackId/comments',
        data: {'content': content},
      );
      final newComment = Comment.fromJson(response.data);
      final current = state.value ?? [];
      state = AsyncValue.data([newComment, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/tracks/$_trackId/comments/$commentId');
      final current = state.value ?? [];
      state = AsyncValue.data(
          current.where((c) => c.id != commentId).toList());
    } catch (_) {}
  }
}

final commentsProvider = StateNotifierProvider.family<CommentsNotifier,
    AsyncValue<List<Comment>>, String>(
  (ref, trackId) => CommentsNotifier(ref, trackId),
);
