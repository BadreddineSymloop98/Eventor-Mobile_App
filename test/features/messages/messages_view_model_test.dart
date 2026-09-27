import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/conversation_filter.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/features/messages/view_model/messages_view_model.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeMessagingRepository messaging;
  late FakeNotificationsRepository notifications;

  setUp(() {
    messaging = FakeMessagingRepository();
    notifications = FakeNotificationsRepository();
  });

  MessagesViewModel build({Duration debounce = Duration.zero}) {
    final MessagesViewModel viewModel = MessagesViewModel(
      messaging: messaging,
      badges: ShellBadges(notifications: notifications),
      debounce: debounce,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  /// 25 bare rows — enough for a second page of the default 20-row limit.
  List<ConversationRow> manyRows() => <ConversationRow>[
    for (int i = 0; i < 25; i++)
      ConversationRow.fromJson(<String, Object?>{'id': 'c-$i'}),
  ];

  group('MessagesViewModel first load', () {
    test('shows the rows once loaded', () async {
      final MessagesViewModel viewModel = build();

      expect(viewModel.isFirstLoad, isTrue);
      await flushAsync();

      expect(viewModel.isFirstLoad, isFalse);
      expect(viewModel.items, hasLength(messaging.rows.length));
      expect(viewModel.empty, MessagesEmpty.none);
    });

    test('a failure with nothing cached is the generic error state', () async {
      messaging.loadError = const NetworkFailure();
      final MessagesViewModel viewModel = build();
      await flushAsync();

      expect(viewModel.hasError, isTrue);
      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.items, isEmpty);
      expect(viewModel.empty, MessagesEmpty.none);
      expect(viewModel.isOffline, isFalse);
    });

    test('calls the badges refresh on success', () async {
      build();
      await flushAsync();

      expect(notifications.calls, contains('counts'));
    });
  });

  group('MessagesViewModel filter', () {
    test('reloads immediately with the chosen filter', () async {
      final MessagesViewModel viewModel = build();
      await flushAsync();

      viewModel.setFilter(ConversationFilter.unread);
      await flushAsync();

      expect(messaging.calls, contains('conversations:unread:null:1'));
      expect(viewModel.filter, ConversationFilter.unread);
    });

    test('a stale response from before a filter change is discarded', () async {
      messaging.gate = Completer<void>();
      final MessagesViewModel viewModel = build();

      viewModel.setFilter(ConversationFilter.unread);
      messaging.gate!.complete();
      await flushAsync();

      // Only c-lumiere has an unread count in the fixture.
      expect(viewModel.items.map((ConversationRow r) => r.id), <String>[
        'c-lumiere',
      ]);
      expect(messaging.calls, <String>[
        'conversations:all:null:1',
        'conversations:unread:null:1',
      ]);
    });
  });

  group('MessagesViewModel search', () {
    test('debounces rapid typing into a single trimmed call', () async {
      final MessagesViewModel viewModel = build(
        debounce: const Duration(milliseconds: 300),
      );
      await flushAsync();
      messaging.calls.clear();

      viewModel.setQuery('st');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      viewModel.setQuery('stu');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Only 200 ms have passed since the last call; still waiting.
      expect(messaging.calls, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(messaging.calls, <String>['conversations:all:stu:1']);
      expect(viewModel.query, 'stu');
    });

    test('clearing the query to blank sends no q at all', () async {
      final MessagesViewModel viewModel = build();
      await flushAsync();
      viewModel.setQuery('lumiere');
      await flushAsync();
      expect(viewModel.query, 'lumiere');
      messaging.calls.clear();

      viewModel.setQuery('   ');
      await flushAsync();

      expect(messaging.calls, <String>['conversations:all:null:1']);
      expect(viewModel.query, '');
    });

    test(
      'a filter change flushes a pending search into the same reload',
      () async {
        final MessagesViewModel viewModel = build(
          debounce: const Duration(milliseconds: 300),
        );
        await flushAsync();
        messaging.calls.clear();

        viewModel.setQuery('lumiere');
        viewModel.setFilter(ConversationFilter.booking);
        await flushAsync();

        expect(messaging.calls, <String>['conversations:booking:lumiere:1']);
        expect(viewModel.query, 'lumiere');
        expect(viewModel.filter, ConversationFilter.booking);
      },
    );
  });

  group('MessagesViewModel loadMore', () {
    test('appends the next page and stops when there is no more', () async {
      messaging.rows = manyRows();
      final MessagesViewModel viewModel = build();
      await flushAsync();

      expect(viewModel.items, hasLength(20));
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadMore();

      expect(viewModel.items, hasLength(25));
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.loadMoreFailed, isFalse);
    });

    test('a failed page keeps the rows and flags the failure', () async {
      messaging.rows = manyRows();
      final MessagesViewModel viewModel = build();
      await flushAsync();

      messaging.failNext = const NetworkFailure();
      await viewModel.loadMore();

      expect(viewModel.items, hasLength(20));
      expect(viewModel.hasMore, isTrue);
      expect(viewModel.loadMoreFailed, isTrue);
    });
  });

  group('MessagesViewModel refresh', () {
    test(
      'a network failure with rows showing goes offline, not error',
      () async {
        final MessagesViewModel viewModel = build();
        await flushAsync();
        final int loaded = viewModel.items.length;

        messaging.loadError = const NetworkFailure();
        final Failure? failure = await viewModel.refresh();

        expect(failure, isA<NetworkFailure>());
        expect(viewModel.isOffline, isTrue);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.items, hasLength(loaded));

        messaging.loadError = null;
        final Failure? second = await viewModel.refresh();

        expect(second, isNull);
        expect(viewModel.isOffline, isFalse);
      },
    );
  });

  group('MessagesViewModel empty variants', () {
    test('no rows at all is the all-conversations empty state', () async {
      messaging.rows = <ConversationRow>[];
      final MessagesViewModel viewModel = build();
      await flushAsync();

      expect(viewModel.empty, MessagesEmpty.all);
    });

    test('no rows on the unread filter is the unread empty state', () async {
      messaging.rows = <ConversationRow>[];
      final MessagesViewModel viewModel = build();
      await flushAsync();

      viewModel.setFilter(ConversationFilter.unread);
      await flushAsync();

      expect(viewModel.empty, MessagesEmpty.unread);
    });

    test('no rows on the booking filter is the bookings empty state', () async {
      messaging.rows = <ConversationRow>[];
      final MessagesViewModel viewModel = build();
      await flushAsync();

      viewModel.setFilter(ConversationFilter.booking);
      await flushAsync();

      expect(viewModel.empty, MessagesEmpty.bookings);
    });

    test('a query with no matches is the search empty state, whatever '
        'the filter', () async {
      messaging.rows = <ConversationRow>[];
      final MessagesViewModel viewModel = build();
      await flushAsync();

      viewModel.setFilter(ConversationFilter.booking);
      viewModel.setQuery('nothing');
      await flushAsync();

      expect(viewModel.empty, MessagesEmpty.search);
    });
  });
}
