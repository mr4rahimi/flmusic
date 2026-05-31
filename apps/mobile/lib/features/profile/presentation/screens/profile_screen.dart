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
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('خطا در بارگذاری پروفایل'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(profileNotifierProvider(username)),
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
                            ? () => _pickAvatar(context, ref)
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
                              .read(profileNotifierProvider(username)
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
                              context, ref, profile.bio),
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

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.darkSurface),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'آهنگ‌ها',
                        style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tracks
            tracksAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Center(
                    child: Text('خطا در بارگذاری آهنگ‌ها')),
              ),
              data: (tracks) => tracks.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'هنوز آهنگی آپلود نشده',
                            style: TextStyle(
                                color: AppColors.darkTextSecondary),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => TrackCard(
                          track: tracks[i],
                          onTap: () =>
                              _playTrack(context, ref, tracks, i),
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

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
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
      ref.invalidate(profileNotifierProvider(username));

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

  void _playTrack(BuildContext context, WidgetRef ref,
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
      BuildContext context, WidgetRef ref, String? currentBio) {
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
