import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/user_preference.dart';
import 'package:roommate_hub_mobile/models/viewing_appointment.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/edit_profile_screen.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';
import 'package:roommate_hub_mobile/screens/room_flow_screen.dart';
import 'package:roommate_hub_mobile/screens/settings_screen.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

class FakeProfileApi implements ApiService {
  Map<String, dynamic>? preferencesData;
  bool shouldFailPreferences = false;
  int getPreferencesCalls = 0;
  Completer<Map<String, dynamic>?>? pendingPreferences;

  int updateProfileCalls = 0;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  String? lastUpdatedGender;
  DateTime? lastUpdatedBirthDate;
  String? lastUpdatedUniversity;
  String? lastUpdatedBio;
  bool shouldFailUpdate = false;

  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    getPreferencesCalls++;
    if (pendingPreferences != null) return pendingPreferences!.future;
    if (shouldFailPreferences) {
      throw ApiException('Không thể kết nối đến máy chủ', statusCode: 500);
    }
    return preferencesData;
  }

  @override
  Future<bool> updateProfile(
    int userId,
    String fullName,
    String phone,
    String gender,
    DateTime? birthDate,
    String? university, {
    String? bioNote,
  }) async {
    updateProfileCalls++;
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;
    lastUpdatedGender = gender;
    lastUpdatedBirthDate = birthDate;
    lastUpdatedUniversity = university;
    lastUpdatedBio = bioNote;
    if (shouldFailUpdate) return false;
    if (bioNote != null && preferencesData != null) {
      final raw = preferencesData!['bioDescription'] as String? ?? '';
      final metadata = RegExp(
        r'^\[(.*?)\](?:\n(.*))?$',
        dotAll: true,
      ).firstMatch(raw);
      preferencesData = {
        ...preferencesData!,
        'bioDescription': metadata == null
            ? bioNote
            : '[${metadata.group(1)}]${bioNote.isEmpty ? '' : '\n$bioNote'}',
      };
    }
    return true;
  }

  @override
  void clearAuthToken() {}

  @override
  Future<List<ViewingAppointment>> getMyAppointments() async => [];

  @override
  bool get hasAuthToken => true;

  @override
  String? get authToken => 'fake-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createProfileTestApp({
  required AuthUser user,
  required FakeProfileApi api,
  AuthSession? session,
}) {
  final authSession = session ?? AuthSession(apiService: api);
  if (authSession.user == null) authSession.updateUser(user);

  return ChangeNotifierProvider<AuthSession>.value(
    value: authSession,
    child: MaterialApp(
      home: ProfileScreen(currentUser: user, apiService: api),
      routes: {
        AppRoutes.login: (_) =>
            const Scaffold(body: Center(child: Text('Màn hình Đăng Nhập'))),
        AppRoutes.editProfile: (_) => EditProfileScreen(
          currentUser: authSession.user ?? user,
          apiService: api,
        ),
        AppRoutes.survey: (_) =>
            SurveyScreen(userId: user.userId, apiService: api),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.viewingAppointments: (_) => RoomFlowScreen(
          mode: RoomFlowMode.viewingSchedule,
          currentUserId: user.userId,
          apiService: api,
        ),
      },
    ),
  );
}

