import 'package:flutter/services.dart';

import '../errors/validation_error.dart';

/// The rules the app's inputs enforce.
///
/// The formatter that blocks bad keystrokes, the hint that describes the rule
/// and the validator that checks it all read from here, so the three can never
/// disagree about what a valid value is. The bounds are the API's own — a
/// value that passes here is one the server accepts.
abstract final class InputRules {
  /// The API's password floor. The live value comes from `/app/config`
  /// (`passwordPolicy.minLength`); this is the fallback and today's value.
  static const int minPasswordLength = 10;
  static const int maxPasswordLength = 128;

  /// The API caps an address at 190 characters.
  static const int maxEmailLength = 190;

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

  /// Whether [password] has at least one letter and one digit — the second
  /// half of the API's rule. Letters in any script count.
  static bool hasLetterAndDigit(String password) =>
      RegExp(r'\p{L}', unicode: true).hasMatch(password) &&
      RegExp(r'\d').hasMatch(password);

  /// Checks a password being *chosen* — sign-up, reset, invite — against the
  /// server's policy. Login does not use this: it has no minimum.
  static PasswordError? validateNewPassword(
    String password, {
    int minLength = minPasswordLength,
    bool needsLetterAndDigit = true,
  }) {
    if (password.isEmpty) return const PasswordRequired();
    if (password.length < minLength) return PasswordTooShort(minLength);
    if (needsLetterAndDigit && !hasLetterAndDigit(password)) {
      return const PasswordNeedsLetterAndDigit();
    }
    return null;
  }

  /// What an attached document may be. A scan arrives as a PDF and a
  /// photograph of a card as an image.
  static const List<String> documentExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  /// Stated in whole megabytes because that is how the message says it. The
  /// server's value comes back with the documents; this is the fallback.
  static const int maxDocumentMegabytes = 5;
  static const int maxDocumentBytes = maxDocumentMegabytes * 1024 * 1024;

  /// Whether [extension] is a document this app accepts.
  static bool isAcceptableDocumentType(String extension) =>
      documentExtensions.contains(extension.toLowerCase());

  static const int minNameLength = 2;

  /// The API's cap on `fullName`.
  static const int maxNameLength = 120;

  static const int minBusinessNameLength = 2;

  /// The API's cap on `businessName`.
  static const int maxBusinessNameLength = 150;

  /// A local Algerian number: ten digits beginning with a zero.
  static const int phoneLength = 10;
  static const String phoneLeadingDigit = '0';

  /// The country code the server stores every number with.
  static const String phoneCountryCode = '+213';

  /// A name is rejected for what it must *not* contain rather than for what it
  /// may. An allow-list of letters would have to enumerate every script the
  /// app serves, and would throw out a legitimate Arabic name the day it
  /// missed one.
  static final List<TextInputFormatter> nameFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.deny(_digitsOrSymbols),
    LengthLimitingTextInputFormatter(maxNameLength),
  ];

  /// A business name legitimately carries digits and punctuation — "Studio
  /// 21", "Salle d'Or" — so only its length is bounded.
  static final List<TextInputFormatter> businessNameFormatters =
      <TextInputFormatter>[
    LengthLimitingTextInputFormatter(maxBusinessNameLength),
  ];

  /// Digits, a leading `+` and the spaces people type between groups — the
  /// field accepts a number written either way the API does.
  static final List<TextInputFormatter> phoneFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
    LengthLimitingTextInputFormatter(17),
  ];

  /// [phone] in the local form, `0XXXXXXXXX`, or `null` when it is not a
  /// whole Algerian number in either form.
  ///
  /// Accepts `0555 12 34 56`, `+213 555 12 34 56` and `213555123456`. The
  /// server stores and returns `+213…`, so a number coming back from a profile
  /// normalises here too.
  static String? normalisePhone(String phone) {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String local = digits.startsWith('213') && digits.length == 12
        ? '0${digits.substring(3)}'
        : digits;
    if (local.length != phoneLength || !local.startsWith(phoneLeadingDigit)) {
      return null;
    }
    return local;
  }

  /// Whether [phone] is a whole number in either form.
  static bool isPhoneComplete(String phone) => normalisePhone(phone) != null;

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
  static final RegExp _digitsOrSymbols =
      RegExp(r'[0-9_@#$%^&*()+=\[\]{}<>/\\|~`]');
}
