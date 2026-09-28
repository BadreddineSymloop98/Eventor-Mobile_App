import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/errors/failure.dart';

/// B7 After the event: "All good" in one tap, or "There was a problem",
/// which opens a dispute. When both sides say "All good" the booking closes
/// at once; otherwise it closes on its own after the dispute window.
class CheckInViewModel extends BaseViewModel {
  CheckInViewModel({required this.booking, required this._bookings});

  final BookingDetail booking;
  final BookingsRepository _bookings;

  bool _isConfirming = false;

  bool get isConfirming => _isConfirming;

  /// "All good". The booking as it now stands, or `null` with [failure].
  Future<BookingDetail?> confirm() async {
    if (_isConfirming) return null;
    _isConfirming = true;
    notifyListeners();
    final BookingDetail? updated = await runGuarded(() => _bookings.checkIn(booking.id));
    _isConfirming = false;
    notifyListeners();
    return updated;
  }

  /// The problem sheet's send. `null` when the dispute is open.
  Future<Failure?> reportProblem(DisputeType type, String description) async {
    try {
      await _bookings.openDispute(booking.id, type: type, description: description);
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }
}
