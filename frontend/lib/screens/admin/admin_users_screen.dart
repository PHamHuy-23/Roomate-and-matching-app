import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_profile_avatar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final ApiService _api;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _users = <Map<String, String>>[];
  bool _isLoading = true;
  String? _error;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getAdminUsers();
      if (!mounted) return;
      setState(() {
        _users = response.whereType<Map>().map(_mapUser).toList();
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
        _error = 'Không thể tải danh sách người dùng, vui lòng thử lại.';
      });
    }
  }

  Map<String, String> _mapUser(Map<dynamic, dynamic> raw) {
    final id = raw['id'] ?? raw['userId'];
    final role = raw['role']?.toString().toUpperCase();
    final status = raw['status']?.toString().toUpperCase();
    final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
    final createdLabel = createdAt == null
        ? '—'
        : '${createdAt.month.toString().padLeft(2, '0')} / ${createdAt.year}';
    return {
      'id': id == null ? '—' : '#$id',
      'userId': id?.toString() ?? '',
      'fullName': raw['fullName']?.toString() ?? 'Chưa đặt tên',
      'email': raw['email']?.toString() ?? 'Chưa có email',
      'role': role == 'ROLE_ADMIN' || role == 'ADMIN'
          ? 'Quản trị viên'
          : 'Thành viên',
      'status': status == 'LOCKED' ? 'Đã khóa' : 'Hoạt động',
      'createdAt': createdLabel,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredUsers {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((user) {
      final searchable = [
        user['fullName'],
        user['email'],
        user['id'],
      ].map((value) => value?.toString().toLowerCase() ?? '');
      return searchable.any((value) => value.contains(query));
    }).toList(growable: false);
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

  Widget _buildUserRow(
    BuildContext context,
    Map<String, String> user,
  ) {
    final name = user['fullName'] ?? 'Chưa đặt tên';
    final email = user['email'] ?? 'Chưa có email';
    final role = user['role'] ?? 'Thành viên';
    final status = user['status'] ?? 'Hoạt động';
    final date = user['createdAt'] ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // User Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          color: Color(0xFF142523),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
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
              ],
            ),
          ),
          // Role
          Expanded(
            flex: 2,
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF142523),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'SourceSansPro',
                color: status == 'Đã khóa' ? Colors.red : const Color(0xFF087E6B),
              ),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF142523),
              ),
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.adminUserDetails,
                  arguments: {
                    'user': user,
                    'onStatusChanged': (String status) {
                      final userId = user['id'];
                      final index = _users.indexWhere(
                        (item) => item['id'] == userId,
                      );
                      if (index == -1) return;
                      setState(() {
                        _users[index] = {
                          ..._users[index],
                          'status': status,
                        };
                      });
                    },
                  },
                );
              },
              child: const Text(
                'Chi tiết →',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SourceSansPro',
                  color: Color(0xFF087E6B),
                ),
              ),
            ),
          ),
        ],
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
                _buildSidebarItem(context, 'Người dùng', isActive: true),
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
                            'Quản lý người dùng',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tìm kiếm, kiểm tra hồ sơ và trạng thái tài khoản',
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
                  
                  // Search
                  Container(
                    width: double.infinity,
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF65746F)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _query = value),
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo tên, email hoặc mã người dùng',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF65746F),
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, color: Color(0xFF65746F)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Table
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Row(
                            children: [
                              Expanded(flex: 3, child: _buildTableHeader('NGƯỜI DÙNG')),
                              Expanded(flex: 2, child: _buildTableHeader('VAI TRÒ')),
                              Expanded(flex: 2, child: _buildTableHeader('TRẠNG THÁI')),
                              Expanded(flex: 2, child: _buildTableHeader('NGÀY TẠO')),
                              Expanded(flex: 1, child: _buildTableHeader('')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE)),
                          
                          // Table Body
                          Expanded(child: _buildTableBody()),
                        ],
                      ),
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

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'SourceSansPro',
        color: Color(0xFF65746F),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTableBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF087E6B)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF65746F)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadUsers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    final users = _filteredUsers;
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy người dùng phù hợp.',
          style: TextStyle(color: Color(0xFF65746F)),
        ),
      );
    }
    return ListView(
      children: [for (final user in users) _buildUserRow(context, user)],
    );
  }
}
