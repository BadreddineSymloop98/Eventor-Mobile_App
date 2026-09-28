import '../errors/failure.dart';
import '../network/api_client.dart';
import 'models/catalog_models.dart';

/// The client's saved services and packs. Needs a session; a provider is
/// refused (`FORBIDDEN_ROLE`).
abstract interface class FavouritesRepository {
  /// Newest first. [categoryId] narrows to services only.
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  });

  /// Idempotent: saving twice returns the same row.
  Future<Favourite> add(FavouriteTarget target);

  /// Un-saves [target] from a card or a detail screen.
  Future<void> remove(FavouriteTarget target);

  /// Un-saves a row of screen 17. A row that is already gone counts as
  /// removed.
  Future<void> removeById(String favouriteId);
}

/// [FavouritesRepository] against the live API.
class ApiFavouritesRepository implements FavouritesRepository {
  ApiFavouritesRepository(this._api);

  final ApiClient _api;
  static const String _path = '/app/me/favourites';
  static const int _pageSize = 20;

  @override
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  }) async {
    final ApiPage<Map<String, Object?>> result = await _api.getPage(
      _path,
      query: <String, Object?>{
        if (kind != null) 'kind': kind.apiValue,
        'categoryId': ?categoryId,
        'page': page,
        'limit': _pageSize,
      },
    );
    return result.map(Favourite.fromJson);
  }

  @override
  Future<Favourite> add(FavouriteTarget target) async {
    final Object? data = await _api.post(
      _path,
      body: <String, Object?>{
        if (target.kind == FavouriteKind.service) 'serviceId': target.id,
        if (target.kind == FavouriteKind.pack) 'packId': target.id,
      },
    );
    return Favourite.fromJson(data! as Map<String, Object?>);
  }

  /// One call, by what was saved rather than by row. Idempotent on the
  /// server: something no longer saved still answers 204, so a double tap
  /// on the heart never errors.
  @override
  Future<void> remove(FavouriteTarget target) => _api.delete(
        _path,
        query: <String, Object?>{
          if (target.kind == FavouriteKind.service) 'serviceId': target.id,
          if (target.kind == FavouriteKind.pack) 'packId': target.id,
        },
      );

  @override
  Future<void> removeById(String favouriteId) async {
    try {
      await _api.delete('$_path/$favouriteId');
    } on ApiFailure catch (failure) {
      if (failure.code != ApiErrorCode.favouriteNotFound) rethrow;
    }
  }
}
