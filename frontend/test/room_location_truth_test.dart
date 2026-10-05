import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/district_names.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';
import 'package:roommate_hub_mobile/screens/room_viewing_screen.dart';
import 'package:roommate_hub_mobile/widgets/room_location_map.dart';

RoomPost postFor(String address, String district) => RoomPost(
  id: 10,
  title: 'Phòng từ API',
  description: 'Mô tả thực tế',
  price: 3200000,
  address: address,
  district: district,
  maxOccupants: 2,
  authorName: 'Người đăng',
  authorId: 5,
);

void main() {
  Future<void> openLocation(
    WidgetTester tester,
    RoomPost post, {
    Size size = const Size(360, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: RoomFlowScreen(post: post, mode: RoomFlowMode.location),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final district in [
    'Bình Thạnh',
    'Quận 1',
    'Quận 3',
    'Quận 7',
    'Thủ Đức',
    'Thu Duc',
    'Quan 10',
  ]) {
    testWidgets(
      '$district does not fabricate nearby places or travel estimates',
      (tester) async {
        final post = postFor('Địa chỉ thực tế của tin $district', district);
        await openLocation(tester, post);
        expect(find.text(post.address), findsOneWidget);
        expect(find.text(DistrictNames.display(district)), findsOneWidget);
        expect(find.byType(RoomLocationMap), findsOneWidget);
        expect(find.text('Khu vực tham khảo'), findsOneWidget);
        expect(
          find.text(
            'Chưa có dữ liệu địa điểm, khoảng cách và thời gian di chuyển.',
          ),
          findsNWidgets(2),
        );
        expect(
          find.textContaining(RegExp(r'Khoảng \d|phút đi bộ|phút xe máy')),
          findsNothing,
        );
        for (final fakePlace in [
          'Đại học HUTECH / GTVT',
          'Chợ Văn Thánh',
          'Đại học Khoa học Xã hội',
          'Chợ Bến Thành',
          'UEH',
          'Hồ Con Rùa',
          'RMIT',
          'Crescent Mall',
          'Làng Đại học',
          'Trạm Metro',
        ]) {
          expect(find.textContaining(fakePlace), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Address keywords do not infer proximity to HUTECH', (
    tester,
  ) async {
    await openLocation(tester, postFor('Nguyễn Gia Trí, gần HUTECH', ''));
    expect(find.text('Nguyễn Gia Trí, gần HUTECH'), findsOneWidget);
    expect(find.text('Chưa cập nhật khu vực'), findsOneWidget);
    expect(find.textContaining('Khoảng'), findsNothing);
    expect(find.text('Đại học HUTECH / GTVT'), findsNothing);
    expect(find.textContaining('Landmark 81'), findsNothing);
  });

  for (final blank in ['', '   ']) {
    testWidgets(
      'Missing address/district (${blank.length} chars) stays unknown',
      (tester) async {
        await openLocation(tester, postFor(blank, blank));
        expect(find.text('Chưa cập nhật khu vực'), findsOneWidget);
        expect(find.text('Chưa cập nhật địa chỉ'), findsOneWidget);
        expect(find.text('Khu vực gần trung tâm'), findsNothing);
        expect(find.text('Khu vực tham khảo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Location keeps the booking action and passes the actual post', (
    tester,
  ) async {
    final post = postFor('Địa chỉ thật', 'Bình Thạnh');
    await openLocation(tester, post, size: const Size(800, 1000));
    await tester.ensureVisible(find.text('Đặt lịch xem phòng'));
    await tester.tap(find.text('Đặt lịch xem phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomViewingScreen), findsOneWidget);
    expect(
      tester.widget<RoomViewingScreen>(find.byType(RoomViewingScreen)).post,
      same(post),
    );
    expect(tester.takeException(), isNull);
  });
}
