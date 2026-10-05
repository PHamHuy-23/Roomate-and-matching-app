import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_moderate_post_screen.dart';
import 'package:roommate_hub_mobile/screens/admin_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _VersionApi implements ApiService {
  int loads = 0;
  bool missingVersion = false;
  bool reloadFails = false;
  bool conflicts = true;
  Completer<bool>? pending;
  final calls = <({int id, int version, String status, String? reason})>[];

  @override
  Future<List<dynamic>> getAdminPosts() async {
    loads++;
    if (reloadFails && loads > 1) {
      throw const ApiException('Không tải được phiên bản mới', statusCode: 503);
    }
    return [
      {
        'id': 28,
        if (!missingVersion) 'version': loads == 1 ? 7 : 8,
        'title': loads == 1 ? 'Nội dung đã xem' : 'Nội dung mới cần xem lại',
        'description': 'Mô tả kiểm thử',
        'price': 2000000,
        'maxOccupants': 2,
        'status': 'PENDING',
      },
    ];
  }

  @override
  Future<List<dynamic>> getAdminUsers() async => [];

  @override
  Future<bool> moderatePost(
    int postId,
    String status, {
    required int expectedVersion,
    String? reason,
  }) async {
    calls.add((
      id: postId,
      version: expectedVersion,
      status: status,
      reason: reason,
    ));
    if (conflicts && calls.length == 1) {
      throw const ApiException('Tin đã thay đổi, hãy xem lại', statusCode: 409);
    }
    return pending == null ? true : await pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _VersionApi api, {
  bool legacy = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: legacy
          ? AdminScreen(apiService: api)
          : AdminModeratePostScreen(apiService: api),
      routes: {
        AppRoutes.adminPostApproved: (_) =>
            const Scaffold(body: Text('Kết quả duyệt thành công')),
        AppRoutes.adminPostNeedsEdit: (_) =>
            const Scaffold(body: Text('Kết quả từ chối thành công')),
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'API sends viewed version and keeps 409 without automatic retry or logout',
    () async {
      final requests = <http.Request>[];
      final api = ApiService.withClient(
        MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'message': 'Tin đã thay đổi'}),
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      api.setAuthToken('test-access-token');
      var expirations = 0;
      ApiService.configureUnauthorizedHandler(() => expirations++);
      addTearDown(() => ApiService.configureUnauthorizedHandler(() {}));
      await expectLater(
        api.moderatePost(
          28,
          'REJECTED',
          expectedVersion: 7,
          reason: ' Xem lại ',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );
      expect(requests.single.url.queryParameters, {
        'status': 'REJECTED',
        'expectedVersion': '7',
        'reason': 'Xem lại',
      });
      expect(api.hasAuthToken, isTrue);
      expect(expirations, 0);
    },
  );

  test('Negative version cannot be sent to backend', () async {
    var requests = 0;
    final api = ApiService.withClient(
      MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      api.moderatePost(28, 'APPROVED', expectedVersion: -1),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 0);
  });

  for (final approve in [true, false]) {
    testWidgets(
      'Conflict refreshes content but requires a new explicit ${approve ? "approval" : "rejection"}',
      (tester) async {
        final api = _VersionApi();
        await _open(tester, api);
        await tester.enterText(
          find.byType(TextField),
          'Lý do dành cho phiên bản cũ',
        );
        final button = find.text(
          approve ? 'Duyệt & hiển thị tin' : 'Từ chối tin đăng',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(api.calls.single.version, 7);
        expect(api.loads, 2);
        expect(find.textContaining('Nội dung mới cần xem lại'), findsWidgets);
        expect(find.text('Tin đã thay đổi, hãy xem lại'), findsOneWidget);
        expect(find.textContaining('Kết quả'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        await tester.enterText(find.byType(TextField), 'Lý do mới');
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(api.calls.last.version, 8);
        expect(api.calls.last.id, 28);
        expect(api.calls.last.reason, approve ? null : 'Lý do mới');
        expect(
          find.text(
            approve ? 'Kết quả duyệt thành công' : 'Kết quả từ chối thành công',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('Reload failure prevents decisions on obsolete content', (
    tester,
  ) async {
    final api = _VersionApi()..reloadFails = true;
    await _open(tester, api);
    await tester.ensureVisible(find.text('Duyệt & hiển thị tin'));
    await tester.tap(find.text('Duyệt & hiển thị tin'));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được phiên bản mới'), findsOneWidget);
    expect(find.text('Duyệt & hiển thị tin'), findsNothing);
    expect(api.calls, hasLength(1));
    api.reloadFails = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nội dung mới cần xem lại'), findsWidgets);
    expect(api.calls, hasLength(1));
  });

  testWidgets('Missing version never defaults to zero or sends moderation', (
    tester,
  ) async {
    final api = _VersionApi()..missingVersion = true;
    await _open(tester, api);
    expect(api.calls, isEmpty);
    expect(find.textContaining('Thiếu phiên bản tin đăng.'), findsWidgets);
    expect(find.text('Duyệt & hiển thị tin'), findsNothing);
    api.missingVersion = false;
    await tester.tap(find.text('Tải lại tin đăng'));
    await tester.pumpAndSettle();
    expect(find.text('Duyệt & hiển thị tin'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('Pending decision blocks double submit', (tester) async {
    final api = _VersionApi()
      ..conflicts = false
      ..pending = Completer<bool>();
    await _open(tester, api);
    await tester.ensureVisible(find.text('Duyệt & hiển thị tin'));
    await tester.tap(find.text('Duyệt & hiển thị tin'));
    await tester.pump();
    await tester.tap(find.text('Từ chối tin đăng'));
    await tester.pump();
    expect(api.calls, hasLength(1));
    api.pending!.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Kết quả duyệt thành công'), findsOneWidget);
  });

  testWidgets(
    'Legacy admin screen also carries version and reloads after conflict without retry',
    (tester) async {
      final api = _VersionApi();
      await _open(tester, api, legacy: true);
      await tester.tap(find.text('Phê Duyệt'));
      await tester.pumpAndSettle();
      expect(api.calls.single.version, 7);
      expect(api.loads, 2);
      expect(find.text('Nội dung mới cần xem lại'), findsOneWidget);
      expect(find.text('Tin đã thay đổi, hãy xem lại'), findsOneWidget);
      await tester.tap(find.text('Phê Duyệt'));
      await tester.pumpAndSettle();
      expect(api.calls.last.version, 8);
    },
  );
}
