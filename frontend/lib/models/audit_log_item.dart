class AuditLogItem {
  final int id;
  final int? actorId;
  final String actorEmail;
  final String action;
  final String targetType;
  final int? targetId;
  final String? details;
  final DateTime createdAt;

  const AuditLogItem({
    required this.id,
    this.actorId,
    required this.actorEmail,
    required this.action,
    required this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return AuditLogItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      actorId: json['actorId'] is num ? (json['actorId'] as num).toInt() : null,
      actorEmail: json['actorEmail']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId'] is num ? (json['targetId'] as num).toInt() : null,
      details: json['details']?.toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
