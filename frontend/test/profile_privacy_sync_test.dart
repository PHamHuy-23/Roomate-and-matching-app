import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:roommate_hub_mobile/models/auth_user.dart';
import 'package:roommate_hub_mobile/navigation/app_routes.dart';
import 'package:roommate_hub_mobile/screens/edit_profile_screen.dart';
import 'package:roommate_hub_mobile/screens/privacy_screen.dart';
import 'package:roommate_hub_mobile/screens/profile_screen.dart';
import 'package:roommate_hub_mobile/screens/settings_screen.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

final original = AuthUser(
  token: 'A-access',
  refreshToken: 'A-refresh',
  userId: 10,
  email: 'A@example.test',
  fullName: 'Original name',
  gender: 'MALE',
  role: 'ROLE_USER',
  phone: '0901234567',
  university: 'Original university',
);

http.Response reply(Object? value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> profile({String? avatar}) => {
  'id': 10,
  'email': 'A@example.test',
  'fullName': 'Server name',
  'gender': 'MALE',
  'role': 'ROLE_USER',
  'phone': '0901234567',
  'university': 'Server university',
  'avatarUrl': avatar,
  'birthDate': null,
};

ApiService apiWith(Future<http.Response> Function(http.Request) handler) =>
    ApiService.withClient(MockClient(handler))
      ..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');

Future<AuthUser> saveApiProfile(ApiService api) => api.updateProfile(
  10,
  'Draft name',
  '0901234567',
  'MALE',
  null,
  'Draft university',
);
Future<bool> saveSessionProfile(AuthSession session) => session.updateProfile(
  fullName: 'Draft name',
  phone: '0901234567',
  gender: 'MALE',
  birthDate: null,
  university: 'Draft university',
);

Future<void> openPrivacy(
  WidgetTester tester,
  ApiService api,
  AuthSession session, {
  void Function(Object?)? onReturn,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthSession>.value(
      value: session,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute<Object?>(
                    builder: (_) => PrivacyScreen(apiService: api),
                  ),
                );
                onReturn?.call(result);
              },
              child: const Text('Open privacy'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open privacy'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => ApiService.configureUnauthorizedHandler(() {}));

  for (final operation in ['GET', 'PUT']) {
    for (final body in [
      null,
      [],
      {},
      {'searchActive': 'true'},
    ]) {
      test(
        '$operation invalid search-status body does not overwrite confirmed cache: $body',
        () async {
          final api = apiWith((_) async => reply(body));
          final action = operation == 'GET'
              ? api.getSearchStatus()
              : api.updateSearchStatus(false);
          await expectLater(action, throwsA(isA<ApiException>()));
          expect(api.isSearchActive, isTrue);
        },
      );
    }
  }
  test(
    'Search cache uses backend acknowledgement, not the requested value',
    () async {
      final api = apiWith((_) async => reply({'searchActive': false}));
      expect(await api.updateSearchStatus(true), isFalse);
      expect(api.isSearchActive, isFalse);
    },
  );
  test(
    'Late search read cannot overwrite a newer confirmed privacy save',
    () async {
      final delayed = Completer<http.Response>();
      final api = apiWith(
        (request) async => request.method == 'GET'
            ? delayed.future
            : reply({'searchActive': false}),
      );
      final reading = api.getSearchStatus();
      expect(await api.updateSearchStatus(false), isFalse);
      delayed.complete(reply({'searchActive': true}));
      expect(await reading, isTrue);
      expect(api.isSearchActive, isFalse);
    },
  );

  for (final invalid in [
    <String, dynamic>{},
    {...profile(), 'id': 99},
    {...profile(), 'fullName': null},
    {...profile(), 'phone': 42},
    {...profile(), 'birthDate': 'bad-date'},
  ]) {
    test(
      'HTTP 200 invalid profile is not a successful save: $invalid',
      () async {
        final api = apiWith((_) async => reply(invalid));
        await expectLater(saveApiProfile(api), throwsA(isA<ApiException>()));
        expect(api.authToken, 'A-access');
      },
    );
  }
  test(
    'Profile API consumes authoritative data without trusting response tokens',
    () async {
      final api = apiWith(
        (_) async => reply({
          ...profile(avatar: 'https://media.example.test/new.png'),
          'token': 'untrusted',
          'refreshToken': 'untrusted',
        }),
      );
      final saved = await saveApiProfile(api);
      expect(saved.fullName, 'Server name');
      expect(saved.university, 'Server university');
      expect(saved.avatarUrl, 'https://media.example.test/new.png');
      expect(saved.token, 'A-access');
      expect(saved.refreshToken, 'A-refresh');
    },
  );

  test('Session uses backend profile fields and keeps tokens', () async {
    final api = apiWith(
      (_) async =>
          reply(profile(avatar: 'https://media.example.test/latest.png')),
    );
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    expect(await saveSessionProfile(session), isTrue);
    expect(session.user!.fullName, 'Server name');
    expect(session.user!.university, 'Server university');
    expect(session.user!.avatarUrl, 'https://media.example.test/latest.png');
    expect(session.user!.token, 'A-access');
  });
  test('Profile save keeps tokens refreshed during the request', () async {
    var puts = 0;
    final api = apiWith((request) async {
      if (request.url.path.endsWith('/auth/refresh-token')) {
        return reply({
          'accessToken': 'fresh-access',
          'refreshToken': 'fresh-refresh',
        });
      }
      if (++puts == 1) return reply({}, 401);
      return reply(profile());
    });
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    expect(await saveSessionProfile(session), isTrue);
    expect(session.user!.token, 'fresh-access');
    expect(session.user!.refreshToken, 'fresh-refresh');
  });
  test('Failed profile save leaves the confirmed session unchanged', () async {
    final api = apiWith((_) async => reply({'message': 'Rejected'}, 400));
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    await expectLater(
      saveSessionProfile(session),
      throwsA(isA<ApiException>()),
    );
    expect(session.user, same(original));
  });
  test(
    'Avatar confirmed during profile save survives a delayed old response',
    () async {
      final delayed = Completer<http.Response>();
      final api = apiWith((_) => delayed.future);
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      final saving = saveSessionProfile(session);
      session.updateUser(
        session.user!.copyWith(avatarUrl: 'https://media.example.test/new.png'),
      );
      delayed.complete(reply(profile()));
      expect(await saving, isTrue);
      expect(session.user!.avatarUrl, 'https://media.example.test/new.png');
      expect(session.user!.fullName, 'Server name');
    },
  );
  test('Old profile response cannot update a new account', () async {
    final delayed = Completer<http.Response>();
    final api = apiWith((_) => delayed.future);
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    final saving = saveSessionProfile(session);
    final checked = expectLater(saving, throwsA(isA<ApiException>()));
    api.setTokens(accessToken: 'B-access', refreshToken: 'B-refresh');
    session.updateUser(
      original.copyWith(
        userId: 20,
        email: 'B@example.test',
        fullName: 'Account B',
      ),
    );
    delayed.complete(reply(profile()));
    await checked;
    expect(session.user!.fullName, 'Account B');
    expect(api.authToken, 'B-access');
  });

  testWidgets(
    'Privacy switch is a draft; save waits, blocks duplicates, then returns success',
    (tester) async {
      final delayed = Completer<http.Response>();
      var writes = 0;
      Object? returned;
      final api = apiWith((request) async {
        if (request.method == 'GET') return reply({'searchActive': true});
        writes++;
        expect(jsonDecode(request.body), {'searchActive': false});
        return delayed.future;
      });
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await openPrivacy(
        tester,
        api,
        session,
        onReturn: (result) => returned = result,
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(writes, 0);
      expect(api.isSearchActive, isTrue);
      expect(find.text('Chưa lưu thay đổi'), findsOneWidget);
      await tester.tap(find.text('Lưu cài đặt'));
      await tester.pump();
      expect(writes, 1);
      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(returned, isNull);
      expect(find.text('Đã lưu cài đặt.'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      delayed.complete(reply({'searchActive': false}));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(api.isSearchActive, isFalse);
      expect(find.byType(PrivacyScreen), findsNothing);
    },
  );

  for (final failure in [
    reply({'message': 'Synthetic failure'}, 500),
    reply({}),
    reply({'searchActive': true}),
  ]) {
    testWidgets(
      'Privacy failed/malformed/mismatched save keeps draft and supports retry: ${failure.body}',
      (tester) async {
        var writes = 0;
        final api = apiWith((request) async {
          if (request.method == 'GET') return reply({'searchActive': true});
          return ++writes == 1 ? failure : reply({'searchActive': false});
        });
        final session = AuthSession(apiService: api)..updateUser(original);
        addTearDown(session.dispose);
        await openPrivacy(tester, api, session);
        await tester.tap(find.byType(Switch));
        await tester.pump();
        await tester.tap(find.text('Lưu cài đặt'));
        await tester.pumpAndSettle();
        expect(find.byType(PrivacyScreen), findsOneWidget);
        expect(find.text('Đã lưu cài đặt.'), findsNothing);
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(api.isSearchActive, isTrue);
        await tester.tap(find.text('Lưu cài đặt'));
        await tester.pumpAndSettle();
        expect(writes, 2);
        expect(find.byType(PrivacyScreen), findsNothing);
        expect(api.isSearchActive, isFalse);
      },
    );
  }
  testWidgets('Unknown search status blocks save and allows GET retry', (
    tester,
  ) async {
    var reads = 0, writes = 0;
    final api = apiWith((request) async {
      if (request.method == 'PUT') {
        writes++;
        return reply({'searchActive': true});
      }
      return ++reads == 1 ? reply({}, 503) : reply({'searchActive': false});
    });
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    await openPrivacy(tester, api, session);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.text('Đã tắt · Ẩn khỏi gợi ý'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    expect(writes, 0);
  });
  testWidgets('Cancel privacy discards draft without writing server/cache', (
    tester,
  ) async {
    var writes = 0;
    final api = apiWith((request) async {
      if (request.method == 'PUT') writes++;
      return reply({'searchActive': true});
    });
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    await openPrivacy(tester, api, session);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(api.isSearchActive, isTrue);
  });
  testWidgets(
    'Late privacy save after account switch cannot close route or report success',
    (tester) async {
      final delayed = Completer<http.Response>();
      final api = apiWith(
        (request) async => request.method == 'GET'
            ? reply({'searchActive': true})
            : delayed.future,
      );
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await openPrivacy(tester, api, session);
      await tester.tap(find.text('Lưu cài đặt'));
      await tester.pump();
      api.setAuthToken('B-access');
      session.updateUser(original.copyWith(userId: 20, fullName: 'Account B'));
      await tester.pump();
      delayed.complete(reply({'searchActive': false}));
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu cài đặt.'), findsNothing);
      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(session.user!.fullName, 'Account B');
      expect(api.isSearchActive, isTrue);
    },
  );

  testWidgets('Profile opened before edits observes current session data', (
    tester,
  ) async {
    final api = apiWith((_) async => reply(null, 404));
    final session = AuthSession(apiService: api)..updateUser(original);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthSession>.value(
        value: session,
        child: MaterialApp(
          home: ProfileScreen(currentUser: original, apiService: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    session.updateUser(
      original.copyWith(
        fullName: 'Updated via settings',
        university: 'New university',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Updated via settings'), findsOneWidget);
    expect(find.text('Original name'), findsNothing);
    expect(session.user!.university, 'New university');
  });

  testWidgets(
    'Profile visibility uses actual status and retries unknown data',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var reads = 0;
      final api = apiWith((request) async {
        if (request.url.path.endsWith('/search-status')) {
          return ++reads == 1 ? reply({}) : reply({'searchActive': false});
        }
        return reply(null, 404);
      });
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(
            home: ProfileScreen(currentUser: original, apiService: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được trạng thái tìm bạn'), findsOneWidget);
      expect(find.text('Đang tìm bạn ở ghép'), findsNothing);
      await tester.tap(find.text('Thử lại trạng thái'));
      await tester.pumpAndSettle();
      expect(find.text('Đã tắt tìm bạn ở ghép'), findsOneWidget);
    },
  );

  testWidgets(
    'Settings privacy save refreshes visibility on the existing profile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var active = true;
      final api = apiWith((request) async {
        if (request.url.path.endsWith('/search-status')) {
          if (request.method == 'PUT') {
            active = jsonDecode(request.body)['searchActive'] as bool;
          }
          return reply({'searchActive': active});
        }
        return reply(null, 404);
      });
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(
            home: ProfileScreen(currentUser: original, apiService: api),
            routes: {
              AppRoutes.settings: (_) => const SettingsScreen(),
              AppRoutes.privacy: (_) => PrivacyScreen(apiService: api),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đang tìm bạn ở ghép'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cài đặt & quyền riêng tư'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quyền riêng tư'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Lưu cài đặt'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Đã tắt tìm bạn ở ghép'), findsOneWidget);
      expect(find.text('Đang tìm bạn ở ghép'), findsNothing);
      expect(api.isSearchActive, isFalse);
    },
  );

  testWidgets(
    'Delayed edit save cannot report success or change a new account',
    (tester) async {
      final delayed = Completer<http.Response>();
      final api = apiWith(
        (request) async =>
            request.method == 'PUT' ? delayed.future : reply(null, 404),
      );
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EditProfileScreen(
                        currentUser: original,
                        apiService: api,
                      ),
                    ),
                  ),
                  child: const Text('Open edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();
      api.setAuthToken('B-access');
      session.updateUser(original.copyWith(userId: 20, fullName: 'Account B'));
      await tester.pump();
      delayed.complete(reply(profile()));
      await tester.pumpAndSettle();
      expect(session.user!.fullName, 'Account B');
      expect(find.text('Đã lưu thay đổi'), findsNothing);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(
        find.text('Phiên đăng nhập đã thay đổi. Vui lòng mở lại hồ sơ.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Settings edit uses server response and updates the underlying profile',
    (tester) async {
      final api = apiWith(
        (request) async =>
            request.method == 'PUT' ? reply(profile()) : reply(null, 404),
      );
      final session = AuthSession(apiService: api)..updateUser(original);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: MaterialApp(
            home: ProfileScreen(currentUser: original, apiService: api),
            routes: {
              AppRoutes.settings: (_) => const SettingsScreen(),
              AppRoutes.editProfile: (_) => EditProfileScreen(
                currentUser: session.user!,
                apiService: api,
              ),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cài đặt & quyền riêng tư'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thông tin cá nhân'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('Họ và tên')),
        'Draft name',
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(session.user!.fullName, 'Server name');
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Server name'), findsOneWidget);
      expect(find.text('Original name'), findsNothing);
    },
  );
}
