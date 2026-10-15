import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_reports_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

late DateTime _signedAt;

class _EvidenceApi implements ApiService {
  bool authenticated = true;
  final requests = <Completer<List<dynamic>>>[];

  @override
  bool get hasAuthToken => authenticated;

  @override
  Future<List<dynamic>> getAdminReports() {
    final request = Completer<List<dynamic>>();
    requests.add(request);
    return request.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _report(int id, String? url) => {
  'id': id,
  'targetType': 'ROOM_POST',
  'targetId': id + 10,
  'reason': 'Báo cáo thử nghiệm $id',
  'reporterName': 'Người thử nghiệm',
  'status': 'PENDING',
  'actionNote': 'Ghi chú từ server $id',
  'evidenceUrl': url,
};

String _url(int id, String version, {DateTime? signedAt, int expires = 120}) {
  final date = (signedAt ?? _signedAt).toUtc();
  String pad(int value, int width) => value.toString().padLeft(width, '0');
  final timestamp =
      '${pad(date.year, 4)}${pad(date.month, 2)}${pad(date.day, 2)}'
      'T${pad(date.hour, 2)}${pad(date.minute, 2)}${pad(date.second, 2)}Z';
  final signature = version.codeUnits
      .map((value) => value.toRadixString(16))
      .join()
      .padRight(64, '0')
      .substring(0, 64);
  return 'https://private.example.test/reports/$id/test.png?'
      'X-Amz-Signature=$signature&X-Amz-Date=$timestamp&X-Amz-Expires=$expires';
}

String? _displayedUrl(WidgetTester tester) {
  final finder = find.byType(Image);
  if (finder.evaluate().isEmpty) return null;
  return (tester.widget<Image>(finder).image as NetworkImage).url;
}

Future<void> _open(WidgetTester tester, _EvidenceApi api) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: AdminReportsScreen(apiService: api)),
  );
}

