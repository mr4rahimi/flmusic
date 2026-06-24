import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../providers/profile_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/feed/data/feed_models.dart';
import '../../../../features/feed/presentation/widgets/track_card.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/playlists/presentation/providers/playlist_provider.dart';
import '../../../../features/playlists/data/playlist_models.dart';

  class ProfileScreen extends ConsumerStatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0; // 0: آهنگ‌ها، 1: پلی‌لیست‌ها

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider(widget.username));
    final tracksAsync = ref.watch(profileTracksProvider(widget.username));
    final authUser = ref.watch(authStateProvider).value;
    final isMe = authUser?.username == widget.username;



    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('خطا در بارگذاری پروفایل'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileNotifierProvider(widget.username).notifier).toggleFollow(),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              actions: isMe
                  ? [
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.6),
                        AppColors.darkBg,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      // Avatar با قابلیت آپلود
                      GestureDetector(
                        onTap: isMe
                            ? () => _pickAvatar(context)
                            : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.primary,
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(
                                      '${baseUrl.replaceAll('/api/v1', '')}/${profile.avatarUrl}',
                                    )
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      profile.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (isMe)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.username,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (profile.verifiedStatus == 'verified') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      Text(
                        profile.bio!,
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Stats — followers / following / tracks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                            label: 'دنبال‌کننده',
                            value: profile.followersCount),
                        Container(
                            width: 1,
                            height: 32,
                            color:
                                AppColors.darkTextSecondary.withOpacity(0.3)),
                        _StatItem(
                            label: 'دنبال‌شده',
                            value: profile.followingCount),
                        Container(
                            width: 1,
                            height: 32,
                            color:
                                AppColors.darkTextSecondary.withOpacity(0.3)),
                        _StatItem(
                            label: 'آهنگ',
                            value: profile.tracksCount),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Follow / Edit Button
                    if (!isMe)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => ref
                              .read(profileNotifierProvider(widget.username)
                                  .notifier)
                              .toggleFollow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profile.isFollowing
                                ? AppColors.darkSurface
                                : AppColors.primary,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: Text(
                            profile.isFollowing
                                ? 'دنبال‌شده ✓'
                                : 'دنبال کن',
                            style: TextStyle(
                              color: profile.isFollowing
                                  ? AppColors.darkTextSecondary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),

                    if (isMe)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditProfile(
                              context, profile.bio),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('ویرایش پروفایل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.darkTextPrimary,
                            side: const BorderSide(
                                color: AppColors.darkTextSecondary),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    _ProfileTabBar(
                      selectedTab: _selectedTab,
                      onTabChange: (t) => setState(() => _selectedTab = t),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Tracks
              if (_selectedTab == 0)
              tracksAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(child: Text('خطا در بارگذاری آهنگ‌ها')),
                ),
                data: (tracks) => tracks.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('هنوز آهنگی آپلود نشده',
                                style: TextStyle(color: AppColors.darkTextSecondary)),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => TrackCard(
                            track: tracks[i],
                            onTap: () => _playTrack(context, tracks, i),
                          ),
                          childCount: tracks.length,
                        ),
                      ),
              )
            else
              _PlaylistsTab(username: widget.username),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(image.path),
      });
      await dio.post('/profiles/me/avatar', data: formData);
      ref.invalidate(profileNotifierProvider(widget.username));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تصویر پروفایل آپدیت شد ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در آپلود تصویر'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playTrack(BuildContext context,
      List<Track> tracks, int index) {
    final queue = tracks
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
    ref.read(playerActionsProvider).setQueue(queue, index);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerScreen(track: queue[index]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('خروج',
            style: TextStyle(color: AppColors.darkTextPrimary)),
        content: const Text('مطمئنی می‌خوای خارج بشی؟',
            style: TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await Future.delayed(const Duration(milliseconds: 100));
              await ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('خروج',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(
      BuildContext context, String? currentBio) {
    final bioController = TextEditingController(text: currentBio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ویرایش پروفایل',
              style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(color: AppColors.darkTextPrimary),
              decoration: const InputDecoration(
                hintText: 'بیوگرافی...',
                counterStyle:
                    TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.patch('/profiles/me',
                      data: {'bio': bioController.text});
                  ref.invalidate(profileNotifierProvider(widget.username));
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {}
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.darkTextSecondary, fontSize: 12)),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────
class _ProfileTabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChange;

  const _ProfileTabBar({
    required this.selectedTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      (Icons.music_note_rounded, 'آهنگ‌ها'),
      (Icons.queue_music_rounded, 'پلی‌لیست‌ها'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          final isActive = selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChange(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Playlists Tab ─────────────────────────────────────────────
class _PlaylistsTab extends ConsumerWidget {
  final String username;
  const _PlaylistsTab({required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final isMe = authUser?.username == username;
    // Profile is already cached (loaded by parent), so .value is available instantly.
    final profileId = ref.watch(profileNotifierProvider(username)).value?.id;

    final AsyncValue<List<Playlist>> playlistsAsync;
    if (isMe) {
      playlistsAsync = ref.watch(myPlaylistsProvider);
    } else if (profileId != null) {
      playlistsAsync = ref.watch(userPlaylistsProvider(profileId));
    } else {
      playlistsAsync = const AsyncLoading();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return playlistsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Center(child: Text('خطا در بارگذاری')),
      ),
      data: (playlists) => playlists.isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.queue_music_rounded,
                        size: 64,
                        color: (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary)
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      isMe ? 'هنوز پلی‌لیستی نساختی' : 'پلی‌لیستی وجود ندارد',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PlaylistGridItem(playlist: playlists[i]),
                childCount: playlists.length,
              ),
            ),
    );
  }
}

// ── Playlist Grid Item ────────────────────────────────────────
class _PlaylistGridItem extends StatelessWidget {
  final playlist;
  const _PlaylistGridItem({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/playlist/${playlist.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // cover
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: playlist.coverUrl != null
                      ? Image.network(
                          playlist.coverUrl!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.queue_music_rounded,
                            color: AppColors.primary,
                            size: 48,
                          ),
                        ),
                ),
              ),
            ),
            // info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${playlist.tracksCount} آهنگ',
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
            ),
          ],
        ),
      ),
    );
  }
}