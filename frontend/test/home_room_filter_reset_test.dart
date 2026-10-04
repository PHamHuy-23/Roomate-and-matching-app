import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/match_recommendation.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/home_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

class _RoomApi implements ApiService {
  @override
  bool get hasAuthToken => false;
  @override
  Set<int> get savedPostIds => {};
  @override
  Future<List<MatchRecommendation>> getRecommendations(int userId) async => [];
  @override
  Future<List<RoomPost>> getRoomPosts() async => [
    _room(1, 'Phòng giá dưới một triệu', 500000),
    _room(2, 'Phòng giá hơn mười lăm triệu', 20000000),
    _room(3, 'Phòng thỏa bộ lọc riêng', 3000000, area: 30, furnished: true),
    _room(4, 'Phòng dữ liệu cũ giá bằng không', 0),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RoomPost _room(
  int id,
  String title,
  double price, {
  double? area,
  bool furnished = false,
}) => RoomPost(
  id: id,
  title: title,
  description: 'Phòng kiểm thử',
  price: price,
  address: 'Địa chỉ kiểm thử',
  district: furnished ? 'Binh Thanh' : 'Thu Duc',
  maxOccupants: 2,
  authorName: 'Người đăng',
  authorId: 7,
  areaM2: area,
  amenities: furnished ? ['Nội thất'] : [],
);

Future<void> _home(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        apiService: _RoomApi(),
        initialTab: 1,
        currentUser: AuthUser(
          token: 'test',
          userId: 1,
          email: 'test@example.invalid',
          fullName: 'Tester',
          gender: 'MALE',
          role: 'ROLE_USER',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectAllRooms() {
  expect(find.text('Phòng giá dưới một triệu'), findsOneWidget);
  expect(find.text('Phòng giá hơn mười lăm triệu'), findsOneWidget);
  expect(find.text('Phòng thỏa bộ lọc riêng'), findsOneWidget);
  expect(find.text('Phòng dữ liệu cũ giá bằng không'), findsOneWidget);
}

Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.text('Lọc'));
  await tester.pumpAndSettle();
}

Future<void> _applyFilters(WidgetTester tester) async {
  await tester.tap(find.text('Xem phòng phù hợp'));
  await tester.pumpAndSettle();
}

Future<void> _selectCustomFilters(WidgetTester tester) async {
  await _openFilters(tester);
  await tester.tap(find.text('Tất cả khu vực'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bình Thạnh, TP.HCM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nội thất'));
  await tester.tap(find.text('Tất cả diện tích'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Từ 25 m²'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Không giới hạn giá'));
  await tester.pumpAndSettle();
  tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
    const RangeValues(2000000, 4000000),
  );
  await tester.pump();
  await tester.tap(find.text('Xác nhận'));
  await tester.pumpAndSettle();
  await _applyFilters(tester);
}

void main() {
  testWidgets(
    'Initial room feed has no hidden upper price or metadata filter',
    (tester) async {
      await _home(tester);
      _expectAllRooms();
    },
  );

  testWidgets(
    'Opening and reapplying unchanged filter leaves all rooms visible',
    (tester) async {
      await _home(tester);
      for (var attempt = 0; attempt < 2; attempt++) {
        await _openFilters(tester);
        await _applyFilters(tester);
        _expectAllRooms();
      }
    },
  );

  testWidgets(
    'Clear applied filter restores all districts, prices and unknown data',
    (tester) async {
      await _home(tester);
      await _selectCustomFilters(tester);
      expect(find.text('Phòng thỏa bộ lọc riêng'), findsOneWidget);
      expect(find.text('Phòng giá dưới một triệu'), findsNothing);
      expect(find.text('Phòng giá hơn mười lăm triệu'), findsNothing);
      await _openFilters(tester);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pump();
      await _applyFilters(tester);
      _expectAllRooms();
      expect(
        tester
            .widgetList<FilterChip>(find.byType(FilterChip))
            .every((chip) => !chip.selected),
        isTrue,
      );
    },
  );

  testWidgets(
    'Cancel after clearing a draft retains the active custom filter',
    (tester) async {
      await _home(tester);
      await _selectCustomFilters(tester);
      await _openFilters(tester);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Phòng thỏa bộ lọc riêng'), findsOneWidget);
      expect(find.text('Phòng giá dưới một triệu'), findsNothing);
      await _openFilters(tester);
      expect(find.text('2.000.000đ — 4.000.000đ'), findsOneWidget);
      expect(find.text('Từ 25 m²'), findsOneWidget);
      expect(find.text('Bình Thạnh, TP.HCM'), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Nội thất'))
            .selected,
        isTrue,
      );
    },
  );

  testWidgets('Turning quick price off does not leave a 15-million cap', (
    tester,
  ) async {
    await _home(tester);
    await tester.tap(find.text('Dưới 4 triệu'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng giá hơn mười lăm triệu'), findsNothing);
    expect(find.text('Phòng giá dưới một triệu'), findsOneWidget);
    await tester.tap(find.text('Dưới 4 triệu'));
    await tester.pumpAndSettle();
    _expectAllRooms();
  });

  testWidgets('View all from empty result removes every price bound', (
    tester,
  ) async {
    await _home(tester);
    await tester.enterText(find.byType(TextField), 'không có phòng phù hợp');
    await tester.pumpAndSettle();
    expect(find.text('Chưa tìm thấy phòng phù hợp'), findsOneWidget);
    await tester.tap(find.text('Xem tất cả phòng'));
    await tester.pumpAndSettle();
    _expectAllRooms();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'không có phòng phù hợp');
    await tester.pumpAndSettle();
    expect(find.text('Chưa tìm thấy phòng phù hợp'), findsOneWidget);
  });

  testWidgets(
    'Search clear button clears visible text and preserves advanced filters',
    (tester) async {
      await _home(tester);
      await tester.tap(find.text('Dưới 4 triệu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'không có phòng phù hợp');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Phòng giá dưới một triệu'), findsOneWidget);
      expect(find.text('Phòng giá hơn mười lăm triệu'), findsNothing);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Dưới 4 triệu'))
            .selected,
        isTrue,
      );
    },
  );
}