Future<void> _complete(
  WidgetTester tester,
  _EvidenceApi api,
  int index,
  List<dynamic> reports,
) async {
  api.requests[index].complete(reports);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _signedAt = DateTime.now().toUtc());
  testWidgets('initial evidence is loaded fresh from the authenticated API', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    expect(api.requests, hasLength(1));
    expect(find.byKey(const Key('admin_evidence_loading')), findsOneWidget);
    expect(_displayedUrl(tester), isNull);

    await _complete(tester, api, 0, [_report(28, _url(28, 'initial'))]);
    expect(_displayedUrl(tester), _url(28, 'initial'));
    expect(find.text('BC-028 / Chi tiết báo cáo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecting after expiry renews evidence and preserves ID on reorder',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [
        _report(28, _url(28, 'old')),
        _report(27, _url(27, 'old')),
      ]);
      await tester.pump(const Duration(minutes: 3));
      await tester.tap(find.byKey(const Key('admin_report_BC-027')));
      await tester.pump();

      expect(api.requests, hasLength(2));
      expect(find.text('BC-027 / Chi tiết báo cáo'), findsOneWidget);
      expect(_displayedUrl(tester), isNull);
      expect(find.byKey(const Key('admin_evidence_loading')), findsOneWidget);

      await _complete(tester, api, 1, [
        _report(27, _url(27, 'fresh')),
        _report(28, _url(28, 'fresh')),
      ]);
      expect(find.text('BC-027 / Chi tiết báo cáo'), findsOneWidget);
      expect(_displayedUrl(tester), _url(27, 'fresh'));
      expect(find.text('Ghi chú từ server 27'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping current report also requests a new signed URL', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    await _complete(tester, api, 0, [_report(28, _url(28, 'old'))]);

    await tester.tap(find.byKey(const Key('admin_report_BC-028')));
    await tester.pump();
    expect(api.requests, hasLength(2));
    expect(_displayedUrl(tester), isNull);
    await _complete(tester, api, 1, [_report(28, _url(28, 'renewed'))]);
    expect(_displayedUrl(tester), _url(28, 'renewed'));
  });

  testWidgets(
    'out-of-order responses cannot restore evidence for stale selection',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [_report(28, null), _report(27, null)]);
      await tester.tap(find.byKey(const Key('admin_report_BC-027')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin_report_BC-028')));
      await tester.pump();
      expect(api.requests, hasLength(3));

      await _complete(tester, api, 2, [_report(28, _url(28, 'current'))]);
      await _complete(tester, api, 1, [_report(27, _url(27, 'stale'))]);
      expect(find.text('BC-028 / Chi tiết báo cáo'), findsOneWidget);
      expect(_displayedUrl(tester), _url(28, 'current'));
      expect(find.byKey(const Key('admin_report_BC-027')), findsNothing);
    },
  );

  testWidgets(
    'refresh failure keeps selection/list but hides expired image and retries',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [_report(28, _url(28, 'old'))]);
      await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
      await tester.pump();
      expect(_displayedUrl(tester), isNull);
      api.requests[1].completeError(
        Exception('403 không có quyền tải báo cáo'),
      );
      await tester.pumpAndSettle();

      expect(find.text('BC-028 / Chi tiết báo cáo'), findsOneWidget);
      expect(find.byKey(const Key('admin_report_BC-028')), findsOneWidget);
      expect(find.byKey(const Key('admin_evidence_error')), findsOneWidget);
      expect(find.textContaining('403 không có quyền'), findsOneWidget);
      expect(_displayedUrl(tester), isNull);

      await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
      await tester.pump();
      await _complete(tester, api, 2, [_report(28, _url(28, 'retry'))]);
      expect(_displayedUrl(tester), _url(28, 'retry'));
      expect(find.byKey(const Key('admin_evidence_error')), findsNothing);
    },
  );

  testWidgets(
    'network image error offers API renewal instead of reusing the old URL',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [_report(28, _url(28, 'expired'))]);
      // Flutter's test HTTP client returns 400; the screen handles it inline.
      expect(find.byKey(const Key('admin_evidence_retry')), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin_evidence_retry')));
      await tester.pump();
      expect(api.requests, hasLength(2));
      expect(_displayedUrl(tester), isNull);
      await _complete(tester, api, 1, [_report(28, _url(28, 'retry'))]);
      expect(_displayedUrl(tester), _url(28, 'retry'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renewal preserves a currently typed moderation note', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    await _complete(tester, api, 0, [_report(28, null)]);
    final refresh = tester.widget<TextButton>(
      find.byKey(const Key('admin_evidence_refresh')),
    );
    await tester.tap(find.text('Đánh dấu đã xử lý'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Bản nháp ghi chú đang viết',
    );

    refresh.onPressed!();
    await tester.pump();
    await _complete(tester, api, 1, [_report(28, _url(28, 'renewed'))]);
    expect(find.text('Bản nháp ghi chú đang viết'), findsOneWidget);
    expect(find.text('Kết quả xem xét báo cáo'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('BC-028 / Chi tiết báo cáo'), findsOneWidget);
    expect(_displayedUrl(tester), _url(28, 'renewed'));
  });

  testWidgets('removed report does not silently show another report evidence', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    await _complete(tester, api, 0, [_report(28, null), _report(27, null)]);
    await tester.tap(find.byKey(const Key('admin_report_BC-027')));
    await tester.pump();
    await _complete(tester, api, 1, [_report(28, _url(28, 'other'))]);
    expect(find.text('BC-027 / Chi tiết báo cáo'), findsNothing);
    expect(find.text('BC-028 / Chi tiết báo cáo'), findsNothing);
    expect(find.byKey(const Key('admin_evidence_error')), findsOneWidget);
    expect(_displayedUrl(tester), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late refresh after dispose has no state update or exception', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    await _complete(tester, api, 0, [_report(28, null)]);
    await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    api.requests[1].complete([_report(28, _url(28, 'late'))]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing login clears the old image and does not call protected API',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [_report(28, _url(28, 'old'))]);
      api.authenticated = false;
      await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
      await tester.pumpAndSettle();
      expect(api.requests, hasLength(1));
      expect(_displayedUrl(tester), isNull);
      expect(find.text('Cần đăng nhập lại để tải báo cáo.'), findsOneWidget);
    },
  );

  testWidgets(
    'no evidence remains empty without fallback to legacy image URL',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      await _complete(tester, api, 0, [
        {
          ..._report(28, null),
          'imageUrl': 'https://public.example.test/old.png',
        },
      ]);
      expect(_displayedUrl(tester), isNull);
      expect(find.text('Không có ảnh đính kèm'), findsOneWidget);
    },
  );

  testWidgets('expired link is not requested and can be renewed via API', (
    tester,
  ) async {
    final api = _EvidenceApi();
    await _open(tester, api);
    await _complete(tester, api, 0, [
      _report(
        28,
        _url(
          28,
          'expired',
          signedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ),
    ]);
    expect(_displayedUrl(tester), isNull);
    expect(find.textContaining('Liên kết ảnh đã hết hạn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
    await tester.pump();
    final fresh = _url(28, 'fresh');
    await _complete(tester, api, 1, [_report(28, fresh)]);
    expect(_displayedUrl(tester), fresh);
  });

  testWidgets(
    'public, HTTP and malformed signatures never become displayed evidence',
    (tester) async {
      final api = _EvidenceApi();
      await _open(tester, api);
      final signed = _url(28, 'valid');
      final invalidUrls = [
        'https://public.example.test/reports/28/photo.png',
        signed.replaceFirst('https:', 'http:'),
        signed.replaceFirst(
          RegExp(r'X-Amz-Signature=[0-9a-f]+'),
          'X-Amz-Signature=invalid',
        ),
        signed.replaceFirst(
          RegExp(r'X-Amz-Date=\d{8}T\d{6}Z'),
          'X-Amz-Date=20261399T250000Z',
        ),
        signed.replaceFirst('X-Amz-Expires=120', 'X-Amz-Expires=3600'),
        '$signed#fragment',
        '$signed&X-Amz-Expires=120',
      ];
      for (var index = 0; index < invalidUrls.length; index++) {
        if (index > 0) {
          await tester.tap(find.byKey(const Key('admin_evidence_refresh')));
          await tester.pump();
        }
        await _complete(tester, api, index, [_report(28, invalidUrls[index])]);
        expect(_displayedUrl(tester), isNull);
        expect(
          find.textContaining('Liên kết ảnh không hợp lệ'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}
