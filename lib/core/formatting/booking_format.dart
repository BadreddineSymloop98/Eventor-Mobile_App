// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

/// `"13:00 → 23:00"`, `"13:00"`, or `""` with no start. Set left to right
/// wherever it is shown, so the arrow keeps pointing from start to end.
///
/// An end at or before the start is the next day — an event running past
/// midnight — and gets [nextDay] after it: `"18:00 → 02:00 (+1 day)"`.
String timeRange(String? start, String? end, {String? nextDay}) {
  if (start == null) return '';
  if (end == null) return start;
  final String mark =
      nextDay != null && endsNextDay(start, end) ? ' ($nextDay)' : '';
  return '$start → $end$mark';
}

/// `"18:30"` → 1110. `null` for no time.
int? minutesOfDay(String? hm) {
  if (hm == null) return null;
  final List<String> parts = hm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// The end falls on the day after the event date. An end equal to the start
/// counts too: the only way to read it is a full day.
bool endsNextDay(String? start, String? end) {
  final int? from = minutesOfDay(start);
  final int? to = minutesOfDay(end);
  return from != null && to != null && to <= from;
}

/// Minutes from [start] to [end], an end past midnight counting on.
int spanMinutes(String start, String end) {
  final int span = minutesOfDay(end)! - minutesOfDay(start)!;
  return span <= 0 ? span + _day : span;
}

const int _day = 24 * 60;
const int _slot = 30;

String _hm(int minutes) {
  final int m = minutes % _day;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// "Saturday 14 March" / "السبت 14 مارس" — B1b's taken day.
String weekdayDayMonth(DateTime date, String locale) =>
    '${DateFormat.EEEE(locale).format(date)} ${date.day} '
    '${DateFormat.MMMM(locale).format(date)}';

/// "Saturday 14 March 2026" — the booking's date on B4 and the invoice.
String fullDate(DateTime date, String locale) =>
    '${weekdayDayMonth(date, locale)} ${date.year}';

/// "14:20" — a timeline entry's clock time, local.
String clockTime(DateTime at) {
  final DateTime local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Every half hour of the day — the From picker.
List<String> halfHourSlots() => <String>[
      for (int m = 0; m < _day; m += _slot) _hm(m),
    ];

/// The To picker once [start] is set: every half hour from 30 minutes after
/// it to 30 minutes before it the next day, in order — so the list reads as
/// a growing duration, and the start itself (a 24-hour event) is not in it.
List<String> endSlotsAfter(String start) {
  final int from = minutesOfDay(start)!;
  return <String>[
    for (int m = from + _slot; m < from + _day; m += _slot) _hm(m),
  ];
}
