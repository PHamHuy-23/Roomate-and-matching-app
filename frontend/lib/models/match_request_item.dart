class MatchRequestItem {
  final int requestId;
  final int partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final double matchScore;
  String status; // PENDING, ACCEPTED, REJECTED
  final String? createdAt;
  final String? contactPhone;
  final String? contactEmail;

  MatchRequestItem({
    required this.requestId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.matchScore,
    required this.status,
    this.createdAt,
    this.contactPhone,
    this.contactEmail,
  });

  factory MatchRequestItem.fromJson(Map<String, dynamic> json) {
    return MatchRequestItem(
      requestId: json['requestId'] as int,
      partnerId: json['partnerId'] as int,
      partnerName: json['partnerName'] as String,
      partnerAvatar: json['partnerAvatar'] as String?,
      matchScore: (json['matchScore'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
    );
  }
}