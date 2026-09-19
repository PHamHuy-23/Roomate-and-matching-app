import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roommate_hub_mobile/main.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';

void main() {
  testWidgets('Ứng dụng khởi động tại màn hình đăng nhập', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    expect(find.text('Đăng nhập'), findsNWidgets(2));
    expect(find.text('ROOMMATE HUB'), findsOneWidget);
  });

  testWidgets('Không thể mở màn hình cần đăng nhập khi chưa có phiên', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    appNavigatorKey.currentState!.pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsNWidgets(2));
  });

  testWidgets('Form đăng ký bắt buộc ngày sinh và trường đại học', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_birth_date_field')), findsOneWidget);
    expect(find.byKey(const Key('register_university_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'new.user@example.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), '123456');
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Người dùng mới',
    );
    await tester.enterText(
      find.byKey(const Key('register_phone_field')),
      '0901234567',
    );
    await tester.enterText(
      find.byKey(const Key('register_university_field')),
      'Đại học Quốc gia TP.HCM',
    );

    await tester.ensureVisible(find.text('Tạo tài khoản').last);
    await tester.tap(find.text('Tạo tài khoản').last);
    await tester.pump();

    expect(find.text('Vui lòng chọn ngày sinh'), findsOneWidget);
  });

  testWidgets('Form đăng ký kiểm tra mật khẩu xác nhận', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('register_confirm_password_field')),
      findsOneWidget,
    );
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
  });

  testWidgets('Mật khẩu có thể ẩn hiện trên giao diện Penpot', (tester) async {
    await tester.pumpWidget(const RoommateHubApp());

    final password = find.byKey(const Key('password_field'));
    expect(tester.widget<TextField>(password).obscureText, isTrue);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();

    expect(tester.widget<TextField>(password).obscureText, isFalse);
  });

  testWidgets(
    'Giao diện mới vẫn kiểm tra định dạng email trước khi đăng nhập',
    (tester) async {
      await tester.pumpWidget(const RoommateHubApp());
      await tester.enterText(find.byKey(const Key('email_field')), 'sai-email');
      await tester.enterText(find.byKey(const Key('password_field')), '123456');

      await tester.tap(find.text('Đăng nhập').last);
      await tester.pump();

      expect(find.text('Email không đúng định dạng'), findsOneWidget);
    },
  );

  testWidgets('Form đăng ký cuộn được ở màn hình rộng 320px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const RoommateHubApp());
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký ngay'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('register_university_field')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_university_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hồ sơ cho phép cập nhật ngày sinh và trường đại học', (
    WidgetTester tester,
  ) async {
    final user = AuthUser(
      token: 'token',
      userId: 1,
      email: 'user@example.com',
      fullName: 'Người dùng',
      gender: 'MALE',
      role: 'ROLE_USER',
      birthDate: DateTime(2004, 4, 12),
      university: 'Đại học Quốc gia TP.HCM',
    );

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(currentUser: user)),
    );

    expect(find.byKey(const Key('profile_birth_date_field')), findsOneWidget);
    expect(find.byKey(const Key('profile_university_field')), findsOneWidget);
    expect(find.text('Đại học Quốc gia TP.HCM'), findsOneWidget);
  });
}
