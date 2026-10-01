import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/contact_details_screen.dart';

void main() {
  for (final missing in [null, '', '   ']) {
    testWidgets('Liên hệ trống ($missing) không bị thay bằng dữ liệu mẫu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ContactDetailsScreen(
            contactId: 2,
            contactName: 'Người đã kết nối',
            phone: missing,
            email: missing,
          ),
        ),
      );
      expect(find.text('Chưa cập nhật số điện thoại'), findsOneWidget);
      expect(find.text('Chưa cập nhật email'), findsOneWidget);
      expect(find.text('0903 333 444'), findsNothing);
      expect(find.text('nguoidung@roommatehub.vn'), findsNothing);
      // Contact fields may be absent even after a valid connection.
      expect(find.text('Nhắn tin'), findsOneWidget);
    });
  }

  testWidgets('Có số điện thoại nhưng thiếu email thì không bịa email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactDetailsScreen(
          contactId: 2,
          phone: ' 0000000000 ',
          email: '',
        ),
      ),
    );
    expect(find.text('0000000000'), findsOneWidget);
    expect(find.text('Chưa cập nhật email'), findsOneWidget);
    expect(find.text('Chưa cập nhật số điện thoại'), findsNothing);
  });

  testWidgets('Có email nhưng thiếu số điện thoại thì không bịa số', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactDetailsScreen(
          contactId: 2,
          phone: '',
          email: ' partner@test.invalid ',
        ),
      ),
    );
    expect(find.text('partner@test.invalid'), findsOneWidget);
    expect(find.text('Chưa cập nhật số điện thoại'), findsOneWidget);
    expect(find.text('Chưa cập nhật email'), findsNothing);
  });

  testWidgets('Dữ liệu liên hệ đầy đủ hiển thị đúng dữ liệu được cấp', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactDetailsScreen(
          contactId: 2,
          phone: '0000000000',
          email: 'partner@test.invalid',
        ),
      ),
    );
    expect(find.text('0000000000'), findsOneWidget);
    expect(find.text('partner@test.invalid'), findsOneWidget);
    expect(find.textContaining('Chưa cập nhật'), findsNothing);
  });
}
