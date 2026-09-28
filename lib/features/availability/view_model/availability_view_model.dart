import 'dart:async';

import '../../../core/availability/availability_repository.dart';
import '../../../core/base/base_view_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/provider/models/provider_home.dart' show ProviderServiceRow;

/// Why a day cannot take another block — P15c then offers no block action
/// and says why.
enum BlockRefusal {
  /// The day is over (a past day's sheet is read-only).
  past,

  /// Already blocked all day for every service: nothing is left to block.
  alreadyBlocked,

  /// Accepted bookings fill the day's capacity: clients cannot book it
  /// anyway, and a block would change nothing.
  fullyBooked,
}

/// P15 Availability and its sheets (P15a, P15b, P15c): the provider's
/// calendar a month at a time, the day picked, and the blocks added and
/// removed from it.
///
/// Each month is fetched once and kept, so paging back and forth costs
/// nothing; a block or a removal shows at once and reloads its month in the
/// background, so the day's status is always the server's in the end. The
/// other months kept are marked stale on a refresh and fetched again when
/// shown. The calendar starts on the current month and cannot go before it.
class AvailabilityViewModel extends BaseViewModel {
  AvailabilityViewModel({
    required this._availability,
    required this._loadServices,
    required this._config,
    this._today = DateTime.now,
  }) {
    showMonth(firstMonth);
  }

  final AvailabilityRepository _availability;

  /// The provider's services, for "Which services" — the integrator reads
  /// them from the services module.
  final Future<List<ProviderServiceRow>> Function() _loadServices;
  final AppConfig _config;
  final DateTime Function() _today;

  final Map<int, AvailabilityMonth> _months = <int, AvailabilityMonth>{};
  final Map<int, Failure> _monthFailures = <int, Failure>{};
  final Set<int> _loading = <int>{};
  final Set<int> _stale = <int>{};

  /// The latest fetch per month: an older answer that lands after a newer
  /// one (a reload after a block) is dropped.
  final Map<int, int> _fetches = <int, int>{};
  final Set<String> _removing = <String>{};

  DateTime? _visible;
  DateTime? _selected;
  List<ProviderServiceRow>? _services;
  Future<Failure?>? _servicesLoad;

  static int _key(DateTime month) => month.year * 100 + month.month;

  static DateTime _dayOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  /// Today's date, local midnight.
  DateTime get today => _dayOnly(_today());

  /// The first month the calendar shows — this one.
  DateTime get firstMonth => DateTime(today.year, today.month);

  DateTime get visibleMonth => _visible ?? firstMonth;
  bool get canGoBack => visibleMonth.isAfter(firstMonth);

  /// The month on screen; `null` while it first loads or when it failed.
  AvailabilityMonth? get month => _months[_key(visibleMonth)];

  /// Nothing to show for the month yet — the grid's skeleton.
  bool get isFirstLoad => month == null && monthFailure == null;

  /// Why the month on screen could not load, when nothing of it is shown.
  Failure? get monthFailure => month == null ? _monthFailures[_key(visibleMonth)] : null;

  bool get isLoadingMonth => _loading.contains(_key(visibleMonth));

  /// Clients cannot book closer than this — from the server's config (the
  /// design's "3 days" was a placeholder).
  int get minNoticeDays => _config.bookingMinNoticeDays;

  /// The day picked on the month shown. Paging away hides it; paging back
  /// brings it back.
  DateTime? get selectedDate {
    final DateTime? picked = _selected;
    if (picked == null) return null;
    return _key(picked) == _key(visibleMonth) ? picked : null;
  }

  /// The picked day's contents, once its month is loaded.
  ProviderDay? get selectedDay {
    final DateTime? picked = selectedDate;
    return picked == null ? null : dayOf(picked);
  }

  /// P15's "Block a day": a picked day that can still take a block.
  bool get canBlockSelected {
    final DateTime? picked = selectedDate;
    return picked != null && whyNotBlockable(picked) == null;
  }

  bool isPast(DateTime day) => _dayOnly(day).isBefore(today);

  bool isToday(DateTime day) => _dayOnly(day) == today;

  /// What is on [day], when its month is loaded.
  ProviderDay? dayOf(DateTime day) => _months[_key(day)]?.dayOf(day);

  /// `null` when [day] can take a block — the whole day or a slot. The
  /// server only refuses past days; the other two are the app's own sense:
  /// blocking a day nothing more can be booked on changes nothing. A day a
  /// request holds can be blocked (it does not decline the request).
  BlockRefusal? whyNotBlockable(DateTime day) {
    if (isPast(day)) return BlockRefusal.past;
    final AvailabilityMonth? loaded = _months[_key(day)];
    if (loaded == null) return null;
    final List<ProviderDayItem> items = loaded.dayOf(day).items;
    if (items.any((ProviderDayItem i) => i.blocksEverything)) return BlockRefusal.alreadyBlocked;
    final int booked = items.where((ProviderDayItem i) => i.kind == ProviderDayItemKind.booked).length;
    if (booked >= loaded.maxEventsPerDay) return BlockRefusal.fullyBooked;
    return null;
  }

  // --------------------------------------------------------------- months

  /// Shows [month], fetching it the first time or when it went stale.
  Future<void> showMonth(DateTime month) async {
    final DateTime first = DateTime(month.year, month.month);
    if (first.isBefore(firstMonth)) return;
    _visible = first;
    notifyListeners();
    final int key = _key(first);
    if (_months.containsKey(key) && !_stale.contains(key)) return;
    await _fetch(first);
  }

