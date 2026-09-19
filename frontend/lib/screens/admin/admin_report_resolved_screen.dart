import 'package:flutter/material.dart';

class AdminReportResolvedScreen extends StatelessWidget {
  const AdminReportResolvedScreen({super.key});

  Widget _buildSidebarItem(BuildContext context, String title, {bool isActive = false, String? route}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: Row(
        children: [
          // Sidebar
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
                      Text(
                        'RH / Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SourceSansPro',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ROOMMATE HUB',
                        style: TextStyle(
                          color: Color(0xFF8FB8AC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(context, 'Tổng quan', route: '/admin/dashboard'),
                _buildSidebarItem(context, 'Người dùng', route: '/admin/users'),
                _buildSidebarItem(context, 'Duyệt tin đăng', route: '/admin/moderate-post'),
                _buildSidebarItem(context, 'Báo cáo vi phạm', isActive: true, route: '/admin/reports'),
                
                const Spacer(),
                
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Text(
                    'Không gian quản trị',
                    style: TextStyle(
                      color: Color(0xFF8FB8AC),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SourceSansPro',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Đã xử lý báo cáo',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thao tác quản trị · Dữ liệu minh họa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF65746F),
                            ),
                          ),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  
                  // Center Card
                  Center(
                    child: Container(
                      width: 690,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đã xử lý báo cáo',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'BC-028 · Đã ghi nhận kết quả và ghi chú xử lý.\nThông báo kết quả đã được gửi tới người báo cáo.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF65746F),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 64),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
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
                                'Về danh sách báo cáo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SourceSansPro',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
