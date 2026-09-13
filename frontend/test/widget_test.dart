import 'package:flutter_test/flutter_test.dart';

import 'package:roommate_hub_mobile/main.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';

void main() {
  testWidgets('Ứng dụng khởi động tại màn hình đăng nhập', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    expect(find.text('Đăng Nhập Roommate Hub'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });

  testWidgets('Không thể mở màn hình cần đăng nhập khi chưa có phiên', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    appNavigatorKey.currentState!.pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.text('Đăng Nhập Roommate Hub'), findsOneWidget);
    expect(find.text('Roommate Hub'), findsNothing);
  });
}
