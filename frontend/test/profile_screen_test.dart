import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/user_preference.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/edit_profile_screen.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';
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
    DateTime birthDate,
    String university,
  ) async {
    updateProfileCalls++;
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;
    lastUpdatedGender = gender;
    lastUpdatedBirthDate = birthDate;
    lastUpdatedUniversity = university;
    return true;
  }

  @override
  void clearAuthToken() {}

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
        AppRoutes.login: (_) => const Scaffold(
              body: Center(child: Text('Màn hình Đăng Nhập')),
            ),
        AppRoutes.editProfile: (_) => EditProfileScreen(
              currentUser: user,
              apiService: api,
            ),
        AppRoutes.survey: (_) => SurveyScreen(
              userId: user.userId,
              apiService: api,
            ),
        AppRoutes.settings: (_) => const SettingsScreen(),
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
      expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsOneWidget);
    });

    testWidgets('nút chỉnh sửa mở EditProfileScreen và lưu thông tin',
        (tester) async {
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
      await tester.enterText(fields.at(0), 'Nguyễn Văn Test');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedName, 'Nguyễn Văn Test');
      expect(api.lastUpdatedPhone, '0901234567');
      expect(api.lastUpdatedBirthDate, DateTime(2002, 5, 20));
      expect(api.lastUpdatedUniversity, 'Đại học Sư phạm Kỹ thuật TP.HCM');
      expect(session.user!.fullName, 'Nguyễn Văn Test');
      expect(find.byType(ProfileScreen), findsOneWidget);
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

    testWidgets('không hard-code badge xác thực khi không có dữ liệu',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Đã xác thực thẻ sinh viên'), findsNothing);
      expect(find.text('Student Verified'), findsNothing);
    });
  });
}
