class CommentUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String verifiedStatus;

  CommentUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.verifiedStatus,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) => CommentUser(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        avatarUrl: json['avatarUrl'],
        verifiedStatus: json['verifiedStatus'] ?? 'none',
      );
}

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final CommentUser user;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        user: CommentUser.fromJson(json['user']),
      );
}

class CommentsResponse {
  final List<Comment> data;
  final int total;
  final int page;
  final int totalPages;

  CommentsResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) =>
      CommentsResponse(
        data: (json['data'] as List).map((e) => Comment.fromJson(e)).toList(),
        total: json['total'] ?? 0,
        page: json['page'] ?? 1,
        totalPages: json['totalPages'] ?? 1,
      );
}
