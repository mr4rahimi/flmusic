import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/feed_models.dart';
import '../../../../core/api/api_client.dart';

enum FeedType { trending, following, newTracks }

final feedTypeProvider = StateProvider<FeedType>((ref) => FeedType.trending);

final feedProvider = FutureProvider.family<List<Track>, FeedType>((ref, type) async {
  final dio = ref.read(dioProvider);
  final endpoint = switch (type) {
    FeedType.trending => '/feed/trending',
    FeedType.following => '/feed/following',
    FeedType.newTracks => '/feed/new',
  };
  final response = await dio.get(endpoint, queryParameters: {'limit': 20});
  return FeedResponse.fromJson(response.data).data;
});
