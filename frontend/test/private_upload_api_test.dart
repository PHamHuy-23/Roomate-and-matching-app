import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roommate_hub_mobile/models/upload_ticket.dart';
import 'package:roommate_hub_mobile/services/api_service.dart';

const _uuid = '12345678-1234-4234-8234-123456789abc';
const _chatKey = 'chat/1/$_uuid.png';
const _uploadUrl = 'https://r2.test.invalid/upload?signature=temporary';
const _directories = {
  'avatar': 'avatars',
  'room-post': 'room-posts',
  'chat': 'chat',
  'report': 'reports',
};

Map<String, dynamic> _ticket(String purpose) {
  final key = '${_directories[purpose]}/1/$_uuid.png';
  return {
    'uploadUrl': _uploadUrl,
    'publicUrl': purpose == 'chat' || purpose == 'report'
        ? null
        : 'https://media.test.invalid/$key',
    'objectKey': key,
    'contentType': 'image/png',
    'expiresInSeconds': 600,
  };
}

http.Response _reply(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<UploadTicket> _upload(ApiService api, String purpose) => api.uploadImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'image.png',
  contentType: 'image/png',
  purpose: purpose,
);

Map<String, dynamic> _message([String? imageUrl]) => {
  'id': 9,
  'senderId': 1,
  'receiverId': 2,
  'content': 'Caption',
  'imageUrl': imageUrl,
  'createdAt': '2026-10-04T10:00:00',
  'fromMe': true,
};

