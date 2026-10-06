import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  ImagePicker? imagePicker,
}) async {
  addTearDown(client.close);
  final api = ApiService.withClient(client)..setAuthToken('test-access');
  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        partnerId: partnerId,
        partnerName: 'Nguyễn Văn A',
        apiService: api,
        imagePicker: imagePicker,
      ),
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpAndSettle();
}

const imageKey = 'chat/1/12345678-1234-4234-8234-123456789abc.png';
final imageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);

class MemoryImagePicker extends ImagePicker {
  MemoryImagePicker({this.names = const ['private.png']});

  final List<String> names;
  int calls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final name = names[calls++];
    return XFile.fromData(
      imageBytes,
      name: name,
      path: name,
      mimeType: 'image/png',
    );
  }
}

Map<String, dynamic> privateTicket([String objectKey = imageKey]) => {
  'uploadUrl': 'https://r2.test.invalid/upload?signature=temporary',
  'publicUrl': null,
  'objectKey': objectKey,
  'contentType': 'image/png',
  'expiresInSeconds': 600,
};

Future<void> pickLocalImage(WidgetTester tester) async {
  await clearChatSnackBars(tester);
  await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded));
  await tester.pumpAndSettle();
  expect(find.textContaining('Dán link'), findsNothing);
  await tester.tap(find.text('Thư viện ảnh'));
  await tester.pumpAndSettle();
}

Future<void> clearChatSnackBars(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .clearSnackBars();
  await tester.pumpAndSettle();
}

String signedChatImageUrl({
  String objectKey = imageKey,
  DateTime? signedAt,
  int expires = 120,
  String signature = 'a',
}) => Uri.https('r2.test.invalid', '/private-bucket/$objectKey', {
  'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
  'X-Amz-Date': DateFormat(
    "yyyyMMdd'T'HHmmss'Z'",
  ).format(signedAt ?? DateTime.now().toUtc()),
  'X-Amz-Expires': '$expires',
  'X-Amz-Signature': List.filled(64, signature).join(),
}).toString();

String visibleChatImageUrl(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image).first).image as NetworkImage).url;

