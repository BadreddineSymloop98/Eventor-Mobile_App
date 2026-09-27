import 'package:eventor/core/formatting/amount_input.dart';
import 'package:eventor/core/formatting/money_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _typed(String text, {int? caret}) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );

void main() {
  const DinarInputFormatter formatter = DinarInputFormatter();
  const String s = amountGroupSeparator;

  group('DinarInputFormatter', () {
    test('groups digits in threes as they are typed', () {
      final TextEditingValue value =
          formatter.formatEditUpdate(TextEditingValue.empty, _typed('400000'));

      expect(value.text, '400${s}000');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('drops anything that is not a digit', () {
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, _typed('12a,3.4')).text,
        '1${s}234',
      );
    });

    test('drops leading zeros', () {
      expect(formatter.formatEditUpdate(TextEditingValue.empty, _typed('0005')).text, '5');
      expect(formatter.formatEditUpdate(TextEditingValue.empty, _typed('0')).text, '0');
    });

    test('keeps the caret after the digit it followed', () {
      // "1 234" with the caret after the "2", then a "9" typed there.
      final TextEditingValue value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _typed('1${s}2934', caret: 4),
      );

      expect(value.text, '12${s}934');
      expect(value.selection.baseOffset, 4);
    });

    test('refuses more than the maximum digits', () {
      final TextEditingValue before = _typed('123');
      const DinarInputFormatter short = DinarInputFormatter(maxDigits: 3);

      expect(short.formatEditUpdate(before, _typed('1234')), before);
    });

    test('empties to empty', () {
      expect(formatter.formatEditUpdate(_typed('5'), _typed('')).text, '');
    });
  });

  group('parseDinars', () {
    test('reads grouped digits', () {
      expect(parseDinars('400${s}000'), 400000);
    });

    test('reads an empty field as null', () {
      expect(parseDinars(''), isNull);
    });
  });
}
