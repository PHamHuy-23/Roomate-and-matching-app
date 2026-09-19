import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget _buildSidebarItem(String title, {bool isActive = false}) {
    return Container(
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
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        height: 134,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 37,
                fontWeight: FontWeight.w700,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF087E6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF65746F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double heightRatio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 38,
          height: 220 * heightRatio,
          decoration: BoxDecoration(
            color: const Color(0xFF087E6B),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
          ),
        ),
      ],
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
                _buildSidebarItem('Tổng quan', isActive: true),
                _buildSidebarItem('Người dùng'),
                _buildSidebarItem('Duyệt tin đăng'),
                _buildSidebarItem('Báo cáo vi phạm'),
                
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
                            'Tổng quan hệ thống',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thứ Bảy, 19 / 09 / 2026 · Dữ liệu minh họa',
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
                  
                  // Top Stats
                  Row(
                    children: [
                      _buildStatCard('1.284', 'Người dùng'),
                      _buildStatCard('128', 'Tin đang hiển thị'),
                      _buildStatCard('12', 'Tin chờ duyệt'),
                      _buildStatCard('08', 'Báo cáo cần xử lý'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Middle Row
                  Row(
                    children: [
                      // Chart
                      Expanded(
                        flex: 6,
                        child: Container(
                          height: 345,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kết nối mới trong tuần',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildChartBar('T2', 90/220),
                                  _buildChartBar('T3', 138/220),
                                  _buildChartBar('T4', 110/220),
                                  _buildChartBar('T5', 189/220),
                                  _buildChartBar('T6', 162/220),
                                  _buildChartBar('T7', 220/220),
                                  _buildChartBar('CN', 184/220),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      
                      // Alerts
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 345,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Cần bạn xem xét',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF142523),
                                ),
                              ),
                              SizedBox(height: 40),
                              Text(
                                '12 tin đang chờ duyệt  →',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF087E6B),
                                ),
                              ),
                              SizedBox(height: 32),
                              Text(
                                '08 báo cáo chưa xử lý  →',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF087E6B),
                                ),
                              ),
                              SizedBox(height: 32),
                              Text(
                                '03 tài khoản cần rà soát  →',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SourceSansPro',
                                  color: Color(0xFF087E6B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom Row
                  Container(
                    width: double.infinity,
                    height: 128,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nhật ký hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '14:32  ·  Tin RH-024 được duyệt       14:10  ·  Báo cáo BC-028 được tiếp nhận',
                          style: TextStyle(
                            fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
