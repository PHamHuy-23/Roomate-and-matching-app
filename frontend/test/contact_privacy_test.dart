import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/screens/contact_details_screen.dart';
import 'package:roommate_hub_mobile/screens/privacy_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

void main() {
  group('ApiService Contact Privacy Methods (FR-45)', () {
    test('getContactPrivacySettings parses backend map', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/profile/contact-privacy');
        return http.Response(
          jsonEncode({
            'sharePhone': true,
            'shareEmail': false,
            'shareZalo': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiService.withClient(client)
        ..setTokens(accessToken: 'mock-token', refreshToken: 'mock-refresh');

      final settings = await api.getContactPrivacySettings();
      expect(settings['sharePhone'], isTrue);
      expect(settings['shareEmail'], isFalse);
      expect(settings['shareZalo'], isTrue);
    });

    test('updateContactPrivacySettings sends PUT and parses response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/profile/contact-privacy');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['sharePhone'], isFalse);
        expect(body['shareEmail'], isTrue);
        return http.Response(
          jsonEncode({
            'sharePhone': false,
            'shareEmail': true,
            'shareZalo': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiService.withClient(client)
        ..setTokens(accessToken: 'mock-token', refreshToken: 'mock-refresh');

      final result = await api.updateContactPrivacySettings(
        sharePhone: false,
        shareEmail: true,
      );
      expect(result['sharePhone'], isFalse);
      expect(result['shareEmail'], isTrue);
      expect(result['shareZalo'], isTrue);
    });
  });

  group('PrivacyScreen UI & Sync (FR-45)', () {
    final testUser = AuthUser(
      token: 'tok',
      refreshToken: 'ref',
      userId: 1,
      email: 'user@test.vn',
      fullName: 'Test User',
      gender: 'MALE',
      role: 'ROLE_USER',
    );

    testWidgets('Renders contact privacy section and switches with subtitles', (
      tester,
    ) async {
      final client = MockClient((request) async {
        if (request.url.path.contains('search-status')) {
          return http.Response(jsonEncode({'searchActive': true}), 200);
        }
        if (request.url.path.contains('contact-privacy')) {
          return http.Response(
            jsonEncode({
              'sharePhone': true,
              'shareEmail': true,
              'shareZalo': true,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      final api = ApiService.withClient(client)
        ..setTokens(accessToken: 'tok', refreshToken: 'ref');
      final session = AuthSession(apiService: api)..updateUser(testUser);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(home: PrivacyScreen(apiService: api)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Chia sẻ thông tin liên lạc sau khi ghép đôi thành công'),
        findsOneWidget,
      );
      expect(find.text('Chia sẻ Số điện thoại'), findsOneWidget);
      expect(
        find.text('Đối phương có thể gọi điện trực tiếp sau khi match'),
        findsOneWidget,
      );
      expect(find.text('Chia sẻ Email'), findsOneWidget);
      expect(
        find.text('Đối phương có thể gửi thư trao đổi sau khi match'),
        findsOneWidget,
      );
      expect(find.text('Chia sẻ Zalo'), findsOneWidget);
      expect(
        find.text('Cho phép tìm kiếm và kết bạn Zalo qua số điện thoại'),
        findsOneWidget,
      );
    });

    testWidgets('Toggling contact privacy switch immediately syncs with backend', (
      tester,
    ) async {
      var privacyUpdateSent = false;
      final client = MockClient((request) async {
        if (request.url.path.contains('search-status')) {
          return http.Response(jsonEncode({'searchActive': true}), 200);
        }
        if (request.url.path.contains('contact-privacy')) {
          if (request.method == 'PUT') {
            privacyUpdateSent = true;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'sharePhone': body['sharePhone'] ?? true,
                'shareEmail': body['shareEmail'] ?? true,
                'shareZalo': body['shareZalo'] ?? true,
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'sharePhone': true,
              'shareEmail': true,
              'shareZalo': true,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final api = ApiService.withClient(client)
        ..setTokens(accessToken: 'tok', refreshToken: 'ref');
      final session = AuthSession(apiService: api)..updateUser(testUser);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(home: PrivacyScreen(apiService: api)),
        ),
      );
      await tester.pumpAndSettle();

      // Find the switch for "Chia sẻ Số điện thoại"
      // Switches in order: SearchActive, SharePhone, ShareEmail, ShareZalo
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(4));

      // Toggle sharePhone (index 1)
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(privacyUpdateSent, isTrue);
    });
  });

  group('ContactDetailsScreen Contact Privacy Display (FR-45)', () {
    testWidgets('Shows hidden message when phone and email are not shared', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ContactDetailsScreen(
            contactId: 5,
            contactName: 'Đối tác',
            phone: null,
            email: null,
          ),
        ),
      );

      expect(find.text('Người dùng không chia sẻ số điện thoại'), findsOneWidget);
      expect(find.text('Người dùng không chia sẻ email'), findsOneWidget);

      final zaloButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Mở Zalo'),
      );
      expect(zaloButton.onPressed, isNull);
    });

    testWidgets('Shows contact data and enables Zalo when shared', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ContactDetailsScreen(
            contactId: 5,
            contactName: 'Đối tác',
            phone: '0987654321',
            email: 'doitac@gmail.com',
            shareZalo: true,
          ),
        ),
      );

      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('doitac@gmail.com'), findsOneWidget);

      final zaloButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Mở Zalo'),
      );
      expect(zaloButton.onPressed, isNotNull);
    });

    testWidgets('Disables Zalo button when shareZalo is false even if phone exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ContactDetailsScreen(
            contactId: 5,
            contactName: 'Đối tác',
            phone: '0987654321',
            email: 'doitac@gmail.com',
            shareZalo: false,
          ),
        ),
      );

      expect(find.text('0987654321'), findsOneWidget);
      final zaloButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Mở Zalo'),
      );
      expect(zaloButton.onPressed, isNull);
    });
  });
}