  /// Retries the month on screen after it failed.
  Future<void> retryMonth() async {
    await _fetch(visibleMonth);
  }

  /// Pull to refresh, the return from a booking and the app coming back to
  /// the front. What is on screen stays when it fails; the other months kept
  /// are fetched again when next shown.
  Future<Failure?> refresh() {
    final int visible = _key(visibleMonth);
    _stale.addAll(_months.keys.where((int key) => key != visible));
    return _fetch(visibleMonth);
  }

  Future<Failure?> _fetch(DateTime first) async {
    final int key = _key(first);
    final int fetch = (_fetches[key] ?? 0) + 1;
    _fetches[key] = fetch;
    _loading.add(key);
    _monthFailures.remove(key);
    notifyListeners();
    Failure? failure;
    try {
      final AvailabilityMonth loaded = await _availability.month(first);
      if (_fetches[key] == fetch) {
        _months[key] = loaded;
        _stale.remove(key);
      }
    } on Failure catch (error) {
      failure = error;
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    if (_fetches[key] == fetch) {
      _loading.remove(key);
      if (failure != null) _monthFailures[key] = failure;
      notifyListeners();
    }
    return failure;
  }

  /// [day]'s month changed on the server: fetched again now when on screen,
  /// or marked to be when shown.
  Future<void> _reload(DateTime day) async {
    final int key = _key(day);
    _stale.add(key);
    if (key == _key(visibleMonth)) await _fetch(DateTime(day.year, day.month));
  }

  // ----------------------------------------------------------------- days

  /// Picks [day] — the day "Block a day" acts on. A past day cannot be
  /// picked.
  void selectDay(DateTime day) {
    if (isPast(day)) return;
    _selected = _dayOnly(day);
    notifyListeners();
  }

  // ------------------------------------------------------------- services

  /// The services "Which services" offers; `null` until loaded.
  List<ProviderServiceRow>? get services => _services;

  /// Loads the services once. Concurrent calls share the one load.
  Future<Failure?> loadServices() {
    if (_services != null) return Future<Failure?>.value();
    return _servicesLoad ??= _loadServicesOnce();
  }

  Future<Failure?> _loadServicesOnce() async {
    try {
      _services = await _loadServices();
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    } finally {
      _servicesLoad = null;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------- writes

  /// P15a / P15b's confirm, and Undo after a removal. `null` when the block
  /// was added; otherwise the sheet shows the failure and stays open.
  Future<Failure?> block(BlockRequest request) async {
    final ProviderDayItem created;
    try {
      created = await _availability.block(request);
    } on Failure catch (failure) {
      if (failure is ApiFailure) {
        switch (failure.code) {
          // Midnight passed while the sheet was open: the calendar moves on.
          case ApiErrorCode.availabilityDatePast:
            unawaited(_reload(request.date));
          // The list is out of date — a service deleted meanwhile.
          case ApiErrorCode.availabilityServiceInvalid:
            _services = null;
        }
      }
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
    _insert(created);
    unawaited(_reload(request.date));
    return null;
  }

  /// A removal of [item] is running — its Remove is not offered twice.
  bool isRemoving(ProviderDayItem item) => item.id != null && _removing.contains(item.id);

  /// Removes one of the provider's own blocks at once (decision 6); the
  /// view then offers Undo, which is [block] with the block's own request.
  /// A block already gone or no longer removable reloads its month.
  Future<Failure?> remove(ProviderDayItem item) async {
    final String? id = item.id;
    if (id == null || !item.removable) {
      return const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.availabilityBlockNotRemovable,
        message: '',
      );
    }
    if (!_removing.add(id)) return null;
    final int key = _key(item.date);
    final AvailabilityMonth? before = _months[key];
    AvailabilityMonth? shown;
    if (before != null) {
      final ProviderDay day = before.dayOf(item.date);
      shown = before.withDay(
        day.withItems(day.items.where((ProviderDayItem i) => i.id != id).toList()),
      );
      _months[key] = shown;
    }
    notifyListeners();

    Failure? failure;
    try {
      await _availability.unblock(id);
    } on Failure catch (error) {
      failure = error;
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    _removing.remove(id);
    if (failure == null) {
      unawaited(_reload(item.date));
      return null;
    }
    if (_isStale(failure)) {
      await _reload(item.date);
    } else if (before != null && identical(_months[key], shown)) {
      // Put back only if nothing newer landed meanwhile.
      _months[key] = before;
    }
    notifyListeners();
    return failure;
  }

  /// Undo after [remove]: the same block again — date, times, service and
  /// note. It comes back under a new id.
  Future<Failure?> restore(ProviderDayItem item) => block(item.asRequest);

  void _insert(ProviderDayItem item) {
    final int key = _key(item.date);
    final AvailabilityMonth? loaded = _months[key];
    if (loaded == null) return;
    final ProviderDay day = loaded.dayOf(item.date);
    _months[key] = loaded.withDay(day.withItems(<ProviderDayItem>[...day.items, item]));
    notifyListeners();
  }

  static bool _isStale(Failure failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.availabilityBlockNotFound ||
          failure.code == ApiErrorCode.availabilityBlockNotRemovable);
}
