import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/playlist_models.dart';
import '../../../../core/api/api_client.dart';

// لیست پلی‌لیست‌های کاربر
final myPlaylistsProvider =
    AsyncNotifierProvider<MyPlaylistsNotifier, List<Playlist>>(
        MyPlaylistsNotifier.new);

class MyPlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() async {
    return _fetch();
  }

  Future<List<Playlist>> _fetch() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/playlists/my');
    return (res.data as List).map((e) => Playlist.fromJson(e)).toList();
  }

  Future<Playlist> create(String name, {String? description}) async {
    final dio = ref.read(dioProvider);
    final res = await dio.post('/playlists', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    final playlist = Playlist.fromJson(res.data);
    state = AsyncData([playlist, ...state.value ?? []]);
    return playlist;
  }

  Future<void> delete(String playlistId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/playlists/$playlistId');
    state = AsyncData(
      (state.value ?? []).where((p) => p.id != playlistId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// جزئیات یک پلی‌لیست با آهنگ‌هاش
final playlistDetailProvider =
    FutureProvider.family<Playlist, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/playlists/$id');
  return Playlist.fromJson(res.data);
});

// اضافه/حذف آهنگ از پلی‌لیست
final playlistActionsProvider = Provider<PlaylistActions>((ref) {
  return PlaylistActions(ref);
});

class PlaylistActions {
  final Ref _ref;
  PlaylistActions(this._ref);

  Future<void> addTrack(String playlistId, String trackId) async {
    final dio = _ref.read(dioProvider);
    await dio.post('/playlists/$playlistId/tracks',
        data: {'trackId': trackId});
    _ref.invalidate(playlistDetailProvider(playlistId));
    _ref.invalidate(myPlaylistsProvider);
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    final dio = _ref.read(dioProvider);
    await dio.delete('/playlists/$playlistId/tracks/$trackId');
    _ref.invalidate(playlistDetailProvider(playlistId));
  }
}
