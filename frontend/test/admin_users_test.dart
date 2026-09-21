import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_confirm_lock_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_user_details_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_users_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _AdminUsersApi implements ApiService {
  @override
  Future<List<dynamic>> getAdminUsers() async => [
        {
          'id': 1,
          'fullName': 'Minh Anh',
          'email': 'anh@example.com',
          'role': 'ROLE_USER',
          'status': 'ACTIVE',
          'createdAt': '2026-08-12T10:00:00',
        },
        {
          'id': 28,
          'fullName': 'Tài khoản #028',
          'email': 'user28@example.com',
          'role': 'ROLE_USER',
          'status': 'LOCKED',
          'createdAt': '2026-08-13T10:00:00',
        },
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Quản lý người dùng tải dữ liệu API và tìm kiếm được', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AdminUsersScreen(apiService: _AdminUsersApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Tài khoản #028'), findsOneWidget);
    expect(find.text('Đã khóa'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '028');
    await tester.pump();
    expect(find.text('Minh Anh'), findsNothing);
    expect(find.text('Tài khoản #028'), findsOneWidget);
  });

  testWidgets('Tài khoản đang hoạt động hiển thị nút khóa và mở màn xác nhận',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: const AdminUserDetailsScreen(
          user: {
            'id': '#001',
            'fullName': 'Minh Anh',
            'email': 'anh@example.com',
            'role': 'Thành viên',
            'status': 'Hoạt động',
          },
        ),
        routes: {
          AppRoutes.adminConfirmLock: (_) => const AdminConfirmLockScreen(),
        },
      ),
    );

    expect(find.text('Khóa tài khoản'), findsOneWidget);
    expect(find.text('Mở khóa tài khoản'), findsNothing);

    await tester.tap(find.text('Khóa tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận khóa tài khoản'), findsNWidgets(2));
  });

  testWidgets('Tài khoản đã khóa chỉ hiển thị nút mở khóa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AdminUserDetailsScreen(
          user: {
            'id': '#028',
            'fullName': 'Tài khoản #028',
            'email': 'user28@example.com',
            'role': 'Thành viên',
            'status': 'Đã khóa',
          },
          onToggleStatus: (_) async {},
        ),
      ),
    );

    expect(find.text('Mở khóa tài khoản'), findsOneWidget);
    expect(find.text('Khóa tài khoản'), findsNothing);

    await tester.tap(find.text('Mở khóa tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Đã mở khóa tài khoản.'), findsOneWidget);
    expect(find.text('Khóa tài khoản'), findsOneWidget);
  });
}
