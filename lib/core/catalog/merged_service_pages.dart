import '../network/api_page.dart';
import 'models/catalog_models.dart';
import 'service_query.dart';

/// Asks the server for one page of one category's results.
typedef CategoryPageFetch = Future<ApiPage<ServiceCard>> Function(
  String categoryId,
  int page,
  int pageSize,
);

/// Several categories' results as one paged list, for an API that filters by
/// a single category per request (`categoryId` rejects a second value).
///
/// Each category is its own paged list on the server, already in the query's
/// order. This merges them as a k-way merge does: it always takes the best of
/// the lists' next cards, and pages a list on only when it has run out — so
/// price, rating and popularity come out in true order across categories,
/// and one category's own order is never changed. Relevance and newest have
/// nothing on the card to compare, so those lists take turns instead.
///
/// Pages are built in order and kept, so asking for one again (a retry, a
/// rebuild) gives the same cards. A failed fetch loses nothing: the next
/// call carries on from where this one stopped.
class MergedServicePages {
  MergedServicePages({
    required List<String> categoryIds,
    required this.order,
    required this.pageSize,
    required this._fetch,
  }) : _lists = <_CategoryList>[
         for (int i = 0; i < categoryIds.length; i++)
           _CategoryList(categoryIds[i], i),
       ];

  final ServiceOrder order;
  final int pageSize;
  final CategoryPageFetch _fetch;
  final List<_CategoryList> _lists;
  final List<ServiceCard> _merged = <ServiceCard>[];

  /// Page [number], 1-based, of [pageSize] cards.
  Future<ApiPage<ServiceCard>> page(int number) async {
    final int end = number * pageSize;
    while (_merged.length < end) {
      await _refill();
      final _CategoryList? next = _best();
      if (next == null) break;
      _merged.add(next.take());
    }

    final int total = _lists.fold(
      0,
      (int sum, _CategoryList list) => sum + list.total,
    );
    final int start = (number - 1) * pageSize;
    // Once every list has given its all, this is the last page, whatever the
    // totals claimed — a list that asks for more would otherwise ask forever.
    final bool exhausted =
        _merged.length <= end &&
        _lists.every(
          (_CategoryList list) => list.buffer.isEmpty && !list.needsPage,
        );
    return ApiPage<ServiceCard>(
      items: start >= _merged.length
          ? const <ServiceCard>[]
          : _merged.sublist(start, end.clamp(0, _merged.length)),
      page: number,
      totalPages: exhausted ? number : (total / pageSize).ceil(),
      total: total,
    );
  }

  /// Fetches, together, the next page of every list that has run out but
  /// has more — the best next card cannot be known until they are in.
  Future<void> _refill() async {
    final List<_CategoryList> dry = _lists
        .where((_CategoryList list) => list.needsPage)
        .toList();
    if (dry.isEmpty) return;
    final List<ApiPage<ServiceCard>> pages = await Future.wait(
      <Future<ApiPage<ServiceCard>>>[
        for (final _CategoryList list in dry)
          _fetch(list.categoryId, list.page + 1, pageSize),
      ],
    );
    // Only once every fetch has succeeded, so a failure leaves no list half
    // advanced.
    for (int i = 0; i < dry.length; i++) {
      dry[i].add(pages[i]);
    }
  }

  _CategoryList? _best() {
    _CategoryList? best;
    for (final _CategoryList list in _lists) {
      if (list.buffer.isEmpty) continue;
      if (best == null || _compare(list, best) < 0) best = list;
    }
    return best;
  }

  /// Negative when [a]'s next card comes before [b]'s. Ties go to the list
  /// that has given fewer cards, then to the first category.
  int _compare(_CategoryList a, _CategoryList b) {
    final ServiceCard x = a.buffer.first;
    final ServiceCard y = b.buffer.first;
    final int byKey = switch (order) {
      ServiceOrder.priceAsc => _amount(
        x.basePrice,
      ).compareTo(_amount(y.basePrice)),
      ServiceOrder.priceDesc => _amount(
        y.basePrice,
      ).compareTo(_amount(x.basePrice)),
      ServiceOrder.rating => _amount(
        y.avgRating,
      ).compareTo(_amount(x.avgRating)),
      ServiceOrder.popular => y.bookingsCount.compareTo(x.bookingsCount),
      ServiceOrder.relevance || ServiceOrder.newest => 0,
    };
    if (byKey != 0) return byKey;
    final int byTurn = a.given.compareTo(b.given);
    return byTurn != 0 ? byTurn : a.position.compareTo(b.position);
  }

  /// For comparing only — an amount shown to the user is never parsed.
  static num _amount(String value) => num.tryParse(value) ?? 0;
}

/// One category's results as fetched so far.
class _CategoryList {
  _CategoryList(this.categoryId, this.position);

  final String categoryId;

  /// Its place in the query, for breaking ties the same way every time.
  final int position;

  final List<ServiceCard> buffer = <ServiceCard>[];
  int page = 0;
  int totalPages = 1;
  int total = 0;

  /// How many cards it has given to the merged list.
  int given = 0;

  bool get needsPage => buffer.isEmpty && page < totalPages;

  void add(ApiPage<ServiceCard> result) {
    buffer.addAll(result.items);
    page = result.page;
    totalPages = result.totalPages;
    total = result.total;
  }

  ServiceCard take() {
    given++;
    return buffer.removeAt(0);
  }
}
