import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/screens/chat_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

http.Response reply(Object data, [int code = 200]) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> message(String content, {bool fromMe = false}) => {
  'id': 10,
  'senderId': fromMe ? 1 : 2,
  'senderName': 'Người gửi',
  'receiverId': fromMe ? 2 : 1,
  'receiverName': 'Người nhận',
  'content': content,
  'isRead': false,
  'createdAt': '2026-10-01T10:00:00',
  'fromMe': fromMe,
};
Future<void> openChat(
  WidgetTester tester,
  MockClient client, {
  int? partnerId = 2,
}) async {
  addTearDown(client.close);
  final api = ApiService.withClient(client)..setAuthToken('test-access');
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        partnerId: partnerId,
        partnerName: 'Nguyễn Văn A',
        apiService: api,
      ),
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Response tải cũ không xóa tin nhắn vừa gửi thành công', (
    tester,
  ) async {
    var loads = 0;
    final stale = Completer<http.Response>();
    await openChat(
      tester,
      MockClient((request) async {
        if (request.method == 'POST') {
          return reply(message('Tin nhắn vừa gửi', fromMe: true));
        }
        if (++loads == 1) return reply([]);
        return stale.future;
      }),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(loads, 2);
    await tester.enterText(find.byType(TextField), 'Tin nhắn vừa gửi');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn vừa gửi'), findsOneWidget);
    stale.complete(reply([]));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn vừa gửi'), findsOneWidget);
    expect(find.textContaining('Hãy gửi lời chào'), findsNothing);
  });
  testWidgets('Timeout chat hiển thị lỗi thay vì lời chào', (tester) async {
    await openChat(
      tester,
      MockClient((_) async => throw TimeoutException('timeout')),
    );
    expect(
      find.text('Máy chủ phản hồi quá lâu, vui lòng thử lại'),
      findsOneWidget,
    );
    expect(find.textContaining('Hãy gửi lời chào'), findsNothing);
  });
  testWidgets('Chat thật sự trống mới hiển thị lời chào', (tester) async {
    await openChat(tester, MockClient((_) async => reply([])));
    expect(find.text('Hãy gửi lời chào tới Nguyễn Văn A!'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });
  for (final code in [401, 403, 500]) {
    testWidgets(
      'Tải chat lỗi $code không bị hiển thị như cuộc trò chuyện trống',
      (tester) async {
        await openChat(
          tester,
          MockClient(
            (_) async => reply({'message': 'Lỗi tải chat $code'}, code),
          ),
        );
        expect(
          find.text(
            code == 401 ? 'Phiên làm việc đã hết hạn' : 'Lỗi tải chat $code',
          ),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);
        expect(find.textContaining('Hãy gửi lời chào'), findsNothing);
      },
    );
  }
  testWidgets('Mất mạng hiển thị lỗi và thử lại tải được tin nhắn thật', (
    tester,
  ) async {
    var calls = 0;
    await openChat(
      tester,
      MockClient((request) async {
        expect(request.url.path.endsWith('/chat/messages/2'), isTrue);
        if (++calls == 1) throw http.ClientException('offline');
        return reply([message('Tin nhắn thật')]);
      }),
    );
    expect(find.text('Không thể kết nối đến máy chủ'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn thật'), findsOneWidget);
    expect(find.text('Không thể kết nối đến máy chủ'), findsNothing);
    expect(calls, 2);
  });
  testWidgets('JSON sai không bị coi là chat trống', (tester) async {
    await openChat(
      tester,
      MockClient((_) async => http.Response('invalid-json', 200)),
    );
    expect(
      find.text('Không thể tải tin nhắn, vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.textContaining('Hãy gửi lời chào'), findsNothing);
  });
  testWidgets('Polling lỗi giữ lịch sử cũ, cảnh báo và phục hồi khi thử lại', (
    tester,
  ) async {
    var calls = 0;
    await openChat(
      tester,
      MockClient((_) async {
        if (++calls == 2) return reply({'message': 'Máy chủ đang lỗi'}, 500);
        return reply([message(calls > 2 ? 'Tin nhắn mới' : 'Tin nhắn cũ')]);
      }),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn cũ'), findsOneWidget);
    expect(find.text('Máy chủ đang lỗi'), findsOneWidget);
    expect(find.text('Đang hiển thị lịch sử đã tải trước đó.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn mới'), findsOneWidget);
    expect(find.text('Máy chủ đang lỗi'), findsNothing);
  });
  testWidgets('Thiếu người nhận: báo lỗi, không gọi API và không cho gửi', (
    tester,
  ) async {
    var calls = 0;
    await openChat(
      tester,
      MockClient((_) async {
        calls++;
        return reply([]);
      }),
      partnerId: null,
    );
    expect(
      find.text('Không xác định được người nhận tin nhắn.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(calls, 0);
    expect(find.textContaining('Hãy gửi lời chào'), findsNothing);
  });
  testWidgets('Không tải chồng nhau và response sau dispose không gây lỗi', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final client = MockClient((_) {
      calls++;
      return pending.future;
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          partnerId: 2,
          apiService: ApiService.withClient(client),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(reply([]));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Gửi lỗi giữ bản nháp và ảnh, chỉ xóa sau khi gửi thành công', (
    tester,
  ) async {
    var sends = 0;
    var stored = false;
    final pending = Completer<http.Response>();
    await openChat(
      tester,
      MockClient((request) async {
        if (request.method == 'GET') {
          return reply(
            stored ? [message('Nội dung đang soạn', fromMe: true)] : [],
          );
        }
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        expect(data['content'], 'Nội dung đang soạn');
        expect(data['imageUrl'], 'https://media.test.invalid/photo.png');
        if (++sends == 1) return reply({'message': 'Gửi thất bại'}, 500);
        return pending.future;
      }),
    );
    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Dán link'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'https://media.test.invalid/photo.png',
    );
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nội dung đang soạn');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gửi thất bại'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Nội dung đang soạn',
    );
    expect(find.text('Ảnh từ liên kết web'), findsOneWidget);
    expect(find.textContaining('Đã gửi'), findsNothing);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .clearSnackBars();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    stored = true;
    pending.complete(reply(message('Nội dung đang soạn', fromMe: true)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Ảnh từ liên kết web'), findsNothing);
    expect(find.text('Nội dung đang soạn'), findsOneWidget);
    expect(find.textContaining('Đã gửi'), findsOneWidget);
    expect(sends, 2);
  });
}
