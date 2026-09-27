import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/listing_management_screen.dart';

RoomPost _post() => RoomPost(
  id: 2,
  title: 'Tin phòng Bình Thạnh',
  description: 'Phòng sáng, có nội thất cơ bản.',
  price: 2200000,
  address: 'Bình Thạnh, TP.HCM',
  maxOccupants: 2,
  authorName: 'Minh Anh',
  authorId: 4,
);

void main() {
  testWidgets('Quản lý tin đăng mở được flow xem trước và gửi tin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.myListings,
          authorId: 4,
          posts: <RoomPost>[],
        ),
      ),
    );

    expect(find.text('Tin đăng của tôi'), findsOneWidget);
    await tester.tap(find.text('+ Đăng phòng mới'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng phòng mới'), findsOneWidget);
    expect(find.text('Tiếp tục · Ảnh & tiện ích'), findsOneWidget);

  });

  testWidgets('Các trạng thái tin đăng hiển thị được', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.preview,
          authorId: 4,
          posts: <RoomPost>[_post()],
        ),
      ),
    );

    expect(find.text('Xem trước tin đăng'), findsOneWidget);
    expect(find.text('Gửi tin để duyệt'), findsOneWidget);
    await tester.tap(find.text('Gửi tin để duyệt'));
    await tester.pump();
    expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsOneWidget);
  });

  testWidgets('Chỉnh sửa tin đi qua đủ các bước và mũi tên quay lại từng bước', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.myListings,
          authorId: 4,
          posts: <RoomPost>[_post()],
        ),
      ),
    );

    await tester.tap(find.text('Chỉnh sửa tin đăng'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu & gửi kiểm duyệt'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tin đăng của tôi'), findsOneWidget);
  });
}
