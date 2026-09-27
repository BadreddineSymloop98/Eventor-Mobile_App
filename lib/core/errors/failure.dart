/// Everything that can go wrong, as a type rather than as a message.
///
/// View models have no [BuildContext] and so cannot resolve a localised
/// string; they report *what* failed and leave the wording to the view. The
/// hierarchy is sealed, so the `switch` that turns a failure into a message is
/// exhaustive — adding a case here without localising it is a compile error
/// rather than a blank label in production.
///
/// Failures are thrown by repositories and caught by
/// `BaseViewModel.runGuarded`, which is why this implements [Exception].
sealed class Failure implements Exception {
  const Failure({this.cause});

  /// The original error, kept for logging. Never shown to the user.
  final Object? cause;
}

/// Writing to on-device storage failed.
class StorageFailure extends Failure {
  const StorageFailure({super.cause});
}

/// The request never got an answer: no connection, a timeout, DNS.
///
/// Distinct from [ApiFailure] because the fix is on the user's side — check
/// the connection and try again — and nothing about the request was wrong.
class NetworkFailure extends Failure {
  const NetworkFailure({super.cause});
}

/// The server answered with its error envelope.
///
/// [code] is the stable `UPPER_SNAKE` value from the API — see [ApiErrorCode]
/// — and is what the app switches on. [message] is the server's own sentence,
/// already translated through `Accept-Language`; it is shown only when the app
/// has nothing more specific of its own to say.
class ApiFailure extends Failure {
  const ApiFailure({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
    this.fieldErrors = const <FieldError>[],
    super.cause,
  });

  final int statusCode;
  final String code;
  final String message;

  /// The envelope's `details` when it is an object — `retryAfterSeconds`,
  /// `email`, an admin's `message`.
  final Map<String, Object?>? details;

  /// Per-field problems, when `details` is the field list of a
  /// `VALIDATION_FAILED`.
  final List<FieldError> fieldErrors;

  /// Seconds to wait, from `details.retryAfterSeconds`, when the server gave
  /// one.
  int? get retryAfterSeconds {
    final Object? value = details?['retryAfterSeconds'];
    return value is num ? value.toInt() : null;
  }

  @override
  String toString() => 'ApiFailure($statusCode $code: $message)';
}

/// The session ended underneath the user — the refresh token was refused or
/// revoked — and they have to sign in again.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({super.cause});
}

/// Anything with no more specific type. The catch-all in [Failure] mapping.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.cause});
}

/// One field the server refused, from a `VALIDATION_FAILED` envelope.
class FieldError {
  const FieldError({
    required this.field,
    required this.code,
    required this.message,
  });

  /// The request's own property name — `email`, `phone`, `password`.
  final String field;
  final String code;

  /// Already translated.
  final String message;
}

/// The API error codes the app acts on.
///
/// The server's list has ~190 values; only the ones some screen reacts to are
/// named here, so a new one on the server never breaks the build — it falls
/// through to the server's own message.
abstract final class ApiErrorCode {
  static const String validationFailed = 'VALIDATION_FAILED';
  static const String rateLimited = 'RATE_LIMITED';

  // Session.
  static const String authTokenMissing = 'AUTH_TOKEN_MISSING';
  static const String authTokenInvalid = 'AUTH_TOKEN_INVALID';
  static const String authTokenExpired = 'AUTH_TOKEN_EXPIRED';
  static const String authSessionRevoked = 'AUTH_SESSION_REVOKED';
  static const String authRefreshInvalid = 'AUTH_REFRESH_INVALID';

  // Sign-in and sign-up.
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String emailNotVerified = 'EMAIL_NOT_VERIFIED';
  static const String accountLocked = 'ACCOUNT_LOCKED';
  static const String accountBlocked = 'ACCOUNT_BLOCKED';
  static const String roleNotAllowedInApp = 'ROLE_NOT_ALLOWED_IN_APP';
  static const String emailTaken = 'EMAIL_TAKEN';
  static const String phoneTaken = 'PHONE_TAKEN';
  static const String passwordWeak = 'PASSWORD_WEAK';
  static const String providerFieldsRequired = 'PROVIDER_FIELDS_REQUIRED';
  static const String categoryNotFound = 'CATEGORY_NOT_FOUND';
  static const String wilayaNotFound = 'WILAYA_NOT_FOUND';

  // Codes.
  static const String codeInvalid = 'CODE_INVALID';
  static const String codeExpired = 'CODE_EXPIRED';
  static const String codeResendTooSoon = 'CODE_RESEND_TOO_SOON';

  // Invite links.
  static const String resetTokenInvalid = 'RESET_TOKEN_INVALID';
  static const String resetTokenExpired = 'RESET_TOKEN_EXPIRED';

  // Files.
  static const String fileTooLarge = 'FILE_TOO_LARGE';
  static const String fileTypeNotAllowed = 'FILE_TYPE_NOT_ALLOWED';

}
