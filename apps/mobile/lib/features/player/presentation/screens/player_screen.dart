import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../../data/player_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/likes/presentation/providers/likes_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final PlayerTrack track;
  const PlayerScreen({super.key, required this.track});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _isLiked = false;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.track.isLiked;
    _likesCount = widget.track.likesCount;
    _checkIsLiked();
  }

  Future<void> _checkIsLiked() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/tracks/${widget.track.id}/liked');
      if (mounted) setState(() => _isLiked = response.data == true);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    try {
      final dio = ref.read(dioProvider);
      if (_isLiked) {
        await dio.delete('/tracks/${widget.track.id}/like');
        setState(() { _isLiked = false; _likesCount--; });
      } else {
        await dio.post('/tracks/${widget.track.id}/like');
        setState(() { _isLiked = true; _likesCount++; });
      }
    } catch (_) {}
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Queue info
          if (queue.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentIndex + 1} از ${queue.length}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Cover
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.music_note_rounded,
                color: AppTheme.primaryColor, size: 80),
          ),
          const SizedBox(height: 24),

          // Title & Artist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  currentTrack.title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(currentTrack.username,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Like & Comment
          Builder(builder: (context) {
            final likeStatus = ref.watch(likeStatusProvider(currentTrack.id));
            final isLikedNow = likeStatus ?? _isLiked;
            final likesCountNow = ref.watch(likesCountProvider(currentTrack.id));
            final displayLikes = likesCountNow > 0 ? likesCountNow : _likesCount;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    final wasLiked = ref.read(likeStatusProvider(currentTrack.id)) ?? false;
                    final currentCount = ref.read(likesCountProvider(currentTrack.id));
                    await ref.read(likeStatusProvider(currentTrack.id).notifier).toggle();
                    ref.read(likesCountProvider(currentTrack.id).notifier).state =
                        wasLiked ? (currentCount > 0 ? currentCount - 1 : 0) : currentCount + 1;
                  },
                  icon: Icon(
                    isLikedNow ? Icons.favorite_rounded : Icons.favorite_outline,
                    color: isLikedNow ? AppTheme.accentColor : AppTheme.textSecondary,
                    size: 26,
                  ),
                ),
                Text('$displayLikes',
                    style: TextStyle(
                      color: isLikedNow ? AppTheme.accentColor : AppTheme.textSecondary,
                    )),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined,
                      color: AppTheme.textSecondary, size: 26),
                ),
                Text('${currentTrack.commentsCount}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            );
          }),

          // Progress Bar
          StreamBuilder<Duration>(
            stream: player.onPositionChanged,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: player.onDurationChanged,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ??
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
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape:
                                const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                            overlayShape:
                                const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                            activeTrackColor: AppTheme.primaryColor,
                            inactiveTrackColor:
                                AppTheme.textSecondary.withOpacity(0.3),
                            thumbColor: AppTheme.primaryColor,
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (v) =>
                                ref.read(playerActionsProvider).seek(
                                      Duration(
                                          milliseconds: (v *
                                                  duration
                                                      .inMilliseconds)
                                              .round()),
                                    ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              Text(_formatDuration(duration),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
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

          const SizedBox(height: 8),

          // Controls
          StreamBuilder<PlayerState>(
            stream: player.onPlayerStateChanged,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data == PlayerState.playing;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Repeat button
                  IconButton(
                    icon: Icon(
                      repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: repeatMode == RepeatMode.none
                          ? AppTheme.textSecondary
                          : AppTheme.primaryColor,
                      size: 24,
                    ),
                    onPressed: () => ref
                        .read(playerActionsProvider)
                        .cycleRepeatMode(),
                    tooltip: repeatMode == RepeatMode.none
                        ? 'تکرار خاموش'
                        : repeatMode == RepeatMode.all
                            ? 'تکرار همه'
                            : 'تکرار یک آهنگ',
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppTheme.textPrimary, size: 36),
                    onPressed: () =>
                        ref.read(playerActionsProvider).playPrevious(),
                  ),

                  // Play/Pause
                  GestureDetector(
                    onTap: () => ref
                        .read(playerActionsProvider)
                        .togglePlayPause(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppTheme.textPrimary, size: 36),
                    onPressed: () =>
                        ref.read(playerActionsProvider).playNext(),
                  ),

                  // Queue count
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: queue.length > 1
                        ? Text(
                            '${queue.length}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
