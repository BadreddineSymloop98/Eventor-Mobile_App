import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/models/booking_card.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';
import '../../../core/provider/models/provider_booking.dart' as provider_booking show replyHoursLeft;
import '../../../core/provider/provider_repository.dart';

/// P1 Requests, the provider's second tab: three lists as the API splits
/// them — requests (pending), upcoming (accepted, still ahead) and past
/// (completed, or accepted and behind us) — and, while the profile is not
/// approved, P1b in their place.
///
/// Each list loads on first open and is kept, so switching back is instant;
/// pull to refresh reloads the one on screen and marks the others to reload
/// when opened. Accept moves a request to Upcoming at once; a decline takes
/// it off the list. A refusal that means the request moved meanwhile
/// reloads the list.
class ProviderRequestsViewModel extends BaseViewModel {
  ProviderRequestsViewModel({
    required this._provider,
    required this._replyDeadlineHours,
    ProviderBookingTab initialTab = ProviderBookingTab.requests,
    this._now = DateTime.now,
  }) : _tab = initialTab {
    load();
  }

  final ProviderRepository _provider;
  final int _replyDeadlineHours;
  final DateTime Function() _now;

  /// One page — the API's default.
  static const int pageSize = 20;

  ProviderBookingTab _tab;
  final Map<ProviderBookingTab, _TabState> _tabs = <ProviderBookingTab, _TabState>{
    for (final ProviderBookingTab tab in ProviderBookingTab.values) tab: _TabState(),
  };

  /// Where the account stands — `null` until `/app/provider/home` answered.
  ProviderHomeState? _state;
  Failure? _stateFailure;
  bool _isLoadingState = false;
  String? _accepting;

  ProviderBookingTab get tab => _tab;
  _TabState get _current => _tabs[_tab]!;

  ProviderHomeState? get accountState => _state;

  /// P1b: documents missing, in review, or refused — no request can come in.
  bool get isUnderReview =>
      _state == ProviderHomeState.pending || _state == ProviderHomeState.rejected;

  bool get isRejected => _state == ProviderHomeState.rejected;

  /// An admin blocked the account: the lists stay readable, nothing can be
  /// answered.
  bool get isBlocked => _state == ProviderHomeState.blocked;

  /// How long a request waits for an answer, from the server's config.
  int get replyDeadlineHours => _replyDeadlineHours;

  List<BookingCard> get items => _current.items;
  bool get hasMore => _current.hasMore;
  bool get isLoadingMore => _current.isLoadingMore;
  bool get loadMoreFailed => _current.loadMoreFailed;

  /// The first load failed — the error card with its retry. A list that did
  /// load is shown even when the account's state could not be read.
  bool get loadFailed =>
      !isUnderReview &&
      !_current.loaded &&
      (_current.failure != null || (_state == null && _stateFailure != null));

  /// Nothing to show yet — the skeletons.
  bool get isFirstLoad =>
      !loadFailed &&
      ((_state == null && _stateFailure == null) ||
          (!isUnderReview && !_current.loaded));

  bool get isEmpty => _current.loaded && _current.items.isEmpty;

  /// The request whose Accept is running.
  String? get accepting => _accepting;

  /// "Reply within 47 h" for [request].
  int? replyHoursLeft(BookingCard request) => provider_booking.replyHoursLeft(
        request,
        deadlineHours: _replyDeadlineHours,
        now: _now(),
      );

  void setTab(ProviderBookingTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
    final _TabState state = _current;
    if (!state.loaded && !state.isLoading && !isUnderReview) _loadTab(tab);
  }

  /// The account's state and the list on screen, from their first page.
  Future<void> load() async {
    clearFailure();
    _stateFailure = null;
    _current.failure = null;
    notifyListeners();
    await Future.wait(<Future<void>>[_loadState(), _loadTab(_tab)]);
  }

