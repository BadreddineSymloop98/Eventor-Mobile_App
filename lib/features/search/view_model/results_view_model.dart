import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';

/// A filter that can be taken off from S2b's chips.
enum FilterChipKind { category, wilaya, price, rating, eventDate, favourites }

/// S2 / S2a / S2b — the services matching one [query], 20 at a time.
///
/// One view model per query: changing the sort or the filters opens a new
/// results page for the new query (the route is keyed by its URL), so this
/// never has to reconcile an old list with a new query.
class ResultsViewModel extends BaseViewModel {
  ResultsViewModel({required this.query, required this._catalog}) {
    load();
    _loadCategoryNames();
  }

  final ServiceQuery query;
  final CatalogRepository _catalog;

  final List<ServiceCard> _items = <ServiceCard>[];
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  List<CategoryWithCount> _categories = const <CategoryWithCount>[];

  List<ServiceCard> get items => List<ServiceCard>.unmodifiable(_items);
  int get total => _total;
  bool get hasMore => _hasMore;
  bool get isFirstLoad => _isLoading && _items.isEmpty;
  bool get isLoadingMore => _isLoadingMore;

  /// The next page failed; the list stays and offers a retry at its foot.
  bool get loadMoreFailed => _loadMoreFailed;

  /// Loaded, and nothing matched — S2b.
  bool get isEmpty => !_isLoading && !hasError && _items.isEmpty;

  /// The chosen categories, in the catalog's order — S2a's title, once the
  /// category list is in.
  List<CategoryWithCount> get categories => _categories;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final ApiPage<ServiceCard>? page =
        await runGuarded(() => _catalog.services(query));
    if (page != null) {
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.page;
      _total = page.total;
      _hasMore = page.hasMore;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// The next page, when the list nears its end. Ignored while one is
  /// already loading or there is none.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();
    try {
      final ApiPage<ServiceCard> page =
          await _catalog.services(query, page: _page + 1);
      _items.addAll(page.items);
      _page = page.page;
      _total = page.total;
      _hasMore = page.hasMore;
    } catch (_) {
      _loadMoreFailed = true;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Pull to refresh: page 1 again. The old list stays if it fails.
  Future<Failure?> refresh() async {
    try {
      final ApiPage<ServiceCard> page = await _catalog.services(query);
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.page;
      _total = page.total;
      _hasMore = page.hasMore;
      _loadMoreFailed = false;
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  Future<void> _loadCategoryNames() async {
    if (query.categoryIds.isEmpty) return;
    try {
      final List<CategoryWithCount> all = await _catalog.categories();
      _categories = <CategoryWithCount>[
        for (final CategoryWithCount category in all)
          if (query.categoryIds.contains(category.id)) category,
      ];
      notifyListeners();
    } catch (_) {
      // The title falls back to the generic one.
    }
  }

  /// The filters that are on, in the order the chips show them.
  List<FilterChipKind> get activeFilters => <FilterChipKind>[
        if (query.categoryIds.isNotEmpty) FilterChipKind.category,
        if (query.wilayaCodes.isNotEmpty) FilterChipKind.wilaya,
        if (query.toQuery().containsKey('priceMin') ||
            query.toQuery().containsKey('priceMax'))
          FilterChipKind.price,
        if (query.minRating != null) FilterChipKind.rating,
        if (query.eventDate != null) FilterChipKind.eventDate,
        if (query.favouritesOnly) FilterChipKind.favourites,
      ];

  /// [query] without one filter — the results to open when its chip is
  /// taken off.
  ServiceQuery without(FilterChipKind kind) => switch (kind) {
        FilterChipKind.category => query.copyWith(categoryIds: const <String>{}),
        FilterChipKind.wilaya => query.copyWith(wilayaCodes: const <int>{}),
        FilterChipKind.price =>
          query.copyWith(priceMin: () => null, priceMax: () => null),
        FilterChipKind.rating => query.copyWith(minRating: () => null),
        FilterChipKind.eventDate => query.copyWith(eventDate: () => null),
        FilterChipKind.favourites => query.copyWith(favouritesOnly: false),
      };
}
