import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/penpot_back_button.dart';

class ContactDetailsScreen extends StatelessWidget {
  final int? contactId;
  final String? contactName;
  
  const ContactDetailsScreen({super.key, this.contactId, this.contactName});

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEAF8F5),
            foregroundColor: const Color(0xFF087E6B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'SourceSansPro',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = contactName ?? 'Người dùng Roommate Hub';
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
                    'Kết nối thành công',
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
                  'Cả hai đã đồng ý chia sẻ liên hệ',
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
                  // Avatar
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        // image: NetworkImage('...'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name and Info
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sinh viên · Bình Thạnh',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Contact Details Cards
                  _buildInfoCard('Số điện thoại', '090 ••• •••• · Dữ liệu mẫu'),
                  const SizedBox(height: 16),
                  _buildInfoCard('Email liên hệ', 'nam@example.com'),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  _buildActionButton('Xem hồ sơ', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.roommateProfile,
                      arguments: {
                        'userId': contactId,
                        'partnerName': name,
                      },
                    );
                  }),
                  _buildActionButton('Nhắn tin', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {
                        'partnerId': contactId,
                        'partnerName': name,
                      },
                    );
                  }),
                  _buildActionButton('Báo cáo hoặc chặn', () {
                    Navigator.pushNamed(context, AppRoutes.reportViolation);
                  }),
                  _buildActionButton('Hủy kết nối', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.cancelConnection,
                      arguments: {'partnerId': contactId},
                    );
                  }),
                  
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
