import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

typedef _ApiCall = Future<Object?> Function(ApiService api);

http.Response _error(int statusCode, String message) => http.Response(
  jsonEncode({
    'status': statusCode,
    'message': message,
    'data': null,
    'timestamp': '2026-10-04T00:00:00Z',
  }),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _calls = <String, _ApiCall>{
  'admin post moderation': (api) =>
      api.moderatePost(28, 'APPROVED', expectedVersion: 0),
  'admin report moderation': (api) => api.moderateAdminReport(
    55,
    status: 'RESOLVED',
    note: 'Kết quả kiểm tra thực tế',
  ),
  'admin account status': (api) => api.setUserStatus(28, 'LOCKED'),
  'chat send': (api) => api.sendChatMessage(receiverId: 2, content: 'Bản nháp'),
  'appointment creation': (api) => api.createAppointment(
    roomPostId: 28,
    appointmentTime: DateTime(2099, 11, 4, 10, 30),
    note: 'Bản nháp lịch hẹn',
  ),
  'appointment status': (api) => api.updateAppointmentStatus(55, 'CANCELLED'),
  'report submission': (api) => api.submitReport(
    targetId: 2,
    targetType: 'USER',
    reason: 'Nội dung báo cáo kiểm thử',
  ),
};

void main() {
  tearDown(() => ApiService.configureUnauthorizedHandler(() {}));

  for (final operation in _calls.entries) {
    for (final statusCode in [400, 403, 404, 409, 500, 503]) {
      test(
        '${operation.key}: HTTP $statusCode fails without expiring session',
        () async {
          var requests = 0;
          var unauthorizedCallbacks = 0;
          final message = 'Lỗi thử nghiệm $statusCode — dữ liệu không thay đổi';
          ApiService.configureUnauthorizedHandler(
            () => unauthorizedCallbacks++,
          );
          final client = MockClient((request) async {
            requests++;
            expect(request.url.path, isNot(endsWith('/auth/refresh-token')));
            expect(request.headers['authorization'], 'Bearer business-access');
            return _error(statusCode, message);
          });
          addTearDown(client.close);
          final api = ApiService.withClient(client)
            ..setTokens(
              accessToken: 'business-access',
              refreshToken: 'business-refresh',
            )
            ..savedPostIds.add(28);

          await expectLater(
            operation.value(api),
            throwsA(
              isA<ApiException>()
                  .having((error) => error.statusCode, 'statusCode', statusCode)
                  .having((error) => error.message, 'message', message),
            ),
          );

          expect(
            requests,
            1,
            reason: 'Business errors must not retry via refresh',
          );
          expect(unauthorizedCallbacks, 0);
          expect(api.authToken, 'business-access');
          expect(api.refreshToken, 'business-refresh');
          expect(api.hasAuthToken, isTrue);
          expect(api.hasRefreshToken, isTrue);
          expect(api.savedPostIds, {28});
        },
      );
    }

    test(
      '${operation.key}: HTTP 401 expires only after failed refresh',
      () async {
        var operationRequests = 0;
        var refreshRequests = 0;
        var unauthorizedCallbacks = 0;
        ApiService.configureUnauthorizedHandler(() => unauthorizedCallbacks++);
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh-token')) {
            refreshRequests++;
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {
              'refreshToken': 'expired-refresh',
            });
            return _error(401, 'Refresh token không còn hiệu lực');
          }
          operationRequests++;
          expect(request.headers['authorization'], 'Bearer expired-access');
          return _error(401, 'Access token không còn hiệu lực');
        });
        addTearDown(client.close);
        final api = ApiService.withClient(client)
          ..setTokens(
            accessToken: 'expired-access',
            refreshToken: 'expired-refresh',
          )
          ..savedPostIds.add(28);

        await expectLater(
          operation.value(api),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'statusCode', 401)
                .having(
                  (error) => error.message,
                  'message',
                  'Phiên làm việc đã hết hạn',
                ),
          ),
        );

        expect(
          operationRequests,
          1,
          reason: 'Failed refresh must not resend mutation',
        );
        expect(refreshRequests, 1);
        expect(unauthorizedCallbacks, 1);
        expect(api.authToken, isNull);
        expect(api.refreshToken, isNull);
        expect(api.hasAuthToken, isFalse);
        expect(api.hasRefreshToken, isFalse);
        expect(api.savedPostIds, isEmpty);
      },
    );
  }

  test(
    'HTTP 401 without refresh expires once and does not retry mutation',
    () async {
      var requests = 0;
      var unauthorizedCallbacks = 0;
      ApiService.configureUnauthorizedHandler(() => unauthorizedCallbacks++);
      final client = MockClient((_) async {
        requests++;
        return _error(401, 'Chưa đăng nhập');
      });
      addTearDown(client.close);
      final api = ApiService.withClient(client)..setAuthToken('expired-access');

      await expectLater(
        api.moderatePost(28, 'APPROVED', expectedVersion: 0),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(requests, 1);
      expect(unauthorizedCallbacks, 1);
      expect(api.hasAuthToken, isFalse);
    },
  );

  test(
    'Non-JSON server error uses safe fallback and preserves session',
    () async {
      var unauthorizedCallbacks = 0;
      ApiService.configureUnauthorizedHandler(() => unauthorizedCallbacks++);
      final client = MockClient(
        (_) async => http.Response('<html>Internal diagnostic</html>', 500),
      );
      addTearDown(client.close);
      final api = ApiService.withClient(client)
        ..setTokens(
          accessToken: 'business-access',
          refreshToken: 'business-refresh',
        );

      await expectLater(
        api.moderatePost(28, 'APPROVED', expectedVersion: 0),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 500)
              .having(
                (error) => error.message,
                'message',
                'Không thể duyệt bài đăng',
              ),
        ),
      );

      expect(unauthorizedCallbacks, 0);
      expect(api.authToken, 'business-access');
      expect(api.refreshToken, 'business-refresh');
    },
  );
}
