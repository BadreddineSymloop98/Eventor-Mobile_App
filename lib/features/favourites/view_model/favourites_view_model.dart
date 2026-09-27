import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/favourites_controller.dart';
import '../../../core/catalog/favourites_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_page.dart';

/// Screen 17 — what the client saved: services or packs, a category at a
/// time for services.
///
/// Removing is undoable (spec D6): the card leaves the grid at once, and the
/// server is only told when the toast closes without Undo. A heart changed on
/// any other screen moves [FavouritesController.version], and the list
/// reloads to match.
class FavouritesViewModel extends BaseViewModel {
  FavouritesViewModel({
    required this._favourites,
    required this._catalog,
    required this._controller,
  }) : _seenVersion = _controller.version {
    _controller.addListener(_onFavouritesChanged);
    load();
    _loadCategories();
  }

  final FavouritesRepository _favourites;
  final CatalogRepository _catalog;
  final FavouritesController _controller;

  FavouriteKind _kind = FavouriteKind.service;
  String? _categoryId;
  final List<Favourite> _items = <Favourite>[];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _seenVersion;

  /// Moves on with every new list; an answer for an older one — another tab,
  /// another category — is dropped instead of mixed in.
  int _generation = 0;
  List<CategoryWithCount> _categories = <CategoryWithCount>[];

  FavouriteKind get kind => _kind;
  String? get categoryId => _categoryId;
  List<Favourite> get items => List<Favourite>.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isFirstLoad => _isLoading && _items.isEmpty;
  bool get isEmpty => !_isLoading && !hasError && _items.isEmpty;
  List<CategoryWithCount> get categories => _categories;

  Future<void> load() async {
    final int generation = ++_generation;
    _isLoading = true;
    _items.clear();
    notifyListeners();
    final ApiPage<Favourite>? page = await runGuarded(
      () => _favourites.list(
        kind: _kind,
        categoryId: _kind == FavouriteKind.service ? _categoryId : null,
      ),
    );
    if (generation != _generation) return;
    if (page != null) {
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.page;
      _hasMore = page.hasMore;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    final int generation = _generation;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final ApiPage<Favourite> page = await _favourites.list(
        kind: _kind,
        categoryId: _kind == FavouriteKind.service ? _categoryId : null,
        page: _page + 1,
      );
      if (generation == _generation) {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      }
    } catch (_) {
      // The next scroll asks again.
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Pull to refresh, keeping the grid if it fails.
  Future<Failure?> refresh() async {
    final int generation = _generation;
    try {
      final ApiPage<Favourite> page = await _favourites.list(
        kind: _kind,
        categoryId: _kind == FavouriteKind.service ? _categoryId : null,
      );
      if (generation != _generation) return null;
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.page;
      _hasMore = page.hasMore;
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  void setKind(FavouriteKind kind) {
    if (kind == _kind) return;
    _kind = kind;
    load();
  }

  /// Services only — packs have no single category.
  void setCategory(String? categoryId) {
    if (categoryId == _categoryId) return;
    _categoryId = categoryId;
    load();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _catalog.categories();
      notifyListeners();
    } catch (_) {
      // The chips stay at "All".
    }
  }

  /// Takes [favourite] off the grid, for now. Returns where it was, for
  /// [undoRemove].
  int removeLocally(Favourite favourite) {
    final int index = _items.indexWhere((Favourite f) => f.id == favourite.id);
    if (index < 0) return -1;
    _items.removeAt(index);
    notifyListeners();
    return index;
  }

  /// Puts it back where it was — Undo.
  void undoRemove(Favourite favourite, int index) {
    if (_items.any((Favourite f) => f.id == favourite.id)) return;
    _items.insert(index.clamp(0, _items.length), favourite);
    notifyListeners();
  }

  /// Tells the server, once Undo is no longer on offer. A failure puts the
  /// card back and is returned for a toast.
  Future<Failure?> commitRemove(Favourite favourite, int index) async {
    try {
      await _favourites.removeById(favourite.id);
      // Seen before notifying, so this screen does not reload for its own
      // change; every other screen's hearts empty.
      _seenVersion = _controller.version + 1;
      _controller.markRemoved(favourite.target);
      return null;
    } on Failure catch (failure) {
      undoRemove(favourite, index);
      return failure;
    }
  }

  void _onFavouritesChanged() {
    if (_controller.version == _seenVersion) return;
    _seenVersion = _controller.version;
    load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onFavouritesChanged);
    super.dispose();
  }
}
