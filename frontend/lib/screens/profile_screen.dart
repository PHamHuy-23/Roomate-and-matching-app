import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auth_user.dart';
import '../models/user_preference.dart';
import '../navigation/app_routes.dart';
import '../screens/survey_screen.dart';
import '../services/api_service.dart';
import '../state/auth_session.dart';

class ProfileScreen extends StatefulWidget {
  final AuthUser currentUser;
  final ApiService? apiService;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    this.apiService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiService _api;
  late AuthUser _currentUser;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthDateCtrl;
  late TextEditingController _universityCtrl;
  DateTime? _birthDate;
  late String _gender;

  bool _isUpdatingProfile = false;
  bool _isLoadingPreferences = true;
  String? _preferenceError;
  UserPreference? _preference;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _currentUser = widget.currentUser;
    _nameCtrl = TextEditingController(text: _currentUser.fullName);
    _phoneCtrl = TextEditingController(text: _currentUser.phone ?? '');
    _birthDate = _currentUser.birthDate;
    _birthDateCtrl = TextEditingController(
      text: _birthDate == null ? '' : _formatDate(_birthDate!),
    );
    _universityCtrl = TextEditingController(
      text: _currentUser.university ?? '',
    );
    _gender = _currentUser.gender;
    _loadPreferences();
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
    if (selectedDate == null) return;

