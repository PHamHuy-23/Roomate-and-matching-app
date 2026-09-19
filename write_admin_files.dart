import 'dart:io';

void main() {
  final adminScreenCode = r'''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';

class AdminScreen extends StatefulWidget {
  final ApiService? apiService;
  const AdminScreen({super.key, this.apiService});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final ApiService _api;
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<dynamic> _posts = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  final Set<int> _actingPostIds = {};
  final Set<int> _actingUserIds = {};

  // Filters
  String _postSearch = '';
  String _postFilter = 'All';
  String _userSearch = '';
  String _userFilter = 'All';

  static const Color primaryColor = Color(0xFF087E6B);
  static const Color canvasColor = Color(0xFFF5F8F7);
  static const Color dangerColor = Color(0xFFD9485F);
  static const Color successColor = Color(0xFF2E9C65);
  static const Color warningColor = Color(0xFFE99A21);

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final posts = await _api.getAdminPosts();
      final users = await _api.getAdminUsers();
      if (mounted) {
        setState(() {
          _posts = posts;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int get totalUsers => _users.length;
  int get lockedUsers => _users.where((u) => u['status'] == 'LOCKED').length;
  int get totalPosts => _posts.length;
  int get pendingPosts => _posts.where((p) => p['status'] == 'PENDING').length;

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleModeratePost(int id, String status) async {
    final actionName = status == 'APPROVED' ? 'duyệt' : 'từ chối';
    final confirm = await _showConfirmDialog(
      'Xác nhận',
      'Bạn có chắc muốn $actionName bài đăng này?',
    );
    if (confirm != true) return;

    setState(() => _actingPostIds.add(id));
    try {
      final success = await _api.moderatePost(id, status);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã $actionName bài đăng thành công'), backgroundColor: successColor),
        );
        _loadData(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _actingPostIds.remove(id));
    }
  }

  Future<void> _handleToggleUser(int id, bool isCurrentlyLocked) async {
    final authSession = context.read<AuthSession>();
    if (authSession.user?.userId == id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể khóa tài khoản của chính mình'), backgroundColor: dangerColor),
      );
      return;
    }

    final actionName = isCurrentlyLocked ? 'mở khóa' : 'khóa';
    final confirm = await _showConfirmDialog(
      'Xác nhận',
      'Bạn có chắc muốn $actionName người dùng này?',
    );
    if (confirm != true) return;

    setState(() => _actingUserIds.add(id));
    try {
      final success = await _api.toggleUserStatus(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã $actionName thành công'), backgroundColor: successColor),
        );
        _loadData(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _actingUserIds.remove(id));
    }
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _SummaryCard(title: 'Tổng Người Dùng', value: totalUsers.toString(), color: Colors.blue),
          _SummaryCard(title: 'Người Dùng Khóa', value: lockedUsers.toString(), color: dangerColor),
          _SummaryCard(title: 'Tổng Bài Đăng', value: totalPosts.toString(), color: Colors.purple),
          _SummaryCard(title: 'Bài Chờ Duyệt', value: pendingPosts.toString(), color: warningColor),
        ],
      ),
    );
  }

  List<dynamic> get filteredPosts {
    return _posts.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final address = (p['address'] ?? '').toString().toLowerCase();
      final search = _postSearch.toLowerCase();
      final matchSearch = title.contains(search) || address.contains(search);

      final status = p['status'] ?? 'PENDING';
      bool matchFilter = true;
      if (_postFilter == 'Pending') matchFilter = status == 'PENDING';
      if (_postFilter == 'Approved') matchFilter = status == 'APPROVED' || status == 'AVAILABLE';
      if (_postFilter == 'Rejected') matchFilter = status == 'REJECTED';

      return matchSearch && matchFilter;
    }).toList();
  }

  List<dynamic> get filteredUsers {
    return _users.where((u) {
      final name = (u['fullName'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final search = _userSearch.toLowerCase();
      final matchSearch = name.contains(search) || email.contains(search);

      final status = u['status'] ?? 'ACTIVE';
      final role = u['role'] ?? 'USER';
      bool matchFilter = true;
      if (_userFilter == 'Active') matchFilter = status != 'LOCKED';
      if (_userFilter == 'Locked') matchFilter = status == 'LOCKED';
      if (_userFilter == 'Admin') matchFilter = role == 'ADMIN';
      if (_userFilter == 'User') matchFilter = role == 'USER';

      return matchSearch && matchFilter;
    }).toList();
  }

  Widget _buildPostTab() {
    final posts = filteredPosts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm tiêu đề, địa chỉ...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _postSearch = v),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _postFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'Pending', child: Text('Chờ duyệt')),
                  DropdownMenuItem(value: 'Approved', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'Rejected', child: Text('Từ chối')),
                ],
                onChanged: (v) => setState(() => _postFilter = v ?? 'All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: posts.isEmpty
              ? const Center(child: Text('Không có bài đăng nào khớp.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    final id = p['id'] as int;
                    final status = p['status'] ?? 'PENDING';
                    final isActing = _actingPostIds.contains(id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                _StatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Giá: ${fmt.format(p['price'] ?? 0)}/tháng', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                            Text('Địa chỉ: ${p['address'] ?? ''}'),
                            Text('Mô tả: ${p['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status != 'REJECTED')
                                  OutlinedButton(
                                    onPressed: isActing ? null : () => _handleModeratePost(id, 'REJECTED'),
                                    style: OutlinedButton.styleFrom(foregroundColor: dangerColor),
                                    child: isActing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Từ chối'),
                                  ),
                                const SizedBox(width: 8),
                                if (status == 'PENDING')
                                  FilledButton(
                                    onPressed: isActing ? null : () => _handleModeratePost(id, 'APPROVED'),
                                    style: FilledButton.styleFrom(backgroundColor: successColor),
                                    child: isActing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Phê duyệt'),
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
      ],
    );
  }

  Widget _buildUserTab() {
    final usersList = filteredUsers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm tên, email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _userSearch = v),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _userFilter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'Active', child: Text('Hoạt động')),
                  DropdownMenuItem(value: 'Locked', child: Text('Đã khóa')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'User', child: Text('Người dùng')),
                ],
                onChanged: (v) => setState(() => _userFilter = v ?? 'All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: usersList.isEmpty
              ? const Center(child: Text('Không có người dùng nào khớp.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: usersList.length,
                  itemBuilder: (context, i) {
                    final u = usersList[i];
                    final id = u['id'] as int;
                    final isLocked = u['status'] == 'LOCKED';
                    final isActing = _actingUserIds.contains(id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLocked ? dangerColor.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                          child: Icon(isLocked ? Icons.lock : Icons.person, color: isLocked ? dangerColor : primaryColor),
                        ),
                        title: Text(u['fullName'] ?? 'Chưa đặt tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${u['email']} | SĐT: ${u['phone'] ?? 'Chưa có'}\nQuyền: ${u['role'] ?? 'USER'}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: isActing ? null : () => _handleToggleUser(id, isLocked),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLocked ? successColor : dangerColor,
                            foregroundColor: Colors.white,
                          ),
                          child: isActing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(isLocked ? 'Mở khóa' : 'Khóa'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: primaryColor));
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: dangerColor, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: dangerColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: () => _loadData(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSummaryCards(),
              SizedBox(
                height: 800, // A fixed height or use Expanded if not in SingleChildScrollView.
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: primaryColor,
                        indicatorColor: primaryColor,
                        tabs: [
                          Tab(text: 'Bài Đăng'),
                          Tab(text: 'Người Dùng'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPostTab(),
                            _buildUserTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        title: const Text('Bảng Quản Trị'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: content,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'APPROVED':
      case 'AVAILABLE':
        bg = _AdminScreenState.successColor;
        label = 'Đã duyệt';
        break;
      case 'REJECTED':
        bg = _AdminScreenState.dangerColor;
        label = 'Từ chối';
        break;
      default:
        bg = _AdminScreenState.warningColor;
        label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
''';

  final testScreenCode = r'''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/admin_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/state/auth_session.dart';
import 'package:frontend/models/auth_user.dart';

class MockApiService extends Mock implements ApiService {
  @override
  Future<List<dynamic>> getAdminPosts() async {
    return super.noSuchMethod(
      Invocation.method(#getAdminPosts, []),
      returnValue: Future.value(<dynamic>[]),
      returnValueForMissingStub: Future.value(<dynamic>[]),
    );
  }

  @override
  Future<List<dynamic>> getAdminUsers() async {
    return super.noSuchMethod(
      Invocation.method(#getAdminUsers, []),
      returnValue: Future.value(<dynamic>[]),
      returnValueForMissingStub: Future.value(<dynamic>[]),
    );
  }

  @override
  Future<bool> moderatePost(int? postId, String? status) async {
    return super.noSuchMethod(
      Invocation.method(#moderatePost, [postId, status]),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }

  @override
  Future<bool> toggleUserStatus(int? userId) async {
    return super.noSuchMethod(
      Invocation.method(#toggleUserStatus, [userId]),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }
}

class MockAuthSession extends Mock implements AuthSession {
  @override
  AuthUser? get user => super.noSuchMethod(
        Invocation.getter(#user),
        returnValue: null,
        returnValueForMissingStub: null,
      );
}

void main() {
  late MockApiService mockApiService;
  late MockAuthSession mockAuthSession;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthSession = MockAuthSession();
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSession>.value(value: mockAuthSession),
      ],
      child: MaterialApp(
        home: AdminScreen(apiService: mockApiService),
      ),
    );
  }

  testWidgets('1. Shows loading state initially', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return [];
    });
    when(mockApiService.getAdminUsers()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return [];
    });

    await tester.pumpWidget(buildTestApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('2. Shows empty state for posts and users', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => []);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(4)); // Summary cards
    expect(find.text('Không có bài đăng nào khớp.'), findsOneWidget);

    await tester.tap(find.text('Người Dùng').last);
    await tester.pumpAndSettle();

    expect(find.text('Không có người dùng nào khớp.'), findsOneWidget);
  });

  testWidgets('3. Shows error state with retry button', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenThrow(Exception('API Error'));
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Exception: API Error'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    when(mockApiService.getAdminPosts()).thenAnswer((_) async => []);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Exception: API Error'), findsNothing);
  });

  testWidgets('4. Displays data and summary cards correctly', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => [
      {'id': 1, 'title': 'Post 1', 'status': 'PENDING'},
      {'id': 2, 'title': 'Post 2', 'status': 'APPROVED'}
    ]);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => [
      {'id': 1, 'fullName': 'User 1', 'status': 'ACTIVE', 'role': 'USER'},
      {'id': 2, 'fullName': 'User 2', 'status': 'LOCKED', 'role': 'USER'}
    ]);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2)); // Total Posts, Total Users
    expect(find.text('1'), findsNWidgets(2)); // Locked Users, Pending Posts

    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
  });

  testWidgets('5. Search filtering works for posts', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => [
      {'id': 1, 'title': 'Room A', 'status': 'PENDING'},
      {'id': 2, 'title': 'Apartment B', 'status': 'APPROVED'}
    ]);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Room A'), findsOneWidget);
    expect(find.text('Apartment B'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Room');
    await tester.pumpAndSettle();

    expect(find.text('Room A'), findsOneWidget);
    expect(find.text('Apartment B'), findsNothing);
  });

  testWidgets('6. Dropdown filtering works for users', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => []);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => [
      {'id': 1, 'fullName': 'User Active', 'status': 'ACTIVE', 'role': 'USER'},
      {'id': 2, 'fullName': 'User Locked', 'status': 'LOCKED', 'role': 'USER'}
    ]);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Người Dùng').last);
    await tester.pumpAndSettle();

    expect(find.text('User Active'), findsOneWidget);
    expect(find.text('User Locked'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã khóa').last);
    await tester.pumpAndSettle();

    expect(find.text('User Active'), findsNothing);
    expect(find.text('User Locked'), findsOneWidget);
  });

  testWidgets('7. Moderate post shows confirm dialog and locks button', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => [
      {'id': 1, 'title': 'Post 1', 'status': 'PENDING'}
    ]);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => []);
    
    when(mockApiService.moderatePost(1, 'APPROVED')).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    });

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phê duyệt'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn có chắc muốn duyệt bài đăng này?'), findsOneWidget);

    await tester.tap(find.text('Xác nhận'));
    await tester.pump();

    // Now button should show loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // Finish loading
    verify(mockApiService.moderatePost(1, 'APPROVED')).called(1);
    expect(find.text('Đã duyệt bài đăng thành công'), findsOneWidget); // SnackBar
  });

  testWidgets('8. Toggle user shows confirm dialog and updates UI', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => []);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => [
      {'id': 2, 'fullName': 'User 2', 'status': 'ACTIVE', 'role': 'USER'}
    ]);
    when(mockAuthSession.user).thenReturn(const AuthUser(userId: 1, email: 'admin@test.com', token: 'token', fullName: 'Admin'));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Người Dùng').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn có chắc muốn khóa người dùng này?'), findsOneWidget);

    when(mockApiService.toggleUserStatus(2)).thenAnswer((_) async => true);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    verify(mockApiService.toggleUserStatus(2)).called(1);
  });

  testWidgets('9. Admin cannot lock their own account', (WidgetTester tester) async {
    when(mockApiService.getAdminPosts()).thenAnswer((_) async => []);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => [
      {'id': 1, 'fullName': 'Admin', 'status': 'ACTIVE', 'role': 'ADMIN'}
    ]);
    when(mockAuthSession.user).thenReturn(const AuthUser(userId: 1, email: 'admin@test.com', token: 'token', fullName: 'Admin'));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Người Dùng').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể khóa tài khoản của chính mình'), findsOneWidget);
    verifyNever(mockApiService.toggleUserStatus(1));
  });

  testWidgets('10. Responsive UI - renders without overflow on mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    when(mockApiService.getAdminPosts()).thenAnswer((_) async => [
      {'id': 1, 'title': 'Long title to ensure no overflow happens here because we wrap text appropriately', 'status': 'PENDING'}
    ]);
    when(mockApiService.getAdminUsers()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // No layout exceptions

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
''';

  File('G:/Desktop/Roomate-and-matching-app/frontend/lib/screens/admin_screen.dart').writeAsStringSync(adminScreenCode);
  File('G:/Desktop/Roomate-and-matching-app/frontend/test/admin_screen_test.dart').writeAsStringSync(testScreenCode);
}
