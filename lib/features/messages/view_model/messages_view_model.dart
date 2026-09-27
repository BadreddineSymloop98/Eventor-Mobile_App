import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/conversation_filter.dart';
import '../../../core/messaging/messaging_repository.dart';
import '../../../core/messaging/models/conversation.dart';
import '../../../core/network/api_page.dart';
import '../../shell/shell_badges.dart';

/// Screen 14's empty state, once loading and any error are out of the way.
enum MessagesEmpty {
  /// Rows are showing, or nothing has settled yet — render nothing.
  none,
  all,
  unread,
  bookings,
  search,
}

/// Screen 14 — the conversation list: the All/Unread/Bookings chips, a
/// debounced search, and 20 rows a page.
///
/// Every [load] and [refresh] takes its own generation number; a response or
/// failure whose generation is no longer the latest is dropped, so a slow
/// answer to an old filter or query can never overwrite what a newer one
/// already put on screen. [loadMore] carries no generation of its own — it is
/// blocked while a [load] is in flight, and a page that outlives a newer
/// [load] is discarded without touching the rows that load already set.
class MessagesViewModel extends BaseViewModel {
  MessagesViewModel({
    required this._messaging,
    required this._badges,
    this._debounce = const Duration(milliseconds: 300),
  }) {
    load();
  }

  final MessagingRepository _messaging;
  final ShellBadges _badges;
  final Duration _debounce;

  ConversationFilter _filter = ConversationFilter.all;

  /// The applied, trimmed query — what the last request was sent with.
  String _query = '';

  final List<ConversationRow> _items = <ConversationRow>[];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _isOffline = false;
  int _generation = 0;

  /// Set while [setQuery]'s debounce is waiting to commit its text.
  Timer? _searchTimer;

  /// What [setQuery] last saw, trimmed — read back by [setFilter] to flush a
  /// search the debounce has not committed yet.
  String _pendingQuery = '';

  ConversationFilter get filter => _filter;
  String get query => _query;
  List<ConversationRow> get items => List<ConversationRow>.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// The very first load, with nothing on screen yet — S14's full-screen
  /// loader rather than the row list.
  bool get isFirstLoad => _isLoading && _items.isEmpty;

  /// The next page failed; the list stays and offers a retry at its foot.
  bool get loadMoreFailed => _loadMoreFailed;

  /// The last load or refresh hit a [NetworkFailure] while rows were already
  /// showing: the banner goes up and the rows stay, rather than the screen
  /// turning into the generic error state.
  bool get isOffline => _isOffline;

  /// `none` while loading, erroring, or with rows to show; otherwise which
  /// empty illustration screen 14 renders.
  MessagesEmpty get empty {
    if (_isLoading || hasError || _items.isNotEmpty) return MessagesEmpty.none;
    if (_query.isNotEmpty) return MessagesEmpty.search;
    return switch (_filter) {
      ConversationFilter.all => MessagesEmpty.all,
      ConversationFilter.unread => MessagesEmpty.unread,
      ConversationFilter.booking => MessagesEmpty.bookings,
    };
  }

  /// A chip tap: reloads immediately. A search still waiting on its debounce
  /// is flushed into this same reload rather than firing its own one right
  /// after.
  void setFilter(ConversationFilter filter) {
    final String? pending = _searchTimer == null ? null : _pendingQuery;
    _searchTimer?.cancel();
    _searchTimer = null;
    final String nextQuery = pending ?? _query;
    if (filter == _filter && nextQuery == _query) return;
    _filter = filter;
    _query = nextQuery;
    load();
  }

  /// The search field. Trimmed, and debounced by [_debounce] so a reload is
  /// not fired per keystroke; a blank result sends no `q` at all.
  void setQuery(String text) {
    final String trimmed = text.trim();
    _pendingQuery = trimmed;
    _searchTimer?.cancel();
    _searchTimer = Timer(_debounce, () => _commitQuery(trimmed));
  }

  void _commitQuery(String trimmed) {
    _searchTimer = null;
    if (trimmed == _query) return;
    _query = trimmed;
    load();
  }

  /// Page 1 for the current filter and query.
  Future<void> load() async {
    final int generation = ++_generation;
    _isLoading = true;
    _loadMoreFailed = false;
    notifyListeners();
    try {
      final ApiPage<ConversationRow> page = await _messaging.conversations(
        filter: _filter,
        q: _query.isEmpty ? null : _query,
      );
      if (generation != _generation) return;
      _applyPage(page);
      clearFailure();
      unawaited(_badges.refresh());
    } catch (error) {
      if (generation != _generation) return;
      _applyFailure(error);
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// The next page, appended. Ignored while a [load] is in flight or there
  /// is no further page; a page that lands after a newer [load] started is
  /// dropped.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final int generation = _generation;
    _isLoadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();
    try {
      final ApiPage<ConversationRow> page = await _messaging.conversations(
        filter: _filter,
        q: _query.isEmpty ? null : _query,
        page: _page + 1,
      );
      if (generation == _generation) {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      }
    } catch (_) {
      if (generation == _generation) _loadMoreFailed = true;
    } finally {
      // Unlike load's own flag, this always clears: nothing else will, since
      // loadMore carries no generation of its own to be resumed by.
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Pull to refresh: page 1 again, without the full-screen loader.
  Future<Failure?> refresh() async {
    final int generation = ++_generation;
    try {
      final ApiPage<ConversationRow> page = await _messaging.conversations(
        filter: _filter,
        q: _query.isEmpty ? null : _query,
      );
      if (generation != _generation) return null;
      _applyPage(page);
      clearFailure();
      notifyListeners();
      unawaited(_badges.refresh());
      return null;
    } catch (error) {
      if (generation != _generation) return null;
      final Failure failure = _applyFailure(error);
      return failure;
    }
  }

  void _applyPage(ApiPage<ConversationRow> page) {
    _items
      ..clear()
      ..addAll(page.items);
    _page = page.page;
    _hasMore = page.hasMore;
    _isOffline = false;
    _loadMoreFailed = false;
  }

  /// Records [error] as either the offline banner (a [NetworkFailure] with
  /// rows already showing) or the generic error state, and returns it as a
  /// [Failure] either way.
  Failure _applyFailure(Object error) {
    final Failure failure = error is Failure
        ? error
        : UnexpectedFailure(cause: error);
    if (failure is NetworkFailure && _items.isNotEmpty) {
      _isOffline = true;
      notifyListeners();
    } else {
      setFailure(failure);
    }
    return failure;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
