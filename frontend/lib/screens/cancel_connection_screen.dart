import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/penpot_back_button.dart';

class CancelConnectionScreen extends StatefulWidget {
  final int? partnerId;

  const CancelConnectionScreen({super.key, this.partnerId});

  @override
  State<CancelConnectionScreen> createState() => _CancelConnectionScreenState();
}

class _CancelConnectionScreenState extends State<CancelConnectionScreen> {
  bool _isSubmitting = false;

  Future<void> _handleCancelConnection() async {
    if (widget.partnerId == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await ApiService().cancelConnection(widget.partnerId!);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã hủy kết nối thành công.'),
          backgroundColor: Color(0xFF087E6B),
        ),
      );
      nav.pop(true);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                  const Text(
                    'Hủy kết nối',
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
                      child: const Center(
                        child: Icon(
                          Icons.link_off,
                          size: 48,
                          color: Color(0xFF087E6B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Ngừng chia sẻ liên hệ?',
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
                    const Text(
                      'Hai bạn sẽ không còn trong danh sách\nkết nối của nhau.',
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
            
            // Bottom Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleCancelConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087E6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Xác nhận hủy kết nối',
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
                        // Keep connection (cancel)
                        Navigator.pop(context);
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
                        'Giữ kết nối',
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
          ],
        ),
      ),
    );
  }
}
