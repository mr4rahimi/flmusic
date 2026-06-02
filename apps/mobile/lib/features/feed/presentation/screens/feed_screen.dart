import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/track_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/widgets/mini_player.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedType = ref.watch(feedTypeProvider);
    final feedAsync = ref.watch(feedProvider(feedType));

    return Scaffold(
      appBar: _FeedAppBar(feedType: feedType, ref: ref),
      body: Column(
        children: [
          Expanded(
            child: feedAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text('خطا در بارگذاری'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(feedProvider(feedType)),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              ),
              data: (tracks) => tracks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_off_rounded,
                              color: AppColors.darkTextSecondary, size: 64),
                          SizedBox(height: 16),
                          Text('هنوز آهنگی نیست',
                              style:
                                  TextStyle(color: AppColors.darkTextSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(feedProvider(feedType)),
                      child: ListView.builder(
                        itemCount: tracks.length,
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 80),
                        itemBuilder: (_, i) {
                          final track = tracks[i];
                          return TrackCard(
                            track: track,
                            onTap: () {
                              final queue = tracks.map((t) => PlayerTrack(
                                id: t.id,
                                title: t.title,
                                coverUrl: t.coverUrl,
                                audioUrl: t.audioUrl,
                                duration: t.duration,
                                username: t.user.username,
                                avatarUrl: t.user.avatarUrl,
                                likesCount: t.likesCount,
                                commentsCount: t.commentsCount,
                              )).toList();
                              ref.read(playerActionsProvider).setQueue(queue, i);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => PlayerScreen(track: queue[i]),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _FeedTypeTabs extends StatefulWidget {
  final FeedType feedType;
  final WidgetRef ref;

  const _FeedTypeTabs({required this.feedType, required this.ref});

  @override
  State<_FeedTypeTabs> createState() => _FeedTypeTabsState();
}

class _FeedTypeTabsState extends State<_FeedTypeTabs> {
  final List<GlobalKey> _keys = List.generate(3, (_) => GlobalKey());

  @override
  void didUpdateWidget(_FeedTypeTabs old) {
    super.didUpdateWidget(old);
    if (old.feedType != widget.feedType) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      (FeedType.trending, 'محبوب‌ها', Icons.local_fire_department_rounded),
      (FeedType.following, 'دنبال‌شده‌ها', Icons.headphones_rounded),
      (FeedType.newTracks, 'جدیدترین', Icons.access_time_rounded),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Stack(
        children: [
          // pill
          _AnimatedPill(
            keys: _keys,
            activeIndex: types.indexWhere((t) => t.$1 == widget.feedType),
          ),
          // tabs
          Row(
            children: types.asMap().entries.map((e) {
              final i = e.key;
              final (type, label, icon) = e.value;
              final isActive = widget.feedType == type;
              return Expanded(
                child: GestureDetector(
                  key: _keys[i],
                  onTap: () =>
                      widget.ref.read(feedTypeProvider.notifier).state = type,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPill extends StatefulWidget {
  final List<GlobalKey> keys;
  final int activeIndex;
  const _AnimatedPill({required this.keys, required this.activeIndex});

  @override
  State<_AnimatedPill> createState() => _AnimatedPillState();
}

class _AnimatedPillState extends State<_AnimatedPill> {
  double _x = 0;
  double _w = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(_AnimatedPill old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    }
  }

  void _update() {
    final key = widget.keys[widget.activeIndex];
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero,
        ancestor: context.findRenderObject());
    setState(() {
      _x = pos.dx;
      _w = box.size.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      left: _x,
      top: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        width: _w,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}



class _FeedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final FeedType feedType;
  final WidgetRef ref;

  const _FeedAppBar({required this.feedType, required this.ref});

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row اصلی
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    // منو همبرگری — سمت راست
                    _HamburgerMenu(),

                    // عنوان — وسط
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.primaryDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'موزیک',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // آیکن تم — سمت چپ
                    IconButton(
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).state =
                            themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(themeMode),
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tabs
            _FeedTypeTabs(feedType: feedType, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _HamburgerMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () => _showMenu(context),
      icon: Icon(
        Icons.menu_rounded,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
        size: 22,
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: subColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // عنوان منو
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'منو',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 8),

                // تماس با ما
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  label: 'تماس با ما',
                  color: AppColors.accentBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _showContactDialog(context);
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCard : AppColors.lightSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تماس با ما',
          style: TextStyle(
              fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'برای ارتباط با تیم پشتیبانی:\n\nایمیل: support@musicapp.ir\nتلگرام: @musicapp_support',
          style: TextStyle(fontFamily: 'Vazirmatn', height: 1.8),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن',
                style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
