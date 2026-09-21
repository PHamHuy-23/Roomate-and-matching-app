import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../navigation/app_routes.dart';
import '../state/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRegister = false});

  final bool initialRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _surface = Colors.white;
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  static const _border = Color(0xFFDCE6E3);
  static const _primary = Color(0xFF087E6B);
  static const _danger = Color(0xFFD9485F);

  late bool _isLogin;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'MALE';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.initialRegister;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
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
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: _primary)),
        child: child!,
      ),
    );
    if (selectedDate == null || !mounted) return;

    setState(() {
      _birthDate = selectedDate;
      _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final isLogin = _isLogin;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ email và mật khẩu'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không đúng định dạng'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    if (!isLogin) {
      if (_nameCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.trim().isEmpty ||
          _universityCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đầy đủ thông tin đăng ký'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
      if (password.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu phải có ít nhất 8 ký tự'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
      if (_confirmPassCtrl.text != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu xác nhận không khớp'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày sinh'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đồng ý với Điều khoản và Quyền riêng tư'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final session = context.read<AuthSession>();
      if (isLogin) {
        await session.login(email, password);
      } else {
        await session.register(
          email,
          password,
          _nameCtrl.text.trim(),
          _gender,
          _phoneCtrl.text.trim(),
          _birthDate!,
          _universityCtrl.text.trim(),
        );
      }

      final signedInUser = session.user;
      final isAdmin = signedInUser != null &&
          {
            'ADMIN',
            'ROLE_ADMIN',
          }.contains(signedInUser.role.trim().toUpperCase());
      final hasPreferences =
          isLogin && !isAdmin ? await session.hasPreferences() : null;
      if (mounted && session.isAuthenticated) {
        final needsSurvey = isLogin && hasPreferences == false;
        final destination = isAdmin
            ? AppRoutes.adminDashboard
            : (needsSurvey || !isLogin ? AppRoutes.survey : AppRoutes.home);
        Navigator.pushReplacementNamed(
          context,
          destination,
          arguments: !isAdmin && (needsSurvey || !isLogin)
              ? const {'fromRegistration': true}
              : null,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      );

  Widget _labeledField(String label, Widget field) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Quay lại bắt đầu',
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.welcome,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    )
                  else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Quay lại bắt đầu',
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.welcome,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _isLogin ? 'Chào bạn trở lại!' : 'Tạo tài khoản',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Đăng nhập để tiếp tục hành trình'
                        : 'Cùng tìm một người ở ghép phù hợp',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  if (!_isLogin)
                    _labeledField(
                      'Họ và tên',
                      TextField(
                        key: const Key('register_name_field'),
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        cursorColor: _primary,
                        decoration: _inputDecoration('Nhập tên của bạn'),
                      ),
                    ),
                  _labeledField(
                    'Email',
                    TextField(
                      key: const Key('email_field'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      cursorColor: _primary,
                      decoration: _inputDecoration(
                        _isLogin ? 'huy@example.com' : 'ban@example.com',
                      ),
                    ),
                  ),
                  _labeledField(
                    'Mật khẩu',
                    TextField(
                      key: const Key('password_field'),
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      cursorColor: _primary,
                      decoration: _inputDecoration(
                        _isLogin ? 'Nhập mật khẩu' : 'Tối thiểu 8 ký tự',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: _primary),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                  if (!_isLogin) ...[
                    _labeledField(
                      'Xác nhận mật khẩu',
                      TextField(
                        key: const Key('register_confirm_password_field'),
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirmPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        cursorColor: _primary,
                        decoration: _inputDecoration(
                          'Nhập lại mật khẩu',
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Hiện mật khẩu xác nhận'
                                : 'Ẩn mật khẩu xác nhận',
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Mật khẩu gồm chữ hoa, chữ thường,\nchữ số và ký tự đặc biệt.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Thông tin để tìm bạn ở ghép phù hợp',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _labeledField(
                      'Số điện thoại',
                      TextField(
                        key: const Key('register_phone_field'),
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        cursorColor: _primary,
                        decoration: _inputDecoration('0901234567'),
                      ),
                    ),
                    _labeledField(
                      'Ngày sinh',
                      TextField(
                        key: const Key('register_birth_date_field'),
                        controller: _birthDateCtrl,
                        readOnly: true,
                        onTap: _selectBirthDate,
                        decoration: _inputDecoration(
                          'Ngày / Tháng / Năm',
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: _muted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    _labeledField(
                      'Trường đại học',
                      TextField(
                        key: const Key('register_university_field'),
                        controller: _universityCtrl,
                        textCapitalization: TextCapitalization.words,
                        cursorColor: _primary,
                        decoration: _inputDecoration('Tên trường của bạn'),
                      ),
                    ),
                    _labeledField(
                      'Giới tính',
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        isExpanded: true,
                        decoration: _inputDecoration('Chọn giới tính'),
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                        ],
                        onChanged: (val) => setState(() => _gender = val!),
                      ),
                    ),
                  ],
                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            key: const Key('register_terms_checkbox'),
                            value: _acceptedTerms,
                            activeColor: _primary,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 11),
                              child: Text(
                                'Tôi đồng ý Điều khoản & Quyền riêng tư',
                                style: TextStyle(color: _ink, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                color: _surface,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    style: TextButton.styleFrom(foregroundColor: _primary),
                    child: Text(
                      _isLogin ? 'Tạo tài khoản' : 'Đã có tài khoản · Đăng nhập',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 80),
                    const Text(
                      'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
