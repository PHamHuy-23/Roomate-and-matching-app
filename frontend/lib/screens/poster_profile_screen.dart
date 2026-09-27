import 'package:flutter/material.dart';

import '../models/room_post.dart';
import '../navigation/app_routes.dart';
import '../widgets/penpot_back_button.dart';
import 'room_details_screen.dart';

class PosterProfileScreen extends StatelessWidget {
  final int? userId;
  final int? roomId; // ID of the room to view details
  
  const PosterProfileScreen({
    super.key,
    this.userId,
    this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
                  const Text(
                    'Người đăng phòng',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hồ sơ công khai',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF65746F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // User Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                          // image: NetworkImage('...'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Minh Anh',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF142523),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Email đã xác minh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF087E6B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Bio
                  const Text(
                    'Đang cho thuê phòng tại Bình Thạnh.\nƯu tiên người thuê lâu dài',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Room Post
                  const Text(
                    'Phòng đang đăng',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Room Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 178,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.photo, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Room Title
                  const Text(
                    'Studio ngập nắng · 3,5 triệu / tháng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final post = RoomPost(
                          id: roomId ?? 0,
                          title: 'Studio ngập nắng',
                          description:
                              'Không gian sáng, thoáng, phù hợp cho người đi học và đi làm.',
                          price: 3500000,
                          address: 'Quận 3, TP. Hồ Chí Minh',
                          maxOccupants: 2,
                          authorName: 'Minh Anh',
                          authorId: userId ?? 0,
                          areaM2: 28,
                          amenities: const ['Wifi', 'Máy giặt', 'Giữ xe'],
                        );
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => RoomDetailsScreen(post: post),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087E6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xem chi tiết phòng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Report Action
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.reportViolation,
                          arguments: {'targetUserId': userId},
                        );
                      },
                      child: const Text(
                        'Báo cáo người dùng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'SourceSansPro',
                          color: Color(0xFF65746F),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
