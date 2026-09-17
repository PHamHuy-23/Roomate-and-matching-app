import 'package:flutter_test/flutter_test.dart';
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

  test('clearAuthToken xóa phiên dùng chung', () {
    final service = ApiService()..setAuthToken('jwt-token');

    service.clearAuthToken();

    expect(service.authToken, isNull);
    expect(service.hasAuthToken, isFalse);
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
