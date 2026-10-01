import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_confirm_lock_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_user_details_screen.dart';
import 'package:roommate_hub_mobile/screens/admin/admin_users_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

class _AdminUsersApi implements ApiService {
  @override
  Future<List<dynamic>> getAdminUsers() async => [
    {
      'id': 1,
      'fullName': 'Minh Anh',
      'email': 'anh@example.com',
      'role': 'ROLE_USER',
      'status': 'ACTIVE',
      'phone': '0000000000',
      'gender': 'FEMALE',
      'university': 'Đại học thử nghiệm',
      'birthDate': '2002-04-12',
      'createdAt': '2026-08-12T10:00:00',
    },
    {
      'id': 28,
      'fullName': 'Tài khoản #028',
      'email': 'user28@example.com',
      'role': 'ROLE_USER',
      'status': 'LOCKED',
      'phone': '   ',
      'gender': null,
      'university': '',
      'createdAt': '2026-08-13T10:00:00',
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Danh sách admin chuyển đầy đủ hồ sơ thật sang chi tiết', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = ApiService()..setAuthToken('test-access');
    addTearDown(api.clearAuthToken);
    final session = AuthSession(apiService: api)
      ..updateUser(
        AuthUser(
          token: 'test-access',
          userId: 99,
          email: 'admin@test.invalid',
          fullName: 'Admin',
          gender: 'MALE',
          role: 'ROLE_ADMIN',
        ),
      );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthSession>.value(
        value: session,
        child: MaterialApp(
          home: AdminUsersScreen(apiService: _AdminUsersApi()),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('08 / 2026'), findsNWidgets(2));
    await tester.tap(find.text('Chi tiết →').first);
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserDetailsScreen), findsOneWidget);
    expect(find.textContaining('Số điện thoại: 0000000000'), findsOneWidget);
    expect(find.textContaining('Giới tính: Nữ'), findsOneWidget);
    expect(
      find.textContaining('Trường học: Đại học thử nghiệm'),
      findsOneWidget,
    );
    expect(find.textContaining('Ngày sinh: 2002-04-12'), findsOneWidget);
    expect(find.textContaining('Đã xác minh email'), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chi tiết →').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Số điện thoại: Chưa cập nhật SĐT'),
      findsOneWidget,
    );
    expect(find.textContaining('Giới tính: Chưa cập nhật'), findsOneWidget);
    expect(
      find.textContaining('Trường học: Chưa cập nhật trường'),
      findsOneWidget,
    );
  });

  testWidgets('Quản lý người dùng tải dữ liệu API và tìm kiếm được', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: AdminUsersScreen(apiService: _AdminUsersApi())),
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

  testWidgets('Tài khoản đang hoạt động hiển thị nút khóa và mở màn xác nhận', (
    tester,
  ) async {
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
