import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/models/booking_card.dart';
import '../../../core/errors/failure.dart';
import '../../../core/provider/provider_repository.dart';

/// P5 After the event: "All good" in one tap (the provider's check-in), or
/// "There was a problem", which opens a dispute on the shared route. When
/// both sides said "All good" the booking closes at once; otherwise it
/// closes on its own 72 h after the event.
///
/// Opened from P2 with the booking at hand, or from the post-event
/// notification with only its id — then it loads it first.
class ProviderCheckInViewModel extends BaseViewModel {
  ProviderCheckInViewModel({
    required this.id,
    required this._provider,
    ProviderBooking? booking,
  }) : _booking = booking {
    if (booking == null) load();
  }

  final String id;
  final ProviderRepository _provider;

  ProviderBooking? _booking;
  bool _isLoading = false;
  bool _isGone = false;
  bool _isConfirming = false;

  ProviderBooking? get booking => _booking;
  bool get isFirstLoad => _booking == null && (_isLoading || !hasError) && !_isGone;
  bool get isGone => _isGone;
  bool get isConfirming => _isConfirming;

  /// There is still something to confirm — otherwise the screen points to
  /// the booking instead (a stale notification, a confirmation already
  /// given).
  bool get canConfirm => _booking?.can(BookingAction.checkIn) ?? false;

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final ProviderBooking? loaded = await runGuarded(() => _provider.booking(id));
    final Failure? failure = this.failure;
    if (loaded != null) {
      _booking = loaded;
    } else if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.bookingNotFound ||
            failure.code == ApiErrorCode.notOwner ||
            failure.statusCode == 404)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// "All good". The booking as it now stands, or `null` with [failure] —
  /// too early (`CHECK_IN_TOO_EARLY`), no longer possible
  /// (`CHECK_IN_NOT_ALLOWED`) or held by a dispute (`CHECK_IN_DISPUTED`).
  Future<ProviderBooking?> confirm() async {
    if (_isConfirming) return null;
    _isConfirming = true;
    notifyListeners();
    // What stands now goes back to P2; this screen keeps what it showed
    // while it closes, rather than flashing "nothing to confirm".
    final ProviderBooking? updated = await runGuarded(() => _provider.checkIn(id));
    _isConfirming = false;
    notifyListeners();
    return updated;
  }

  /// The problem sheet's send. `null` when the dispute is open.
  Future<Failure?> reportProblem(ProviderDisputeType type, String description) async {
    try {
      await _provider.openDispute(id, type: type, description: description);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }
}
