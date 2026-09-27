import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/failure.dart';
import '../session/token_store.dart';
import 'api_page.dart';

export 'api_page.dart';

/// Where the API lives.
abstract final class ApiConfig {
  /// The live backend. One environment for now; a `--dart-define` can
  /// override it for a staging server without touching code.
  static const String baseUrl = String.fromEnvironment(
    'EVENTOR_API_URL',
    defaultValue: 'https://api.eventor.72-60-190-211.sslip.io/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Uploads carry up to 5 MB over a phone connection.
  static const Duration sendTimeout = Duration(seconds: 60);
}

/// The one door to the backend.
///
/// Every call returns the envelope's `data` already unwrapped, and every
/// failure arrives as a [Failure] — an [ApiFailure] carrying the server's
/// stable `code`, a [NetworkFailure] when there was no answer, or a
/// [SessionExpiredFailure] when the session could not be renewed. Nothing
/// above this class ever sees a [DioException].
///
/// It also owns the session plumbing, so repositories never think about it:
///
/// * the bearer token goes on every request that has one;
/// * `Accept-Language` follows the app's language, because the server
///   translates its messages by it;
/// * a 401 for an expired access token triggers **one** refresh, shared by
///   every request that failed while it ran — the refresh token is single-use
///   and replaying a rotated one revokes the whole session, so two refreshes
///   racing each other would sign the user out.
class ApiClient {
  ApiClient({
    required this._tokens,
    required this._languageCode,
    Dio? dio,
  })  : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(onRequest: _onRequest),
    );
  }

  final Dio _dio;
  final TokenStore _tokens;
  final String Function() _languageCode;

  /// The refresh in flight, if any. Everyone who needs a fresh token while it
  /// runs awaits this same future instead of starting their own.
  Future<bool>? _refreshing;

  /// Called when the session is gone for good — the refresh token itself was
  /// refused. The session controller listens and signs the user out.
  VoidCallback? onSessionExpired;

  /// Marks a request that must go out without a bearer token and must not
  /// trigger a refresh — the auth endpoints themselves.
  static const String _publicKey = 'eventor.public';

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Accept-Language'] = _languageCode();
    final String? token = _tokens.accessToken;
    if (token != null && options.extra[_publicKey] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    bool isPublic = false,
  }) {
    return _send(
      () => _dio.get<Object?>(
        path,
        queryParameters: query,
        options: _options(isPublic),
      ),
      isPublic: isPublic,
    );
  }

  Future<Object?> post(
    String path, {
    Object? body,
    bool isPublic = false,
  }) {
    return _send(
      () => _dio.post<Object?>(path, data: body, options: _options(isPublic)),
      isPublic: isPublic,
    );
  }

  /// A list endpoint, keeping the paging `meta` that [get] discards.
  ///
  /// A `List` value in [query] goes out as the key repeated —
  /// `wilaya=16&wilaya=31` — the only form the API accepts.
  Future<ApiPage<Map<String, Object?>>> getPage(
    String path, {
    Map<String, Object?>? query,
    bool isPublic = false,
  }) async {
    final Object? body = await _send(
      () => _dio.get<Object?>(
        path,
        queryParameters: query,
        options: _options(isPublic).copyWith(listFormat: ListFormat.multi),
      ),
      isPublic: isPublic,
      unwrap: false,
    );
    return _toPage(body);
  }

  Future<void> delete(String path) async {
    await _send(
      () => _dio.delete<Object?>(path, options: _options(false)),
      isPublic: false,
    );
  }

  Future<Object?> patch(String path, {Object? body}) {
    return _send(
      () => _dio.patch<Object?>(path, data: body, options: _options(false)),
      isPublic: false,
    );
  }

  /// A multipart upload, reporting progress from 0 to 1.
  Future<Object?> upload(
    String path, {
    required FormData Function() form,
    ValueChanged<double>? onProgress,
  }) {
    return _send(
      () => _dio.post<Object?>(
        path,
        // Built fresh per attempt: a FormData stream can only be read once,
        // and a retry after a refresh needs to read it again.
        data: form(),
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress == null
            ? null
            : (int sent, int total) {
                if (total > 0) onProgress(sent / total);
              },
      ),
      isPublic: false,
    );
  }

  Options _options(bool isPublic) => Options(
        extra: <String, Object?>{_publicKey: isPublic},
      );

  /// Runs [request], renewing the session once if the access token has
  /// expired, and turns the result into `data` or a [Failure].
  Future<Object?> _send(
    Future<Response<Object?>> Function() request, {
    required bool isPublic,
    bool unwrap = true,
  }) async {
    Object? handle(Response<Object?> response) =>
        unwrap ? _unwrap(response.data) : response.data;

    if (!isPublic) await _renewIfExpiring();

    try {
      return handle(await request());
    } on DioException catch (error) {
      final bool canRenew = !isPublic &&
          error.response?.statusCode == 401 &&
          _tokens.refreshToken != null;

      if (canRenew) {
        // Retried at most once: a second 401 falls through to the failure
        // below rather than looping.
        if (await _renewSession()) {
          try {
            return handle(await request());
          } on DioException catch (retryError) {
            throw _toFailure(retryError);
          }
        }
        // The refresh got no answer at all — the tokens are still there, so
        // the session is fine and the connection is not. Say so, rather than
        // passing on the stale 401.
        if (_tokens.refreshToken != null) throw NetworkFailure(cause: error);
      }
      throw _toFailure(error);
    }
  }

  /// `{data}` and `{data, meta}` both unwrap to `data`; a 204 has none.
  Object? _unwrap(Object? body) {
    if (body is Map<String, Object?> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  /// How close to expiry a token is renewed ahead of a call.
  static const Duration _expiryMargin = Duration(seconds: 30);

  /// Renews the session before a signed-in call if the access token has
  /// expired or is about to.
  ///
  /// The 401-then-refresh path in [_send] is not enough on its own: the
  /// catalog routes are public, and the server treats an expired token there
  /// as no token at all — it answers 200 with every `isFavourite` false, so
  /// no 401 ever comes back to trigger a refresh.
  Future<void> _renewIfExpiring() async {
    final String? token = _tokens.accessToken;
    if (token == null || _tokens.refreshToken == null) return;
    final DateTime? expiry = _expiryOf(token);
    if (expiry == null) return;
    if (DateTime.now().add(_expiryMargin).isBefore(expiry)) return;
    // A failed renewal is reported by the call itself, which then goes out
    // with the old token as before.
    await _renewSession();
  }

  /// The `exp` claim of a JWT, or `null` for anything that is not one.
  static DateTime? _expiryOf(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final Object? payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final Object? exp = payload is Map<String, Object?> ? payload['exp'] : null;
      return exp is num
          ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
          : null;
    } on FormatException {
      return null;
    }
  }

  /// `{data: [...], meta: {page, totalPages, total}}` as an [ApiPage]. A
  /// missing `meta` reads as a single complete page, so a list endpoint that
  /// stops paging does not break the screens on top of it.
  ApiPage<Map<String, Object?>> _toPage(Object? body) {
    final Object? data =
        body is Map<String, Object?> ? body['data'] : body;
    final List<Map<String, Object?>> items = data is List<Object?>
        ? data.whereType<Map<String, Object?>>().toList()
        : <Map<String, Object?>>[];
    final Object? meta = body is Map<String, Object?> ? body['meta'] : null;
    if (meta is! Map<String, Object?>) {
      return ApiPage<Map<String, Object?>>(
        items: items,
        page: 1,
        totalPages: 1,
        total: items.length,
      );
    }
    int read(String key) => (meta[key] as num?)?.toInt() ?? 0;
    return ApiPage<Map<String, Object?>>(
      items: items,
      page: read('page'),
      totalPages: read('totalPages'),
      total: read('total'),
    );
  }

  /// Renews the access token with the stored refresh token. `true` when a new
  /// pair was stored. Single-flight — see the class comment.
  Future<bool> _renewSession() {
    return _refreshing ??= _doRenew().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRenew() async {
    final String? refreshToken = _tokens.refreshToken;
    if (refreshToken == null) return false;

    try {
      final Response<Object?> response = await _dio.post<Object?>(
        '/app/auth/refresh',
        data: <String, Object?>{'refreshToken': refreshToken},
        options: _options(true),
      );
      final Object? data = _unwrap(response.data);
      if (data is! Map<String, Object?>) return false;
      await _tokens.save(
        accessToken: data['accessToken']! as String,
        refreshToken: data['refreshToken']! as String,
      );
      return true;
    } on DioException catch (error) {
      // No answer at all is not the session's fault: keep it, and let the
      // original request fail as a network error.
      if (error.response == null) return false;
      await _tokens.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  /// Renews the session on demand — the app start, restoring a stored one.
  /// Returns `false` when there is nothing to restore or it was refused.
  Future<bool> restoreSession() => _renewSession();

  Failure _toFailure(DioException error) {
    final Response<Object?>? response = error.response;
    if (response == null) return NetworkFailure(cause: error);

    final Object? body = response.data;
    if (body is! Map<String, Object?> || body['code'] is! String) {
      return UnexpectedFailure(cause: error);
    }

    final String code = body['code']! as String;
    final int status = response.statusCode ?? 0;

    if (status == 401 && _isSessionCode(code) && _tokens.refreshToken == null) {
      return SessionExpiredFailure(cause: error);
    }

    final Object? details = body['details'];
    return ApiFailure(
      statusCode: status,
      code: code,
      message: body['message'] as String? ?? '',
      details: details is Map<String, Object?> ? details : null,
      fieldErrors: details is List<Object?>
          ? details
              .whereType<Map<String, Object?>>()
              .map(
                (Map<String, Object?> field) => FieldError(
                  field: field['field'] as String? ?? '',
                  code: field['code'] as String? ?? '',
                  message: field['message'] as String? ?? '',
                ),
              )
              .toList()
          : const <FieldError>[],
      cause: error,
    );
  }

  static bool _isSessionCode(String code) => const <String>{
        ApiErrorCode.authTokenMissing,
        ApiErrorCode.authTokenInvalid,
        ApiErrorCode.authTokenExpired,
        ApiErrorCode.authSessionRevoked,
        ApiErrorCode.authRefreshInvalid,
      }.contains(code);
}
