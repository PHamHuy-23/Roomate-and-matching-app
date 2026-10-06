import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/room_amenities.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/screens/home_screen.dart';
import 'package:roommate_hub_mobile/screens/listing_management_screen.dart';
import 'package:roommate_hub_mobile/screens/room_details_screen.dart';
import 'package:roommate_hub_mobile/screens/room_filters_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

Map<String, dynamic> payload({
  int id = 1,
  double? area,
  String amenities = 'Chỗ để xe',
}) => {
  'id': id,
  'title': 'Room $id',
  'description': 'Actual room description',
  'address': 'Actual address',
  'district': 'Thu Duc',
  'price': 2200000,
  'maxOccupants': 3,
  'currentOccupants': 1,
  'authorId': 4,
  'authorName': 'Owner',
  'area': area,
  'amenities': amenities,
  'deposit': 1000000,
  'electricityWaterCost': 300000,
  'status': 'APPROVED',
};
http.Response reply(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> edit(
  WidgetTester tester,
  ApiService api,
  Map<String, dynamic> data,
) async {
  await tester.binding.setSurfaceSize(const Size(360, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ListingManagementScreen(
        mode: ListingFlowMode.edit,
        authorId: 4,
        posts: [RoomPost.fromJson(data)],
        apiService: api,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Lưu & gửi kiểm duyệt'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lưu & gửi kiểm duyệt'));
  await tester.pumpAndSettle();
}

Future<void> home(WidgetTester tester, List<Map<String, dynamic>> posts) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final api = ApiService.withClient(
    MockClient(
      (request) async =>
          reply(request.url.path.endsWith('/posts') ? posts : []),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        initialTab: 1,
        apiService: api,
        currentUser: AuthUser(
          token: 'test-only',
          userId: 4,
          email: 'owner@example.test',
          fullName: 'Owner',
          gender: 'MALE',
          role: 'ROLE_USER',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final area in [null, 0.0, -1.0, double.nan, double.infinity]) {
    test('Unknown or invalid area is never replaced by 28 m²: $area', () {
      final post = RoomPost(
        id: 1,
        title: '',
        description: '',
        price: 1,
        address: '',
        maxOccupants: 2,
        authorName: '',
        authorId: 4,
        areaM2: area,
      );
      expect(post.hasKnownArea, isFalse);
      expect(post.areaLabel, 'Chưa cập nhật diện tích');
    });
  }
  test(
    'Valid area keeps its actual precision rather than rounding to an integer',
    () {
      expect(RoomPost.fromJson(payload(area: 25.5)).areaLabel, '25.5 m²');
      expect(RoomPost.fromJson(payload(area: 28)).areaLabel, '28 m²');
      expect(RoomPost.fromJson(payload(area: 0.25)).areaLabel, '0.25 m²');
    },
  );
  for (final label in ['Chỗ để xe', 'Giữ xe', '  CHỖ   ĐỂ XE  ', ' giữ XE ']) {
    test('Parking compatibility recognizes the exact legacy label: $label', () {
      expect(RoomAmenities.canonical(label), 'Giữ xe');
      expect(RoomAmenities.key(label), RoomAmenities.key('Giữ xe'));
    });
  }
  test(
    'Amenities normalize list and CSV without inventing or dropping unknown amenities',
    () {
      for (final raw in [
        'Chỗ để xe,Giữ xe, Máy giặt,Không có giữ xe',
        ['Chỗ để xe', 'Giữ xe', ' Máy giặt ', 'Không có giữ xe'],
      ]) {
        expect(RoomPost.fromJson({...payload(), 'amenities': raw}).amenities, [
          'Giữ xe',
          'Máy giặt',
          'Không có giữ xe',
        ]);
      }
      expect(
        RoomPost.fromJson({...payload(), 'amenities': null}).amenities,
        isEmpty,
      );
      expect(
        RoomAmenities.key('Không có giữ xe'),
        isNot(RoomAmenities.key('Giữ xe')),
      );
    },
  );
  testWidgets(
    'Legacy edit has a blank area field and can save a real fractional value',
    (tester) async {
      Map<String, dynamic>? submitted;
      var data = payload();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.method == 'PUT') {
            submitted = jsonDecode(request.body) as Map<String, dynamic>;
            data = {...data, ...submitted!, 'status': 'PENDING'};
            return reply(data);
          }
          return reply(request.url.path.endsWith('/posts/my') ? [data] : []);
        }),
      )..setAuthToken('test-only');
      await edit(tester, api, data);
      expect(
        tester.widget<TextField>(field('Diện tích (m²)')).controller!.text,
        isEmpty,
      );
      await tester.ensureVisible(field('Diện tích (m²)'));
      await tester.enterText(field('Diện tích (m²)'), '25,5');
      await save(tester);
      expect(submitted!['area'], 25.5);
      expect(submitted!['amenities'], 'Giữ xe');
      expect(submitted!['price'], 2200000);
      expect(submitted!['deposit'], 1000000);
      expect(submitted!['electricityWaterCost'], 300000);
      expect(submitted!['currentOccupants'], 1);
      expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsOneWidget);
    },
  );
  for (final input in ['', '0', '-1', 'NaN', 'Infinity', 'abc']) {
    testWidgets('Invalid edit area $input blocks PUT and preserves the draft', (
      tester,
    ) async {
      var writes = 0;
      final data = payload();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.method == 'PUT') writes++;
          return reply(request.url.path.endsWith('/posts/my') ? [data] : []);
        }),
      )..setAuthToken('test-only');
      await edit(tester, api, data);
      await tester.ensureVisible(field('Diện tích (m²)'));
      await tester.enterText(field('Diện tích (m²)'), input);
      await save(tester);
      expect(writes, 0);
      expect(
        tester.widget<TextField>(field('Diện tích (m²)')).controller!.text,
        input,
      );
      expect(find.textContaining('diện tích lớn hơn 0'), findsOneWidget);
      expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsNothing);
    });
  }
  testWidgets(
    'Existing area is editable and remains intact after a failed save',
    (tester) async {
      final data = payload(area: 35.75);
      final api = ApiService.withClient(
        MockClient(
          (request) async => request.method == 'PUT'
              ? reply({'message': 'Synthetic save failure'}, 500)
              : reply(request.url.path.endsWith('/posts/my') ? [data] : []),
        ),
      )..setAuthToken('test-only');
      await edit(tester, api, data);
      expect(
        tester.widget<TextField>(field('Diện tích (m²)')).controller!.text,
        '35.75',
      );
      await tester.ensureVisible(field('Diện tích (m²)'));
      await tester.enterText(field('Diện tích (m²)'), '42.25');
      await save(tester);
      expect(
        tester.widget<TextField>(field('Diện tích (m²)')).controller!.text,
        '42.25',
      );
      expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsNothing);
    },
  );
  testWidgets('New listing does not start with a fabricated area', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.create,
          authorId: 4,
        ),
      ),
    );
    expect(
      tester.widget<TextField>(field('Diện tích (m²)')).controller!.text,
      isEmpty,
    );
    expect(find.text('28 m²'), findsNothing);
    await tester.ensureVisible(find.text('Tiếp tục · Ảnh & tiện ích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục · Ảnh & tiện ích'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập diện tích lớn hơn 0.'), findsOneWidget);
    expect(find.text('Ảnh bìa'), findsNothing);
  });
  testWidgets(
    'Feed and detail mark missing area unknown but keep fractional area',
    (tester) async {
      await home(tester, [payload(), payload(id: 2, area: 25.5)]);
      expect(find.textContaining('Chưa cập nhật diện tích'), findsOneWidget);
      expect(find.textContaining('25.5 m²'), findsOneWidget);
      expect(find.textContaining('28 m²'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailsScreen(post: RoomPost.fromJson(payload())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa cập nhật diện tích'), findsOneWidget);
      expect(find.text('28 m²'), findsNothing);
    },
  );
  testWidgets(
    'Parking filter includes both labels and keeps AND semantics with other amenities',
    (tester) async {
      await home(tester, [
        payload(amenities: 'Chỗ để xe,Nội thất'),
        payload(id: 2, amenities: 'Giữ xe'),
        payload(id: 3, amenities: 'Không có giữ xe'),
        payload(id: 4, amenities: ''),
      ]);
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giữ xe'));
      await tester.tap(find.text('Xem phòng phù hợp'));
      await tester.pumpAndSettle();
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsOneWidget);
      expect(find.text('Room 3'), findsNothing);
      expect(find.text('Room 4'), findsNothing);
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Nội thất'));
      await tester.tap(find.text('Xem phòng phù hợp'));
      await tester.pumpAndSettle();
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsNothing);
    },
  );
  testWidgets(
    'Area filter excludes missing or zero metadata instead of using a made-up default',
    (tester) async {
      await home(tester, [
        payload(),
        payload(id: 2, area: 0),
        payload(id: 3, area: 25.5),
      ]);
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả diện tích'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ 25 m²'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem phòng phù hợp'));
      await tester.pumpAndSettle();
      expect(find.text('Room 1'), findsNothing);
      expect(find.text('Room 2'), findsNothing);
      expect(find.text('Room 3'), findsOneWidget);
    },
  );
  testWidgets(
    'Legacy initial parking filter selects the current chip without mutating input',
    (tester) async {
      final selected = {'Chỗ để xe'};
      await tester.pumpWidget(
        MaterialApp(home: RoomFiltersScreen(initialAmenities: selected)),
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Giữ xe'))
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Giữ xe'));
      await tester.pump();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Giữ xe'))
            .selected,
        isFalse,
      );
      expect(selected, {'Chỗ để xe'});
    },
  );
}
