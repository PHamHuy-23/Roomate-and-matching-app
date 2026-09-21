import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_profile_avatar.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({
    super.key,
    this.user,
    this.onStatusChanged,
    this.onToggleStatus,
  });

  final Map<String, String>? user;
  final ValueChanged<String>? onStatusChanged;
  final Future<void> Function(int userId)? onToggleStatus;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  final ApiService _api = ApiService();
  late String _status;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _status = widget.user?['status'] ?? 'Đã khóa';
  }

  String get _userName => widget.user?['fullName'] ?? 'Tài khoản #028';
  String get _userEmail => widget.user?['email'] ?? 'user28@example.com';
  String get _userId => widget.user?['id'] ?? '#028';
  bool get _isLocked => _status == 'Đã khóa';

  void _handleStatusChanged(String status) {
    if (!mounted) return;
    setState(() => _status = status);
    widget.onStatusChanged?.call(status);
  }

  int? get _numericUserId {
    final rawId = widget.user?['userId'] ?? widget.user?['id'];
    if (rawId == null) return null;
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits);
  }

  Future<void> _unlockAccount() async {
    final userId = _numericUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được tài khoản cần mở khóa.'),
        ),
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);
    try {
      await (widget.onToggleStatus ?? _api.toggleUserStatus)(userId);
      if (!mounted) return;
      _handleStatusChanged('Hoạt động');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã mở khóa tài khoản.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở khóa tài khoản, vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Widget _buildSidebarItem(BuildContext context, String title, {bool isActive = false, String? route}) {
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
                _buildSidebarItem(context, 'Tổng quan', route: '/admin/dashboard'),
                _buildSidebarItem(context, 'Người dùng', isActive: true, route: '/admin/users'),
                _buildSidebarItem(context, 'Duyệt tin đăng', route: AppRoutes.adminModeratePost),
                _buildSidebarItem(context, 'Báo cáo vi phạm', route: AppRoutes.adminReports),
                
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
                        children: const [
                          Text(
                            'Chi tiết người dùng',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kiểm tra thông tin trước khi thay đổi quyền truy cập',
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
                  
                  // Profile Overview Card
                  Container(
                    width: double.infinity,
                    height: 170,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF142523),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '$_userEmail · Vai trò: ${widget.user?['role'] ?? 'Thành viên'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF142523),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isLocked
                                  ? 'Đã xác minh email · Đã khóa'
                                  : 'Đã xác minh email · Hoạt động',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SourceSansPro',
                                color: _isLocked
                                    ? Colors.red
                                    : Color(0xFF087E6B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom Row
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 62, // approx 618 width
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
                                  'Thông tin tài khoản',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'Mã tài khoản: $_userId\nTham gia: 08 / 2025\nKhu vực: Bình Thạnh\nTin đã đăng: 3\nBáo cáo vi phạm: 0',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                    height: 1.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // Right Column
                        Expanded(
                          flex: 38, // approx 378 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thao tác quản trị',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isLocked
                                      ? 'Mở khóa tài khoản để người dùng\ntiếp tục đăng nhập và sử dụng dịch vụ'
                                      : 'Khóa tài khoản sẽ ngăn người dùng\nđăng nhập và sử dụng dịch vụ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                    height: 1.4,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () {
                                            if (_isLocked) {
                                              _unlockAccount();
                                            } else {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.adminConfirmLock,
                                                arguments: {
                                                  'user': widget.user,
                                                  'onStatusChanged':
                                                      _handleStatusChanged,
                                                },
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLocked
                                          ? const Color(0xFF087E6B)
                                          : const Color(0xFFEAF8F5),
                                      foregroundColor: _isLocked
                                          ? Colors.white
                                          : const Color(0xFF087E6B),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isUpdatingStatus
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF087E6B),
                                            ),
                                          )
                                        : Text(
                                            _isLocked
                                                ? 'Mở khóa tài khoản'
                                                : 'Khóa tài khoản',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'SourceSansPro',
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF087E6B),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Trở về danh sách',
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
