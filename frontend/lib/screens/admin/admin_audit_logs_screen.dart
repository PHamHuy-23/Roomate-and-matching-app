import 'package:flutter/material.dart';

import '../../models/audit_log_item.dart';
import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../utils/file_download_helper.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  late final ApiService _api;
  bool _isLoading = true;
  String? _error;
  List<AuditLogItem> _logs = [];

  // Filter state
  String _selectedActionFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return '$dayStr, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExporting = false;

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _api.getAdminAuditLogs();
      if (!mounted) return;
      setState(() {
        _logs = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String get _fileTimestamp {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exportAuditLogsCsv() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final fileName = 'NhatKy_HeThong_$_fileTimestamp.csv';

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
            Expanded(child: Text('Đang tải tệp $fileName...')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final csvString = await _api.exportAdminReport('audit-logs');
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
          content: Text('Lỗi khi xuất CSV nhật ký: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  List<AuditLogItem> get _filteredLogs {
    return _logs.where((log) {
      if (_selectedActionFilter != 'ALL') {
        if (log.action.toUpperCase() != _selectedActionFilter.toUpperCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchEmail = log.actorEmail.toLowerCase().contains(q);
        final matchDetails = (log.details ?? '').toLowerCase().contains(q);
        final matchTargetType = log.targetType.toLowerCase().contains(q);
        final matchTargetId = log.targetId?.toString().contains(q) ?? false;
        final matchAction = log.action.toLowerCase().contains(q);
        if (!matchEmail &&
            !matchDetails &&
            !matchTargetType &&
            !matchTargetId &&
            !matchAction) {
          return false;
        }
      }
      return true;
    }).toList();
  }

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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedActionFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: const Color(0xFF087E6B),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF087E6B) : const Color(0xFFD3E0DC),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF142523),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontFamily: 'SourceSansPro',
        fontSize: 13,
      ),
      onSelected: (_) {
        setState(() {
          _selectedActionFilter = value;
        });
      },
    );
  }

  Color _getActionBadgeColor(String action) {
    final act = action.toUpperCase();
    if (act.contains('LOCK') ||
        act.contains('DELETE') ||
        act.contains('BLOCK')) {
      return const Color(0xFFD32F2F);
    }
    if (act.contains('USER') || act.contains('SET_USER_STATUS')) {
      return const Color(0xFFE65100);
    }
    if (act.contains('POST') || act.contains('MODERATE_POST')) {
      return const Color(0xFF1565C0);
    }
    if (act.contains('REPORT') || act.contains('MODERATE_REPORT')) {
      return const Color(0xFF6A1B9A);
    }
    if (act.contains('BACKUP') || act.contains('RESTORE')) {
      return const Color(0xFF087E6B);
    }
    return const Color(0xFF455A64);
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute:$second';
  }

  Widget _buildAuditCard(AuditLogItem item) {
    final badgeColor = _getActionBadgeColor(item.action);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0EAE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.action,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'SourceSansPro',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.targetType}${item.targetId != null ? ' #${item.targetId}' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF455A64),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SourceSansPro',
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Color(0xFF8FA09B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF65746F),
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                size: 16,
                color: Color(0xFF087E6B),
              ),
              const SizedBox(width: 6),
              Text(
                'Quản trị viên: ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF142523),
                  fontFamily: 'SourceSansPro',
                ),
              ),
              Text(
                item.actorEmail.isNotEmpty
                    ? item.actorEmail
                    : (item.actorId != null ? '#${item.actorId}' : 'Hệ thống'),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF087E6B),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'SourceSansPro',
                ),
              ),
            ],
          ),
          if (item.details != null && item.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8EFEB)),
              ),
              child: Text(
                item.details!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2C3E3A),
                  fontFamily: 'SourceSansPro',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

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
                  route: AppRoutes.adminDashboard,
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
                  isActive: true,
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
                    await _api.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
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
                            'Nhật ký hệ thống (Audit Log)',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentFormattedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF65746F),
                              fontFamily: 'SourceSansPro',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isExporting
                                ? null
                                : _exportAuditLogsCsv,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF087E6B),
                                    ),
                                  )
                                : const Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                  ),
                            label: const Text('Xuất CSV'),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadAuditLogs,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Làm mới'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF087E6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search and quick filter row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Tìm theo Email admin hoặc nội dung nhật ký...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF65746F),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD3E0DC),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD3E0DC),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF087E6B),
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Tất cả', 'ALL'),
                      _buildFilterChip(
                        'Khóa/Mở User (SET_USER_STATUS)',
                        'SET_USER_STATUS',
                      ),
                      _buildFilterChip(
                        'Duyệt bài đăng (MODERATE_POST)',
                        'MODERATE_POST',
                      ),
                      _buildFilterChip(
                        'Xử lý báo cáo (MODERATE_REPORT)',
                        'MODERATE_REPORT',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content Body
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF087E6B),
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF65746F),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadAuditLogs,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF087E6B),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Color(0xFFB0C4BE),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Không có bản ghi nhật ký hệ thống nào.',
                                  style: TextStyle(
                                    color: Color(0xFF65746F),
                                    fontSize: 16,
                                    fontFamily: 'SourceSansPro',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildAuditCard(filtered[index]);
                            },
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
