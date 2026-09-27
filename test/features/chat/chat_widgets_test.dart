import 'dart:convert';
import 'dart:typed_data';

import 'package:eventor/core/messaging/models/chat_message.dart';
import 'package:eventor/core/messaging/models/report_reason.dart';
import 'package:eventor/core/messaging/picked_image.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/features/chat/view/widgets/chat_composer.dart';
import 'package:eventor/features/chat/view/widgets/chat_sheets.dart';
import 'package:eventor/features/chat/view/widgets/chat_top_bar.dart';
import 'package:eventor/features/chat/view/widgets/message_bubble.dart';
import 'package:eventor/features/chat/view_model/chat_thread.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'chat_test_support.dart';

/// A real 1×1 PNG, so a memory image decodes without an error.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

ChatEntry _entry(
  String id, {
  bool mine = false,
  String body = 'hello',
  bool masked = false,
  String? imageUrl,
  EntryState state = EntryState.sent,
  PickedImage? localImage,
}) => ChatEntry(
  message: ChatMessage(
    id: id,
    conversationId: 'c-1',
    kind: imageUrl != null || localImage != null
        ? MessageKind.attachment
        : MessageKind.text,
    senderId: mine ? 'u-me' : 'p-1',
    mine: mine,
    body: body,
    masked: masked,
    imageUrl: imageUrl,
    imageLargeUrl: imageUrl,
    createdAt: DateTime(2026, 3, 12, 9, 24),
  ),
  state: state,
  localImage: localImage,
);

Finder _icon(AppIcons icon) =>
    find.byWidgetPredicate((Widget w) => w is AppIcon && w.icon == icon);

