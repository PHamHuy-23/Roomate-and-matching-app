import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

void main() {
  for (final status in ['ACTIVE', 'LOCKED']) {
    for (final wrapped in [false, true]) {
      test(
        'admin sets $status explicitly and confirms response ($wrapped)',
        () async {
          final api = ApiService.withClient(
            MockClient((request) async {
              expect(request.method, 'PUT');
              expect(request.url.path, '/api/v1/admin/users/28/status');
              expect(request.url.query, isEmpty);
              expect(request.headers['authorization'], 'Bearer test-admin');
              expect(jsonDecode(request.body), {'status': status});
              final payload = {'userId': 28, 'status': status};
              return http.Response(
                jsonEncode(
                  wrapped ? {'status': 'success', 'data': payload} : payload,
                ),
                200,
              );
            }),
          )..setAuthToken('test-admin');
          expect(await api.setUserStatus(28, status), status);
        },
      );
    }
  }

  test('repeated lock request never becomes a toggle or an unlock', () async {
    var count = 0;
    final api = ApiService.withClient(
      MockClient((request) async {
        count++;
        expect(request.url.path, '/api/v1/admin/users/28/status');
        expect(jsonDecode(request.body), {'status': 'LOCKED'});
        return http.Response('{"userId":28,"status":"LOCKED"}', 200);
      }),
    );
    expect(await api.setUserStatus(28, 'LOCKED'), 'LOCKED');
    expect(await api.setUserStatus(28, 'LOCKED'), 'LOCKED');
    expect(count, 2);
  });

  for (final payload in [
    '',
    'not-json',
    'null',
    '[]',
    'true',
    '{}',
    '{"userId":28}',
    '{"status":"LOCKED"}',
    '{"userId":29,"status":"LOCKED"}',
    '{"userId":"28","status":"LOCKED"}',
    '{"userId":28.0,"status":"LOCKED"}',
    '{"userId":28,"status":"ACTIVE"}',
    '{"userId":28,"status":"locked"}',
    '{"userId":28,"status":"BANNED"}',
    '{"status":"success","data":null}',
  ]) {
    test(
      'admin rejects unconfirmed/malformed status response: $payload',
      () async {
        final api = ApiService.withClient(
          MockClient((_) async => http.Response(payload, 200)),
        );
        await expectLater(
          api.setUserStatus(28, 'LOCKED'),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }

  for (final statusCode in [201, 204, 400, 403, 404, 500]) {
    test('admin rejects non-200 status update: $statusCode', () async {
      final api = ApiService.withClient(
        MockClient(
          (_) async => http.Response(
            '{"message":"Không cho phép thao tác"}',
            statusCode,
          ),
        ),
      );
      await expectLater(
        api.setUserStatus(28, 'LOCKED'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );
    });
  }

  for (final status in ['', 'locked', ' ACTIVE ', 'BANNED', 'PENDING']) {
    test('admin does not send unsupported desired state: $status', () async {
      final api = ApiService.withClient(
        MockClient((_) async {
          fail('Invalid status must be rejected before sending HTTP');
        }),
      );
      await expectLater(
        api.setUserStatus(28, status),
        throwsA(isA<ApiException>()),
      );
    });
  }

  for (final userId in [0, -1]) {
    test('admin does not send invalid user ID: $userId', () async {
      final api = ApiService.withClient(
        MockClient((_) async {
          fail('Invalid user ID must be rejected before sending HTTP');
        }),
      );
      await expectLater(
        api.setUserStatus(userId, 'ACTIVE'),
        throwsA(isA<ApiException>()),
      );
    });
  }
}
