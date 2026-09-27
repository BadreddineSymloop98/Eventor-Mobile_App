/// One page of a list endpoint — the envelope's `data` with its `meta`.
///
/// The API pages from 1; an empty result comes back as page 1 of 0.
class ApiPage<T> {
  const ApiPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  /// Nothing yet — the starting point of a list before its first load.
  factory ApiPage.empty() => ApiPage<T>(
        items: const <Never>[],
        page: 0,
        totalPages: 0,
        total: 0,
      );

  final List<T> items;
  final int page;
  final int totalPages;

  /// Across every page, not just this one — what "28 services" shows.
  final int total;

  bool get hasMore => page < totalPages;

  ApiPage<R> map<R>(R Function(T item) convert) => ApiPage<R>(
        items: items.map(convert).toList(),
        page: page,
        totalPages: totalPages,
        total: total,
      );
}
