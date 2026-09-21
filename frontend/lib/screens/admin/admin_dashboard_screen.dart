import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
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
  String? _error;
  int? _userCount;
  int? _visiblePostCount;
  int? _pendingPostCount;
  int? _lockedUserCount;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
          if (post is! Map) return false;
          final status = post['status']?.toString().toUpperCase();
          return status == 'APPROVED' || status == 'AVAILABLE';
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
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải số liệu quản trị, vui lòng thử lại.';
      });
    }
  }

  String _statValue(int? value) {
    if (_isLoading) return '…';
    return value?.toString() ?? '—';
  }

  Widget _buildSidebarItem(
    BuildContext context,
    String title, {
    bool isActive = false,
    String? route,
  }) {
    return InkWell(
      onTap: isActive || route == null
          ? null
          : () => Navigator.pushReplacementNamed(context, route),
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

  Widget _buildAlertAction(
    BuildContext context,
    String label,
    String route,
  ) {
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

  Widget _buildChartBar(String label, double heightRatio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 38,
          height: 220 * heightRatio,
          decoration: BoxDecoration(
            color: const Color(0xFF087E6B),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
          ),
        ),
      ],
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
                _buildSidebarItem(context, 'Tổng quan', isActive: true),
                _buildSidebarItem(context, 'Người dùng', route: AppRoutes.adminUsers),
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
                            'Thứ Bảy, 19 / 09 / 2026 · Dữ liệu minh họa',
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
                  if (_error != null)
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
                              _error!,
                              style: const TextStyle(color: Color(0xFF7A4A00)),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadStats,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  
                  // Top Stats
                  Row(
                    children: [
                      _buildStatCard(_statValue(_userCount), 'Người dùng'),
                      _buildStatCard(_statValue(_visiblePostCount), 'Tin đang hiển thị'),
                      _buildStatCard(_statValue(_pendingPostCount), 'Tin chờ duyệt'),
                      _buildStatCard('—', 'Báo cáo cần xử lý'),
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
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildChartBar('T2', 90/220),
                                  _buildChartBar('T3', 138/220),
                                  _buildChartBar('T4', 110/220),
                                  _buildChartBar('T5', 189/220),
                                  _buildChartBar('T6', 162/220),
                                  _buildChartBar('T7', 220/220),
                                  _buildChartBar('CN', 184/220),
                                ],
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
                                'Báo cáo chưa có API',
                                AppRoutes.adminReports,
                              ),
                              const SizedBox(height: 16),
                              _buildAlertAction(
                                context,
                                '${_statValue(_lockedUserCount)} tài khoản đang khóa',
                                AppRoutes.adminUsers,
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
                          '14:32  ·  Tin RH-024 được duyệt       14:10  ·  Báo cáo BC-028 được tiếp nhận',
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
