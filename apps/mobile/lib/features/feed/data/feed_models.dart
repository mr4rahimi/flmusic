class TrackUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String verifiedStatus;

  TrackUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.verifiedStatus,
  });

  factory TrackUser.fromJson(Map<String, dynamic> json) => TrackUser(
    id: json['id'],
    username: json['username'],
    avatarUrl: json['avatarUrl'],
    verifiedStatus: json['verifiedStatus'] ?? 'none',
  );
}

class Track {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;
  final String? genre;
  final List<String>? tags;
  final int playCount;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final TrackUser user;

  Track({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.audioUrl,
    this.duration,
    this.genre,
    this.tags,
    required this.playCount,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.user,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    coverUrl: json['coverUrl'],
    audioUrl: json['audioUrl'],
    duration: json['duration'],
    genre: json['genre'],
    tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    playCount: json['playCount'] ?? 0,
    likesCount: json['likesCount'] ?? 0,
    commentsCount: json['commentsCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    user: TrackUser.fromJson(json['user']),
  );
}

class FeedResponse {
  final List<Track> data;
  final int total;
  final int page;
  final int totalPages;

  FeedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) => FeedResponse(
    data: (json['data'] as List).map((e) => Track.fromJson(e)).toList(),
    total: json['total'],
    page: json['page'],
    totalPages: json['totalPages'],
  );
}
