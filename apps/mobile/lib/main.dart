import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/audio/audio_handler.dart';
import 'features/player/presentation/providers/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Permission.notification.request();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  // این خط چیزی بود که کم داشتیم:
  // AudioService سرویس foreground اندروید را بالا می‌آورد و
  // نوتیفیکیشن + کنترل‌های لاک‌اسکرین را می‌سازد.
  final audioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.music.app.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationChannelDescription: 'کنترل پخش موسیقی',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidShowNotificationBadge: false,
      notificationColor: Color(0xFFF97316),
    ),
  );

  timeago.setLocaleMessages('fa', timeago.FaMessages());

  runApp(ProviderScope(
    overrides: [
      audioHandlerProvider.overrideWithValue(audioHandler),
    ],
    child: const MusicApp(),
  ));
}

class MusicApp extends ConsumerWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return AuthRedirectWrapper(
      child: MaterialApp.router(
        title: 'Music Platform',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('fa', 'IR'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
      ),
    );
  }
}