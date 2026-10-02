import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../models/user_preference.dart';
import '../navigation/app_routes.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';
import '../widgets/penpot_back_button.dart';

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
  late TextEditingController _bioCtrl;

  bool _isUpdating = false;
  bool _isLoadingBio = true;
  bool _hasPreferences = false;
  String? _bioLoadError;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _nameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _universityCtrl = TextEditingController(
      text: widget.currentUser.university ?? '',
    );
    _bioCtrl = TextEditingController();
    _loadBio();
  }

  Future<void> _loadBio() async {
    setState(() {
      _isLoadingBio = true;
      _bioLoadError = null;
    });
    try {
      final data = await _api.getPreferences(widget.currentUser.userId);
      if (!mounted) return;
      setState(() {
        _hasPreferences = data != null;
        _bioCtrl.text = data == null
            ? ''
            : UserPreference.fromJson(data).bioNote ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _bioLoadError =
            'Không thể tải giới thiệu. Vui lòng thử lại trước khi lưu.',
      );
    } finally {
      if (mounted) setState(() => _isLoadingBio = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _universityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isUpdating || _isLoadingBio || _bioLoadError != null) return;
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ và tên')));
      return;
    }

    setState(() => _isUpdating = true);

    final university = _universityCtrl.text.trim();
    // A missing, unchanged university is omitted rather than sent as an invalid empty string.
    final universityUpdate =
        university.isEmpty && widget.currentUser.university == null
        ? null
        : university;
    try {
      final ok = await _api.updateProfile(
        widget.currentUser.userId,
        newName,
        widget.currentUser.phone ?? '',
        widget.currentUser.gender,
        widget.currentUser.birthDate,
        universityUpdate,
        bioNote: _hasPreferences ? _bioCtrl.text.trim() : null,
      );

      if (!ok) throw ApiException('Không thể cập nhật hồ sơ');

      if (mounted && ok) {
        final updatedUser = widget.currentUser.copyWith(
          fullName: newName,
          university: universityUpdate ?? widget.currentUser.university,
        );

        context.read<AuthSession>().updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi'),
            backgroundColor: Color(0xFF087e6b),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Cập nhật thất bại'),
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
    bool enabled = true,
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
            key: ValueKey(label),
            enabled: enabled && !_isUpdating,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
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
    final hasValidAvatar =
        avatarUrl != null &&
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
                  const PenpotBackButton(),
                  const SizedBox(width: 10),
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
                              Navigator.pushNamed(
                                context,
                                AppRoutes.avatarPicker,
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 41,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: hasValidAvatar
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: !hasValidAvatar
                                      ? Text(
                                          widget.currentUser.fullName.isNotEmpty
                                              ? widget.currentUser.fullName[0]
                                                    .toUpperCase()
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
                    _buildTextField(label: 'Họ và tên', controller: _nameCtrl),
                    _buildTextField(
                      label: 'Trường học / nghề nghiệp',
                      controller: _universityCtrl,
                    ),
                    _buildTextField(
                      label: 'Giới thiệu bản thân',
                      controller: _bioCtrl,
                      maxLines: 3,
                      enabled:
                          !_isLoadingBio &&
                          _bioLoadError == null &&
                          _hasPreferences,
                    ),
                    if (_isLoadingBio)
                      const Text('Đang tải giới thiệu...')
                    else if (_bioLoadError != null) ...[
                      Text(_bioLoadError!),
                      TextButton(
                        onPressed: _loadBio,
                        child: const Text('Thử lại'),
                      ),
                    ] else if (!_hasPreferences)
                      const Text(
                        'Hãy thiết lập tiêu chí ghép trọ trước khi thêm giới thiệu.',
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
                  onPressed:
                      _isUpdating || _isLoadingBio || _bioLoadError != null
                      ? null
                      : _handleSave,
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
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
