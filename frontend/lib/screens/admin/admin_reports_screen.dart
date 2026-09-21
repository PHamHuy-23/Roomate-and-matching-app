import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../widgets/admin_profile_avatar.dart';

class _AdminReport {
  const _AdminReport({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.sender,
    required this.note,
  });

  final String id;
  final String title;
  final String subtitle;
  final String reason;
  final String sender;
  final String note;
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _reports = <_AdminReport>[
    _AdminReport(
      id: 'BC-028',
      title: 'Thông tin phòng sai',
      subtitle: 'Tin RH-028 · 15 phút trước',
      reason: 'Thông tin phòng không đúng thực tế',
      sender: 'Thành viên ẩn danh',
      note: 'Đã đối chiếu thông tin, yêu cầu cập nhật tin.',
    ),
    _AdminReport(
      id: 'BC-027',
      title: 'Nội dung không phù hợp',
      subtitle: 'Người dùng #028 · 2 giờ trước',
      reason: 'Nội dung tin đăng không phù hợp',
      sender: 'Người dùng #028',
      note: 'Đang chờ quản trị viên kiểm tra nội dung.',
    ),
    _AdminReport(
      id: 'BC-026',
      title: 'Tin đăng trùng lặp',
      subtitle: 'Tin RH-024 · Hôm qua',
      reason: 'Tin đăng có dấu hiệu trùng lặp',
      sender: 'Thành viên ẩn danh',
      note: 'Cần đối chiếu với tin RH-024 trước khi xử lý.',
    ),
  ];

  int _selectedIndex = 0;

  _AdminReport get _selectedReport => _reports[_selectedIndex];

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

  Widget _buildReportItem(_AdminReport report, {required bool isActive}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('admin_report_${report.id}'),
        onTap: () => setState(() {
          _selectedIndex = _reports.indexOf(report);
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEAF8F5) : const Color(0xFFF5F8F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${report.id} · ${report.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SourceSansPro',
                  color: Color(0xFF142523),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'SourceSansPro',
                  color: Color(0xFF65746F),
                ),
              ),
            ],
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
                _buildSidebarItem(context, 'Báo cáo vi phạm', isActive: true),
                
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
            child: SingleChildScrollView(
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
                            'Báo cáo vi phạm',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF142523),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ưu tiên xử lý các báo cáo về an toàn và thông tin sai',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'SourceSansPro',
                              color: Color(0xFF65746F),
                            ),
                          ),
                        ],
                      ),
                      const AdminProfileAvatar(),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Two columns
                  SizedBox(
                    height: 620,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column (List)
                        Expanded(
                          flex: 48, // approx 480 width
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
                                  'Báo cáo đang chờ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      for (var index = 0; index < _reports.length; index++)
                                        _buildReportItem(
                                          _reports[index],
                                          isActive: index == _selectedIndex,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // Right Column (Details)
                        Expanded(
                          flex: 52, // approx 520 width
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedReport.id} / Chi tiết báo cáo',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Lý do: ${_selectedReport.reason}\nNgười gửi: ${_selectedReport.sender}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 224,
                                    height: 147,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Bằng chứng đính kèm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF65746F),
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Ghi chú xử lý',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SourceSansPro',
                                    color: Color(0xFF142523),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F8F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedReport.note,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'SourceSansPro',
                                      color: Color(0xFF142523),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        AppRoutes.adminReportResolved,
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
                                      'Đánh dấu đã xử lý',
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
