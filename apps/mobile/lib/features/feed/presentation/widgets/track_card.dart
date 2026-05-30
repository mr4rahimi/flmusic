import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/feed_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/likes/presentation/providers/likes_provider.dart';

class TrackCard extends ConsumerWidget {
  final Track track;
  final VoidCallback? onTap;

  const TrackCard({super.key, required this.track, this.onTap});

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStatus = ref.watch(likeStatusProvider(track.id));
    final isLiked = likeStatus ?? false;
    final isLoading = likeStatus == null;

    final storedCount = ref.watch(likesCountProvider(track.id));
    final displayLikes = storedCount == -1 ? track.likesCount : storedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: track.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: track.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppTheme.surfaceColor),
                        errorWidget: (_, __, ___) => _defaultCover(),
                      )
                    : _defaultCover(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () =>
                        context.push('/profile/${track.user.username}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            track.user.username[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            track.user.username,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(track.createdAt, locale: 'fa'),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (track.genre != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        track.genre!,
                        style: const TextStyle(
                            color: AppTheme.primaryColor, fontSize: 11),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${track.playCount}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                final wasLiked =
                                    ref.read(likeStatusProvider(track.id)) ??
                                        false;
                                final current =
                                    ref.read(likesCountProvider(track.id));
                                final base = current == -1
                                    ? track.likesCount
                                    : current;
                                await ref
                                    .read(likeStatusProvider(track.id)
                                        .notifier)
                                    .toggle();
                                ref
                                    .read(likesCountProvider(track.id)
                                        .notifier)
                                    .state = wasLiked
                                    ? (base > 0 ? base - 1 : 0)
                                    : base + 1;
                              },
                        child: Row(
                          children: [
                            isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppTheme.textSecondary),
                                  )
                                : Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline,
                                    size: 16,
                                    color: isLiked
                                        ? AppTheme.accentColor
                                        : AppTheme.textSecondary,
                                  ),
                            const SizedBox(width: 4),
                            Text(
                              '$displayLikes',
                              style: TextStyle(
                                color: isLiked
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isLiked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${track.commentsCount}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text(
                        _formatDuration(track.duration),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultCover() => Container(
        color: AppTheme.surfaceColor,
        child: const Center(
          child: Icon(Icons.music_note_rounded,
              color: AppTheme.primaryColor, size: 48),
        ),
      );
}
