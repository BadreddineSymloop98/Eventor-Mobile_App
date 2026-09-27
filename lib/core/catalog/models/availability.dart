import 'json_read.dart';

/// One day on a service's or a pack's calendar.
enum DayState {
  /// Can be requested.
  available,

  /// Fully booked — the day's capacity is used up.
  busy,

  /// Not offered: blocked by the provider, or too soon to book.
  blocked;

  static DayState fromApi(String? value) => switch (value) {
        'available' => available,
        'busy' => busy,
        _ => blocked,
      };
}

class AvailabilityDay {
  const AvailabilityDay({required this.date, required this.state});

  factory AvailabilityDay.fromJson(Map<String, Object?> json) =>
      AvailabilityDay(
        date: readDate(json, 'date'),
        state: DayState.fromApi(json['state'] as String?),
      );

  /// Local midnight.
  final DateTime date;
  final DayState state;
}

/// A month of a calendar. For a pack, a day is available only when every
/// service in it is free.
class Availability {
  Availability({
    required this.month,
    required this.minNoticeDays,
    required this.firstBookableDate,
    required List<AvailabilityDay> days,
  }) : _byDay = <int, DayState>{
          for (final AvailabilityDay day in days) _key(day.date): day.state,
        };

  factory Availability.fromJson(Map<String, Object?> json) => Availability(
        month: readString(json, 'month'),
        minNoticeDays: readInt(json, 'minNoticeDays'),
        firstBookableDate: readDate(json, 'firstBookableDate'),
        days: readList(json, 'days', AvailabilityDay.fromJson),
      );

  /// `"2026-03"`.
  final String month;
  final int minNoticeDays;

  /// The earliest day that can be requested at all, in Algiers time.
  final DateTime firstBookableDate;
  final Map<int, DayState> _byDay;

  /// The state of [day]. A day the server did not list is not bookable.
  DayState stateOf(DateTime day) => _byDay[_key(day)] ?? DayState.blocked;

  static int _key(DateTime day) => day.year * 10000 + day.month * 100 + day.day;
}
