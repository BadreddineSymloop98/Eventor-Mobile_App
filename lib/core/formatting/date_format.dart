// Only DateFormat: intl's own TextDirection would shadow Flutter's.
import 'package:intl/intl.dart' show DateFormat;

/// "Sat 14 Mar" / "السبت 14 مارس".
///
/// Built from parts rather than one `DateFormat` pattern: intl writes Arabic
/// dates in Arabic-Indic digits, and the app uses Western digits everywhere.
/// The names come from intl; the day number is written here.
String shortDate(DateTime date, String locale) =>
    '${DateFormat.E(locale).format(date)} ${date.day} '
    '${DateFormat.MMM(locale).format(date)}';

/// "Sat 14 Mar 2026" / "السبت 14 مارس 2026" — [shortDate] with the year.
String longDate(DateTime date, String locale) =>
    '${shortDate(date, locale)} ${date.year}';

/// "12 May 2025" / "12 مايو 2025" — a day on record, no weekday.
String dayMonthYear(DateTime date, String locale) =>
    '${date.day} ${DateFormat.MMMM(locale).format(date)} ${date.year}';
