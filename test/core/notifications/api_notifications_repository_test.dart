import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/notifications/models/app_notification.dart';
import 'package:eventor/core/notifications/notifications_repository.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../network/scripted_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late ApiNotificationsRepository notifications;

  Future<ResponseBody> server(RequestOptions request) async {
    if (request.method == 'GET' && request.path == '/app/me/notifications') {
      return jsonResponse(fixture('notifications_page.json', dir: 'messaging'));
    }
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
    notifications = ApiNotificationsRepository(scriptedClient(adapter, tokens));
  });

  RequestOptions lastRequest() => adapter.requests.last;

  Map<String, Object?> bodyOf(RequestOptions request) {
    final Object? data = request.data;
    return (data is String ? jsonDecode(data) : data)! as Map<String, Object?>;
  }

  test('list sends the page and limit', () async {
    final ApiPage<AppNotification> page = await notifications.list(page: 2);

    expect(lastRequest().path, '/app/me/notifications');
    expect(lastRequest().uri.queryParameters, <String, String>{
      'page': '2',
      'limit': '20',
    });
    expect(page.items, hasLength(4));
  });

  test('markRead posts the ids and returns the new unread count', () async {
    adapter.respond = (RequestOptions request) async =>
        jsonResponse(<String, Object?>{'data': <String, Object?>{'unread': 3}});

    final int unread = await notifications.markRead(<String>['n-1']);

    expect(lastRequest().method, 'POST');
    expect(lastRequest().path, '/app/me/notifications/read');
    expect(bodyOf(lastRequest()), <String, Object?>{'ids': <String>['n-1']});
    expect(unread, 3);
  });

  test('markAllRead posts all and returns the new unread count', () async {
    adapter.respond = (RequestOptions request) async =>
        jsonResponse(<String, Object?>{'data': <String, Object?>{'unread': 0}});

    final int unread = await notifications.markAllRead();

    expect(lastRequest().path, '/app/me/notifications/read');
    expect(bodyOf(lastRequest()), <String, Object?>{'all': true});
    expect(unread, 0);
  });

  group('ApiNotificationsRepository.counts', () {
    test('reads both badge counts from GET /app/me', () async {
      adapter.respond = (RequestOptions request) async => jsonResponse(<String, Object?>{
            'data': <String, Object?>{
              'unreadNotifications': 5,
              'unreadConversations': 2,
            },
          });

      final ({int notifications, int conversations}) counts =
          await notifications.counts();

      expect(lastRequest().path, '/app/me');
      expect(counts.notifications, 5);
      expect(counts.conversations, 2);
    });

    test('reads a missing field as 0', () async {
      adapter.respond = (RequestOptions request) async =>
          jsonResponse(<String, Object?>{'data': <String, Object?>{'unreadNotifications': 5}});

      final ({int notifications, int conversations}) counts =
          await notifications.counts();

      expect(counts.notifications, 5);
      expect(counts.conversations, 0);
    });
  });
}
