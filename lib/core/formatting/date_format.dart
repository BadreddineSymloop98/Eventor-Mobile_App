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
