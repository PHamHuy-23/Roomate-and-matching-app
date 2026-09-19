import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final int? partnerId;
  final String? partnerName;
  
  const ChatScreen({super.key, this.partnerId, this.partnerName});

  Widget _buildReceivedMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSentMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFEAF8F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'SourceSansPro',
            color: Color(0xFF142523),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedImage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 243,
        height: 154,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Center(
          child: Icon(Icons.photo, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = partnerName ?? 'Minh Anh';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      '‹',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF142523),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF142523),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Đã kết nối · Trao đổi về phòng trọ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Container(
                      width: 46,
                      height: 46,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  const Center(
                    child: Text(
                      'HÔM NAY · 14:20',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF65746F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildReceivedMessage('Chào Huy! Bạn muốn xem phòng\nvào chiều thứ Hai phải không?'),
                  
                  _buildSentMessage('Đúng rồi, khoảng 14:00 nhé.\nPhòng có chỗ để xe không bạn?'),
                  
                  _buildReceivedMessage('Có nhé, mình gửi thêm ảnh cho bạn.'),
                  
                  _buildReceivedImage(),
                  
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '14:24 · Đã xem',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SourceSansPro',
                        color: Color(0xFF65746F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFFF5F8F7),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 51,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.5),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn…',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'SourceSansPro',
                            color: Color(0xFF65746F),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // Send action
                    },
                    child: Container(
                      width: 50,
                      height: 51,
                      decoration: BoxDecoration(
                        color: const Color(0xFF087E6B),
                        borderRadius: BorderRadius.circular(25.5),
                      ),
                      child: const Center(
                        child: Text(
                          '↑',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
