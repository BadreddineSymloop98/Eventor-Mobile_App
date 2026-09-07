/// Everything that can go wrong, as a type rather than as a message.
///
/// View models have no [BuildContext] and so cannot resolve a localised
/// string; they report *what* failed and leave the wording to the view. The
/// hierarchy is sealed, so the `switch` that turns a failure into a message is
/// exhaustive — adding a case here without localising it is a compile error
/// rather than a blank label in production.
///
/// Network and authentication failures join this list once there is a backend
/// to produce them.
sealed class Failure {
  const Failure({this.cause});

  /// The original error, kept for logging. Never shown to the user.
  final Object? cause;
}

/// Writing to on-device storage failed.
class StorageFailure extends Failure {
  const StorageFailure({super.cause});
}

/// Anything with no more specific type. The catch-all in [Failure] mapping.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.cause});
}
