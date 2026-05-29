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
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_theme.dart';

final _routerKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
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

// این widget بیرون از router هست و navigate رو مدیریت می‌کنه
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/feed');
            case 1:
              context.go('/search');
            case 2:
              context.go('/notifications');
            case 3:
              if (authUser != null) {
                context.go('/profile/${authUser.username}');
              }
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'فید',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'جستجو',
          ),
          BottomNavigationBarItem(
            icon: unreadAsync.when(
              data: (count) => count > 0
                  ? Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              loading: () => const Icon(Icons.notifications_outlined),
              error: (_, __) => const Icon(Icons.notifications_outlined),
            ),
            activeIcon: const Icon(Icons.notifications_rounded),
            label: 'اعلان‌ها',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
