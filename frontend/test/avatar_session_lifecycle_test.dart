import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/screens/avatar_picker_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

class _MemoryPicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6RkAAAAASUVORK5CYII=',
    ),
    name: 'avatar.png',
    path: 'avatar.png',
    mimeType: 'image/png',
  );
}

http.Response _reply(Object data) => http.Response(jsonEncode(data), 200);

void main() {
  const key = 'avatars/1/12345678-1234-4234-8234-123456789abc.png';
  const avatar = 'https://media.test.invalid/$key';
  for (final stage in ['upload', 'confirm']) {
    for (final action in [
      'switch',
      'same-account',
      'logout',
      'dispose',
      'success',
    ]) {
      testWidgets(
        '$stage response after $action cannot restore an obsolete avatar/user',
        (tester) async {
          tester.view.physicalSize = const Size(900, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final delayed = Completer<http.Response>();
          final started = Completer<void>();
          var confirms = 0;
          final api = ApiService.withClient(
            MockClient((request) async {
              if (request.url.path.endsWith('/auth/login')) {
                final b = jsonDecode(request.body)['email'] == 'B@example.test';
                return _reply({
                  'token': b ? 'B-access' : 'A-access',
                  'refreshToken': b ? 'B-refresh' : 'A-refresh',
                  'userId': b ? 2 : 1,
                  'email': b ? 'B@example.test' : 'A@example.test',
                  'fullName': b ? 'B' : 'A',
                });
              }
              if (request.url.path.endsWith('/auth/logout')) return _reply({});
              if (request.url.path.endsWith('/uploads/presign')) {
                return _reply({
                  'uploadUrl': 'https://r2.test.invalid/upload',
                  'publicUrl': avatar,
                  'objectKey': key,
                  'contentType': 'image/png',
                  'expiresInSeconds': 600,
                });
              }
              if (request.url.path.endsWith('/uploads/avatar')) {
                confirms++;
                if (stage == 'confirm') {
                  started.complete();
                  return delayed.future;
                }
                return _reply({'avatarUrl': avatar});
              }
              expect(request.url.host, 'r2.test.invalid');
              if (stage == 'upload') {
                started.complete();
                return delayed.future;
              }
              return http.Response('', 200);
            }),
          );
          final session = AuthSession(apiService: api);
          final user = await session.login('A@example.test', 'test-password');
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthSession>.value(
              value: session,
              child: MaterialApp(
                navigatorKey: navigator,
                home: const Scaffold(body: Text('Destination')),
              ),
            ),
          );
          unawaited(
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => AvatarPickerScreen(
                  currentUser: user,
                  apiService: api,
                  imagePicker: _MemoryPicker(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Chọn ảnh từ thư viện'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dùng ảnh này'));
          await tester.pump();
          expect(started.isCompleted, isTrue);

          switch (action) {
            case 'switch':
              await session.login('B@example.test', 'test-password');
            case 'same-account':
              await session.signOut();
              await session.login('A@example.test', 'test-password');
            case 'logout':
              await session.signOut();
            case 'dispose':
              navigator.currentState!.pop();
              await tester.pumpAndSettle();
            case 'success':
              session.updateUser(session.user!.copyWith(fullName: 'Updated A'));
          }
          delayed.complete(
            stage == 'upload'
                ? http.Response('', 200)
                : _reply({'avatarUrl': avatar}),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (action == 'success') {
            expect(session.user!.avatarUrl, avatar);
            expect(session.user!.fullName, 'Updated A');
            expect(find.text('Destination'), findsOneWidget);
            expect(confirms, 1);
          } else {
            expect(session.user?.avatarUrl, isNull);
            expect(
              session.user?.userId,
              action == 'logout'
                  ? null
                  : action == 'switch'
                  ? 2
                  : 1,
            );
            expect(confirms, stage == 'confirm' ? 1 : 0);
            expect(find.text('Đã cập nhật ảnh đại diện'), findsNothing);
          }
        },
      );
    }
  }
}