void main() {
  for (final scenario in [
    'still-valid',
    'revoked',
    'near-expiry',
    'different-object',
    'legacy-public',
    'missing-signature',
    'legacy-long-expiry',
    'restored',
  ]) {
    testWidgets('Polling ảnh chat xử lý signed URL đúng: $scenario', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      final oldUrl = switch (scenario) {
        'near-expiry' => signedChatImageUrl(
          signedAt: now.subtract(const Duration(seconds: 100)),
        ),
        'legacy-public' => 'https://media.test.invalid/$imageKey',
        'missing-signature' =>
          'https://r2.test.invalid/private-bucket/$imageKey?X-Amz-Date=20261004T100000Z',
        'restored' => null,
        'legacy-long-expiry' => signedChatImageUrl(signedAt: now, expires: 600),
        _ => signedChatImageUrl(signedAt: now),
      };
      final newUrl = scenario == 'revoked'
          ? null
          : signedChatImageUrl(
              objectKey: scenario == 'different-object'
                  ? 'chat/1/87654321-1234-4234-8234-123456789abc.png'
                  : imageKey,
              signedAt: now,
              signature: 'b',
            );
      var calls = 0;
      await openChat(
        tester,
        MockClient((request) async {
          expect(request.method, 'GET');
          final first = ++calls == 1;
          return reply([
            {
              ...message(
                first ? 'Chú thích cũ' : 'Chú thích mới',
                fromMe: true,
              ),
              'imageUrl': first ? oldUrl : newUrl,
              'isRead': !first,
            },
          ]);
        }),
      );
      if (oldUrl == null) {
        expect(find.byType(Image), findsNothing);
      } else {
        expect(visibleChatImageUrl(tester), oldUrl);
      }
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Chú thích mới'), findsOneWidget);
      expect(find.text('Chú thích cũ'), findsNothing);
      if (scenario == 'revoked') {
        expect(find.byType(Image), findsNothing);
      } else {
        expect(
          visibleChatImageUrl(tester),
          scenario == 'still-valid' ? oldUrl : newUrl,
        );
      }
    });
  }

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
    var tickets = 0;
    var uploads = 0;
    var stored = false;
    final pending = Completer<http.Response>();
    await openChat(
      tester,
      MockClient((request) async {
        if (request.url.host == 'r2.test.invalid') {
          uploads++;
          expect(request.method, 'PUT');
          expect(request.bodyBytes, imageBytes);
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response('', 200);
        }
        if (request.url.path.endsWith('/uploads/presign')) {
          tickets++;
          return reply(privateTicket());
        }
        if (request.method == 'GET') {
          return reply(
            stored ? [message('Nội dung đang soạn', fromMe: true)] : [],
          );
        }
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        expect(data['content'], 'Nội dung đang soạn');
        expect(data['imageObjectKey'], imageKey);
        expect(data.containsKey('imageUrl'), isFalse);
        if (++sends == 1) return reply({'message': 'Gửi thất bại'}, 500);
        return pending.future;
      }),
      imagePicker: MemoryImagePicker(),
    );
    await pickLocalImage(tester);
    await tester.enterText(find.byType(TextField), 'Nội dung đang soạn');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gửi thất bại'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Nội dung đang soạn',
    );
    expect(find.text('private.png'), findsOneWidget);
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
    expect(find.text('private.png'), findsNothing);
    expect(find.text('Nội dung đang soạn'), findsOneWidget);
    expect(find.textContaining('Đã gửi'), findsOneWidget);
    expect(sends, 2);
    expect(tickets, 1);
    expect(uploads, 1);
  });

  testWidgets(
    'Upload lỗi giữ ảnh và chú thích, thử lại upload rồi mới gửi key',
    (tester) async {
      var tickets = 0;
      var puts = 0;
      var sends = 0;
      await openChat(
        tester,
        MockClient((request) async {
          if (request.url.host == 'r2.test.invalid') {
            return http.Response('', ++puts == 1 ? 403 : 200);
          }
          if (request.url.path.endsWith('/uploads/presign')) {
            tickets++;
            return reply(privateTicket());
          }
          if (request.method == 'GET') return reply([]);
          sends++;
          expect(jsonDecode(request.body), {
            'receiverId': 2,
            'content': 'Chú thích riêng tư',
            'imageObjectKey': imageKey,
          });
          return reply(message('Chú thích riêng tư', fromMe: true));
        }),
        imagePicker: MemoryImagePicker(),
      );
      await pickLocalImage(tester);
      await tester.enterText(find.byType(TextField), 'Chú thích riêng tư');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      expect(find.text('private.png'), findsOneWidget);
      expect(find.textContaining('Không thể tải ảnh'), findsOneWidget);
      expect(find.textContaining('dán link'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Chú thích riêng tư',
      );
      expect(sends, 0);
      await clearChatSnackBars(tester);
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      expect(sends, 1);
      expect(tickets, 2);
      expect(puts, 2);
      expect(find.text('private.png'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Ticket private có public URL bị từ chối, giữ bản nháp và không upload/gửi',
    (tester) async {
      var uploads = 0;
      var sends = 0;
      await openChat(
        tester,
        MockClient((request) async {
          if (request.url.host == 'r2.test.invalid') {
            uploads++;
            return http.Response('', 200);
          }
          if (request.url.path.endsWith('/uploads/presign')) {
            return reply({
              ...privateTicket(),
              'publicUrl': 'https://media.test.invalid/private.png',
            });
          }
          if (request.method == 'GET') return reply([]);
          sends++;
          return reply(message('Riêng tư', fromMe: true));
        }),
        imagePicker: MemoryImagePicker(),
      );
      await pickLocalImage(tester);
      await tester.enterText(find.byType(TextField), 'Riêng tư');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      expect(find.text('private.png'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Riêng tư',
      );
      expect(
        find.textContaining('Thông tin upload từ máy chủ không hợp lệ'),
        findsOneWidget,
      );
      expect(uploads, 0);
      expect(sends, 0);
    },
  );

  testWidgets(
    'Hủy ảnh sau khi gửi lỗi xóa key cũ, giữ nội dung và gửi text-only',
    (tester) async {
      var tickets = 0;
      var sends = 0;
      await openChat(
        tester,
        MockClient((request) async {
          if (request.url.host == 'r2.test.invalid') {
            return http.Response('', 200);
          }
          if (request.url.path.endsWith('/uploads/presign')) {
            tickets++;
            return reply(privateTicket());
          }
          if (request.method == 'GET') return reply([]);
          final data = jsonDecode(request.body) as Map<String, dynamic>;
          if (++sends == 1) {
            expect(data['imageObjectKey'], imageKey);
            return reply({'message': 'Gửi thất bại'}, 500);
          }
          expect(data, {'receiverId': 2, 'content': 'Chỉ nội dung'});
          return reply(message('Chỉ nội dung', fromMe: true));
        }),
        imagePicker: MemoryImagePicker(),
      );
      await pickLocalImage(tester);
      await tester.enterText(find.byType(TextField), 'Chỉ nội dung');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      await clearChatSnackBars(tester);
      await tester.tap(find.byTooltip('Hủy ảnh đính kèm'));
      await tester.pumpAndSettle();
      expect(find.text('private.png'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Chỉ nội dung',
      );
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      expect(sends, 2);
      expect(tickets, 1);
    },
  );

  testWidgets('Thay ảnh sau khi gửi lỗi xóa key cũ, retry dùng key ảnh mới', (
    tester,
  ) async {
    const secondKey = 'chat/1/87654321-1234-4234-8234-123456789abc.png';
    var tickets = 0;
    var puts = 0;
    var sends = 0;
    await openChat(
      tester,
      MockClient((request) async {
        if (request.url.host == 'r2.test.invalid') {
          puts++;
          return http.Response('', 200);
        }
        if (request.url.path.endsWith('/uploads/presign')) {
          final data = jsonDecode(request.body) as Map<String, dynamic>;
          expect(data['fileName'], tickets == 0 ? 'first.png' : 'second.png');
          return reply(privateTicket(++tickets == 1 ? imageKey : secondKey));
        }
        if (request.method == 'GET') return reply([]);
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        expect(data['imageObjectKey'], ++sends == 1 ? imageKey : secondKey);
        expect(data.containsKey('imageUrl'), isFalse);
        if (sends <= 2) return reply({'message': 'Gửi thất bại'}, 500);
        return reply(message('Ảnh đã thay', fromMe: true));
      }),
      imagePicker: MemoryImagePicker(names: ['first.png', 'second.png']),
    );
    await pickLocalImage(tester);
    await tester.enterText(find.byType(TextField), 'Ảnh đã thay');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('first.png'), findsOneWidget);
    await pickLocalImage(tester);
    expect(find.text('first.png'), findsNothing);
    expect(find.text('second.png'), findsOneWidget);
    await clearChatSnackBars(tester);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('second.png'), findsOneWidget);
    await clearChatSnackBars(tester);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(tickets, 2);
    expect(puts, 2);
    expect(sends, 3);
    expect(find.text('second.png'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
