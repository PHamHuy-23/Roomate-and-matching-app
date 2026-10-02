import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

void main() {
  tearDown(() => ApiService().clearAuthToken());

  test('survey GET keeps the structured fields from the server', () async {
    const data = {
      'moveInDate': '2099-11-04',
      'roomType': 'SHARED',
      'workSchedule': 'DAY',
      'personalValue': 'CLEAN',
    };
    final api = ApiService.withClient(
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/profile/preferences/10');
        return http.Response(jsonEncode(data), 200);
      }),
    );
    expect(await api.getPreferences(10), data);
  });

  for (final invalid in ['[]', '"invalid"']) {
    test(
      'survey GET rejects malformed payload rather than treating it as a new profile: $invalid',
      () async {
        final api = ApiService.withClient(
          MockClient((_) async => http.Response(invalid, 200)),
        );
        await expectLater(api.getPreferences(10), throwsA(isA<ApiException>()));
      },
    );
  }

  test(
    'survey GET still supports genuine not-found and legacy null responses',
    () async {
      for (final response in [
        http.Response('{}', 404),
        http.Response('null', 200),
      ]) {
        final api = ApiService.withClient(MockClient((_) async => response));
        expect(await api.getPreferences(10), isNull);
      }
    },
  );

  test(
    'survey sends and confirms the four structured fields via real API transport',
    () async {
      const fields = {
        'moveInDate': '2099-11-04',
        'roomType': 'PRIVATE',
        'workSchedule': 'NIGHT',
        'personalValue': 'SCHEDULE',
      };
      final api = ApiService.withClient(
        MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/profile/preferences/10');
          expect(jsonDecode(request.body), fields);
          return http.Response(jsonEncode(fields), 200);
        }),
      );
      expect(await api.savePreferences(10, fields), isTrue);
    },
  );

  for (final response in ['{}', '{"roomType":"SHARED"}', '[]']) {
    test(
      'survey does not report success when server omits or disagrees with new fields: $response',
      () async {
        final api = ApiService.withClient(
          MockClient((_) async => http.Response(response, 200)),
        );
        await expectLater(
          api.savePreferences(10, {'roomType': 'PRIVATE'}),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }

  test(
    'API lịch tải đúng endpoint, đổi đúng ID và giữ timezone response',
    () async {
      final payload = <String, dynamic>{
        'id': 55,
        'requesterId': 10,
        'hostId': 20,
        'roomPostId': 123,
        'roomTitle': 'Phòng thật',
        'roomAddress': 'Địa chỉ thật',
        'roomPrice': 2500000,
        'appointmentTime': '2099-11-04T10:30:00+07:00',
        'status': 'PENDING',
        'createdAt': '2026-10-02T10:00:00',
      };
      var calls = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          calls++;
          if (request.method == 'GET') {
            expect(request.url.path, '/api/v1/appointments/my');
            return http.Response(
              jsonEncode([payload]),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/appointments/55/status');
          expect(request.url.queryParameters, {'status': 'CANCELLED'});
          return http.Response(
            jsonEncode({...payload, 'status': 'CANCELLED'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final data = await api.getMyAppointments();
      expect(data.single.id, 55);
      expect(
        data.single.appointmentTime,
        DateTime.parse(payload['appointmentTime'] as String).toLocal(),
      );
      final updated = await api.updateAppointmentStatus(
        data.single.id,
        'CANCELLED',
      );
      expect(updated.id, 55);
      expect(updated.status, 'CANCELLED');
      expect(calls, 2);
    },
  );

  test(
    'cập nhật hồ sơ bỏ qua ngày sinh trống và trường tùy chọn chưa có',
    () async {
      final api = ApiService.withClient(
        MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/profile/user/10');
          expect(request.url.queryParameters, {
            'fullName': 'Tên mới',
            'phone': '',
            'gender': 'MALE',
          });
          return http.Response('{}', 200);
        }),
      );
      expect(
        await api.updateProfile(10, 'Tên mới', '', 'MALE', null, null),
        isTrue,
      );
    },
  );

  test(
    'cập nhật hồ sơ gửi đúng ngày sinh và giới thiệu, kể cả xóa giới thiệu',
    () async {
      final notes = ['Giới thiệu tiếng Việt\nDòng tiếp theo', ''];
      var calls = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          expect(request.url.queryParameters['birthDate'], '2002-05-20');
          expect(
            request.url.queryParameters['university'],
            'Trường thử nghiệm',
          );
          expect(request.url.queryParameters['bioNote'], notes[calls++]);
          return http.Response('{}', 200);
        }),
      );
      for (final note in notes) {
        expect(
          await api.updateProfile(
            10,
            'Tên mới',
            '',
            'MALE',
            DateTime(2002, 5, 20),
            'Trường thử nghiệm',
            bioNote: note,
          ),
          isTrue,
        );
      }
      expect(calls, 2);
    },
  );

  test('ApiService dùng chung token giữa các màn hình', () {
    final loginService = ApiService();
    final homeService = ApiService();

    loginService.setAuthToken('jwt-token');

    expect(homeService.authToken, 'jwt-token');
    expect(homeService.hasAuthToken, isTrue);
  });

  test('clearAuthToken xóa phiên dùng chung bao gồm cả refreshToken', () {
    final service = ApiService()
      ..setTokens(
        accessToken: 'jwt-token',
        refreshToken: 'refresh-sample-token',
      );

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
