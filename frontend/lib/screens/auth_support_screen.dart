import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_routes.dart';

enum AuthSupportMode { welcome, verifyEmail, forgotPassword, newPassword, changePassword }

class AuthSupportScreen extends StatefulWidget {
  const AuthSupportScreen({required this.mode, super.key, this.email});

  final AuthSupportMode mode;
  final String? email;

  @override
  State<AuthSupportScreen> createState() => _AuthSupportScreenState();
}

class _AuthSupportScreenState extends State<AuthSupportScreen> {
  static const _canvas = Color(0xFFF5F8F7);
  static const _surface = Colors.white;
  static const _ink = Color(0xFF142523);
  static const _muted = Color(0xFF52625F);
  static const _border = Color(0xFFDCE6E3);
  static const _primary = Color(0xFF087E6B);
  static const _danger = Color(0xFFD9485F);

  late final TextEditingController _emailCtrl;
  final _codeControllers = <TextEditingController>[];
  final _codeFocusNodes = <FocusNode>[];
  final _currentPasswordCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email ?? '');
    for (var index = 0; index < 6; index++) {
      _codeControllers.add(TextEditingController());
      _codeFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    _currentPasswordCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case AuthSupportMode.welcome:
        return 'Roommate Hub';
      case AuthSupportMode.verifyEmail:
        return 'Xác minh email';
      case AuthSupportMode.forgotPassword:
        return 'Quên mật khẩu';
      case AuthSupportMode.newPassword:
        return 'Tạo mật khẩu mới';
      case AuthSupportMode.changePassword:
        return 'Đổi mật khẩu';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case AuthSupportMode.welcome:
        return 'Tìm bạn hợp. Tìm nơi thuộc về.';
      case AuthSupportMode.verifyEmail:
        return 'Mã được gửi đến ${widget.email ?? 'huy@example.com'}';
      case AuthSupportMode.forgotPassword:
        return 'Nhận mã để tạo mật khẩu mới';
      case AuthSupportMode.newPassword:
        return 'Nhập mã trong email khôi phục';
      case AuthSupportMode.changePassword:
        return 'Cập nhật mật khẩu để bảo vệ tài khoản';
    }
  }

  InputDecoration _decoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  }

  Widget _field(String label, Widget child) {
    return Padding(
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
          child,
        ],
      ),
    );
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng này đang chờ API backend được triển khai.'),
      ),
    );
  }

  void _submit() {
    switch (widget.mode) {
      case AuthSupportMode.welcome:
        return;
      case AuthSupportMode.verifyEmail:
        if (_verificationCode.length < 6) {
          _showError('Vui lòng nhập đủ 6 ký tự mã xác minh.');
          return;
        }
        break;
      case AuthSupportMode.forgotPassword:
        if (!_validEmail(_emailCtrl.text.trim())) {
          _showError('Email không đúng định dạng.');
          return;
        }
        break;
      case AuthSupportMode.newPassword:
        if (_verificationCode.length < 6) {
          _showError('Vui lòng nhập đủ 6 ký tự mã xác nhận.');
          return;
        }
        if (_passwordCtrl.text.length < 8) {
          _showError('Mật khẩu phải có ít nhất 8 ký tự.');
          return;
        }
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          _showError('Mật khẩu xác nhận không khớp.');
          return;
        }
        break;
      case AuthSupportMode.changePassword:
        if (_currentPasswordCtrl.text.trim().isEmpty) {
          _showError('Vui lòng nhập mật khẩu hiện tại.');
          return;
        }
        if (_passwordCtrl.text.length < 8) {
          _showError('Mật khẩu phải có ít nhất 8 ký tự.');
          return;
        }
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          _showError('Mật khẩu xác nhận không khớp.');
          return;
        }
        break;
    }
    _showUnavailable();
  }

  String get _verificationCode =>
      _codeControllers.map((controller) => controller.text).join();

  bool _validEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _danger),
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController controller, {
    required bool obscure,
    required VoidCallback onToggle,
    String hint = 'Tối thiểu 8 ký tự',
    Key? key,
  }) {
    return _field(
      label,
      TextField(
        key: key,
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        decoration: _decoration(
          hint,
          suffixIcon: IconButton(
            tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: _muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _verificationCodeFields({required Key firstFieldKey}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        _codeControllers.length,
        (index) => SizedBox(
          width: 42,
          child: TextField(
            key: index == 0 ? firstFieldKey : null,
            controller: _codeControllers[index],
            focusNode: _codeFocusNodes[index],
            autofocus: index == 0,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < _codeFocusNodes.length - 1) {
                _codeFocusNodes[index + 1].requestFocus();
              }
            },
            decoration: _decoration('').copyWith(counterText: ''),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    switch (widget.mode) {
      case AuthSupportMode.welcome:
        return Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_work_outlined, color: _primary, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'Một tổ ấm mới,\nmột khởi đầu vui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 22, height: 1.25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Khám phá phòng trọ và kết nối với người\ncó cùng nhịp sống với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            _primaryButton(
              'Bắt đầu',
              () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.login,
                arguments: const {'register': true},
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.login,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Tôi đã có tài khoản'),
            ),
          ],
        );
      case AuthSupportMode.verifyEmail:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kiểm tra hộp thư của bạn',
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập mã 6 số để bảo vệ tài khoản.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nếu chưa thấy email, kiểm tra mục Spam.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _verificationCodeFields(
              firstFieldKey: const Key('verify_email_code_field'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showUnavailable,
              child: const Text('Gửi lại mã sau 00:45'),
            ),
            _primaryButton('Xác minh & tiếp tục', _submit),
            TextButton(
              onPressed: _showUnavailable,
              child: const Text('Đổi email'),
            ),
          ],
        );
      case AuthSupportMode.forgotPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bạn sẽ sớm quay lại thôi.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _field(
              'Email tài khoản',
              TextField(
                key: const Key('forgot_password_email_field'),
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('huy@example.com'),
              ),
            ),
            _primaryButton('Gửi mã khôi phục', _submit),
            const SizedBox(height: 16),
            const Text(
              'Nếu email có tài khoản, hướng dẫn khôi phục sẽ được gửi đến hộp thư của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ],
        );
      case AuthSupportMode.newPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              'Mã xác nhận',
              _verificationCodeFields(
                firstFieldKey: const Key('new_password_code_field'),
              ),
            ),
            _passwordField(
              'Mật khẩu mới',
              _passwordCtrl,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              key: const Key('new_password_field'),
            ),
            _passwordField(
              'Xác nhận mật khẩu mới',
              _confirmPasswordCtrl,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              key: const Key('new_password_confirm_field'),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Dùng ít nhất 8 ký tự gồm chữ hoa, chữ thường,\nchữ số và ký tự đặc biệt.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ),
            _primaryButton('Lưu mật khẩu & đăng nhập', _submit),
          ],
        );
      case AuthSupportMode.changePassword:
        return Column(
          children: [
            _passwordField(
              'Mật khẩu hiện tại',
              _currentPasswordCtrl,
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              hint: 'Nhập mật khẩu hiện tại',
              key: const Key('current_password_field'),
            ),
            _passwordField(
              'Mật khẩu mới',
              _passwordCtrl,
              obscure: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              key: const Key('change_password_field'),
            ),
            _passwordField(
              'Xác nhận mật khẩu mới',
              _confirmPasswordCtrl,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              key: const Key('change_password_confirm_field'),
            ),
            _primaryButton('Lưu mật khẩu', _submit),
          ],
        );
    }
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBack = widget.mode != AuthSupportMode.welcome;
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Quay lại',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        )
                      else
                        const SizedBox(height: 32),
                      const SizedBox(height: 20),
                      Text(
                        _title,
                        textAlign: widget.mode == AuthSupportMode.welcome
                            ? TextAlign.center
                            : TextAlign.left,
                        style: const TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle,
                        textAlign: widget.mode == AuthSupportMode.welcome
                            ? TextAlign.center
                            : TextAlign.left,
                        style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      _form(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
