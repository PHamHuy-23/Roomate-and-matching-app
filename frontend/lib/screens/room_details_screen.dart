import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room_post.dart';
import 'room_flow_screen.dart';
import 'room_viewing_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({required this.post, super.key});

  final RoomPost post;

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _primary = Color(0xFF087E6B);
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  static const _soft = Color(0xFFE8F4F1);

  bool _saved = false;

  String get _price => NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(widget.post.price);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final area = post.areaM2 == null ? '28 m²' : '${post.areaM2!.round()} m²';
    final hasImage = post.imageUrl?.trim().isNotEmpty == true;
    final hasCompleteDetails = post.areaM2 != null && post.amenities.isNotEmpty;
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _saved ? 'Bỏ lưu phòng' : 'Lưu phòng',
            onPressed: () => setState(() => _saved = !_saved),
            icon: Icon(_saved ? Icons.favorite : Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Chia sẻ',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chia sẻ phòng sẽ được bổ sung sau.'),
              ),
            ),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            _hero(post),
            const SizedBox(height: 18),
            Text(
              post.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(post.address, style: const TextStyle(color: _muted)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tag(area),
                _tag(
                  '${post.maxOccupants == 1 ? '1' : '1–${post.maxOccupants}'} người',
                ),
                _tag('Có nội thất'),
              ],
            ),
            if (!hasImage || !hasCompleteDetails) ...[
              const SizedBox(height: 8),
              const Text(
                'Một số thông tin đang hiển thị minh họa vì API chưa trả đủ dữ liệu.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            _authorCard(post),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RoomFlowScreen(post: post, mode: RoomFlowMode.roomPhotos),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Xem 4 ảnh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RoomFlowScreen(post: post, mode: RoomFlowMode.roomInfo),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tiện ích, chi phí & nội quy',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: _muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _price,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    'mỗi tháng • cọc 1 tháng',
                    style: TextStyle(color: _muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RoomViewingScreen(post: post),
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Đặt lịch xem'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(RoomPost post) {
    final url = post.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackImage(),
              )
            : _fallbackImage(),
      ),
    );
  }

  Widget _fallbackImage() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFD7EDE7), Color(0xFF9BC8BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.home_work_outlined, color: _primary, size: 74),
    ),
  );

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _authorCard(RoomPost post) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: _soft,
          foregroundColor: _primary,
          child: Text(
            post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${post.authorName} • Người đăng',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thông tin người đăng phòng',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
