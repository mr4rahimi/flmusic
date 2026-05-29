import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/track_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/widgets/mini_player.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedType = ref.watch(feedTypeProvider);
    final feedAsync = ref.watch(feedProvider(feedType));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('موزیک'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FeedTypeTabs(feedType: feedType, ref: ref),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: feedAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text('خطا در بارگذاری'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(feedProvider(feedType)),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),
              data: (tracks) => tracks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_off_rounded,
                              color: AppTheme.textSecondary, size: 64),
                          SizedBox(height: 16),
                          Text('هنوز آهنگی نیست',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(feedProvider(feedType)),
                      child: ListView.builder(
                        itemCount: tracks.length,
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 80),
                        itemBuilder: (_, i) {
                          final track = tracks[i];
                          return TrackCard(
                            track: track,
                            onTap: () {
                              final playerTrack = PlayerTrack(
                                id: track.id,
                                title: track.title,
                                coverUrl: track.coverUrl,
                                audioUrl: track.audioUrl,
                                duration: track.duration,
                                username: track.user.username,
                                avatarUrl: track.user.avatarUrl,
                                likesCount: track.likesCount,
                                commentsCount: track.commentsCount,
                              );
                              ref
                                  .read(playerActionsProvider)
                                  .playTrack(playerTrack);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    PlayerScreen(track: playerTrack),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _FeedTypeTabs extends StatelessWidget {
  final FeedType feedType;
  final WidgetRef ref;

  const _FeedTypeTabs({required this.feedType, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
            label: 'ترندینگ',
            type: FeedType.trending,
            current: feedType,
            ref: ref),
        _Tab(
            label: 'دنبال‌شده‌ها',
            type: FeedType.following,
            current: feedType,
            ref: ref),
        _Tab(
            label: 'جدیدترین',
            type: FeedType.newTracks,
            current: feedType,
            ref: ref),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final FeedType type;
  final FeedType current;
  final WidgetRef ref;

  const _Tab({
    required this.label,
    required this.type,
    required this.current,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = type == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(feedTypeProvider.notifier).state = type,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
