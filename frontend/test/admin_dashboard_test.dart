import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_dashboard_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _DashboardApi implements ApiService {
  _DashboardApi({this.posts});

  final List<dynamic>? posts;

  @override
  Future<List<dynamic>> getAdminUsers() async => [
    {'id': 1, 'status': 'ACTIVE'},
    {'id': 2, 'status': 'LOCKED'},
  ];

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
    expect(find.textContaining('Báo cáo chưa có API'), findsOneWidget);
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
    expect(find.text('3'), findsNothing);
    expect(find.textContaining('1 tài khoản đang khóa'), findsOneWidget);
  });
}
