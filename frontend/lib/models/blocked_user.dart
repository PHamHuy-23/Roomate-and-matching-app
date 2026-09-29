class BlockedUser {
  final int id;
  final int blockedUserId;
  final String blockedUserName;
  final String? blockedUserAvatar;
  final String? blockedUserEmail;
  final DateTime? createdAt;

  const BlockedUser({
    required this.id,
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserAvatar,
    this.blockedUserEmail,
    this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as int? ?? 0,
      blockedUserId: json['blockedUserId'] as int? ?? 0,
      blockedUserName: json['blockedUserName'] as String? ?? 'Người dùng',
      blockedUserAvatar: json['blockedUserAvatar'] as String?,
      blockedUserEmail: json['blockedUserEmail'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
