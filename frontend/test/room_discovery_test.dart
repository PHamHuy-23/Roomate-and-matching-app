import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/room_details_screen.dart';
import 'package:roommate_hub_mobile/screens/room_viewing_screen.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';
import 'package:roommate_hub_mobile/screens/room_filters_screen.dart';
import 'package:roommate_hub_mobile/screens/saved_rooms_screen.dart';

RoomPost _samplePost() => RoomPost(
  id: 1,
  title: 'Phòng đầy đủ nội thất gần HUTECH',
  description: 'Phòng sáng, có máy lạnh và khu vực bếp chung.',
  price: 2500000,
  address: '25 Điện Biên Phủ, Bình Thạnh',
  maxOccupants: 2,
  authorName: 'Minh Anh',
  authorId: 7,
);

void main() {
  testWidgets('Chi tiết phòng hiển thị thông tin và mở đặt lịch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RoomDetailsScreen(post: _samplePost())),
    );

    expect(find.text('Phòng đầy đủ nội thất gần HUTECH'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đặt lịch xem'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đặt lịch xem'), findsOneWidget);

    await tester.tap(find.text('Đặt lịch xem'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomViewingScreen), findsOneWidget);
    expect(find.text('Gửi yêu cầu xem phòng'), findsOneWidget);
  });

  testWidgets('Đặt lịch yêu cầu chọn khung giờ', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: RoomViewingScreen(post: _samplePost())),
    );

    await tester.tap(find.text('Gửi yêu cầu xem phòng'));
    await tester.pump();

    expect(find.text('Vui lòng chọn khung giờ xem phòng.'), findsOneWidget);
  });

  testWidgets('Luồng phòng có màn thông tin, ảnh và vị trí', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomFlowScreen(post: _samplePost(), mode: RoomFlowMode.roomInfo),
      ),
    );

    expect(find.text('Thông tin căn phòng'), findsOneWidget);
    await tester.tap(find.text('Xem vị trí & khu vực'));
    await tester.pumpAndSettle();
    expect(find.text('Vị trí & khu vực'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoomFlowScreen(
          post: _samplePost(),
          mode: RoomFlowMode.roomPhotos,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ảnh căn phòng'), findsWidgets);
    await tester.tap(find.text('Phòng khách'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng khách'), findsWidgets);
  });

  testWidgets('Bộ lọc và phòng đã lưu có trạng thái frontend', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: RoomFiltersScreen()));
    expect(find.text('Bộ lọc phòng trọ'), findsOneWidget);
    expect(find.text('Tìm căn phòng phù hợp với bạn'), findsOneWidget);
    expect(find.text('Bình Thạnh, TP.HCM'), findsOneWidget);
    expect(find.text('2.000.000đ — 4.000.000đ'), findsOneWidget);
    expect(find.text('Từ 20 m²'), findsOneWidget);
    expect(find.text('Xem phòng phù hợp'), findsOneWidget);
    await tester.tap(find.text('Máy lạnh'));
    await tester.scrollUntilVisible(
      find.text('Xóa bộ lọc'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: SavedRoomsScreen(posts: <RoomPost>[])),
    );
    expect(find.text('Chưa có phòng đã lưu'), findsOneWidget);
    expect(
      find.textContaining('Chạm biểu tượng lưu ở trang chi tiết'),
      findsOneWidget,
    );
    expect(find.text('Khám phá phòng'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SavedRoomsScreen(
          key: const ValueKey('saved-with-data'),
          posts: <RoomPost>[_samplePost()],
        ),
      ),
    );
    expect(
      find.text('Dễ dàng xem lại những căn phòng yêu thích'),
      findsOneWidget,
    );
    expect(find.text('Xem phòng'), findsOneWidget);
    expect(find.text('Bỏ lưu phòng'), findsOneWidget);
    await tester.tap(find.text('Bỏ lưu phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phòng đã lưu'), findsOneWidget);
  });
}
