import 'package:flutter_test/flutter_test.dart';

import 'package:roommate_hub_mobile/main.dart';

void main() {
  testWidgets('Ứng dụng khởi động tại màn hình đăng nhập', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoommateHubApp());

    expect(find.text('Đăng Nhập Roommate Hub'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}
