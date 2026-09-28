import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/month_availability.dart';
import '../../../core/errors/failure.dart';

/// Why B6 could not send, when the screen itself has to say so.
enum RescheduleProblem {
  /// The day went meanwhile — struck through, pick another.
  dateTaken,

  /// A proposal is already waiting, or the booking moved on: back to B4.
  stale,

  /// Offline, or anything else — try again.
  failed,
}

/// B6: a new day (and, if wanted, new times) for a booking, with the reason
/// the provider will read. On a pending request it moves at once; on an
/// accepted booking it is a proposal the provider answers, and the booked
/// day stays held meanwhile.
class RescheduleViewModel extends BaseViewModel with MonthAvailability {
  RescheduleViewModel({
    required this.booking,
    required this._bookings,
    required this._catalog,
    this._today = DateTime.now,
  })  : _startTime = booking.card.startTime,
        _endTime = booking.card.endTime {
    showMonth(booking.card.eventDate);
  }

  final BookingDetail booking;
  final BookingsRepository _bookings;
  final CatalogRepository _catalog;
  final DateTime Function() _today;

  /// The API's cap on the reason.
  static const int maxReason = 200;

  String? _startTime;
  String? _endTime;
  String _reason = '';
  bool _dateMissing = false;
  bool _reasonMissing = false;
  RescheduleProblem? _problem;
  DateTime? _takenDate;

  String? get startTime => _startTime;
  String? get endTime => _endTime;
  bool get dateMissing => _dateMissing;
  bool get reasonMissing => _reasonMissing;
  RescheduleProblem? get problem => _problem;
  DateTime? get takenDate => _takenDate;

  /// A pending request moves at once; an accepted booking waits for the
  /// provider.
  bool get isProposal => booking.status == 'accepted';

  bool get isDirty => selectedDate != null || _reason.trim().isNotEmpty;

  @override
  bool get canPickDates => true;

  @override
  DateTime today() => _today();

  @override
  Future<Availability> fetchMonth(DateTime month) {
    final String? pack = booking.card.packId;
    return pack != null
        ? _catalog.packAvailability(pack, month)
        : _catalog.serviceAvailability(booking.card.serviceId!, month);
  }

  @override
  void selectDate(DateTime day) {
    super.selectDate(day);
    if (selectedDate != null) {
      _dateMissing = false;
      if (_problem == RescheduleProblem.dateTaken) _problem = null;
      notifyListeners();
    }
  }

  void setStartTime(String? value) {
    _startTime = value;
    // As on B1: an end equal to the new start would be a 24-hour event.
    if (value == null || value == _endTime) _endTime = null;
    notifyListeners();
  }

  void setEndTime(String? value) {
    _endTime = value;
    notifyListeners();
  }

  void setReason(String value) {
    _reason = value;
    if (value.trim().isNotEmpty) _reasonMissing = false;
    if (_problem == RescheduleProblem.failed) _problem = null;
    notifyListeners();
  }

  /// Sends it. The booking as it now stands, or `null` with [problem] (or
  /// a missing field marked).
  Future<BookingDetail?> submit() async {
    final DateTime? date = selectedDate;
    _dateMissing = date == null;
    _reasonMissing = _reason.trim().isEmpty;
    if (date == null || _reasonMissing) {
      notifyListeners();
      return null;
    }
    _problem = null;
    final BookingDetail? updated = await runGuarded(
      () => _bookings.reschedule(
        booking.id,
        date: date,
        reason: _reason,
        startTime: _startTime,
        endTime: _startTime == null ? null : _endTime,
      ),
    );
    if (updated != null) return updated;
    final Failure? error = failure;
    if (error is ApiFailure) {
      switch (error.code) {
        case ApiErrorCode.dateUnavailable:
        case ApiErrorCode.bookingDatePast:
          _problem = RescheduleProblem.dateTaken;
          _takenDate = date;
          markTaken(date);
        case ApiErrorCode.reschedulePendingExists:
        case ApiErrorCode.bookingNotEditable:
          _problem = RescheduleProblem.stale;
        default:
          _problem = RescheduleProblem.failed;
      }
    } else {
      _problem = RescheduleProblem.failed;
    }
    notifyListeners();
    return null;
  }
}
