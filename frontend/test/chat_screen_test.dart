import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/screens/chat_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

void main() {
  testWidgets('ChatScreen hiển thị giao diện đối thoại và nút đính kèm ảnh', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          partnerId: 2,
          partnerName: 'Nguyễn Văn A',
          apiService: ApiService.withClient(client),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Trò chuyện'), findsOneWidget);
    expect(find.textContaining('Trực tuyến'), findsNothing);
    expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });
}
