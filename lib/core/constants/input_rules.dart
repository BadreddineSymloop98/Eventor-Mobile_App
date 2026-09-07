import 'package:flutter/services.dart';

/// The rules the app's inputs enforce.
///
/// The formatter that blocks bad keystrokes, the hint that describes the rule
/// and the validator that checks it all read from here, so the three can never
/// disagree about what a valid value is.
abstract final class InputRules {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 64;

  /// RFC 5321 caps an address at 254 characters.
  static const int maxEmailLength = 254;

  /// Deliberately permissive: it rejects obvious typos without turning away
  /// addresses that are unusual but valid.
  static final RegExp emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// No address contains whitespace, so it is never worth accepting a space
  /// and failing validation later.
  static final List<TextInputFormatter> emailFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_whitespace),
    LengthLimitingTextInputFormatter(maxEmailLength),
  ];

  /// Whitespace in a password is almost always an accidental space or a
  /// trailing newline from a paste.
  static final List<TextInputFormatter> passwordFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_whitespace),
    LengthLimitingTextInputFormatter(maxPasswordLength),
  ];

  static const int minNameLength = 2;
  static const int maxNameLength = 80;

  /// A local number, written in full: ten digits beginning with a zero.
  ///
  /// This deliberately turns away an international `+` form — the app asks for
  /// the number the way it is dialled locally, and one shape is easier to
  /// state, to check and to store than two.
  static const int phoneLength = 10;
  static const String phoneLeadingDigit = '0';

  /// A name is rejected for what it must *not* contain rather than for what it
  /// may. An allow-list of letters would have to enumerate every script the
  /// app serves, and would throw out a legitimate Arabic name the day it
  /// missed one.
  static final List<TextInputFormatter> nameFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_digitsOrSymbols),
    LengthLimitingTextInputFormatter(maxNameLength),
  ];

  /// Digits, and no more of them than the number holds.
  static final List<TextInputFormatter> phoneFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(phoneLength),
  ];

  /// The digits of [phone] on their own.
  ///
  /// The formatter above already keeps everything else out as it is typed, but
  /// a value set programmatically — a paste, an autofill — never passes
  /// through it, so the check reads through any spacing it brought with it.
  static String phoneDigits(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  /// Whether [phone] is a whole local number.
  static bool isPhoneComplete(String phone) {
    final String digits = phoneDigits(phone);
    return digits.length == phoneLength &&
        digits.startsWith(phoneLeadingDigit);
  }

  /// How many digits a verification code carries.
  static const int verificationCodeLength = 6;

  /// Digits and nothing else. A code has no formatting of its own.
  static final List<TextInputFormatter> verificationCodeFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(verificationCodeLength),
  ];

  static final RegExp _whitespace = RegExp(r'\s');

  /// Digits, and the punctuation that has no business in a person's name.
  /// Hyphens and apostrophes are deliberately absent — plenty of names have
  /// them.
  static final RegExp _digitsOrSymbols = RegExp(r'[0-9_@#$%^&*()+=\[\]{}<>/\\|~`]');
}
