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

  /// The server has no such route — how a feature the app is ahead of the
  /// backend on (deleting a budget) answers until it ships.
  static const String routeNotFound = 'ROUTE_NOT_FOUND';
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

  // Catalog and favourites.
  static const String serviceNotFound = 'SERVICE_NOT_FOUND';
  static const String packNotFound = 'PACK_NOT_FOUND';
  static const String providerNotFound = 'PROVIDER_NOT_FOUND';
  static const String favouriteNotFound = 'FAVOURITE_NOT_FOUND';
  static const String favouriteTargetInvalid = 'FAVOURITE_TARGET_INVALID';
  static const String forbiddenRole = 'FORBIDDEN_ROLE';

  // Messaging.
  static const String notAParticipant = 'NOT_A_PARTICIPANT';
  static const String conversationNotFound = 'CONVERSATION_NOT_FOUND';
  static const String conversationClosed = 'CONVERSATION_CLOSED';
  static const String conversationReadOnly = 'CONVERSATION_READ_ONLY';
  static const String recipientInvalid = 'RECIPIENT_INVALID';
  static const String userNotFound = 'USER_NOT_FOUND';
  static const String messageNotFound = 'MESSAGE_NOT_FOUND';
  static const String notificationNotFound = 'NOTIFICATION_NOT_FOUND';

  // Budget.
  static const String budgetNotFound = 'BUDGET_NOT_FOUND';
  static const String budgetItemNotFound = 'BUDGET_ITEM_NOT_FOUND';
  static const String budgetItemLimit = 'BUDGET_ITEM_LIMIT';
  static const String bookingNotFound = 'BOOKING_NOT_FOUND';
  static const String budgetBookingAlreadyLinked = 'BUDGET_BOOKING_ALREADY_LINKED';

  // Provider.
  static const String providerNotVerified = 'PROVIDER_NOT_VERIFIED';
  static const String bookingInvalidTransition = 'BOOKING_INVALID_TRANSITION';
  static const String dateUnavailable = 'DATE_UNAVAILABLE';
  static const String notAProvider = 'NOT_A_PROVIDER';

  // Client bookings.
  static const String minNotice = 'MIN_NOTICE';
  static const String providerNotAccepting = 'PROVIDER_NOT_ACCEPTING';
  static const String serviceUnavailableForBooking =
      'SERVICE_UNAVAILABLE_FOR_BOOKING';
  static const String packUnavailable = 'PACK_UNAVAILABLE';
  static const String communeNotFound = 'COMMUNE_NOT_FOUND';
  static const String communeWilayaMismatch = 'COMMUNE_WILAYA_MISMATCH';
  static const String bookingExtraInvalid = 'BOOKING_EXTRA_INVALID';
  static const String bookingNotEditable = 'BOOKING_NOT_EDITABLE';
  static const String bookingDatePast = 'BOOKING_DATE_PAST';
  static const String reschedulePendingExists = 'RESCHEDULE_PENDING_EXISTS';
  static const String rescheduleNotFound = 'RESCHEDULE_NOT_FOUND';
  static const String rescheduleNotPending = 'RESCHEDULE_NOT_PENDING';
  static const String checkInNotAllowed = 'CHECK_IN_NOT_ALLOWED';
  static const String checkInDisputed = 'CHECK_IN_DISPUTED';
  static const String checkInTooEarly = 'CHECK_IN_TOO_EARLY';
  static const String invoiceNotFound = 'INVOICE_NOT_FOUND';
  static const String reviewExists = 'REVIEW_EXISTS';
  static const String reviewNotAllowed = 'REVIEW_NOT_ALLOWED';
  static const String reviewWindowClosed = 'REVIEW_WINDOW_CLOSED';
  static const String disputeAlreadyOpen = 'DISPUTE_ALREADY_OPEN';
  static const String bookingNotDisputable = 'BOOKING_NOT_DISPUTABLE';
  static const String disputeWindowClosed = 'DISPUTE_WINDOW_CLOSED';
  static const String notOwner = 'NOT_OWNER';

  // Section 10 · the provider's services, packs and availability.

  /// Publishing a service with something missing; `details.missing` lists
  /// the `publishMissing` keys (P9).
  static const String servicePublishInvalid = 'SERVICE_PUBLISH_INVALID';

  /// Publishing a pack with something missing; `details.missing` (P14).
  static const String packPublishInvalid = 'PACK_PUBLISH_INVALID';
  static const String packWilayaNotCovered = 'PACK_WILAYA_NOT_COVERED';

  /// Deleting a service or pack with accepted bookings still ahead (P7b).
  static const String serviceHasBookings = 'SERVICE_HAS_BOOKINGS';
  static const String serviceInPacks = 'SERVICE_IN_PACKS';
  static const String packHasBookings = 'PACK_HAS_BOOKINGS';
  static const String serviceInvalidTransition = 'SERVICE_INVALID_TRANSITION';
  static const String packInvalidTransition = 'PACK_INVALID_TRANSITION';
  static const String packServiceNotFound = 'PACK_SERVICE_NOT_FOUND';
  static const String packServiceOtherProvider = 'PACK_SERVICE_OTHER_PROVIDER';
  static const String providerProfileMissing = 'PROVIDER_PROFILE_MISSING';
  static const String categoryHidden = 'CATEGORY_HIDDEN';
  static const String wilayaClosed = 'WILAYA_CLOSED';

  static const String photoLimitReached = 'PHOTO_LIMIT_REACHED';
  static const String photoOrderInvalid = 'PHOTO_ORDER_INVALID';
  static const String photoNotFound = 'PHOTO_NOT_FOUND';
  static const String fileNotFound = 'FILE_NOT_FOUND';
  static const String fileNotReady = 'FILE_NOT_READY';

  static const String availabilityDatePast = 'AVAILABILITY_DATE_PAST';
  static const String availabilityServiceInvalid = 'AVAILABILITY_SERVICE_INVALID';
  static const String availabilityBlockNotRemovable = 'AVAILABILITY_BLOCK_NOT_REMOVABLE';
  static const String availabilityBlockNotFound = 'AVAILABILITY_BLOCK_NOT_FOUND';
  static const String monthInvalid = 'MONTH_INVALID';
}
