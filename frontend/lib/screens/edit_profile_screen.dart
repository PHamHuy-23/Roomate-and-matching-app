import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService? apiService;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
    this.apiService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ApiService _api;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _universityCtrl;
  late TextEditingController _bioCtrl; // Not in old Profile but in Penpot
  
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _nameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _universityCtrl = TextEditingController(text: widget.currentUser.university ?? '');
    _bioCtrl = TextEditingController(text: ''); // Should be loaded from currentUser if available
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _universityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ và tên')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    
    // We update using the existing API if possible. The old profile screen used updateProfile 
    // with phone, gender, birthDate etc. For now we use the ones we have in the UI, 
    // keeping old values for the missing fields, since Penpot design for this screen only has Name, University, Bio.
    try {
      final ok = await _api.updateProfile(
        widget.currentUser.userId,
        newName,
        widget.currentUser.phone ?? '',
        widget.currentUser.gender,
        widget.currentUser.birthDate ?? DateTime(2000), // fallback if null
        _universityCtrl.text.trim(),
      );

      if (mounted && ok) {
        final updatedUser = widget.currentUser.copyWith(
          fullName: newName,
          university: _universityCtrl.text.trim(),
        );

        context.read<AuthSession>().updateUser(updatedUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi'),
            backgroundColor: Color(0xFF087e6b),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSansPro',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontFamily: 'SourceSansPro',
              color: Colors.black,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.currentUser.avatarUrl;
    final hasValidAvatar = avatarUrl != null &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar replacement based on Penpot design
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      '‹',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SourceSansPro',
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chỉnh sửa hồ sơ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SourceSansPro',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thông tin giúp bạn tìm người phù hợp',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'SourceSansPro',
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Avatar section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.avatarPicker);
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 41,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: hasValidAvatar ? NetworkImage(avatarUrl) : null,
                                  child: !hasValidAvatar
                                      ? Text(
                                          widget.currentUser.fullName.isNotEmpty
                                              ? widget.currentUser.fullName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Đổi ảnh đại diện',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SourceSansPro',
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Fields
                    _buildTextField(
                      label: 'Họ và tên',
                      controller: _nameCtrl,
                    ),
                    _buildTextField(
                      label: 'Trường học / nghề nghiệp',
                      controller: _universityCtrl,
                    ),
                    _buildTextField(
                      label: 'Giới thiệu bản thân',
                      controller: _bioCtrl,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),
                    
                    // Email Verification Status
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email: ${widget.currentUser.email} · Đã xác minh',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'SourceSansPro',
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087e6b),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu thay đổi',
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
