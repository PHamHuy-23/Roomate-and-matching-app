class AuthUser {
  final String token;
  final int userId;
  final String email;
  final String fullName;
  final String gender;
  final String role;

  AuthUser({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    final user = nestedUser is Map<String, dynamic> ? nestedUser : json;
    final tokenValue = json['accessToken'] ?? json['token'];
    if (tokenValue is! String || tokenValue.isEmpty) {
      throw const FormatException('Auth response không chứa access token');
    }

    return AuthUser(
      token: tokenValue,
      userId: (user['id'] ?? user['userId']) as int,
      email: user['email'] as String,
      fullName: user['fullName'] as String,
      gender: user['gender'] as String,
      role: user['role'] as String,
    );
  }
}