void main() {
  final sampleUser = AuthUser(
    token: 'jwt-mock-token',
    userId: 10,
    email: 'sinhvien@hcmute.edu.vn',
    fullName: 'Phạm Quốc Huy',
    gender: 'MALE',
    role: 'ROLE_USER',
    phone: '0901234567',
    birthDate: DateTime(2002, 5, 20),
    university: 'Đại học Sư phạm Kỹ thuật TP.HCM',
  );

  final samplePreferences = <String, dynamic>{
    'targetDistrict': 'Thu Duc',
    'budgetAmount': 3500000.0,
    'sleepHabit': 1,
    'cleanlinessLevel': 4,
    'isSmoking': false,
    'allowPets': true,
    'bioDescription':
        '[Yêu cầu giới tính: Nam | Ngân sách: 2.000.000 đ - 4.500.000 đ | Nấu ăn: Tự nấu ở nhà | Thú cưng: Thích / Nuôi thú cưng | Tính cách: Hướng nội | Sở thích: Thể thao, Đọc sách, Âm nhạc | Dọn vào: Dọn vào ở ngay | Ưu tiên: Ngân sách phù hợp]\n'
        'Tìm bạn cùng phòng gọn gàng, tôn trọng không gian riêng.',
  };

  test('AuthUser parses profile fields from auth payload', () {
    final user = AuthUser.fromJson({
      'token': 'jwt-real-token',
      'userId': 99,
      'email': 'student@hcmute.edu.vn',
      'fullName': 'Nguyễn Văn Đạt',
      'gender': 'MALE',
      'role': 'ROLE_USER',
      'phone': '0912345678',
      'birthDate': '2002-05-20',
      'university': 'Đại học Sư phạm Kỹ thuật TP.HCM',
    });

    expect(user.token, 'jwt-real-token');
    expect(user.phone, '0912345678');
    expect(user.birthDate, DateTime(2002, 5, 20));
    expect(user.university, 'Đại học Sư phạm Kỹ thuật TP.HCM');
  });

  test('UserPreference parses Penpot summary metadata', () {
    final preference = UserPreference.fromJson(samplePreferences);

    expect(preference.districtDisplay, 'TP. Thủ Đức');
    expect(preference.budgetDisplay, contains('2.000.000'));
    expect(preference.sleepHabitDisplay, 'Dậy sớm (Early Bird)');
    expect(preference.cleanlinessDisplay, '4★ / 5★');
    expect(preference.smokingDisplay, 'Không hút thuốc');
    expect(preference.bioNote, contains('Tìm bạn cùng phòng'));
  });

  group('ProfileScreen và luồng hồ sơ theo Penpot', () {
    testWidgets('hiển thị trạng thái tải tiêu chí', (tester) async {
      final api = FakeProfileApi()
        ..pendingPreferences = Completer<Map<String, dynamic>?>();

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pump();

      expect(find.text('Đang tải...'), findsOneWidget);

      api.pendingPreferences!.complete(samplePreferences);
      await tester.pumpAndSettle();

      expect(find.textContaining('TP. Thủ Đức'), findsOneWidget);
    });

    testWidgets('hiển thị tóm tắt tiêu chí khi API thành công', (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu chí của tôi'), findsOneWidget);
      expect(find.textContaining('2.000.000'), findsOneWidget);
      expect(find.textContaining('TP. Thủ Đức'), findsOneWidget);
      expect(find.textContaining('Không hút thuốc'), findsOneWidget);
    });

    testWidgets('hiển thị empty state khi chưa có tiêu chí', (tester) async {
      final api = FakeProfileApi();

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsOneWidget);
    });

    testWidgets('API lỗi không làm hỏng màn hồ sơ', (tester) async {
      final api = FakeProfileApi()..shouldFailPreferences = true;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu chí của tôi'), findsOneWidget);
      expect(
        find.text('Không tải được tiêu chí. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsNothing);
    });

    testWidgets('nút chỉnh sửa mở EditProfileScreen và lưu thông tin', (
      tester,
    ) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      final session = AuthSession(apiService: api);
      session.updateUser(sampleUser);

      await tester.pumpWidget(
        createProfileTestApp(user: sampleUser, api: api, session: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
      expect(find.text('Trường học / nghề nghiệp'), findsOneWidget);
      expect(find.text('Giới thiệu bản thân'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      expect(
        tester.widget<TextField>(fields.at(2)).controller!.text,
        'Tìm bạn cùng phòng gọn gàng, tôn trọng không gian riêng.',
      );
      await tester.enterText(fields.at(0), 'Nguyễn Văn Test');
      await tester.enterText(fields.at(2), 'Giới thiệu mới');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedName, 'Nguyễn Văn Test');
      expect(api.lastUpdatedPhone, '0901234567');
      expect(api.lastUpdatedBirthDate, DateTime(2002, 5, 20));
      expect(api.lastUpdatedUniversity, 'Đại học Sư phạm Kỹ thuật TP.HCM');
      expect(api.lastUpdatedBio, 'Giới thiệu mới');
      expect(session.user!.fullName, 'Nguyễn Văn Test');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Nguyễn Văn Test'), findsOneWidget);
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
        'Giới thiệu mới',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Nguyễn Văn Test',
      );
    });

    testWidgets('ngày sinh trống không bị thay bằng ngày giả', (tester) async {
      final user = sampleUser.copyWith(birthDate: null, university: null);
      final api = FakeProfileApi();
      final session = AuthSession(apiService: api)..updateUser(user);
      await tester.pumpWidget(
        createProfileTestApp(user: user, api: api, session: session),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(
        find.text('Hãy thiết lập tiêu chí ghép trọ trước khi thêm giới thiệu.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('Giới thiệu bản thân')),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedBirthDate, isNull);
      expect(api.lastUpdatedBio, isNull);
      expect(api.lastUpdatedUniversity, isNull);
      expect(session.user!.birthDate, isNull);
      expect(session.user!.university, isNull);
    });

    testWidgets('lỗi tải giới thiệu chặn lưu và cho thử lại', (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();
      api.shouldFailPreferences = true;
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
            )
            .onPressed,
        isNull,
      );
      expect(api.updateProfileCalls, 0);
      api.shouldFailPreferences = false;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('Giới thiệu bản thân')),
            )
            .controller!
            .text,
        contains('Tìm bạn cùng phòng'),
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('lưu thất bại giữ bản nháp và phiên cũ', (tester) async {
      final api = FakeProfileApi()
        ..preferencesData = samplePreferences
        ..shouldFailUpdate = true;
      final session = AuthSession(apiService: api)..updateUser(sampleUser);
      await tester.pumpWidget(
        createProfileTestApp(user: sampleUser, api: api, session: session),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Bản nháp');
      await tester.enterText(
        find.byKey(const ValueKey('Giới thiệu bản thân')),
        'Giới thiệu đang sửa',
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Không thể cập nhật hồ sơ'), findsOneWidget);
      expect(session.user!.fullName, sampleUser.fullName);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('Giới thiệu bản thân')),
            )
            .controller!
            .text,
        'Giới thiệu đang sửa',
      );
    });

    testWidgets('đang tải giới thiệu không cho lưu hoặc sửa nội dung trống', (
      tester,
    ) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();
      api.pendingPreferences = Completer<Map<String, dynamic>?>();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Đang tải giới thiệu...'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('Giới thiệu bản thân')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
            )
            .onPressed,
        isNull,
      );
      expect(api.updateProfileCalls, 0);
      api.pendingPreferences!.complete(samplePreferences);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'xóa giới thiệu gửi chuỗi trống và không lộ metadata khi mở lại',
      (tester) async {
        final api = FakeProfileApi()..preferencesData = samplePreferences;
        await tester.pumpWidget(
          createProfileTestApp(user: sampleUser, api: api),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chỉnh sửa'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('Giới thiệu bản thân')),
          '',
        );
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle();
        expect(api.lastUpdatedBio, '');
        final preference = UserPreference.fromJson(api.preferencesData!);
        expect(preference.interests, contains('Đọc sách'));
        await tester.tap(find.text('Chỉnh sửa'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('Giới thiệu bản thân')),
              )
              .controller!
              .text,
          '',
        );
      },
    );

    testWidgets('Lịch xem phòng mở lịch đã đặt, không còn số lịch giả', (
      tester,
    ) async {
      final api = FakeProfileApi();
      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();
      expect(find.text('1 lịch đang chờ xác nhận'), findsNothing);
      await tester.tap(find.text('Lịch xem phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomFlowScreen), findsOneWidget);
      expect(
        tester
            .widget<RoomFlowScreen>(find.byType(RoomFlowScreen))
            .currentUserId,
        sampleUser.userId,
      );
    });

    testWidgets('Tiêu chí của tôi mở màn khảo sát', (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(api.getPreferencesCalls, 1);
      await tester.tap(find.text('Tiêu chí của tôi'));
      await tester.pumpAndSettle();

      expect(find.byType(SurveyScreen), findsOneWidget);
    });

    testWidgets('Cài đặt mở được và đăng xuất xóa phiên', (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      final session = AuthSession(apiService: api);
      session.updateUser(sampleUser);

      await tester.pumpWidget(
        createProfileTestApp(user: sampleUser, api: api, session: session),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      final settingsTile = find.text('Cài đặt & quyền riêng tư');
      await tester.tap(settingsTile);
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản & sự riêng tư'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      final logoutButton = find.widgetWithText(ElevatedButton, 'Đăng xuất');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(session.user, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(find.text('Màn hình Đăng Nhập'), findsOneWidget);
    });

    testWidgets('không hard-code badge xác thực khi không có dữ liệu', (
      tester,
    ) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Đã xác thực thẻ sinh viên'), findsNothing);
      expect(find.text('Student Verified'), findsNothing);
    });
  });
}