  Future<void> _loadState() async {
    if (_isLoadingState) return;
    _isLoadingState = true;
    try {
      _state = (await _provider.home()).state;
      _stateFailure = null;
    } on Failure catch (failure) {
      _stateFailure = failure;
    } catch (error) {
      _stateFailure = UnexpectedFailure(cause: error);
    }
    _isLoadingState = false;
    notifyListeners();
  }

  Future<void> _loadTab(ProviderBookingTab tab) async {
    final _TabState state = _tabs[tab]!;
    if (state.isLoading) return;
    state
      ..isLoading = true
      ..failure = null;
    notifyListeners();
    try {
      _apply(state, await _provider.bookings(tab: tab, limit: pageSize), replace: true);
    } on Failure catch (failure) {
      state.failure = failure;
    } catch (error) {
      state.failure = UnexpectedFailure(cause: error);
    }
    state.isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, the app coming back, the tab tapped again, and the
  /// return from P2. What is on screen stays when it fails.
  Future<Failure?> refresh() async {
    final ProviderBookingTab tab = _tab;
    final _TabState state = _tabs[tab]!;
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _provider.home(),
        _provider.bookings(tab: tab, limit: pageSize),
      ]);
      _state = (results[0] as ProviderHome).state;
      _stateFailure = null;
      _apply(state, results[1] as ApiPage<BookingCard>, replace: true);
      state.failure = null;
      // Another list may have gained or lost what moved: reload it on open.
      for (final ProviderBookingTab other in ProviderBookingTab.values) {
        if (other != tab) _tabs[other]!.loaded = false;
      }
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      if (!state.loaded) {
        state.failure = failure;
        notifyListeners();
      }
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  Future<void> loadMore() async {
    final _TabState state = _current;
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    final ProviderBookingTab tab = _tab;
    state
      ..isLoadingMore = true
      ..loadMoreFailed = false;
    notifyListeners();
    try {
      _apply(
        state,
        await _provider.bookings(tab: tab, page: state.page + 1, limit: pageSize),
        replace: false,
      );
    } catch (_) {
      state.loadMoreFailed = true;
    }
    state.isLoadingMore = false;
    notifyListeners();
  }

  /// Accept, in one tap: the request leaves the list and Upcoming reloads
  /// when opened. `null` when it went through.
  Future<Failure?> accept(BookingCard request) async {
    if (_accepting != null) return null;
    _accepting = request.id;
    notifyListeners();
    Failure? failure;
    try {
      await _provider.accept(request.id);
      _removeRequest(request.id);
      _tabs[ProviderBookingTab.upcoming]!.loaded = false;
    } on Failure catch (error) {
      failure = error;
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    _accepting = null;
    notifyListeners();
    if (failure != null && _isStale(failure)) await refresh();
    return failure;
  }

  /// P3's confirm. The sheet waits on it, so the failure comes back to it.
  Future<Failure?> decline(BookingCard request, String reason) async {
    try {
      await _provider.decline(request.id, reason: reason.trim());
    } on Failure catch (failure) {
      if (_isStale(failure)) await refresh();
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
    _removeRequest(request.id);
    notifyListeners();
    return null;
  }

  void _removeRequest(String id) {
    final _TabState requests = _tabs[ProviderBookingTab.requests]!;
    requests.items.removeWhere((BookingCard b) => b.id == id);
  }

  static void _apply(
    _TabState state,
    ApiPage<BookingCard> page, {
    required bool replace,
  }) {
    if (replace) state.items.clear();
    final Set<String> known = <String>{for (final BookingCard b in state.items) b.id};
    state.items.addAll(page.items.where((BookingCard b) => known.add(b.id)));
    state
      ..page = page.page
      ..hasMore = page.hasMore
      ..loaded = true;
  }

  static bool _isStale(Failure failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.bookingInvalidTransition ||
          failure.code == ApiErrorCode.bookingNotFound ||
          failure.code == ApiErrorCode.dateUnavailable);
}

class _TabState {
  final List<BookingCard> items = <BookingCard>[];
  int page = 0;
  bool hasMore = false;
  bool loaded = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool loadMoreFailed = false;
  Failure? failure;
}
