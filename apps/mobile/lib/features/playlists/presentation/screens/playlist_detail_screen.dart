import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../../data/playlist_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: playlistAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('خطا در بارگذاری')),
        data: (playlist) => CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _PlaylistHeader(playlist: playlist),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.play_circle_filled_rounded,
                      color: AppColors.primary, size: 32),
                  onPressed: playlist.tracks.isEmpty
                      ? null
                      : () => _playAll(context, ref, playlist),
                ),
              ],
            ),

            // tracks count
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${playlist.tracksCount} آهنگ',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (playlist.tracks.isNotEmpty)
                      GestureDetector(
                        onTap: () => _playAll(context, ref, playlist),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('پخش همه',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // tracks list
            playlist.tracks.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.music_off_rounded,
                              size: 64,
                              color: (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('آهنگی در این پلی‌لیست نیست',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              )),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TrackTile(
                        track: playlist.tracks[i],
                        index: i,
                        onTap: () => _playFrom(context, ref, playlist, i),
                        onRemove: () => _removeTrack(
                            ref, playlist.id, playlist.tracks[i].id),
                      ),
                      childCount: playlist.tracks.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _playAll(BuildContext context, WidgetRef ref, Playlist playlist) {
    _playFrom(context, ref, playlist, 0);
  }

  void _playFrom(
      BuildContext context, WidgetRef ref, Playlist playlist, int index) {
    final queue = playlist.tracks
        .map((t) => PlayerTrack(
              id: t.id,
              title: t.title,
              coverUrl: t.coverUrl,
              audioUrl: t.audioUrl,
              duration: t.duration,
              username: t.user.username,
              likesCount: t.likesCount,
              commentsCount: t.commentsCount,
            ))
        .toList();
    ref.read(playerControllerProvider).setQueue(queue, index);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerScreen(track: queue[index]),
    );
  }

  void _removeTrack(WidgetRef ref, String playlistId, String trackId) {
    ref.read(playlistActionsProvider).removeTrack(playlistId, trackId);
  }
}

// ── Playlist Header ───────────────────────────────────────────
class _PlaylistHeader extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistHeader({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.7),
            isDark ? AppColors.darkBg : AppColors.lightBg,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            children: [
              // cover
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: playlist.coverUrl != null
                      ? Image.network(
                          '${baseUrl.replaceAll('/api/v1', '')}/${playlist.coverUrl}',
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.queue_music_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playlist.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        playlist.description!,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

// ── Track Tile ────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final PlaylistTrack track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseUrl.replaceAll('/api/v1', '');

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.coverUrl != null
            ? Image.network(
                track.coverUrl!.startsWith('http')
                    ? track.coverUrl!
                    : '$base/${track.coverUrl}',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: AppColors.primary, size: 22),
              ),
      ),
      title: Text(
        track.title,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.user.username,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert_rounded,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
        onPressed: () => _showOptions(context),
      ),
      onTap: onTap,
    );
  }

  void _showOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.primary),
              title: const Text('پخش',
                  style: TextStyle(fontFamily: 'Vazirmatn')),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline_rounded,
                      color: Colors.redAccent),
              title: const Text('حذف از پلی‌لیست',
                  style: TextStyle(
                      fontFamily: 'Vazirmatn', color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
