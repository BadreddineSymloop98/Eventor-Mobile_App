import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/models/availability.dart';
import '../../../core/catalog/month_availability.dart';
import '../../../core/errors/failure.dart';
import '../../../core/provider/provider_repository.dart';

/// Why P4 could not send, when the screen itself has to say so.
enum ProviderRescheduleProblem {
  /// The day is no longer free (or already behind us) — pick another.
  dateTaken,

  /// A proposal is already waiting, or the booking moved on: back to P2.
  stale,

  /// Offline, or anything else — try again.
  failed,
}

/// P4 Propose a new date. On a pending request the date moves at once; on
/// an accepted booking it is a proposal the client answers, and the booked
/// day stays as it is meanwhile.
///
/// The calendar is the provider's own (`GET /app/provider/availability`):
/// a day is free while it has room for one more event, past days and
/// whole-day blocks are not. The times start as the booking's.
class ProviderRescheduleViewModel extends BaseViewModel with MonthAvailability {
  ProviderRescheduleViewModel({
    required this.booking,
    required this._provider,
    this._today = DateTime.now,
  })  : _startTime = booking.card.startTime,
        _endTime = booking.card.endTime {
    showMonth(booking.card.eventDate);
  }

  final ProviderBooking booking;
  final ProviderRepository _provider;
  final DateTime Function() _today;

  /// The API's cap on the reason.
  static const int maxReason = 200;

  String? _startTime;
  String? _endTime;
  String _reason = '';
  bool _dateMissing = false;
  bool _reasonMissing = false;
  ProviderRescheduleProblem? _problem;
  DateTime? _takenDate;

  String? get startTime => _startTime;
  String? get endTime => _endTime;
  bool get dateMissing => _dateMissing;
  bool get reasonMissing => _reasonMissing;
  ProviderRescheduleProblem? get problem => _problem;
  DateTime? get takenDate => _takenDate;

  /// A pending request moves at once; an accepted booking waits for the
  /// client.
  bool get isProposal => booking.status == 'accepted';

  bool get isDirty =>
      selectedDate != null ||
      _reason.trim().isNotEmpty ||
      _startTime != booking.card.startTime ||
      _endTime != booking.card.endTime;

  @override
  bool get canPickDates => true;

  @override
  DateTime today() => _today();

  @override
  Future<Availability> fetchMonth(DateTime month) async =>
      availabilityFor(await _provider.availabilityMonth(month), month);

  /// The provider's month as the shared calendar reads it: past days and
  /// whole-day blocks greyed out, days with no room left struck through —
  /// this booking's own place on the calendar does not count against it.
  Availability availabilityFor(ProviderCalendarMonth calendar, DateTime month) {
    final DateTime now = _today();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = DateTime(month.year, month.month + 1, 0).day;
    return Availability(
      month: calendar.month,
      minNoticeDays: 0,
      firstBookableDate: today,
      days: <AvailabilityDay>[
        for (int d = 1; d <= days; d++)
          () {
            final DateTime date = DateTime(month.year, month.month, d);
            final ProviderCalendarDay? day = calendar.dayOf(date);
            final int others =
                (day?.bookingIds ?? const <String>{}).where((String id) => id != booking.id).length;
            final DayState state;
            if (date.isBefore(today) || day?.status == ProviderDayStatus.blocked) {
              state = DayState.blocked;
            } else if (others >= calendar.maxEventsPerDay || _sameDay(date, booking.card.eventDate)) {
              state = DayState.busy;
            } else {
              state = DayState.available;
            }
            return AvailabilityDay(date: date, state: state);
          }(),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void selectDate(DateTime day) {
    super.selectDate(day);
    if (selectedDate != null) {
      _dateMissing = false;
      if (_problem == ProviderRescheduleProblem.dateTaken) _problem = null;
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
    if (_problem == ProviderRescheduleProblem.failed) _problem = null;
    notifyListeners();
  }

  /// Sends it. The booking as it now stands, or `null` with [problem] (or
  /// a missing field marked).
  Future<ProviderBooking?> submit() async {
    if (isBusy) return null;
    final DateTime? date = selectedDate;
    _dateMissing = date == null;
    _reasonMissing = _reason.trim().isEmpty;
    if (date == null || _reasonMissing) {
      notifyListeners();
      return null;
    }
    _problem = null;
    final ProviderBooking? updated = await runGuarded(
      () => _provider.reschedule(
        booking.id,
        date: date,
        reason: _reason.trim(),
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
          _problem = ProviderRescheduleProblem.dateTaken;
          _takenDate = date;
          markTaken(date);
        case ApiErrorCode.reschedulePendingExists:
        case ApiErrorCode.bookingNotEditable:
        case ApiErrorCode.bookingNotFound:
          _problem = ProviderRescheduleProblem.stale;
        case ApiErrorCode.validationFailed
            when error.fieldErrors.any((FieldError f) => f.field == 'reason'):
          _reasonMissing = true;
        default:
          _problem = ProviderRescheduleProblem.failed;
      }
    } else {
      _problem = ProviderRescheduleProblem.failed;
    }
    notifyListeners();
    return null;
  }
}
