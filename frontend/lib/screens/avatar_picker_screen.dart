import 'package:flutter/material.dart';
import '../models/auth_user.dart';

class AvatarPickerScreen extends StatefulWidget {
  final AuthUser currentUser;
  
  const AvatarPickerScreen({super.key, required this.currentUser});
  
  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  // To simulate picking an image
  bool _hasPickedImage = false;
  
  void _pickImage() {
    setState(() {
      _hasPickedImage = true;
    });
  }
  
  void _cancel() {
    setState(() {
      _hasPickedImage = false;
    });
  }
  
  void _useImage() {
    // In a real app we'd upload this image. For now just pop.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Ảnh đại diện',
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
                  'Chọn ảnh rõ mặt để bạn bè nhận ra bạn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'SourceSansPro',
                    color: Color(0xFF65746F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            
            // Image Preview (Square)
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                image: _hasPickedImage
                    ? const DecorationImage(
                        image: NetworkImage('https://via.placeholder.com/260'), // mock placeholder
                        fit: BoxFit.cover,
                      )
                    : (widget.currentUser.avatarUrl != null && widget.currentUser.avatarUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.currentUser.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: (!_hasPickedImage && (widget.currentUser.avatarUrl == null || widget.currentUser.avatarUrl!.isEmpty))
                  ? const Center(
                      child: Icon(Icons.person, size: 100, color: Colors.grey),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Ảnh vuông · JPG hoặc PNG · Tối đa 5 MB',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'SourceSansPro',
                color: Color(0xFF65746F),
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF8F5),
                        foregroundColor: const Color(0xFF087E6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Chọn ảnh từ thư viện',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SourceSansPro',
                        ),
                      ),
                    ),
                  ),
                  if (_hasPickedImage) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _useImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087E6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Dùng ảnh này',
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
                        onPressed: _cancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF8F5),
                          foregroundColor: const Color(0xFF087E6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SourceSansPro',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
