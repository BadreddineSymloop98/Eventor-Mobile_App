import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/session/token_store.dart';

/// Answers one request. Throw from it to simulate no answer at all.
typedef Responder = Future<ResponseBody> Function(RequestOptions request);

/// A [HttpClientAdapter] that never touches the network: every request is
/// recorded and answered by [respond], which a test can swap at any point.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.respond);

  Responder respond;

  /// Every request that reached the wire, in order.
  final List<RequestOptions> requests = <RequestOptions>[];

  /// The requests made to [path].
  List<RequestOptions> requestsTo(String path) => requests
      .where((RequestOptions request) => request.path == path)
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// [body] as a JSON response with [status].
ResponseBody jsonResponse(Object? body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// The API's error envelope.
ResponseBody errorResponse(
  int status,
  String code, {
  String message = 'Server says no.',
  Object? details,
}) {
  return jsonResponse(
    <String, Object?>{
      'code': code,
      'message': message,
      'details': ?details,
    },
    status: status,
  );
}

/// No answer at all — what a dropped connection looks like to dio.
Never noAnswer(RequestOptions request) {
  throw DioException(
    requestOptions: request,
    type: DioExceptionType.connectionError,
    message: 'Connection refused',
  );
}

/// An [ApiClient] wired to [adapter] and [tokens].
ApiClient scriptedClient(
  ScriptedAdapter adapter,
  TokenStore tokens, {
  String languageCode = 'en',
}) {
  final Dio dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(tokens: tokens, languageCode: () => languageCode, dio: dio);
}
