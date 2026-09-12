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
}
