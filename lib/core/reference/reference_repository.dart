import '../models/account.dart';
import '../network/api_client.dart';

/// The server's fixed lists — wilayas and service categories — loaded once
/// per app run and kept.
///
/// Both change only when an admin edits them, which is rare enough that a
/// cold start is a fine time to pick changes up.
abstract interface class ReferenceRepository {
  Future<List<Wilaya>> wilayas();
  Future<List<ServiceCategory>> categories();
}

class ApiReferenceRepository implements ReferenceRepository {
  ApiReferenceRepository(this._api);

  final ApiClient _api;

  List<Wilaya>? _wilayas;
  List<ServiceCategory>? _categories;

  @override
  Future<List<Wilaya>> wilayas() async {
    return _wilayas ??= (await _list('/app/wilayas'))
        .map(Wilaya.fromJson)
        .toList()
      ..sort((Wilaya a, Wilaya b) => a.code.compareTo(b.code));
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    return _categories ??=
        (await _list('/app/categories')).map(ServiceCategory.fromJson).toList();
  }

  Future<List<Map<String, Object?>>> _list(String path) async {
    final Object? data = await _api.get(path, isPublic: true);
    if (data is! List<Object?>) return const <Map<String, Object?>>[];
    return data.whereType<Map<String, Object?>>().toList();
  }
}
