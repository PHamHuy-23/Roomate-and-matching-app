import 'dart:convert';

/// Rules for new passwords, not login or the current password of an existing account.
class AuthValidation {
  static String? newPasswordError(String password) {
    if (password.trim().isEmpty) return 'Mật khẩu không được để trống';
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (utf8.encode(password).length > 72) {
      return 'Mật khẩu không được vượt quá 72 byte UTF-8';
    }
    return null;
  }

  static String? registrationFieldsError({
    required String email,
    required String fullName,
    required String gender,
    required String phone,
    required String university,
  }) {
    if (email.length > 100) return 'Email không được vượt quá 100 ký tự';
    if (fullName.length > 100) return 'Họ tên không được vượt quá 100 ký tự';
    if (!const {'MALE', 'FEMALE', 'OTHER'}.contains(gender.toUpperCase())) {
      return 'Giới tính phải là MALE, FEMALE hoặc OTHER';
    }
    if (phone.length > 20) return 'Số điện thoại không được vượt quá 20 ký tự';
    if (university.length > 150) {
      return 'Tên trường không được vượt quá 150 ký tự';
    }
    return null;
  }
}
