import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../providers/player_provider.dart';
import '../../data/player_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/likes/presentation/providers/likes_provider.dart';
import '../../../../features/comments/presentation/screens/comments_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final PlayerTrack track;
  const PlayerScreen({super.key, required this.track});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(audioPlayerProvider);
    final currentTrack = ref.watch(currentTrackProvider) ?? widget.track;
    final repeatMode = ref.watch(repeatModeProvider);
    final queue = ref.watch(queueProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final likeStatus = ref.watch(likeStatusProvider(currentTrack.id));
    final isLiked = likeStatus ?? false;
    final storedCount = ref.watch(likesCountProvider(currentTrack.id));
    final displayLikes =
        storedCount == -1 ? currentTrack.likesCount : storedCount;

    final coverUrl = currentTrack.coverUrl != null
        ? '${baseUrl.replaceAll('/api/v1', '')}/${currentTrack.coverUrl}'
        : null;

    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);

    if (isPlaying) {
      _rotateController.forward();
    } else {
      _rotateController.stop();
    }

    return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
          ),
          child: Stack(
            children: [
              // Background — blur cover art
              if (coverUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          color: (isDark ? Colors.black : Colors.white)
                              .withOpacity(isDark ? 0.75 : 0.82),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content
              Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            size: 28,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'در حال پخش',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (queue.length > 1)
                                Text(
                                  '${currentIndex + 1} از ${queue.length}',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CommentsScreen(
                              trackId: currentTrack.id,
                              trackTitle: currentTrack.title,
                              commentsCount: currentTrack.commentsCount,
                            ),
                          ),
                          icon: Icon(
                            Icons.comment_outlined,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cover Art با انیمیشن
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // حلقه‌های pulse
                          if (isPlaying)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Container(
                                width:
                                    220 + _pulseController.value * 20,
                                height:
                                    220 + _pulseController.value * 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(
                                            0.15 * (1 - _pulseController.value)),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                          // Cover دوار
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (_, child) => Transform.rotate(
                              angle: _rotateController.value * 2 * pi,
                              child: child,
                            ),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryDark,
                                              AppColors.primary,
                                              AppColors.primaryLight,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.music_note_rounded,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // مرکز دایره
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Waveform
                  SizedBox(
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (_, __) => CustomPaint(
                        painter: _WavePainter(
                          progress: _waveController.value,
                          isPlaying: isPlaying,
                          color: AppColors.primary,
                        ),
                        size: Size(
                            MediaQuery.of(context).size.width - 48, 48),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title & Artist + Like
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTrack.title,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentTrack.username,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Like button
                        GestureDetector(
                          onTap: () async {
                            final wasLiked =
                                ref.read(likeStatusProvider(
                                        currentTrack.id)) ??
                                    false;
                            final current = ref
                                .read(likesCountProvider(currentTrack.id));
                            final base = current == -1
                                ? currentTrack.likesCount
                                : current;
                            await ref
                                .read(likeStatusProvider(currentTrack.id)
                                    .notifier)
                                .toggle();
                            ref
                                .read(likesCountProvider(currentTrack.id)
                                    .notifier)
                                .state = wasLiked
                                ? (base > 0 ? base - 1 : 0)
                                : base + 1;
                          },
                          child: Column(
                            children: [
                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(
                                        scale: anim, child: child),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  key: ValueKey(isLiked),
                                  color: isLiked
                                      ? AppColors.accent
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                  size: 28,
                                ),
                              ),
                              Text(
                                '$displayLikes',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: isLiked
                                      ? AppColors.accent
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  StreamBuilder<Duration>(
                    stream: player.onPositionChanged,
                    builder: (context, posSnapshot) {
                      final position =
                          posSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: player.onDurationChanged,
                        builder: (context, durSnapshot) {
                          final duration = durSnapshot.data ??
                              (currentTrack.duration != null
                                  ? Duration(
                                      seconds: currentTrack.duration!)
                                  : Duration.zero);
                          final progress =
                              duration.inMilliseconds > 0
                                  ? (position.inMilliseconds /
                                          duration.inMilliseconds)
                                      .clamp(0.0, 1.0)
                                  : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                            enabledThumbRadius: 7),
                                    overlayShape:
                                        const RoundSliderOverlayShape(
                                            overlayRadius: 16),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor:
                                        AppColors.primary.withOpacity(0.2),
                                    thumbColor: AppColors.primary,
                                    overlayColor:
                                        AppColors.primary.withOpacity(0.2),
                                  ),
                                  child: Slider(
                                    value: progress,
                                    onChanged: (v) => ref
                                        .read(playerActionsProvider)
                                        .seek(
                                          Duration(
                                              milliseconds: (v *
                                                      duration
                                                          .inMilliseconds)
                                                  .round()),
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors
                                                  .lightTextSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(position),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors
                                                  .lightTextSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Controls
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat
                        _ControlBtn(
                          icon: repeatMode == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: repeatMode != RepeatMode.none
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          size: 24,
                          onTap: () => ref
                              .read(playerActionsProvider)
                              .cycleRepeatMode(),
                        ),

                        // Previous
                        _ControlBtn(
                          icon: Icons.skip_previous_rounded,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          size: 36,
                          onTap: () => ref
                              .read(playerActionsProvider)
                              .playPrevious(),
                        ),

                        // Play/Pause — دکمه سه‌بعدی
                        _PlayButton(
                            isPlaying: isPlaying,
                            onTap: () => ref
                                .read(playerActionsProvider)
                                .togglePlayPause()),

                        // Next
                        _ControlBtn(
                          icon: Icons.skip_next_rounded,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          size: 36,
                          onTap: () =>
                              ref.read(playerActionsProvider).playNext(),
                        ),

                        // Queue size
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: queue.length > 1
                              ? Center(
                                  child: GlassmorphicContainer(
                                    width: 36,
                                    height: 36,
                                    borderRadius: 18,
                                    blur: 10,
                                    alignment: Alignment.center,
                                    border: 1,
                                    linearGradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderGradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.5),
                                        AppColors.primary.withOpacity(0.2),
                                      ],
                                    ),
                                    child: Text(
                                      '${queue.length}',
                                      style: const TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        );
  }
}

// Wave Painter
class _WavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barCount = 32;
    final barWidth = size.width / (barCount * 2);
    final random = Random(42);

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth;
      final baseHeight = random.nextDouble() * 0.6 + 0.1;
      final animOffset = sin(progress * 2 * pi + i * 0.4);
      final height = isPlaying
          ? (baseHeight + animOffset * 0.3).clamp(0.05, 1.0) * size.height
          : baseHeight * 0.3 * size.height;

      final centerY = size.height / 2;
      final opacity = 0.4 + (i / barCount) * 0.6;
      paint.color = color.withOpacity(opacity * 0.7);

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}

// Control Button
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

// Play Button سه‌بعدی
class _PlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primaryDark,
                      offset: const Offset(0, depth),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      offset: const Offset(0, depth + 6),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              widget.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key: ValueKey(widget.isPlaying),
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
