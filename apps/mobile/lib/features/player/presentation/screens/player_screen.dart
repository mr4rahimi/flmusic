import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../../data/player_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/likes/presentation/providers/likes_provider.dart';
import '../../../../features/comments/presentation/screens/comments_screen.dart';

// ── Gradient palettes (همان track_card) ──────────────────────
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

class PlayerScreen extends ConsumerStatefulWidget {
  final PlayerTrack track;
  const PlayerScreen({super.key, required this.track});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // drag to dismiss
  double _dragY = 0;
  bool _dragging = false;
  double _dragStartY = 0;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _dragStartY = d.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    final delta = d.globalPosition.dy - _dragStartY;
    setState(() => _dragY = delta > 0 ? delta : delta * 0.25);
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    if (_dragY > 130) {
      Navigator.pop(context);
    } else {
      setState(() => _dragY = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(audioPlayerProvider);
    final currentTrack = ref.watch(currentTrackProvider) ?? widget.track;
    final repeatMode = ref.watch(repeatModeProvider);
    final queue = ref.watch(queueProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final likeStatus = ref.watch(likeStatusProvider(currentTrack.id));
    final isLiked = likeStatus ?? false;
    final storedCount = ref.watch(likesCountProvider(currentTrack.id));
    final displayLikes =
        storedCount == -1 ? currentTrack.likesCount : storedCount;

    final palette = _paletteFor(currentTrack.id);
    final base = baseUrl.replaceAll('/api/v1', '');
    final coverUrl = currentTrack.coverUrl != null
        ? (currentTrack.coverUrl!.startsWith('http')
            ? currentTrack.coverUrl!
            : '$base/${currentTrack.coverUrl}')
        : null;

    if (isPlaying) {
      _rotateCtrl.forward();
    } else {
      _rotateCtrl.stop();
    }

    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragY.clamp(0, double.infinity)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            color: isDark ? const Color(0xFF0B0B11) : AppColors.lightBg,
          ),
          child: Stack(
            children: [
              // ── Ambient background ──────────────────────────
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Stack(
                    children: [
                      // gradient ambient از palette
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              palette[0].withValues(alpha: isDark ? 0.55 : 0.25),
                              palette[2].withValues(alpha: isDark ? 0.3 : 0.1),
                              isDark ? const Color(0xFF0B0B11) : AppColors.lightBg,
                            ],
                            stops: const [0, 0.45, 0.85],
                          ),
                        ),
                      ),
                      // اگه cover داشت blur بده
                      if (coverUrl != null) ...[
                        CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: isDark ? 0.82 : 0.88),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    // grip
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Header ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // بستن
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              size: 30,
                            ),
                          ),
                          // عنوان
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'در حال پخش',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                if (queue.length > 1)
                                  Text(
                                    '${currentIndex + 1} از ${queue.length}',
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // more
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Visualizer (cover دوار + pulse rings) ─
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: _RadialVisualizer(
                          coverUrl: coverUrl,
                          palette: palette,
                          isPlaying: isPlaying,
                          rotateCtrl: _rotateCtrl,
                          pulseCtrl: _pulseCtrl,
                        ),
                      ),
                    ),

                    // ── Title + Like + Comment ────────────────
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentTrack.username,
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Like
                          _IconAction(
                            icon: isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            label: '$displayLikes',
                            active: isLiked,
                            activeColor: AppColors.primary,
                            isDark: isDark,
                            onTap: () async {
                              final wasLiked =
                                  ref.read(likeStatusProvider(currentTrack.id)) ??
                                      false;
                              final current =
                                  ref.read(likesCountProvider(currentTrack.id));
                              final base = current == -1
                                  ? currentTrack.likesCount
                                  : current;
                              await ref
                                  .read(likeStatusProvider(currentTrack.id)
                                      .notifier)
                                  .toggle();
                              ref
                                  .read(
                                      likesCountProvider(currentTrack.id).notifier)
                                  .state = wasLiked
                                  ? (base > 0 ? base - 1 : 0)
                                  : base + 1;
                            },
                          ),
                          const SizedBox(width: 12),
                          // Comment
                          _IconAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '${currentTrack.commentsCount}',
                            isDark: isDark,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CommentsScreen(
                                trackId: currentTrack.id,
                                trackTitle: currentTrack.title,
                                commentsCount: currentTrack.commentsCount,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Progress Bar ─────────────────────────
                    StreamBuilder<Duration>(
                      stream: player.onPositionChanged,
                      builder: (_, posSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: player.onDurationChanged,
                          builder: (_, durSnap) {
                            final duration = durSnap.data ??
                                (currentTrack.duration != null
                                    ? Duration(seconds: currentTrack.duration!)
                                    : Duration.zero);
                            final progress = duration.inMilliseconds > 0
                                ? (position.inMilliseconds /
                                        duration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  // custom seek bar
                                  _SeekBar(
                                    progress: progress.toDouble(),
                                    onSeek: (v) => ref
                                        .read(playerControllerProvider)
                                        .seek(Duration(
                                            milliseconds: (v *
                                                    duration.inMilliseconds)
                                                .round())),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fmt(position),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        _fmt(duration),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Transport Controls ───────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Repeat
                          _CtrlBtn(
                            icon: repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: repeatMode != RepeatMode.none
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                            size: 22,
                            onTap: () => ref
                                .read(playerControllerProvider)
                                .cycleRepeatMode(),
                          ),
                          // Previous
                          _CtrlBtn(
                            icon: Icons.skip_previous_rounded,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            size: 34,
                            fill: true,
                            onTap: () => ref
                                .read(playerControllerProvider)
                                .playPrevious(),
                          ),
                          // Play/Pause
                          _PlayBtn(
                            isPlaying: isPlaying,
                            isLoading: isLoading,
                            onTap: () => ref
                                .read(playerControllerProvider)
                                .togglePlayPause(),
                          ),
                          // Next
                          _CtrlBtn(
                            icon: Icons.skip_next_rounded,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            size: 34,
                            fill: true,
                            onTap: () =>
                                ref.read(playerControllerProvider).playNext(),
                          ),
                          // Queue count
                          _CtrlBtn(
                            icon: Icons.queue_music_rounded,
                            color: queue.length > 1
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                            size: 22,
                            onTap: () {},
                            badge: queue.length > 1 ? '${queue.length}' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Radial Visualizer ─────────────────────────────────────────
class _RadialVisualizer extends StatelessWidget {
  final String? coverUrl;
  final List<Color> palette;
  final bool isPlaying;
  final AnimationController rotateCtrl;
  final AnimationController pulseCtrl;

  const _RadialVisualizer({
    required this.coverUrl,
    required this.palette,
    required this.isPlaying,
    required this.rotateCtrl,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glow
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette[0].withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // pulse rings
          if (isPlaying)
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      _PulseRing(
                        color: palette[0],
                        progress: (pulseCtrl.value + i / 3) % 1.0,
                        maxRadius: 140,
                      ),
                  ],
                );
              },
            ),

          // radial bars
          if (isPlaying)
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => _RadialBars(
                progress: pulseCtrl.value,
                color: palette[0],
              ),
            ),

          // cover دوار
          AnimatedBuilder(
            animation: rotateCtrl,
            builder: (_, child) => Transform.rotate(
              angle: rotateCtrl.value * 2 * pi,
              child: child,
            ),
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette[0].withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: coverUrl != null
                    ? CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: palette,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
              ),
            ),
          ),

          // مرکز
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0B0B11)
                  : AppColors.lightBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final Color color;
  final double progress;
  final double maxRadius;

  const _PulseRing({
    required this.color,
    required this.progress,
    required this.maxRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = maxRadius * progress;
    final opacity = (1 - progress) * 0.25;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity.clamp(0, 1)),
          width: 1.5,
        ),
      ),
    );
  }
}

