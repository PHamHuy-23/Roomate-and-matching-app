import 'package:flutter/material.dart';

import '../models/room_post.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';
import 'room_details_screen.dart';

class PosterProfileScreen extends StatefulWidget {
  const PosterProfileScreen({super.key, this.userId, this.roomId});
  final int? userId;
  final int? roomId;

  @override
  State<PosterProfileScreen> createState() => _PosterProfileScreenState();
}

class _PosterProfileScreenState extends State<PosterProfileScreen> {
  RoomPost? _post;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roomId = widget.roomId;
    if (roomId == null || roomId <= 0) {
      setState(() => _error = 'Không xác định được tin phòng.');
      return;
    }
    try {
      final post = await ApiService().getRoomPost(roomId);
      if (!mounted) return;
      if (widget.userId != null && widget.userId != post.authorId) {
        setState(() => _error = 'Tin phòng không thuộc người dùng này.');
      } else {
        setState(() => _post = post);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không tải được hồ sơ người đăng: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Người đăng phòng'),
        backgroundColor: const Color(0xFFF5F8F7),
        foregroundColor: const Color(0xFF142523),
        leading: const PenpotBackButton(),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : post == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(Icons.person, size: 42),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ứng dụng chỉ hiển thị thông tin công khai có trong tin đăng. Thông tin liên hệ được mở sau khi hai bên kết nối.',
                ),
                const SizedBox(height: 28),
                const Text(
                  'Phòng đang đăng',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(post.address),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomDetailsScreen(post: post),
                    ),
                  ),
                  child: const Text('Xem chi tiết phòng'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.reportViolation,
                    arguments: {'targetUserId': post.authorId},
                  ),
                  child: const Text('Báo cáo người dùng'),
                ),
              ],
            ),
    );
  }
}
