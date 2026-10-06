import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../models/report_receipt.dart';
import '../widgets/penpot_back_button.dart';

class ReportReceivedScreen extends StatelessWidget {
  const ReportReceivedScreen({super.key, this.receipt});
  final ReportReceipt? receipt;

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
                  Expanded(
                    child: Text(
                      receipt == null ? 'Thông tin báo cáo' : 'Đã nhận báo cáo',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Circle
                    Container(
                      width: 102,
                      height: 102,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF8F5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          receipt == null ? Icons.info_outline : Icons.check,
                          size: 48,
                          color: Color(0xFF087E6B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      receipt == null
                          ? 'Chưa có mã tiếp nhận'
                          : 'Cảm ơn bạn đã phản hồi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      receipt == null
                          ? 'Không có thông tin xác nhận báo cáo từ máy chủ.'
                          : 'Báo cáo #${receipt!.code} đã được tiếp nhận để ban quản trị xem xét.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF65746F),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
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
                    Navigator.popUntil(
                      context,
                      (route) =>
                          route.settings.name == AppRoutes.profile ||
                          route.settings.name == AppRoutes.home ||
                          route.isFirst,
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
                    'Về hồ sơ',
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
