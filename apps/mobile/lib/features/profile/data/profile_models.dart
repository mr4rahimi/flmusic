class Profile {
  final String id;
  final String username;
  final String email;
  final String role;
  final String verifiedStatus;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int tracksCount;
  final bool isFollowing;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.verifiedStatus,
    this.avatarUrl,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.tracksCount,
    required this.isFollowing,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    role: json['role'],
    verifiedStatus: json['verifiedStatus'] ?? 'none',
    avatarUrl: json['avatarUrl'],
    bio: json['bio'],
    followersCount: json['followersCount'] ?? 0,
    followingCount: json['followingCount'] ?? 0,
    tracksCount: json['tracksCount'] ?? 0,
    isFollowing: json['isFollowing'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Profile copyWith({
    int? followersCount,
    bool? isFollowing,
    String? avatarUrl,
    String? bio,
  }) =>
      Profile(
        id: id,
        username: username,
        email: email,
        role: role,
        verifiedStatus: verifiedStatus,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount,
        tracksCount: tracksCount,
        isFollowing: isFollowing ?? this.isFollowing,
        createdAt: createdAt,
      );
}
