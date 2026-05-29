import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notifications_provider.dart';
import '../../data/notification_models.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اعلان‌ها'),
        actions: [
          notifAsync.when(
            data: (data) => data.unreadCount > 0
                ? TextButton(
                    onPressed: () => ref
                        .read(notificationsActionsProvider)
                        .markAllAsRead(),
                    child: const Text(
                      'همه خوانده شد',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('خطا در بارگذاری اعلان‌ها'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
        data: (data) => data.data.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: AppTheme.textSecondary, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'اعلانی نداری',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  itemCount: data.data.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppTheme.surfaceColor,
                    height: 1,
                  ),
                  itemBuilder: (_, i) => _NotificationItem(
                    notif: data.data[i],
                    onTap: () {
                      if (!data.data[i].isRead) {
                        ref
                            .read(notificationsActionsProvider)
                            .markOneAsRead(data.data[i].id);
                      }
                      // navigate به profile
                      context.push(
                          '/profile/${data.data[i].actor.username}');
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotificationItem({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.type) {
      case 'follow':
        return Icons.person_add_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'repost':
        return Icons.repeat_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case 'follow':
        return AppTheme.primaryColor;
      case 'like':
        return AppTheme.accentColor;
      case 'comment':
        return Colors.amber;
      case 'repost':
        return Colors.greenAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _message {
    switch (notif.type) {
      case 'follow':
        return 'شما را دنبال کرد';
      case 'like':
        return 'آهنگ شما را لایک کرد';
      case 'comment':
        return 'روی آهنگ شما نظر گذاشت';
      case 'repost':
        return 'آهنگ شما را ریپست کرد';
      default:
        return 'یک اعلان جدید دارید';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : AppTheme.primaryColor.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Actor Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.surfaceColor,
                  child: Text(
                    notif.actor.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.backgroundColor, width: 1.5),
                    ),
                    child: Icon(_icon, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notif.actor.username,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: _message,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notif.createdAt, locale: 'fa'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
