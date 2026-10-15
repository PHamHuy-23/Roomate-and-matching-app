import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_profile_avatar.dart';

class _AdminReport {
  const _AdminReport({
    required this.rawId,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.sender,
    required this.note,
    this.status = 'PENDING',
    this.evidenceUrl,
  });

  final int rawId;
  final String id;
  final String title;
  final String subtitle;
  final String reason;
  final String sender;
  final String note;
  final String status;
  final String? evidenceUrl;
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, this.apiService});
  final ApiService? apiService;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ApiService get _api => widget.apiService ?? ApiService();
  bool _isLoading = false;
  bool _isResolving = false;
  bool _isEditingNote = false;
  bool _isRefreshingEvidence = false;
  int _loadVersion = 0;
  String? _selectedEvidenceUrl;
  String? _evidenceError;
  final _noteController = TextEditingController();
  final Map<int, String> _noteDrafts = {};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<_AdminReport> _reports = [];
  String? _loadError;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({int? selectedReportId}) async {
    final loadVersion = ++_loadVersion;
    final refresh = _reports.isNotEmpty;
    final requestedId =
        selectedReportId ??
        (_selectedReport.rawId > 0 ? _selectedReport.rawId : null);
    if (!_api.hasAuthToken) {
      setState(() {
        _selectedEvidenceUrl = null;
        _evidenceError = 'Cần đăng nhập lại để tải báo cáo.';
        _loadError = _evidenceError;
        _isLoading = false;
        _isRefreshingEvidence = false;
      });
      return;
    }
    setState(() {
      _isLoading = !refresh;
      _isRefreshingEvidence = refresh;
      // Do not keep using a cached bearer URL while its replacement is loading.
      _selectedEvidenceUrl = null;
      _evidenceError = null;
    });
    try {
      final list = await _api.getAdminReports();
      if (!mounted || loadVersion != _loadVersion) return;
      final loaded = list.map((item) {
        final map = item as Map<String, dynamic>;
        final rawId = map['id'] is int
            ? map['id'] as int
            : int.tryParse(map['id'].toString()) ?? 0;
        if (rawId <= 0) throw const FormatException('Mã báo cáo không hợp lệ');
        final targetType = map['targetType']?.toString() ?? 'USER';
        final targetId = map['targetId']?.toString() ?? '0';
        final reason = map['reason']?.toString() ?? 'Không rõ lý do';
        final sender = map['reporterName']?.toString() ?? 'Thành viên ẩn danh';
        final status = map['status']?.toString() ?? 'UNKNOWN';
        final note =
            map['actionNote']?.toString() ??
            (status == 'RESOLVED'
                ? 'Đã xử lý vi phạm.'
                : 'Đang chờ quản trị viên kiểm tra nội dung.');
        final prefix = targetType == 'ROOM_POST'
            ? 'Tin RH-$targetId'
            : 'Người dùng #$targetId';
        final statusVi = status == 'RESOLVED'
            ? 'Đã xử lý'
            : status == 'DISMISSED'
            ? 'Đã bác bỏ'
            : status == 'PENDING'
            ? 'Đang chờ'
            : 'Chưa rõ trạng thái';
        final evidenceUrl = map['evidenceUrl']?.toString();
        return _AdminReport(
          rawId: rawId,
          id: 'BC-${rawId.toString().padLeft(3, '0')}',
          title: reason.length > 25 ? '${reason.substring(0, 25)}...' : reason,
          subtitle: '$prefix · $statusVi',
          reason: reason,
          sender: sender,
          note: note,
          status: status,
          evidenceUrl: evidenceUrl,
        );
      }).toList();

      setState(() {
        _reports = loaded;
        _loadError = null;
        _selectedIndex = requestedId == null
            ? (loaded.isEmpty ? -1 : 0)
            : loaded.indexWhere((report) => report.rawId == requestedId);
        if (_selectedIndex >= 0) {
          final url = loaded[_selectedIndex].evidenceUrl;
          _evidenceError = _evidenceUrlError(url);
          _selectedEvidenceUrl = _evidenceError == null ? url : null;
        } else if (requestedId != null) {
          _evidenceError = 'Báo cáo đã chọn không còn trong danh sách.';
          _loadError = _evidenceError;
        }
        _isLoading = false;
        _isRefreshingEvidence = false;
      });
    } catch (e) {
      if (mounted && loadVersion == _loadVersion) {
        setState(() {
          _selectedEvidenceUrl = null;
          if (refresh) {
            _evidenceError = 'Không làm mới được bằng chứng: $e';
          } else {
            _reports = [];
            _loadError = 'Không tải được báo cáo: $e';
          }
          _isLoading = false;
          _isRefreshingEvidence = false;
        });
      }
    }
  }

  _AdminReport get _selectedReport =>
      _reports.isNotEmpty &&
          _selectedIndex >= 0 &&
          _selectedIndex < _reports.length
      ? _reports[_selectedIndex]
      : _AdminReport(
          rawId: 0,
          id: 'BC-000',
          title: 'Không có báo cáo',
          subtitle: '',
          reason: _loadError ?? 'Hiện chưa có báo cáo vi phạm nào.',
          sender: '',
          note: '',
        );

  Widget _buildSidebarItem(
    BuildContext context,
    String title, {
    bool isActive = false,
    String? route,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive && route != null) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        width: double.infinity,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF087E6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'SourceSansPro',
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(_AdminReport report, {required bool isActive}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('admin_report_${report.id}'),
        onTap: () {
          setState(() => _selectedIndex = _reports.indexOf(report));
          _loadReports(selectedReportId: report.rawId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEAF8F5) : const Color(0xFFF5F8F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${report.id} · ${report.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SourceSansPro',
                  color: Color(0xFF142523),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'SourceSansPro',
                  color: Color(0xFF65746F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidence() {
    if (_isLoading || _isRefreshingEvidence) {
      return const Center(
        child: CircularProgressIndicator(key: Key('admin_evidence_loading')),
      );
    }
    final evidenceError =
        _evidenceError ?? _evidenceUrlError(_selectedEvidenceUrl);
    if (evidenceError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            evidenceError,
            key: const Key('admin_evidence_error'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }
    final url = _selectedEvidenceUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        key: ValueKey('admin_evidence_$url'),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 32, color: Colors.grey),
              const Text(
                'Ảnh lỗi hoặc liên kết đã hết hạn.',
                style: TextStyle(fontSize: 12),
              ),
              TextButton(
                key: const Key('admin_evidence_retry'),
                onPressed: () =>
                    _loadReports(selectedReportId: _selectedReport.rawId),
                child: const Text('Tải lại ảnh'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 36,
            color: Colors.grey,
          ),
          SizedBox(height: 4),
          Text(
            'Không có ảnh đính kèm',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String? _evidenceUrlError(String? value) {
    if (value == null || value.isEmpty) return null;
    const invalid = 'Liên kết ảnh không hợp lệ. Hãy làm mới ảnh.';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        uri.path.isEmpty) {
      return invalid;
    }
    final query = uri.queryParametersAll;
    if ([
      'X-Amz-Signature',
      'X-Amz-Date',
      'X-Amz-Expires',
    ].any((key) => query[key]?.length != 1)) {
      return invalid;
    }
    final signature = query['X-Amz-Signature']!.single;
    final timestamp = query['X-Amz-Date']!.single;
    final expires = int.tryParse(query['X-Amz-Expires']!.single);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(signature) ||
        !RegExp(r'^\d{8}T\d{6}Z$').hasMatch(timestamp) ||
        expires == null ||
        expires < 60 ||
        expires > 300) {
      return invalid;
    }
    final signedAt = DateTime.tryParse(
      '${timestamp.substring(0, 4)}-${timestamp.substring(4, 6)}-'
      '${timestamp.substring(6, 8)}T${timestamp.substring(9, 11)}:'
      '${timestamp.substring(11, 13)}:${timestamp.substring(13, 15)}Z',
    );
    if (signedAt == null ||
        signedAt.year != int.parse(timestamp.substring(0, 4)) ||
        signedAt.month != int.parse(timestamp.substring(4, 6)) ||
        signedAt.day != int.parse(timestamp.substring(6, 8)) ||
        signedAt.hour != int.parse(timestamp.substring(9, 11)) ||
        signedAt.minute != int.parse(timestamp.substring(11, 13)) ||
        signedAt.second != int.parse(timestamp.substring(13, 15))) {
      return invalid;
    }
    if (!signedAt
        .add(Duration(seconds: expires))
        .isAfter(DateTime.now().toUtc())) {
      return 'Liên kết ảnh đã hết hạn. Hãy làm mới ảnh.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 224,
            color: const Color(0xFF142523),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 34, 28, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'RH / Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SourceSansPro',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ROOMMATE HUB',
                        style: TextStyle(
                          color: Color(0xFF8FB8AC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(
                  context,
                  'Tổng quan',
                  route: '/admin/dashboard',
                ),
                _buildSidebarItem(context, 'Người dùng', route: '/admin/users'),
                _buildSidebarItem(
                  context,
                  'Duyệt tin đăng',
                  route: '/admin/moderate-post',
                ),
                _buildSidebarItem(context, 'Báo cáo vi phạm', isActive: true),

                const Spacer(),

                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Text(
                    'Không gian quản trị',
                    style: TextStyle(
                      color: Color(0xFF8FB8AC),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Báo cáo vi phạm',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ưu tiên xử lý các báo cáo về an toàn và thông tin sai',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF65746F),
                            ),
                          ),
                        ],
                      ),
                      const AdminProfileAvatar(),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Two columns
                  SizedBox(
                    height: 620,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column (List)
                        Expanded(
                          flex: 48, // approx 480 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Tất cả báo cáo',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'SourceSansPro',
                                        color: Color(0xFF142523),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLoading || _loadError != null
                                          ? 'Đang chờ: —'
                                          : 'Đang chờ: ${_reports.where((report) => report.status == 'PENDING').length}',
                                      key: const Key(
                                        'admin_pending_report_count',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF65746F),
                                      ),
                                    ),

                                    if (_isLoading) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: _reports.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Chưa có báo cáo vi phạm nào.',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF65746F),
                                              fontFamily: 'SourceSansPro',
                                            ),
                                          ),
                                        )
                                      : ListView(
                                          children: [
                                            for (
                                              var index = 0;
                                              index < _reports.length;
                                              index++
                                            )
                                              _buildReportItem(
                                                _reports[index],
                                                isActive:
                                                    index == _selectedIndex,
                                              ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Column (Details)
                        Expanded(
                          flex: 52, // approx 520 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedReport.id} / Chi tiết báo cáo',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Lý do: ${_selectedReport.reason}\nNgười gửi: ${_selectedReport.sender}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 224,
                                    height: 147,
                                    color: Colors.grey.shade300,
                                    child: _buildEvidence(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Bằng chứng đính kèm',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'SourceSansPro',
                                          color: Color(0xFF65746F),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      key: const Key('admin_evidence_refresh'),
                                      style: TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed:
                                          _isLoading || _isRefreshingEvidence
                                          ? null
                                          : () => _loadReports(),
                                      child: const Text('Làm mới ảnh'),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  'Ghi chú xử lý',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F8F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedReport.note,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF142523),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    key: const Key('admin_resolve_report'),
                                    onPressed:
                                        _isResolving ||
                                            _isEditingNote ||
                                            _selectedReport.rawId <= 0 ||
                                            _selectedReport.status != 'PENDING'
                                        ? null
                                        : () async {
                                            if (_isResolving ||
                                                _isEditingNote) {
                                              return;
                                            }
                                            final reportId =
                                                _selectedReport.rawId;
                                            setState(
                                              () => _isEditingNote = true,
                                            );
                                            final noteController =
                                                _noteController
                                                  ..text =
                                                      _noteDrafts[reportId] ??
                                                      '';
                                            final note = await showDialog<String>(
                                              context: context,
                                              builder: (dialogContext) =>
                                                  AlertDialog(
                                                    title: const Text(
                                                      'Kết quả xem xét báo cáo',
                                                    ),
                                                    content: TextField(
                                                      controller:
                                                          noteController,
                                                      maxLines: 3,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Ghi rõ kết quả và hành động thực tế đã thực hiện',
                                                          ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                            ),
                                                        child: const Text(
                                                          'Hủy',
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () {
                                                          if (noteController
                                                              .text
                                                              .trim()
                                                              .isNotEmpty) {
                                                            Navigator.pop(
                                                              dialogContext,
                                                              noteController
                                                                  .text
                                                                  .trim(),
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Lưu kết quả',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            // The dialog owns the controller until its closing animation ends.
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            _noteDrafts[reportId] =
                                                noteController.text;
                                            setState(
                                              () => _isEditingNote = false,
                                            );
                                            if (note == null) return;
                                            setState(() => _isResolving = true);
                                            try {
                                              if (reportId > 0) {
                                                final saved = await _api
                                                    .moderateAdminReport(
                                                      reportId,
                                                      status: 'RESOLVED',
                                                      note: note,
                                                    );
                                                if (!saved) {
                                                  throw const ApiException(
                                                    'Chưa xác nhận lưu kết quả báo cáo',
                                                  );
                                                }
                                              }
                                              if (!mounted ||
                                                  !context.mounted) {
                                                return;
                                              }
                                              _noteDrafts.remove(reportId);
                                              Navigator.pushReplacementNamed(
                                                context,
                                                AppRoutes.adminReportResolved,
                                              );
                                            } catch (e) {
                                              if (!mounted ||
                                                  !context.mounted) {
                                                return;
                                              }
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Lỗi: $e'),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _isResolving = false,
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF087E6B),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isResolving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Đánh dấu đã xử lý',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'SourceSansPro',
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
