import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_models.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/feed/data/feed_models.dart';


final profileProvider =
    FutureProvider.family<Profile, String>((ref, username) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/profiles/$username');
  return Profile.fromJson(response.data);
});

final profileTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, username) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/tracks/user/$username');
  return (response.data as List).map((e) => Track.fromJson(e)).toList();
});

class ProfileNotifier extends StateNotifier<AsyncValue<Profile>> {
  final Ref _ref;
  final String username;

  ProfileNotifier(this._ref, this.username) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/profiles/$username');
      state = AsyncValue.data(Profile.fromJson(response.data));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggleFollow() async {
    final profile = state.value;
    if (profile == null) return;

    try {
      final dio = _ref.read(dioProvider);
      if (profile.isFollowing) {
        await dio.delete('/profiles/$username/follow');
        state = AsyncValue.data(profile.copyWith(
          isFollowing: false,
          followersCount: profile.followersCount - 1,
        ));
      } else {
        await dio.post('/profiles/$username/follow');
        state = AsyncValue.data(profile.copyWith(
          isFollowing: true,
          followersCount: profile.followersCount + 1,
        ));
      }
    } catch (_) {}
  }
}

final profileNotifierProvider = StateNotifierProvider.family<ProfileNotifier,
    AsyncValue<Profile>, String>(
  (ref, username) => ProfileNotifier(ref, username),
);