void main() {
  test('UploadTicket preserves a nullable private public URL', () {
    expect(UploadTicket.fromJson(_ticket('chat')).publicUrl, isNull);
    expect(UploadTicket.fromJson(_ticket('report')).publicUrl, isNull);
    final omitted = _ticket('chat')..remove('publicUrl');
    expect(UploadTicket.fromJson(omitted).publicUrl, isNull);
  });

  for (final purpose in _directories.keys) {
    test(
      '$purpose upload uses the ticket without exposing auth to R2',
      () async {
        var presigns = 0;
        var puts = 0;
        final payload = _ticket(purpose);
        final client = MockClient((request) async {
          if (request.method == 'POST') {
            presigns++;
            expect(request.url.path, '/api/v1/uploads/presign');
            expect(request.headers['Authorization'], 'Bearer test-access');
            expect(jsonDecode(request.body), {
              'fileName': 'image.png',
              'contentType': 'image/png',
              'fileSize': 3,
              'purpose': purpose,
            });
            return _reply({'status': 200, 'data': payload});
          }
          puts++;
          expect(request.method, 'PUT');
          expect(request.url.toString(), _uploadUrl);
          expect(request.headers['Content-Type'], 'image/png');
          expect(request.headers['Content-Length'], '3');
          expect(
            request.headers['Cache-Control'],
            purpose == 'chat' || purpose == 'report'
                ? 'private, no-store'
                : isNull,
          );
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.bodyBytes, [1, 2, 3]);
          return http.Response('', 200);
        });
        addTearDown(client.close);
        final result = await _upload(
          ApiService.withClient(client)..setAuthToken('test-access'),
          purpose,
        );
        expect(result.objectKey, payload['objectKey']);
        expect(result.publicUrl, payload['publicUrl']);
        expect(presigns, 1);
        expect(puts, 1);
      },
    );
  }

  for (final purpose in ['chat', 'report']) {
    for (final publicUrl in ['', 'https://media.test.invalid/private.png']) {
      test(
        '$purpose rejects a non-null public URL before any PUT: $publicUrl',
        () async {
          var requests = 0;
          final client = MockClient((request) async {
            requests++;
            expect(request.method, 'POST');
            return _reply({..._ticket(purpose), 'publicUrl': publicUrl});
          });
          addTearDown(client.close);
          await expectLater(
            _upload(ApiService.withClient(client), purpose),
            throwsA(isA<ApiException>()),
          );
          expect(requests, 1);
        },
      );
    }
  }

  for (final invalid in [
    'reports/1/$_uuid.png',
    'https://media.test.invalid/$_chatKey',
    'chat/1/../$_uuid.png',
    'chat/1/%2e%2e/$_uuid.png',
    'chat/0/$_uuid.png',
    'chat/01/$_uuid.png',
    'chat/1/not-a-uuid.png',
    'chat/1/$_uuid.png?signature=temporary',
    'chat/1/$_uuid.svg',
  ]) {
    test(
      'chat rejects a noncanonical or cross-purpose ticket key: $invalid',
      () async {
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          expect(request.method, 'POST');
          return _reply({..._ticket('chat'), 'objectKey': invalid});
        });
        addTearDown(client.close);
        await expectLater(
          _upload(ApiService.withClient(client), 'chat'),
          throwsA(isA<ApiException>()),
        );
        expect(calls, 1);
      },
    );
  }

  test('report rejects a chat ticket key', () async {
    final client = MockClient(
      (_) async => _reply({..._ticket('report'), 'objectKey': _chatKey}),
    );
    addTearDown(client.close);
    await expectLater(
      _upload(ApiService.withClient(client), 'report'),
      throwsA(isA<ApiException>()),
    );
  });

  for (final purpose in ['avatar', 'room-post']) {
    for (final publicUrl in [
      null,
      '',
      'http://media.test.invalid/public.png',
      'https://media.test.invalid/wrong-object.png',
    ]) {
      test(
        '$purpose requires a matching HTTPS public URL: $publicUrl',
        () async {
          var calls = 0;
          final client = MockClient((request) async {
            calls++;
            expect(request.method, 'POST');
            return _reply({..._ticket(purpose), 'publicUrl': publicUrl});
          });
          addTearDown(client.close);
          await expectLater(
            _upload(ApiService.withClient(client), purpose),
            throwsA(isA<ApiException>()),
          );
          expect(calls, 1);
        },
      );
    }
  }

  for (final malformed in <Map<String, dynamic>>[
    {'uploadUrl': 'http://r2.test.invalid/upload'},
    {'uploadUrl': 'https://user:password@r2.test.invalid/upload'},
    {'uploadUrl': 'https://r2.test.invalid/upload#fragment'},
    {'contentType': 'image/jpeg'},
    {'expiresInSeconds': 0},
    {'objectKey': 12},
    {'publicUrl': 12},
  ]) {
    test('malformed upload ticket is rejected: $malformed', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.method, 'POST');
        return _reply({..._ticket('chat'), ...malformed});
      });
      addTearDown(client.close);
      await expectLater(
        _upload(ApiService.withClient(client), 'chat'),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });
  }

  test('unsupported purpose is rejected without calling the backend', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _reply(_ticket('chat'));
    });
    addTearDown(client.close);
    await expectLater(
      _upload(ApiService.withClient(client), 'unknown'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 0);
  });

  test(
    'failed private PUT fails upload and does not pretend success',
    () async {
      final client = MockClient(
        (request) async => request.method == 'POST'
            ? _reply(_ticket('chat'))
            : http.Response('', 403),
      );
      addTearDown(client.close);
      await expectLater(
        _upload(ApiService.withClient(client), 'chat'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
    },
  );

  test(
    'send chat carries only the private key, response read URL remains displayable',
    () async {
      const readUrl = 'https://r2.test.invalid/$_chatKey?signature=short-lived';
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/chat/messages');
        expect(jsonDecode(request.body), {
          'receiverId': 2,
          'content': 'Caption',
          'imageObjectKey': _chatKey,
        });
        return _reply(_message(readUrl), 201);
      });
      addTearDown(client.close);
      final result = await ApiService.withClient(client).sendChatMessage(
        receiverId: 2,
        content: 'Caption',
        imageObjectKey: _chatKey,
      );
      expect(result.imageUrl, readUrl);
    },
  );

  test(
    'text-only send does not emit an attachment or legacy URL field',
    () async {
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {
          'receiverId': 2,
          'content': 'Caption',
        });
        return _reply(_message());
      });
      addTearDown(client.close);
      expect(
        (await ApiService.withClient(
          client,
        ).sendChatMessage(receiverId: 2, content: 'Caption')).imageUrl,
        isNull,
      );
    },
  );

  for (final invalid in [
    '',
    'reports/1/$_uuid.png',
    'https://media.test.invalid/$_chatKey',
    'chat/1/../$_uuid.png',
  ]) {
    test(
      'send rejects an invalid or pasted URL key without transport: $invalid',
      () async {
        var calls = 0;
        final client = MockClient((_) async {
          calls++;
          return _reply(_message());
        });
        addTearDown(client.close);
        await expectLater(
          ApiService.withClient(client).sendChatMessage(
            receiverId: 2,
            content: 'Caption',
            imageObjectKey: invalid,
          ),
          throwsA(isA<ApiException>()),
        );
        expect(calls, 0);
      },
    );
  }
}
