import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';
import 'room_details_screen.dart';

class SavedRoomsScreen extends StatefulWidget {
  const SavedRoomsScreen({required this.posts, this.onUnsave, super.key});

  final List<RoomPost> posts;
  final ValueChanged<int>? onUnsave;

  @override
  State<SavedRoomsScreen> createState() => _SavedRoomsScreenState();
}

class _SavedRoomsScreenState extends State<SavedRoomsScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF65746F);
  static const _soft = Color(0xFFE8F4F1);

  late List<RoomPost> _savedPosts;

  @override
  void initState() {
    super.initState();
    _savedPosts = List<RoomPost>.of(widget.posts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Phòng đã lưu'),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: _savedPosts.isEmpty ? _empty(context) : _list(context),
    );
  }

  Widget _list(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: <Widget>[
        const Text(
          'Dễ dàng xem lại những căn phòng yêu thích',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        ..._savedPosts.map((post) => _card(context, post)),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: _soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: _primary, size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có phòng đã lưu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chạm biểu tượng lưu ở trang chi tiết\nđể giữ lại căn phòng bạn quan tâm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 230,
              child: FilledButton(
                onPressed: () => Navigator.maybePop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Khám phá phòng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, RoomPost post) {
    final price = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(post.price);
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 156,
                child: _RoomPreview(imageUrl: post.imageUrl),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$price / tháng · ${_district(post.address)}',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RoomDetailsScreen(post: post),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem phòng'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => _remove(post),
                    style: TextButton.styleFrom(foregroundColor: _muted),
                    child: const Text('Bỏ lưu phòng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _district(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return address;
  }

  void _remove(RoomPost post) {
    setState(() => _savedPosts.removeWhere((item) => item.id == post.id));
    widget.onUnsave?.call(post.id);
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD7EDE7), Color(0xFF9BC8BC)],
      ),
    ),
    child: const Center(
      child: Icon(Icons.home_work_outlined, color: Color(0xFF087E6B), size: 54),
    ),
  );
}
