import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/formatting/money_format.dart';
import 'package:eventor/core/formatting/rating_format.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/atoms/category_icon.dart';
import 'package:eventor/core/widgets/molecules/price_text.dart';
import 'package:eventor/core/widgets/organisms/favourite_tile.dart';
import 'package:eventor/core/widgets/organisms/month_calendar.dart';
import 'package:eventor/core/widgets/organisms/pack_cards.dart';
import 'package:eventor/core/widgets/organisms/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_app.dart';

/// March 2026: the 10th busy, the 20th blocked, before the 5th too soon.
Availability march() => Availability(
      month: '2026-03',
      minNoticeDays: 1,
      firstBookableDate: DateTime(2026, 3, 5),
      days: <AvailabilityDay>[
        for (int d = 1; d <= 31; d++)
          AvailabilityDay(
            date: DateTime(2026, 3, d),
            state: d < 5 || d == 20
                ? DayState.blocked
                : d == 10
                    ? DayState.busy
                    : DayState.available,
          ),
      ],
    );

void main() {
  group('formatting', () {
    test('writes ratings with one decimal', () {
      expect(formatRating('4.80'), '4.8');
      expect(formatRating('5.00'), '5.0');
      expect(formatRating('n/a'), 'n/a');
    });

    test('knows when an amount is worth showing', () {
      expect(amountIsPositive('45000.00'), isTrue);
      expect(amountIsPositive('0.50'), isTrue);
      expect(amountIsPositive('0.00'), isFalse);
      expect(amountIsPositive('-5.00'), isFalse);
      expect(amountIsPositive(''), isFalse);
    });
  });

  group('categoryIcon', () {
    test('maps the server\'s names to the design\'s glyphs', () {
      expect(categoryIcon('building'), AppIcons.building);
      expect(categoryIcon('utensils'), AppIcons.catering);
      expect(categoryIcon('sparkles'), AppIcons.decor);
    });

    test('falls back for anything unknown', () {
      expect(categoryIcon('car'), AppIcons.layers);
      expect(categoryIcon(null), AppIcons.layers);
    });
  });

  group('MonthCalendar', () {
    Future<List<DateTime>> pumpCalendar(
      WidgetTester tester, {
      Locale locale = englishLocale,
      bool readOnly = false,
      List<DateTime>? months,
    }) async {
      final List<DateTime> picked = <DateTime>[];
      await pumpAppWidget(
        tester,
        SingleChildScrollView(
          child: MonthCalendar(
            month: DateTime(2026, 3),
            availability: march(),
            selected: DateTime(2026, 3, 14),
            onSelect: readOnly ? null : picked.add,
            onMonthChanged: (DateTime month) => months?.add(month),
            firstMonth: DateTime(2026, 3),
          ),
        ),
        locale: locale,
      );
      return picked;
    }

    Text day(WidgetTester tester, int n) => tester.widget<Text>(find.text('$n'));

    testWidgets('strikes through a fully booked day', (WidgetTester tester) async {
      await pumpCalendar(tester);

      expect(day(tester, 10).style?.decoration, TextDecoration.lineThrough);
      expect(day(tester, 11).style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('lets an available day be picked', (WidgetTester tester) async {
      final List<DateTime> picked = await pumpCalendar(tester);

      await tester.tap(find.text('16'));

      expect(picked, <DateTime>[DateTime(2026, 3, 16)]);
    });

    testWidgets('ignores busy, blocked and too-soon days', (WidgetTester tester) async {
      final List<DateTime> picked = await pumpCalendar(tester);

      await tester.tap(find.text('10'));
      await tester.tap(find.text('20'));
      await tester.tap(find.text('3'));

      expect(picked, isEmpty);
    });

    testWidgets('picks nothing when read-only', (WidgetTester tester) async {
      final List<DateTime> picked = await pumpCalendar(tester, readOnly: true);

      await tester.tap(find.text('16'));

      expect(picked, isEmpty);
    });

    testWidgets('cannot go back before the first month, can go forward',
        (WidgetTester tester) async {
      final List<DateTime> months = <DateTime>[];
      await pumpCalendar(tester, months: months);

      await tester.tap(find.bySemanticsLabel(l10n(tester).calendarPreviousMonth));
      await tester.tap(find.bySemanticsLabel(l10n(tester).calendarNextMonth));

      expect(months, <DateTime>[DateTime(2026, 4)]);
    });

    testWidgets('puts Sunday on the right in Arabic', (WidgetTester tester) async {
      await pumpCalendar(tester, locale: arabicLocale);

      // 1 March 2026 is a Sunday; the 7th a Saturday.
      expect(
        tester.getCenter(find.text('1')).dx,
        greaterThan(tester.getCenter(find.text('7')).dx),
      );
    });

    testWidgets('keeps the year in Western digits in Arabic',
        (WidgetTester tester) async {
      await pumpCalendar(tester, locale: arabicLocale);

      expect(find.text('2026'), findsOneWidget);
    });
  });

  group('showSideDrawer', () {
    Future<void> openDrawer(WidgetTester tester, Locale locale) async {
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showSideDrawer<void>(
              context,
              barrierLabel: 'close',
              builder: (_) => const Text('Filters'),
            ),
            child: const Text('open'),
          ),
        ),
        locale: locale,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('slides in on the right in English', (WidgetTester tester) async {
      await openDrawer(tester, englishLocale);
      final double screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;

      expect(tester.getCenter(find.text('Filters')).dx, greaterThan(screen / 2));
    });

    testWidgets('slides in on the left in Arabic', (WidgetTester tester) async {
      await openDrawer(tester, arabicLocale);
      final double screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;

      expect(tester.getCenter(find.text('Filters')).dx, lessThan(screen / 2));
    });
  });

  group('SavingsPill', () {
    testWidgets('reads "Save 45 000 DA · 12%" in order, in Arabic too',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: SavingsPill(savings: '45000.00', percent: 12)),
        locale: arabicLocale,
      );
      final String save = l10n(tester).packSave;

      expect(
        tester.getCenter(find.text(save)).dx,
        greaterThan(tester.getCenter(find.text('45 000')).dx),
      );
      expect(tester.widget<Text>(find.text('12%')).textDirection, TextDirection.ltr);
    });

    testWidgets('keeps a decimal percent', (WidgetTester tester) async {
      await pumpAppWidget(tester, const SavingsPill(savings: '7000.00', percent: 15.1));

      expect(find.text('15.1%'), findsOneWidget);
    });
  });

  group('PackRailCard', () {
    final PackCard pack = PackCard.fromJson(fixtureList('packs_page.json').first);

    testWidgets('leaves the design\'s 20pt under the price', (WidgetTester tester) async {
      // Figma: text block padded 8/12, then the card's own 12 at the bottom.
      await pumpAppWidget(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: PackRailCard(pack, onTap: () {}),
        ),
      );

      final Rect card = tester.getRect(find.byType(PackRailCard));
      final Rect price = tester.getRect(find.byType(PriceText));
      expect(card.bottom - price.bottom, moreOrLessEquals(20.dh, epsilon: 0.5));
    });

    testWidgets('sets the price in Body/M Strong, as drawn', (WidgetTester tester) async {
      await pumpAppWidget(tester, Center(child: PackRailCard(pack)));
      final TextTheme theme = Theme.of(tester.element(find.byType(PackRailCard))).textTheme;

      final Text amount = tester.widget<Text>(
        find.descendant(of: find.byType(PriceText), matching: find.byType(Text)).at(1),
      );
      expect(amount.style?.fontSize, theme.titleSmall?.fontSize);
    });

    testWidgets('lets the rail take the height of its cards', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        PacksRail(packs: <PackCard>[pack, pack], onOpen: (_) {}),
      );

      // No overflow warnings, whatever the text scale gives the cards.
      expect(tester.takeException(), isNull);
      expect(find.byType(PackRailCard), findsNWidgets(2));
    });
  });

  group('ServicePrice', () {
    testWidgets('says "On quote" instead of a price', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ServicePrice(amount: '45000.00', type: PriceType.onQuote),
      );

      expect(find.text(l10n(tester).priceOnQuote), findsOneWidget);
      expect(find.text('45 000'), findsNothing);
    });

    testWidgets('names the unit otherwise', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ServicePrice(amount: '45000.00', type: PriceType.perDay),
      );

      expect(find.text(l10n(tester).priceUnitPerDay), findsOneWidget);
      expect(find.text(l10n(tester).priceFrom), findsOneWidget);
    });

    for (final Locale locale in <Locale>[englishLocale, arabicLocale]) {
      testWidgets('puts "From" on its own line above the price (${locale.languageCode})',
          (WidgetTester tester) async {
        // 12's action bar: "From", then "45 000 DA per day" on the line below.
        await pumpAppWidget(
          tester,
          const Center(
            child: ServicePrice(
              amount: '45000.00',
              type: PriceType.perDay,
              fromOnOwnLine: true,
            ),
          ),
          locale: locale,
        );
        final Rect from = tester.getRect(find.text(l10n(tester).priceFrom));
        final Rect amount = tester.getRect(find.text('45 000'));
        final Rect unit = tester.getRect(find.text(l10n(tester).priceUnitPerDay));

        expect(from.bottom, lessThanOrEqualTo(amount.top));
        expect(unit.top, greaterThanOrEqualTo(from.bottom));
        // Both lines start on the reading side: left in English, right in Arabic.
        if (locale == arabicLocale) {
          expect(from.right, moreOrLessEquals(amount.right, epsilon: 0.5));
        } else {
          expect(from.left, moreOrLessEquals(amount.left, epsilon: 0.5));
        }
      });
    }

    testWidgets('still says only "On quote" when stacked', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const ServicePrice(amount: '45000.00', type: PriceType.onQuote, fromOnOwnLine: true),
      );

      expect(find.text(l10n(tester).priceOnQuote), findsOneWidget);
      expect(find.text(l10n(tester).priceFrom), findsNothing);
    });
  });

  group('FavouriteTile', () {
    final List<Favourite> favourites =
        fixtureList('favourites_page.json').map(Favourite.fromJson).toList();

    testWidgets('opens an available item', (WidgetTester tester) async {
      int opens = 0;
      await pumpAppWidget(
        tester,
        SizedBox(
          width: 180,
          child: FavouriteTile(favourites.first, onRemove: () {}, onTap: () => opens++),
        ),
      );

      await tester.tap(find.text(favourites.first.title.of('en')));

      expect(opens, 1);
    });

    testWidgets('cannot open one that is no longer listed, but can remove it',
        (WidgetTester tester) async {
      int opens = 0;
      int removals = 0;
      await pumpAppWidget(
        tester,
        SizedBox(
          width: 180,
          child: FavouriteTile(
            favourites.last,
            onRemove: () => removals++,
            onTap: () => opens++,
          ),
        ),
      );

      expect(find.text(l10n(tester).noLongerAvailable), findsOneWidget);
      await tester.tap(find.text(favourites.last.title.of('en')));
      await tester.tap(find.bySemanticsLabel(l10n(tester).favouriteSaved));

      expect(opens, 0);
      expect(removals, 1);
    });
  });
}
