import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final TextEditingController _userSearchController = TextEditingController();

  List<dynamic> _posts = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _userQuery = '';

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredUsers {
    final query = _userQuery.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((user) {
      if (user is! Map) return false;
      final values = [
        user['fullName'],
        user['email'],
        user['id'],
      ].map((value) => value?.toString().toLowerCase() ?? '');
      return values.any((value) => value.contains(query));
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final posts = await _api.getAdminPosts();
      final users = await _api.getAdminUsers();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _users = users;
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
        _error = 'Không thể tải dữ liệu quản trị, vui lòng thử lại.';
      });
    }
  }

  Future<void> _moderatePost(int? postId, String status) async {
    if (postId == null) return;
    try {
      await _api.moderatePost(postId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'APPROVED'
                ? 'Đã phê duyệt bài đăng.'
                : 'Đã từ chối bài đăng.',
          ),
        ),
      );
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật bài đăng, vui lòng thử lại.'),
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'APPROVED':
      case 'AVAILABLE':
        bg = Colors.green;
        label = 'Đã duyệt';
        break;
      case 'REJECTED':
        bg = Colors.red;
        label = 'Từ chối';
        break;
      default:
        bg = Colors.orange;
        label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bảng Quản Trị (Admin Panel)'),
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            tabs: [
              Tab(icon: Icon(Icons.rate_review), text: 'Duyệt Bài Đăng'),
              Tab(icon: Icon(Icons.manage_accounts), text: 'Người Dùng'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 44),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loadData,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
            : TabBarView(
                children: [
                  // TAB 1: DUYỆT BÀI ĐĂNG
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _posts.isEmpty
                        ? const Center(child: Text('Không có bài đăng nào'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _posts.length,
                            itemBuilder: (context, i) {
                              final p = _posts[i];
                              final status = p['status'] ?? 'PENDING';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(p['title'] ?? '',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Giá: ${fmt.format(p['price'] ?? 0)}/tháng',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      Text('Địa chỉ: ${p['address'] ?? ''}', style: const TextStyle(fontSize: 13)),
                                      Text('Mô tả: ${p['description'] ?? ''}',
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (status != 'REJECTED')
                                            OutlinedButton(
                                              onPressed: () => _moderatePost(
                                                p['id'] as int?,
                                                'REJECTED',
                                              ),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Từ chối / Khóa'),
                                            ),
                                          const SizedBox(width: 8),
                                          if (status != 'APPROVED' && status != 'AVAILABLE')
                                            ElevatedButton(
                                              onPressed: () => _moderatePost(
                                                p['id'] as int?,
                                                'APPROVED',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green, foregroundColor: Colors.white),
                                              child: const Text('Phê Duyệt'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // TAB 2: QUẢN LÝ NGƯỜI DÙNG
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: _users.isEmpty
                        ? const Center(child: Text('Không có tài khoản nào'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredUsers.length +
                                1 +
                                (_filteredUsers.isEmpty ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextField(
                                    controller: _userSearchController,
                                    onChanged: (value) =>
                                        setState(() => _userQuery = value),
                                    decoration: InputDecoration(
                                      hintText: 'Tìm theo tên, email hoặc mã người dùng',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _userQuery.isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: 'Xóa tìm kiếm',
                                              onPressed: () {
                                                _userSearchController.clear();
                                                setState(() => _userQuery = '');
                                              },
                                              icon: const Icon(Icons.close),
                                            ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (_filteredUsers.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Không tìm thấy tài khoản phù hợp.'),
                                );
                              }
                              final u = _filteredUsers[i - 1];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: const Icon(Icons.person, color: Colors.indigo),
                                  ),
                                  title: Text(u['fullName'] ?? 'Chưa đặt tên',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${u['email']} | SĐT: ${u['phone'] ?? 'Chưa có'}\nQuyền: ${u['role']}'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
