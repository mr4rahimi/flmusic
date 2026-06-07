class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? coverUrl;
  final String visibility;
  final int tracksCount;
  final DateTime createdAt;
  final List<PlaylistTrack> tracks;

  Playlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    required this.visibility,
    required this.tracksCount,
    required this.createdAt,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        description: json['description'],
        coverUrl: json['coverUrl'],
        visibility: json['visibility'] ?? 'public',
        tracksCount: json['tracksCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        tracks: (json['tracks'] as List<dynamic>?)
                ?.map((t) => PlaylistTrack.fromJson(t))
                .toList() ??
            [],
      );
}

class PlaylistTrack {
  final String id;
  final String title;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;
  final int likesCount;
  final int commentsCount;
  final PlaylistTrackUser user;

  PlaylistTrack({
    required this.id,
    required this.title,
    this.coverUrl,
    this.audioUrl,
    this.duration,
    required this.likesCount,
    required this.commentsCount,
    required this.user,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
        id: json['id'],
        title: json['title'],
        coverUrl: json['coverUrl'],
        audioUrl: json['audioUrl'],
        duration: json['duration'],
        likesCount: json['likesCount'] ?? 0,
        commentsCount: json['commentsCount'] ?? 0,
        user: PlaylistTrackUser.fromJson(json['user'] ?? {}),
      );
}

class PlaylistTrackUser {
  final String username;
  final String? avatarUrl;

  PlaylistTrackUser({required this.username, this.avatarUrl});

  factory PlaylistTrackUser.fromJson(Map<String, dynamic> json) =>
      PlaylistTrackUser(
        username: json['username'] ?? '',
        avatarUrl: json['avatarUrl'],
      );
}
