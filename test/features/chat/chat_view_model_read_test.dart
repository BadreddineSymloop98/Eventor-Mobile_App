import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/features/chat/view_model/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';
import 'chat_test_support.dart';

void main() {
  late ChatHarness h;

  setUp(() => h = ChatHarness());

  group('loading', () {
    test('opens ready, marks the chat read and starts polling', () async {
      final ChatViewModel viewModel = h.build();
      expect(viewModel.loadState, ChatLoadState.loading);
      await flushAsync();

      expect(viewModel.loadState, ChatLoadState.ready);
      expect(bubbles(viewModel), hasLength(5));
      expect(viewModel.thread.whereType<SystemItem>(), hasLength(1));
      expect(viewModel.thread.whereType<DayItem>(), hasLength(2));
      expect(h.messaging.calls, contains('markRead:c-lumiere'));
      expect(h.notifications.calls, contains('counts'));
      expect(h.updates.started, isTrue);
    });

    test('shows the provider reply time from 13 (D4)', () async {
      final ChatViewModel viewModel = h.build();
      await flushAsync();

      expect(viewModel.replyTime, '2 h');
    });

    test('a failed provider lookup only hides the line', () async {
      h.catalog.providerError = const NetworkFailure();
      final ChatViewModel viewModel = h.build();
      await flushAsync();

      expect(viewModel.replyTime, isNull);
      expect(viewModel.loadState, ChatLoadState.ready);
    });

    test('a chat that is not ours is no longer available', () async {
      h.messaging.loadError = apiFailure(
        ApiErrorCode.notAParticipant,
        statusCode: 403,
      );
      final ChatViewModel viewModel = h.build();
      await flushAsync();

      expect(viewModel.loadState, ChatLoadState.unavailable);
      expect(h.updates.started, isFalse);
    });

    test('a chat that is gone is no longer available', () async {
      final ChatViewModel viewModel = h.build(conversationId: 'c-nope');
      await flushAsync();

      expect(viewModel.loadState, ChatLoadState.unavailable);
    });

    test('a network failure is an error with a retry', () async {
      h.messaging.loadError = const NetworkFailure();
      final ChatViewModel viewModel = h.build();
      await flushAsync();

      expect(viewModel.loadState, ChatLoadState.error);
      expect(viewModel.failure, isA<NetworkFailure>());

      h.messaging.loadError = null;
      await viewModel.load();

      expect(viewModel.loadState, ChatLoadState.ready);
      expect(viewModel.failure, isNull);
    });
  });

  group('composer mode and menu', () {
    Future<ChatViewModel> open(ConversationDetail detail) async {
      h.messaging.details[detail.id] = detail;
      final ChatViewModel viewModel = h.build(conversationId: detail.id);
      await flushAsync();
      return viewModel;
    }

    test('an open chat takes messages', () async {
      final ChatViewModel viewModel = h.build();
      await flushAsync();

      expect(viewModel.composerMode, ComposerMode.open);
      expect(viewModel.showsMenu, isTrue);
    });

    test('canWrite false closes the composer', () async {
      final ChatViewModel viewModel = await open(
        detailWith(<String, Object?>{'id': 'c-closed', 'canWrite': false}),
      );

      expect(viewModel.composerMode, ComposerMode.closed);
    });

    test('a blocked other party gets the D12 notice', () async {
      final ChatViewModel viewModel = await open(
        detailWith(<String, Object?>{
          'id': 'c-blocked',
          'other': <String, Object?>{
            'id': 'p-lumiere',
            'name': 'Studio Lumière',
            'avatarUrl': null,
            'role': 'provider',
            'blocked': true,
          },
        }),
      );

      expect(viewModel.composerMode, ComposerMode.otherInactive);
    });

    test('a deleted account gets the D12 notice and no menu', () async {
      final ChatViewModel viewModel = await open(
        detailWith(<String, Object?>{'id': 'c-deleted', 'other': null}),
      );

      expect(viewModel.composerMode, ComposerMode.otherInactive);
      expect(viewModel.showsMenu, isFalse);
    });

    test('support and dispute chats have no menu', () async {
      final ChatViewModel dispute = await open(
        h.messaging.details['c-dispute']!,
      );
      final ChatViewModel support = await open(
        detailWith(<String, Object?>{'id': 'c-support', 'kind': 'support'}),
      );

      expect(dispute.showsMenu, isFalse);
      expect(support.showsMenu, isFalse);
    });
  });

  group('older pages', () {
    late ChatViewModel viewModel;

    setUp(() async {
      final DateTime start = DateTime(2026, 3, 1, 9);
      h.messaging.details['c-big'] = detailWith(<String, Object?>{
        'id': 'c-big',
      });
      h.messaging.threads['c-big'] = <ChatMessage>[
        for (int i = 0; i < 45; i++)
          message(
            'b-$i',
            at: start.add(Duration(minutes: i)),
            conversationId: 'c-big',
          ),
      ];
      viewModel = h.build(conversationId: 'c-big');
      await flushAsync();
    });

    test('loads 30, then the 15 before them', () async {
      expect(bubbles(viewModel), hasLength(30));
      expect(viewModel.hasOlder, isTrue);

      await viewModel.loadOlder();

      expect(bubbles(viewModel), hasLength(45));
      expect(viewModel.hasOlder, isFalse);
      expect(h.messaging.calls, contains('messages:c-big:b-15'));
    });

    test('a second call while one runs is ignored', () async {
      h.messaging.gate = Completer<void>();
      final Future<void> first = viewModel.loadOlder();
      final Future<void> second = viewModel.loadOlder();
      h.messaging.gate!.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(h.count('messages:c-big:b-'), 1);
    });

    test('a failure is offered again', () async {
      h.messaging.loadError = const NetworkFailure();
      await viewModel.loadOlder();

      expect(viewModel.olderFailed, isTrue);
      expect(viewModel.hasOlder, isTrue);

      h.messaging.loadError = null;
      await viewModel.loadOlder();

      expect(viewModel.olderFailed, isFalse);
      expect(bubbles(viewModel), hasLength(45));
    });
  });

  group('polling', () {
    late ChatViewModel viewModel;

    setUp(() async {
      viewModel = h.build();
      await flushAsync();
    });

    void arrive(String id) => h.messaging.threads['c-lumiere']!.add(
      // Later than every fixture message, whatever the local time zone.
      message(
        id,
        at: DateTime.parse('2026-03-12T12:00:00Z').toLocal(),
        body: 'new',
      ),
    );

    test('a new received message shows and marks the chat read', () async {
      arrive('m-7');
      await h.updates.tick();
      await flushAsync();

      expect(bubbleIds(viewModel).first, 'm-7');
      expect(h.count('markRead:c-lumiere'), 2);
      expect(
        h.notifications.calls.where((String c) => c == 'counts').length,
        2,
      );
    });

    test('while reading further up a pill offers the new ones (D9)', () async {
      viewModel.setAtBottom(false);
      arrive('m-7');
      await h.updates.tick();

      expect(viewModel.hasNewBelow, isTrue);

      viewModel.setAtBottom(true);

      expect(viewModel.hasNewBelow, isFalse);
    });

    test('at the bottom nothing asks for attention', () async {
      arrive('m-7');
      await h.updates.tick();

      expect(viewModel.hasNewBelow, isFalse);
    });

    test('a message an admin deleted drops out', () async {
      h.messaging.threads['c-lumiere']!.removeWhere(
        (ChatMessage m) => m.id == 'm-5',
      );
      await h.updates.tick();

      expect(bubbleIds(viewModel), isNot(contains('m-5')));
    });

    test('a tick while the chat reloads does nothing', () async {
      h.messaging.gate = Completer<void>();
      final Future<void> reload = viewModel.load();
      final int before = h.count('messages:');
      await h.updates.tick();

      expect(h.count('messages:'), before);

      h.messaging.gate!.complete();
      await reload;
    });

    test('a failed tick is silent', () async {
      h.messaging.loadError = const NetworkFailure();
      await h.updates.tick();

      expect(viewModel.loadState, ChatLoadState.ready);
      expect(bubbles(viewModel), hasLength(5));
    });
  });

  test('reloads one photo from the page that ends with it (D15)', () async {
    final ChatViewModel viewModel = h.build();
    await flushAsync();
    final List<ChatMessage> thread = h.messaging.threads['c-lumiere']!;
    final int index = thread.indexWhere((ChatMessage m) => m.id == 'm-4');
    thread[index] = thread[index].withImages(
      imageUrl: 'https://files.example/i4.jpg?exp=2&sig=fresh',
      imageLargeUrl: 'https://files.example/i4-large.jpg?exp=2&sig=fresh',
    );

    await viewModel.reloadPhoto('m-4');

    expect(h.messaging.calls, contains('messages:c-lumiere:m-5'));
    final BubbleItem photo = bubbles(viewModel)
        .firstWhere((BubbleItem b) => b.entry.message.id == 'm-4');
    expect(photo.entry.message.imageUrl, contains('sig=fresh'));
  });

  test('a hand-over opens at once, without loading the header', () async {
    final ChatViewModel viewModel = h.build(
      opening: ChatOpening(
        detail: h.messaging.details['c-lumiere']!,
        page: MessagePage(
          items: h.messaging.threads['c-lumiere']!,
          hasMore: false,
          nextBefore: null,
        ),
      ),
    );

    expect(viewModel.loadState, ChatLoadState.ready);
    await flushAsync();

    expect(h.count('conversation:'), 0);
    expect(bubbles(viewModel), hasLength(5));
    expect(h.updates.started, isTrue);
  });

  test(
    'a draft is ready and empty, polls nothing, and knows the provider',
    () async {
      final ChatViewModel viewModel = h.build(
        draft: const ChatDraftPeer(userId: 'p-1', name: 'Salle Yasmine'),
      );
      await flushAsync();

      expect(viewModel.loadState, ChatLoadState.ready);
      expect(viewModel.isDraft, isTrue);
      expect(viewModel.thread, isEmpty);
      expect(h.updates.started, isFalse);
      expect(viewModel.replyTime, '2 h');
      expect(viewModel.showsMenu, isTrue);
    },
  );

  test('closing mid-poll stops the poller and notifies nobody', () async {
    final ChatViewModel viewModel = h.build(autoDispose: false);
    await flushAsync();
    h.messaging.gate = Completer<void>();
    final Future<void> tick = h.updates.tick();

    // Something new arrives, which a live chat would mark read.
    h.messaging.threads['c-lumiere']!.add(
      message('m-9', at: DateTime.parse('2026-03-12T12:00:00Z').toLocal()),
    );
    viewModel.addListener(() => fail('notified after dispose'));
    viewModel.dispose();
    final int calls = h.messaging.calls.length;
    h.messaging.gate!.complete();
    await tick;
    await flushAsync();

    // No read mark or badge refresh for a chat nobody is looking at.
    expect(h.messaging.calls.length, calls);

    expect(h.updates.stopped, isTrue);
  });
}
