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

  List<dynamic> _posts = [];
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final posts = await _api.getAdminPosts();
    final users = await _api.getAdminUsers();
    if (mounted) {
      setState(() {
        _posts = posts;
        _users = users;
        _isLoading = false;
      });
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
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
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
                                              onPressed: () async {
                                                await _api.moderatePost(p['id'], 'REJECTED');
                                                _loadData();
                                              },
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Từ chối / Khóa'),
                                            ),
                                          const SizedBox(width: 8),
                                          if (status != 'APPROVED' && status != 'AVAILABLE')
                                            ElevatedButton(
                                              onPressed: () async {
                                                await _api.moderatePost(p['id'], 'APPROVED');
                                                _loadData();
                                              },
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
                            itemCount: _users.length,
                            itemBuilder: (context, i) {
                              final u = _users[i];
                              final isLocked = 'LOCKED'.equalsIgnoreCase(u['status']?.toString());
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isLocked ? Colors.red.shade100 : Colors.indigo.shade100,
                                    child: Icon(
                                      isLocked ? Icons.lock : Icons.person,
                                      color: isLocked ? Colors.red : Colors.indigo,
                                    ),
                                  ),
                                  title: Text(u['fullName'] ?? 'Chưa đặt tên',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${u['email']} | SĐT: ${u['phone'] ?? 'Chưa có'}\nQuyền: ${u['role']}'),
                                  trailing: ElevatedButton(
                                    onPressed: () async {
                                      await _api.toggleUserStatus(u['id']);
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLocked ? Colors.green : Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(isLocked ? 'Mở Khóa' : 'Khóa'),
                                  ),
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

extension StringIgnoreCase on String {
  bool equalsIgnoreCase(String? other) => toLowerCase() == other?.toLowerCase();
}