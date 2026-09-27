import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_profile_avatar.dart';

class AdminModeratePostScreen extends StatefulWidget {
  const AdminModeratePostScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<AdminModeratePostScreen> createState() => _AdminModeratePostScreenState();
}

class _AdminModeratePostScreenState extends State<AdminModeratePostScreen> {
  late final ApiService _api;
  final TextEditingController _reasonController = TextEditingController();

  List<Map<String, dynamic>> _posts = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedPost;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _loadPosts();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getAdminPosts();
      if (!mounted) return;
      final posts = response.whereType<Map>().map(_mapPost).toList();
      setState(() {
        _posts = posts;
        _selectedPost = posts.isEmpty ? null : _preferredPost(posts);
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
        _error = 'Không thể tải danh sách tin đăng, vui lòng thử lại.';
      });
    }
  }

  Map<String, dynamic> _mapPost(Map<dynamic, dynamic> raw) {
    final author = raw['author'];
    final nestedAuthor = author is Map ? author : const <dynamic, dynamic>{};
    final id = _asInt(raw['id'] ?? raw['postId']);
    final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
    return {
      'id': id,
      'label': id == null ? '—' : 'RH-${id.toString().padLeft(3, '0')}',
      'title': raw['title']?.toString() ?? 'Tin đăng chưa có tiêu đề',
      'description': raw['description']?.toString() ?? '',
      'authorName': raw['authorName']?.toString() ??
          nestedAuthor['fullName']?.toString() ??
          nestedAuthor['name']?.toString() ??
          'Người đăng',
      'address': raw['address']?.toString() ?? 'Chưa có địa chỉ',
      'price': _asNum(raw['price']),
      'maxOccupants': _asInt(raw['maxOccupants']),
      'area': raw['area']?.toString(),
      'imageUrl': raw['imageUrl']?.toString(),
      'status': raw['status']?.toString().toUpperCase() ?? 'PENDING',
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> _preferredPost(List<Map<String, dynamic>> posts) {
    return posts.firstWhere(
      (post) {
        final status = post['status']?.toString().toUpperCase();
        return status == 'PENDING' ||
            status == 'PENDING_REVIEW' ||
            status == 'WAITING_APPROVAL';
      },
      orElse: () => posts.first,
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  String _formatDate(dynamic value) {
    if (value is! DateTime) return '—';
    return '${value.day.toString().padLeft(2, '0')} / '
        '${value.month.toString().padLeft(2, '0')} / ${value.year}';
  }

  String _formatPrice(dynamic value) {
    final price = value is num ? value : _asNum(value);
    if (price == null) return 'Chưa có giá';
    final digits = price.round().toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = end - 3 < 0 ? 0 : end - 3;
      groups.insert(0, digits.substring(start, end));
    }
    return '${groups.join('.')}đ / tháng';
  }

  Widget _buildSidebarItem(BuildContext context, String title,
      {bool isActive = false, String? route}) {
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

  Widget _buildPostImage(Map<String, dynamic> post) {
    final imageUrl = post['imageUrl']?.toString();
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 267,
        color: Colors.grey.shade300,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image, size: 64, color: Colors.grey),
              )
            : const Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildPostDetails(Map<String, dynamic> post) {
    final area = post['area']?.toString();
    final maxOccupants = post['maxOccupants'];
    final extra = <String>[];
    if (area != null && area.isNotEmpty) extra.add(area);
    if (maxOccupants != null) extra.add('Tối đa $maxOccupants người');
    final description = post['description']?.toString() ?? '';
    final details = description.isEmpty
        ? 'Thông tin chi tiết đang được người đăng bổ sung.'
        : description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPostImage(post),
        const SizedBox(height: 24),
        Text(
          '${post['label']} · ${post['title']}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${post['authorName']} · ${post['address']} · ${_formatDate(post['createdAt'])}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF65746F),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          [_formatPrice(post['price']), ...extra].join(' · '),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF087E6B),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          details,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Future<void> _moderatePost({required bool approve}) async {
    final postId = _selectedPost?['id'];
    if (postId is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tin đăng chưa có mã hợp lệ để xử lý.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _api.moderatePost(postId, approve ? 'APPROVED' : 'REJECTED');
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        approve ? AppRoutes.adminPostApproved : AppRoutes.adminPostNeedsEdit,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật trạng thái tin đăng.')),
      );
    }
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFF65746F))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadPosts, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_selectedPost == null) {
      return const Center(
        child: Text(
          'Không có tin đăng chờ kiểm duyệt.',
          style: TextStyle(color: Color(0xFF65746F), fontSize: 16),
        ),
      );
    }
    final post = _selectedPost!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 62,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(child: _buildPostDetails(post)),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 38, child: _buildDecisionPanel()),
      ],
    );
  }

  Widget _buildDecisionPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quyết định kiểm duyệt',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'SourceSansPro', color: Color(0xFF142523)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Kiểm tra nội dung',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'SourceSansPro', color: Color(0xFF142523)),
          ),
          const SizedBox(height: 16),
          const Text(
            '✓  Tiêu đề & địa chỉ rõ ràng\n✓  Có ảnh minh họa căn phòng\n✓  Nội dung hợp lệ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, fontFamily: 'SourceSansPro', color: Color(0xFF142523), height: 1.8),
          ),
          const SizedBox(height: 40),
          const Text(
            'Lý do từ chối',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'SourceSansPro', color: Color(0xFF142523)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 105,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF5F8F7), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _reasonController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do để người đăng chỉnh sửa…',
                hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, fontFamily: 'SourceSansPro', color: Color(0xFF65746F)),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 15, fontFamily: 'SourceSansPro', color: Color(0xFF142523)),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _moderatePost(approve: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087E6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Duyệt & hiển thị tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SourceSansPro')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _moderatePost(approve: false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAF8F5), foregroundColor: const Color(0xFF087E6B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: const Text('Từ chối tin đăng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SourceSansPro')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = _isLoading
        ? 'Đang tải tin chờ duyệt…'
        : '${_posts.length} tin chờ duyệt · Kiểm tra ảnh và thông tin trước khi xuất bản';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: Row(
        children: [
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
                      Text('RH / Admin', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'SourceSansPro')),
                      SizedBox(height: 4),
                      Text('ROOMMATE HUB', style: TextStyle(color: Color(0xFF8FB8AC), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'SourceSansPro', letterSpacing: 1.5)),
                    ],
                  ),
                ),
                _buildSidebarItem(context, 'Tổng quan', route: '/admin/dashboard'),
                _buildSidebarItem(context, 'Người dùng', route: '/admin/users'),
                _buildSidebarItem(context, 'Duyệt tin đăng', isActive: true),
                _buildSidebarItem(context, 'Báo cáo vi phạm', route: AppRoutes.adminReports),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Text('Không gian quản trị', style: TextStyle(color: Color(0xFF8FB8AC), fontSize: 13, fontWeight: FontWeight.w400, fontFamily: 'SourceSansPro')),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kiểm duyệt tin đăng', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'SourceSansPro', color: Color(0xFF142523))),
                          const SizedBox(height: 8),
                          Text(countLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, fontFamily: 'SourceSansPro', color: Color(0xFF65746F))),
                        ],
                      ),
                      const AdminProfileAvatar(),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(height: 680, child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
