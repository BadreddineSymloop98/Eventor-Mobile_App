import '../../../core/errors/failure.dart';

/// How a Publish tap ended — the list's and the forms' alike. [M] is the
/// checklist key: `ServiceMissing` or `PackMissing`.
sealed class PublishOutcome<M> {
  const PublishOutcome();
}

/// Live.
final class PublishDone<M> extends PublishOutcome<M> {
  const PublishDone();
}

/// P9 / P14: not ready; what is still [missing]. The draft is saved.
final class PublishChecklist<M> extends PublishOutcome<M> {
  const PublishChecklist(this.missing);

  final List<M> missing;
}

/// The profile is still under review: publishing unlocks once the
/// documents are approved. The draft is saved.
final class PublishNotVerified<M> extends PublishOutcome<M> {
  const PublishNotVerified();
}

/// The form could not even be saved — required fields are empty; they are
/// flagged on the form.
final class PublishInvalid<M> extends PublishOutcome<M> {
  const PublishInvalid();
}

final class PublishFailed<M> extends PublishOutcome<M> {
  const PublishFailed(this.failure);

  final Failure failure;
}

/// Why a delete was refused — one row of P7b's blocker card.
enum DeleteBlockerKind {
  /// `SERVICE_HAS_BOOKINGS` / `PACK_HAS_BOOKINGS`.
  bookings,

  /// `SERVICE_IN_PACKS`.
  packs,
}

class DeleteBlocker {
  const DeleteBlocker(this.kind, {this.count});

  final DeleteBlockerKind kind;

  /// How many, when the server said — worded without a number otherwise.
  final int? count;
}

sealed class DeleteOutcome {
  const DeleteOutcome();
}

final class DeleteDone extends DeleteOutcome {
  const DeleteDone();
}

/// P7b: the server refused, for [blockers].
final class DeleteRefused extends DeleteOutcome {
  const DeleteRefused(this.blockers);

  final List<DeleteBlocker> blockers;
}

final class DeleteFailed extends DeleteOutcome {
  const DeleteFailed(this.failure);

  final Failure failure;
}

/// The checklist keys an `*_PUBLISH_INVALID` refusal lists in
/// `details.missing`; empty when it did not say.
List<String> missingKeysOf(ApiFailure failure) {
  final Object? missing = failure.details?['missing'];
  return missing is List<Object?> ? missing.whereType<String>().toList() : <String>[];
}

/// The blocker a delete refusal names, or `null` for any other failure.
DeleteBlocker? deleteBlockerOf(Failure failure) {
  if (failure is! ApiFailure) return null;
  final DeleteBlockerKind? kind = switch (failure.code) {
    ApiErrorCode.serviceHasBookings || ApiErrorCode.packHasBookings =>
      DeleteBlockerKind.bookings,
    ApiErrorCode.serviceInPacks => DeleteBlockerKind.packs,
    _ => null,
  };
  if (kind == null) return null;
  final Object? counted = failure.details?[
      kind == DeleteBlockerKind.bookings ? 'upcomingBookings' : 'packsCount'];
  int? count = counted is num ? counted.toInt() : null;
  // The documented body has no details, but the message carries the count
  // ("This service has 2 accepted upcoming bookings").
  if (count == null) {
    final RegExpMatch? digits = RegExp(r'\d+').firstMatch(failure.message);
    if (digits != null) count = int.tryParse(digits.group(0)!);
  }
  return DeleteBlocker(kind, count: count != null && count > 0 ? count : null);
}
