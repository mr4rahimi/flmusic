class NotificationActor {
  final String id;
  final String username;
  final String? avatarUrl;
  final String verifiedStatus;

  NotificationActor({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.verifiedStatus,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) =>
      NotificationActor(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        avatarUrl: json['avatarUrl'],
        verifiedStatus: json['verifiedStatus'] ?? 'none',
      );
}

class AppNotification {
  final String id;
  final String type;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;
  final NotificationActor actor;

  AppNotification({
    required this.id,
    required this.type,
    this.entityId,
    required this.isRead,
    required this.createdAt,
    required this.actor,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        entityId: json['entityId'],
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        actor: NotificationActor.fromJson(json['actor']),
      );
}

class NotificationsResponse {
  final List<AppNotification> data;
  final int total;
  final int unreadCount;

  NotificationsResponse({
    required this.data,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsResponse(
        data: (json['data'] as List)
            .map((e) => AppNotification.fromJson(e))
            .toList(),
        total: json['total'] ?? 0,
        unreadCount: json['unreadCount'] ?? 0,
      );
}
