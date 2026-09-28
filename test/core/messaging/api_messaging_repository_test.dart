import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/conversation_filter.dart';
import 'package:eventor/core/messaging/messaging_repository.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../network/scripted_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late ApiMessagingRepository messaging;

  /// A minimal, valid message envelope — the shape `sendText`/`sendPhoto`/
  /// `sendDisputeText` get back, with room to override a field or two.
  Map<String, Object?> messageJson({
    String id = 'm-new',
    String kind = 'text',
    String? imageUrl,
  }) =>
      <String, Object?>{
        'data': <String, Object?>{
          'id': id,
          'conversationId': 'c-1',
          'kind': kind,
          'senderId': 'u-me',
          'mine': true,
          'body': 'hi',
          'masked': false,
          'imageUrl': imageUrl,
          'imageLargeUrl': imageUrl,
          'createdAt': '2026-03-12T09:20:00.000Z',
        },
      };

  Future<ResponseBody> server(RequestOptions request) async {
    if (request.method == 'GET' && request.path == '/app/conversations') {
      return jsonResponse(fixture('conversations_page.json', dir: 'messaging'));
    }
    if (request.method == 'GET' && request.path == '/app/conversations/c-1') {
      return jsonResponse(fixture('conversation_detail.json', dir: 'messaging'));
    }
    if (request.method == 'GET' &&
        request.path == '/app/conversations/c-1/messages') {
      return jsonResponse(fixture('messages_page.json', dir: 'messaging'));
    }
    if (request.method == 'POST') return jsonResponse(messageJson());
    return errorResponse(404, 'NOT_FOUND');
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'eventor.access_token': 'access-1',
      'eventor.refresh_token': 'refresh-1',
    });
    final TokenStore tokens = TokenStore();
    await tokens.load();
    adapter = ScriptedAdapter(server);
    messaging = ApiMessagingRepository(scriptedClient(adapter, tokens));
  });

  RequestOptions lastRequest() => adapter.requests.last;

  /// A JSON request body, whether dio handed the adapter the encoded string
  /// or the raw map.
  Map<String, Object?> bodyOf(RequestOptions request) {
    final Object? data = request.data;
    return (data is String ? jsonDecode(data) : data)! as Map<String, Object?>;
  }

  group('ApiMessagingRepository.conversations', () {
    test('sends the page and limit only, by default', () async {
      final ApiPage<ConversationRow> page = await messaging.conversations();

      expect(lastRequest().path, '/app/conversations');
      expect(lastRequest().uri.queryParameters, <String, String>{
        'page': '1',
        'limit': '20',
      });
      expect(page.items, hasLength(5));
    });

    test('sends the filter and a trimmed query, on a later page', () async {
      await messaging.conversations(
        filter: ConversationFilter.unread,
        q: '  studio ',
        page: 2,
      );

      expect(lastRequest().uri.queryParameters, <String, String>{
        'filter': 'unread',
        'q': 'studio',
        'page': '2',
        'limit': '20',
      });
    });

    test('never sends a blank query', () async {
      await messaging.conversations(q: '   ');

      expect(lastRequest().uri.queryParameters.containsKey('q'), isFalse);
    });
  });

  test('conversation opens a thread by id', () async {
    final ConversationDetail detail = await messaging.conversation('c-1');

    expect(lastRequest().path, '/app/conversations/c-1');
    expect(detail.id, 'c-lumiere');
  });

  group('ApiMessagingRepository.messages', () {
    test('sends before with no limit, and parses the page', () async {
      final MessagePage page = await messaging.messages('c-1', before: 'm-9');

      expect(lastRequest().path, '/app/conversations/c-1/messages');
      expect(lastRequest().uri.queryParameters, <String, String>{'before': 'm-9'});
      expect(page.items, hasLength(6));
      expect(page.hasMore, isTrue);
      expect(page.nextBefore, 'm-1');
    });

    test('omits before on the first page', () async {
      await messaging.messages('c-1');

      expect(lastRequest().uri.queryParameters, isEmpty);
    });
  });

  test('sendText posts the body', () async {
    final ChatMessage message = await messaging.sendText('c-1', 'Hello');

    expect(lastRequest().method, 'POST');
    expect(lastRequest().path, '/app/conversations/c-1/messages');
    expect(bodyOf(lastRequest()), <String, Object?>{'body': 'Hello'});
    expect(message.id, 'm-new');
  });

  group('ApiMessagingRepository.sendPhoto', () {
    test('posts multipart with the image and a caption', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(messageJson(kind: 'attachment', imageUrl: 'https://files.example/i.jpg'));

      final ChatMessage message = await messaging.sendPhoto(
        'c-1',
        PickedImage(name: 'image.jpg', bytes: Uint8List.fromList(<int>[1, 2, 3]), extension: 'jpg'),
        caption: '  a caption  ',
      );

      expect(lastRequest().path, '/app/conversations/c-1/messages');
      final FormData form = lastRequest().data as FormData;
      expect(form.files, hasLength(1));
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'image.jpg');
      expect(form.fields, <MapEntry<String, String>>[
        const MapEntry<String, String>('body', 'a caption'),
      ]);
      expect(message.kind, MessageKind.attachment);
      expect(message.hasImage, isTrue);
    });

    test('omits the caption field when it is blank', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(messageJson(kind: 'attachment', imageUrl: 'https://files.example/i.jpg'));

      await messaging.sendPhoto(
        'c-1',
        PickedImage(name: 'image.jpg', bytes: Uint8List.fromList(<int>[1, 2, 3]), extension: 'jpg'),
        caption: '   ',
      );

      final FormData form = lastRequest().data as FormData;
      expect(form.fields, isEmpty);
    });
  });

  test('sendDisputeText posts to the dispute\'s own route', () async {
    await messaging.sendDisputeText('d-2041', 'x');

    expect(lastRequest().path, '/app/disputes/d-2041/messages');
    expect(bodyOf(lastRequest()), <String, Object?>{'body': 'x'});
  });

  test('start posts exactly userId and body, and returns the detail', () async {
    adapter.respond = (RequestOptions request) async =>
        jsonResponse(fixture('conversation_detail.json', dir: 'messaging'));

    final ConversationDetail detail = await messaging.start('p-1', 'Hello');

    expect(lastRequest().path, '/app/conversations');
    expect(bodyOf(lastRequest()), <String, Object?>{'userId': 'p-1', 'body': 'Hello'});
    expect(detail.id, 'c-lumiere');
  });

  test('markRead posts with no body', () async {
    adapter.respond = (RequestOptions request) async => ResponseBody.fromString('', 204);

    await messaging.markRead('c-1');

    expect(lastRequest().method, 'POST');
    expect(lastRequest().path, '/app/conversations/c-1/read');
    expect(lastRequest().data, isNull);
  });

  group('ApiMessagingRepository.reportMessage', () {
    test('posts the reason and returns created', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{'data': <String, Object?>{'created': true}});

      final bool created = await messaging.reportMessage(
        'm-4',
        ReportReason.contactOutside,
        null,
      );

      expect(lastRequest().path, '/app/messages/m-4/report');
      expect(bodyOf(lastRequest()), <String, Object?>{'reason': 'contact_outside'});
      expect(created, isTrue);
    });

    test('sends a trimmed note only when it is non-blank', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{'data': <String, Object?>{'created': true}});

      await messaging.reportMessage('m-4', ReportReason.spam, '  looks fake  ');
      expect(bodyOf(lastRequest()), <String, Object?>{
        'reason': 'spam',
        'note': 'looks fake',
      });

      await messaging.reportMessage('m-4', ReportReason.spam, '   ');
      expect(bodyOf(lastRequest()), <String, Object?>{'reason': 'spam'});
    });
  });

  test('reportUser posts the target and reason', () async {
    adapter.respond = (RequestOptions request) async =>
        jsonResponse(<String, Object?>{'data': <String, Object?>{'created': true}});

    final bool created = await messaging.reportUser(
      'p-1',
      ReportReason.harassment,
      null,
    );

    expect(lastRequest().path, '/app/reports');
    expect(bodyOf(lastRequest()), <String, Object?>{
      'targetType': 'user',
      'targetId': 'p-1',
      'reason': 'harassment',
    });
    expect(created, isTrue);
  });

  group('ApiMessagingRepository.findWith', () {
    Map<String, Object?> rowJson({
      required String id,
      required String kind,
      required String otherId,
      String name = 'Salle Yasmine',
    }) =>
        <String, Object?>{
          'id': id,
          'kind': kind,
          'status': 'open',
          'other': <String, Object?>{
            'id': otherId,
            'name': name,
            'avatarUrl': null,
            'role': 'provider',
            'blocked': false,
          },
          'lastMessage': null,
          'lastMessageAt': null,
          'unreadCount': 0,
          'booking': null,
          'canWrite': true,
        };

    Future<ResponseBody> pageOf(List<Map<String, Object?>> rows) async =>
        jsonResponse(<String, Object?>{
          'data': rows,
          'meta': <String, Object?>{'page': 1, 'limit': 20, 'total': rows.length, 'totalPages': 1},
        });

    test('asks for the chat with that user and returns it', () async {
      adapter.respond = (RequestOptions request) async => pageOf(<Map<String, Object?>>[
            rowJson(id: 'c-a', kind: 'direct', otherId: 'p-yasmine'),
          ]);

      final ConversationRow? row = await messaging.findWith('p-yasmine');

      expect(lastRequest().uri.queryParameters['userId'], 'p-yasmine');
      expect(lastRequest().uri.queryParameters['q'], isNull);
      expect(row?.id, 'c-a');
    });

    test('returns null when there is no chat with that user', () async {
      adapter.respond = (RequestOptions request) async => pageOf(<Map<String, Object?>>[]);

      expect(await messaging.findWith('p-yasmine'), isNull);
    });

    test('does not return a dispute row with the same other id', () async {
      adapter.respond = (RequestOptions request) async => pageOf(<Map<String, Object?>>[
            rowJson(id: 'c-dispute', kind: 'dispute', otherId: 'p-yasmine'),
          ]);

      final ConversationRow? row = await messaging.findWith('p-yasmine');

      expect(row, isNull);
    });
  });

  group('ApiMessagingRepository errors', () {
    test('surfaces a 409 CONVERSATION_CLOSED on send', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(409, ApiErrorCode.conversationClosed);

      await expectLater(
        messaging.sendText('c-1', 'x'),
        throwsA(isA<ApiFailure>()
            .having((ApiFailure f) => f.code, 'code', ApiErrorCode.conversationClosed)
            .having((ApiFailure f) => f.statusCode, 'statusCode', 409)),
      );
    });

    test('surfaces a 403 CONVERSATION_CLOSED on send', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(403, ApiErrorCode.conversationClosed);

      await expectLater(
        messaging.sendDisputeText('d-2041', 'x'),
        throwsA(isA<ApiFailure>()
            .having((ApiFailure f) => f.code, 'code', ApiErrorCode.conversationClosed)
            .having((ApiFailure f) => f.statusCode, 'statusCode', 403)),
      );
    });

    test('surfaces a 403 NOT_A_PARTICIPANT on conversation', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(403, ApiErrorCode.notAParticipant);

      await expectLater(
        messaging.conversation('c-1'),
        throwsA(isA<ApiFailure>()
            .having((ApiFailure f) => f.code, 'code', ApiErrorCode.notAParticipant)),
      );
    });
  });
}
