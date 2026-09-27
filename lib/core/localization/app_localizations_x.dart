import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../errors/failure.dart';
import '../errors/validation_error.dart';

/// Shorthand for reaching the strings: `context.l10n.logIn`.
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
      NetworkFailure() => errorNetwork,
      SessionExpiredFailure() => errorSessionExpired,
      // The server's sentence is already in the request's language; it is
      // only replaced when it is missing.
      ApiFailure(:final String message) =>
        message.trim().isEmpty ? errorUnexpected : message,
      UnexpectedFailure() => errorUnexpected,
    };
  }

  String forEmailError(EmailError error) {
    return switch (error) {
      EmailRequired() => emailRequired,
      EmailInvalid() => emailInvalid,
      EmailTaken() => emailTaken,
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
      PhoneInvalid() => phoneInvalid,
      PhoneTaken() => phoneTaken,
    };
  }

  String forPasswordError(PasswordError error) {
    return switch (error) {
      PasswordRequired() => passwordRequired,
      PasswordTooShort(:final int minimumLength) =>
        passwordTooShort(minimumLength),
      PasswordNeedsLetterAndDigit() => passwordNeedsLetterAndDigit,
      PasswordWeak() => passwordWeak,
      PasswordMismatch() => passwordMismatch,
    };
  }

  String forDocumentError(DocumentError error) {
    return switch (error) {
      DocumentMissing() => documentMissing,
      DocumentTooLarge(:final int maximumMegabytes) =>
        documentTooLarge(maximumMegabytes),
      DocumentWrongType() => documentWrongType,
      DocumentUploadFailed() => documentUploadFailed,
    };
  }
}
