/// Money as the design writes it: `45 000`, `2 500.50`.
///
/// The API sends amounts as strings with two decimals, in dinars. They are
/// formatted as strings too — never parsed to a `double` — so an amount is
/// shown exactly as the server stored it.
library;

/// Separates groups of three digits. A no-break space, so an amount never
/// wraps across two lines, and a plain-width one, as the design draws it.
const String amountGroupSeparator = '\u00A0';

final RegExp _amount = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$');

/// Whether [apiAmount] is above zero — a pack with no saving shows no pill.
bool amountIsPositive(String apiAmount) {
  final RegExpMatch? match = _amount.firstMatch(apiAmount.trim());
  if (match == null || match.group(1) == '-') return false;
  return '${match.group(2)}${match.group(3) ?? ''}'
      .split('')
      .any((String digit) => digit != '0');
}

/// [apiAmount] in centimes, for comparing two amounts — never through a
/// `double`. Anything that is not an amount reads as 0.
int amountCents(String apiAmount) {
  final RegExpMatch? match = _amount.firstMatch(apiAmount.trim());
  if (match == null) return 0;
  final String fraction = (match.group(3) ?? '').padRight(2, '0');
  final int cents =
      int.parse(match.group(2)!) * 100 + int.parse(fraction.substring(0, 2));
  return match.group(1) == '-' ? -cents : cents;
}

/// Whole dinars as the API writes money: `400000` → `"400000.00"`.
String apiAmountOf(int dinars) => '$dinars.00';

/// `"120000.00"` → `"120 000"`; `"2500.50"` → `"2 500.50"`.
///
/// A zero fraction is dropped — dinar prices are whole in practice — but any
/// other is kept rather than rounded away. Anything that is not an amount is
/// handed back unchanged, so a bad value shows up instead of vanishing.
String formatAmount(String apiAmount) {
  final RegExpMatch? match = _amount.firstMatch(apiAmount.trim());
  if (match == null) return apiAmount;

  final String sign = match.group(1)!;
  final String whole = match.group(2)!;
  final String? fraction = match.group(3);

  final StringBuffer grouped = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final int fromEnd = whole.length - i;
    if (i > 0 && fromEnd % 3 == 0) grouped.write(amountGroupSeparator);
    grouped.write(whole[i]);
  }

  final bool hasFraction =
      fraction != null && fraction.split('').any((String d) => d != '0');
  return '$sign$grouped${hasFraction ? '.$fraction' : ''}';
}
