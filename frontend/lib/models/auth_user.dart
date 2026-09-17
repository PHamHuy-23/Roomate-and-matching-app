class AuthUser {
  static const Object _sentinel = Object();

  final String token;
  final int userId;
  final String email;
  final String fullName;
  final String gender;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? university;

  AuthUser({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.birthDate,
    this.university,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    final user = nestedUser is Map<String, dynamic> ? nestedUser : json;
    final tokenValue = json['accessToken'] ?? json['token'];
    if (tokenValue is! String || tokenValue.isEmpty) {
      throw const FormatException('Auth response không chứa access token');
    }

    final rawPhone = user['phone'] ?? json['phone'];
    final rawAvatar = user['avatarUrl'] ?? json['avatarUrl'];

    return AuthUser(
      token: tokenValue,
      userId: (user['id'] ?? user['userId']) as int,
      email: user['email'] as String,
      fullName: user['fullName'] as String,
      gender: (user['gender'] as String?) ?? 'MALE',
      role: (user['role'] as String?) ?? 'ROLE_USER',
      phone: rawPhone is String && rawPhone.isNotEmpty ? rawPhone : null,
      avatarUrl: rawAvatar is String && rawAvatar.isNotEmpty ? rawAvatar : null,
      birthDate: user['birthDate'] is String
          ? DateTime.tryParse(user['birthDate'] as String)
          : null,
      university: user['university'] as String?,
    );
  }

  AuthUser copyWith({
    String? token,
    int? userId,
    String? email,
    String? fullName,
    String? gender,
    String? role,
    Object? phone = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? birthDate = _sentinel,
    Object? university = _sentinel,
  }) {
    return AuthUser(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      phone: identical(phone, _sentinel) ? this.phone : (phone as String?),
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : (avatarUrl as String?),
      birthDate: identical(birthDate, _sentinel)
          ? this.birthDate
          : (birthDate as DateTime?),
      university: identical(university, _sentinel)
          ? this.university
          : (university as String?),
    );
  }
}
