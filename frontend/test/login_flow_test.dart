import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/login_screen.dart';
import 'package:roommate_hub_mobile/screens/survey_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

class _LoginApi implements ApiService {
  _LoginApi();

  Map<String, dynamic>? preferences;
  String? _token;

  final _user = AuthUser(
    token: 'test-token',
    userId: 42,
    email: 'huy@example.com',
    fullName: 'Huy',
    gender: 'MALE',
    role: 'ROLE_USER',
  );

  @override
  Future<AuthUser> login(String email, String password) async {
    _token = _user.token;
    return _user;
  }

  @override
  Future<Map<String, dynamic>?> getPreferences(int userId) async {
    return preferences;
  }

  @override
  String? get authToken => _token;

  @override
  bool get hasAuthToken => _token != null;

  @override
  void setAuthToken(String token) => _token = token;

  @override
  void clearAuthToken() => _token = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _loginApp(_LoginApi api) {
  final session = AuthSession(apiService: api);
  return ChangeNotifierProvider<AuthSession>.value(
    value: session,
    child: MaterialApp(
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.survey:
            return MaterialPageRoute<void>(
              builder: (_) => SurveyScreen(
                userId: 42,
                apiService: api,
                redirectToHomeOnComplete: true,
              ),
            );
          case AppRoutes.home:
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Discovery')),
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Unknown route')),
            );
        }
      },
    ),
  );
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'huy@example.com',
  );
  await tester.enterText(find.byKey(const Key('password_field')), 'password');
  await tester.tap(find.text('Đăng nhập'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Đăng nhập user chưa có tiêu chí sẽ mở khảo sát', (tester) async {
    final api = _LoginApi();
    await tester.pumpWidget(_loginApp(api));

    await _fillAndSubmit(tester);

    expect(find.text('Bạn muốn ở đâu?'), findsOneWidget);
    expect(find.text('1 / 5 · Ngân sách & khu vực'), findsOneWidget);
  });

  testWidgets('Đăng nhập user đã có tiêu chí sẽ mở Discovery', (tester) async {
    final api = _LoginApi()..preferences = {'targetDistrict': 'Binh Thanh'};
    await tester.pumpWidget(_loginApp(api));

    await _fillAndSubmit(tester);

    expect(find.text('Discovery'), findsOneWidget);
  });
}
