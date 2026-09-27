import 'package:flutter/foundation.dart';

/// How search results are ordered — the SORT BY chips on 11a.
enum ServiceOrder {
  relevance('relevance'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  rating('rating'),
  popular('popular'),
  newest('newest');

  const ServiceOrder(this.apiValue);

  final String apiValue;

  static ServiceOrder? fromApi(String? value) {
    for (final ServiceOrder order in values) {
      if (order.apiValue == value) return order;
    }
    return null;
  }
}

/// Everything that narrows a list of services: the search box, the category,
/// the filters drawer, the sort.
///
/// Immutable, so a screen can hold the query it is showing and the drawer can
/// work on a copy. It travels between screens as route parameters — the
/// results are deep-linkable, and Back restores exactly what was shown.
@immutable
class ServiceQuery {
  const ServiceQuery({
    this.q,
    this.categoryIds = const <String>{},
    this.wilayaCodes = const <int>{},
    this.priceMin,
    this.priceMax,
    this.minRating,
    this.eventDate,
    this.favouritesOnly = false,
    this.order = ServiceOrder.relevance,
  });

  /// The top of the budget slider, drawn as "500 000+": at the top it means
  /// no ceiling at all.
  static const int priceCeiling = 500000;

  final String? q;

  /// Matches services in any of them. The live API takes one category per
  /// request, so [ApiCatalogRepository] asks for each and merges the lists.
  final Set<String> categoryIds;

  /// Matches services covering any of them.
  final Set<int> wilayaCodes;
  final int? priceMin;
  final int? priceMax;

  /// A minimum average, such as 4.5.
  final num? minRating;

  /// Keeps only services free on that day.
  final DateTime? eventDate;
  final bool favouritesOnly;
  final ServiceOrder order;

  String? get _search {
    final String? text = q?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool get _hasFloor => priceMin != null && priceMin! > 0;
  bool get _hasCeiling => priceMax != null && priceMax! < priceCeiling;

  /// The request's query parameters. Defaults are left out, and wilayas are
  /// sorted so the same filters always make the same request.
  Map<String, Object?> toQuery() => <String, Object?>{
        'q': ?_search,
        if (categoryIds.length == 1)
          'categoryId': categoryIds.first
        else if (categoryIds.isNotEmpty)
          // Repeated, as `wilaya` is — what the API is asked to accept.
          'categoryId': _sortedCategories,
        if (wilayaCodes.isNotEmpty) 'wilaya': _sortedWilayas,
        if (_hasFloor) 'priceMin': priceMin,
        if (_hasCeiling) 'priceMax': priceMax,
        'rating': ?minRating,
        if (eventDate != null) 'eventDate': _day(eventDate!),
        if (favouritesOnly) 'favourite': true,
        if (order != ServiceOrder.relevance) 'order': order.apiValue,
      };

  List<int> get _sortedWilayas => wilayaCodes.toList()..sort();
  List<String> get _sortedCategories => categoryIds.toList()..sort();

  /// How many filters are on — the "Filters · 2" chip. The search text and
  /// the sort are not filters.
  int get filterCount => <bool>[
        categoryIds.isNotEmpty,
        wilayaCodes.isNotEmpty,
        _hasFloor || _hasCeiling,
        minRating != null,
        eventDate != null,
        favouritesOnly,
      ].where((bool on) => on).length;

  /// Nullable fields take a getter, so `() => null` clears one and leaving it
  /// out keeps it.
  ServiceQuery copyWith({
    ValueGetter<String?>? q,
    Set<String>? categoryIds,
    Set<int>? wilayaCodes,
    ValueGetter<int?>? priceMin,
    ValueGetter<int?>? priceMax,
    ValueGetter<num?>? minRating,
    ValueGetter<DateTime?>? eventDate,
    bool? favouritesOnly,
    ServiceOrder? order,
  }) =>
      ServiceQuery(
        q: q == null ? this.q : q(),
        categoryIds: categoryIds ?? this.categoryIds,
        wilayaCodes: wilayaCodes ?? this.wilayaCodes,
        priceMin: priceMin == null ? this.priceMin : priceMin(),
        priceMax: priceMax == null ? this.priceMax : priceMax(),
        minRating: minRating == null ? this.minRating : minRating(),
        eventDate: eventDate == null ? this.eventDate : eventDate(),
        favouritesOnly: favouritesOnly ?? this.favouritesOnly,
        order: order ?? this.order,
      );

  /// "Clear all" — the search and the sort are what the user came with, so
  /// they stay.
  ServiceQuery clearFilters() => ServiceQuery(q: q, order: order);

  /// For a route's query string. Every value is a `String` or a list of them,
  /// as `Uri.queryParameters` wants.
  Map<String, Object> toRouteParams() => <String, Object>{
        'q': ?_search,
        if (categoryIds.isNotEmpty) 'category': _sortedCategories,
        if (wilayaCodes.isNotEmpty)
          'wilaya': _sortedWilayas.map((int code) => '$code').toList(),
        if (_hasFloor) 'priceMin': '$priceMin',
        if (_hasCeiling) 'priceMax': '$priceMax',
        if (minRating != null) 'rating': '$minRating',
        if (eventDate != null) 'date': _day(eventDate!),
        if (favouritesOnly) 'saved': '1',
        if (order != ServiceOrder.relevance) 'order': order.apiValue,
      };

  /// Reads [toRouteParams] back. Anything malformed is dropped rather than
  /// failing the route — a hand-edited link still opens a results screen.
  factory ServiceQuery.fromRouteParams(Map<String, List<String>> params) {
    String? first(String key) {
      final List<String>? values = params[key];
      return values == null || values.isEmpty ? null : values.first;
    }

    return ServiceQuery(
      q: first('q'),
      categoryIds: <String>{
        for (final String id in params['category'] ?? const <String>[])
          if (id.isNotEmpty) id,
      },
      wilayaCodes: <int>{
        for (final String code in params['wilaya'] ?? const <String>[])
          ?int.tryParse(code),
      },
      priceMin: int.tryParse(first('priceMin') ?? ''),
      priceMax: int.tryParse(first('priceMax') ?? ''),
      minRating: num.tryParse(first('rating') ?? ''),
      eventDate: DateTime.tryParse(first('date') ?? ''),
      favouritesOnly: first('saved') == '1',
      order: ServiceOrder.fromApi(first('order')) ?? ServiceOrder.relevance,
    );
  }

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ServiceQuery &&
      other._search == _search &&
      setEquals(other.categoryIds, categoryIds) &&
      setEquals(other.wilayaCodes, wilayaCodes) &&
      other.priceMin == priceMin &&
      other.priceMax == priceMax &&
      other.minRating == minRating &&
      other.eventDate == eventDate &&
      other.favouritesOnly == favouritesOnly &&
      other.order == order;

  @override
  int get hashCode => Object.hash(
        _search,
        Object.hashAll(_sortedCategories),
        Object.hashAll(_sortedWilayas),
        priceMin,
        priceMax,
        minRating,
        eventDate,
        favouritesOnly,
        order,
      );
}