    setState(() {
      _birthDate = selectedDate;
      _birthDateCtrl.text = _formatDate(selectedDate);
    });
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
      _preferenceError = null;
    });

    try {
      final data = await _api.getPreferences(_currentUser.userId);
      if (mounted) {
        setState(() {
          _preference = data != null ? UserPreference.fromJson(data) : null;
          _isLoadingPreferences = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _preferenceError = e is ApiException
              ? e.message
              : 'Không thể tải tiêu chí ghép trọ. Vui lòng thử lại.';
          _isLoadingPreferences = false;
        });
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) return;

    setState(() => _isUpdatingProfile = true);
    final newName = _nameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final newGender = _gender;
    final newUniversity = _universityCtrl.text.trim();

    try {
      final ok = await _api.updateProfile(
        _currentUser.userId,
        newName,
        newPhone,
        newGender,
        _birthDate!,
        newUniversity,
      );

      if (mounted && ok) {
        final updatedUser = _currentUser.copyWith(
          fullName: newName,
          phone: newPhone,
          gender: newGender,
          birthDate: _birthDate,
          university: newUniversity,
        );

        context.read<AuthSession>().updateUser(updatedUser);
        setState(() {
          _currentUser = updatedUser;
          _isUpdatingProfile = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
        final msg = e is ApiException
            ? e.message
            : 'Cập nhật thất bại: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToSurvey() async {
    await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyScreen(
          userId: _currentUser.userId,
          apiService: _api,
        ),
      ),
    );
    if (mounted) {
      await _loadPreferences();
    }
  }

  void _handleChangePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Đổi Mật Khẩu'),
          ],
        ),
        content: const Text(
          'Tính năng đổi mật khẩu đang được phát triển ở phiên bản tiếp theo (Giai đoạn Backend Security Milestone 4).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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

  Widget _buildPreferenceChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tiêu chí ghép trọ hiện tại',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Tooltip(
                message: 'Cập nhật tiêu chí ghép trọ',
                child: OutlinedButton.icon(
                  onPressed: _navigateToSurvey,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Cập nhật'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPreferences)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Đang tải tiêu chí ghép trọ...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_preferenceError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _preferenceError!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadPreferences,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            )
          else if (_preference == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rule_folder_outlined,
                    size: 40,
                    color: Colors.indigo.shade300,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa thiết lập tiêu chí ghép trọ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hãy hoàn thành bài khảo sát để hệ thống tính toán điểm tương thích và gợi ý bạn cùng phòng tốt nhất!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToSurvey,
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Làm khảo sát ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPreferenceChip(
                  icon: Icons.payments_outlined,
                  label: 'Ngân sách',
                  value: _preference!.budgetDisplay,
                  color: Colors.indigo,
                ),
                _buildPreferenceChip(
                  icon: Icons.location_on_outlined,
                  label: 'Khu vực',
                  value: _preference!.districtDisplay,
                  color: Colors.teal,
                ),
                _buildPreferenceChip(
                  icon: Icons.bedtime_outlined,
                  label: 'Giờ giấc',
                  value: _preference!.sleepHabitDisplay,
                  color: Colors.purple,
                ),
                _buildPreferenceChip(
                  icon: Icons.cleaning_services_outlined,
                  label: 'Sạch sẽ',
                  value: _preference!.cleanlinessDisplay,
                  color: Colors.amber.shade900,
                ),
                _buildPreferenceChip(
                  icon: Icons.smoke_free_outlined,
                  label: 'Hút thuốc',
                  value: _preference!.smokingDisplay,
                  color: _preference!.isSmoking ? Colors.red : Colors.green,
                ),
                _buildPreferenceChip(
                  icon: Icons.pets_outlined,
                  label: 'Thú cưng',
                  value: _preference!.petDisplay,
                  color: Colors.blueGrey,
                ),
                if (_preference!.cookingHabit != null)
                  _buildPreferenceChip(
                    icon: Icons.soup_kitchen_outlined,
                    label: 'Nấu ăn',
                    value: _preference!.cookingHabit!,
                    color: Colors.deepOrange,
                  ),
                if (_preference!.personality != null)
                  _buildPreferenceChip(
                    icon: Icons.psychology_outlined,
                    label: 'Tính cách',
                    value: _preference!.personality!,
                    color: Colors.blue,
                  ),
                if (_preference!.targetGender != null)
                  _buildPreferenceChip(
                    icon: Icons.wc_outlined,
                    label: 'Ghép với',
                    value: _preference!.targetGender!,
                    color: Colors.brown,
                  ),
              ],
            ),
            if (_preference!.interests.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Sở thích:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _preference!.interests
                    .map(
                      (interest) => Chip(
                        label: Text(
                          interest,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.indigo.shade50,
                        side: BorderSide(color: Colors.indigo.shade100),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (_preference!.bioNote != null &&
                _preference!.bioNote!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _preference!.bioNote!,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEditProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Chỉnh sửa thông tin cá nhân',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                if (v.trim().length < 2) {
                  return 'Họ và tên phải có ít nhất 2 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: 'Nhập số điện thoại (10 số, ví dụ 0901234567)',
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final phone = v.trim();
                  if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
                    return 'Số điện thoại không hợp lệ (gồm 10 chữ số bắt đầu bằng số 0)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('profile_birth_date_field'),
              controller: _birthDateCtrl,
              readOnly: true,
              onTap: _selectBirthDate,
              decoration: const InputDecoration(
                labelText: 'Ngày sinh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) => _birthDate == null
                  ? 'Vui lòng chọn ngày sinh'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('profile_university_field'),
              controller: _universityCtrl,
              maxLength: 150,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Trường đại học',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập trường đại học'
                  : null,
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
              onChanged: (val) {
                if (val != null) setState(() => _gender = val);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isUpdatingProfile ? null : _handleUpdate,
              icon: _isUpdatingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isUpdatingProfile ? 'Đang lưu...' : 'Lưu Thay Đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Cài đặt tài khoản',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: 'Đổi mật khẩu tài khoản',
            child: OutlinedButton.icon(
              onPressed: _handleChangePassword,
              icon: const Icon(Icons.lock_outline, color: Colors.indigo),
              label: const Text(
                'Đổi Mật Khẩu',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.indigo),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: 'Đăng xuất khỏi ứng dụng',
            child: OutlinedButton.icon(
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _currentUser.avatarUrl;
    final hasValidAvatar =
        avatarUrl != null &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPreferences,
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Profile Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.indigo.shade100,
                          backgroundImage: hasValidAvatar
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: !hasValidAvatar
                              ? Text(
                                  _currentUser.fullName.isNotEmpty
                                      ? _currentUser.fullName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentUser.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser.email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            Chip(
                              avatar: Icon(
                                _currentUser.gender == 'FEMALE'
                                    ? Icons.female
                                    : Icons.male,
                                size: 16,
                                color: Colors.indigo,
                              ),
                              label: Text(
                                _currentUser.gender == 'FEMALE'
                                    ? 'Nữ'
                                    : 'Nam',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.indigo.shade50,
                              side: BorderSide(color: Colors.indigo.shade100),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              avatar: Icon(
                                _currentUser.role.contains('ADMIN')
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                size: 16,
                                color: Colors.teal,
                              ),
                              label: Text(
                                _currentUser.role.contains('ADMIN')
                                    ? 'Quản trị viên'
                                    : 'Người tìm trọ',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.teal.shade50,
                              side: BorderSide(color: Colors.teal.shade100),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Preferences Section
                  _buildPreferencesSection(),
                  const SizedBox(height: 16),

                  // 3. Edit Profile Section
                  _buildEditProfileSection(),
                  const SizedBox(height: 16),

                  // 4. Account Settings Section
                  _buildAccountSettingsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
