import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../utils/file_download_helper.dart';
import '../../widgets/admin_profile_avatar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  bool _isLoadingReports = true;
  String? _error;
  String? _reportError;
  int? _userCount;
  int? _visiblePostCount;
  double? _matchSuccessRate;
  int? _pendingPostCount;
  int? _lockedUserCount;
  int? _pendingReportCount;

  String get _currentFormattedDate {
    final now = DateTime.now();
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayStr = days[(now.weekday - 1) % 7];
    return '$dayStr, ${now.day.toString().padLeft(2, '0')} / ${now.month.toString().padLeft(2, '0')} / ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _isLoadingReports = true;
      _error = null;
      _reportError = null;
      _userCount = null;
      _visiblePostCount = null;
      _pendingPostCount = null;
      _lockedUserCount = null;
      _pendingReportCount = null;
    });
    try {
      final responses = await Future.wait<List<dynamic>>([
        _api.getAdminUsers(),
        _api.getAdminPosts(),
      ]);
      if (!mounted) return;
      final users = responses[0];
      final posts = responses[1];
      setState(() {
        _userCount = users.length;
        _lockedUserCount = users.where((user) {
          return user is Map &&
              user['status']?.toString().toUpperCase() == 'LOCKED';
        }).length;
        _visiblePostCount = posts.where((post) {
          return post is Map && post['publiclyVisible'] == true;
        }).length;
        _pendingPostCount = posts.where((post) {
          if (post is! Map) return false;
          final status = post['status']?.toString().toUpperCase();
          return status == 'PENDING' ||
              status == 'PENDING_REVIEW' ||
              status == 'WAITING_APPROVAL';
        }).length;
        _isLoading = false;
      });

      try {
        final reports = await _api.getAdminReports();
        if (mounted) {
          setState(() {
            _isLoadingReports = false;
            _pendingReportCount = reports.where((r) {
              if (r is! Map) return false;
              return r['status']?.toString().toUpperCase() == 'PENDING';
            }).length;
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLoadingReports = false;
          _reportError =
              'Không thể tải số báo cáo cần xử lý, vui lòng thử lại.';
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingReports = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingReports = false;
        _error = 'Không thể tải số liệu quản trị, vui lòng thử lại.';
      });
    }
  }

  String _statValue(int? value) {
    if (_isLoading) return '…';
    return value?.toString() ?? '—';
  }

  String get _reportValue =>
      _isLoadingReports ? '…' : _pendingReportCount?.toString() ?? '—';

  Widget _buildSidebarItem(
    BuildContext context,
    String title, {
    bool isActive = false,
    String? route,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: isActive
          ? null
          : (onTap ??
                (route == null
                    ? null
                    : () => Navigator.pushReplacementNamed(context, route))),
      borderRadius: BorderRadius.circular(8),
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
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF8FB8AC),
                size: 18,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'SourceSansPro',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertAction(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '$label  →',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF087E6B),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        height: 134,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 37,
                fontWeight: FontWeight.w700,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF087E6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF65746F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportReportsDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3DFDC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F3F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
                      color: Color(0xFF087E6B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xuất báo cáo hệ thống',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        Text(
                          'Tải dữ liệu dưới dạng tệp CSV / Excel',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF65746F),
                            fontFamily: 'SourceSansPro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFECEFF1), height: 1),
              const SizedBox(height: 12),
              _buildExportOption(
                title: '1. Báo cáo Tổng quan hệ thống',
                subtitle: 'Số liệu người dùng, bài đăng, tương tác tổng hợp',
                icon: Icons.dashboard_outlined,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleExportReport(
                    reportType: 'overview',
                    fileName: 'BaoCao_TongQuan_$_fileTimestamp.csv',
                  );
                },
              ),
              _buildExportOption(
                title: '2. Danh sách Thành viên & Trạng thái tài khoản',
                subtitle: 'Toàn bộ danh sách người dùng, trạng thái và vai trò',
                icon: Icons.people_outline,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleExportReport(
                    reportType: 'users',
                    fileName: 'DanhSach_ThanhVien_$_fileTimestamp.csv',
                  );
                },
              ),
              _buildExportOption(
                title: '3. Danh sách Bài đăng & Kiểm duyệt',
                subtitle:
                    'Tin tìm phòng, giá thuê, địa chỉ và trạng thái duyệt',
                icon: Icons.apartment_outlined,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleExportReport(
                    reportType: 'posts',
                    fileName: 'DanhSach_BaiDang_$_fileTimestamp.csv',
                  );
                },
              ),
              _buildExportOption(
                title: '4. Toàn bộ Nhật ký hệ thống (Audit Logs)',
                subtitle: 'Lịch sử thao tác của ban quản trị và hệ thống',
                icon: Icons.receipt_long_outlined,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _handleExportReport(
                    reportType: 'audit-logs',
                    fileName: 'NhatKy_HeThong_$_fileTimestamp.csv',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDCE6E3)),
          ),
          child: Icon(icon, color: const Color(0xFF087E6B), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF65746F),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF8FA09B),
        ),
        onTap: onTap,
      ),
    );
  }

  String get _fileTimestamp {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleExportReport({
    required String reportType,
    required String fileName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Đang tạo báo cáo $fileName...')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final csvString = await _api.exportAdminReport(reportType);
      if (!mounted) return;
      await FileDownloadHelper.downloadCsv(
        context: context,
        fileName: fileName,
        csvContent: csvString,
      );
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Xuất báo cáo thành công ($fileName)'),
          backgroundColor: const Color(0xFF087E6B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xuất báo cáo: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
                  isActive: true,
                  icon: Icons.dashboard_outlined,
                ),
                _buildSidebarItem(
                  context,
                  'Người dùng',
                  route: AppRoutes.adminUsers,
                  icon: Icons.people_outline,
                ),
                _buildSidebarItem(
                  context,
                  'Duyệt tin đăng',
                  route: AppRoutes.adminModeratePost,
                  icon: Icons.approval_outlined,
                ),
                _buildSidebarItem(
                  context,
                  'Báo cáo vi phạm',
                  route: AppRoutes.adminReports,
                  icon: Icons.report_outlined,
                ),
                _buildSidebarItem(
                  context,
                  'Nhật ký hệ thống',
                  route: AppRoutes.adminAuditLogs,
                  icon: Icons.receipt_long_outlined,
                ),
                _buildSidebarItem(
                  context,
                  'Sao lưu & Khôi phục',
                  route: AppRoutes.adminBackup,
                  icon: Icons.cloud_sync_outlined,
                ),

                const Spacer(),

                const Divider(
                  color: Color(0xFF2A3D39),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 8),

                _buildSidebarItem(
                  context,
                  'Về app người dùng',
                  icon: Icons.home_outlined,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.home),
                ),
                _buildSidebarItem(
                  context,
                  'Đăng xuất',
                  icon: Icons.logout,
                  onTap: () async {
                    // Await logout để đảm bảo backend thu hồi token trước khi navigate.
                    await _api.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (r) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                        children: [
                          const Text(
                            'Tổng quan hệ thống',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _currentFormattedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF65746F),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showExportReportsDialog,
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 20,
                            ),
                            label: const Text('Xuất báo cáo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF087E6B),
                              side: const BorderSide(
                                color: Color(0xFF087E6B),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SourceSansPro',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const AdminProfileAvatar(),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (_error != null || _reportError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error ?? _reportError!,
                              style: const TextStyle(color: Color(0xFF7A4A00)),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading || _isLoadingReports
                                ? null
                                : _loadStats,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),

                  // Top Stats
                  Row(
                    children: [
                      _buildStatCard(_statValue(_userCount), 'Người dùng'),
                      _buildStatCard(
                        _matchSuccessRate != null
                            ? '${_matchSuccessRate!.toStringAsFixed(1)}%'
                            : (_isLoading ? '…' : '0%'),
                        'Tỷ lệ ghép đôi',
                      ),
                      _buildStatCard(
                        _statValue(_pendingPostCount),
                        'Tin chờ duyệt',
                      ),
                      _buildStatCard(_reportValue, 'Báo cáo cần xử lý'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Middle Row
                  Row(
                    children: [
                      // Chart
                      Expanded(
                        flex: 6,
                        child: Container(
                          height: 345,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kết nối mới trong tuần',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Chưa hỗ trợ thống kê kết nối theo tuần.\n'
                                    'Hệ thống chưa cung cấp dữ liệu thời điểm kết nối thành công.',
                                    key: Key(
                                      'admin_weekly_connections_unavailable',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF65746F),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Alerts
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 345,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cần bạn xem xét',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildAlertAction(
                                context,
                                '${_statValue(_pendingPostCount)} tin đang chờ duyệt',
                                AppRoutes.adminModeratePost,
                              ),
                              const SizedBox(height: 16),
                              _buildAlertAction(
                                context,
                                _pendingReportCount != null
                                    ? '$_reportValue báo cáo cần xử lý'
                                    : _isLoadingReports
                                    ? 'Đang tải số báo cáo cần xử lý'
                                    : 'Chưa tải được số báo cáo cần xử lý',
                                AppRoutes.adminReports,
                              ),
                              const SizedBox(height: 16),
                              _buildAlertAction(
                                context,
                                '${_statValue(_lockedUserCount)} tài khoản đang khóa',
                                AppRoutes.adminUsers,
                              ),
                              const SizedBox(height: 16),
                              _buildAlertAction(
                                context,
                                '${_statValue(_visiblePostCount)} tin đăng đang hiển thị',
                                AppRoutes.adminModeratePost,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom Row
                  Container(
                    width: double.infinity,
                    height: 145,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nhật ký hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa hỗ trợ nhật ký hoạt động. Hệ thống chưa cung cấp lịch sử thao tác quản trị.',
                          key: Key('admin_activity_log_unavailable'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
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