void main() {
  group('MessageBubble', () {
    BorderRadiusDirectional corners(WidgetTester tester, String text) {
      final Container bubble = tester.widget<Container>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Container))
            .first,
      );
      return (bubble.decoration! as BoxDecoration).borderRadius!
          as BorderRadiusDirectional;
    }

    Future<void> pumpPair(WidgetTester tester, Locale locale) => pumpAppWidget(
      tester,
      Column(
        children: <Widget>[
          MessageBubble(entry: _entry('r', body: 'received')),
          MessageBubble(entry: _entry('s', body: 'sent', mine: true)),
        ],
      ),
      locale: locale,
    );

    testWidgets('received keeps its tail at the start, sent at the end', (
      WidgetTester tester,
    ) async {
      await pumpPair(tester, englishLocale);

      expect(corners(tester, 'received').bottomStart, const Radius.circular(4));
      expect(corners(tester, 'sent').bottomEnd, const Radius.circular(4));
      // Resolved for English, the received tail is bottom-left.
      expect(
        corners(tester, 'received').resolve(TextDirection.ltr).bottomLeft,
        const Radius.circular(4),
      );
      expect(
        tester.getRect(find.text('sent')).right,
        greaterThan(tester.getRect(find.text('received')).right),
      );
    });

    testWidgets('Arabic mirrors the sides', (WidgetTester tester) async {
      await pumpPair(tester, arabicLocale);

      expect(
        corners(tester, 'received').resolve(TextDirection.rtl).bottomRight,
        const Radius.circular(4),
      );
      expect(
        tester.getRect(find.text('sent')).left,
        lessThan(tester.getRect(find.text('received')).left),
      );
    });

    testWidgets('a masked message carries the note (D14)', (
      WidgetTester tester,
    ) async {
      await pumpAppWidget(
        tester,
        MessageBubble(entry: _entry('m', mine: true, masked: true)),
      );

      expect(find.text(l10n(tester).chatMaskedNote), findsOneWidget);
    });

    testWidgets('a removed message is worded by the app and has no menu', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await pumpAppWidget(
        tester,
        MessageBubble(
          entry: _entry('m', body: ChatMessage.removedBody),
          onLongPress: () => pressed = true,
        ),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.chatRemoved), findsOneWidget);
      expect(find.text(ChatMessage.removedBody), findsNothing);
      final Opacity faded = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text(strings.chatRemoved),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(faded.opacity, 0.55);

      await tester.longPress(find.text(strings.chatRemoved));
      expect(pressed, isFalse);
    });

    testWidgets('a photo alone has no empty text line, and a dead link '
        'offers a reload (D15)', (WidgetTester tester) async {
      bool reloaded = false;
      await pumpAppWidget(
        tester,
        MessageBubble(
          entry: _entry('p', body: '', imageUrl: 'asset:assets/nope.png'),
          onPhotoReload: () => reloaded = true,
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<Text> texts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.byType(Text),
        ),
      );
      expect(texts.where((Text t) => t.data == ''), isEmpty);

      await tester.tap(find.text(l10n(tester).photoReload));
      expect(reloaded, isTrue);
    });

    testWidgets('a photo on its way shows from memory', (
      WidgetTester tester,
    ) async {
      await pumpAppWidget(
        tester,
        MessageBubble(
          entry: _entry(
            'local-0',
            mine: true,
            body: '',
            state: EntryState.sending,
            localImage: PickedImage(
              name: 'a.png',
              bytes: _png,
              extension: 'png',
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is Image && w.image is MemoryImage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('sending shows a clock; failed says so and retries', (
      WidgetTester tester,
    ) async {
      bool retried = false;
      await pumpAppWidget(
        tester,
        Column(
          children: <Widget>[
            MessageBubble(
              entry: _entry(
                'a',
                mine: true,
                body: 'going',
                state: EntryState.sending,
              ),
            ),
            MessageBubble(
              entry: _entry(
                'b',
                mine: true,
                body: 'lost',
                state: EntryState.failed,
              ),
              onRetry: () => retried = true,
            ),
          ],
        ),
      );

      expect(_icon(AppIcons.clock), findsOneWidget);
      expect(find.text(l10n(tester).chatNotSent), findsOneWidget);

      await tester.tap(find.text('lost'));
      expect(retried, isTrue);
    });

    testWidgets('a group names the sender above the bubble', (
      WidgetTester tester,
    ) async {
      await pumpAppWidget(
        tester,
        MessageBubble(entry: _entry('a'), senderName: 'Eventor support'),
      );

      expect(
        tester.getRect(find.text('Eventor support')).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('hello')).top),
      );
    });
  });

  group('ChatComposer', () {
    Future<void> pumpComposer(
      WidgetTester tester, {
      required bool canSend,
      bool canAttach = true,
      PickedImage? attachment,
      VoidCallback? onSend,
      VoidCallback? onRemove,
    }) => pumpAppWidget(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: ChatComposer(
          controller: TextEditingController(),
          hint: 'Write a message',
          canAttach: canAttach,
          canSend: canSend,
          attachment: attachment,
          onAttach: () {},
          onRemoveAttachment: onRemove ?? () {},
          onSend: onSend ?? () {},
        ),
      ),
    );

    testWidgets('Send is dimmed and inert while there is nothing to send', (
      WidgetTester tester,
    ) async {
      int sends = 0;
      await pumpComposer(tester, canSend: false, onSend: () => sends++);

      await tester.tap(_icon(AppIcons.chevronRight));
      expect(sends, 0);

      await pumpComposer(tester, canSend: true, onSend: () => sends++);
      await tester.tap(_icon(AppIcons.chevronRight));
      expect(sends, 1);
    });

    testWidgets('no "+" where photos are not allowed', (
      WidgetTester tester,
    ) async {
      await pumpComposer(tester, canSend: false, canAttach: false);

      expect(_icon(AppIcons.plus), findsNothing);
    });

    testWidgets('a picked photo shows as a chip that can be removed', (
      WidgetTester tester,
    ) async {
      bool removed = false;
      await pumpComposer(
        tester,
        canSend: true,
        attachment: PickedImage(
          name: 'hall.png',
          bytes: _png,
          extension: 'png',
        ),
        onRemove: () => removed = true,
      );

      expect(find.text('hall.png'), findsOneWidget);
      await tester.tap(_icon(AppIcons.close));
      expect(removed, isTrue);
    });

    testWidgets('a closed chat shows only the notice', (
      WidgetTester tester,
    ) async {
      await pumpAppWidget(tester, const ClosedComposer(notice: 'Closed.'));

      expect(find.text('Closed.'), findsOneWidget);
      expect(_icon(AppIcons.chevronRight), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('the top bar mirrors in Arabic, and ⋯ can be hidden', (
    WidgetTester tester,
  ) async {
    await pumpAppWidget(
      tester,
      ChatTopBar(
        avatar: const SizedBox.square(dimension: 36),
        title: 'Studio Lumière',
        onBack: () {},
        onMore: () {},
      ),
      locale: arabicLocale,
    );

    final double back = tester.getCenter(_icon(AppIcons.chevronLeft)).dx;
    final double title = tester.getCenter(find.text('Studio Lumière')).dx;
    final double more = tester.getCenter(_icon(AppIcons.moreHorizontal)).dx;
    expect(back, greaterThan(title));
    expect(title, greaterThan(more));

    await pumpAppWidget(
      tester,
      ChatTopBar(
        avatar: const SizedBox.square(dimension: 36),
        title: 'Eventor support',
        onBack: () {},
      ),
    );
    expect(_icon(AppIcons.moreHorizontal), findsNothing);
  });

  testWidgets('the booking card keeps the reference left-to-right', (
    WidgetTester tester,
  ) async {
    await pumpAppWidget(
      tester,
      BookingContextCard(
        booking: detailWith(<String, Object?>{}).booking!,
        onTap: () {},
      ),
      locale: arabicLocale,
    );

    final Text reference = tester.widget<Text>(find.text('EVT-000123'));
    expect(reference.textDirection, TextDirection.ltr);
    expect(find.text(l10n(tester).statusPending), findsOneWidget);
  });

  group('sheets', () {
    Future<T?> open<T>(
      WidgetTester tester,
      Future<T?> Function(BuildContext context) show,
    ) async {
      T? result;
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => result = await show(context),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('the report sheet sends only once a reason is picked', (
      WidgetTester tester,
    ) async {
      ({ReportReason reason, String? note})? chosen;
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => chosen = await showReportSheet(context),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final AppLocalizations strings = l10n(tester);

      await tester.tap(find.text(strings.reportSend));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(find.text(strings.reportSend), findsOneWidget);

      await tester.tap(find.text(strings.reportReasonSpam));
      await tester.enterText(find.byType(TextField), 'note');
      await tester.tap(find.text(strings.reportSend));
      await tester.pumpAndSettle();

      expect(chosen?.reason, ReportReason.spam);
      expect(chosen?.note, 'note');
    });

    testWidgets('a message menu lists only what is allowed', (
      WidgetTester tester,
    ) async {
      await open<MessageAction>(
        tester,
        (BuildContext context) =>
            showMessageActions(context, canCopy: false, canReport: true),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.chatCopy), findsNothing);
      expect(find.text(strings.chatReportMessage), findsOneWidget);
    });
  });
}
