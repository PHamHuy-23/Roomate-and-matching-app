import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../widgets/penpot_back_button.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Widget _buildNotificationItem({
    bool hasAvatar = true,
    IconData? avatarIcon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (hasAvatar) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade300,
                  child: Icon(avatarIcon ?? Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cập nhật dành cho bạn',
                          style: TextStyle(
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
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  _buildNotificationItem(
                    title: 'Minh Anh gửi lời mời kết nối',
                    subtitle: '15 phút trước · 94% phù hợp',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.requests);
                    },
                  ),
                  _buildNotificationItem(
                    title: 'Lịch xem phòng đang chờ xác nhận',
                    subtitle: 'Hôm nay · Studio ngập nắng',
                    avatarIcon: Icons.calendar_today,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.listingManagement);
                    },
                  ),
                  _buildNotificationItem(
                    hasAvatar: false,
                    title: 'Tin đăng đang được kiểm duyệt',
                    subtitle: 'Hôm qua · Xem trạng thái tin',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.listingManagement);
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF8F5),
                    foregroundColor: const Color(0xFF087E6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đánh dấu tất cả đã đọc',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
