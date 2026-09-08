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
    return AuthUser(
      token: json['token'] as String,
      userId: json['userId'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      gender: json['gender'] as String,
      role: json['role'] as String,
    );
  }
}