import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/models/viewing_appointment.dart';
import 'package:roommate_hub_mobile/screens/listing_management_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

RoomPost _post({
  int id = 2,
  String title = 'Tin phòng Bình Thạnh',
  int authorId = 4,
  int maxOccupants = 2,
  int currentOccupants = 0,
}) => RoomPost(
  id: id,
  title: title,
  description: 'Phòng sáng, có nội thất cơ bản.',
  price: 2200000,
  address: 'Bình Thạnh, TP.HCM',
  maxOccupants: maxOccupants,
  currentOccupants: currentOccupants,
  authorName: 'Minh Anh',
  authorId: authorId,
  district: 'Bình Thạnh',
  areaM2: 35,
  deposit: 1000000,
  electricityWaterCost: 300000,
  amenities: ['Wi-Fi'],
  status: 'PENDING',
);

class _MockListingApi implements ApiService {
  _MockListingApi({this.posts = const []});
  List<RoomPost> posts;
  int? updatedId;
  int? closedId;
  Map<String, dynamic>? created;
  @override
  bool get hasAuthToken => true;

  @override
  Future<bool> createRoomPost(Map<String, dynamic> postData) async {
    created = postData;
    return true;
  }

  @override
  Future<List<RoomPost>> getMyPosts() async => posts;
  @override
  Future<List<ViewingAppointment>> getMyAppointments() async => [];
  @override
  Future<bool> closeRoomPost(int postId) async {
    closedId = postId;
    return true;
  }

  @override
  Future<RoomPost> updateRoomPost({
    required int postId,
    required String title,
    required String description,
    required double price,
    required String address,
    required String district,
    required double deposit,
    required String electricityWaterCost,
    required double area,
    required int maxOccupants,
    int? currentOccupants,
    required List<String> amenities,
    String? imageObjectKey,
  }) async {
    updatedId = postId;
    expect(area, 35);
    expect(deposit, 1000000);
    expect(electricityWaterCost, '300.000');
    expect(amenities, ['Wi-Fi']);
    return posts.firstWhere((post) => post.id == postId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final occupants in [2, 3]) {
    testWidgets(
      'editing capacity 2 with $occupants occupants validates before saving',
      (tester) async {
        final api = _MockListingApi(
          posts: [_post(currentOccupants: occupants)],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ListingManagementScreen(
              mode: ListingFlowMode.edit,
              authorId: 4,
              posts: api.posts,
              apiService: api,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Lưu & gửi kiểm duyệt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu & gửi kiểm duyệt'));
        await tester.pumpAndSettle();
        if (occupants > 2) {
          expect(api.updatedId, isNull);
          expect(
            find.textContaining(
              'Số người tối đa không được nhỏ hơn số người đang ở.',
            ),
            findsOneWidget,
          );
        } else {
          expect(api.updatedId, 2);
        }
      },
    );
  }

  testWidgets('Quản lý tin đăng mở được flow xem trước và gửi tin', (
    tester,
  ) async {
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
    final mockApi = _MockListingApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.create,
          authorId: 4,
          posts: <RoomPost>[_post()],
          apiService: mockApi,
        ),
      ),
    );

    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.enterText(field('Tiêu đề bài đăng'), 'Phòng kiểm thử');
    await tester.enterText(field('Địa chỉ / khu vực'), 'Địa chỉ kiểm thử');
    await tester.enterText(field('Quận / huyện'), 'Thủ Đức');
    await tester.enterText(field('Mô tả'), 'Mô tả phòng kiểm thử');
    await tester.ensureVisible(find.text('Tiếp tục · Ảnh & tiện ích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục · Ảnh & tiện ích'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tiếp tục · Giá & nội quy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục · Giá & nội quy'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Tiền thuê / tháng'), '2.000.000');
    await tester.enterText(field('Tiền cọc (đ)'), '1.000.000');
    await tester.enterText(
      field('Tổng điện / nước / phí dịch vụ mỗi tháng (đ)'),
      '200.000',
    );
    await tester.ensureVisible(find.text('Xem trước tin đăng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trước tin đăng'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi tin để duyệt'), findsOneWidget);
    await tester.tap(find.text('Gửi tin để duyệt'));
    await tester.pumpAndSettle();
    expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsOneWidget);
    expect(mockApi.created?['district'], 'Thủ Đức');
    expect(mockApi.created?['deposit'], 1000000);
    expect(mockApi.created?['electricityWaterCost'], 200000);
  });

  testWidgets(
    'Khi thiếu token, gửi tin đăng bị từ chối và hiện thông báo lỗi',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListingManagementScreen(
            mode: ListingFlowMode.preview,
            authorId: 4,
            posts: <RoomPost>[_post()],
          ),
        ),
      );

      await tester.tap(find.text('Gửi tin để duyệt'));
      await tester.pump();
      expect(find.text('Tin của bạn đang chờ kiểm duyệt'), findsNothing);
      expect(find.text('Vui lòng đăng nhập để gửi tin đăng.'), findsOneWidget);
    },
  );

  testWidgets(
    'Chỉnh sửa tin đi qua đủ các bước và mũi tên quay lại từng bước',
    (tester) async {
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
    },
  );

  testWidgets('Sửa và đóng đúng tin thứ hai, giữ thông tin gốc', (
    tester,
  ) async {
    final api = _MockListingApi(
      posts: [
        _post(),
        _post(id: 7, title: 'Tin thứ hai'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.myListings,
          authorId: 4,
          apiService: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final edit = find.text('Chỉnh sửa tin đăng').last;
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('Tin thứ hai'), findsWidgets);
    await tester.ensureVisible(find.text('Lưu & gửi kiểm duyệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu & gửi kiểm duyệt'));
    await tester.pumpAndSettle();
    expect(api.updatedId, 7);
    await tester.tap(find.text('Về tin đăng của tôi'));
    await tester.pumpAndSettle();
    final close = find.text('Đóng tin đăng').last;
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận đóng tin'));
    await tester.pumpAndSettle();
    expect(api.closedId, 7);
  });

  testWidgets(
    'Không hiển thị tin người khác và không tạo lịch hẹn giả khi rỗng',
    (tester) async {
      final api = _MockListingApi(
        posts: [
          _post(),
          _post(id: 8, title: 'Tin người khác', authorId: 9),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ListingManagementScreen(
            mode: ListingFlowMode.myListings,
            authorId: 4,
            apiService: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tin người khác'), findsNothing);
      await tester.tap(find.text('Yêu cầu xem phòng · 0'));
      await tester.pumpAndSettle();
      expect(find.text('Tin này chưa có lịch xem phòng.'), findsOneWidget);
      expect(find.text('Xác nhận lịch hẹn'), findsNothing);
    },
  );
}