class _RadialBars extends StatelessWidget {
  final double progress;
  final Color color;

  const _RadialBars({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    const n = 40;
    final rnd = Random(42);
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _RadialBarsPainter(
          progress: progress,
          color: color,
          n: n,
          rnd: rnd,
        ),
      ),
    );
  }
}

class _RadialBarsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int n;
  final Random rnd;

  _RadialBarsPainter({
    required this.progress,
    required this.color,
    required this.n,
    required this.rnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const innerR = 100.0;
    const maxBarH = 28.0;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final rndLocal = Random(42);
    for (int i = 0; i < n; i++) {
      final angle = (i / n) * 2 * pi - pi / 2;
      final base = 0.3 + 0.7 * (rndLocal.nextDouble());
      final anim = sin(progress * 2 * pi + i * 0.7) * 0.4 + 0.6;
      final barH = base * anim * maxBarH;
      final opacity = 0.4 + (base * 0.6);

      paint.color = color.withValues(alpha: opacity * 0.75);

      final p1 = Offset(
        center.dx + cos(angle) * innerR,
        center.dy + sin(angle) * innerR,
      );
      final p2 = Offset(
        center.dx + cos(angle) * (innerR + barH),
        center.dy + sin(angle) * (innerR + barH),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_RadialBarsPainter old) => old.progress != progress;
}

// ── Seek Bar ──────────────────────────────────────────────────
class _SeekBar extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onSeek;

  const _SeekBar({required this.progress, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(d.globalPosition);
        onSeek((local.dx / box.size.width).clamp(0, 1));
      },
      onHorizontalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(d.globalPosition);
        onSeek((local.dx / box.size.width).clamp(0, 1));
      },
      child: Container(
        height: 20,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // track
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            // fill
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // thumb
            Positioned(
              left: progress *
                      (MediaQuery.of(context).size.width - 56) -
                  7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control Button ────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool fill;
  final VoidCallback onTap;
  final String? badge;

  const _CtrlBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.fill = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: size),
            if (badge != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Play Button ───────────────────────────────────────────────
class _PlayBtn extends StatefulWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayBtn({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
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
          width: 72,
          height: 72,
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
                      color: AppColors.primary.withValues(alpha: 0.4),
                      offset: const Offset(0, depth + 6),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isPlaying),
                    color: Colors.white,
                    size: 38,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Icon Action (like / comment) ──────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active && activeColor != null
        ? activeColor!
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(icon, key: ValueKey(active), color: color, size: 26),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}