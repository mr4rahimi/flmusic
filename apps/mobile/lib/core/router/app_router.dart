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
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
    final index = _currentIndex(location);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/upload'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surfaceColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // فید
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'فید',
              isActive: index == 0,
              onTap: () => context.go('/feed'),
            ),
            // جستجو
            _NavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: 'جستجو',
              isActive: index == 1,
              onTap: () => context.go('/search'),
            ),
            // فاصله برای FAB
            const SizedBox(width: 56),
            // اعلان‌ها
            _NavItemWithBadge(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'اعلان‌ها',
              isActive: index == 2,
              badgeCount: unreadAsync.value ?? 0,
              onTap: () => context.go('/notifications'),
            ),
            // پروفایل
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'پروفایل',
              isActive: index == 3,
              onTap: () {
                if (authUser != null) {
                  context.go('/profile/${authUser.username}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              badgeCount > 0
                  ? Badge(
                      label: Text('$badgeCount'),
                      child: Icon(
                        isActive ? activeIcon : icon,
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                    )
                  : Icon(
                      isActive ? activeIcon : icon,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      size: 24,
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
