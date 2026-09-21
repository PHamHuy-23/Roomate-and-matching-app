import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/penpot_back_button.dart';

class RoommateProfileScreen extends StatelessWidget {
  final int? userId;
  final String? displayName;
  
  const RoommateProfileScreen({super.key, this.userId, this.displayName});

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'SourceSansPro',
          color: Color(0xFF087E6B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName ?? 'Người dùng Roommate Hub';
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
                    'Hồ sơ bạn ở ghép',
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
                  'Thông tin công khai',
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
                          width: 112,
                          height: 124,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                          // image: NetworkImage('...'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF142523),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'HUTECH · Sinh viên',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'SourceSansPro',
                                color: Color(0xFF142523),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                    'Một chút về mình',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mình thích nấu ăn, đọc sách và chạy bộ.\nTìm một người ở cùng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Preferences
                  const Text(
                    'Mong muốn ở ghép',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2,5 – 4 triệu / tháng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bình Thạnh · Chuyển vào từ 01 / 10',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge('Ngủ trước 23h'),
                            _buildBadge('Không hút thuốc'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.sendRequest,
                        arguments: {
                          'partnerId': userId,
                          'partnerName': name,
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF8F5),
                        foregroundColor: const Color(0xFF087E6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '94% phù hợp · Xem lý do',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Liên hệ chỉ mở khi cả hai chấp nhận kết nối.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF65746F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: const Color(0xFFF5F8F7),
                        builder: (sheetContext) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Vì sao hai bạn phù hợp?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                SizedBox(height: 16),
                                _MatchReason(text: 'Cùng khu vực Bình Thạnh'),
                                _MatchReason(text: 'Ngân sách ở ghép tương đồng'),
                                _MatchReason(text: 'Thói quen sinh hoạt phù hợp'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087E6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Gửi lời mời kết nối',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
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

class _MatchReason extends StatelessWidget {
  const _MatchReason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF087E6B)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Color(0xFF142523))),
        ],
      ),
    );
  }
}
