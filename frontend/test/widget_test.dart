import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roommate_hub_mobile/main.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/edit_profile_screen.dart';
import 'package:roommate_hub_mobile/screens/auth_support_screen.dart';

void main() {
  testWidgets('Ứng dụng khởi động tại màn Roommate Hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    expect(find.text('Roommate Hub'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
  });

  testWidgets('Màn Roommate Hub chuyển đúng sang đăng ký', (tester) async {
    await tester.pumpWidget(const RoommateHubApp());

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsNWidgets(2));
    expect(find.byKey(const Key('register_birth_date_field')), findsOneWidget);
  });

  testWidgets('Nút quay lại ở màn đăng ký trở về Roommate Hub', (tester) async {
    await tester.pumpWidget(const RoommateHubApp());

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quay lại bắt đầu'));
    await tester.pumpAndSettle();

    expect(find.text('Roommate Hub'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
  });

  testWidgets('Không thể mở màn hình cần đăng nhập khi chưa có phiên', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    appNavigatorKey.currentState!.pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.text('Chào bạn trở lại!'), findsOneWidget);
  });

  testWidgets('Form đăng ký bắt buộc ngày sinh và trường đại học', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_birth_date_field')), findsOneWidget);
    expect(find.byKey(const Key('register_university_field')), findsOneWidget);
    expect(find.byKey(const Key('register_terms_checkbox')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'new.user@example.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), '12345678');
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      '12345678',
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
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('register_confirm_password_field')),
      findsOneWidget,
    );
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
  });

  testWidgets('Mật khẩu có thể ẩn hiện trên giao diện Penpot', (tester) async {
    await tester.pumpWidget(const RoommateHubApp());
    await tester.tap(find.text('Tôi đã có tài khoản'));
    await tester.pumpAndSettle();

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
      await tester.tap(find.text('Tôi đã có tài khoản'));
      await tester.pumpAndSettle();
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
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('register_university_field')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_university_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn chỉnh sửa hồ sơ hiển thị thông tin trường học', (
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
      MaterialApp(home: EditProfileScreen(currentUser: user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Trường học / nghề nghiệp'), findsOneWidget);
    expect(find.text('Đại học Quốc gia TP.HCM'), findsOneWidget);
  });

  testWidgets('Các route xác thực phụ hiển thị đúng màn hình Penpot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    appNavigatorKey.currentState!.pushNamed(AppRoutes.forgotPassword);
    await tester.pumpAndSettle();
    expect(find.text('Quên mật khẩu'), findsOneWidget);
    expect(find.byKey(const Key('forgot_password_email_field')), findsOneWidget);

    appNavigatorKey.currentState!.pushNamed(AppRoutes.verifyEmail);
    await tester.pumpAndSettle();
    expect(find.text('Xác minh email'), findsWidgets);
    expect(find.byKey(const Key('verify_email_code_field')), findsOneWidget);
    expect(find.text('Xác minh & tiếp tục'), findsOneWidget);
    expect(find.text('Đổi email'), findsOneWidget);
  });

  testWidgets('Màn tạo mật khẩu mới có mã xác nhận theo Penpot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    appNavigatorKey.currentState!.pushNamed(AppRoutes.newPassword);
    await tester.pumpAndSettle();

    expect(find.text('Tạo mật khẩu mới'), findsOneWidget);
    expect(find.text('Nhập mã trong email khôi phục'), findsOneWidget);
    expect(find.byKey(const Key('new_password_code_field')), findsOneWidget);
    expect(find.text('Lưu mật khẩu & đăng nhập'), findsOneWidget);
  });

  testWidgets('Màn đổi mật khẩu kiểm tra xác nhận trước khi gọi API', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthSupportScreen(mode: AuthSupportMode.changePassword),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('change_password_field')),
      '12345678',
    );
    await tester.enterText(
      find.byKey(const Key('current_password_field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('change_password_confirm_field')),
      'different',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
  });
}
