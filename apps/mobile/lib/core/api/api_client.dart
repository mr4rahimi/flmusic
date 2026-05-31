import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

// آدرس سرور production رو اینجا بذار
const String _productionUrl = 'https://api.flmusic.ir/api/v1';
const String _devUrl = 'http://127.0.0.1:3000/api/v1';

const String baseUrl = kReleaseMode ? _productionUrl : _devUrl;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final storage = ref.read(secureStorageProvider);
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '$baseUrl/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newToken = response.data['accessToken'];
              await storage.saveTokens(
                accessToken: newToken,
                refreshToken: refreshToken,
              );
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final retryResponse = await Dio().fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {
              await storage.clearTokens();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
