import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scripted_adapter.dart';

const String _refreshPath = '/app/auth/refresh';
const String _accessKey = 'eventor.access_token';
const String _refreshKey = 'eventor.refresh_token';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What the keychain holds, readable after the fact.
  late Map<String, String> keychain;
  late TokenStore tokens;
  late ScriptedAdapter adapter;
  late ApiClient client;
  late int expiredCalls;

  /// Starts the client with a stored session — or without one.
  Future<void> start({bool signedIn = true, String languageCode = 'en'}) async {
    keychain = <String, String>{
      if (signedIn) _accessKey: 'access-1',
      if (signedIn) _refreshKey: 'refresh-1',
    };
    FlutterSecureStorage.setMockInitialValues(keychain);
    tokens = TokenStore();
    await tokens.load();
    adapter = ScriptedAdapter(
      (RequestOptions request) async => jsonResponse(<String, Object?>{
        'data': <String, Object?>{'ok': true},
      }),
    );
    client = scriptedClient(adapter, tokens, languageCode: languageCode);
    expiredCalls = 0;
    client.onSessionExpired = () => expiredCalls++;
  }

  /// A server whose access tokens expire: `access-1` is refused, the refresh
  /// endpoint hands out `access-2` after [refreshDelay], and `access-2` works.
  Responder expiringServer({
    Duration refreshDelay = Duration.zero,
    ResponseBody Function()? refreshAnswer,
  }) {
    return (RequestOptions request) async {
      if (request.path == _refreshPath) {
        await Future<void>.delayed(refreshDelay);
        return refreshAnswer?.call() ??
            jsonResponse(<String, Object?>{
              'data': <String, Object?>{
                'accessToken': 'access-2',
                'refreshToken': 'refresh-2',
              },
            });
      }
      if (request.headers['Authorization'] == 'Bearer access-2') {
        return jsonResponse(<String, Object?>{
          'data': <String, Object?>{'path': request.path},
        });
      }
      return errorResponse(401, ApiErrorCode.authTokenExpired);
    };
  }

  group('ApiClient requests', () {
    setUp(() => start(languageCode: 'ar'));

    test('unwrap the envelope to its data', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{
            'data': <Object?>[1, 2, 3],
            'meta': <String, Object?>{'total': 3},
          });

      expect(await client.get('/wilayas'), <Object?>[1, 2, 3]);
    });

    test('hand back a body that has no envelope as it is', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{'status': 'ok'});

      expect(await client.get('/health'), <String, Object?>{'status': 'ok'});
    });

    test("carry the app's language, so the server translates its messages",
        () async {
      await client.get('/me');

      expect(adapter.requests.single.headers['Accept-Language'], 'ar');
    });

    test('carry the bearer token on a private request', () async {
      await client.get('/me');

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('leave the token off a public one', () async {
      await client.post('/app/auth/login', body: <String, Object?>{}, isPublic: true);

      expect(adapter.requests.single.headers['Authorization'], isNull);
    });
  });

  group('ApiClient failures', () {
    setUp(start);

    test('turn the error envelope into an ApiFailure', () async {
      adapter.respond = (RequestOptions request) async => errorResponse(
            429,
            ApiErrorCode.rateLimited,
            message: 'Too many attempts.',
            details: <String, Object?>{'retryAfterSeconds': 30},
          );

      await expectLater(
        client.post('/app/auth/forgot-password', isPublic: true),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.statusCode, 'statusCode', 429)
              .having((ApiFailure f) => f.code, 'code', 'RATE_LIMITED')
              .having((ApiFailure f) => f.message, 'message',
                  'Too many attempts.')
              .having((ApiFailure f) => f.retryAfterSeconds,
                  'retryAfterSeconds', 30)
              .having((ApiFailure f) => f.fieldErrors, 'fieldErrors', isEmpty),
        ),
      );
    });

    test('read a list of details as per-field errors', () async {
      adapter.respond = (RequestOptions request) async => errorResponse(
            400,
            ApiErrorCode.validationFailed,
            details: <Object?>[
              <String, Object?>{
                'field': 'email',
                'code': 'isEmail',
                'message': 'Not an email.',
              },
              <String, Object?>{'field': 'phone'},
              // Anything that is not an object is skipped, not fatal.
              'garbage',
            ],
          );

      await expectLater(
        client.post('/app/auth/register', isPublic: true),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.details, 'details', isNull)
              .having(
                (ApiFailure f) => f.fieldErrors
                    .map((FieldError e) => '${e.field}/${e.code}/${e.message}')
                    .toList(),
                'fieldErrors',
                <String>['email/isEmail/Not an email.', 'phone//'],
              ),
        ),
      );
    });

    test('report no answer at all as a NetworkFailure', () async {
      adapter.respond = (RequestOptions request) async => noAnswer(request);

      await expectLater(client.get('/me'), throwsA(isA<NetworkFailure>()));
    });

    test('report an answer that is not the envelope as unexpected', () async {
      // A proxy's HTML error page, say — nothing the app can read a code from.
      adapter.respond = (RequestOptions request) async =>
          ResponseBody.fromString(
            '<html>Bad gateway</html>',
            502,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>['text/html'],
            },
          );

      await expectLater(client.get('/me'), throwsA(isA<UnexpectedFailure>()));
    });

    test('do not renew the session for a public request', () async {
      // A wrong password is a 401 too, and must not be mistaken for an
      // expired session.
      adapter.respond = (RequestOptions request) async =>
          errorResponse(401, ApiErrorCode.invalidCredentials);

      await expectLater(
        client.post('/app/auth/login', isPublic: true),
        throwsA(isA<ApiFailure>().having(
          (ApiFailure f) => f.code,
          'code',
          ApiErrorCode.invalidCredentials,
        )),
      );
      expect(adapter.requestsTo(_refreshPath), isEmpty);
    });
  });

  group('ApiClient session renewal', () {
    setUp(start);

    test('refreshes on a 401 and retries with the new token', () async {
      adapter.respond = expiringServer();

      expect(await client.get('/me'), <String, Object?>{'path': '/me'});

      final List<RequestOptions> refreshes = adapter.requestsTo(_refreshPath);
      expect(refreshes, hasLength(1));
      expect(
        refreshes.single.data,
        <String, Object?>{'refreshToken': 'refresh-1'},
      );
      // The refresh itself goes out without the dead bearer token.
      expect(refreshes.single.headers['Authorization'], isNull);
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer access-2',
      );
    });

    test('stores the rotated pair, in memory and in the keychain', () async {
      adapter.respond = expiringServer();

      await client.get('/me');

      expect(tokens.accessToken, 'access-2');
      expect(tokens.refreshToken, 'refresh-2');
      expect(keychain[_accessKey], 'access-2');
      expect(keychain[_refreshKey], 'refresh-2');
    });

    test('shares one refresh between requests that fail together', () async {
      // The refresh token is single-use: a second refresh racing the first
      // would replay a rotated token and get the whole session revoked.
      adapter.respond = expiringServer(
        refreshDelay: const Duration(milliseconds: 30),
      );

      final List<Object?> results = await Future.wait(<Future<Object?>>[
        client.get('/me'),
        client.get('/bookings'),
      ]);

      expect(adapter.requestsTo(_refreshPath), hasLength(1));
      expect(results, <Object?>[
        <String, Object?>{'path': '/me'},
        <String, Object?>{'path': '/bookings'},
      ]);
    });

    test('refreshes again for a later expiry, once the first is done',
        () async {
      adapter.respond = expiringServer();
      await client.get('/me');

      // The new token expires in turn.
      adapter.respond = (RequestOptions request) async {
        if (request.path == _refreshPath) {
          return jsonResponse(<String, Object?>{
            'data': <String, Object?>{
              'accessToken': 'access-3',
              'refreshToken': 'refresh-3',
            },
          });
        }
        return request.headers['Authorization'] == 'Bearer access-3'
            ? jsonResponse(<String, Object?>{'data': 'fine'})
            : errorResponse(401, ApiErrorCode.authTokenExpired);
      };

      expect(await client.get('/me'), 'fine');
      expect(adapter.requestsTo(_refreshPath), hasLength(2));
    });

    test('retries at most once', () async {
      // Even a freshly issued token being refused must not loop.
      adapter.respond = expiringServer();
      final Responder base = adapter.respond;
      adapter.respond = (RequestOptions request) async =>
          request.path == _refreshPath
              ? base(request)
              : errorResponse(401, ApiErrorCode.authTokenExpired);

      await expectLater(client.get('/me'), throwsA(isA<ApiFailure>()));
      expect(adapter.requestsTo(_refreshPath), hasLength(1));
      expect(adapter.requestsTo('/me'), hasLength(2));
    });

    test('ends the session when the refresh token is refused', () async {
      adapter.respond = expiringServer(
        refreshAnswer: () =>
            errorResponse(401, ApiErrorCode.authRefreshInvalid),
      );

      await expectLater(
        client.get('/me'),
        throwsA(isA<SessionExpiredFailure>()),
      );
      expect(expiredCalls, 1);
      expect(tokens.accessToken, isNull);
      expect(tokens.refreshToken, isNull);
      expect(keychain, isEmpty);
    });

    test('ends it only once when several requests were waiting', () async {
      adapter.respond = expiringServer(
        refreshDelay: const Duration(milliseconds: 30),
        refreshAnswer: () =>
            errorResponse(401, ApiErrorCode.authSessionRevoked),
      );

      final List<Object?> outcomes = await Future.wait(<Future<Object?>>[
        client.get('/me').catchError((Object error) => error),
        client.get('/bookings').catchError((Object error) => error),
      ]);

      expect(outcomes, everyElement(isA<SessionExpiredFailure>()));
      expect(adapter.requestsTo(_refreshPath), hasLength(1));
      expect(expiredCalls, 1);
    });

    test('keeps the session when the refresh gets no answer', () async {
      // Offline is not the session's fault: signing the user out for it
      // would be wrong.
      adapter.respond = (RequestOptions request) async =>
          request.path == _refreshPath
              ? noAnswer(request)
              : errorResponse(401, ApiErrorCode.authTokenExpired);

      // A connection problem, not the stale 401 the request first got.
      await expectLater(client.get('/me'), throwsA(isA<NetworkFailure>()));
      expect(expiredCalls, 0);
      expect(tokens.refreshToken, 'refresh-1');
      expect(keychain[_refreshKey], 'refresh-1');
    });
  });

  group('ApiClient without a session', () {
    setUp(() => start(signedIn: false));

    test('reports a 401 as an ended session, without trying to refresh',
        () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(401, ApiErrorCode.authTokenMissing);

      await expectLater(
        client.get('/me'),
        throwsA(isA<SessionExpiredFailure>()),
      );
      expect(adapter.requestsTo(_refreshPath), isEmpty);
      expect(adapter.requests.single.headers['Authorization'], isNull);
    });

    test('has nothing to restore', () async {
      expect(await client.restoreSession(), isFalse);
      expect(adapter.requests, isEmpty);
    });
  });

  group('ApiClient.restoreSession', () {
    setUp(start);

    test('renews a stored session', () async {
      adapter.respond = expiringServer();

      expect(await client.restoreSession(), isTrue);
      expect(tokens.accessToken, 'access-2');
    });

    test('reports a refused one', () async {
      adapter.respond = expiringServer(
        refreshAnswer: () =>
            errorResponse(401, ApiErrorCode.authRefreshInvalid),
      );

      expect(await client.restoreSession(), isFalse);
      expect(tokens.refreshToken, isNull);
    });
  });

  group('ApiClient with an access token about to expire', () {
    /// A JWT whose `exp` is [secondsFromNow] away. Only the payload matters.
    String jwt(int secondsFromNow) {
      final int exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + secondsFromNow;
      String part(Map<String, Object?> json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      return '${part(<String, Object?>{'alg': 'HS256'})}.'
          '${part(<String, Object?>{'sub': 'u', 'exp': exp})}.sig';
    }

    Future<void> startWith(String accessToken) async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        _accessKey: accessToken,
        _refreshKey: 'refresh-1',
      });
      tokens = TokenStore();
      await tokens.load();
      adapter = ScriptedAdapter((RequestOptions request) async {
        if (request.path == _refreshPath) {
          return jsonResponse(<String, Object?>{
            'data': <String, Object?>{
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
            },
          });
        }
        return jsonResponse(<String, Object?>{
          'data': <String, Object?>{'auth': request.headers['Authorization']},
        });
      });
      client = scriptedClient(adapter, tokens);
    }

    test('renews it before a signed-in call', () async {
      // Public catalog routes treat an expired token as no token at all —
      // no 401 would ever trigger the refresh, and every heart would read
      // empty. So it is renewed before it is sent.
      await startWith(jwt(-60));

      final Object? data = await client.get('/app/services');

      expect(adapter.requests.first.path, _refreshPath);
      expect(data, <String, Object?>{'auth': 'Bearer access-2'});
    });

    test('renews it when it has seconds left', () async {
      await startWith(jwt(10));

      await client.get('/app/services');

      expect(adapter.requestsTo(_refreshPath), hasLength(1));
    });

    test('leaves a fresh one alone', () async {
      await startWith(jwt(600));

      await client.get('/app/services');

      expect(adapter.requestsTo(_refreshPath), isEmpty);
    });

    test('never renews for a public call', () async {
      await startWith(jwt(-60));

      await client.get('/app/wilayas', isPublic: true);

      expect(adapter.requestsTo(_refreshPath), isEmpty);
    });
  });

  group('ApiClient pages', () {
    setUp(start);

    Responder pageOf(List<Object?> items, {int page = 1, int totalPages = 3}) =>
        (RequestOptions request) async => jsonResponse(<String, Object?>{
              'data': items,
              'meta': <String, Object?>{
                'page': page,
                'limit': 20,
                'total': 41,
                'totalPages': totalPages,
              },
            });

    test('keep the items and the paging meta', () async {
      adapter.respond = pageOf(<Object?>[
        <String, Object?>{'id': 'a'},
        <String, Object?>{'id': 'b'},
      ]);

      final ApiPage<Map<String, Object?>> page =
          await client.getPage('/app/services');

      expect(page.items.map((Map<String, Object?> item) => item['id']),
          <Object?>['a', 'b']);
      expect(page.page, 1);
      expect(page.totalPages, 3);
      expect(page.total, 41);
      expect(page.hasMore, isTrue);
    });

    test('have no more on the last page', () async {
      adapter.respond = pageOf(<Object?>[], page: 3);

      expect((await client.getPage('/app/services')).hasMore, isFalse);
    });

    test('have no more when the result is empty', () async {
      // An empty result comes back with totalPages 0.
      adapter.respond = pageOf(<Object?>[], totalPages: 0);

      final ApiPage<Map<String, Object?>> page =
          await client.getPage('/app/services');

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('send a list parameter as the key repeated', () async {
      // The API rejects `wilaya=16,31` and `wilaya[]=16`.
      adapter.respond = pageOf(<Object?>[]);

      await client.getPage(
        '/app/services',
        query: <String, Object?>{
          'wilaya': <int>[16, 31],
        },
      );

      expect(
        adapter.requests.single.uri.query,
        'wilaya=16&wilaya=31',
      );
    });

    test('map their items', () async {
      adapter.respond = pageOf(<Object?>[
        <String, Object?>{'id': 'a'},
      ]);

      final ApiPage<String> page = (await client.getPage('/app/services'))
          .map((Map<String, Object?> item) => item['id']! as String);

      expect(page.items, <String>['a']);
      expect(page.total, 41);
    });
  });

  group('ApiClient.getEnvelope', () {
    setUp(start);

    test('returns the envelope whole, with a meta getPage cannot read',
        () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{
            'data': <Object?>[
              <String, Object?>{'id': 'm-1'},
            ],
            'meta': <String, Object?>{
              'limit': 30,
              'hasMore': true,
              'nextBefore': 'm-1',
            },
          });

      final Map<String, Object?> envelope = await client.getEnvelope(
        '/app/conversations/c-1/messages',
        query: <String, Object?>{'before': 'm-9'},
      );

      expect(envelope, <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'id': 'm-1'},
        ],
        'meta': <String, Object?>{
          'limit': 30,
          'hasMore': true,
          'nextBefore': 'm-1',
        },
      });
      expect(adapter.requests.single.uri.query, 'before=m-9');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
    });

    test('turns a 403 into its ApiFailure', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(403, ApiErrorCode.notAParticipant);

      await expectLater(
        client.getEnvelope('/app/conversations/c-1/messages'),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.code, 'code',
                  ApiErrorCode.notAParticipant)
              .having((ApiFailure f) => f.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('wraps a bare body as data', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<Object?>[1, 2]);

      expect(
        await client.getEnvelope('/app/health'),
        <String, Object?>{'data': <Object?>[1, 2]},
      );
    });
  });

  group('ApiClient deletes', () {
    setUp(start);

    test('go out as DELETE with the token, and accept a 204', () async {
      adapter.respond = (RequestOptions request) async =>
          ResponseBody.fromString('', 204);

      await client.delete('/app/me/favourites/f-1');

      final RequestOptions request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/app/me/favourites/f-1');
      expect(request.headers['Authorization'], 'Bearer access-1');
    });

    test('turn a 404 into its code', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(404, ApiErrorCode.favouriteNotFound);

      await expectLater(
        client.delete('/app/me/favourites/gone'),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.code, 'code',
                  ApiErrorCode.favouriteNotFound),
        ),
      );
    });
  });
}
