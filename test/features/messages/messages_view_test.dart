import 'dart:async';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/formatting/chat_time_format.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/notification_bell.dart';
import 'package:eventor/core/widgets/molecules/offline_banner.dart';
import 'package:eventor/features/messages/view/widgets/conversation_row.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// A signed-in client on the Messages tab, with [messaging] behind it.
  Future<TestApp> startMessages(
    WidgetTester tester, {
    FakeMessagingRepository? messaging,
    Locale? locale,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
      auth: FakeAuthRepository()..restoredUser = testUser(),
      messaging: messaging,
    );
    await startAt(tester, app, AppRoutes.messages);
    return app;
  }

  String path(TestApp app) =>
      app.services.router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('shows the skeleton, then the conversations', (
    WidgetTester tester,
  ) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository();
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      auth: FakeAuthRepository()..restoredUser = testUser(),
      messaging: messaging,
    );
    await startApp(tester, app);
    messaging.gate = Completer<void>();
    app.services.router.go(AppRoutes.messages);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ConversationTileSkeleton), findsWidgets);
    expect(find.byType(ConversationTile), findsNothing);

    messaging.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(ConversationTileSkeleton), findsNothing);
    expect(find.byType(ConversationTile), findsNWidgets(5));
  });

  testWidgets('names support, dispute and deleted chats itself', (
    WidgetTester tester,
  ) async {
    await startMessages(tester);
    final AppLocalizations strings = l10n(tester);

    expect(find.byType(ConversationTile), findsNWidgets(5));
    expect(find.text('Studio Lumière'), findsOneWidget);
    expect(find.text(strings.chatSupport), findsOneWidget);
    expect(find.textContaining('Dispute'), findsOneWidget);
    expect(find.text(strings.chatDeletedAccount), findsOneWidget);
    // Its last message was a photo with no caption (D11).
    expect(find.text(strings.chatPhoto), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('in Arabic the reference and the time keep their own order', (
    WidgetTester tester,
  ) async {
    await startMessages(tester, locale: arabicLocale);

    final Text dispute = tester.widget<Text>(find.textContaining('EVT-2041'));
    expect(dispute.data, contains(ltrIsolate('EVT-2041')));

    final Finder rowTexts = find.descendant(
      of: find.byType(ConversationTile).first,
      matching: find.byType(Text),
    );
    final Iterable<Text> ltr = tester
        .widgetList<Text>(rowTexts)
        .where((Text t) => t.textDirection == TextDirection.ltr);
    expect(ltr, isNotEmpty);

    // The unread count sits at the row's end — the left in Arabic.
    expect(
      tester.getCenter(find.text('2')).dx,
      lessThan(tester.getCenter(find.text('Studio Lumière')).dx),
    );
  });

  testWidgets('a chip reloads with its filter', (WidgetTester tester) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository();
    await startMessages(tester, messaging: messaging);

    await tester.tap(find.text(l10n(tester).messagesFilterUnread));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('conversations:unread:null:1'));
    expect(find.byType(ConversationTile), findsOneWidget);
  });

  testWidgets('typing searches after a pause', (WidgetTester tester) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository();
    await startMessages(tester, messaging: messaging);

    await tester.enterText(find.byType(TextField), 'yas');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('conversations:all:yas:1'));
  });

  testWidgets('says when nothing is unread or nothing matches', (
    WidgetTester tester,
  ) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository()
      ..rows = const <Never>[];
    await startMessages(tester, messaging: messaging);
    final AppLocalizations strings = l10n(tester);

    expect(find.text(strings.messagesEmptyTitle), findsOneWidget);

    await tester.tap(find.text(strings.messagesFilterUnread));
    await tester.pumpAndSettle();

    expect(find.text(strings.messagesUnreadEmpty), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text(strings.messagesNoMatch('zz')), findsOneWidget);
  });

  testWidgets('offline with rows showing keeps them under a banner', (
    WidgetTester tester,
  ) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository();
    await startMessages(tester, messaging: messaging);
    messaging.loadError = const NetworkFailure();

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.byType(ConversationTile), findsNWidgets(5));

    messaging.loadError = null;
    await tester.tap(find.text(l10n(tester).offlineRetry));
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('the bell opens the notifications', (WidgetTester tester) async {
    final TestApp app = await startMessages(tester);

    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();

    expect(path(app), AppRoutes.notifications);
  });

  testWidgets('a row opens its chat and the list reloads on the way back', (
    WidgetTester tester,
  ) async {
    final FakeMessagingRepository messaging = FakeMessagingRepository();
    final TestApp app = await startMessages(tester, messaging: messaging);

    await tester.tap(find.text('Studio Lumière'));
    await tester.pumpAndSettle();

    expect(path(app), '/conversations/c-lumiere');

    final int before = messaging.calls
        .where((String c) => c.startsWith('conversations:'))
        .length;
    app.services.router.pop();
    await tester.pumpAndSettle();

    expect(
      messaging.calls
          .where((String c) => c.startsWith('conversations:'))
          .length,
      greaterThan(before),
    );
  });
}
