import 'package:flutter/services.dart';

import 'money_format.dart';

/// Whole dinars as they are typed: digits only, grouped in threes as the
/// design writes money — `400 000`. The caret stays after the digit it
/// followed, however many separators appear or vanish before it.
class DinarInputFormatter extends TextInputFormatter {
  const DinarInputFormatter({this.maxDigits = 12});

  /// 12 digits is under a thousand billion dinars — far above any event, and
  /// well inside an `int`.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // No leading zeros: "0" then "5" reads 5, not 05.
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > maxDigits) return oldValue;

    final int caretDigits = newValue.selection.baseOffset < 0
        ? digits.length
        : newValue.text
            .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
            .replaceAll(RegExp(r'\D'), '')
            .length
            .clamp(0, digits.length);

    final String text = groupDinars(digits);
    int caret = 0;
    for (int seen = 0; caret < text.length && seen < caretDigits; caret++) {
      if (text[caret] != amountGroupSeparator) seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}

/// `"400000"` → `"400 000"`; an empty string stays empty.
String groupDinars(String digits) =>
    digits.isEmpty ? '' : formatAmount(digits);

/// The dinars in a field [DinarInputFormatter] shaped — `null` when it is
/// empty.
int? parseDinars(String text) {
  final String digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : int.parse(digits);
}
