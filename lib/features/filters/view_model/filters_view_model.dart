import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/service_query.dart';
import '../../../core/reference/reference_repository.dart';

/// 11a — the filters drawer, working on a copy of the results' query.
///
/// Every change updates the live "Show N services" count: one request of a
/// single row, whose `total` is the count, sent 300 ms after the last change
/// so dragging the budget slider does not fire a request per pixel. A count
/// that arrives after a newer one was asked for is dropped.
///
/// Adapted to the API (spec §2.6): any number of categories (merged on
/// live, one request each), wilayas as your city plus
/// whatever is selected with the rest behind "All wilayas", no event type.
class FiltersViewModel extends BaseViewModel {
  FiltersViewModel({
    required ServiceQuery initial,
    required this._catalog,
    required this._reference,
    required this._homeWilaya,
    this._debounce = const Duration(milliseconds: 300),
  }) : _query = initial {
    _loadOptions();
    _scheduleCount(immediately: true);
  }

  final CatalogRepository _catalog;
  final ReferenceRepository _reference;
  final int? _homeWilaya;
  final Duration _debounce;

  ServiceQuery _query;
  int? _resultCount;
  bool _isCounting = false;
  Timer? _countTimer;
  int _countRequest = 0;

  List<CategoryWithCount> _categories = <CategoryWithCount>[];
  List<Wilaya> _wilayas = <Wilaya>[];

  ServiceQuery get query => _query;

  /// `null` until the first count lands, or when it failed.
  int? get resultCount => _resultCount;
  bool get isCounting => _isCounting;

  List<CategoryWithCount> get categories => _categories;

  /// Every open wilaya, for the drill-in.
  List<Wilaya> get allWilayas => _wilayas;

  /// The chips shown inline: the client's own city first, then whatever else
  /// is selected, by code. The rest are one tap away in the drill-in.
  List<Wilaya> get wilayaChips {
    final Set<int> codes = <int>{
      ?_homeWilaya,
      ..._query.wilayaCodes,
    };
    final List<Wilaya> chips = _wilayas
        .where((Wilaya w) => codes.contains(w.code))
        .toList()
      ..sort((Wilaya a, Wilaya b) {
        if (a.code == _homeWilaya) return -1;
        if (b.code == _homeWilaya) return 1;
        return a.code.compareTo(b.code);
      });
    return chips;
  }

  Future<void> _loadOptions() async {
    // Either list failing leaves its group empty; the rest of the drawer
    // still works, and the result count still counts.
    try {
      _categories = await _catalog.categories();
    } catch (_) {
      _categories = <CategoryWithCount>[];
    }
    try {
      _wilayas = await _reference.wilayas();
    } catch (_) {
      _wilayas = <Wilaya>[];
    }
    notifyListeners();
  }

  void _update(ServiceQuery next) {
    if (next == _query) return;
    _query = next;
    notifyListeners();
    _scheduleCount();
  }

  void setOrder(ServiceOrder order) => _update(_query.copyWith(order: order));

  /// Any number of categories — tapping a selected one takes it off.
  void toggleCategory(String categoryId) {
    final Set<String> ids = Set<String>.of(_query.categoryIds);
    if (!ids.remove(categoryId)) ids.add(categoryId);
    _update(_query.copyWith(categoryIds: ids));
  }

  void toggleWilaya(int code) {
    final Set<int> codes = Set<int>.of(_query.wilayaCodes);
    if (!codes.remove(code)) codes.add(code);
    _update(_query.copyWith(wilayaCodes: codes));
  }

  void setWilayas(Set<int> codes) =>
      _update(_query.copyWith(wilayaCodes: Set<int>.of(codes)));

  /// The slider's two ends. The bottom at 0 and the top at the ceiling mean
  /// "no limit" on that side.
  void setPrice(double min, double max) => _update(
        _query.copyWith(
          priceMin: () => min <= 0 ? null : min.round(),
          priceMax: () =>
              max >= ServiceQuery.priceCeiling ? null : max.round(),
        ),
      );

  void setMinRating(num? rating) =>
      _update(_query.copyWith(minRating: () => rating));

  void setEventDate(DateTime? date) =>
      _update(_query.copyWith(eventDate: () => date));

  void setFavouritesOnly(bool value) =>
      _update(_query.copyWith(favouritesOnly: value));

  /// "Clear all" — the search text stays; it is not a filter.
  void clearAll() => _update(_query.clearFilters());

  void _scheduleCount({bool immediately = false}) {
    _countTimer?.cancel();
    if (immediately) {
      _count();
    } else {
      _countTimer = Timer(_debounce, _count);
    }
  }

  Future<void> _count() async {
    final int request = ++_countRequest;
    _isCounting = true;
    notifyListeners();
    int? total;
    try {
      total = (await _catalog.services(_query, limit: 1)).total;
    } catch (_) {
      total = null;
    }
    // A newer change already asked again; this answer is stale.
    if (request != _countRequest) return;
    _resultCount = total;
    _isCounting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    super.dispose();
  }
}
