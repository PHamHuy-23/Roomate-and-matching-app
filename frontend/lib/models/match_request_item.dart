class MatchRequestItem {
  final int requestId;
  final int partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final double matchScore;
  String status; // PENDING, ACCEPTED, REJECTED
  final String? createdAt;
  final String? message;
  final String? contactPhone;
  final String? contactEmail;
  final bool? shareZalo;

  MatchRequestItem({
    required this.requestId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.matchScore,
    required this.status,
    this.createdAt,
    this.message,
    this.contactPhone,
    this.contactEmail,
    this.shareZalo,
  });

  factory MatchRequestItem.fromJson(Map<String, dynamic> json) {
    bool? parseShareZalo() {
      final rawShare = json['shareZalo'];
      if (rawShare is bool) return rawShare;
      final rawZalo = json['contactZalo'];
      if (rawZalo is bool) return rawZalo;
      if (rawZalo is String) {
        return rawZalo.trim().isNotEmpty;
      }
      return null;
    }

    return MatchRequestItem(
      requestId: (json['requestId'] as num?)?.toInt() ?? 0,
      partnerId: (json['partnerId'] as num?)?.toInt() ?? 0,
      partnerName: (json['partnerName'] ?? '') as String,
      partnerAvatar: json['partnerAvatar'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? 'PENDING') as String,
      createdAt: json['createdAt']?.toString(),
      message: json['message'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      shareZalo: parseShareZalo(),
    );
  }
}
