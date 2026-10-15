import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/room_details_screen.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';

RoomPost _testPost() => RoomPost(
  id: 1,
  title: 'Phòng studio tiện nghi Bình Thạnh',
  description: 'Phòng ban công thoáng mát.',
  price: 3500000,
  address: 'Nguyễn Gia Trí, Bình Thạnh',
  maxOccupants: 2,
  authorName: 'Minh Anh',
  authorId: 5,
  imageUrl: 'https://example.invalid/room.jpg',
);

void main() {
  testWidgets(
    'Xem ảnh và thông tin quay lại đúng màn, không tạo danh mục ảnh giả',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RoomDetailsScreen(post: _testPost())),
      );

      // Open the one photo actually provided by the API.
      await tester.scrollUntilVisible(
        find.text('Xem ảnh phòng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem ảnh phòng'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomFlowScreen), findsOneWidget);
      expect(find.text('Ảnh căn phòng'), findsWidgets);

      expect(find.text('1 ảnh phòng'), findsOneWidget);
      expect(find.text('Phòng khách'), findsNothing);
      expect(find.text('Ảnh tiếp theo →'), findsNothing);
      await tester.tap(find.text('Xem thông tin căn phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Thông tin căn phòng'), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Ảnh căn phòng'), findsWidgets);

      // 3. Thử nút quay lại (Back button trên AppBar)
      // Mong đợi: Chỉ cần 1 lần bấm là quay thẳng về RoomDetailsScreen, KHÔNG bị lặp lại từng ảnh
      final backButton = find.byTooltip('Quay lại');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Đã trở về RoomDetailsScreen thành công
      expect(find.byType(RoomFlowScreen), findsNothing);
      expect(find.byType(RoomDetailsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Nút đóng (X) trên AppBar luôn thoát khỏi RoomFlowScreen ngay lập tức',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RoomDetailsScreen(post: _testPost())),
      );

      await tester.scrollUntilVisible(
        find.text('Xem ảnh phòng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem ảnh phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomFlowScreen), findsOneWidget);

      await tester.tap(find.text('Xem thông tin căn phòng'));
      await tester.pumpAndSettle();

      // Bấm nút Đóng (X)
      final closeButton = find.byTooltip('Đóng');
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Thoát thẳng về RoomDetailsScreen
      expect(find.byType(RoomFlowScreen), findsNothing);
      expect(find.byType(RoomDetailsScreen), findsOneWidget);
    },
  );
}
