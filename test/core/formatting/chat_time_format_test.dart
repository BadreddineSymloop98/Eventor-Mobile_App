import 'package:eventor/core/formatting/chat_time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;

/// No Arabic-Indic digit may reach the thread — Western digits only, even
/// for the `ar` locale.
final RegExp _arabicIndicDigits = RegExp('[٠-٩]');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  // Fixed rather than DateTime.now(), so every rung of the ladder is exact
  // regardless of when the suite runs. 2026-03-12 is a Thursday.
  final DateTime now = DateTime(2026, 3, 12, 15);
  const String today = 'Today';
  const String yesterday = 'Yesterday';

  group('clockTime', () {
    test('zero-pads the hour and the minute', () {
      expect(clockTime(DateTime(2026, 3, 12, 9, 24)), '09:24');
      expect(clockTime(DateTime(2026, 3, 12, 0, 5)), '00:05');
    });
  });

  group('listTime', () {
    test('reads earlier today as the clock time', () {
      expect(
        listTime(DateTime(2026, 3, 12, 9, 24),
            now: now, locale: 'en', yesterday: yesterday),
        '09:24',
      );
      expect(
        listTime(DateTime(2026, 3, 12, 0, 5),
            now: now, locale: 'en', yesterday: yesterday),
        '00:05',
      );
    });

    test('treats a minute of clock skew as today, not the future', () {
      final DateTime skewed = now.add(const Duration(minutes: 1));

      expect(
        listTime(skewed, now: now, locale: 'en', yesterday: yesterday),
        clockTime(skewed),
      );
    });

    test('reads yesterday as the word given for it', () {
      expect(
        listTime(DateTime(2026, 3, 11, 23, 59),
            now: now, locale: 'en', yesterday: yesterday),
        yesterday,
      );
    });

    test('reads the short weekday name in English', () {
      expect(
        listTime(DateTime(2026, 3, 9, 10),
            now: now, locale: 'en', yesterday: yesterday),
        'Mon',
      );
    });

    test('reads the full weekday name in Arabic', () {
      // Computed rather than hard-coded, per the standing rule on Arabic
      // spellings in tests.
      final DateTime day = DateTime(2026, 3, 9, 10);

      expect(
        listTime(day, now: now, locale: 'ar', yesterday: yesterday),
        DateFormat.EEEE('ar').format(day),
      );
    });

    test('reads day and month at the 7-day boundary, in English', () {
      expect(
        listTime(DateTime(2026, 3, 5),
            now: now, locale: 'en', yesterday: yesterday),
        '5 Mar',
      );
    });

    test('reads day and month at the 7-day boundary, in Arabic', () {
      final DateTime day = DateTime(2026, 3, 5);

      expect(
        listTime(day, now: now, locale: 'ar', yesterday: yesterday),
        '5 ${DateFormat.MMM('ar').format(day)}',
      );
    });

    test('adds the year once the date is no longer this one', () {
      expect(
        listTime(DateTime(2025, 12, 1),
            now: now, locale: 'en', yesterday: yesterday),
        '1 Dec 2025',
      );
    });

    test('never prints an Arabic-Indic digit, in either locale', () {
      final List<DateTime> ladder = <DateTime>[
        DateTime(2026, 3, 12, 9, 24),
        DateTime(2026, 3, 11, 23, 59),
        DateTime(2026, 3, 9, 10),
        DateTime(2026, 3, 5),
        DateTime(2025, 12, 1),
      ];

      for (final String locale in <String>['en', 'ar']) {
        for (final DateTime time in ladder) {
          final String result =
              listTime(time, now: now, locale: locale, yesterday: yesterday);
          expect(result, isNot(matches(_arabicIndicDigits)), reason: result);
        }
      }
    });
  });

  group('dayLabel', () {
    test('reads today and yesterday as the words given for them', () {
      expect(
        dayLabel(DateTime(2026, 3, 12),
            now: now, locale: 'en', today: today, yesterday: yesterday),
        today,
      );
      expect(
        dayLabel(DateTime(2026, 3, 11),
            now: now, locale: 'en', today: today, yesterday: yesterday),
        yesterday,
      );
    });

    test('falls through to the same ladder as listTime beyond yesterday',
        () {
      expect(
        dayLabel(DateTime(2026, 3, 9),
            now: now, locale: 'en', today: today, yesterday: yesterday),
        'Mon',
      );
      expect(
        dayLabel(DateTime(2026, 3, 5),
            now: now, locale: 'en', today: today, yesterday: yesterday),
        '5 Mar',
      );
      expect(
        dayLabel(DateTime(2025, 12, 1),
            now: now, locale: 'en', today: today, yesterday: yesterday),
        '1 Dec 2025',
      );
    });

    test('never prints an Arabic-Indic digit', () {
      final String result = dayLabel(DateTime(2025, 12, 1),
          now: now, locale: 'ar', today: today, yesterday: yesterday);

      expect(result, isNot(matches(_arabicIndicDigits)), reason: result);
    });
  });

  group('ltrIsolate', () {
    // Written as code points rather than the bidi-control characters
    // themselves, so no invisible character sits in the test source.
    final String leftToRightIsolate = String.fromCharCode(0x2066);
    final String popDirectionalIsolate = String.fromCharCode(0x2069);

    test('wraps the text in a first-strong isolate', () {
      expect(
        ltrIsolate('EVT-2041'),
        '$leftToRightIsolate' 'EVT-2041' '$popDirectionalIsolate',
      );
      expect(ltrIsolate('EVT-2041'), startsWith(leftToRightIsolate));
      expect(ltrIsolate('EVT-2041'), endsWith(popDirectionalIsolate));
    });
  });
}
