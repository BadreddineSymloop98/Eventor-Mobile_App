import '../network/api_client.dart';
import 'merged_service_pages.dart';
import 'models/catalog_models.dart';
import 'service_query.dart';

/// How Ready Packs are ordered on 19. The API has no "newest" for packs.
enum PackOrder {
  savings('savings'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  rating('rating'),
  popular('popular');

  const PackOrder(this.apiValue);

  final String apiValue;
}

/// Everything a client browses: Home, services, providers, packs and their
/// calendars.
abstract interface class CatalogRepository {
  /// The whole of screen 11 in one call. Needs a session.
  Future<HomeFeed> home();

  /// Every category with its service count. Loaded once per run.
  Future<List<CategoryWithCount>> categories();

  /// [limit] 1 is how the filters drawer counts results without loading them.
  /// Several categories match a service in any of them.
  Future<ApiPage<ServiceCard>> services(
    ServiceQuery query, {
    int page = 1,
    int limit = 20,
  });

  Future<ServiceDetail> service(String id);

  /// The calendar for the month containing [month].
  Future<Availability> serviceAvailability(String id, DateTime month);

  Future<ProviderDetail> provider(String id);

  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  });

  Future<PackDetail> pack(String id);

  /// Only the days when every service in the pack is free.
  Future<Availability> packAvailability(String id, DateTime month);
}

/// [CatalogRepository] against the live API.
///
/// The catalog routes are public, but every call carries the session anyway:
/// without it the server answers as a stranger and every `isFavourite` comes
/// back false.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._api);

  final ApiClient _api;
  static const int _pageSize = 20;

  Future<List<CategoryWithCount>>? _categories;

  /// Multi-category lists being paged through, most recently used last —
  /// the results on screen and the drawer's count, with room to spare.
  final Map<(ServiceQuery, int), MergedServicePages> _merges =
      <(ServiceQuery, int), MergedServicePages>{};
  static const int _mergesKept = 4;

  @override
  Future<HomeFeed> home() async =>
      HomeFeed.fromJson(_object(await _api.get('/app/home')));

  @override
  Future<List<CategoryWithCount>> categories() {
    // A failed load is forgotten, so the next caller tries again.
    return _categories ??= _loadCategories()
      ..catchError((Object _) {
        _categories = null;
        return const <CategoryWithCount>[];
      });
  }

  Future<List<CategoryWithCount>> _loadCategories() async {
    final Object? data = await _api.get('/app/categories');
    final List<CategoryWithCount> categories = data is List<Object?>
        ? data
            .whereType<Map<String, Object?>>()
            .map(CategoryWithCount.fromJson)
            .toList()
        : <CategoryWithCount>[];
    return categories
      ..sort(
        (CategoryWithCount a, CategoryWithCount b) =>
            a.position.compareTo(b.position),
      );
  }

  @override
  Future<ApiPage<ServiceCard>> services(
    ServiceQuery query, {
    int page = 1,
    int limit = _pageSize,
  }) {
    // The API takes one categoryId per request (a second is a 400), so
    // several are asked for one by one and merged.
    if (query.categoryIds.length > 1) return _merged(query, limit, page).page(page);
    return _servicesPage(query, page, limit);
  }

  MergedServicePages _merged(ServiceQuery query, int limit, int page) {
    final (ServiceQuery, int) key = (query, limit);
    // Page 1 starts afresh: a first load, or a pull to refresh.
    MergedServicePages? merge = page == 1 ? null : _merges.remove(key);
    merge ??= MergedServicePages(
      categoryIds: query.categoryIds.toList()..sort(),
      order: query.order,
      pageSize: limit,
      fetch: (String categoryId, int number, int size) => _servicesPage(
        query.copyWith(categoryIds: <String>{categoryId}),
        number,
        size,
      ),
    );
    _merges
      ..remove(key)
      ..[key] = merge;
    while (_merges.length > _mergesKept) {
      _merges.remove(_merges.keys.first);
    }
    return merge;
  }

  Future<ApiPage<ServiceCard>> _servicesPage(
    ServiceQuery query,
    int page,
    int limit,
  ) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/services',
      query: <String, Object?>{
        ...query.toQuery(),
        'page': page,
        'limit': limit,
      },
    );
    return result.map(ServiceCard.fromJson);
  }

  @override
  Future<ServiceDetail> service(String id) async =>
      ServiceDetail.fromJson(_object(await _api.get('/app/services/$id')));

  @override
  Future<Availability> serviceAvailability(String id, DateTime month) async =>
      Availability.fromJson(
        _object(
          await _api.get(
            '/app/services/$id/availability',
            query: <String, Object?>{'month': monthParam(month)},
          ),
        ),
      );

  @override
  Future<ProviderDetail> provider(String id) async =>
      ProviderDetail.fromJson(_object(await _api.get('/app/providers/$id')));

  @override
  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  }) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      '/app/packs',
      query: <String, Object?>{
        if (eventType != null) 'eventType': eventType.apiValue,
        if (order != PackOrder.savings) 'order': order.apiValue,
        'page': page,
        'limit': _pageSize,
      },
    );
    return result.map(PackCard.fromJson);
  }

  @override
  Future<PackDetail> pack(String id) async =>
      PackDetail.fromJson(_object(await _api.get('/app/packs/$id')));

  @override
  Future<Availability> packAvailability(String id, DateTime month) async =>
      Availability.fromJson(
        _object(
          await _api.get(
            '/app/packs/$id/availability',
            query: <String, Object?>{'month': monthParam(month)},
          ),
        ),
      );

  static Map<String, Object?> _object(Object? data) =>
      data is Map<String, Object?> ? data : const <String, Object?>{};
}

/// `2026-03` — the month a calendar request names.
String monthParam(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';
