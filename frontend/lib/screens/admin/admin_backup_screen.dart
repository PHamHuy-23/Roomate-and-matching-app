import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../navigation/app_routes.dart';

class AdminBackupScreen extends StatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  State<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends State<AdminBackupScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  List<dynamic> _backups = [];

  @override
  void initState() {
    super.initState();
    _fetchBackups();
  }

  Future<void> _fetchBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getAdminBackups();
      if (!mounted) return;
      setState(() {
        _backups = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerBackup() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _apiService.triggerAdminBackup();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _successMessage = 'Đã tạo bản sao lưu thành công: ${res['fileName'] ?? ''}';
      });
      await _fetchBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmResetDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Khôi phục dữ liệu Demo'),
          ],
        ),
        content: const Text(
          'Hành động này sẽ khôi phục trạng thái chuẩn sạch ban đầu của hệ thống:\n'
          '• Mở khóa tài khoản demo và reset số lần sai.\n'
          '• Khôi phục trạng thái APPROVED cho 8 bài đăng mẫu.\n'
          '• Dọn dẹp các yêu cầu ghép đôi và lịch hẹn phát sinh.\n\n'
          'Bạn có chắc chắn muốn thực hiện ngay không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087E6B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executeResetDemo();
    }
  }

  Future<void> _executeResetDemo() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _apiService.resetDemoState();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _successMessage = res['message']?.toString() ?? 'Đã khôi phục dữ liệu Demo thành công!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmRestoreBackup(String backupId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận khôi phục'),
        content: Text('Bạn có chắc muốn khôi phục dữ liệu từ bản sao lưu "$fileName" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087E6B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final res = await _apiService.restoreAdminBackup(backupId);
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _successMessage = res['message']?.toString() ?? 'Khôi phục dữ liệu thành công!';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildSidebarItem(BuildContext context, String title, {bool isActive = false, String? route, IconData? icon}) {
    return InkWell(
      onTap: isActive
          ? null
          : (route == null ? null : () => Navigator.pushReplacementNamed(context, route)),
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
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF142523),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Roommate Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ),
                _buildSidebarItem(
                  context,
                  'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  route: AppRoutes.adminDashboard,
                ),
                _buildSidebarItem(
                  context,
                  'Quản lý tin đăng',
                  icon: Icons.article_outlined,
                  route: AppRoutes.adminModeratePost,
                ),
                _buildSidebarItem(
                  context,
                  'Người dùng',
                  icon: Icons.people_outline,
                  route: AppRoutes.adminUsers,
                ),
                _buildSidebarItem(
                  context,
                  'Báo cáo & Khiếu nại',
                  icon: Icons.report_problem_outlined,
                  route: AppRoutes.adminReports,
                ),
                _buildSidebarItem(
                  context,
                  'Nhật ký hệ thống',
                  icon: Icons.receipt_long_outlined,
                  route: AppRoutes.adminAuditLogs,
                ),
                _buildSidebarItem(
                  context,
                  'Sao lưu & Khôi phục',
                  icon: Icons.cloud_sync_outlined,
                  isActive: true,
                ),
                const Spacer(),
                const Divider(color: Color(0x33FFFFFF)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF087E6B),
                        child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản trị viên',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'admin@roommatehub.com',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sao lưu & Khôi phục Dữ liệu',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quản lý sao lưu định kỳ hàng ngày (Daily) và khôi phục nhanh trạng thái phục vụ Demo.',
                            style: TextStyle(color: Color(0xFF65746F), fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isProcessing ? null : _confirmResetDemo,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Khôi phục dữ liệu Demo'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF087E6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isProcessing ? null : _triggerBackup,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: const Text('Tạo bản sao lưu ngay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(color: Color(0xFF087E6B)),
                    ),

                  if (_successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.schedule, color: Color(0xFF087E6B), size: 32),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lịch sao lưu tự động',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hàng ngày lúc 00:00 (Daily Cron Scheduled)',
                                    style: TextStyle(color: Color(0xFF65746F), fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_done_outlined, color: Colors.blue, size: 32),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vị trí lưu trữ dữ liệu',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cloudflare R2 Bucket (roommate-hub-private)',
                                    style: TextStyle(color: Color(0xFF65746F), fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Table of backups
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh sách các bản sao lưu đã tạo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SourceSansPro',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: Color(0xFF087E6B)),
                            ),
                          )
                        else if (_backups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Chưa có bản sao lưu nào được ghi nhận.'),
                            ),
                          )
                        else
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Tên file sao lưu', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Loại sao lưu', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Dung lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Thời điểm tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _backups.map((bk) {
                              final id = bk['id']?.toString() ?? '';
                              final fileName = bk['fileName']?.toString() ?? 'backup.sql.gz';
                              final isDaily = bk['backupType'] == 'DAILY_AUTO';
                              final size = bk['sizeFormatted']?.toString() ?? '—';
                              final createdAt = bk['createdAt']?.toString() ?? '—';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Icon(
                                          isDaily ? Icons.schedule : Icons.fingerprint,
                                          size: 18,
                                          color: isDaily ? Colors.blue : Colors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDaily ? Colors.blue.shade50 : Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isDaily ? 'Tự động hàng ngày' : 'Thủ công',
                                        style: TextStyle(
                                          color: isDaily ? Colors.blue.shade700 : Colors.teal.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(size)),
                                  DataCell(Text(createdAt)),
                                  DataCell(
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF087E6B),
                                        side: const BorderSide(color: Color(0xFF087E6B)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: _isProcessing ? null : () => _confirmRestoreBackup(id, fileName),
                                      icon: const Icon(Icons.settings_backup_restore, size: 16),
                                      label: const Text('Khôi phục bản này'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
