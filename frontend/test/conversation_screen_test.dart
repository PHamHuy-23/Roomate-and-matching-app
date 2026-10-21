import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/screens/conversation_screen.dart';

void main() {
  testWidgets('Màn liên hệ Minh Anh bám nội dung Penpot', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConversationScreen()));

    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('Đã kết nối · Trao đổi về phòng trọ'), findsOneWidget);
    expect(find.text('Chào Huy! Bạn muốn xem phòng\nvào chiều thứ Hai phải không?'), findsOneWidget);
    expect(find.text('Nhập tin nhắn…'), findsOneWidget);
  });

  testWidgets('Có thể gửi tin nhắn trong màn liên hệ', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConversationScreen()));

    await tester.enterText(find.byType(TextField), 'Hẹn bạn chiều thứ Hai nhé');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(find.text('Hẹn bạn chiều thứ Hai nhé'), findsOneWidget);
  });
}
