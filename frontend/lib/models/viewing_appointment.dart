class ViewingAppointment {
  final int id;
  final int requesterId;
  final String requesterName;
  final String? requesterPhone;
  final String? requesterAvatar;

  final int hostId;
  final String hostName;
  final String? hostPhone;
  final String? hostAvatar;

  final int roomPostId;
  final String roomTitle;
  final String roomAddress;
  final double roomPrice;

  final DateTime appointmentTime;
  final String status;
  final String? note;
  final DateTime createdAt;

  const ViewingAppointment({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhone,
    this.requesterAvatar,
    required this.hostId,
    required this.hostName,
    this.hostPhone,
    this.hostAvatar,
    required this.roomPostId,
    required this.roomTitle,
    required this.roomAddress,
    required this.roomPrice,
    required this.appointmentTime,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory ViewingAppointment.fromJson(Map<String, dynamic> json) {
    return ViewingAppointment(
      id: (json['id'] as num).toInt(),
      requesterId: (json['requesterId'] as num).toInt(),
      requesterName: (json['requesterName'] as String?) ?? 'Người dùng',
      requesterPhone: json['requesterPhone'] as String?,
      requesterAvatar: json['requesterAvatar'] as String?,
      hostId: (json['hostId'] as num).toInt(),
      hostName: (json['hostName'] as String?) ?? 'Chủ phòng',
      hostPhone: json['hostPhone'] as String?,
      hostAvatar: json['hostAvatar'] as String?,
      roomPostId: (json['roomPostId'] as num).toInt(),
      roomTitle: (json['roomTitle'] as String?) ?? 'Phòng trọ',
      roomAddress: (json['roomAddress'] as String?) ?? '',
      roomPrice: (json['roomPrice'] as num?)?.toDouble() ?? 0.0,
      appointmentTime: DateTime.parse(json['appointmentTime'] as String),
      status: (json['status'] as String?) ?? 'PENDING',
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
