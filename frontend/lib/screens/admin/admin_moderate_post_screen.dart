import 'package:flutter/material.dart';

class AdminModeratePostScreen extends StatelessWidget {
  const AdminModeratePostScreen({super.key});

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
                _buildSidebarItem(context, 'Duyệt tin đăng', isActive: true),
                _buildSidebarItem(context, 'Báo cáo vi phạm'),
                
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
                            'Kiểm duyệt tin đăng',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '12 tin chờ duyệt · Kiểm tra ảnh và thông tin trước khi xuất bản',
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
                  const SizedBox(height: 40),
                  
                  // Two columns
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column (Post Details)
                        Expanded(
                          flex: 62, // approx 626 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      height: 267,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'RH-028 · Studio ngập nắng, có ban công',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF142523),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Minh Anh · Bình Thạnh · 19 / 09 / 2026',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF65746F),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    '3.500.000đ / tháng · 28 m² · Tối đa 2 người',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF087E6B),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Nội thất: Giường, tủ, máy lạnh, bếp riêng.\nĐiện: 3.800đ / kWh\nNước: 100.000đ / người\nGiờ giấc tự do, không chung chủ.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF142523),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // Right Column (Moderation Actions)
                        Expanded(
                          flex: 38, // approx 372 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quyết định kiểm duyệt',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Kiểm tra nội dung',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '✓  Tiêu đề & địa chỉ rõ ràng\n✓  Có ảnh minh họa căn phòng\n✓  Nội dung hợp lệ',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                    height: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Lý do từ chối',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 105,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F8F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const TextField(
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập lý do để người đăng chỉnh sửa…',
                                      hintStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'SourceSansPro',
                                        color: Color(0xFF65746F),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF142523),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Approve and navigate to success screen
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
                                      'Duyệt & hiển thị tin',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SourceSansPro',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Reject
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
                                      'Từ chối tin đăng',
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
