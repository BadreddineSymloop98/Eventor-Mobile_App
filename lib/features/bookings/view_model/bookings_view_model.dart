import '../../../core/base/base_view_model.dart';
import '../../../core/bookings/bookings_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';

/// B3 My bookings: four tabs, as the API splits them — upcoming (accepted,
/// still ahead), pending, past (done, or accepted and behind us) and
/// cancelled (cancelled or declined). Each tab loads on first open and is
/// kept, so switching back is instant; pull to refresh reloads the one on
/// screen.
class BookingsViewModel extends BaseViewModel {
  BookingsViewModel({required this._bookings}) {
    load();
  }

  final BookingsRepository _bookings;

  BookingTab _tab = BookingTab.upcoming;
  final Map<BookingTab, _TabState> _tabs = <BookingTab, _TabState>{
    for (final BookingTab tab in BookingTab.values) tab: _TabState(),
  };

  BookingTab get tab => _tab;
  _TabState get _current => _tabs[_tab]!;

  List<BookingCard> get items => _current.items;
  bool get hasMore => _current.hasMore;
  bool get isFirstLoad => _current.isLoading && !_current.loaded;
  bool get isLoadingMore => _current.isLoadingMore;
  bool get loadMoreFailed => _current.loadMoreFailed;
  bool get isEmpty => _current.loaded && _current.items.isEmpty;
  bool get loadFailed => _current.failure != null && !_current.loaded;
  Failure? get loadFailure => _current.failure;

  void setTab(BookingTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
    if (!_current.loaded && !_current.isLoading) load();
  }

  /// The tab on screen, from its first page.
  Future<void> load() async {
    final BookingTab tab = _tab;
    final _TabState state = _tabs[tab]!;
    state
      ..isLoading = true
      ..failure = null;
    notifyListeners();
    try {
      _apply(state, await _bookings.list(tab: tab), replace: true);
    } on Failure catch (failure) {
      state.failure = failure;
    } catch (error) {
      state.failure = UnexpectedFailure(cause: error);
    }
    state.isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, and the reload after a booking was opened. What is
  /// on screen stays when it fails.
  Future<Failure?> refresh() async {
    final BookingTab tab = _tab;
    final _TabState state = _tabs[tab]!;
    try {
      _apply(state, await _bookings.list(tab: tab), replace: true);
      state.failure = null;
      // Another tab may have gained or lost what moved: reload it on open.
      for (final BookingTab other in BookingTab.values) {
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
    final BookingTab tab = _tab;
    state
      ..isLoadingMore = true
      ..loadMoreFailed = false;
    notifyListeners();
    try {
      _apply(state, await _bookings.list(tab: tab, page: state.page + 1), replace: false);
    } catch (_) {
      state.loadMoreFailed = true;
    }
    state.isLoadingMore = false;
    notifyListeners();
  }

  static void _apply(_TabState state, ApiPage<BookingCard> page, {required bool replace}) {
    if (replace) state.items.clear();
    final Set<String> known = <String>{for (final BookingCard b in state.items) b.id};
    state.items.addAll(page.items.where((BookingCard b) => known.add(b.id)));
    state
      ..page = page.page
      ..hasMore = page.hasMore
      ..loaded = true;
  }
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
