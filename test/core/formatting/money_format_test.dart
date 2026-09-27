import 'package:eventor/core/formatting/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// The group separator: a no-break space, so an amount never wraps mid-number.
const String _nbsp = ' ';

void main() {
  group('formatAmount', () {
    test('groups thousands and drops a zero fraction', () {
      expect(formatAmount('120000.00'), '120${_nbsp}000');
      expect(formatAmount('45000.00'), '45${_nbsp}000');
      expect(formatAmount('1200.00'), '1${_nbsp}200');
    });

    test('groups millions', () {
      expect(formatAmount('2500000.00'), '2${_nbsp}500${_nbsp}000');
    });

    test('leaves small amounts ungrouped', () {
      expect(formatAmount('950.00'), '950');
      expect(formatAmount('0.00'), '0');
    });

    test('keeps a fraction that is not zero', () {
      expect(formatAmount('2500.50'), '2${_nbsp}500.50');
    });

    test('accepts an amount without a fraction', () {
      expect(formatAmount('45000'), '45${_nbsp}000');
    });

    test('never parses through a double', () {
      // 0.1 + 0.2 style drift would show here if it did.
      expect(formatAmount('99999999999.99'),
          '99${_nbsp}999${_nbsp}999${_nbsp}999.99');
    });

    test('hands back anything that is not an amount untouched', () {
      expect(formatAmount(''), '');
      expect(formatAmount('abc'), 'abc');
    });
  });
}
