import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_avatar.dart';
import 'package:eventor/core/widgets/atoms/rating_view.dart';
import 'package:eventor/core/widgets/atoms/status_badge.dart';
import 'package:eventor/core/widgets/molecules/main_button.dart';
import 'package:eventor/core/widgets/organisms/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Pumps [card] the way a list would hold it.
Future<void> _pumpCard(
  WidgetTester tester,
  Widget card, {
  Locale locale = englishLocale,
}) {
  return pumpAppWidget(
    tester,
    ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[card],
    ),
    locale: locale,
  );
}

void main() {
  group('ProviderCard', () {
    testWidgets('shows who, what, how good and how much',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ProviderCard(
          name: 'Studio Lumière',
          meta: 'Photographer · Alger',
          amount: '45000.00',
          unit: 'per day',
          score: '4.8',
          reviewCount: 32,
        ),
      );

      expect(find.text('Studio Lumière'), findsOneWidget);
      expect(find.text('Photographer · Alger'), findsOneWidget);
      expect(find.text('45 000'), findsOneWidget);
      expect(find.text('per day'), findsOneWidget);
      expect(find.text(l10n(tester).priceFrom), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('SL'), findsOneWidget);
    });

    testWidgets('leaves the rating out when there is none',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ProviderCard(
          name: 'Studio Lumière',
          meta: 'Photographer · Alger',
          amount: '45000.00',
          unit: 'per day',
        ),
      );

      expect(find.byType(RatingView), findsNothing);
    });

    testWidgets('keeps the price reading left to right in Arabic',
        (WidgetTester tester) async {
      // The standing rule: a spaced number inside Arabic copy reverses its
      // groups unless it is pinned.
      await _pumpCard(
        tester,
        const ProviderCard(
          name: 'استوديو النور',
          meta: 'مصور · الجزائر',
          amount: '45000.00',
          unit: 'في اليوم',
        ),
        locale: arabicLocale,
      );

      expect(
        tester.widget<Text>(find.text('45 000')).textDirection,
        TextDirection.ltr,
      );
      // The avatar leads on the right.
      expect(
        tester.getCenter(find.byType(AppAvatar)).dx,
        greaterThan(tester.getCenter(find.text('45 000')).dx),
      );
    });

    testWidgets('reports the tap and shows the press',
        (WidgetTester tester) async {
      int taps = 0;
      await _pumpCard(
        tester,
        ProviderCard(
          name: 'Studio Lumière',
          meta: 'Photographer · Alger',
          amount: '45000.00',
          unit: 'per day',
          onTap: () => taps++,
        ),
      );
      final Finder shell = find
          .descendant(
            of: find.byType(ProviderCard),
            matching: find.byType(AnimatedContainer),
          )
          .first;

      final TestGesture finger =
          await tester.startGesture(tester.getCenter(find.text('per day')));
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        (tester.widget<AnimatedContainer>(shell).decoration! as BoxDecoration)
            .color,
        AppColors.bgSurfacePressed,
      );

      await finger.up();
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('BookingCard', () {
    testWidgets('shows the counterpart and the status',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const BookingCard(
          counterpartName: 'Amina Benali',
          meta: 'Photography · Sat 14 Mar',
          status: BookingStatusKind.accepted,
        ),
      );

      expect(find.text('Amina Benali'), findsOneWidget);
      expect(find.text('Photography · Sat 14 Mar'), findsOneWidget);
      expect(find.text(l10n(tester).statusAccepted), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('reads in Arabic', (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const BookingCard(
          counterpartName: 'أمينة بن علي',
          meta: 'تصوير · السبت 14 مارس',
          status: BookingStatusKind.pending,
        ),
        locale: arabicLocale,
      );

      expect(find.text('أمينة بن علي'), findsOneWidget);
      expect(find.text(l10n(tester).statusPending), findsOneWidget);
    });
  });

  group('RequestCard', () {
    Future<List<String>> pumpRequest(
      WidgetTester tester, {
      bool isBusy = false,
    }) async {
      final List<String> calls = <String>[];
      await _pumpCard(
        tester,
        RequestCard(
          clientName: 'Yacine Haddad',
          meta: 'Wedding photography · Sat 14 Mar · 150 guests',
          onAccept: () => calls.add('accept'),
          onDecline: () => calls.add('decline'),
          isBusy: isBusy,
        ),
      );
      return calls;
    }

    testWidgets('shows the request as pending with both answers',
        (WidgetTester tester) async {
      await pumpRequest(tester);

      expect(find.text('Yacine Haddad'), findsOneWidget);
      expect(
        find.text('Wedding photography · Sat 14 Mar · 150 guests'),
        findsOneWidget,
      );
      expect(find.text(l10n(tester).statusPending), findsOneWidget);
      expect(find.text(l10n(tester).requestAccept), findsOneWidget);
      expect(find.text(l10n(tester).requestDecline), findsOneWidget);
    });

    testWidgets('reports each answer', (WidgetTester tester) async {
      final List<String> calls = await pumpRequest(tester);

      await tester.tap(find.text(l10n(tester).requestDecline));
      await tester.tap(find.text(l10n(tester).requestAccept));

      expect(calls, <String>['decline', 'accept']);
    });

    testWidgets('puts Decline before Accept, as outlined and filled',
        (WidgetTester tester) async {
      await pumpRequest(tester);
      final List<MainButton> buttons =
          tester.widgetList<MainButton>(find.byType(MainButton)).toList();

      expect(buttons[0].style, MainButtonStyle.secondary);
      expect(buttons[1].style, MainButtonStyle.primary);
    });

    testWidgets('takes no second answer while one is being sent',
        (WidgetTester tester) async {
      final List<String> calls = await pumpRequest(tester, isBusy: true);

      await tester.tap(find.text(l10n(tester).requestAccept));
      await tester.tap(find.text(l10n(tester).requestDecline));

      expect(calls, isEmpty);
    });
  });

  group('ServiceItem', () {
    testWidgets('shows the title, the price and its unit',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ServiceItem(
          title: 'Wedding photography',
          price: '45 000 DA',
          unit: 'per day',
          isAvailable: true,
        ),
      );

      expect(find.text('Wedding photography'), findsOneWidget);
      expect(find.text('45 000 DA'), findsOneWidget);
      expect(find.text('per day'), findsOneWidget);
      expect(find.text(l10n(tester).availabilityAvailable), findsOneWidget);
    });

    testWidgets('says when it is not taking bookings',
        (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ServiceItem(
          title: 'تصوير الأعراس',
          price: '45 000 DA',
          unit: 'في اليوم',
          isAvailable: false,
        ),
        locale: arabicLocale,
      );

      expect(find.text(l10n(tester).availabilityUnavailable), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('45 000 DA')).textDirection,
        TextDirection.ltr,
      );
    });
  });
}
