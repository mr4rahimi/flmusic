class AuthUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? bio;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.bio,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    role: json['role'],
    avatarUrl: json['avatarUrl'],
    bio: json['bio'],
  );
}

class AuthResponse {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: AuthUser.fromJson(json['user']),
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
  );
}
