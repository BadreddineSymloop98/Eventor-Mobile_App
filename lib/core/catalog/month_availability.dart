import '../base/base_view_model.dart';
import 'models/availability.dart';

/// The calendar half of screens 12 and 20: which month is shown, its day
/// states, and the date picked.
///
/// Each month is fetched once and kept, so paging back and forth costs
/// nothing. The calendar starts on the current month and cannot go before
/// it. A day can be picked only when it is available and the provider is
/// taking bookings.
mixin MonthAvailability on BaseViewModel {
  /// Fetches the month containing [month].
  Future<Availability> fetchMonth(DateTime month);

  /// Whether days can be picked at all — `false` when the provider paused
  /// bookings; the calendar then only shows.
  bool get canPickDates;

  /// Today, injectable for tests.
  DateTime today();

  final Map<int, Availability> _months = <int, Availability>{};
  DateTime? _visibleMonth;
  bool _isLoadingMonth = false;
  bool _monthFailed = false;
  DateTime? _selected;

  static int _key(DateTime month) => month.year * 100 + month.month;

  /// The first month the calendar can show — this one.
  DateTime get firstMonth {
    final DateTime now = today();
    return DateTime(now.year, now.month);
  }

  DateTime get visibleMonth => _visibleMonth ?? firstMonth;

  /// `null` while [visibleMonth] loads, or when it failed.
  Availability? get availability => _months[_key(visibleMonth)];

  bool get isLoadingMonth => _isLoadingMonth;
  bool get monthFailed => _monthFailed;
  DateTime? get selectedDate => _selected;

  /// Shows [month], fetching it the first time.
  Future<void> showMonth(DateTime month) async {
    final DateTime first = DateTime(month.year, month.month);
    if (first.isBefore(firstMonth)) return;
    _visibleMonth = first;
    _monthFailed = false;
    if (_months.containsKey(_key(first))) {
      notifyListeners();
      return;
    }
    _isLoadingMonth = true;
    notifyListeners();
    try {
      final Availability loaded = await fetchMonth(first);
      _months[_key(first)] = loaded;
    } catch (_) {
      // Only if the user is still on this month; otherwise it no longer
      // matters.
      if (_key(visibleMonth) == _key(first)) _monthFailed = true;
    }
    _isLoadingMonth = false;
    notifyListeners();
  }

  /// Retries the month on screen.
  Future<void> retryMonth() => showMonth(visibleMonth);

  /// Lets go of the picked day — B1b, or a screen that starts over.
  void clearSelection() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  /// [day] was taken by someone else meanwhile (B1b): it is struck through
  /// where it stands and, if it was the picked one, let go of.
  void markTaken(DateTime day) {
    final Availability? month = _months[_key(day)];
    if (month != null) _months[_key(day)] = month.withBusy(day);
    final DateTime? picked = _selected;
    if (picked != null &&
        picked.year == day.year &&
        picked.month == day.month &&
        picked.day == day.day) {
      _selected = null;
    }
    notifyListeners();
  }

  /// Opens on [day]'s month and picks it when it can be requested — the day
  /// chosen on 12 or 20 carried into B1 or B9.
  Future<void> openOn(DateTime? day) async {
    if (day == null) return showMonth(visibleMonth);
    await showMonth(day);
    selectDate(day);
  }

  /// Picks [day] if it can be requested; anything else is ignored.
  void selectDate(DateTime day) {
    if (!canPickDates) return;
    final Availability? month = _months[_key(day)];
    if (month == null || month.stateOf(day) != DayState.available) return;
    _selected = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }
}
