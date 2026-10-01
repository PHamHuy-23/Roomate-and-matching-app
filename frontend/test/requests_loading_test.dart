import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/screens/requests_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

http.Response reply(Object data, [int code = 200]) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> connection(String status) => {
  'requestId': 10,
  'partnerId': 2,
  'partnerName': 'Người kết nối thật',
  'matchScore': 80.0,
  'status': status,
};
Future<void> openRequests(WidgetTester tester, MockClient client) async {
  addTearDown(client.close);
  final api = ApiService.withClient(client)..setAuthToken('test-access');
  await tester.pumpWidget(
    MaterialApp(home: RequestsScreen(currentUserId: 1, apiService: api)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Timeout kết nối hiển thị lỗi thay vì danh sách trống', (
    tester,
  ) async {
    await openRequests(
      tester,
      MockClient((_) async => throw TimeoutException('timeout')),
    );
    expect(
      find.text('Máy chủ phản hồi quá lâu, vui lòng thử lại'),
      findsOneWidget,
    );
    expect(find.text('Không có kết nối nào'), findsNothing);
  });
  for (final code in [401, 403, 500]) {
    testWidgets('Kết nối lỗi $code không giả thành danh sách trống', (
      tester,
    ) async {
      await openRequests(
        tester,
        MockClient(
          (_) async => reply({'message': 'Lỗi tải kết nối $code'}, code),
        ),
      );
      expect(
        find.text(
          code == 401 ? 'Phiên làm việc đã hết hạn' : 'Lỗi tải kết nối $code',
        ),
        findsOneWidget,
      );
      expect(find.text('Không có kết nối nào'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  }
  testWidgets('Mất mạng có thể thử lại và khôi phục danh sách', (tester) async {
    var offline = true;
    await openRequests(
      tester,
      MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        return reply(
          request.url.path.contains('/received/')
              ? [connection('ACCEPTED')]
              : [],
        );
      }),
    );
    expect(find.text('Không thể kết nối đến máy chủ'), findsOneWidget);
    offline = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Người kết nối thật'), findsOneWidget);
    expect(find.text('Không thể kết nối đến máy chủ'), findsNothing);
  });
  testWidgets('Tải lỗi danh sách đã gửi không bị coi là dữ liệu hoàn chỉnh', (
    tester,
  ) async {
    await openRequests(
      tester,
      MockClient(
        (request) async => request.url.path.contains('/received/')
            ? reply([connection('ACCEPTED')])
            : reply({'message': 'Không tải được yêu cầu đã gửi'}, 500),
      ),
    );
    expect(find.text('Không tải được yêu cầu đã gửi'), findsOneWidget);
    expect(find.text('Người kết nối thật'), findsNothing);
    expect(find.text('Không có kết nối nào'), findsNothing);
  });
  testWidgets('JSON sai hiện lỗi chung, không khẳng định danh sách trống', (
    tester,
  ) async {
    await openRequests(
      tester,
      MockClient((_) async => http.Response('not-json', 200)),
    );
    expect(
      find.text('Không thể tải kết nối, vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Không có kết nối nào'), findsNothing);
  });
  testWidgets(
    'Danh sách thật sự trống vẫn hiển thị trống và kéo tải lại được',
    (tester) async {
      var calls = 0;
      await openRequests(
        tester,
        MockClient((_) async {
          calls++;
          return reply([]);
        }),
      );
      expect(find.text('Không có kết nối nào'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(calls, 4);
    },
  );
  testWidgets('Tải lại lỗi không để liên hệ cũ trông như dữ liệu mới nhất', (
    tester,
  ) async {
    var failed = false;
    await openRequests(
      tester,
      MockClient((request) async {
        if (failed) {
          return reply({'message': 'Không tải được dữ liệu mới'}, 500);
        }
        return reply(
          request.url.path.contains('/received/')
              ? [connection('ACCEPTED')]
              : [],
        );
      }),
    );
    expect(find.text('Người kết nối thật'), findsOneWidget);
    failed = true;
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được dữ liệu mới'), findsOneWidget);
    expect(find.text('Người kết nối thật'), findsNothing);
    expect(find.text('Không có kết nối nào'), findsNothing);
    failed = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Người kết nối thật'), findsOneWidget);
  });
}
