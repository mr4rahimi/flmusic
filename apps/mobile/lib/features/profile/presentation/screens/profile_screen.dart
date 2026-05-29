import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/feed/data/feed_models.dart';
import '../../../../features/feed/presentation/widgets/track_card.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';

class ProfileScreen extends ConsumerWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider(username));
    final tracksAsync = ref.watch(profileTracksProvider(username));
    final authUser = ref.watch(authStateProvider).value;
    final isMe = authUser?.username == username;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('خطا در بارگذاری پروفایل'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileNotifierProvider(username)),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              actions: isMe
                  ? [
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'خروج',
                        onPressed: () => _showLogoutDialog(context, ref),
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
                        AppTheme.primaryColor.withOpacity(0.6),
                        AppTheme.backgroundColor,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          profile.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.username,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (profile.verifiedStatus == 'verified') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: AppTheme.primaryColor, size: 18),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (profile.bio != null) ...[
                      Text(
                        profile.bio!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                            label: 'دنبال‌کننده',
                            value: profile.followersCount),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppTheme.textSecondary.withOpacity(0.3)),
                        _StatItem(
                            label: 'دنبال‌شده',
                            value: profile.followingCount),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isMe)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => ref
                              .read(profileNotifierProvider(username).notifier)
                              .toggleFollow(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profile.isFollowing
                                ? AppTheme.surfaceColor
                                : AppTheme.primaryColor,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: Text(
                            profile.isFollowing ? 'دنبال‌شده ✓' : 'دنبال کن',
                            style: TextStyle(
                              color: profile.isFollowing
                                  ? AppTheme.textSecondary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (isMe)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showEditProfile(context, ref, profile.bio),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('ویرایش پروفایل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                                color: AppTheme.textSecondary),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.surfaceColor),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'آهنگ‌ها',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => TrackCard(
                          track: tracks[i],
                          onTap: () => _playTrack(context, ref, tracks[i]),
                        ),
                        childCount: tracks.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showAdaptiveDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('خروج', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('مطمئنی می‌خوای خارج بشی؟',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف',
                style: TextStyle(color: AppTheme.textSecondary)),
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

  void _playTrack(BuildContext context, WidgetRef ref, Track track) {
    final playerTrack = PlayerTrack(
      id: track.id,
      title: track.title,
      coverUrl: track.coverUrl,
      audioUrl: track.audioUrl,
      duration: track.duration,
      username: track.user.username,
      likesCount: track.likesCount,
      commentsCount: track.commentsCount,
    );
    ref.read(playerActionsProvider).playTrack(playerTrack);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerScreen(track: playerTrack),
    );
  }

  void _showEditProfile(
      BuildContext context, WidgetRef ref, String? currentBio) {
    final bioController = TextEditingController(text: currentBio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
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
            const Text('ویرایش پروفایل',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'بیوگرافی...',
                counterStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.patch('/profiles/me',
                      data: {'bio': bioController.text});
                  ref.invalidate(profileNotifierProvider(username));
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
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
