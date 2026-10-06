import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/penpot_back_button.dart';

class ContactDetailsScreen extends StatelessWidget {
  final int? contactId;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  const ContactDetailsScreen({
    super.key,
    this.contactId,
    this.contactName,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  Widget _buildInfoCard(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF087E6B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF65746F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF142523),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? const Color(0xFF087E6B)
                : const Color(0xFFEAF8F5),
            foregroundColor: isPrimary ? Colors.white : const Color(0xFF087E6B),
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
    final actualPhone = phone?.trim();
    final actualEmail = email?.trim();
    final displayPhone = actualPhone?.isNotEmpty == true
        ? actualPhone!
        : 'Chưa cập nhật số điện thoại';
    final displayEmail = actualEmail?.isNotEmpty == true
        ? actualEmail!
        : 'Chưa cập nhật email';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Align(
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
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Avatar
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade300,
                        child:
                            (avatarUrl != null && avatarUrl!.startsWith('http'))
                            ? Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name and Info
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF142523),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đã kết nối Double Opt-in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SourceSansPro',
                      color: Color(0xFF087E6B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact Details Cards
                  _buildInfoCard(
                    'Số điện thoại',
                    displayPhone,
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Email liên hệ',
                    displayEmail,
                    Icons.email_outlined,
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  _buildActionButton('Nhắn tin', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {'partnerId': contactId, 'partnerName': name},
                    );
                  }, isPrimary: true),
                  _buildActionButton('Xem hồ sơ chi tiết', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.roommateProfile,
                      arguments: {'userId': contactId, 'partnerName': name},
                    );
                  }),
                  _buildActionButton('Báo cáo vi phạm', () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.reportViolation,
                      arguments: {'targetUserId': contactId},
                    );
                  }),
                  _buildActionButton('Hủy kết nối', () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.cancelConnection,
                      arguments: {'partnerId': contactId},
                    );
                    if (res == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
