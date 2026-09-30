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
    );

void main() {
  testWidgets(
    'Chuyển đổi các ảnh không tích lũy route navigation và quay lại chỉ bằng 1 lần nhấn',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailsScreen(post: _testPost()),
        ),
      );

      // 1. Mở màn hình xem ảnh (RoomFlowScreen) bằng cách cuộn tới nút "Xem 4 ảnh"
      await tester.scrollUntilVisible(
        find.text('Xem 4 ảnh'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem 4 ảnh'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomFlowScreen), findsOneWidget);
      expect(find.text('Ảnh căn phòng'), findsWidgets);

      // 2. Nhấn chuyển lần lượt qua các danh mục ảnh
      await tester.tap(find.text('Phòng khách'));
      await tester.pumpAndSettle();
      expect(find.text('Không gian phòng khách'), findsOneWidget);

      await tester.tap(find.text('Phòng ngủ'));
      await tester.pumpAndSettle();
      expect(find.text('Không gian phòng ngủ'), findsOneWidget);

      await tester.tap(find.text('Khu bếp'));
      await tester.pumpAndSettle();
      expect(find.text('Không gian khu bếp'), findsOneWidget);

      await tester.tap(find.text('Ảnh tiếp theo →'));
      await tester.pumpAndSettle();
      expect(find.text('Ảnh căn phòng'), findsWidgets);

      await tester.tap(find.text('Tất cả ảnh'));
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
        MaterialApp(
          home: RoomDetailsScreen(post: _testPost()),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Xem 4 ảnh'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem 4 ảnh'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomFlowScreen), findsOneWidget);

      // Chuyển ảnh nhiều lần
      await tester.tap(find.text('Phòng khách'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng ngủ'));
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
