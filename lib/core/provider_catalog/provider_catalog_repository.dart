import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/foundation.dart' show ValueChanged;

import '../messaging/picked_image.dart';
import '../network/api_client.dart';
import 'models/catalog_photo.dart';
import 'models/provider_pack.dart';
import 'models/provider_service.dart';

export '../messaging/picked_image.dart' show ImageProblem, PickedImage;
export 'models/catalog_photo.dart';
export 'models/content_language.dart';
export 'models/provider_pack.dart';
export 'models/provider_service.dart';

/// The provider's own catalog — Figma section 10, P6–P14: their services
/// and Ready Packs, drafts included, and the galleries of both.
///
/// Every write answers with what the server now holds, so a screen never
/// has to guess what its save did.
abstract interface class ProviderCatalogRepository {
  /// P6 — every service, drafts and hidden ones included. Unpaginated.
  Future<List<ProviderServiceSummary>> services();

  /// P7a's source of truth, with its publish checklist.
  Future<ProviderServiceDetail> service(String id);

  /// P7's first save. The service starts as a draft.
  Future<ProviderServiceDetail> createService(ServiceInput input);

  /// A partial update: only what [input] sets changes.
  Future<ProviderServiceDetail> updateService(String id, ServiceInput input);

  /// Refused with 409 `SERVICE_HAS_BOOKINGS` while an accepted booking is
  /// ahead (and `SERVICE_IN_PACKS`, should the server send it).
  Future<void> deleteService(String id);

  /// 422 `SERVICE_PUBLISH_INVALID` (`details.missing`) or
  /// `PROVIDER_NOT_VERIFIED` when it cannot go live yet.
  Future<ProviderServiceDetail> publishService(String id);

  /// Back to a draft.
  Future<ProviderServiceDetail> unpublishService(String id);

  /// P8 — answers the whole gallery. 422 `PHOTO_LIMIT_REACHED` past the
  /// config's `photosPerService`.
  Future<List<CatalogPhoto>> addServicePhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  });

  /// Refused with 422 `SERVICE_PUBLISH_INVALID` for the last photo of a
  /// published service.
  Future<List<CatalogPhoto>> removeServicePhoto(String id, String photoId);

  /// Every photo id, in the new order; the first is the cover.
  Future<List<CatalogPhoto>> orderServicePhotos(String id, List<String> photoIds);

  /// P10.
  Future<List<ProviderPackSummary>> packs();

  /// P12's source of truth, with its publish checklist.
  Future<ProviderPackDetail> pack(String id);

  Future<ProviderPackDetail> createPack(PackInput input);

  Future<ProviderPackDetail> updatePack(String id, PackInput input);

  /// Refused with 409 `PACK_HAS_BOOKINGS` while a booking on it is live.
  Future<void> deletePack(String id);

  /// 422 `PACK_PUBLISH_INVALID` (`details.missing`) or
  /// `PROVIDER_NOT_VERIFIED`.
  Future<ProviderPackDetail> publishPack(String id);

  /// To `unpublished` — not back to a draft, unlike a service.
  Future<ProviderPackDetail> unpublishPack(String id);

  /// P13 — the limit is the config's `photosPerPack`.
  Future<List<CatalogPhoto>> addPackPhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  });

  Future<List<CatalogPhoto>> removePackPhoto(String id, String photoId);

  Future<List<CatalogPhoto>> orderPackPhotos(String id, List<String> photoIds);
}

/// [ProviderCatalogRepository] against the live API.
class ApiProviderCatalogRepository implements ProviderCatalogRepository {
  ApiProviderCatalogRepository(this._api);

  final ApiClient _api;

  static const String _services = '/app/provider/services';
  static const String _packs = '/app/provider/packs';

  @override
  Future<List<ProviderServiceSummary>> services() async =>
      _rows(await _api.get(_services)).map(ProviderServiceSummary.fromJson).toList();

  @override
  Future<ProviderServiceDetail> service(String id) async =>
      ProviderServiceDetail.fromJson(_object(await _api.get('$_services/$id')));

