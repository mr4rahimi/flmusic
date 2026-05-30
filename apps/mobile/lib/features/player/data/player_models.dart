enum RepeatMode { none, one, all }

class PlayerTrack {
  final String id;
  final String title;
  final String? coverUrl;
  final String? audioUrl;
  final int? duration;
  final String username;
  final String? avatarUrl;
  int likesCount;
  int commentsCount;
  bool isLiked;

  PlayerTrack({
    required this.id,
    required this.title,
    this.coverUrl,
    this.audioUrl,
    this.duration,
    required this.username,
    this.avatarUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });
}
