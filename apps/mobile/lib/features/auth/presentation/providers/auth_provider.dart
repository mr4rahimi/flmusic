import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_models.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/profiles/me');
      state = AsyncValue.data(AuthUser.fromJson(response.data));
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(response.data);
    final storage = _ref.read(secureStorageProvider);
    await storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    state = AsyncValue.data(auth.user);
  }

  Future<void> register(String username, String email, String password) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    final auth = AuthResponse.fromJson(response.data);
    final storage = _ref.read(secureStorageProvider);
    await storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    state = AsyncValue.data(auth.user);
  }

  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.clearTokens();
    state = const AsyncValue.data(null);
  }
}

// برای backward compatibility
final authActionsProvider = Provider<_AuthActionsCompat>((ref) {
  return _AuthActionsCompat(ref);
});

class _AuthActionsCompat {
  final Ref _ref;
  _AuthActionsCompat(this._ref);

  Future<void> login(String email, String password) =>
      _ref.read(authStateProvider.notifier).login(email, password);

  Future<void> register(String username, String email, String password) =>
      _ref.read(authStateProvider.notifier).register(username, email, password);

  Future<void> logout() =>
      _ref.read(authStateProvider.notifier).logout();
}
