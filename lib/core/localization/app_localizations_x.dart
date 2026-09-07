import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/failure.dart';
import '../errors/validation_error.dart';

/// Shorthand for reaching the strings: `context.l10n.signIn`.
extension LocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Turns the typed errors produced by view models into sentences.
///
/// Every `switch` here is exhaustive over a sealed hierarchy, so adding a new
/// error without a message for it fails the build.
extension AppLocalizationsX on AppLocalizations {
  String forFailure(Failure failure) {
    return switch (failure) {
      StorageFailure() => errorStorage,
      UnexpectedFailure() => errorUnexpected,
    };
  }

  String forEmailError(EmailError error) {
    return switch (error) {
      EmailRequired() => emailRequired,
      EmailInvalid() => emailInvalid,
    };
  }

  String forNameError(NameError error) {
    return switch (error) {
      NameRequired() => nameRequired,
      NameTooShort(:final int minimumLength) => nameTooShort(minimumLength),
    };
  }

  String forPhoneError(PhoneError error) {
    return switch (error) {
      PhoneRequired() => phoneRequired,
      PhoneInvalid(
        :final int requiredDigits,
        :final String leadingDigit,
      ) =>
        phoneInvalid(requiredDigits, leadingDigit),
    };
  }

  String forPasswordError(PasswordError error) {
    return switch (error) {
      PasswordRequired() => passwordRequired,
      PasswordTooShort(:final int minimumLength) =>
        passwordTooShort(minimumLength),
    };
  }
}
