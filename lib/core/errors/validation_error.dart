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

/// Why a person's name was rejected.
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

/// The value is not [requiredDigits] digits beginning with [leadingDigit].
///
/// A local number has one shape, so there is one way to be wrong about it and
/// one sentence that says so — the same sentence the field states as its rule
/// before anything is typed.
class PhoneInvalid extends PhoneError {
  const PhoneInvalid({
    required this.requiredDigits,
    required this.leadingDigit,
  });

  final int requiredDigits;
  final String leadingDigit;
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
