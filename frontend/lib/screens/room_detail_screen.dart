import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room_post.dart';

/// Màn hình Chi tiết phòng trọ — hiển thị đầy đủ thông tin bài đăng
class RoomDetailScreen extends StatelessWidget {
  final RoomPost post;
  const RoomDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ===== HEADER ẢNH PHÒNG =====
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                post.district.isNotEmpty ? '📍 ${post.district}' : '',
                style: const TextStyle(fontSize: 14, shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh phòng (hoặc placeholder gradient)
                  post.imageUrl != null && post.imageUrl!.isNotEmpty
                      ? Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  // Huy hiệu trạng thái
                  Positioned(
                    top: 80,
                    right: 16,
                    child: _buildStatusBadge(post.status),
                  ),
                ],
              ),
            ),
          ),

          // ===== NỘI DUNG CHI TIẾT =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Giá + Lượt xem
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${fmt.format(post.price)}/tháng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (post.viewCount > 0)
                        Row(
                          children: [
                            Icon(Icons.visibility,
                                size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${post.viewCount} lượt xem',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== THÔNG TIN CHI TIẾT (Grid) =====
                  _buildInfoGrid(fmt),
                  const SizedBox(height: 20),

                  // ===== ĐỊA CHỈ =====
                  _buildDetailRow(
                    icon: Icons.location_on,
                    iconColor: Colors.red.shade400,
                    label: 'Địa chỉ',
                    value: post.address,
                  ),
                  const SizedBox(height: 16),

                  // ===== TIỆN ÍCH =====
                  if (post.amenities.isNotEmpty) ...[
                    const Text(
                      'Tiện ích có sẵn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.amenities.map((a) {
                        final emoji = RoomPost.amenityIcons[a] ?? '🔹';
                        return Chip(
                          avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
                          label: Text(a),
                          backgroundColor: Colors.indigo.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ===== MÔ TẢ =====
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      post.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== THÔNG TIN NGƯỜI ĐĂNG =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.indigo.shade200,
                          child: Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.timeAgo.isNotEmpty
                                    ? 'Đăng ${post.timeAgo}'
                                    : 'Người đăng bài',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== CÁC NÚT HÀNH ĐỘNG =====
                  Row(
                    children: [
                      // Nút Đặt lịch hẹn xem phòng
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '📅 Tính năng Đặt lịch hẹn xem phòng sẽ hoàn thiện ở Giai đoạn 4!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Đặt lịch hẹn'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.indigo),
                            foregroundColor: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Gửi lời mời ghép đôi
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🤝 Tính năng Gửi lời mời ghép đôi sẽ hoàn thiện ở Giai đoạn 4!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('Ghép đôi'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grid thông tin chi tiết: Cọc, Diện tích, Số người, Điện nước
  Widget _buildInfoGrid(NumberFormat fmt) {
    final items = <_InfoItem>[];

    if (post.deposit != null && post.deposit! > 0) {
      items.add(_InfoItem(
        icon: Icons.account_balance_wallet,
        label: 'Tiền cọc',
        value: fmt.format(post.deposit),
        color: Colors.orange,
      ));
    }

    if (post.area != null && post.area! > 0) {
      items.add(_InfoItem(
        icon: Icons.square_foot,
        label: 'Diện tích',
        value: '${post.area!.toStringAsFixed(0)} m²',
        color: Colors.teal,
      ));
    }

    items.add(_InfoItem(
      icon: Icons.group,
      label: 'Số người',
      value: '${post.currentOccupants}/${post.maxOccupants} người',
      color: Colors.blue,
    ));

    if (post.electricityWaterCost != null && post.electricityWaterCost! > 0) {
      items.add(_InfoItem(
        icon: Icons.bolt,
        label: 'Điện/Nước',
        value: fmt.format(post.electricityWaterCost),
        color: Colors.amber.shade700,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: item.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: item.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String text;
    switch (status) {
      case 'AVAILABLE':
        bg = Colors.green;
        text = '🟢 Đang mở';
        break;
      case 'PENDING':
        bg = Colors.orange;
        text = '🟡 Chờ duyệt';
        break;
      case 'APPROVED':
        bg = Colors.blue;
        text = '✅ Đã duyệt';
        break;
      default:
        bg = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 64, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              'Phòng trọ',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
