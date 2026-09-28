import 'package:eventor/core/formatting/booking_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timeRange', () {
    test('a same-day range has no mark', () {
      expect(timeRange('13:00', '23:00', nextDay: '+1 day'), '13:00 → 23:00');
    });

    test('an end past midnight is marked as the next day', () {
      expect(timeRange('18:00', '02:00', nextDay: '+1 day'), '18:00 → 02:00 (+1 day)');
    });

    test('without a mark to show, the range is plain', () {
      expect(timeRange('18:00', '02:00'), '18:00 → 02:00');
    });

    test('a start alone, or nothing', () {
      expect(timeRange('18:00', null, nextDay: '+1 day'), '18:00');
      expect(timeRange(null, '02:00'), '');
    });
  });

  group('endsNextDay', () {
    test('only an end at or before the start', () {
      expect(endsNextDay('18:00', '23:30'), isFalse);
      expect(endsNextDay('18:00', '00:00'), isTrue);
      expect(endsNextDay('18:00', '18:00'), isTrue);
      expect(endsNextDay('18:00', null), isFalse);
    });
  });

  group('spanMinutes', () {
    test('counts on past midnight', () {
      expect(spanMinutes('18:00', '23:00'), 300);
      expect(spanMinutes('20:00', '02:00'), 360);
      expect(spanMinutes('00:00', '23:30'), 1410);
    });
  });

  group('endSlotsAfter', () {
    test('runs from half an hour after the start to half an hour before it', () {
      final List<String> slots = endSlotsAfter('18:00');

      expect(slots, hasLength(47));
      expect(slots.first, '18:30');
      expect(slots, containsAllInOrder(<String>['23:30', '00:00', '02:00']));
      expect(slots.last, '17:30');
      expect(slots, isNot(contains('18:00')));
    });

    test('from a late start, crosses midnight at once', () {
      final List<String> slots = endSlotsAfter('23:30');

      expect(slots.first, '00:00');
      expect(slots.last, '23:00');
    });
  });
}
