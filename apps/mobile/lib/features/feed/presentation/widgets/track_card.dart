import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';
import '../../data/feed_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/likes/presentation/providers/likes_provider.dart';
import '../../../../features/comments/presentation/screens/comments_screen.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/playlists/presentation/widgets/save_to_playlist_sheet.dart';

// ── gradient palettes برای cover بدون عکس ──────────────────
const _palettes = [
  [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFF312E81)],
  [Color(0xFFFB7185), Color(0xFFF59E0B), Color(0xFF7F1D3A)],
  [Color(0xFF14B8A6), Color(0xFF22D3EE), Color(0xFF0F4C5C)],
  [Color(0xFFF472B6), Color(0xFF8B5CF6), Color(0xFF581C87)],
  [Color(0xFF34D399), Color(0xFFA3E635), Color(0xFF14532D)],
  [Color(0xFF60A5FA), Color(0xFF6366F1), Color(0xFF1E3A8A)],
  [Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFF7C2D12)],
  [Color(0xFFF43F5E), Color(0xFFEC4899), Color(0xFF831843)],
];

List<Color> _paletteFor(String id) {
  final hash = id.codeUnits.fold(0, (a, b) => a + b);
  return _palettes[hash % _palettes.length];
}

class TrackCard extends ConsumerStatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final bool isCurrent;
  final bool isPlaying;

  const TrackCard({
    super.key,
    required this.track,
    this.onTap,
    this.isCurrent = false,
    this.isPlaying = false,
  });

  @override
  ConsumerState<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends ConsumerState<TrackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = widget.track;

    final likeStatus = ref.watch(likeStatusProvider(track.id));
    final isLiked = likeStatus ?? false;
    final storedCount = ref.watch(likesCountProvider(track.id));
    final displayLikes = storedCount == -1 ? track.likesCount : storedCount;

    final colors = _paletteFor(track.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover ───────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // عکس یا gradient
                  _CoverBackground(track: track, colors: colors),

                  // scrim
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x28000000),
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x55000000),
                        ],
                        stops: [0, 0.25, 0.65, 1],
                      ),
                    ),
                  ),

                  // genre chip — بالا راست
                  if (track.genre != null && track.genre!.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _Chip(label: track.genre!),
                    ),

                  // duration chip — پایین چپ
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _Chip(label: _formatDuration(track.duration)),
                  ),

                  // دکمه play — وسط
                  Center(
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: _PlayBtn(
                        isPlaying: widget.isCurrent && widget.isPlaying,
                      ),
                    ),
                  ),

                  // double-tap like
                  //              Positioned.fill(
                  //                child: GestureDetector(
                  //                  onDoubleTap: () {
                  //                    if (!isLiked) {
                  //                      _triggerLike(ref, track, isLiked, storedCount);
                  //                      _likeCtrl.forward(from: 0);
                  //                    }
                  //                  },
                  //                  child: Container(color: Colors.transparent),
                  //                ),
                  //              ),
                  //
                  // burst heart
                  AnimatedBuilder(
                    animation: _likeCtrl,
                    builder: (_, __) {
                      final v = _likeCtrl.value;
                      final opacity = v < 0.35
                          ? v / 0.35
                          : v < 0.7
                          ? 0.95
                          : 1 - (v - 0.7) / 0.3;
                      final scale = v < 0.35
                          ? 0.2 + v / 0.35 * 0.85
                          : v < 0.7
                          ? 1.05
                          : 0.95 + (v - 0.7) / 0.3 * 0.3;
                      if (v == 0) return const SizedBox.shrink();
                      return Center(
                        child: Opacity(
                          opacity: opacity.clamp(0, 1),
                          child: Transform.scale(
                            scale: scale,
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 86,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // avatar + نام + تاریخ + follow + more
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.push('/profile/${track.user.username}'),
                      child: _Avatar(username: track.user.username),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            context.push('/profile/${track.user.username}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.user.username,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeago.format(track.createdAt, locale: 'fa'),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Follow btn
                    _FollowBtn(username: track.user.username),
                    const SizedBox(width: 6),
                    // More
                    _GhostBtn(icon: Icons.more_horiz_rounded, onTap: () {}),
                  ],
                ),

                // title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    track.title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.3,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // actions
                Row(
                  children: [
                    // like
                    _ActBtn(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      label: '$displayLikes',
                      active: isLiked,
                      activeColor: AppColors.primary,
                      onTap: () =>
                          _triggerLike(ref, track, isLiked, storedCount),
                    ),
                    const SizedBox(width: 18),
                    // comment
                    _ActBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${track.commentsCount}',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CommentsScreen(
                          trackId: track.id,
                          trackTitle: track.title,
                          commentsCount: track.commentsCount,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // plays
                    _ActBtn(
                      icon: Icons.headphones_rounded,
                      label: '${track.playCount}',
                      onTap: () {},
                    ),
                    const Spacer(),
                    // bookmark
                    _GhostBtn(
                      icon: Icons.bookmark_add_outlined,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SaveToPlaylistSheet(
                          trackId: track.id,
                          trackTitle: track.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // share
                    _GhostBtn(icon: Icons.ios_share_rounded, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _triggerLike(
    WidgetRef ref,
    Track track,
    bool isLiked,
    int storedCount,
  ) async {
    final base = storedCount == -1 ? track.likesCount : storedCount;
    final success = await ref
        .read(likeStatusProvider(track.id).notifier)
        .toggle();
    if (!success) return;

    ref.read(likesCountProvider(track.id).notifier).state = isLiked
        ? (base > 0 ? base - 1 : 0)
        : base + 1;
  }
}

// ── Cover Background ─────────────────────────────────────────
class _CoverBackground extends StatelessWidget {
  final Track track;
  final List<Color> colors;
  const _CoverBackground({required this.track, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (track.coverUrl != null) {
      final base = 'http://185.164.73.224';
      final url = track.coverUrl!.startsWith('http')
          ? track.coverUrl!
          : '$base/${track.coverUrl}';
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => _GradientCover(colors: colors),
        errorWidget: (_, __, ___) => _GradientCover(colors: colors),
      );
    }
    return _GradientCover(colors: colors);
  }
}

class _GradientCover extends StatelessWidget {
  final List<Color> colors;
  const _GradientCover({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0], colors[1], colors[2]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 64,
        ),
      ),
    );
  }
}

// ── Chip ─────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Play Button ───────────────────────────────────────────────
class _PlayBtn extends StatelessWidget {
  final bool isPlaying;
  const _PlayBtn({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPlaying
            ? AppColors.primary.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 24,
          ),
        ],
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String username;
  const _Avatar({required this.username});

  @override
  Widget build(BuildContext context) {
    final colors = _paletteFor(username);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          username[0].toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Follow Button ─────────────────────────────────────────────
class _FollowBtn extends ConsumerWidget {
  final String username;
  const _FollowBtn({required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider(username));
    final isFollowing = profileAsync.value?.isFollowing ?? false;

    return GestureDetector(
      onTap: () =>
          ref.read(profileNotifierProvider(username).notifier).toggleFollow(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.7),
            width: 1.4,
          ),
        ),
        child: Text(
          isFollowing ? 'دنبال میکنی' : 'دنبال کردن',
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _FollowBtnState extends State<_FollowBtn> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: _following
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _following
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.7),
            width: 1.4,
          ),
        ),
        child: Text(
          _following ? 'دنبال میکنی' : 'دنبال کردن',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Ghost Button ──────────────────────────────────────────────
class _GhostBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GhostBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────
class _ActBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active && activeColor != null
        ? activeColor!
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
