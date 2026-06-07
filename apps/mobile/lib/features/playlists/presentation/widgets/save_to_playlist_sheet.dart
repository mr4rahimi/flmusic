import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../../data/playlist_models.dart';
import '../../../../core/theme/app_theme.dart';

class SaveToPlaylistSheet extends ConsumerStatefulWidget {
  final String trackId;
  final String trackTitle;

  const SaveToPlaylistSheet({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  @override
  ConsumerState<SaveToPlaylistSheet> createState() =>
      _SaveToPlaylistSheetState();
}

class _SaveToPlaylistSheetState extends ConsumerState<SaveToPlaylistSheet> {
  bool _showNewForm = false;
  final _nameCtrl = TextEditingController();
  bool _creating = false;
  Set<String> _addedIds = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // grip
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmark_add_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ذخیره در پلی‌لیست',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            )),
                        Text(
                          widget.trackTitle,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // new playlist form
            if (_showNewForm) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: TextStyle(
                            fontFamily: 'Vazirmatn', color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'نام پلی‌لیست...',
                          hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn', color: textSecondary),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _creating ? null : _createAndAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('ساخت',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                )),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // playlists list
            playlistsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (playlists) => playlists.isEmpty && !_showNewForm
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.playlist_add_rounded,
                              size: 48,
                              color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('هنوز پلی‌لیستی نداری',
                              style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: playlists.length,
                      itemBuilder: (_, i) {
                        final p = playlists[i];
                        final added = _addedIds.contains(p.id);
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.queue_music_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${p.tracksCount} آهنگ',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          trailing: added
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : const Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.primary),
                          onTap: added ? null : () => _addToPlaylist(p),
                        );
                      },
                    ),
            ),

            // new playlist button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: GestureDetector(
                onTap: () => setState(() => _showNewForm = !_showNewForm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showNewForm ? Icons.close_rounded : Icons.add_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showNewForm ? 'انصراف' : 'پلی‌لیست جدید',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    try {
      await ref
          .read(playlistActionsProvider)
          .addTrack(playlist.id, widget.trackId);
      setState(() => _addedIds.add(playlist.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('به ${playlist.name} اضافه شد ✓',
                style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _createAndAdd() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      final playlist = await ref
          .read(myPlaylistsProvider.notifier)
          .create(_nameCtrl.text.trim());
      await ref
          .read(playlistActionsProvider)
          .addTrack(playlist.id, widget.trackId);
      setState(() {
        _addedIds.add(playlist.id);
        _showNewForm = false;
        _creating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('پلی‌لیست «${playlist.name}» ساخته شد ✓',
                style: const TextStyle(fontFamily: 'Vazirmatn')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      setState(() => _creating = false);
    }
  }
}
