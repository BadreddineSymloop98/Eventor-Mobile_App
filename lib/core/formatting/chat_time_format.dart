// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

/// "09:24" — always zero-padded, Western digits.
///
/// Built by hand rather than with `DateFormat.Hm`: intl writes Arabic-Indic
/// digits for the `ar` locale, and the app never lets a clock time do that.
String clockTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Calendar days between [earlier] and [later], as UTC dates so the time of
/// day and DST cannot shift the count.
int _daysBetween(DateTime earlier, DateTime later) =>
    DateTime.utc(later.year, later.month, later.day)
        .difference(DateTime.utc(earlier.year, earlier.month, earlier.day))
        .inDays;

/// The weekday name for the "less than a week ago" rung of the ladder — the
/// design shows it short in English ("Mon") and spelled out in Arabic.
String _weekday(DateTime t, String locale) =>
    locale == 'ar' ? DateFormat.EEEE('ar').format(t) : DateFormat.E(locale).format(t);

/// "5 Mar" — the day written by hand, so it stays Western even in Arabic;
/// only the month name comes from intl.
String _dayMonth(DateTime t, String locale) =>
    '${t.day} ${DateFormat.MMM(locale).format(t)}';

/// A message's timestamp in the thread list — the same ladder the design
/// uses everywhere a time collapses to a day: today's clock time, then
/// "yesterday", then the weekday, then the date, then the date with a year
/// once it is no longer this one.
///
/// [now] is a parameter rather than [DateTime.now] so tests are exact and a
/// clock a minute fast on the server does not read as "in the future" — a
/// [time] after [now] still counts as today.
String listTime(
  DateTime time, {
  required DateTime now,
  required String locale,
  required String yesterday,
}) {
  final int days = _daysBetween(time, now);
  if (days <= 0) return clockTime(time);
  if (days == 1) return yesterday;
  if (days < 7) return _weekday(time, locale);
  if (time.year == now.year) return _dayMonth(time, locale);
  return '${_dayMonth(time, locale)} ${time.year}';
}

/// The same ladder as [listTime], but for a day header inside the thread —
/// so today reads as [today] rather than a clock time.
String dayLabel(
  DateTime day, {
  required DateTime now,
  required String locale,
  required String today,
  required String yesterday,
}) {
  final int days = _daysBetween(day, now);
  if (days <= 0) return today;
  if (days == 1) return yesterday;
  if (days < 7) return _weekday(day, locale);
  if (day.year == now.year) return _dayMonth(day, locale);
  return '${_dayMonth(day, locale)} ${day.year}';
}

/// LEFT-TO-RIGHT ISOLATE and POP DIRECTIONAL ISOLATE — written as code
/// points rather than the bidi-control characters themselves, so the source
/// carries no invisible characters a reviewer cannot see.
const int _leftToRightIsolate = 0x2066;
const int _popDirectionalIsolate = 0x2069;

/// Wraps [text] in a first-strong isolate, so a booking reference or a time
/// interpolated into an Arabic row keeps its own digit order instead of
/// being reversed by the surrounding RTL run — the standing "Arabic number
/// token rows" rule.
String ltrIsolate(String text) =>
    String.fromCharCode(_leftToRightIsolate) +
    text +
    String.fromCharCode(_popDirectionalIsolate);
