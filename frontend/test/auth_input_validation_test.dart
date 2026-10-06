import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/screens/auth_support_screen.dart';
import 'package:roommate_hub_mobile/screens/login_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';
import 'package:roommate_hub_mobile/validation/auth_validation.dart';

String repeated(String value, int count) => List.filled(count, value).join();

void main() {
  tearDown(() => ApiService.configureUnauthorizedHandler(() {}));

  for (final password in [
    '',
    '        ',
    '1234567',
    repeated('a', 73),
    repeated('ắ', 25),
    repeated('😀', 19),
  ]) {
    test('New password rejects invalid length/blank: ${password.length}', () {
      expect(AuthValidation.newPasswordError(password), isNotNull);
    });
  }
  for (final password in [
    '12345678',
    repeated('a', 72),
    repeated('ắ', 24),
    ' 123456 ',
  ]) {
    test(
      'New password accepts boundary, preserves spaces: ${password.length}',
      () {
        expect(AuthValidation.newPasswordError(password), isNull);
      },
    );
  }

  final fieldCases = <String, (String, String)>{
    'email': (
      '${repeated('a', 60)}@${repeated('b', 36)}.com',
      'Email không được vượt quá 100 ký tự',
    ),
    'fullName': (repeated('N', 101), 'Họ tên không được vượt quá 100 ký tự'),
    'phone': (repeated('0', 21), 'Số điện thoại không được vượt quá 20 ký tự'),
    'university': (
      repeated('U', 151),
      'Tên trường không được vượt quá 150 ký tự',
    ),
    'gender': ('INVALID', 'Giới tính phải là MALE, FEMALE hoặc OTHER'),
  };
  for (final entry in fieldCases.entries) {
    test('Registration validates ${entry.key} before API', () {
      expect(
        AuthValidation.registrationFieldsError(
          email: entry.key == 'email' ? entry.value.$1 : 'user@example.com',
          fullName: entry.key == 'fullName' ? entry.value.$1 : 'Test user',
          phone: entry.key == 'phone' ? entry.value.$1 : '',
          university: entry.key == 'university' ? entry.value.$1 : 'University',
          gender: entry.key == 'gender' ? entry.value.$1 : 'MALE',
        ),
        entry.value.$2,
      );
    });
  }
  test(
    'Registration allows exact storage boundaries and supported genders',
    () {
      for (final gender in ['MALE', 'FEMALE', 'OTHER', 'other']) {
        expect(
          AuthValidation.registrationFieldsError(
            email: '${repeated('a', 60)}@${repeated('b', 35)}.com',
            fullName: repeated('N', 100),
            phone: repeated('0', 20),
            university: repeated('U', 150),
            gender: gender,
          ),
          isNull,
        );
      }
    },
  );

  for (final entry in fieldCases.entries.where((e) => e.key != 'gender')) {
    testWidgets('Registration screen blocks oversized ${entry.key}', (
      tester,
    ) async {
      await largeSurface(tester);
      var requests = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          requests++;
          return http.Response('{}', 500);
        }),
      );
      final session = AuthSession(apiService: api);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: const MaterialApp(home: LoginScreen(initialRegister: true)),
        ),
      );
      await fillRegistration(tester);
      final key = switch (entry.key) {
        'email' => 'email_field',
        'fullName' => 'register_name_field',
        'phone' => 'register_phone_field',
        _ => 'register_university_field',
      };
      await tester.enterText(find.byKey(Key(key)), entry.value.$1);
      await submitRegistration(tester);
      expect(find.text(entry.value.$2), findsOneWidget);
      expect(requests, 0);
    });
  }

  final invalidPasswords = <(String, String)>[
    ('1234567', 'Mật khẩu phải có ít nhất 8 ký tự'),
    ('        ', 'Mật khẩu không được để trống'),
    (repeated('ắ', 25), 'Mật khẩu không được vượt quá 72 byte UTF-8'),
  ];
  for (final invalid in invalidPasswords) {
    testWidgets(
      'Registration screen uses shared password policy: ${invalid.$1.length}',
      (tester) async {
        await largeSurface(tester);
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen(initialRegister: true)),
        );
        await fillRegistration(tester);
        await tester.enterText(
          find.byKey(const Key('password_field')),
          invalid.$1,
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')),
          invalid.$1,
        );
        await submitRegistration(tester);
        expect(find.text(invalid.$2), findsOneWidget);
      },
    );

    for (final mode in [
      AuthSupportMode.changePassword,
      AuthSupportMode.newPassword,
    ]) {
      testWidgets(
        '$mode rejects password before calling API: ${invalid.$1.length}',
        (tester) async {
          await largeSurface(tester);
          await tester.pumpWidget(
            MaterialApp(
              home: AuthSupportScreen(mode: mode, email: 'user@example.com'),
            ),
          );
          if (mode == AuthSupportMode.changePassword) {
            // Legacy current password is not subject to the new-password minimum.
            await tester.enterText(
              find.byKey(const Key('current_password_field')),
              '123456',
            );
          } else {
            final codeFields = find
                .byType(TextField)
                .evaluate()
                .where((e) => (e.widget as TextField).maxLength == 1)
                .toList();
            for (final field in codeFields) {
              await tester.enterText(find.byWidget(field.widget), '1');
            }
          }
          final isChange = mode == AuthSupportMode.changePassword;
          await tester.enterText(
            find.byKey(
              Key(isChange ? 'change_password_field' : 'new_password_field'),
            ),
            invalid.$1,
          );
          await tester.enterText(
            find.byKey(
              Key(
                isChange
                    ? 'change_password_confirm_field'
                    : 'new_password_confirm_field',
              ),
            ),
            invalid.$1,
          );
          await tester.tap(
            find.text(isChange ? 'Lưu mật khẩu' : 'Lưu mật khẩu & đăng nhập'),
          );
          await tester.pumpAndSettle();
          expect(find.text(invalid.$2), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Eight-character registration password advances to date validation',
    (tester) async {
      await largeSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen(initialRegister: true)),
      );
      await fillRegistration(tester);
      await submitRegistration(tester);
      expect(find.text('Vui lòng chọn ngày sinh'), findsOneWidget);
      expect(find.text('Mật khẩu phải có ít nhất 8 ký tự'), findsNothing);
    },
  );

  for (final password in ['123456', ' 123456 ']) {
    testWidgets('Login keeps existing password unchanged: ${password.length}', (
      tester,
    ) async {
      await largeSurface(tester);
      String? receivedPassword;
      var requests = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          requests++;
          receivedPassword =
              (jsonDecode(request.body) as Map)['password'] as String;
          return http.Response(
            jsonEncode({'message': 'Test login rejected'}),
            401,
          );
        }),
      );
      final session = AuthSession(apiService: api);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );
      await tester.enterText(find.byKey(const Key('password_field')), password);
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(receivedPassword, password);
      expect(requests, 1);
      expect(find.text('Test login rejected'), findsOneWidget);
    });
  }

  test(
    'API exposes field validation messages without rejected password values',
    () async {
      final api = ApiService.withClient(
        MockClient(
          (request) async => http.Response(
            jsonEncode({
              'message': 'Dữ liệu không hợp lệ',
              'fields': {
                'password': 'Mật khẩu không được vượt quá 72 byte UTF-8',
                'fullName': 'Họ tên không được vượt quá 100 ký tự',
              },
            }),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await expectLater(
        api.register(
          'user@example.com',
          repeated('a', 73),
          'Name',
          'MALE',
          '',
          DateTime(2000),
          'University',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'HTTP', 400)
              .having(
                (e) => e.message,
                'field message',
                contains('72 byte UTF-8'),
              )
              .having((e) => e.message, 'other field', contains('Họ tên'))
              .having(
                (e) => e.message,
                'no rejected password',
                isNot(contains(repeated('a', 73))),
              ),
        ),
      );
    },
  );
}

Future<void> largeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(600, 1500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> fillRegistration(WidgetTester tester) async {
  for (final field in {
    'email_field': 'user@example.com',
    'password_field': '12345678',
    'register_confirm_password_field': '12345678',
    'register_name_field': 'Test user',
    'register_phone_field': '0901234567',
    'register_university_field': 'University',
  }.entries) {
    await tester.ensureVisible(find.byKey(Key(field.key)));
    await tester.enterText(find.byKey(Key(field.key)), field.value);
  }
}

Future<void> submitRegistration(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Tạo tài khoản');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
