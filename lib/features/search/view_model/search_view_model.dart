import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/recent_searches.dart';
import '../../../core/catalog/service_query.dart';

/// S1 — the Search tab before anything is typed: recent searches and the
/// categories to browse, each with how many services it has.
class SearchViewModel extends BaseViewModel {
  SearchViewModel({required this._catalog, required this._recents}) {
    loadCategories();
  }

  final CatalogRepository _catalog;
  final RecentSearches _recents;

  List<CategoryWithCount> _categories = <CategoryWithCount>[];
  bool _isLoading = false;

  List<String> get recents => _recents.all;
  List<CategoryWithCount> get categories => _categories;
  bool get isLoadingCategories => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    final List<CategoryWithCount>? categories =
        await runGuarded(_catalog.categories);
    if (categories != null) _categories = categories;
    _isLoading = false;
    notifyListeners();
  }

  /// The results to open for [text], remembered as a recent search; `null`
  /// for a blank one.
  Future<ServiceQuery?> submit(String text) async {
    final String query = text.trim();
    if (query.isEmpty) return null;
    await _recents.add(query);
    notifyListeners();
    return ServiceQuery(q: query);
  }

  Future<void> removeRecent(String query) async {
    await _recents.remove(query);
    notifyListeners();
  }

  Future<void> clearRecents() async {
    await _recents.clear();
    notifyListeners();
  }
}
