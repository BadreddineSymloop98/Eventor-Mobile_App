import 'package:eventor/core/availability/availability_repository.dart';
import 'package:eventor/features/availability/view/widgets/provider_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/availability_fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  // March 2026 starts on a Sunday, so its first week fills one row.
  final DateTime march = DateTime(2026, 3);
  final DateTime today = DateTime(2026, 3, 10);

  AvailabilityMonth monthWith(List<Map<String, Object?>> items) => AvailabilityMonth.fromJson(<String, Object?>{
        'providerId': 'p',
        'month': '2026-03',
        'maxEventsPerDay': 1,
        'days': <Map<String, Object?>>[
          for (int d = 1; d <= 31; d++)
            () {
              final DateTime date = DateTime(2026, 3, d);
              final List<Map<String, Object?>> rows =
                  items.where((Map<String, Object?> i) => i['date'] == dayKey(date)).toList();
              return <String, Object?>{
                'date': dayKey(date),
                'status': ProviderDayStatus.of(rows.map(ProviderDayItem.fromJson).toList()).name,
                'items': rows,
              };
            }(),
        ],
      });

  Future<List<DateTime>> pumpCalendar(
    WidgetTester tester, {
    required Locale locale,
    AvailabilityMonth? data,
  }) async {
    usePhoneSurface(tester);
    final List<DateTime> taps = <DateTime>[];
    await pumpAppWidget(
      tester,
      SingleChildScrollView(
        child: ProviderMonthCalendar(
          month: march,
          data: data ?? monthWith(const <Map<String, Object?>>[]),
          today: today,
          selected: null,
          canGoBack: false,
          onDayTap: taps.add,
          onMonthChanged: (_) {},
        ),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
    return taps;
  }

  double centreX(WidgetTester tester, String day) => tester.getCenter(find.text(day)).dx;
  double centreY(WidgetTester tester, String day) => tester.getCenter(find.text(day)).dy;

  testWidgets('in Arabic, Sunday leads on the right and each number sits under its weekday',
      (WidgetTester tester) async {
    await pumpCalendar(tester, locale: arabicLocale);

    expect(Directionality.of(tester.element(find.byType(ProviderMonthCalendar))), TextDirection.rtl);

    // 1–7 March is Sunday to Saturday: one row, running right to left.
    for (int d = 1; d < 7; d++) {
      expect(centreY(tester, '$d'), centreY(tester, '${d + 1}'));
      expect(centreX(tester, '$d'), greaterThan(centreX(tester, '${d + 1}')));
    }
    // The next Sunday is under the first one, on the right edge.
    expect(centreX(tester, '8'), moreOrLessEquals(centreX(tester, '1'), epsilon: 0.5));
    expect(centreY(tester, '8'), greaterThan(centreY(tester, '1')));
  });

  testWidgets('in English, Sunday leads on the left', (WidgetTester tester) async {
    await pumpCalendar(tester, locale: englishLocale);

    expect(centreX(tester, '1'), lessThan(centreX(tester, '2')));
    expect(centreX(tester, '8'), moreOrLessEquals(centreX(tester, '1'), epsilon: 0.5));
  });

  testWidgets('a past day opens only when something was on it; any day ahead opens',
      (WidgetTester tester) async {
    final List<DateTime> taps = await pumpCalendar(
      tester,
      locale: englishLocale,
      data: monthWith(<Map<String, Object?>>[
        bookingItemJson(bookingId: 'bk', date: DateTime(2026, 3, 5)),
      ]),
    );

    await tester.tap(find.text('4'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('10'));
    await tester.tap(find.text('21'));

    expect(taps, <DateTime>[DateTime(2026, 3, 5), DateTime(2026, 3, 10), DateTime(2026, 3, 21)]);
  });

  testWidgets('shows skeleton cells while the month loads', (WidgetTester tester) async {
    usePhoneSurface(tester);
    await pumpAppWidget(
      tester,
      ProviderMonthCalendar(
        month: march,
        data: null,
        today: today,
        selected: null,
        canGoBack: false,
        onDayTap: (_) {},
        onMonthChanged: (_) {},
      ),
    );

    expect(find.text('21'), findsNothing);
  });
}
