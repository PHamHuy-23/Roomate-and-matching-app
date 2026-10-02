import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/match_request_item.dart';
import 'package:roommate_hub_mobile/models/room_post.dart';
import 'package:roommate_hub_mobile/models/viewing_appointment.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/listing_management_screen.dart';
import 'package:roommate_hub_mobile/screens/login_screen.dart';
import 'package:roommate_hub_mobile/screens/penpot_state_screens.dart';
import 'package:roommate_hub_mobile/screens/room_details_screen.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';
import 'package:roommate_hub_mobile/screens/room_viewing_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

ViewingAppointment appointment({
  int id = 1,
  int requesterId = 10,
  int hostId = 20,
  int roomId = 100,
  String status = 'PENDING',
  DateTime? time,
}) => ViewingAppointment(
  id: id,
  requesterId: requesterId,
  requesterName: 'Người đặt $requesterId',
  hostId: hostId,
  hostName: 'Người đăng $hostId',
  roomPostId: roomId,
  roomTitle: 'Phòng thật $roomId',
  roomAddress: 'Địa chỉ thật $roomId',
  roomPrice: 2500000,
  appointmentTime: time ?? DateTime(2099, 11, 4, 10, 30),
  status: status,
  note: 'Lời nhắn thật',
  createdAt: DateTime(2026, 10, 2),
);
RoomPost room(int id, {int authorId = 20}) => RoomPost(
  id: id,
  title: 'Phòng thật $id',
  description: 'Mô tả thật',
  address: 'Địa chỉ thật $id',
  price: 2500000,
  authorId: authorId,
  authorName: 'Người đăng $authorId',
  maxOccupants: 2,
);

class AppointmentApi implements ApiService {
  List<ViewingAppointment> appointments = [];
  List<RoomPost> posts = [];
  bool failLoad = false,
      failCancel = false,
      failRoom = false,
      failCreate = false;
  String cancelResponseStatus = 'CANCELLED';
  int loadCalls = 0, cancelCalls = 0, createCalls = 0;
  int? cancelledId, openedRoomId;
  DateTime? createdTime;
  String? createdNote;
  Completer<List<ViewingAppointment>>? pendingLoad;
  Completer<ViewingAppointment>? pendingCancel;
  @override
  bool get hasAuthToken => true;
  @override
  Future<List<ViewingAppointment>> getMyAppointments() async {
    loadCalls++;
    if (pendingLoad != null) return pendingLoad!.future;
    if (failLoad) throw const ApiException('Lỗi tải lịch thật');
    return appointments;
  }

  @override
  Future<List<RoomPost>> getMyPosts() async => posts;
  @override
  Future<List<MatchRequestItem>> getReceivedRequests(int userId) async => [];
  @override
  Future<RoomPost> getRoomPost(int id) async {
    openedRoomId = id;
    if (failRoom) {
      throw const ApiException('Tin không còn hiển thị', statusCode: 404);
    }
    return room(id);
  }

  @override
  Future<ViewingAppointment> updateAppointmentStatus(
    int id,
    String status,
  ) async {
    cancelCalls++;
    cancelledId = id;
    expect(status, 'CANCELLED');
    if (pendingCancel != null) return pendingCancel!.future;
    if (failCancel) throw const ApiException('Không thể hủy lịch thật');
    final original = appointments.firstWhere((item) => item.id == id);
    final updated = appointment(
      id: id,
      requesterId: original.requesterId,
      hostId: original.hostId,
      roomId: original.roomPostId,
      status: cancelResponseStatus,
      time: original.appointmentTime,
    );
    if (cancelResponseStatus == 'CANCELLED') {
      appointments = appointments
          .map((item) => item.id == id ? updated : item)
          .toList();
    }
    return updated;
  }

