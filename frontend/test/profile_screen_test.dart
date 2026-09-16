import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/models/user_preference.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

class FakeProfileApi implements ApiService {
  Map<String, dynamic>? preferencesData;
  bool shouldFailPreferences = false;
  String? preferencesErrorMessage;
  int getPreferencesCalls = 0;
  Completer<Map<String, dynamic>?>? pendingPreferences;

  bool shouldFailUpdate = false;
  String? updateErrorMessage;
  int updateProfileCalls = 0;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  String? lastUpdatedGender;

  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    getPreferencesCalls++;
    if (pendingPreferences != null) {
      return pendingPreferences!.future;
    }
    if (shouldFailPreferences) {
      throw ApiException(
        preferencesErrorMessage ?? 'Không thể kết nối đến máy chủ',
        statusCode: 500,
      );
    }
    return preferencesData;
  }

  @override
  Future<bool> updateProfile(
    int userId,
    String fullName,
    String phone,
    String gender,
  ) async {
    updateProfileCalls++;
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;
    lastUpdatedGender = gender;
    if (shouldFailUpdate) {
      throw ApiException(
        updateErrorMessage ?? 'Cập nhật thất bại từ máy chủ',
        statusCode: 400,
      );
    }
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
  if (authSession.user == null) {
    authSession.updateUser(user);
  }

  return ChangeNotifierProvider<AuthSession>.value(
    value: authSession,
    child: MaterialApp(
      home: ProfileScreen(
        currentUser: user,
        apiService: api,
      ),
      routes: {
        AppRoutes.login: (_) => const Scaffold(
              body: Center(child: Text('Màn hình Đăng Nhập')),
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
  );

  final samplePreferences = <String, dynamic>{
    'targetDistrict': 'Thu Duc',
    'budgetAmount': 3500000.0,
    'sleepHabit': 1,
    'cleanlinessLevel': 4,
    'isSmoking': false,
    'allowPets': true,
    'bioDescription':
        '[Yêu cầu giới tính: Nam | Ngân sách: 2.000.000 đ - 4.500.000 đ | Nấu ăn: Tự nấu ở nhà | Thú cưng: Thích / Nuôi thú cưng | Tính cách: Hướng nội | Sở thích: Thể thao, Đọc sách, Âm nhạc | Dọn vào: Dọn vào ở ngay | Ưu tiên: Ngân sách phù hợp]\nTìm bạn cùng phòng gọn gàng, tôn trọng không gian riêng.',
  };

  group('AuthUser Model & Regression Tests', () {
    test('8.3.3: AuthUser.fromJson parses real auth payload containing phone and token', () {
      final realJson = {
        'token': 'jwt-real-token',
        'userId': 99,
        'email': 'student@hcmute.edu.vn',
        'fullName': 'Nguyễn Văn Đạt',
        'gender': 'MALE',
        'role': 'ROLE_USER',
        'phone': '0912345678',
        'avatarUrl': 'https://example.com/avatar.png',
      };
      final user = AuthUser.fromJson(realJson);
      expect(user.token, 'jwt-real-token');
      expect(user.userId, 99);
      expect(user.email, 'student@hcmute.edu.vn');
      expect(user.fullName, 'Nguyễn Văn Đạt');
      expect(user.phone, '0912345678');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
    });

    test('8.2: AuthUser.copyWith sentinel semantics (omission retains, explicit null clears)', () {
      final initial = AuthUser(
        token: 'tk',
        userId: 1,
        email: 'e@e.com',
        fullName: 'Name',
        gender: 'MALE',
        role: 'ROLE_USER',
        phone: '0901234567',
        avatarUrl: 'https://avatar.png',
      );

      // Omission retains phone and avatar
      final updatedName = initial.copyWith(fullName: 'New Name');
      expect(updatedName.fullName, 'New Name');
      expect(updatedName.phone, '0901234567');
      expect(updatedName.avatarUrl, 'https://avatar.png');

      // Explicit null clears phone and avatar
      final clearedPhone = initial.copyWith(phone: null, avatarUrl: null);
      expect(clearedPhone.phone, isNull);
      expect(clearedPhone.avatarUrl, isNull);
      expect(clearedPhone.fullName, 'Name');
    });
  });

  group('UserPreference Model & Parsers', () {
    test('Parse full metadata correctly from bioDescription', () {
      final pref = UserPreference.fromJson(samplePreferences);
      expect(pref.districtDisplay, 'TP. Thủ Đức');
      expect(pref.budgetDisplay, contains('2.000.000'));
      expect(pref.budgetDisplay, contains('4.500.000'));
      expect(pref.sleepHabitDisplay, 'Dậy sớm (Early Bird)');
      expect(pref.cleanlinessDisplay, '4★ / 5★');
      expect(pref.smokingDisplay, 'Không hút thuốc');
      expect(pref.petDisplay, 'Thích / Nuôi thú cưng');
      expect(pref.cookingHabit, 'Tự nấu ở nhà');
      expect(pref.personality, 'Hướng nội');
      expect(pref.interests, ['Thể thao', 'Đọc sách', 'Âm nhạc']);
      expect(
        pref.bioNote,
        'Tìm bạn cùng phòng gọn gàng, tôn trọng không gian riêng.',
      );
    });

    test('Fallback gracefully when metadata is missing or partial', () {
      final pref = UserPreference.fromJson({
        'targetDistrict': 'Binh Thanh',
        'budgetAmount': 4000000.0,
        'sleepHabit': 3,
        'cleanlinessLevel': 5,
        'isSmoking': true,
        'allowPets': false,
        'bioDescription': null,
      });

      expect(pref.districtDisplay, 'Bình Thạnh');
      expect(pref.budgetDisplay, contains('4.000.000'));
      expect(pref.sleepHabitDisplay, 'Cú đêm (Night Owl)');
      expect(pref.cleanlinessDisplay, '5★ / 5★');
      expect(pref.smokingDisplay, 'Có hút thuốc');
      expect(pref.petDisplay, 'Không nuôi thú cưng');
      expect(pref.interests, isEmpty);
      expect(pref.bioNote, isNull);
    });
  });

  group('ProfileScreen Widget Tests & P1/P2 Regression', () {
    testWidgets('1. Hiển thị loading khi đang tải preference', (tester) async {
      final api = FakeProfileApi()
        ..pendingPreferences = Completer<Map<String, dynamic>?>();

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pump(); // Start build

      expect(find.text('Đang tải tiêu chí ghép trọ...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Finish pending future
      api.pendingPreferences!.complete(samplePreferences);
      await tester.pumpAndSettle();

      expect(find.text('Đang tải tiêu chí ghép trọ...'), findsNothing);
      expect(find.text('TP. Thủ Đức'), findsOneWidget);
    });

    testWidgets('2. Hiển thị preference dưới dạng chip/card khi API thành công',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Tiêu chí ghép trọ hiện tại'), findsOneWidget);
      expect(find.text('TP. Thủ Đức'), findsOneWidget);
      expect(find.text('Dậy sớm (Early Bird)'), findsOneWidget);
      expect(find.text('4★ / 5★'), findsOneWidget);
      expect(find.text('Không hút thuốc'), findsOneWidget);
      expect(find.text('Thích / Nuôi thú cưng'), findsOneWidget);
      expect(find.text('Thể thao'), findsOneWidget);
      expect(find.text('Đọc sách'), findsOneWidget);
      expect(find.text('Âm nhạc'), findsOneWidget);
      expect(
        find.text(
          'Tìm bạn cùng phòng gọn gàng, tôn trọng không gian riêng.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('3. Empty state khi user chưa có preference', (tester) async {
      final api = FakeProfileApi()..preferencesData = null;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Chưa thiết lập tiêu chí ghép trọ'), findsOneWidget);
      expect(find.text('Làm khảo sát ngay'), findsOneWidget);
    });

    testWidgets('4. Error state và nút thử lại khi API lỗi', (tester) async {
      final api = FakeProfileApi()
        ..shouldFailPreferences = true
        ..preferencesErrorMessage = 'Máy chủ đang bảo trì';

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Máy chủ đang bảo trì'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Sửa lỗi và ấn thử lại
      api.shouldFailPreferences = false;
      api.preferencesData = samplePreferences;

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Máy chủ đang bảo trì'), findsNothing);
      expect(find.text('TP. Thủ Đức'), findsOneWidget);
    });

    testWidgets('5. Validation cập nhật hồ sơ & cập nhật thành công', (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
      final saveButton = find.text('Lưu Thay Đổi');

      // Test 5.1: Xóa tên để trống -> Validate lỗi
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, '');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
      expect(api.updateProfileCalls, 0);

      // Test 5.2: Tên quá ngắn (< 2 ký tự)
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'A');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên phải có ít nhất 2 ký tự'), findsOneWidget);
      expect(api.updateProfileCalls, 0);

      // Test 5.3: Số điện thoại sai định dạng
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Nguyễn Văn Test');
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '12345');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Số điện thoại không hợp lệ (gồm 10 chữ số bắt đầu bằng số 0)',
        ),
        findsOneWidget,
      );
      expect(api.updateProfileCalls, 0);

      // Test 5.4: Dữ liệu hợp lệ -> Cập nhật thành công
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '0987654321');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedName, 'Nguyễn Văn Test');
      expect(api.lastUpdatedPhone, '0987654321');
      expect(find.text('Cập nhật thông tin thành công!'), findsOneWidget);
      expect(find.text('Nguyễn Văn Test'), findsWidgets);
    });

    testWidgets('8.1 (P1): Profile khởi tạo số điện thoại từ AuthUser đăng nhập và chỉ sửa tên không làm mất số điện thoại',
        (tester) async {
      final authPayload = {
        'token': 'jwt-token',
        'userId': 10,
        'email': 'sinhvien@hcmute.edu.vn',
        'fullName': 'Phạm Quốc Huy',
        'gender': 'MALE',
        'role': 'ROLE_USER',
        'phone': '0901234567',
      };
      final userFromLogin = AuthUser.fromJson(authPayload);
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      final session = AuthSession(apiService: api);
      session.updateUser(userFromLogin);

      await tester.pumpWidget(
        createProfileTestApp(
          user: userFromLogin,
          api: api,
          session: session,
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      final saveButton = find.text('Lưu Thay Đổi');

      // Người dùng chỉ sửa họ tên, không chạm vào ô điện thoại
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Phạm Quốc Huy Đã Sửa');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedName, 'Phạm Quốc Huy Đã Sửa');
      expect(api.lastUpdatedPhone, '0901234567'); // Số điện thoại cũ vẫn giữ nguyên trong request
      expect(session.user!.phone, '0901234567');
      expect(session.user!.fullName, 'Phạm Quốc Huy Đã Sửa');
    });

    testWidgets('8.2 (P2): Xoá số điện thoại rồi lưu: request gửi chuỗi rỗng và AuthSession.user.phone phản ánh giá trị null',
        (tester) async {
      final authPayload = {
        'token': 'jwt-token',
        'userId': 10,
        'email': 'sinhvien@hcmute.edu.vn',
        'fullName': 'Phạm Quốc Huy',
        'gender': 'MALE',
        'role': 'ROLE_USER',
        'phone': '0901234567',
      };
      final userFromLogin = AuthUser.fromJson(authPayload);
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      final session = AuthSession(apiService: api);
      session.updateUser(userFromLogin);

      await tester.pumpWidget(
        createProfileTestApp(
          user: userFromLogin,
          api: api,
          session: session,
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
      final saveButton = find.text('Lưu Thay Đổi');

      // Người dùng chủ động xoá số điện thoại
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(api.updateProfileCalls, 1);
      expect(api.lastUpdatedPhone, ''); // Gửi chuỗi rỗng lên backend
      expect(session.user!.phone, isNull); // Session được cập nhật null, không giữ số cũ
    });

    testWidgets('6. Điều hướng sang Survey và refresh khi quay lại',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(api.getPreferencesCalls, 1);

      // Bấm nút cập nhật trên header tiêu chí
      final updateButton = find.widgetWithText(OutlinedButton, 'Cập nhật');
      expect(updateButton, findsOneWidget);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Kiểm tra đã điều hướng sang SurveyScreen
      expect(find.byType(SurveyScreen), findsOneWidget);

      // Quay lại từ Survey (bấm AppBar BackButton)
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // ProfileScreen phải hiển thị lại và đã refresh tiêu chí
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(api.getPreferencesCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('7. Logout mở dialog xác nhận, xóa session và quay về Login',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;
      final session = AuthSession(apiService: api);
      session.updateUser(sampleUser);

      await tester.pumpWidget(
        createProfileTestApp(
          user: sampleUser,
          api: api,
          session: session,
        ),
      );
      await tester.pumpAndSettle();

      // Cuộn xuống để thấy nút Đăng xuất
      await tester.ensureVisible(find.text('Đăng Xuất'));
      await tester.tap(find.text('Đăng Xuất'));
      await tester.pumpAndSettle();

      // Xác nhận dialog xuất hiện
      expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
      expect(
        find.text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        findsOneWidget,
      );

      // Nhấn Xác nhận Đăng xuất trong Dialog
      final confirmLogout = find.widgetWithText(ElevatedButton, 'Đăng xuất');
      await tester.tap(confirmLogout);
      await tester.pumpAndSettle();

      // Xác thực session đã bị xóa và đã điều hướng về Login
      expect(session.user, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(find.text('Màn hình Đăng Nhập'), findsOneWidget);
    });

    testWidgets('8. Không hard-code badge xác thực khi không có dữ liệu',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      expect(find.text('Đã xác thực thẻ sinh viên'), findsNothing);
      expect(find.text('Student Verified'), findsNothing);
    });

    testWidgets('9. Đổi mật khẩu mở Dialog giải thích trạng thái API',
        (tester) async {
      final api = FakeProfileApi()..preferencesData = samplePreferences;

      await tester.pumpWidget(createProfileTestApp(user: sampleUser, api: api));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Đổi Mật Khẩu'));
      await tester.tap(find.text('Đổi Mật Khẩu'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tính năng đổi mật khẩu đang được phát triển ở phiên bản tiếp theo (Giai đoạn Backend Security Milestone 4).',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Tính năng đổi mật khẩu đang được phát triển ở phiên bản tiếp theo (Giai đoạn Backend Security Milestone 4).',
        ),
        findsNothing,
      );
    });
  });
}
