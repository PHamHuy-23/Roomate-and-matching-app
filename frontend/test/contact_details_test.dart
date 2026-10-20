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
      expect(find.text('Người dùng không chia sẻ số điện thoại'), findsOneWidget);
      expect(find.text('Người dùng không chia sẻ email'), findsOneWidget);
      expect(find.text('0903 333 444'), findsNothing);
      expect(find.text('nguoidung@roommatehub.vn'), findsNothing);
      // Contact fields may be absent even after a valid connection.
      expect(find.text('Nhắn tin'), findsOneWidget);
      expect(find.text('Mở Zalo'), findsOneWidget);
      // Khi không có số điện thoại, nút Zalo bị disable (onPressed null)
      final zaloButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Mở Zalo'),
      );
      expect(zaloButton.onPressed, isNull);
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
          shareZalo: true,
        ),
      ),
    );
    expect(find.text('0000000000'), findsOneWidget);
    expect(find.text('Người dùng không chia sẻ email'), findsOneWidget);
    expect(find.text('Người dùng không chia sẻ số điện thoại'), findsNothing);
    final zaloButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Mở Zalo'),
    );
    expect(zaloButton.onPressed, isNotNull);
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
    expect(find.text('Người dùng không chia sẻ số điện thoại'), findsOneWidget);
    expect(find.text('Người dùng không chia sẻ email'), findsNothing);
    final zaloButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Mở Zalo'),
    );
    expect(zaloButton.onPressed, isNull);
  });

  testWidgets('Dữ liệu liên hệ đầy đủ hiển thị đúng dữ liệu được cấp và Zalo bật', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactDetailsScreen(
          contactId: 2,
          phone: '0000000000',
          email: 'partner@test.invalid',
          shareZalo: true,
        ),
      ),
    );
    expect(find.text('0000000000'), findsOneWidget);
    expect(find.text('partner@test.invalid'), findsOneWidget);
    expect(find.textContaining('không chia sẻ'), findsNothing);
    final zaloButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Mở Zalo'),
    );
    expect(zaloButton.onPressed, isNotNull);
  });

  testWidgets('Có số điện thoại nhưng tắt shareZalo thì nút Zalo bị disable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContactDetailsScreen(
          contactId: 2,
          phone: '0000000000',
          email: 'partner@test.invalid',
          shareZalo: false,
        ),
      ),
    );
    expect(find.text('0000000000'), findsOneWidget);
    final zaloButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Mở Zalo'),
    );
    expect(zaloButton.onPressed, isNull);
  });
}
