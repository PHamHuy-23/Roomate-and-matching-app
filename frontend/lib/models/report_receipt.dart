/// A confirmed report receipt, not a locally invented tracking number.
class ReportReceipt {
  const ReportReceipt._(this.reportId);

  final int reportId;
  String get code => 'BC-${reportId.toString().padLeft(3, '0')}';

  factory ReportReceipt.fromJson(Map<String, dynamic> json) {
    final id = json['reportId'];
    if (id is! int || id <= 0 || json['status'] != 'PENDING') {
      throw const FormatException(
        'Máy chủ chưa trả mã tiếp nhận báo cáo hợp lệ',
      );
    }
    return ReportReceipt._(id);
  }
}
