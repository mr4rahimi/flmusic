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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08);

    final likeStatus = ref.watch(likeStatusProvider(track.id));
    final isLiked = likeStatus ?? false;
    final isLoadingLike = likeStatus == null;
    final storedCount = ref.watch(likesCountProvider(track.id));
    final displayLikes = storedCount == -1 ? track.likesCount : storedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: track.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _coverPlaceholder(isDark),
                            errorWidget: (_, __, ___) =>
                                _coverPlaceholder(isDark),
                          )
                        : _coverPlaceholder(isDark),
                  ),
                ),

                // Duration badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(track.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ),

                // Play button overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        splashColor: AppColors.primary.withOpacity(0.2),
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 1.5),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist row
                  GestureDetector(
                    onTap: () =>
                        context.push('/profile/${track.user.username}'),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              track.user.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            track.user.username,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(track.createdAt, locale: 'fa'),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    track.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Vazirmatn',
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Bottom row — genre + stats
                  Row(
                    children: [
                      // Genre tag
                      if (track.genre != null && track.genre!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                                isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            track.genre!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Play count
                      _StatChip(
                        icon: Icons.play_circle_outline_rounded,
                        value: '${track.playCount}',
                        color: textSecondary,
                      ),
                      const SizedBox(width: 12),

                      // Like button
                      GestureDetector(
                        onTap: isLoadingLike
                            ? null
                            : () async {
                                final wasLiked =
                                    ref.read(likeStatusProvider(track.id)) ??
                                        false;
                                final current =
                                    ref.read(likesCountProvider(track.id));
                                final base =
                                    current == -1 ? track.likesCount : current;
                                await ref
                                    .read(likeStatusProvider(track.id).notifier)
                                    .toggle();
                                ref
                                    .read(likesCountProvider(track.id).notifier)
                                    .state = wasLiked
                                    ? (base > 0 ? base - 1 : 0)
                                    : base + 1;
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? AppColors.accent.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              isLoadingLike
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: textSecondary,
                                      ),
                                    )
                                  : AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                              scale: anim, child: child),
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_outline_rounded,
                                        key: ValueKey(isLiked),
                                        size: 15,
                                        color: isLiked
                                            ? AppColors.accent
                                            : textSecondary,
                                      ),
                                    ),
                              const SizedBox(width: 4),
                              Text(
                                '$displayLikes',
                                style: TextStyle(
                                  color: isLiked
                                      ? AppColors.accent
                                      : textSecondary,
                                  fontSize: 12,
                                  fontWeight: isLiked
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Comment count
                      _StatChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        value: '${track.commentsCount}',
                        color: textSecondary,
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

  Widget _coverPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              color: AppColors.primary.withOpacity(0.5),
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}
