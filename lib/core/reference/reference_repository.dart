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

  /// The communes of one wilaya, by name — B1's Commune field. Kept per
  /// wilaya once loaded.
  Future<List<Commune>> communes(int wilayaCode);
}

class ApiReferenceRepository implements ReferenceRepository {
  ApiReferenceRepository(this._api);

  final ApiClient _api;

  List<Wilaya>? _wilayas;
  List<ServiceCategory>? _categories;
  final Map<int, List<Commune>> _communes = <int, List<Commune>>{};

  @override
  Future<List<Wilaya>> wilayas() async {
    return _wilayas ??= (await _list('/app/wilayas'))
        .map(Wilaya.fromJson)
        .toList()
      // The server ranks them by services; every picker lists them by code,
      // and 11a ranks its top chips from [Wilaya.servicesCount] itself.
      ..sort((Wilaya a, Wilaya b) => a.code.compareTo(b.code));
  }

  @override
  Future<List<ServiceCategory>> categories() async {
    return _categories ??=
        (await _list('/app/categories')).map(ServiceCategory.fromJson).toList();
  }

  @override
  Future<List<Commune>> communes(int wilayaCode) async {
    final List<Commune>? known = _communes[wilayaCode];
    if (known != null) return known;
    return _communes[wilayaCode] =
        (await _list('/app/wilayas/$wilayaCode/communes'))
            .map(Commune.fromJson)
            .toList();
  }

  Future<List<Map<String, Object?>>> _list(String path) async {
    final Object? data = await _api.get(path, isPublic: true);
    if (data is! List<Object?>) return const <Map<String, Object?>>[];
    return data.whereType<Map<String, Object?>>().toList();
  }
}
