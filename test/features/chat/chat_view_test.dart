import 'dart:convert';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/features/chat/view/chat_view.dart';
import 'package:eventor/features/chat/view_model/chat_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';
import 'chat_test_support.dart';

Finder _icon(AppIcons icon) =>
    find.byWidgetPredicate((Widget w) => w is AppIcon && w.icon == icon);

void main() {
  group('routed', () {
    Future<TestApp> startChat(
      WidgetTester tester,
      String location, {
      FakeMessagingRepository? messaging,
      Locale? locale,
    }) async {
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        locale: locale,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        messaging: messaging,
      );
      await startAt(tester, app, location);
      return app;
    }

    String path(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('opens on the thread under its booking card', (
      WidgetTester tester,
    ) async {
      await startChat(tester, '/conversations/c-lumiere');

      expect(find.text('EVT-000123'), findsOneWidget);
      expect(
        find.text('Good morning — I saw your request for 14 March.'),
        findsOneWidget,
      );

      await tester.tap(find.text('EVT-000123'));
      await tester.pump();

      expect(find.text(l10n(tester).comingSoon), findsOneWidget);
    });

    testWidgets('the name opens the provider', (WidgetTester tester) async {
      final TestApp app = await startChat(tester, '/conversations/c-lumiere');

      await tester.tap(find.text('Studio Lumière').first);
      await tester.pumpAndSettle();

      expect(path(app), '/providers/p-lumiere');
    });

    testWidgets('⋯ reports the provider', (WidgetTester tester) async {
      final FakeMessagingRepository messaging = FakeMessagingRepository()
        ..reportCreated = false;
      await startChat(tester, '/conversations/c-lumiere', messaging: messaging);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(_icon(AppIcons.moreHorizontal));
      await tester.pumpAndSettle();
      expect(find.text(strings.chatViewProfile), findsOneWidget);

      await tester.tap(find.text(strings.chatReportUser('Studio Lumière')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.reportReasonSpam));
      await tester.tap(find.text(strings.reportSend));
      await tester.pumpAndSettle();

      expect(messaging.calls, contains('reportUser:p-lumiere:spam:null'));
      expect(find.text(strings.reportAlready), findsOneWidget);
    });

    testWidgets('typing enables Send; sending clears the field', (
      WidgetTester tester,
    ) async {
      final FakeMessagingRepository messaging = FakeMessagingRepository();
      await startChat(tester, '/conversations/c-lumiere', messaging: messaging);

      await tester.enterText(find.byType(TextField), 'coucou');
      await tester.pump();
      await tester.tap(_icon(AppIcons.chevronRight).last);
      await tester.pumpAndSettle();

      expect(messaging.calls, contains('sendText:c-lumiere:coucou'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
      expect(find.text('coucou'), findsOneWidget);
    });

    testWidgets('a chat closed under us switches the composer', (
      WidgetTester tester,
    ) async {
      final FakeMessagingRepository messaging = FakeMessagingRepository()
        ..sendError = apiFailure(
          ApiErrorCode.conversationClosed,
          statusCode: 409,
        );
      await startChat(tester, '/conversations/c-lumiere', messaging: messaging);
      final AppLocalizations strings = l10n(tester);

      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      await tester.tap(_icon(AppIcons.chevronRight).last);
      await tester.pumpAndSettle();

      expect(find.text(strings.chatClosed), findsOneWidget);
      expect(find.text(strings.chatNotSent), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a dispute chat is text only, with no ⋯', (
      WidgetTester tester,
    ) async {
      await startChat(tester, '/conversations/c-dispute');

      expect(find.text(l10n(tester).chatComposerDisputeHint), findsOneWidget);
      expect(_icon(AppIcons.plus), findsNothing);
      expect(_icon(AppIcons.moreHorizontal), findsNothing);
    });

    testWidgets('a chat that is not ours is no longer available', (
      WidgetTester tester,
    ) async {
      final FakeMessagingRepository messaging = FakeMessagingRepository()
        ..loadError = apiFailure(ApiErrorCode.notAParticipant, statusCode: 403);
      await startChat(tester, '/conversations/c-lumiere', messaging: messaging);

      expect(find.text(l10n(tester).chatUnavailable), findsOneWidget);
    });

    testWidgets('a draft says hello, waits for text, then becomes the chat', (
      WidgetTester tester,
    ) async {
      final FakeMessagingRepository messaging = FakeMessagingRepository();
      final TestApp app = await startChat(
        tester,
        AppRoutes.messages,
        messaging: messaging,
      );
      app.services.router.push(
        AppRoutes.chatDraftFor(userId: 'p-1', name: 'Salle Yasmine'),
      );
      await tester.pumpAndSettle();
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.chatSayHello('Salle Yasmine')), findsOneWidget);

      await tester.tap(_icon(AppIcons.plus));
      await tester.pump();
      expect(find.text(strings.chatPhotoNeedsText), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(_icon(AppIcons.chevronRight).last);
      await tester.pumpAndSettle();

      expect(messaging.calls, contains('start:p-1:Hello'));
      expect(path(app), '/conversations/c-new');

      app.services.router.pop();
      await tester.pumpAndSettle();

      // The draft was replaced, not stacked under the new chat.
      expect(path(app), AppRoutes.messages);
    });

    testWidgets('a long press offers Copy, and Report on theirs', (
      WidgetTester tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await startChat(tester, '/conversations/c-lumiere');
      final AppLocalizations strings = l10n(tester);

      await tester.longPress(
        find.text('Good morning — I saw your request for 14 March.'),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.chatReportMessage), findsOneWidget);

      await tester.tap(find.text(strings.chatCopy));
      await tester.pumpAndSettle();
      expect(find.text(strings.chatCopied), findsOneWidget);

      await tester.longPress(
        find.text('Full day please. My number is [phone hidden]'),
      );
      await tester.pumpAndSettle();
      expect(find.text(strings.chatCopy), findsOneWidget);
      expect(find.text(strings.chatReportMessage), findsNothing);
    });

    testWidgets('in Arabic the back arrow sits on the right', (
      WidgetTester tester,
    ) async {
      await startChat(tester, '/conversations/c-lumiere', locale: arabicLocale);

      final double width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getCenter(_icon(AppIcons.chevronLeft).first).dx,
        greaterThan(width / 2),
      );
    });
  });

  group('direct', () {
    late ChatHarness h;

    setUp(() => h = ChatHarness());

    Future<ChatViewModel> pumpChat(
      WidgetTester tester, {
      PickedImage? pick,
    }) async {
      usePhoneSurface(tester);
      final ChatViewModel viewModel = h.build(config: const AppConfig());
      await pumpAppWidget(
        tester,
        ChangeNotifierProvider<ChatViewModel>.value(
          value: viewModel,
          child: ChatView(pickPhoto: () async => pick),
        ),
      );
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('a photo over 10 MB is refused with the limit', (
      WidgetTester tester,
    ) async {
      await pumpChat(
        tester,
        pick: PickedImage(
          name: 'big.jpg',
          bytes: Uint8List(10 * 1024 * 1024 + 1),
          extension: 'jpg',
        ),
      );

      await tester.tap(_icon(AppIcons.plus));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).photoTooLarge(10)), findsOneWidget);
    });

    testWidgets('a good photo waits in a chip and can be sent alone', (
      WidgetTester tester,
    ) async {
      await pumpChat(
        tester,
        pick: PickedImage(
          name: 'hall.png',
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
          ),
          extension: 'png',
        ),
      );

      await tester.tap(_icon(AppIcons.plus));
      await tester.pumpAndSettle();
      expect(find.text('hall.png'), findsOneWidget);

      await tester.tap(_icon(AppIcons.chevronRight).last);
      await tester.pumpAndSettle();

      expect(h.messaging.calls, contains('sendPhoto:c-lumiere:hall.png:null'));
    });

    testWidgets('new messages below a reader get a pill (D9)', (
      WidgetTester tester,
    ) async {
      final ChatViewModel viewModel = await pumpChat(tester);
      viewModel.setAtBottom(false);
      h.messaging.threads['c-lumiere']!.add(
        message('m-9', at: DateTime.parse('2026-03-12T12:00:00Z').toLocal()),
      );

      await h.updates.tick();
      await tester.pump();
      final AppLocalizations strings = l10n(tester);
      expect(find.text(strings.chatNewMessages), findsOneWidget);

      await tester.tap(find.text(strings.chatNewMessages));
      await tester.pumpAndSettle();
      expect(find.text(strings.chatNewMessages), findsNothing);
    });
  });
}