  @override
  Future<ProviderServiceDetail> createService(ServiceInput input) async =>
      ProviderServiceDetail.fromJson(
        _object(await _api.post(_services, body: input.toJson())),
      );

  @override
  Future<ProviderServiceDetail> updateService(String id, ServiceInput input) async =>
      ProviderServiceDetail.fromJson(
        _object(await _api.patch('$_services/$id', body: input.toJson())),
      );

  @override
  Future<void> deleteService(String id) => _api.delete('$_services/$id');

  @override
  Future<ProviderServiceDetail> publishService(String id) async =>
      ProviderServiceDetail.fromJson(
        _object(await _api.post('$_services/$id/publish')),
      );

  @override
  Future<ProviderServiceDetail> unpublishService(String id) async =>
      ProviderServiceDetail.fromJson(
        _object(await _api.post('$_services/$id/unpublish')),
      );

  @override
  Future<List<CatalogPhoto>> addServicePhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) =>
      _upload('$_services/$id/photos', image, onProgress);

  @override
  Future<List<CatalogPhoto>> removeServicePhoto(String id, String photoId) async =>
      readPhotos(await _api.delete('$_services/$id/photos/$photoId'));

  @override
  Future<List<CatalogPhoto>> orderServicePhotos(String id, List<String> photoIds) async =>
      readPhotos(
        await _api.patch(
          '$_services/$id/photos/order',
          body: <String, Object?>{'ids': photoIds},
        ),
      );

  @override
  Future<List<ProviderPackSummary>> packs() async =>
      _rows(await _api.get(_packs)).map(ProviderPackSummary.fromJson).toList();

  @override
  Future<ProviderPackDetail> pack(String id) async =>
      ProviderPackDetail.fromJson(_object(await _api.get('$_packs/$id')));

  @override
  Future<ProviderPackDetail> createPack(PackInput input) async =>
      ProviderPackDetail.fromJson(
        _object(await _api.post(_packs, body: input.toJson())),
      );

  @override
  Future<ProviderPackDetail> updatePack(String id, PackInput input) async =>
      ProviderPackDetail.fromJson(
        _object(await _api.patch('$_packs/$id', body: input.toJson())),
      );

  @override
  Future<void> deletePack(String id) => _api.delete('$_packs/$id');

  @override
  Future<ProviderPackDetail> publishPack(String id) async =>
      ProviderPackDetail.fromJson(_object(await _api.post('$_packs/$id/publish')));

  @override
  Future<ProviderPackDetail> unpublishPack(String id) async =>
      ProviderPackDetail.fromJson(_object(await _api.post('$_packs/$id/unpublish')));

  @override
  Future<List<CatalogPhoto>> addPackPhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) =>
      _upload('$_packs/$id/photos', image, onProgress);

  @override
  Future<List<CatalogPhoto>> removePackPhoto(String id, String photoId) async =>
      readPhotos(await _api.delete('$_packs/$id/photos/$photoId'));

  @override
  Future<List<CatalogPhoto>> orderPackPhotos(String id, List<String> photoIds) async =>
      readPhotos(
        await _api.patch(
          '$_packs/$id/photos/order',
          body: <String, Object?>{'ids': photoIds},
        ),
      );

  Future<List<CatalogPhoto>> _upload(
    String path,
    PickedImage image,
    ValueChanged<double>? onProgress,
  ) async =>
      readPhotos(
        await _api.upload(
          path,
          // Built inside the closure: a retry after a token refresh has to
          // rebuild the form, since a FormData stream can only be read once.
          form: () => FormData.fromMap(<String, Object?>{
            'file': MultipartFile.fromBytes(image.bytes, filename: image.name),
          }),
          onProgress: onProgress,
        ),
      );

  static List<Map<String, Object?>> _rows(Object? data) => data is List<Object?>
      ? data.whereType<Map<String, Object?>>().toList()
      : const <Map<String, Object?>>[];

  static Map<String, Object?> _object(Object? data) =>
      data is Map<String, Object?> ? data : const <String, Object?>{};
}
