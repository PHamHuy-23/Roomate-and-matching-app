import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_dashboard_screen.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _DashboardApi implements ApiService {
  _DashboardApi({this.posts, this.users, this.reports, this.reportsResponse});

  final List<dynamic>? posts;
  final List<dynamic>? users;
  final List<dynamic>? reports;
  final Future<List<dynamic>>? reportsResponse;
  bool failUsers = false;
  bool failReports = false;

  @override
  Future<List<dynamic>> getAdminUsers() async {
    if (failUsers) throw const ApiException('Lỗi tải người dùng');
    return users ??
        [
          {'id': 1, 'status': 'ACTIVE', 'createdAt': '2026-10-05T14:32:00'},
          {'id': 2, 'status': 'LOCKED'},
        ];
  }

  @override
  Future<List<dynamic>> getAdminReports() async {
    if (failReports) throw const ApiException('Lỗi tải báo cáo');
    return reportsResponse ??
        reports ??
        [
          {'id': 101, 'status': 'PENDING'},
          {'id': 102, 'status': 'PENDING'},
          {'id': 103, 'status': 'PENDING'},
          {'id': 104, 'status': 'RESOLVED', 'createdAt': '2026-10-05T14:10:00'},
        ];
  }

  @override
  Future<List<dynamic>> getAdminPosts() async =>
      posts ??
      [
        {'id': 1, 'status': 'APPROVED', 'publiclyVisible': true},
        {'id': 2, 'status': 'AVAILABLE', 'publiclyVisible': true},
        {'id': 3, 'status': 'PENDING', 'publiclyVisible': false},
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> openDashboard(WidgetTester tester, ApiService api) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: AdminDashboardScreen(apiService: api)),
    );
    await tester.pumpAndSettle();
  }

  void expectUnsupportedPanels() {
    expect(
      find.byKey(const Key('admin_weekly_connections_unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('admin_activity_log_unavailable')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Chưa hỗ trợ thống kê kết nối theo tuần'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Chưa hỗ trợ nhật ký hoạt động'),
      findsOneWidget,
    );
    for (final fake in [
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN',
      'RH-024',
      'BC-028',
      '14:32',
      '14:10',
    ]) {
      expect(find.textContaining(fake), findsNothing);
    }
  }

  testWidgets(
    'Dashboard uses real HTTP responses, not creation dates as activity',
    (tester) async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        expect(request.method, 'GET');
        expect(
          request.headers['Authorization'],
          'Bearer test-dashboard-access',
        );
        final data = switch (request.url.path) {
          '/api/v1/admin/users' => [
            {'id': 901, 'status': 'ACTIVE', 'createdAt': '2026-10-05T14:32:00'},
          ],
          '/api/v1/admin/posts' => [
            {
              'id': 902,
              'status': 'APPROVED',
              'publiclyVisible': true,
              'createdAt': '2026-10-05T14:10:00',
            },
            {'id': 903, 'status': 'PENDING', 'publiclyVisible': false},
          ],
          '/api/v1/admin/reports' => [
            {
              'id': 904,
              'status': 'RESOLVED',
              'createdAt': '2026-10-05T14:10:00',
            },
            {'id': 905, 'status': 'PENDING'},
          ],
          _ => throw StateError('Unexpected API call: ${request.url.path}'),
        };
        return http.Response(
          jsonEncode({'status': 'success', 'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final api = ApiService.withClient(client)
        ..setAuthToken('test-dashboard-access');
      await openDashboard(tester, api);
      expect(find.text('1'), findsNWidgets(4));
      expect(find.textContaining('0 tài khoản đang khóa'), findsOneWidget);
      expect(
        paths,
        unorderedEquals([
          '/api/v1/admin/users',
          '/api/v1/admin/posts',
          '/api/v1/admin/reports',
        ]),
      );
      expectUnsupportedPanels();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tổng quan quản trị hiển thị số liệu từ API', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: AdminDashboardScreen(apiService: _DashboardApi())),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('1 tài khoản đang khóa'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('3 báo cáo cần xử lý'), findsOneWidget);
    expectUnsupportedPanels();
  });

  testWidgets('Tin đang hiển thị không tính tin bị ẩn của tài khoản khóa', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final posts = <dynamic>[
      {'id': 1, 'status': 'APPROVED', 'publiclyVisible': true},
      {'id': 2, 'status': 'APPROVED', 'publiclyVisible': false},
      {'id': 3, 'status': 'AVAILABLE', 'publiclyVisible': false},
      {'id': 4, 'status': 'PENDING', 'publiclyVisible': false},
      {'id': 5, 'status': 'CLOSED', 'publiclyVisible': false},
      {'id': 6, 'status': 'REJECTED', 'publiclyVisible': false},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(apiService: _DashboardApi(posts: posts)),
      ),
    );
    await tester.pumpAndSettle();

    // One public post and one pending post; the user count stays two.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('1 tài khoản đang khóa'), findsOneWidget);
  });

  testWidgets('Empty API data gives real zero counts, not fake chart/history', (
    tester,
  ) async {
    await openDashboard(
      tester,
      _DashboardApi(users: [], posts: [], reports: []),
    );
    expect(find.text('0'), findsNWidgets(4));
    expect(find.textContaining('0 báo cáo cần xử lý'), findsOneWidget);
    expectUnsupportedPanels();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed API data is unknown, not zero or successful activity', (
    tester,
  ) async {
    final api = _DashboardApi()..failUsers = true;
    await openDashboard(tester, api);
    expect(find.text('Lỗi tải người dùng'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('0'), findsNothing);
    expectUnsupportedPanels();
    api.failUsers = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi tải người dùng'), findsNothing);
    expect(find.text('2'), findsNWidgets(2));
    expectUnsupportedPanels();
  });

  testWidgets('Report API failure preserves other counts and can retry', (
    tester,
  ) async {
    final api = _DashboardApi()..failReports = true;
    await openDashboard(tester, api);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('—'), findsOneWidget);
    expect(
      find.textContaining('Không thể tải số báo cáo cần xử lý'),
      findsOneWidget,
    );
    expect(find.textContaining('Báo cáo chưa có API'), findsNothing);
    expectUnsupportedPanels();
    api.failReports = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.textContaining('Không thể tải số báo cáo cần xử lý'),
      findsNothing,
    );
  });

  testWidgets('Pending report request shows loading rather than missing API', (
    tester,
  ) async {
    final response = Completer<List<dynamic>>();
    await openDashboard(
      tester,
      _DashboardApi(reportsResponse: response.future),
    );
    expect(find.text('…'), findsOneWidget);
    expect(
      find.textContaining('Đang tải số báo cáo cần xử lý'),
      findsOneWidget,
    );
    expect(find.textContaining('Báo cáo chưa có API'), findsNothing);
    expectUnsupportedPanels();
    response.complete([
      {'id': 300, 'status': 'PENDING'},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('…'), findsNothing);
    expect(find.textContaining('1 báo cáo cần xử lý'), findsOneWidget);
  });

  testWidgets('Failed retry does not present stale counts as current data', (
    tester,
  ) async {
    final api = _DashboardApi()..failReports = true;
    await openDashboard(tester, api);
    expect(find.text('2'), findsNWidgets(2));
    api.failUsers = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
    expect(find.text('—'), findsNWidgets(4));
    expectUnsupportedPanels();
  });

  for (final route in [
    AppRoutes.adminModeratePost,
    AppRoutes.adminReports,
    AppRoutes.adminUsers,
  ]) {
    testWidgets('Real count action still opens $route', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(apiService: _DashboardApi()),
          routes: {route: (_) => Scaffold(body: Text('Destination $route'))},
        ),
      );
      await tester.pumpAndSettle();
      final label = switch (route) {
        AppRoutes.adminModeratePost => '1 tin đang chờ duyệt',
        AppRoutes.adminReports => '3 báo cáo cần xử lý',
        _ => '1 tài khoản đang khóa',
      };
      await tester.tap(find.textContaining(label));
      await tester.pumpAndSettle();
      expect(find.text('Destination $route'), findsOneWidget);
    });
  }
}
