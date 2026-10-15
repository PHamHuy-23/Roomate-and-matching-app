import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/widgets/room_location_map.dart';

RoomPost _createPost({required String address, required String district}) =>
    RoomPost(
      id: 10,
      title: 'Phòng tiện nghi gần HUTECH',
      description: 'Phòng sạch đẹp.',
      price: 3200000,
      address: address,
      district: district,
      maxOccupants: 2,
      authorName: 'Minh Anh',
      authorId: 5,
    );

void main() {
  testWidgets('Canonical and legacy district names keep the same area center', (
    tester,
  ) async {
    for (final district in ['Thu Duc', 'Thủ Đức', 'TP. Thủ Đức, TP.HCM']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLocationMap(
              key: ValueKey(district),
              post: _createPost(address: 'Test address', district: district),
              height: 300,
            ),
          ),
        ),
      );
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter.latitude, 10.8504);
      expect(map.options.initialCenter.longitude, 106.7719);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomLocationMap(
            key: const ValueKey('Quan10'),
            post: _createPost(address: 'Quận 10', district: 'Quan 10'),
            height: 300,
          ),
        ),
      ),
    );
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, isNot(10.7769));
  });
  testWidgets(
    'RoomLocationMap hiển thị bản đồ tương tác OpenStreetMap và các nút điều khiển',
    (WidgetTester tester) async {
      final post = _createPost(
        address: '475A Điện Biên Phủ, Phường 25',
        district: 'Bình Thạnh',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoomLocationMap(post: post, height: 300)),
        ),
      );

      // 1. Kiểm tra widget bản đồ FlutterMap được dựng
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // 2. Tọa độ chỉ là tâm khu vực, không giả là tọa độ chính xác của phòng.
      expect(find.text('Khu vực tham khảo'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      // 3. Kiểm tra các nút tương tác zoom & Google Maps
      expect(find.byTooltip('Phóng to'), findsOneWidget);
      expect(find.byTooltip('Thu nhỏ'), findsOneWidget);
      expect(find.byTooltip('Căn giữa khu vực'), findsOneWidget);
      expect(find.byTooltip('Mở Google Maps'), findsOneWidget);

      // 4. Bấm thử các nút điều khiển
      await tester.tap(find.byTooltip('Phóng to'));
      await tester.pump();

      await tester.tap(find.byTooltip('Thu nhỏ'));
      await tester.pump();

      await tester.tap(find.byTooltip('Căn giữa khu vực'));
      await tester.pump();
    },
  );
}
