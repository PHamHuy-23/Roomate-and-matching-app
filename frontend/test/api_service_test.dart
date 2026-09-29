import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

void main() {
  tearDown(() => ApiService().clearAuthToken());

  test('ApiService dùng chung token giữa các màn hình', () {
    final loginService = ApiService();
    final homeService = ApiService();

    loginService.setAuthToken('jwt-token');

    expect(homeService.authToken, 'jwt-token');
    expect(homeService.hasAuthToken, isTrue);
  });

  test('clearAuthToken xóa phiên dùng chung bao gồm cả refreshToken', () {
    final service = ApiService()
      ..setTokens(accessToken: 'jwt-token', refreshToken: 'refresh-sample-token');

    expect(service.hasRefreshToken, isTrue);
    expect(service.refreshToken, 'refresh-sample-token');

    service.clearAuthToken();

    expect(service.authToken, isNull);
    expect(service.hasAuthToken, isFalse);
    expect(service.refreshToken, isNull);
    expect(service.hasRefreshToken, isFalse);
  });

  test('AuthUser trích xuất refreshToken từ auth response payload', () {
    final payload = {
      'accessToken': 'access-token-123',
      'refreshToken': 'refresh-token-456',
      'userId': 42,
      'email': 'quochuy@example.com',
      'fullName': 'Quốc Huy',
      'role': 'ROLE_USER',
    };

    final user = AuthUser.fromJson(payload);

    expect(user.token, 'access-token-123');
    expect(user.refreshToken, 'refresh-token-456');
    expect(user.userId, 42);
  });

  test('payload đăng ký chứa ngày sinh và trường đại học', () {
    final payload = ApiService.createRegistrationPayload(
      email: 'new.user@example.com',
      password: '123456',
      fullName: 'Người dùng mới',
      gender: 'MALE',
      phone: '0901234567',
      birthDate: DateTime(2004, 4, 12),
      university: 'Đại học Quốc gia TP.HCM',
    );

    expect(payload['birthDate'], '2004-04-12');
    expect(payload['university'], 'Đại học Quốc gia TP.HCM');
  });
}
