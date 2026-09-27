/// Why a field's value was rejected, as a type rather than as a message.
///
/// A view model validates without a [BuildContext], so it cannot produce a
/// localised sentence. It returns one of these instead and the view turns it
/// into text — see `AppLocalizationsX` in `core/localization`.
///
/// Each hierarchy is sealed so that the `switch` translating it is exhaustive.
library;

/// Why an email address was rejected.
sealed class EmailError {
  const EmailError();
}

/// The field was left empty.
class EmailRequired extends EmailError {
  const EmailRequired();
}

/// The value does not look like an address.
class EmailInvalid extends EmailError {
  const EmailInvalid();
}

/// Another account already uses it — the server's `EMAIL_TAKEN`.
class EmailTaken extends EmailError {
  const EmailTaken();
}

/// Why a person's or a business's name was rejected.
sealed class NameError {
  const NameError();
}

/// The field was left empty.
class NameRequired extends NameError {
  const NameRequired();
}

/// The value is shorter than [minimumLength].
class NameTooShort extends NameError {
  const NameTooShort(this.minimumLength);

  final int minimumLength;
}

/// Why a phone number was rejected.
sealed class PhoneError {
  const PhoneError();
}

/// The field was left empty.
class PhoneRequired extends PhoneError {
  const PhoneRequired();
}

/// Not a whole Algerian number in either accepted form.
class PhoneInvalid extends PhoneError {
  const PhoneInvalid();
}

/// Another account already uses it — the server's `PHONE_TAKEN`.
class PhoneTaken extends PhoneError {
  const PhoneTaken();
}

/// Why a password was rejected.
sealed class PasswordError {
  const PasswordError();
}

/// The field was left empty.
class PasswordRequired extends PasswordError {
  const PasswordRequired();
}

/// The value is shorter than [minimumLength].
///
/// The bound travels with the error so that the message can state it without
/// the view having to know the rule.
class PasswordTooShort extends PasswordError {
  const PasswordTooShort(this.minimumLength);

  final int minimumLength;
}

/// Long enough, but without both a letter and a digit.
class PasswordNeedsLetterAndDigit extends PasswordError {
  const PasswordNeedsLetterAndDigit();
}

/// The server refused it as too common or too weak — `PASSWORD_WEAK`.
class PasswordWeak extends PasswordError {
  const PasswordWeak();
}

/// The confirmation does not match the password above it.
class PasswordMismatch extends PasswordError {
  const PasswordMismatch();
}

/// Why a required choice — a category, the wilayas served — was rejected.
sealed class SelectionError {
  const SelectionError();
}

/// Nothing was picked.
class SelectionRequired extends SelectionError {
  const SelectionRequired();
}

/// Why a document was rejected.
sealed class DocumentError {
  const DocumentError();
}

/// Nothing was attached.
class DocumentMissing extends DocumentError {
  const DocumentMissing();
}

/// The file is over [maximumMegabytes].
class DocumentTooLarge extends DocumentError {
  const DocumentTooLarge(this.maximumMegabytes);

  final int maximumMegabytes;
}

/// The file is not one of the accepted kinds.
class DocumentWrongType extends DocumentError {
  const DocumentWrongType();
}

/// The upload itself failed — no connection, or the server refused it.
class DocumentUploadFailed extends DocumentError {
  const DocumentUploadFailed();
}
