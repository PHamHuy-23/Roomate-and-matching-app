import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../navigation/app_routes.dart';
import '../state/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  final AuthUser currentUser;
  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthDateCtrl;
  late TextEditingController _universityCtrl;
  DateTime? _birthDate;
  late String _gender;
  bool _isLoading = false;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentUser.fullName);
    _phoneCtrl = TextEditingController();
    _birthDate = widget.currentUser.birthDate;
    _birthDateCtrl = TextEditingController(
      text: _birthDate == null ? '' : _formatDate(_birthDate!),
    );
    _universityCtrl = TextEditingController(
      text: widget.currentUser.university ?? '',
    );
    _gender = widget.currentUser.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Chọn ngày sinh',
    );
    if (selectedDate == null || !mounted) return;

    setState(() {
      _birthDate = selectedDate;
      _birthDateCtrl.text = _formatDate(selectedDate);
    });
  }

  Future<void> _handleUpdate() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _universityCtrl.text.trim().isEmpty ||
        _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ tên, ngày sinh và trường đại học'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ok = await context.read<AuthSession>().updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gender: _gender,
        birthDate: _birthDate!,
        university: _universityCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Cập nhật thông tin thành công!' : 'Cập nhật thất bại!',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<AuthSession>().signOut();
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Tài Khoản'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    widget.currentUser.fullName.isNotEmpty
                        ? widget.currentUser.fullName[0]
                        : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.currentUser.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const Divider(height: 32),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Nhập số điện thoại mới',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('profile_birth_date_field'),
                  controller: _birthDateCtrl,
                  readOnly: true,
                  onTap: _selectBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('profile_university_field'),
                  controller: _universityCtrl,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Trường đại học',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                  ],
                  onChanged: (val) => setState(() => _gender = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpdate,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu Thay Đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Đăng Xuất',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
