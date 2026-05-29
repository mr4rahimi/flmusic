import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_models.dart';
import '../../../../core/api/api_client.dart';

final notificationsProvider =
    FutureProvider<NotificationsResponse>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/notifications', queryParameters: {'limit': 30});
  return NotificationsResponse.fromJson(response.data);
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/notifications/unread-count');
  return response.data as int;
});

class NotificationsActions {
  final Ref _ref;
  NotificationsActions(this._ref);

  Future<void> markAllAsRead() async {
    final dio = _ref.read(dioProvider);
    await dio.patch('/notifications/read-all');
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<void> markOneAsRead(String id) async {
    final dio = _ref.read(dioProvider);
    await dio.patch('/notifications/$id/read');
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadCountProvider);
  }
}

final notificationsActionsProvider = Provider<NotificationsActions>((ref) {
  return NotificationsActions(ref);
});
