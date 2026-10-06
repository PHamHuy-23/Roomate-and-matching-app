import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';
import 'package:roommate_hub_mobile/state/auth_session.dart';

http.Response reply(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status);

Map<String, dynamic> account(String name) => {
  'token': '$name-access',
  'refreshToken': '$name-refresh',
  'userId': name == 'A' ? 1 : 2,
  'email': '$name@example.test',
  'fullName': name,
  'gender': 'MALE',
  'role': 'ROLE_USER',
};

final changedSession = isA<ApiException>().having(
  (error) => error.message,
  'message',
  contains('Phiên đăng nhập đã thay đổi'),
);

void main() {
  tearDown(() => ApiService.configureUnauthorizedHandler(() {}));

  test(
    'late logout preserves AuthSession user and tokens after login B',
    () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/logout')) {
            started.complete();
            return delayed.future;
          }
          final b = jsonDecode(request.body)['email'] == 'B@example.test';
          return reply(account(b ? 'B' : 'A'));
        }),
      );
      final session = AuthSession(apiService: api);
      await session.login('A@example.test', 'test-password');
      final logout = session.signOut();
      expect(session.user, isNull);
      expect(api.hasAuthToken, isFalse);
      await started.future;
      await session.login('B@example.test', 'test-password');
      delayed.complete(reply({}));
      await logout;
      expect(session.user!.userId, 2);
      expect(session.isAuthenticated, isTrue);
      expect(api.authToken, 'B-access');
    },
  );

  for (final result in [200, 401]) {
    test(
      'late retry ($result) from A cannot invalidate or return data to B',
      () async {
        final delayed = Completer<http.Response>();
        final started = Completer<void>();
        var callbacks = 0;
        ApiService.configureUnauthorizedHandler(() => callbacks++);
        final api = ApiService.withClient(
          MockClient((request) async {
            if (request.url.path.endsWith('/auth/login')) {
              return reply(account('B'));
            }
            if (request.url.path.endsWith('/auth/refresh-token')) {
              return reply({'token': 'A-renewed', 'refreshToken': 'A-rotated'});
            }
            if (request.headers['authorization'] == 'Bearer A-access') {
              return reply({}, 401);
            }
            expect(request.headers['authorization'], 'Bearer A-renewed');
            started.complete();
            return delayed.future;
          }),
        )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
        final checked = expectLater(
          api.getSearchStatus(),
          throwsA(changedSession),
        );
        await started.future;
        await api.login('B@example.test', 'test-password');
        delayed.complete(reply({'searchActive': false}, result));
        await checked;
        expect(callbacks, 0);
        expect(api.authToken, 'B-access');
        expect(api.isSearchActive, isTrue);
      },
    );
  }

  for (final operation in ['read-saved', 'save-post', 'write-search']) {
    test('$operation late response cannot modify B cache', () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return reply(account('B'));
          }
          started.complete();
          return delayed.future;
        }),
      )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
      final Future<void> pending = switch (operation) {
        'read-saved' => api.loadSavedPosts(),
        'save-post' => api.setPostSaved(17, true),
        _ => api.updateSearchStatus(false),
      };
      final checked = expectLater(pending, throwsA(changedSession));
      await started.future;
      await api.login('B@example.test', 'test-password');
      api.savedPostIds.add(29);
      delayed.complete(reply(operation == 'read-saved' ? [17] : {}));
      await checked;
      expect(api.savedPostIds, {29});
      expect(api.isSearchActive, isTrue);
    });
  }

  test('refresh without token does not poison a later valid refresh', () async {
    final api = ApiService.withClient(
      MockClient(
        (_) async => reply({'token': 'A-renewed', 'refreshToken': 'A-rotated'}),
      ),
    );
    expect(await api.refreshAuthToken(), isFalse);
    api.setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
    expect(await api.refreshAuthToken(), isTrue);
    expect(api.authToken, 'A-renewed');
  });

  for (final result in [200, 401, 503, -1]) {
    test(
      'slow logout ($result) invalidates immediately and preserves B',
      () async {
        final delayed = Completer<http.Response>();
        final started = Completer<void>();
        var refreshes = 0;
        final api = ApiService.withClient(
          MockClient((request) async {
            if (request.url.path.endsWith('/auth/login')) {
              return reply(account('B'));
            }
            if (request.url.path.endsWith('/auth/refresh-token')) refreshes++;
            expect(request.url.path, endsWith('/auth/logout'));
            expect(request.headers['authorization'], 'Bearer A-access');
            expect(jsonDecode(request.body), {'refreshToken': 'A-refresh'});
            started.complete();
            return delayed.future;
          }),
        )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
        api.savedPostIds.add(17);
        api.isSearchActive = false;
        final logout = api.logout();
        expect(api.hasAuthToken, isFalse);
        expect(api.hasRefreshToken, isFalse);
        expect(api.savedPostIds, isEmpty);
        expect(api.isSearchActive, isTrue);
        await started.future;
        await api.login('B@example.test', 'test-password');
        api.savedPostIds.add(29);
        api.isSearchActive = false;
        if (result == -1) {
          delayed.completeError(http.ClientException('offline'));
        } else {
          delayed.complete(reply({}, result));
        }
        await logout;
        expect(api.authToken, 'B-access');
        expect(api.refreshToken, 'B-refresh');
        expect(api.savedPostIds, {29});
        expect(api.isSearchActive, isFalse);
        expect(refreshes, 0);
      },
    );
  }

  for (final result in [200, 401]) {
    test('late A refresh ($result) cannot overwrite or expire B', () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh-token')) {
            expect(jsonDecode(request.body), {'refreshToken': 'A-refresh'});
            started.complete();
            return delayed.future;
          }
          return reply(account('B'));
        }),
      )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
      final refresh = api.refreshAuthToken();
      await started.future;
      await api.login('B@example.test', 'test-password');
      delayed.complete(reply(account('A'), result));
      expect(await refresh, isFalse);
      expect(api.authToken, 'B-access');
      expect(api.refreshToken, 'B-refresh');
    });
  }

  test('A refresh completion does not clear B single-flight refresh', () async {
    final old = Completer<http.Response>();
    final current = Completer<http.Response>();
    final oldStarted = Completer<void>();
    final currentStarted = Completer<void>();
    var calls = 0;
    final api = ApiService.withClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return reply(account('B'));
        }
        calls++;
        if (jsonDecode(request.body)['refreshToken'] == 'A-refresh') {
          oldStarted.complete();
          return old.future;
        }
        if (!currentStarted.isCompleted) currentStarted.complete();
        return current.future;
      }),
    )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
    final oldRefresh = api.refreshAuthToken();
    await oldStarted.future;
    await api.login('B@example.test', 'test-password');
    final first = api.refreshAuthToken();
    await currentStarted.future;
    old.complete(reply(account('A')));
    expect(await oldRefresh, isFalse);
    final second = api.refreshAuthToken();
    current.complete(
      reply({'token': 'B-renewed', 'refreshToken': 'B-rotated'}),
    );
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(calls, 2);
    expect(api.authToken, 'B-renewed');
    expect(api.refreshToken, 'B-rotated');
  });

  for (final result in [200, 401, 403, 500]) {
    test(
      'late A request ($result) is discarded without retry/callback',
      () async {
        final delayed = Completer<http.Response>();
        final started = Completer<void>();
        var callbacks = 0;
        var requests = 0;
        ApiService.configureUnauthorizedHandler(() => callbacks++);
        final api = ApiService.withClient(
          MockClient((request) async {
            if (request.url.path.endsWith('/auth/login')) {
              return reply(account('B'));
            }
            requests++;
            expect(request.url.path, endsWith('/profile/search-status'));
            expect(request.headers['authorization'], 'Bearer A-access');
            started.complete();
            return delayed.future;
          }),
        )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
        final checked = expectLater(
          api.getSearchStatus(),
          throwsA(changedSession),
        );
        await started.future;
        await api.login('B@example.test', 'test-password');
        delayed.complete(reply({'searchActive': false}, result));
        await checked;
        expect(api.isSearchActive, isTrue);
        expect(api.authToken, 'B-access');
        expect(callbacks, 0);
        expect(requests, 1);
      },
    );
  }

  test(
    'A mutation awaiting refresh is never retried using B credentials',
    () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      var mutations = 0;
      var callbacks = 0;
      ApiService.configureUnauthorizedHandler(() => callbacks++);
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return reply(account('B'));
          }
          if (request.url.path.endsWith('/auth/refresh-token')) {
            started.complete();
            return delayed.future;
          }
          mutations++;
          expect(request.headers['authorization'], 'Bearer A-access');
          return reply({}, 401);
        }),
      )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
      final checked = expectLater(
        api.updateSearchStatus(false),
        throwsA(changedSession),
      );
      await started.future;
      await api.login('B@example.test', 'test-password');
      delayed.complete(reply(account('A')));
      await checked;
      expect(mutations, 1);
      expect(callbacks, 0);
      expect(api.authToken, 'B-access');
      expect(api.isSearchActive, isTrue);
    },
  );

  test(
    'same-session concurrent 401s share refresh and retry correctly',
    () async {
      final refresh = Completer<http.Response>();
      final started = Completer<void>();
      var refreshes = 0;
      var original = 0;
      var retries = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh-token')) {
            refreshes++;
            if (!started.isCompleted) started.complete();
            return refresh.future;
          }
          if (request.headers['authorization'] == 'Bearer A-access') {
            original++;
            return reply({}, 401);
          }
          expect(request.headers['authorization'], 'Bearer A-renewed');
          retries++;
          return reply({'searchActive': false});
        }),
      )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
      final first = api.getSearchStatus();
      final second = api.getSearchStatus();
      await started.future;
      // Both original requests are in progress before resolving the shared refresh.
      await Future<void>.delayed(Duration.zero);
      refresh.complete(
        reply({'token': 'A-renewed', 'refreshToken': 'A-rotated'}),
      );
      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(original, 2);
      expect(refreshes, 1);
      expect(retries, 2);
      expect(api.refreshToken, 'A-rotated');
    },
  );

  for (final registration in [false, true]) {
    test(
      'late ${registration ? 'registration' : 'login'} cannot replace B',
      () async {
        final delayed = Completer<http.Response>();
        final started = Completer<void>();
        final api = ApiService.withClient(
          MockClient((request) async {
            final data = jsonDecode(request.body);
            if (data['email'] == 'A@example.test') {
              started.complete();
              return delayed.future;
            }
            return reply(account('B'));
          }),
        );
        final session = AuthSession(apiService: api);
        final old = registration
            ? session.register(
                'A@example.test',
                'test-password',
                'A',
                'MALE',
                '',
                DateTime(2000),
                'Audit University',
              )
            : session.login('A@example.test', 'test-password');
        final checked = expectLater(old, throwsA(changedSession));
        await started.future;
        await session.login('B@example.test', 'test-password');
        delayed.complete(reply(account('A'), registration ? 201 : 200));
        await checked;
        expect(session.user!.userId, 2);
        expect(session.isAuthenticated, isTrue);
        expect(api.authToken, 'B-access');
      },
    );
  }

  test(
    'signOut during login prevents late response restoring the user',
    () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      final api = ApiService.withClient(
        MockClient((_) async {
          started.complete();
          return delayed.future;
        }),
      );
      final session = AuthSession(apiService: api);
      final checked = expectLater(
        session.login('A@example.test', 'test-password'),
        throwsA(changedSession),
      );
      await started.future;
      await session.signOut();
      delayed.complete(reply(account('A')));
      await checked;
      expect(session.user, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(api.authToken, isNull);
    },
  );

  test(
    'signOut notifies listeners only after transport tokens are cleared',
    () async {
      final delayed = Completer<http.Response>();
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/logout')) return delayed.future;
          return reply(account('A'));
        }),
      );
      final session = AuthSession(apiService: api);
      await session.login('A@example.test', 'test-password');
      session.addListener(() {
        expect(session.user, isNull);
        expect(api.hasAuthToken, isFalse);
        expect(api.hasRefreshToken, isFalse);
      });
      final logout = session.signOut();
      delayed.complete(reply({}));
      await logout;
    },
  );

  test(
    'old guarded avatar update is rejected after same-account re-login',
    () async {
      final api = ApiService.withClient(
        MockClient((_) async => reply(account('A'))),
      );
      final session = AuthSession(apiService: api);
      final old = await session.login('A@example.test', 'test-password');
      final generation = session.generation;
      await session.signOut();
      await session.login('A@example.test', 'test-password');
      session.updateUser(
        old.copyWith(avatarUrl: 'https://media.test.invalid/old.png'),
        expectedGeneration: generation,
      );
      expect(session.user!.avatarUrl, isNull);
      expect(session.isCurrentSession(generation, old.userId), isFalse);
    },
  );

  test(
    'R2 PUT completion from A cannot be followed by avatar confirm as B',
    () async {
      const key = 'avatars/1/12345678-1234-4234-8234-123456789abc.png';
      final upload = Completer<http.Response>();
      final started = Completer<void>();
      var confirms = 0;
      final api = ApiService.withClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) {
            return reply(account('B'));
          }
          if (request.url.path.endsWith('/uploads/presign')) {
            return reply({
              'uploadUrl': 'https://r2.test.invalid/upload',
              'publicUrl': 'https://media.test.invalid/$key',
              'objectKey': key,
              'contentType': 'image/png',
              'expiresInSeconds': 600,
            });
          }
          if (request.url.path.endsWith('/uploads/avatar')) confirms++;
          started.complete();
          return upload.future;
        }),
      )..setTokens(accessToken: 'A-access', refreshToken: 'A-refresh');
      final checked = expectLater(() async {
        final ticket = await api.uploadImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'image.png',
          contentType: 'image/png',
          purpose: 'avatar',
        );
        await api.confirmAvatar(ticket.objectKey);
      }(), throwsA(changedSession));
      await started.future;
      await api.login('B@example.test', 'test-password');
      upload.complete(http.Response('', 200));
      await checked;
      expect(confirms, 0);
      expect(api.authToken, 'B-access');
    },
  );
}
