import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/report_receipt.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_reports_screen.dart';
import 'package:roommate_hub_mobile/screens/help_safety_screen.dart';
import 'package:roommate_hub_mobile/screens/report_received_screen.dart';
import 'package:roommate_hub_mobile/screens/report_violation_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

http.Response reply(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiService apiWith(Future<http.Response> Function(http.Request) handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return ApiService.withClient(client)..setAuthToken('test-report-access');
}

Map<String, dynamic> report(int id, String? status) => {
  'id': id,
  'status': status,
  'reason': 'Kiểm tra báo cáo $id',
  'targetId': 4,
  'targetType': 'USER',
  'reporterName': 'Người thử nghiệm',
};

Future<void> openForm(
  WidgetTester tester,
  ApiService api, {
  int? target = 4,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final session = AuthSession(apiService: api)
    ..updateUser(
      AuthUser(
        token: 'test-report-access',
        userId: 1,
        email: 'test@example.invalid',
        fullName: 'Test reporter',
        gender: 'OTHER',
        role: 'ROLE_USER',
      ),
    );
  addTearDown(session.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(
        home: ReportViolationScreen(targetUserId: target, apiService: api),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
}

Future<void> submitForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Mô tả thử nghiệm');
  await tester.tap(find.text('Gửi báo cáo'));
  await tester.pump();
}

Future<void> openAdmin(WidgetTester tester, ApiService api) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: AdminReportsScreen(apiService: api),
      routes: {
        AppRoutes.adminReportResolved: (_) =>
            const Scaffold(body: Text('Kết quả đã lưu')),
      },
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> editNote(WidgetTester tester, String note) async {
  await tester.ensureVisible(find.text('Đánh dấu đã xử lý'));
  await tester.tap(find.text('Đánh dấu đã xử lý'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), note);
}

void main() {
  test('Receipt code is derived only from the confirmed ID', () {
    expect(
      ReportReceipt.fromJson({'reportId': 1, 'status': 'PENDING'}).code,
      'BC-001',
    );
    expect(
      ReportReceipt.fromJson({'reportId': 2000, 'status': 'PENDING'}).code,
      'BC-2000',
    );
  });
  for (final status in [200, 201]) {
    test(
      'Submission HTTP $status returns the real receipt and request fields',
      () async {
        final api = apiWith((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, endsWith('/reports'));
          expect(jsonDecode(request.body), {
            'targetId': 4,
            'targetType': 'USER',
            'reason': 'Reason',
            'evidenceObjectKey': 'reports/1/test.png',
          });
          return reply({'reportId': 1234, 'status': 'PENDING'}, status);
        });
        final receipt = await api.submitReport(
          targetId: 4,
          reason: 'Reason',
          evidenceObjectKey: 'reports/1/test.png',
        );
        expect(receipt.reportId, 1234);
        expect(receipt.code, 'BC-1234');
      },
    );
  }
  test(
    'Envelope receipt uses backend data and does not truncate the ID',
    () async {
      final api = apiWith(
        (_) async => reply({
          'status': 200,
          'data': {'reportId': 9, 'status': 'PENDING'},
        }),
      );
      expect(
        (await api.submitReport(targetId: 4, reason: 'Reason')).code,
        'BC-009',
      );
    },
  );
  for (final body in [
    null,
    {},
    [],
    true,
    {'reportId': 0, 'status': 'PENDING'},
    {'reportId': -1, 'status': 'PENDING'},
    {'reportId': 2.5, 'status': 'PENDING'},
    {'reportId': '12', 'status': 'PENDING'},
    {'reportId': 12},
    {'reportId': 12, 'status': 'RESOLVED'},
  ]) {
    test('HTTP 200 without a valid pending receipt fails: $body', () async {
      var calls = 0;
      final api = apiWith((_) async {
        calls++;
        return reply(body);
      });
      await expectLater(
        api.submitReport(targetId: 4, reason: 'Reason'),
        throwsA(isA<ApiException>()),
      );
      expect(
        calls,
        1,
        reason: 'Never automatically resubmit an uncertain mutation',
      );
      expect(api.hasAuthToken, isTrue);
    });
  }
  test('HTTP 200 invalid JSON never invents a receipt', () async {
    final api = apiWith((_) async => http.Response('not JSON', 200));
    await expectLater(
      api.submitReport(targetId: 4, reason: 'Reason'),
      throwsA(isA<ApiException>()),
    );
  });
  testWidgets(
    'Submit waits, blocks double taps and navigates with real receipt through production router',
    (tester) async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final api = apiWith((request) {
        calls++;
        return pending.future;
      });
      await openForm(tester, api);
      await submitForm(tester);
      await tester.tap(find.byType(ElevatedButton).first);
      expect(calls, 1);
      expect(find.byType(ReportReceivedScreen), findsNothing);
      pending.complete(reply({'reportId': 57, 'status': 'PENDING'}));
      await tester.pumpAndSettle();
      expect(find.textContaining('#BC-057'), findsOneWidget);
      expect(find.textContaining('BC-028'), findsNothing);
      expect(find.textContaining('nhận thông báo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Failed submission retains draft, retries and uses the new returned ID',
    (tester) async {
      var calls = 0;
      final api = apiWith(
        (_) async => ++calls == 1
            ? reply({'message': 'Lỗi thử nghiệm'}, 503)
            : reply({'reportId': 58, 'status': 'PENDING'}),
      );
      await openForm(tester, api);
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ReportReceivedScreen), findsNothing);
      expect(find.text('Mô tả thử nghiệm'), findsOneWidget);
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('#BC-058'), findsOneWidget);
    },
  );
  testWidgets(
    'Malformed successful submission retains form and explains uncertain result',
    (tester) async {
      final api = apiWith((_) async => reply({}));
      await openForm(tester, api);
      await submitForm(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ReportReceivedScreen), findsNothing);
      expect(find.text('Mô tả thử nghiệm'), findsOneWidget);
      expect(find.textContaining('có thể đã được tiếp nhận'), findsOneWidget);
    },
  );
  testWidgets('Missing target or blank description cannot submit', (
    tester,
  ) async {
    var calls = 0;
    final api = apiWith((_) async {
      calls++;
      return reply({});
    });
    await openForm(tester, api, target: null);
    await submitForm(tester);
    expect(calls, 0);
    expect(find.textContaining('Không xác định được người'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await openForm(tester, api);
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.textContaining('Vui lòng mô tả'), findsOneWidget);
  });
  testWidgets(
    'Receipt screen without backend confirmation never claims accepted or a fake ID',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReportReceivedScreen()));
      expect(find.text('Chưa có mã tiếp nhận'), findsOneWidget);
      expect(find.text('Đã nhận báo cáo'), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.textContaining('BC-028'), findsNothing);
    },
  );
  testWidgets(
    'Help explains target-specific entry without opening an unusable form',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: HelpSafetyScreen()));
      await tester.tap(find.text('Hướng dẫn báo cáo vi phạm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Báo cáo người dùng'), findsOneWidget);
      expect(
        find.textContaining('chưa hỗ trợ gửi báo lỗi ứng dụng'),
        findsOneWidget,
      );
      expect(find.byType(ReportViolationScreen), findsNothing);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Pending count excludes resolved, dismissed and unknown without hiding history',
    (tester) async {
      final api = apiWith(
        (_) async => reply([
          report(57, 'PENDING'),
          report(58, 'RESOLVED'),
          report(59, 'DISMISSED'),
          report(60, null),
        ]),
      );
      await openAdmin(tester, api);
      expect(find.text('Đang chờ: 1'), findsOneWidget);
      for (final id in [57, 58, 59, 60]) {
        expect(find.byKey(Key('admin_report_BC-0$id')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('admin_report_BC-058')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('admin_resolve_report')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Đang chờ: 1'), findsOneWidget);
    },
  );
  testWidgets('Initial loading error shows unknown count, not zero pending', (
    tester,
  ) async {
    final api = apiWith((_) async => reply({'message': 'Unavailable'}, 503));
    await openAdmin(tester, api);
    expect(find.text('Đang chờ: —'), findsOneWidget);
    expect(find.text('Đang chờ: 0'), findsNothing);
  });
  testWidgets('Missing report ID is an error rather than invented BC-001', (
    tester,
  ) async {
    final api = apiWith(
      (_) async => reply([
        {'status': 'PENDING'},
      ]),
    );
    await openAdmin(tester, api);
    expect(find.textContaining('Mã báo cáo không hợp lệ'), findsOneWidget);
    expect(find.byKey(const Key('admin_report_BC-001')), findsNothing);
  });
  testWidgets(
    'Admin retry preserves note per report through cancel, refresh and selection',
    (tester) async {
      final saves = <Map<String, String>>[];
      var saved = false;
      final api = apiWith((request) async {
        if (request.method == 'GET') {
          return reply([report(57, 'PENDING'), report(58, 'PENDING')]);
        }
        saves.add(request.url.queryParameters);
        return saved
            ? reply({'id': 57, 'status': 'RESOLVED'})
            : reply({'message': 'Save failed'}, 503);
      });
      await openAdmin(tester, api);
      await editNote(tester, 'Ghi chú A');
      await tester.tap(find.text('Lưu kết quả'));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả đã lưu'), findsNothing);
      await tester.tap(find.byKey(const Key('admin_report_BC-058')));
      await tester.pumpAndSettle();
      await editNote(tester, 'Ghi chú B');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đánh dấu đã xử lý'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ghi chú B',
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin_report_BC-057')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đánh dấu đã xử lý'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ghi chú A',
      );
      saved = true;
      await tester.tap(find.text('Lưu kết quả'));
      await tester.pumpAndSettle();
      expect(saves, hasLength(2));
      expect(saves.map((s) => s['note']), ['Ghi chú A', 'Ghi chú A']);
      expect(find.text('Kết quả đã lưu'), findsOneWidget);
    },
  );
  testWidgets(
    'Pending moderation prevents a second dialog and duplicate mutation',
    (tester) async {
      final pending = Completer<http.Response>();
      var mutations = 0;
      final api = apiWith((request) {
        if (request.method == 'GET') {
          return Future.value(reply([report(57, 'PENDING')]));
        }
        mutations++;
        return pending.future;
      });
      await openAdmin(tester, api);
      await editNote(tester, 'Checked');
      await tester.tap(find.text('Lưu kết quả'));
      await tester.pump(const Duration(seconds: 1));
      expect(mutations, 1);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('admin_resolve_report')),
            )
            .onPressed,
        isNull,
      );
      pending.complete(reply({'id': 57, 'status': 'RESOLVED'}));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả đã lưu'), findsOneWidget);
    },
  );
  for (final body in [
    {},
    {'id': 58, 'status': 'RESOLVED'},
    {'id': 57, 'status': 'PENDING'},
  ]) {
    test(
      'Admin HTTP 200 must confirm the selected ID and decision: $body',
      () async {
        final api = apiWith((_) async => reply(body));
        await expectLater(
          api.moderateAdminReport(57, status: 'RESOLVED', note: 'Checked'),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }
  testWidgets('Receipt route without arguments does not report success', (
    tester,
  ) async {
    final api = apiWith((_) async => reply({}));
    await openForm(tester, api);
    Navigator.of(
      tester.element(find.byType(ReportViolationScreen)),
    ).pushNamed(AppRoutes.reportReceived);
    await tester.pumpAndSettle();
    expect(find.text('Chưa có mã tiếp nhận'), findsOneWidget);
    expect(find.text('Đã nhận báo cáo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Delayed report response cannot confirm a new API session', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final api = apiWith((_) => pending.future);
    await openForm(tester, api);
    await submitForm(tester);
    api.setAuthToken('different-test-session');
    pending.complete(reply({'reportId': 57, 'status': 'PENDING'}));
    await tester.pumpAndSettle();
    expect(find.byType(ReportReceivedScreen), findsNothing);
    expect(find.text('Mô tả thử nghiệm'), findsOneWidget);
    expect(api.authToken, 'different-test-session');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Delayed response after closing report form does not navigate or throw',
    (tester) async {
      final pending = Completer<http.Response>();
      final api = apiWith((_) => pending.future);
      await openForm(tester, api);
      await submitForm(tester);
      await tester.pumpWidget(const MaterialApp(home: Text('Form closed')));
      pending.complete(reply({'reportId': 57, 'status': 'PENDING'}));
      await tester.pumpAndSettle();
      expect(find.text('Form closed'), findsOneWidget);
      expect(find.byType(ReportReceivedScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Pending count updates after refresh but keeps resolved report history',
    (tester) async {
      var resolved = false;
      final api = apiWith(
        (_) async => reply([report(57, resolved ? 'RESOLVED' : 'PENDING')]),
      );
      await openAdmin(tester, api);
      expect(find.text('Đang chờ: 1'), findsOneWidget);
      resolved = true;
      await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
      await tester.pumpAndSettle();
      expect(find.text('Đang chờ: 0'), findsOneWidget);
      expect(find.byKey(const Key('admin_report_BC-057')), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('admin_resolve_report')),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
