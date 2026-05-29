import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/player/presentation/providers/player_provider.dart';
import '../../../../features/player/data/player_models.dart';
import '../../../../features/player/presentation/screens/player_screen.dart';
import '../../../../features/player/presentation/widgets/mini_player.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    setState(() => _submittedQuery = query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final searchKey = '$_submittedQuery::$searchType';
    final resultAsync = _submittedQuery.isEmpty
        ? null
        : ref.watch(searchResultProvider(searchKey));

    return Scaffold(
      appBar: AppBar(title: const Text('جستجو')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'جستجوی آهنگ یا کاربر...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _submittedQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TypeChip(label: 'همه', value: 'all', current: searchType, ref: ref),
                const SizedBox(width: 8),
                _TypeChip(label: 'آهنگ‌ها', value: 'tracks', current: searchType, ref: ref),
                const SizedBox(width: 8),
                _TypeChip(label: 'کاربران', value: 'users', current: searchType, ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _submittedQuery.isEmpty
                ? const _EmptySearch()
                : resultAsync!.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('خطا: $e',
                          style: const TextStyle(color: AppTheme.textSecondary)),
                    ),
                    data: (result) {
                      if (result.tracks.isEmpty && result.users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  color: AppTheme.textSecondary, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'نتیجه‌ای برای "$_submittedQuery" پیدا نشد',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
                          if (result.users.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('کاربران',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                            ...result.users.map((user) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Text(user.username[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Row(children: [
                                    Text(user.username,
                                        style: const TextStyle(color: AppTheme.textPrimary)),
                                    if (user.verifiedStatus == 'verified') ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          color: AppTheme.primaryColor, size: 16),
                                    ],
                                  ]),
                                  subtitle: user.bio != null
                                      ? Text(user.bio!,
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary, fontSize: 12),
                                          overflow: TextOverflow.ellipsis)
                                      : null,
                                  onTap: () => context.push('/profile/${user.username}'),
                                )),
                            const Divider(color: AppTheme.surfaceColor),
                          ],
                          if (result.tracks.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('آهنگ‌ها',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                            ...result.tracks.map((track) => ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.music_note_rounded,
                                        color: AppTheme.primaryColor),
                                  ),
                                  title: Text(track.title,
                                      style: const TextStyle(color: AppTheme.textPrimary)),
                                  subtitle: Text(track.username,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_outline,
                                          size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${track.likesCount}',
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  onTap: () {
                                    final playerTrack = PlayerTrack(
                                      id: track.id,
                                      title: track.title,
                                      coverUrl: track.coverUrl,
                                      audioUrl: track.audioUrl,
                                      duration: track.duration,
                                      username: track.username,
                                      likesCount: track.likesCount,
                                    );
                                    ref.read(playerActionsProvider).playTrack(playerTrack);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => PlayerScreen(track: playerTrack),
                                    );
                                  },
                                )),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.current,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => ref.read(searchTypeProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 64),
          SizedBox(height: 16),
          Text('دنبال چی می‌گردی؟',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('آهنگ یا کاربر رو جستجو کن',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
