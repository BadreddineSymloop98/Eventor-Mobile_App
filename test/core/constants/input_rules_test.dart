import 'package:eventor/core/constants/input_rules.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [value] through [formatters] the way a field would on a paste.
String _format(List<TextInputFormatter> formatters, String value) {
  TextEditingValue result = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
  for (final TextInputFormatter formatter in formatters) {
    result = formatter.formatEditUpdate(TextEditingValue.empty, result);
  }
  return result.text;
}

void main() {
  group('InputRules.normalisePhone', () {
    test('keeps a local number as it is', () {
      expect(InputRules.normalisePhone('0555123456'), '0555123456');
    });

    test('drops the spaces people type between groups', () {
      expect(InputRules.normalisePhone('0555 12 34 56'), '0555123456');
    });

    test('turns the international form into the local one', () {
      // The server stores `+213…`, so a number read back from a profile must
      // land in the same form the field produces.
      expect(InputRules.normalisePhone('+213 555 12 34 56'), '0555123456');
      expect(InputRules.normalisePhone('+213555123456'), '0555123456');
      expect(InputRules.normalisePhone('213555123456'), '0555123456');
    });

    test('rejects a number that is not whole', () {
      expect(InputRules.normalisePhone(''), isNull);
      expect(InputRules.normalisePhone('055512345'), isNull);
      expect(InputRules.normalisePhone('05551234567'), isNull);
      expect(InputRules.normalisePhone('+21355512345'), isNull);
    });

    test('rejects ten digits that do not start with a zero', () {
      expect(InputRules.normalisePhone('5551234567'), isNull);
    });

    test('rejects a trunk zero kept after the country code', () {
      // `+213 0555…` is a common mistake; it is thirteen digits, which is
      // neither form.
      expect(InputRules.normalisePhone('+213 0555 12 34 56'), isNull);
    });

    test('is what isPhoneComplete answers from', () {
      expect(InputRules.isPhoneComplete('+213 555 12 34 56'), isTrue);
      expect(InputRules.isPhoneComplete('0555'), isFalse);
    });
  });

  group('InputRules.hasLetterAndDigit', () {
    test('needs both halves', () {
      expect(InputRules.hasLetterAndDigit('abcdefghij'), isFalse);
      expect(InputRules.hasLetterAndDigit('1234567890'), isFalse);
      expect(InputRules.hasLetterAndDigit('abcde12345'), isTrue);
    });

    test('counts letters in any script', () {
      // An Arabic speaker's password is as valid as a Latin one.
      expect(InputRules.hasLetterAndDigit('كلمةسرية12'), isTrue);
      expect(InputRules.hasLetterAndDigit('Élodie2024'), isTrue);
    });

    test('does not count symbols as letters', () {
      expect(InputRules.hasLetterAndDigit(r'!@#$%^&*12'), isFalse);
    });
  });

  group('InputRules.validateNewPassword', () {
    test('asks for a password when there is none', () {
      expect(InputRules.validateNewPassword(''), isA<PasswordRequired>());
    });

    test('holds a new password to the API floor of ten', () {
      expect(InputRules.minPasswordLength, 10);
      expect(
        InputRules.validateNewPassword('abc12345'),
        isA<PasswordTooShort>().having(
          (PasswordTooShort error) => error.minimumLength,
          'minimumLength',
          10,
        ),
      );
    });

    test('asks for a letter and a digit once it is long enough', () {
      expect(
        InputRules.validateNewPassword('abcdefghijk'),
        isA<PasswordNeedsLetterAndDigit>(),
      );
      expect(
        InputRules.validateNewPassword('12345678901'),
        isA<PasswordNeedsLetterAndDigit>(),
      );
    });

    test('accepts a password that meets the whole rule', () {
      expect(InputRules.validateNewPassword('abcdefgh12'), isNull);
      expect(InputRules.validateNewPassword('كلمةمرور2024'), isNull);
    });

    test('follows the server policy it is given', () {
      // `/app/config` states the rule; the app must not be stricter or
      // looser than it.
      expect(
        InputRules.validateNewPassword('abc1', minLength: 4),
        isNull,
      );
      expect(
        InputRules.validateNewPassword('abcdefghij', needsLetterAndDigit: false),
        isNull,
      );
      expect(
        InputRules.validateNewPassword('abcdefgh12', minLength: 12),
        isA<PasswordTooShort>().having(
          (PasswordTooShort error) => error.minimumLength,
          'minimumLength',
          12,
        ),
      );
    });
  });

  group('the formatters', () {
    test('cap an email at the API limit and strip spaces', () {
      final String long = '${'a' * 200}@example.com';

      expect(InputRules.maxEmailLength, 190);
      expect(_format(InputRules.emailFormatters, long).length, 190);
      expect(
        _format(InputRules.emailFormatters, ' amina @example.com'),
        'amina@example.com',
      );
    });

    test('cap a password at 128 characters and strip whitespace', () {
      expect(
        _format(InputRules.passwordFormatters, 'a' * 200).length,
        InputRules.maxPasswordLength,
      );
      expect(_format(InputRules.passwordFormatters, 'abc 123\n'), 'abc123');
    });

    test('cap a name at 120 characters and keep hyphens and apostrophes', () {
      expect(InputRules.maxNameLength, 120);
      expect(_format(InputRules.nameFormatters, 'x' * 150).length, 120);
      expect(
        _format(InputRules.nameFormatters, "Aït-Ahmed O'Brien"),
        "Aït-Ahmed O'Brien",
      );
      expect(_format(InputRules.nameFormatters, 'Amina2'), 'Amina');
    });

    test('let a business name carry digits and punctuation', () {
      expect(
        _format(InputRules.businessNameFormatters, "Studio 21 — Salle d'Or"),
        "Studio 21 — Salle d'Or",
      );
      expect(
        _format(InputRules.businessNameFormatters, 'x' * 200).length,
        InputRules.maxBusinessNameLength,
      );
    });

    test('let a phone be typed in either form', () {
      expect(
        _format(InputRules.phoneFormatters, '+213 555 12 34 56'),
        '+213 555 12 34 56',
      );
      expect(_format(InputRules.phoneFormatters, '0555-12-34-56'), '0555123456');
    });
  });

  group('InputRules documents', () {
    test('accept scans and photographs, whatever the case', () {
      expect(InputRules.isAcceptableDocumentType('PDF'), isTrue);
      expect(InputRules.isAcceptableDocumentType('jpeg'), isTrue);
      expect(InputRules.isAcceptableDocumentType('png'), isTrue);
      expect(InputRules.isAcceptableDocumentType('docx'), isFalse);
    });

    test('state the size limit in bytes and megabytes alike', () {
      expect(
        InputRules.maxDocumentBytes,
        InputRules.maxDocumentMegabytes * 1024 * 1024,
      );
    });
  });
}
