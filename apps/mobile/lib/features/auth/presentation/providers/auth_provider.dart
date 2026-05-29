import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_models.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';

final authStateProvider = FutureProvider<AuthUser?>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final token = await storage.getAccessToken();
  if (token == null) return null;

  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/profiles/me');
    return AuthUser.fromJson(response.data);
  } catch (_) {
    return null;
  }
});

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

class AuthActions {
  final Ref _ref;
  AuthActions(this._ref);

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
    _ref.invalidate(authStateProvider);
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
    _ref.invalidate(authStateProvider);
  }

  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.clearTokens();
    _ref.invalidate(authStateProvider);
  }
}
