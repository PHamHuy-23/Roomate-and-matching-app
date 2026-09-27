class UploadTicket {
  const UploadTicket({
    required this.uploadUrl,
    required this.publicUrl,
    required this.objectKey,
    required this.contentType,
    required this.expiresInSeconds,
  });

  final String uploadUrl;
  final String publicUrl;
  final String objectKey;
  final String contentType;
  final int expiresInSeconds;

  factory UploadTicket.fromJson(Map<String, dynamic> json) {
    return UploadTicket(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      publicUrl: json['publicUrl'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 0,
    );
  }
}
