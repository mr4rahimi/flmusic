import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

class SearchUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String verifiedStatus;

  SearchUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.verifiedStatus,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) => SearchUser(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    avatarUrl: json['avatarUrl'],
    bio: json['bio'],
    verifiedStatus: json['verifiedStatus'] ?? 'none',
  );
}

class SearchTrack {
  final String id;
  final String title;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;
  final String? genre;
  final int playCount;
  final int likesCount;
  final String username;

  SearchTrack({
    required this.id,
    required this.title,
    this.coverUrl,
    this.audioUrl,
    this.duration,
    this.genre,
    required this.playCount,
    required this.likesCount,
    required this.username,
  });

  factory SearchTrack.fromJson(Map<String, dynamic> json) => SearchTrack(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    coverUrl: json['coverUrl'],
    audioUrl: json['audioUrl'],
    duration: json['duration'],
    genre: json['genre'],
    playCount: json['playCount'] ?? 0,
    likesCount: json['likesCount'] ?? 0,
    username: json['username'] ?? '',
  );
}

class SearchResult {
  final List<SearchTrack> tracks;
  final List<SearchUser> users;
  SearchResult({required this.tracks, required this.users});
}

// key = 'query::type'
final searchResultProvider =
    FutureProvider.family<SearchResult, String>((ref, key) async {
  final parts = key.split('::');
  final query = parts[0];
  final type = parts.length > 1 ? parts[1] : 'all';

  if (query.trim().isEmpty) return SearchResult(tracks: [], users: []);

  final dio = ref.read(dioProvider);
  final response = await dio.get('/search', queryParameters: {
    'q': query,
    'type': type,
    'limit': 20,
  });

  final data = response.data;

  if (type == 'tracks') {
    return SearchResult(
      tracks: (data['data'] as List).map((e) => SearchTrack.fromJson(e)).toList(),
      users: [],
    );
  }

  if (type == 'users') {
    return SearchResult(
      tracks: [],
      users: (data['data'] as List).map((e) => SearchUser.fromJson(e)).toList(),
    );
  }

  // all
  final tracksData = data['tracks']?['data'] as List? ?? [];
  final usersData = data['users']?['data'] as List? ?? [];

  return SearchResult(
    tracks: tracksData.map((e) => SearchTrack.fromJson(e)).toList(),
    users: usersData.map((e) => SearchUser.fromJson(e)).toList(),
  );
});

final searchTypeProvider = StateProvider<String>((ref) => 'all');
