import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/status_badge.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// The outline the badge is drawn with — the pill's own [Container].
BoxDecoration _pillOf(WidgetTester tester, Type badge) {
  return tester
      .widget<Container>(
        find.descendant(of: find.byType(badge), matching: find.byType(Container))
            .first,
      )
      .decoration! as BoxDecoration;
}

void main() {
  group('BookingStatusKind.fromApi', () {
    test('maps every API value to itself', () {
      expect(BookingStatusKind.fromApi('pending'), BookingStatusKind.pending);
      expect(BookingStatusKind.fromApi('accepted'), BookingStatusKind.accepted);
      expect(BookingStatusKind.fromApi('declined'), BookingStatusKind.declined);
      expect(BookingStatusKind.fromApi('completed'), BookingStatusKind.completed);
      expect(BookingStatusKind.fromApi('cancelled'), BookingStatusKind.cancelled);
    });

    test('defaults an unknown value to pending', () {
      expect(BookingStatusKind.fromApi('weird'), BookingStatusKind.pending);
    });
  });

  group('StatusBadge', () {
    /// Each status with the words and colour it should carry.
    final Map<BookingStatusKind, (String Function(AppLocalizations), Color)>
        expected = <BookingStatusKind, (String Function(AppLocalizations), Color)>{
      BookingStatusKind.pending: (
        (AppLocalizations s) => s.statusPending,
        AppColors.statusPending,
      ),
      BookingStatusKind.accepted: (
        (AppLocalizations s) => s.statusAccepted,
        AppColors.statusAccepted,
      ),
      BookingStatusKind.declined: (
        (AppLocalizations s) => s.statusDeclined,
        AppColors.statusDeclined,
      ),
      BookingStatusKind.completed: (
        (AppLocalizations s) => s.statusCompleted,
        AppColors.statusCompleted,
      ),
      BookingStatusKind.cancelled: (
        (AppLocalizations s) => s.statusCancelled,
        AppColors.statusCancelled,
      ),
    };

    for (final Locale locale in <Locale>[englishLocale, arabicLocale]) {
      for (final BookingStatusKind status in BookingStatusKind.values) {
        testWidgets(
            'names and colours ${status.name} (${locale.languageCode})',
            (WidgetTester tester) async {
          await pumpAppWidget(
            tester,
            Center(child: StatusBadge(status)),
            locale: locale,
          );
          final (String Function(AppLocalizations) label, Color color) =
              expected[status]!;
          final String text = label(l10n(tester));

          expect(find.text(text), findsOneWidget);
          // One colour for the outline and the words, on a white ground:
          // the design never fills a badge.
          expect(tester.widget<Text>(find.text(text)).style?.color, color);
          final BoxDecoration pill = _pillOf(tester, StatusBadge);
          expect(pill.color, AppColors.bgSurface);
          expect((pill.border! as Border).top.color, color);
        });
      }
    }

    testWidgets('gives each status its own words', (WidgetTester tester) async {
      await pumpAppWidget(tester, const SizedBox.shrink());
      final AppLocalizations strings = l10n(tester);

      final Set<String> labels = <String>{
        for (final (String Function(AppLocalizations), Color) entry
            in expected.values)
          entry.$1(strings),
      };

      expect(labels, hasLength(BookingStatusKind.values.length));
    });
  });

  group('AvailabilityBadge', () {
    testWidgets('reads available in green', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: AvailabilityBadge(isAvailable: true)),
      );
      final String text = l10n(tester).availabilityAvailable;

      expect(
        tester.widget<Text>(find.text(text)).style?.color,
        AppColors.statusAccepted,
      );
    });

    testWidgets('reads unavailable in grey', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: AvailabilityBadge(isAvailable: false)),
        locale: arabicLocale,
      );
      final String text = l10n(tester).availabilityUnavailable;

      expect(
        tester.widget<Text>(find.text(text)).style?.color,
        AppColors.statusCompleted,
      );
    });

    testWidgets('is fully rounded, unlike a booking status',
        (WidgetTester tester) async {
      // The shape is how the design tells a service property apart from a
      // booking state.
      await pumpAppWidget(
        tester,
        const Column(
          children: <Widget>[
            AvailabilityBadge(isAvailable: true),
            StatusBadge(BookingStatusKind.accepted),
          ],
        ),
      );

      expect(
        _pillOf(tester, AvailabilityBadge).borderRadius,
        BorderRadius.circular(AppRadii.full),
      );
      expect(
        _pillOf(tester, StatusBadge).borderRadius,
        BorderRadius.circular(AppRadii.md),
      );
    });
  });
}
