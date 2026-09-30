import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_dashboard_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _DashboardApi implements ApiService {
  @override
  Future<List<dynamic>> getAdminUsers() async => [
        {'id': 1, 'status': 'ACTIVE'},
        {'id': 2, 'status': 'LOCKED'},
      ];

  @override
  Future<List<dynamic>> getAdminPosts() async => [
        {'id': 1, 'status': 'APPROVED'},
        {'id': 2, 'status': 'AVAILABLE'},
        {'id': 3, 'status': 'PENDING'},
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
}
