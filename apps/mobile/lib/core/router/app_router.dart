import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/upload/presentation/screens/upload_screen.dart';
import '../../features/upload/presentation/providers/upload_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/player/presentation/widgets/mini_player.dart';
import '../theme/app_theme.dart';
import '../../features/playlists/presentation/screens/playlist_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/upload',
        builder: (_, __) => const UploadScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          child: child,
          location: state.matchedLocation,
        ),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/profile/:username',
            builder: (_, state) => ProfileScreen(
                username: state.pathParameters['username']!),
          ),
        ],
      ),

      GoRoute(
        path: '/playlist/:id',
        builder: (_, state) => PlaylistDetailScreen(
          playlistId: state.pathParameters['id']!,
        ),
)       
    ],
  );
});

class AuthRedirectWrapper extends ConsumerWidget {
  final Widget child;
  const AuthRedirectWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncLoading) return;
      final router = ref.read(routerProvider);
      final isLoggedIn = next.value != null;
      final location = router.routeInformationProvider.value.uri.path;
      final isAuthRoute =
          location == '/login' || location == '/register';
      if (!isLoggedIn && !isAuthRoute) {
        router.go('/login');
      } else if (isLoggedIn && isAuthRoute) {
        router.go('/feed');
      }
    });
    return child;
  }
}

class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  int _currentIndex(String location) {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final unreadAsync = ref.watch(unreadCountProvider);
    final uploadState = ref.watch(uploadProvider);
    final index = _currentIndex(location);
    final isUploading = uploadState.status == UploadStatus.uploading ||
        uploadState.status == UploadStatus.processing;

    ref.listen(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('آهنگ با موفقیت آپلود شد ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(uploadProvider.notifier).reset();
      } else if (next.status == UploadStatus.error &&
          prev?.status != UploadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آپلود: ${next.error ?? "خطای ناشناخته"}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(uploadProvider.notifier).reset();
      }
    });

    final fab = MediaQuery.of(context).viewInsets.bottom > 0 || isUploading
        ? null
        : _UploadFAB(onTap: () => context.push('/upload'));

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUploading) _UploadProgressBanner(state: uploadState),
          const MiniPlayer(),
          _BottomNav(
            index: index,
            unreadCount: unreadAsync.value ?? 0,
            fab: fab,
            onTap: (i) {
              switch (i) {
                case 0: context.go('/feed');
                case 1: context.go('/search');
                case 2: context.go('/notifications');
                case 3:
                  if (authUser != null) {
                    context.go('/profile/${authUser.username}');
                  }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UploadProgressBanner extends StatelessWidget {
  final UploadState state;
  const _UploadProgressBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isProcessing = state.status == UploadStatus.processing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.darkSurface,
      child: Row(
        children: [
          Icon(
            isProcessing
                ? Icons.equalizer_rounded
                : Icons.cloud_upload_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProcessing ? 'در حال پردازش...' : 'در حال آپلود...',
                  style: const TextStyle(
                      color: AppColors.darkTextPrimary, fontSize: 11),
                ),
                const SizedBox(height: 3),
                LinearProgressIndicator(
                  value: isProcessing ? null : state.progress,
                  backgroundColor: AppColors.darkCard,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
          if (!isProcessing)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${(state.progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _UploadFAB({required this.onTap});

  @override
  State<_UploadFAB> createState() => _UploadFABState();
}

class _UploadFABState extends State<_UploadFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 56,
        height: 56,
        transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.6),
                    offset: const Offset(0, depth),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    offset: const Offset(0, depth + 6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final int unreadCount;
  final Widget? fab;
  final void Function(int) onTap;

  const _BottomNav({
    required this.index,
    required this.unreadCount,
    required this.onTap,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadow = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'فید',
                isActive: index == 0,
                onTap: () => onTap(0),
              ),
              _NavBtn(
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: 'جستجو',
                isActive: index == 1,
                onTap: () => onTap(1),
              ),
              SizedBox(
                width: 56,
                height: 60,
                child: Center(child: fab ?? const SizedBox(width: 56, height: 56)),
              ),
              _NavBtnBadge(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'اعلان',
                isActive: index == 2,
                badge: unreadCount,
                onTap: () => onTap(2),
              ),
              _NavBtn(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'پروفایل',
                isActive: index == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: isActive ? AppColors.primary : inactiveColor,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtnBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _NavBtnBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: badge > 0
                  ? Badge(
                      label: Text('$badge',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700)),
                      backgroundColor: AppColors.accent,
                      child: Icon(
                        isActive ? activeIcon : icon,
                        color: isActive ? AppColors.primary : inactiveColor,
                        size: 22,
                      ),
                    )
                  : Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : inactiveColor,
                      size: 22,
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                color: isActive ? AppColors.primary : inactiveColor,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
