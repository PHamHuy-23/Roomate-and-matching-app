import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';
import '../widgets/penpot_back_button.dart';

class AvatarPickerScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService? apiService;
  final ImagePicker? imagePicker;

  const AvatarPickerScreen({
    super.key,
    required this.currentUser,
    this.apiService,
    this.imagePicker,
  });

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  static const int _maxBytes = 5 * 1024 * 1024;

  late final ImagePicker _picker;
  late final ApiService _api;
  XFile? _selectedFile;
  Uint8List? _selectedBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _api = widget.apiService ?? ApiService();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh phải nhỏ hơn hoặc bằng 5 MB')),
      );
      return;
    }
    setState(() {
      _selectedFile = file;
      _selectedBytes = bytes;
    });
  }

  void _cancel() {
    setState(() {
      _selectedFile = null;
      _selectedBytes = null;
    });
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _useImage() async {
    final file = _selectedFile;
    final bytes = _selectedBytes;
    if (file == null || bytes == null || _isUploading) return;
    final session = context.read<AuthSession>();
    final generation = session.generation;
    if (!session.isCurrentSession(generation, widget.currentUser.userId)) {
      return;
    }
    setState(() => _isUploading = true);
    try {
      final ticket = await _api.uploadImage(
        bytes: bytes,
        fileName: file.name,
        contentType: _contentType(file.name),
        purpose: 'avatar',
      );
      if (!mounted ||
          !session.isCurrentSession(generation, widget.currentUser.userId)) {
        return;
      }
      final avatarUrl = await _api.confirmAvatar(ticket.objectKey);
      if (!mounted ||
          !session.isCurrentSession(generation, widget.currentUser.userId)) {
        return;
      }
      session.updateUser(
        session.user!.copyWith(avatarUrl: avatarUrl),
        expectedGeneration: generation,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện')));
      Navigator.pop(context, avatarUrl);
    } on ApiException catch (error) {
      if (!mounted ||
          !session.isCurrentSession(generation, widget.currentUser.userId)) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
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
                image: _selectedBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_selectedBytes!),
                        fit: BoxFit.cover,
                      )
                    : (widget.currentUser.avatarUrl != null &&
                              widget.currentUser.avatarUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                widget.currentUser.avatarUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null),
              ),
              child:
                  (_selectedBytes == null &&
                      (widget.currentUser.avatarUrl == null ||
                          widget.currentUser.avatarUrl!.isEmpty))
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
                      onPressed: _isUploading ? null : _pickImage,
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
                  if (_selectedBytes != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _useImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087E6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
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
                        onPressed: _isUploading ? null : _cancel,
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
