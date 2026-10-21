import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/room_details_screen.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';

RoomPost post({
  String? image,
  List<String> amenities = const [],
  double? deposit,
  double? utilities,
  String description = '',
}) => RoomPost(
  id: 1,
  title: 'Phòng kiểm thử',
  description: description,
  price: 2500000,
  address: 'Địa chỉ kiểm thử',
  maxOccupants: 2,
  authorName: 'Người đăng',
  authorId: 7,
  imageUrl: image,
  amenities: amenities,
  deposit: deposit,
  electricityWaterCost: utilities,
);

void main() {
  testWidgets('Chi tiết không tự khẳng định có nội thất hoặc bốn ảnh', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: RoomDetailsScreen(post: post())));
    expect(find.text('Có nội thất'), findsNothing);
    expect(find.text('Chưa cập nhật tiện ích'), findsOneWidget);
    expect(find.text('Xem 4 ảnh'), findsNothing);
    await tester.ensureVisible(find.text('Chưa có ảnh phòng'));
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Chưa có ảnh phòng'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Chi tiết dùng đúng tiện ích thực tế thay vì suy đoán', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomDetailsScreen(post: post(amenities: ['Wi-Fi', 'Máy giặt'])),
      ),
    );
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('Máy giặt'), findsOneWidget);
    expect(find.text('Có nội thất'), findsNothing);
    expect(find.text('Chưa cập nhật tiện ích'), findsNothing);
  });

  testWidgets(
    'Thông tin trống không thay bằng tiện ích, tiền cọc và nội quy giả',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoomFlowScreen(post: post(), mode: RoomFlowMode.roomInfo),
        ),
      );
      expect(find.text('Chưa cập nhật mô tả phòng.'), findsOneWidget);
      expect(find.text('Chưa cập nhật tiện ích.'), findsOneWidget);
      expect(find.text('Điều hòa'), findsNothing);
      expect(find.text('Giường & tủ'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Nội quy'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          'Nội quy chưa được cung cấp. Vui lòng trao đổi với người đăng.',
        ),
        findsOneWidget,
      );
      expect(find.text('3.800đ / kWh'), findsNothing);
      expect(find.text('100.000đ / người'), findsNothing);
      expect(find.text('150.000đ / tháng'), findsNothing);
    },
  );

  testWidgets(
    'Tiền cọc và tổng chi phí lấy từ dữ liệu, không mặc định bằng tiền thuê',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoomFlowScreen(
            post: post(
              deposit: 900000,
              utilities: 320000,
              amenities: ['Wi-Fi'],
            ),
            mode: RoomFlowMode.roomInfo,
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Tiền cọc'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('900.000'), findsOneWidget);
      expect(find.textContaining('320.000'), findsOneWidget);
    },
  );

  for (final mode in [
    RoomFlowMode.roomPhotos,
    RoomFlowMode.livingRoom,
    RoomFlowMode.bedroom,
    RoomFlowMode.kitchen,
  ]) {
    testWidgets(
      'Màn ảnh $mode không tạo thêm ảnh hoặc nhãn phòng khi dữ liệu trống',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RoomFlowScreen(post: post(), mode: mode),
          ),
        );
        expect(
          find.text('Người đăng chưa cập nhật ảnh phòng.'),
          findsOneWidget,
        );
        expect(find.text('1 ảnh phòng'), findsNothing);
        expect(find.text('Phòng khách'), findsNothing);
        expect(find.textContaining('/ 04'), findsNothing);
        expect(find.text('Ánh sáng tự nhiên & ban công riêng'), findsNothing);
      },
    );
  }
}