  @override
  Future<ViewingAppointment> createAppointment({
    required int roomPostId,
    required DateTime appointmentTime,
    String? note,
  }) async {
    createCalls++;
    createdTime = appointmentTime;
    createdNote = note;
    if (failCreate) throw const ApiException('Không đặt được lịch thật');
    final created = appointment(
      id: 55,
      roomId: roomPostId,
      time: appointmentTime,
    );
    appointments = [created];
    return created;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget calendar(AppointmentApi api, {int? selectedId}) => MaterialApp(
  home: RoomFlowScreen(
    mode: selectedId == null
        ? RoomFlowMode.viewingSchedule
        : RoomFlowMode.appointmentDetails,
    currentUserId: 10,
    appointmentId: selectedId,
    apiService: api,
  ),
);

void main() {
  testWidgets(
    'route lịch thật lấy tài khoản phiên và được bảo vệ khi chưa đăng nhập',
    (tester) async {
      final api = AppointmentApi();
      final session = AuthSession(apiService: api);
      Widget app() => ChangeNotifierProvider<AuthSession>.value(
        value: session,
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.viewingAppointments,
                  arguments: {'appointmentId': 88, 'currentUserId': 999},
                ),
                child: const Text('Mở lịch'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.tap(find.text('Mở lịch'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RoomFlowScreen), findsNothing);
      Navigator.of(tester.element(find.byType(LoginScreen))).pop();
      await tester.pumpAndSettle();
      session.updateUser(
        AuthUser(
          token: 'test-token',
          userId: 10,
          fullName: 'Tên thử nghiệm',
          email: 'test@example.invalid',
          gender: 'MALE',
          role: 'ROLE_USER',
        ),
      );
      await tester.tap(find.text('Mở lịch'));
      await tester.pumpAndSettle();
      final screen = tester.widget<RoomFlowScreen>(find.byType(RoomFlowScreen));
      expect(screen.currentUserId, 10);
      expect(screen.appointmentId, 88);
      expect(screen.mode, RoomFlowMode.appointmentDetails);
    },
  );

  testWidgets(
    'lịch đã xác nhận nhắn đúng người đăng, người đặt không có nút xác nhận',
    (tester) async {
      final api = AppointmentApi()
        ..appointments = [appointment(status: 'CONFIRMED', hostId: 42)];
      RouteSettings? routed;
      await tester.pumpWidget(
        MaterialApp(
          home: RoomFlowScreen(
            mode: RoomFlowMode.appointmentDetails,
            currentUserId: 10,
            appointmentId: 1,
            apiService: api,
          ),
          onGenerateRoute: (settings) {
            routed = settings;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Chat thật')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận lịch hẹn'), findsNothing);
      await tester.tap(find.text('Nhắn người đăng'));
      await tester.pumpAndSettle();
      expect(routed!.name, AppRoutes.chat);
      expect(routed!.arguments, {
        'partnerId': 42,
        'partnerName': 'Người đăng 42',
      });
    },
  );
  testWidgets('lịch thật chỉ hiển thị lịch đã đặt, có lịch sử và lịch đã hủy', (
    tester,
  ) async {
    final api = AppointmentApi()
      ..appointments = [
        appointment(),
        appointment(id: 2, roomId: 200, status: 'CONFIRMED'),
        appointment(id: 3, requesterId: 30, hostId: 10, roomId: 300),
        appointment(id: 4, requesterId: 30, hostId: 40, roomId: 400),
        appointment(id: 5, roomId: 500, status: 'CANCELLED'),
        appointment(id: 6, roomId: 600, status: 'COMPLETED'),
        appointment(id: 7, roomId: 700, time: DateTime(2020)),
      ];
    await tester.pumpWidget(calendar(api));
    await tester.pumpAndSettle();
    expect(find.text('Phòng thật 100'), findsOneWidget);
    expect(find.text('Phòng thật 200'), findsOneWidget);
    expect(find.text('Phòng thật 300'), findsNothing);
    expect(find.text('Phòng thật 400'), findsNothing);
    expect(find.text('Phòng thật 500'), findsNothing);
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng thật 600'), findsOneWidget);
    expect(find.text('Phòng thật 700'), findsOneWidget);
    await tester.tap(find.text('Đã hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Phòng thật 500'), findsOneWidget);
    expect(find.textContaining('21/09/2026'), findsNothing);
    expect(find.text('Phòng gần HUTECH · Bình Thạnh'), findsNothing);
  });

  testWidgets(
    'mở đúng lịch được chọn, hiển thị ngày giờ ghi chú và phòng thật',
    (tester) async {
      final api = AppointmentApi()
        ..appointments = [appointment(), appointment(id: 2, roomId: 200)];
      await tester.pumpWidget(calendar(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('appointment-2')));
      await tester.pumpAndSettle();
      expect(find.text('Phòng thật 200'), findsOneWidget);
      expect(find.text('Lời nhắn: Lời nhắn thật'), findsOneWidget);
      expect(find.textContaining('04/11/2099 · 10:30'), findsOneWidget);
      expect(find.text('Người đăng: Người đăng 20'), findsOneWidget);
      await tester.tap(find.text('Xem phòng'));
      await tester.pumpAndSettle();
      expect(api.openedRoomId, 200);
      expect(find.byType(RoomDetailsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'hủy gọi đúng ID, chỉ đổi trạng thái sau response và không gửi hai lần',
    (tester) async {
      final api = AppointmentApi()
        ..appointments = [appointment(), appointment(id: 2, roomId: 200)]
        ..pendingCancel = Completer<ViewingAppointment>();
      await tester.pumpWidget(calendar(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('appointment-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy lịch hẹn').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận hủy lịch'));
      await tester.pump();
      expect(api.cancelledId, 2);
      expect(api.cancelCalls, 1);
      expect(find.text('Đã hủy'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Xác nhận hủy lịch'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Xác nhận hủy lịch'));
      await tester.pump();
      expect(api.cancelCalls, 1);
      final cancelled = appointment(id: 2, roomId: 200, status: 'CANCELLED');
      api.appointments = [appointment(), cancelled];
      api.pendingCancel!.complete(cancelled);
      await tester.pumpAndSettle();
      expect(find.text('Đã hủy'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Hủy lịch hẹn'), findsNothing);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng thật 200'), findsOneWidget);
    },
  );

  for (final failedResponse in [false, true]) {
    testWidgets('hủy thất bại không giả thành công ($failedResponse)', (
      tester,
    ) async {
      final api = AppointmentApi()
        ..appointments = [appointment()]
        ..failCancel = !failedResponse
        ..cancelResponseStatus = failedResponse ? 'PENDING' : 'CANCELLED';
      await tester.pumpWidget(calendar(api, selectedId: 1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy lịch hẹn').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận hủy lịch'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn có chắc muốn hủy lịch này?'), findsOneWidget);
      expect(find.text('Đã hủy lịch hẹn'), findsNothing);
      expect(api.appointments.first.status, 'PENDING');
      api.failCancel = false;
      api.cancelResponseStatus = 'CANCELLED';
      await tester.tap(find.text('Xác nhận hủy lịch'));
      await tester.pumpAndSettle();
      expect(find.text('Đã hủy lịch hẹn'), findsOneWidget);
    });
  }

  testWidgets('lỗi tải phân biệt với danh sách trống và có thể thử lại', (
    tester,
  ) async {
    final api = AppointmentApi()..failLoad = true;
    await tester.pumpWidget(calendar(api));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi tải lịch thật'), findsOneWidget);
    expect(find.text('Chưa có lịch hẹn trong mục này.'), findsNothing);
    api.failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có lịch hẹn trong mục này.'), findsOneWidget);
  });

  testWidgets('đang tải không hiển thị lịch mẫu', (tester) async {
    final api = AppointmentApi()
      ..pendingLoad = Completer<List<ViewingAppointment>>();
    await tester.pumpWidget(calendar(api));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Chưa có lịch hẹn trong mục này.'), findsNothing);
    api.pendingLoad!.complete([appointment()]);
    await tester.pumpAndSettle();
    expect(find.text('Phòng thật 100'), findsOneWidget);
  });

  testWidgets('thông báo không được mở lịch của người khác', (tester) async {
    final api = AppointmentApi()
      ..appointments = [appointment(id: 88, requesterId: 30, hostId: 10)];
    await tester.pumpWidget(calendar(api, selectedId: 88));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy lịch hẹn của bạn.'), findsOneWidget);
    expect(find.text('Hủy lịch hẹn'), findsNothing);
    expect(api.cancelCalls, 0);
  });

  for (final status in ['CANCELLED', 'COMPLETED']) {
    testWidgets('lịch $status không có thao tác hủy hoặc chat', (tester) async {
      final api = AppointmentApi()
        ..appointments = [appointment(status: status)];
      await tester.pumpWidget(calendar(api, selectedId: 1));
      await tester.pumpAndSettle();
      expect(find.text('Hủy lịch hẹn'), findsNothing);
      expect(find.text('Nhắn người đăng'), findsNothing);
    });
  }

  testWidgets('phòng đã ẩn báo lỗi, không dựng phòng giả từ lịch', (
    tester,
  ) async {
    final api = AppointmentApi()
      ..appointments = [appointment()]
      ..failRoom = true;
    await tester.pumpWidget(calendar(api, selectedId: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Tin không còn hiển thị'), findsOneWidget);
    expect(find.byType(RoomDetailsScreen), findsNothing);
  });

  testWidgets(
    'đặt lịch thành công mở xác nhận thật rồi danh sách lịch, không mở lại form',
    (tester) async {
      final api = AppointmentApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomViewingScreen(post: room(123), apiService: api),
                  ),
                ),
                child: const Text('Đặt lịch'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Đặt lịch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14:00'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Lời nhắn đang soạn');
      await tester.tap(find.text('Gửi yêu cầu xem phòng'));
      await tester.pumpAndSettle();
      expect(api.createCalls, 1);
      expect(api.createdTime!.hour, 14);
      expect(api.createdNote, 'Lời nhắn đang soạn');
      expect(find.byType(RoomViewingScreen), findsNothing);
      expect(find.byType(RoomFlowScreen), findsOneWidget);
      expect(find.textContaining('Phòng thật 123'), findsOneWidget);
      await tester.tap(find.text('Xem lịch xem phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng thật 123'), findsOneWidget);
      expect(find.byType(RoomViewingScreen), findsNothing);
    },
  );

  testWidgets('đặt lịch lỗi giữ lời nhắn và khung giờ đã chọn', (tester) async {
    final api = AppointmentApi()..failCreate = true;
    await tester.pumpWidget(
      MaterialApp(
        home: RoomViewingScreen(post: room(123), apiService: api),
      ),
    );
    await tester.tap(find.text('14:00'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bản nháp');
    await tester.tap(find.text('Gửi yêu cầu xem phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Không đặt được lịch thật'), findsOneWidget);
    expect(find.byType(RoomViewingScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Bản nháp',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '14:00'))
          .selected,
      isTrue,
    );
  });

  testWidgets('thông báo dùng vai trò và ID thật thay vì suy đoán tiêu đề', (
    tester,
  ) async {
    final api = AppointmentApi()
      ..appointments = [
        appointment(id: 1),
        appointment(id: 2, requesterId: 30, hostId: 10, roomId: 200),
      ];
    final routed = <RouteSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          routed.add(settings);
          return MaterialPageRoute(
            builder: (_) =>
                Scaffold(appBar: AppBar(), body: const Text('Đích điều hướng')),
          );
        },
        home: Builder(
          builder: (context) => NotificationsScreen(
            currentUserId: 10,
            apiService: api,
            onItemTap: (item) => AppRoutes.openNotification(context, item),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch xem phòng: Phòng thật 100'));
    await tester.pumpAndSettle();
    expect(routed.last.name, AppRoutes.viewingAppointments);
    expect(routed.last.arguments, {'appointmentId': 1});
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch xem phòng: Phòng thật 200'));
    await tester.pumpAndSettle();
    expect(routed.last.name, AppRoutes.listingManagement);
    expect(routed.last.arguments, {'roomPostId': 200});
  });

  testWidgets('thông báo chủ phòng mở yêu cầu của đúng tin đăng', (
    tester,
  ) async {
    final api = AppointmentApi()
      ..posts = [room(100, authorId: 10), room(200, authorId: 10)]
      ..appointments = [appointment(requesterId: 30, hostId: 10, roomId: 200)];
    await tester.pumpWidget(
      MaterialApp(
        home: ListingManagementScreen(
          mode: ListingFlowMode.viewingRequest,
          authorId: 10,
          initialPostId: 200,
          apiService: api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Phòng thật 200'), findsOneWidget);
    expect(find.textContaining('Người đặt 30'), findsOneWidget);
    expect(find.text('Xác nhận lịch hẹn'), findsOneWidget);
  });
}
