import 'dart:typed_data';

import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/conversation_filter.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/core/notifications/models/app_notification.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_messaging.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expects [call] to fail with the API [code].
Future<void> expectCode(Future<Object?> call, String code) async {
  await expectLater(
    call,
    throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
  );
}

const String lumiereId = '3552815d-6aca-43fc-ace8-0409ee3a762e';
const String douceursId = 'e1ad2116-c6a2-4d3f-a9ea-c4168694f925';
const String replyEn =
    "Thanks for your message — I'll get back to you shortly.";

void main() {
  // A fixed Thursday afternoon, so the seed's relative dates are stable.
  final DateTime now = DateTime(2026, 3, 12, 15);

  late MockBackend backend;
  late MockMessagingStore store;
  late MockMessagingRepository messaging;
  late MockNotificationsRepository notifications;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => now,
    );
    await MockAuthRepository(
      backend,
    ).login(email: 'client@eventor.test', password: MockBackend.seedPassword);
    store = MockMessagingStore(
      backend,
      replyDelay: const Duration(milliseconds: 10),
      languageCode: () => 'en',
    );
    messaging = MockMessagingRepository(store, backend);
    notifications = MockNotificationsRepository(store, backend);
  });

  tearDown(() => store.dispose());

  List<String> ids(ApiPage<ConversationRow> page) =>
      page.items.map((ConversationRow row) => row.id).toList();

  group('conversations', () {
    test(
      '25 rows over two pages, Lumière first, every drawn state present',
      () async {
        final ApiPage<ConversationRow> first = await messaging.conversations();
        final ApiPage<ConversationRow> second = await messaging.conversations(
          page: 2,
        );

        expect(first.items, hasLength(20));
        expect(second.items, hasLength(5));
        expect(first.total, 25);
        expect(first.totalPages, 2);
        expect(first.hasMore, isTrue);
        expect(second.hasMore, isFalse);

        final ConversationRow lumiere = first.items.first;
        expect(lumiere.id, 'mock-chat-lumiere');
        expect(lumiere.other?.name, 'Studio Lumière');
        expect(lumiere.unreadCount, 2);
        expect(lumiere.booking?.reference, 'EVT-000123');

        final List<ConversationRow> all = <ConversationRow>[
          ...first.items,
          ...second.items,
        ];
        expect(all.map((ConversationRow r) => r.id).toSet(), hasLength(25));
        expect(all.where((ConversationRow r) => r.isClosed), hasLength(1));
        expect(
          all.where((ConversationRow r) => r.other?.blocked ?? false),
          hasLength(1),
        );
        expect(all.where((ConversationRow r) => r.other == null), hasLength(1));
        expect(
          all.where((ConversationRow r) => r.kind == ConversationKind.dispute),
          hasLength(1),
        );
        expect(
          all.where((ConversationRow r) => r.kind == ConversationKind.support),
          hasLength(1),
        );
      },
    );

    test('newest first by last message', () async {
      final List<ConversationRow> rows =
          (await messaging.conversations()).items;

      for (int i = 1; i < rows.length; i++) {
        expect(
          rows[i - 1].lastMessageAt!.isBefore(rows[i].lastMessageAt!),
          isFalse,
        );
      }
    });

    test('the unread filter gives exactly Lumière and Djazair', () async {
      expect(
        ids(await messaging.conversations(filter: ConversationFilter.unread)),
        <String>['mock-chat-lumiere', 'mock-chat-djazair'],
      );
    });

    test('the booking filter gives the rows with a booking', () async {
      final ApiPage<ConversationRow> page = await messaging.conversations(
        filter: ConversationFilter.booking,
      );

      expect(ids(page), <String>['mock-chat-lumiere', 'mock-chat-dispute']);
      expect(
        page.items.every((ConversationRow r) => r.booking != null),
        isTrue,
      );
    });

    test('q matches names case-insensitively', () async {
      expect(ids(await messaging.conversations(q: 'yasm')), <String>[
        'mock-chat-yasmine',
      ]);
    });

    test('q finds the group rows by "Eventor support"', () async {
      expect(ids(await messaging.conversations(q: 'eventor SUPPORT')), <String>[
        'mock-chat-dispute',
        'mock-chat-support',
      ]);
    });

    test('an unknown conversation is CONVERSATION_NOT_FOUND', () async {
      await expectCode(
        messaging.conversation('nope'),
        ApiErrorCode.conversationNotFound,
      );
      await expectCode(
        messaging.messages('nope'),
        ApiErrorCode.conversationNotFound,
      );
    });

    test('findWith returns the direct row with that provider', () async {
      final ConversationRow? row = await messaging.findWith(lumiereId);

      expect(row?.id, 'mock-chat-lumiere');
      expect(await messaging.findWith('nobody'), isNull);
    });
  });

  group('messages', () {
    test(
      'the newest 30, then older ones through nextBefore, no overlap',
      () async {
        final MessagePage newest = await messaging.messages(
          'mock-chat-lumiere',
        );

        expect(newest.items, hasLength(30));
        expect(newest.hasMore, isTrue);
        expect(newest.nextBefore, newest.items.first.id);
        expect(
          newest.items.last.body,
          "Perfect — I'll hold Sat 14 Mar for you.",
        );

        final MessagePage older = await messaging.messages(
          'mock-chat-lumiere',
          before: newest.nextBefore,
        );

        expect(older.items, isNotEmpty);
        expect(older.hasMore, isFalse);
        expect(older.nextBefore, isNull);
        final Set<String> newestIds = newest.items
            .map((ChatMessage m) => m.id)
            .toSet();
        expect(
          older.items.where((ChatMessage m) => newestIds.contains(m.id)),
          isEmpty,
        );
        expect(
          older.items.last.createdAt.isAfter(newest.items.first.createdAt),
          isFalse,
        );
      },
    );

    test('Lumière holds the drawn states: system, masked, photo', () async {
      final List<ChatMessage> items = (await messaging.messages(
        'mock-chat-lumiere',
      )).items;

      expect(
        items.where((ChatMessage m) => m.kind == MessageKind.system),
        hasLength(1),
      );
      expect(items.where((ChatMessage m) => m.masked && m.mine), hasLength(1));
      final ChatMessage photo = items.firstWhere((ChatMessage m) => m.hasImage);
      expect(photo.mine, isFalse);
      expect(
        photo.imageUrl,
        'asset:assets/mock/photos/pexels-salles-des-fetes-2.webp',
      );
      expect(photo.body, 'Last month at Salle Yasmine');
    });

    test('Yasmine holds a removed message', () async {
      final List<ChatMessage> items = (await messaging.messages(
        'mock-chat-yasmine',
      )).items;

      expect(items.where((ChatMessage m) => m.isRemoved), hasLength(1));
    });

    test('an unknown before is MESSAGE_NOT_FOUND', () async {
      await expectCode(
        messaging.messages('mock-chat-lumiere', before: 'nope'),
        ApiErrorCode.messageNotFound,
      );
    });

    test('dispute messages carry three different sender ids', () async {
      final List<ChatMessage> items = (await messaging.messages(
        'mock-chat-dispute',
      )).items;

      final Set<String> senders = items
          .map((ChatMessage m) => m.senderId)
          .whereType<String>()
          .toSet();
      expect(senders, hasLength(3));
    });
  });

  group('sending', () {
    test('a closed chat is CONVERSATION_CLOSED', () async {
      await expectCode(
        messaging.sendText('mock-chat-oliviers', 'Hello?'),
        ApiErrorCode.conversationClosed,
      );
    });

    test('a blocked other is CONVERSATION_READ_ONLY', () async {
      await expectCode(
        messaging.sendText('mock-chat-bahia', 'Hello?'),
        ApiErrorCode.conversationReadOnly,
      );
    });

    test('a deleted other is CONVERSATION_READ_ONLY', () async {
      await expectCode(
        messaging.sendText('mock-chat-deleted', 'Hello?'),
        ApiErrorCode.conversationReadOnly,
      );
    });

    test('a phone number is stored masked', () async {
      final ChatMessage sent = await messaging.sendText(
        'mock-chat-lumiere',
        'Call me on 0555 12 34 56 please',
      );

      expect(sent.masked, isTrue);
      expect(sent.mine, isTrue);
      expect(sent.body, 'Call me on [phone hidden] please');

      final ChatMessage stored = (await messaging.messages('mock-chat-lumiere'))
          .items
          .last;
      expect(stored.id, sent.id);
      expect(stored.masked, isTrue);
      expect(stored.body, contains('[phone hidden]'));
    });

    test('a send moves the row to the top with its text', () async {
      await messaging.sendText('mock-chat-djazair', 'About 300 guests.');

      final ConversationRow top = (await messaging.conversations()).items.first;
      expect(top.id, 'mock-chat-djazair');
      expect(top.lastMessage, 'About 300 guests.');
      expect(top.lastMessageAt, now);
    });

    test('a photo outside imageTypes is FILE_TYPE_NOT_ALLOWED', () async {
      await expectCode(
        messaging.sendPhoto(
          'mock-chat-lumiere',
          PickedImage(
            name: 'a.gif',
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            extension: 'gif',
          ),
        ),
        ApiErrorCode.fileTypeNotAllowed,
      );
    });

    test('a photo over maxPhotoMb is FILE_TOO_LARGE', () async {
      final MockMessagingStore small = MockMessagingStore(
        backend,
        languageCode: () => 'en',
        config: const AppConfig(maxPhotoMb: 1),
      );
      addTearDown(small.dispose);

      await expectCode(
        MockMessagingRepository(small, backend).sendPhoto(
          'mock-chat-lumiere',
          PickedImage(
            name: 'big.jpg',
            bytes: Uint8List(1024 * 1024 + 1),
            extension: 'jpg',
          ),
        ),
        ApiErrorCode.fileTooLarge,
      );
    });

    test('a sent photo is stored as a data URL', () async {
      final ChatMessage sent = await messaging.sendPhoto(
        'mock-chat-lumiere',
        PickedImage(
          name: 'a.jpg',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          extension: 'jpg',
        ),
        caption: 'The venue',
      );

      expect(sent.kind, MessageKind.attachment);
      expect(sent.imageUrl, 'data:image/jpeg;base64,AQID');
      expect(sent.body, 'The venue');
    });

    test('a dispute send is never masked', () async {
      final ChatMessage sent = await messaging.sendDisputeText(
        'mock-dispute-2041',
        'My number is 0555 12 34 56',
      );

      expect(sent.masked, isFalse);
      expect(sent.conversationId, 'mock-chat-dispute');
      expect(sent.body, 'My number is 0555 12 34 56');
    });
  });

  group('start', () {
    test('an existing pair appends to that chat', () async {
      final ConversationDetail detail = await messaging.start(
        lumiereId,
        'One more question',
      );

      expect(detail.id, 'mock-chat-lumiere');
      expect((await messaging.conversations()).total, 25);
      expect(
        (await messaging.messages('mock-chat-lumiere')).items.last.body,
        'One more question',
      );
    });

    test('a catalog provider without a chat gets a new one', () async {
      final ConversationDetail detail = await messaging.start(
        douceursId,
        'Hello!',
      );

      expect(detail.other?.id, douceursId);
      expect(detail.other?.name, "Douceurs d'Oran");
      expect(detail.canWrite, isTrue);
      expect(detail.lastMessage, 'Hello!');

      final ApiPage<ConversationRow> page = await messaging.conversations();
      expect(page.total, 26);
      expect(page.items.first.id, detail.id);
    });

    test('an unknown user is USER_NOT_FOUND', () async {
      await expectCode(
        messaging.start('nope', 'Hello!'),
        ApiErrorCode.userNotFound,
      );
    });
  });

  group('the mock reply (D3)', () {
    test('arrives once, after the first send, and counts as unread', () async {
      await messaging.sendText('mock-chat-yasmine', 'Is Saturday free?');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ChatMessage last = (await messaging.messages('mock-chat-yasmine'))
          .items
          .last;
      expect(last.mine, isFalse);
      expect(last.body, replyEn);
      expect(
        (await messaging.conversation('mock-chat-yasmine')).unreadCount,
        1,
      );

      await messaging.sendText('mock-chat-yasmine', 'And Sunday?');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ChatMessage after = (await messaging.messages('mock-chat-yasmine'))
          .items
          .last;
      expect(after.mine, isTrue);
      expect(after.body, 'And Sunday?');
      expect(
        (await messaging.conversation('mock-chat-yasmine')).unreadCount,
        1,
      );
    });

    test('is in Arabic when the app is', () async {
      final MockMessagingStore arabic = MockMessagingStore(
        backend,
        replyDelay: const Duration(milliseconds: 10),
        languageCode: () => 'ar',
      );
      addTearDown(arabic.dispose);
      final MockMessagingRepository repository = MockMessagingRepository(
        arabic,
        backend,
      );

      await repository.sendText('mock-chat-yasmine', 'Hello');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        (await repository.messages('mock-chat-yasmine')).items.last.body,
        'شكرًا على رسالتك — سأعود إليك قريبًا.',
      );
    });

    test('never comes in a support chat', () async {
      await messaging.sendText('mock-chat-support', 'Hello');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        (await messaging.messages('mock-chat-support')).items.last.mine,
        isTrue,
      );
    });
  });

  group('reads and reports', () {
    test('markRead drops unreadConversations from 2 to 1', () async {
      expect(store.unreadConversations(), 2);

      await messaging.markRead('mock-chat-lumiere');

      expect(store.unreadConversations(), 1);
      expect(
        (await messaging.conversation('mock-chat-lumiere')).unreadCount,
        0,
      );
    });

    test('a repeated report returns false', () async {
      const String messageId = 'mock-chat-lumiere-m42';

      expect(
        await messaging.reportMessage(messageId, ReportReason.spam, null),
        isTrue,
      );
      expect(
        await messaging.reportMessage(messageId, ReportReason.other, 'again'),
        isFalse,
      );
      expect(
        await messaging.reportUser(lumiereId, ReportReason.harassment, null),
        isTrue,
      );
      expect(
        await messaging.reportUser(lumiereId, ReportReason.harassment, null),
        isFalse,
      );
    });

    test('reporting unknown targets is a 404', () async {
      await expectCode(
        messaging.reportMessage('nope', ReportReason.spam, null),
        ApiErrorCode.messageNotFound,
      );
      await expectCode(
        messaging.reportUser('nope', ReportReason.spam, null),
        ApiErrorCode.userNotFound,
      );
    });
  });

  group('notifications', () {
    test('8 items across the three groups, 2 unread', () async {
      final ApiPage<AppNotification> page = await notifications.list();

      expect(page.items, hasLength(8));
      expect(
        page.items.map((AppNotification n) => n.group).toList(),
        <NotificationGroup>[
          NotificationGroup.today,
          NotificationGroup.today,
          NotificationGroup.thisWeek,
          NotificationGroup.thisWeek,
          NotificationGroup.earlier,
          NotificationGroup.earlier,
          NotificationGroup.earlier,
          NotificationGroup.earlier,
        ],
      );
      expect(page.items[0].type, 'booking.accepted');
      expect(page.items[1].type, 'message.new');
      final NotificationTarget target = page.items[1].target;
      expect(target, isA<ChatTarget>());
      expect((target as ChatTarget).conversationId, 'mock-chat-yasmine');
      expect(page.items.where((AppNotification n) => !n.read), hasLength(2));
      expect((await notifications.counts()).notifications, 2);
    });

    test('markRead and markAllRead return the new unread count', () async {
      final ApiPage<AppNotification> page = await notifications.list();

      expect(await notifications.markRead(<String>[page.items.first.id]), 1);
      expect(await notifications.markAllRead(), 0);
      expect((await notifications.counts()).notifications, 0);
    });

    test('counts reads the store', () async {
      await messaging.markRead('mock-chat-djazair');

      expect(await notifications.counts(), (
        notifications: 2,
        conversations: 1,
      ));
    });
  });

  test('signed out, every call is SessionExpiredFailure', () async {
    await backend.signOut();
    final Matcher expired = throwsA(isA<SessionExpiredFailure>());
    final PickedImage image = PickedImage(
      name: 'a.jpg',
      bytes: Uint8List.fromList(<int>[1]),
      extension: 'jpg',
    );

    await expectLater(messaging.conversations(), expired);
    await expectLater(messaging.conversation('mock-chat-lumiere'), expired);
    await expectLater(messaging.messages('mock-chat-lumiere'), expired);
    await expectLater(messaging.sendText('mock-chat-lumiere', 'hi'), expired);
    await expectLater(messaging.sendPhoto('mock-chat-lumiere', image), expired);
    await expectLater(
      messaging.sendDisputeText('mock-dispute-2041', 'hi'),
      expired,
    );
    await expectLater(messaging.start(lumiereId, 'hi'), expired);
    await expectLater(messaging.markRead('mock-chat-lumiere'), expired);
    await expectLater(
      messaging.reportMessage('mock-chat-lumiere-m1', ReportReason.spam, null),
      expired,
    );
    await expectLater(
      messaging.reportUser(lumiereId, ReportReason.spam, null),
      expired,
    );
    await expectLater(messaging.findWith(lumiereId), expired);
    await expectLater(notifications.list(), expired);
    await expectLater(notifications.markRead(<String>['x']), expired);
    await expectLater(notifications.markAllRead(), expired);
    await expectLater(notifications.counts(), expired);
    expect(store.unreadConversations, expired);
    expect(store.unreadNotifications, expired);
  });

  test('the mock home feed reports the store\'s two counts', () async {
    final MockCatalogRepository catalog = MockCatalogRepository(
      backend,
      languageCode: () => 'en',
      messaging: store,
    );

    final HomeFeed before = await catalog.home();
    expect(before.unreadNotifications, 2);
    expect(before.unreadConversations, 2);

    await messaging.markRead('mock-chat-lumiere');
    await notifications.markAllRead();

    final HomeFeed after = await catalog.home();
    expect(after.unreadNotifications, 0);
    expect(after.unreadConversations, 1);
  });
}
