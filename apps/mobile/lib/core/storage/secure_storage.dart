import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  // Linux desktop fallback — در memory نگه میداره
  static String? _accessToken;
  static String? _refreshToken;

  final _storage = const FlutterSecureStorage(
    lOptions: LinuxOptions(),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    if (!kIsWeb) {
      try {
        await Future.wait([
          _storage.write(key: 'access_token', value: accessToken),
          _storage.write(key: 'refresh_token', value: refreshToken),
        ]);
      } catch (e) {
        debugPrint('SecureStorage write error: $e');
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      return null;
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await Future.wait([
        _storage.delete(key: 'access_token'),
        _storage.delete(key: 'refresh_token'),
      ]);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
    }
  }
}
