import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';

/// Screen 19 — Ready Packs, by event type and order, 20 at a time.
class PacksViewModel extends BaseViewModel {
  PacksViewModel({required this._catalog, this._eventType}) {
    load();
  }

  final CatalogRepository _catalog;

  EventType? _eventType;
  PackOrder _order = PackOrder.savings;
  final List<PackCard> _items = <PackCard>[];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;

  /// Moves on with every new list; an answer for an older one is dropped, so
  /// a slow response for a chip the user already left cannot overwrite the
  /// one they chose.
  int _generation = 0;

  /// `null` is "All".
  EventType? get eventType => _eventType;
  PackOrder get order => _order;
  List<PackCard> get items => List<PackCard>.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isFirstLoad => _isLoading && _items.isEmpty;
  bool get isLoadingMore => _isLoadingMore;
  bool get loadMoreFailed => _loadMoreFailed;
  bool get isEmpty => !_isLoading && !hasError && _items.isEmpty;

  Future<void> load() async {
    final int generation = ++_generation;
    _isLoading = true;
    _items.clear();
    notifyListeners();
    final ApiPage<PackCard>? page = await runGuarded(
      () => _catalog.packs(eventType: _eventType, order: _order),
    );
    if (generation != _generation) return;
    if (page != null) _apply(page, replace: true);
    _isLoading = false;
    notifyListeners();
  }

  void setEventType(EventType? type) {
    if (type == _eventType) return;
    _eventType = type;
    load();
  }

  void setOrder(PackOrder order) {
    if (order == _order) return;
    _order = order;
    load();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final int generation = _generation;
    _isLoadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();
    try {
      final ApiPage<PackCard> page =
          await _catalog.packs(eventType: _eventType, order: _order, page: _page + 1);
      if (generation == _generation) _apply(page, replace: false);
    } catch (_) {
      if (generation == _generation) _loadMoreFailed = true;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<Failure?> refresh() async {
    final int generation = _generation;
    try {
      final ApiPage<PackCard> page =
          await _catalog.packs(eventType: _eventType, order: _order);
      if (generation != _generation) return null;
      _apply(page, replace: true);
      _loadMoreFailed = false;
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  void _apply(ApiPage<PackCard> page, {required bool replace}) {
    if (replace) _items.clear();
    _items.addAll(page.items);
    _page = page.page;
    _hasMore = page.hasMore;
  }
}
