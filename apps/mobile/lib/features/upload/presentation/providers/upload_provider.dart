import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

enum UploadStatus { idle, downloading, uploading, processing, done, error }

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? error;
  final String? trackId;

  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0,
    this.error,
    this.trackId,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
    String? trackId,
  }) =>
      UploadState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        trackId: trackId ?? this.trackId,
      );
}

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref _ref;
  UploadNotifier(this._ref) : super(const UploadState());

  void reset() => state = const UploadState();

  Future<void> uploadFromFile({
    required String filePath,
    required String title,
    required String artistName,
    String? coverPath,
    List<String>? tags,
    String? description,
    String visibility = 'public',
  }) async {
    try {
      state = state.copyWith(status: UploadStatus.uploading, progress: 0);

      final dio = _ref.read(dioProvider);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath),
        'title': title,
        'description': description ?? '',
        'genre': artistName,
        'tags': tags?.join(',') ?? '',
        'visibility': visibility,
        if (coverPath != null)
          'cover': await MultipartFile.fromFile(coverPath),
      });

      final response = await dio.post(
        '/tracks',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = state.copyWith(
        status: UploadStatus.processing,
        progress: 1,
        trackId: response.data['id'],
      );

      // poll تا ready بشه
      await _pollTrackStatus(response.data['id']);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        error: 'خطا در آپلود: ${e.toString()}',
      );
    }
  }

  Future<void> uploadFromUrl({
    required String url,
    required String title,
    required String artistName,
    String? coverPath,
    List<String>? tags,
    String? description,
    String visibility = 'public',
  }) async {
    try {
      state = state.copyWith(status: UploadStatus.downloading, progress: 0);

      // دانلود فایل به temp
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

      final downloadDio = Dio();
      (downloadDio.httpClientAdapter as dynamic).onHttpClientCreate =
          (dynamic client) {
        client.badCertificateCallback =
            (dynamic cert, String host, int port) => true;
        return client;
      };
      await downloadDio.download(
        url,
        tempFile.path,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(progress: received / total * 0.5);
          }
        },
      );

      // آپلود فایل دانلود شده
      await uploadFromFile(
        filePath: tempFile.path,
        title: title,
        artistName: artistName,
        coverPath: coverPath,
        tags: tags,
        description: description,
        visibility: visibility,
      );

      // پاک کردن فایل temp
      if (await tempFile.exists()) await tempFile.delete();
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        error: 'خطا در دانلود لینک: ${e.toString()}',
      );
    }
  }

  Future<void> _pollTrackStatus(String trackId) async {
    final dio = _ref.read(dioProvider);
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final response = await dio.get('/tracks/$trackId');
        if (response.data['status'] == 'ready') {
          state = state.copyWith(status: UploadStatus.done);
          return;
        }
        if (response.data['status'] == 'failed') {
          state = state.copyWith(
            status: UploadStatus.error,
            error: 'پردازش فایل با خطا مواجه شد',
          );
          return;
        }
      } catch (_) {}
    }
    state = state.copyWith(status: UploadStatus.done);
  }
}

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});

// جستجوی live خواننده‌ها
final artistSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final dio = ref.read(dioProvider);
  final response = await dio.get('/search', queryParameters: {
    'q': query,
    'type': 'users',
    'limit': 5,
  });
  return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
});

// جستجوی live تگ‌ها
final tagSearchProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.trim().length < 1) return [];
  // تگ‌های پیشنهادی از پرکاربردترین‌ها
  final suggestions = [
    'پاپ', 'رپ', 'راک', 'کلاسیک', 'جاز', 'الکترونیک',
    'سنتی', 'مردمی', 'عاشقانه', 'شاد', 'غمگین', 'ریمیکس',
    'لایو', 'آکوستیک', 'بیکلام', 'ایرانی', 'خارجی',
  ];
  return suggestions
      .where((t) => t.contains(query) || query.contains(t))
      .toList();
});
