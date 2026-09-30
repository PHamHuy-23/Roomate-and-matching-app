import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/chat_screen.dart';

void main() {
  testWidgets('ChatScreen hiển thị giao diện đối thoại và nút đính kèm ảnh', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatScreen(
          partnerId: 2,
          partnerName: 'Nguyễn Văn A',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Đã kết nối · Trực tuyến'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });
}
