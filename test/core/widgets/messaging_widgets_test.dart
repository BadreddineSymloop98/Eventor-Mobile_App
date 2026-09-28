import 'dart:io';

import 'package:eventor/core/messaging/models/chat_person.dart';
import 'package:eventor/core/messaging/models/conversation.dart';
import 'package:eventor/core/widgets/atoms/app_avatar.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/atoms/app_network_image.dart';
import 'package:eventor/core/widgets/molecules/conversation_avatar.dart';
import 'package:eventor/core/widgets/molecules/offline_banner.dart';
import 'package:eventor/core/widgets/organisms/divided_card.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  group('AppIcons.image / AppIcons.clock', () {
    test('have a file behind their name', () {
      // Mirrors app_icon_test.dart's blanket check, pinned to the two new
      // names so a missing export fails right here too.
      for (final AppIcons icon in <AppIcons>[AppIcons.image, AppIcons.clock]) {
        expect(
          File(icon.assetPath).existsSync(),
          isTrue,
          reason: '${icon.name} → ${icon.assetPath}',
        );
      }
    });

    testWidgets('load as ordinary AppIcons', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Row(
          children: <Widget>[
            AppIcon(AppIcons.image),
            AppIcon(AppIcons.clock),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(AppIcon), findsNWidgets(2));
    });
  });

  group('AppAvatarSize', () {
    test('list is 48 and chatHeader is 36', () {
      expect(AppAvatarSize.list.diameter, 48);
      expect(AppAvatarSize.chatHeader.diameter, 36);
    });
  });

  group('AppNetworkImage', () {
    // A 1×1 transparent PNG, inline — the shape the mock's sent photos come
    // back as.
    const String tinyPng =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1'
        'HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    testWidgets('shows Image.memory for a data: URI',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const AppNetworkImage(url: tinyPng, width: 40, height: 40),
      );

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
    });

    testWidgets('uses errorBuilder when an asset URL fails',
        (WidgetTester tester) async {
      bool calledBack = false;
      await pumpAppWidget(
        tester,
        AppNetworkImage(
          url: 'asset:assets/nope.png',
          width: 40,
          height: 40,
          errorBuilder: () {
            calledBack = true;
            return const SizedBox.shrink();
          },
        ),
      );
      // The bundle lookup fails asynchronously; give it a frame to report.
      await tester.pumpAndSettle();

      expect(calledBack, isTrue);
    });
  });

  group('OfflineBanner', () {
    testWidgets('orders icon, title, retry right-to-left in Arabic',
        (WidgetTester tester) async {
      bool retried = false;
      await pumpAppWidget(
        tester,
        OfflineBanner(body: 'stale copy', onRetry: () => retried = true),
        locale: arabicLocale,
      );

      final AppLocalizations strings = l10n(tester);
      final double iconX = tester.getCenter(find.byType(AppIcon)).dx;
      final double titleX =
          tester.getCenter(find.text(strings.offlineTitle)).dx;
      final double retryX =
          tester.getCenter(find.text(strings.offlineRetry)).dx;

      // A Row in the ambient (RTL) direction starts on the right, so the
      // leading icon sits at the highest x and the trailing action lowest.
      expect(iconX, greaterThan(titleX));
      expect(titleX, greaterThan(retryX));

      await tester.tap(find.text(strings.offlineRetry));
      expect(retried, isTrue);
    });
  });

  group('DividedCard', () {
    testWidgets('draws a divider between each pair of children',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const DividedCard(
          children: <Widget>[Text('a'), Text('b'), Text('c')],
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('ConversationAvatar', () {
    testWidgets('support shows the bundled logo', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ConversationAvatar(
          kind: ConversationKind.support,
          other: null,
          size: AppAvatarSize.list,
        ),
      );

      final Image image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, 'assets/images/logo.png');
    });

    testWidgets('dispute shows "!"', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ConversationAvatar(
          kind: ConversationKind.dispute,
          other: null,
          size: AppAvatarSize.list,
        ),
      );

      expect(find.text('!'), findsOneWidget);
    });

    testWidgets('a missing other shows the person glyph',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ConversationAvatar(
          kind: ConversationKind.direct,
          other: null,
          size: AppAvatarSize.list,
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is AppIcon && widget.icon == AppIcons.user,
        ),
        findsOneWidget,
      );
    });

    testWidgets('a provider other shows their initials',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ConversationAvatar(
          kind: ConversationKind.direct,
          other: ChatPerson(
            id: 'p1',
            name: 'Studio Lumière',
            role: ChatRole.provider,
            blocked: false,
          ),
          size: AppAvatarSize.list,
        ),
      );

      expect(find.text('SL'), findsOneWidget);
    });
  });
}
