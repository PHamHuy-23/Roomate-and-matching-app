import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/screens/home_screen.dart';
import 'package:roommate_hub_mobile/screens/send_request_screen.dart';
import 'package:roommate_hub_mobile/screens/sent_request_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

Map<String, dynamic> requestPayload(String status, {double score = 71.4}) => {
  'requestId': 10,
  'partnerId': 2,
  'partnerName': 'Tuấn Minh',
  'partnerAvatar': null,
  'matchScore': score,
  'status': status,
  'createdAt': '2026-10-01T09:00:00',
  'contactPhone': status == 'ACCEPTED' ? '0000000000' : null,
  'contactEmail': status == 'ACCEPTED' ? 'partner@test.invalid' : null,
};

ApiService apiReturning(Object payload, {int code = 200}) {
  final client = MockClient(
    (_) async => http.Response(
      jsonEncode(payload),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );
  addTearDown(client.close);
  return ApiService.withClient(client);
}

void main() {
  for (final state in ['PENDING', 'ACCEPTED']) {
    test(
      'API giữ nguyên trạng thái $state, điểm và liên hệ từ backend',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path.endsWith('/matches/requests'), isTrue);
          expect(request.url.queryParameters, {'receiverId': '2'});
          expect(request.body, isEmpty);
          expect(request.headers['Authorization'], 'Bearer test-access');
          return http.Response(
            jsonEncode(requestPayload(state)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        addTearDown(client.close);
        final api = ApiService.withClient(client)..setAuthToken('test-access');
        final response = await api.sendMatchRequest(2);
        expect(response.status, state);
        expect(response.requestId, 10);
        expect(response.matchScore, 71.4);
        expect(
          response.contactPhone,
          state == 'ACCEPTED' ? '0000000000' : null,
        );
      },
    );
  }

  test('Mã 201 vẫn đọc dữ liệu thay vì trả bool', () async {
    expect(
      (await apiReturning(
        requestPayload('PENDING'),
        code: 201,
      ).sendMatchRequest(2)).status,
      'PENDING',
    );
  });

  test('Lỗi API không bị biến thành thành công', () async {
    await expectLater(
      apiReturning({
        'message': 'Không thể kết nối',
      }, code: 403).sendMatchRequest(2),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
    );
  });

  test(
    'Response trống, sai partner hoặc trạng thái không hợp lệ bị từ chối',
    () async {
      for (final payload in [
        {},
        {...requestPayload('PENDING'), 'partnerId': 3},
        requestPayload('UNKNOWN'),
        {...requestPayload('PENDING'), 'matchScore': null},
      ]) {
        await expectLater(
          apiReturning(payload).sendMatchRequest(2),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );

  testWidgets('Màn gửi dùng điểm thật và không cho nhập lời nhắn chưa hỗ trợ', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SendRequestScreen(
          currentUserId: 1,
          partnerId: 2,
          partnerName: 'Tuấn Minh',
          matchScore: 68.2,
        ),
      ),
    );
    expect(find.text('68% phù hợp'), findsOneWidget);
    expect(find.textContaining('94%'), findsNothing);
    expect(find.textContaining('Bình Thạnh'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.textContaining('Lời nhắn chưa được hỗ trợ'), findsOneWidget);
  });

  testWidgets('Không có điểm thì ghi rõ chưa có, không dùng 0% hoặc 94%', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SendRequestScreen(currentUserId: 1, partnerId: 2),
      ),
    );
    expect(find.text('Chưa có điểm phù hợp'), findsOneWidget);
    expect(find.text('0% phù hợp'), findsNothing);
  });

  for (final state in ['PENDING', 'ACCEPTED']) {
    testWidgets('Gửi lời mời báo đúng kết quả $state', (tester) async {
      final api = apiReturning(requestPayload(state));
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => SendRequestScreen(
                        currentUserId: 1,
                        partnerId: 2,
                        apiService: api,
                      ),
                    ),
                  );
                },
                child: const Text('Mở lời mời'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi lời mời'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(
        find.text(
          state == 'ACCEPTED'
              ? 'Hai bạn đã kết nối thành công!'
              : 'Đã gửi lời mời kết nối thành công!',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('Gửi thất bại giữ màn hiện tại và cho phép thử lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SendRequestScreen(
          currentUserId: 1,
          partnerId: 2,
          apiService: apiReturning({'message': 'Không thể kết nối'}, code: 403),
        ),
      ),
    );
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();
    expect(find.byType(SendRequestScreen), findsOneWidget);
    expect(find.text('Không thể kết nối'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Gửi lời mời'),
          )
          .onPressed,
      isNotNull,
    );
  });

  for (final state in ['PENDING', 'ACCEPTED', 'REJECTED']) {
    testWidgets('Lời mời đã gửi hiển thị $state và chỉ cho hủy khi chờ', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SentRequestScreen(
            currentUserId: 1,
            partnerId: 2,
            apiService: apiReturning([requestPayload(state)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = switch (state) {
        'ACCEPTED' => 'Đã kết nối',
        'REJECTED' => 'Đã từ chối',
        _ => 'Đang chờ phản hồi',
      };
      expect(find.text(label), findsOneWidget);
      expect(find.text('71% phù hợp · $label'), findsOneWidget);
      expect(
        find.text('Hủy lời mời'),
        state == 'PENDING' ? findsOneWidget : findsNothing,
      );
      if (state != 'PENDING') {
        expect(find.text('Đang chờ phản hồi'), findsNothing);
      }
    });
  }

  testWidgets(
    'Khám phá nhận ACCEPTED và giữ đúng trạng thái khi mở lại hồ sơ',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = MockClient((request) async {
        Object payload = [];
        if (request.method == 'POST') {
          payload = requestPayload('ACCEPTED');
        } else if (request.url.path.contains('recommendations')) {
          payload = [
            {
              'userId': 2,
              'fullName': 'Tuấn Minh',
              'targetDistrict': 'Thủ Đức',
              'budgetAmount': 2200000,
              'totalScore': 88,
              'criteriaDetail': {
                'budgetMatch': 80,
                'sleepMatch': 80,
                'cleanlinessMatch': 80,
                'smokingMatch': 80,
                'petMatch': 80,
              },
            },
          ];
        }
        return http.Response(
          jsonEncode(payload),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final api = ApiService.withClient(client);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            apiService: api,
            currentUser: AuthUser(
              token: 'test-access',
              userId: 1,
              email: 'viewer@test.invalid',
              fullName: 'Viewer',
              gender: 'MALE',
              role: 'ROLE_USER',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Xem hồ sơ & độ phù hợp'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem hồ sơ & độ phù hợp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi lời mời kết nối'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('Đã gửi lời mời kết nối'), findsNothing);
      expect(find.text('Bạn và Tuấn Minh đã kết nối!'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('71% phù hợp · Xem lý do'),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('71% phù hợp · Xem lý do'));
      await tester.pumpAndSettle();
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('Đã kết nối'), findsNWidgets(2));
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem hồ sơ & độ phù hợp'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối'), findsOneWidget);
    },
  );
}
