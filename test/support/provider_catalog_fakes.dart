import 'dart:async';
import 'dart:typed_data';

import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider_catalog/provider_catalog_repository.dart';
import 'package:flutter/foundation.dart' show ValueChanged;

/// A gallery photo as the API sends it.
Map<String, Object?> catalogPhotoJson(
  String id, {
  int position = 0,
  String status = 'ready',
}) =>
    <String, Object?>{
      'id': id,
      'fileId': id,
      'position': position,
      'isCover': position == 0,
      'url': 'https://files.test/$id.webp',
      'thumbUrl': 'https://files.test/$id-thumb.webp',
      'mediumUrl': 'https://files.test/$id-medium.webp',
      'width': 1200,
      'height': 800,
      'processingStatus': status,
      'createdAt': '2026-09-20T10:00:00.000Z',
    };

/// A P6 row — `AppProviderServiceRowDto`.
Map<String, Object?> serviceRowJson({
  String id = 'svc-1',
  String titleEn = 'Wedding photo & video coverage',
  String titleAr = 'تغطية زفاف',
  String status = 'published',
  bool visibleInApp = true,
  String basePrice = '45000.00',
  String priceType = 'per_day',
  int photosCount = 3,
  List<int> wilayas = const <int>[16],
}) =>
    <String, Object?>{
      'id': id,
      'title': titleEn,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'status': status,
      'visibleInApp': visibleInApp,
      'basePrice': basePrice,
      'priceType': priceType,
      'avgRating': '4.80',
      'ratingCount': 32,
      'bookingsCount': 12,
      'photosCount': photosCount,
      'coverUrl': null,
      'wilayas': <Map<String, Object?>>[
        for (final int code in wilayas)
          <String, Object?>{'code': code, 'name': 'W$code', 'nameEn': 'W$code', 'nameAr': 'و$code'},
      ],
    };

/// P7a's source — `ServiceDetailDto`.
Map<String, Object?> serviceDetailJson({
  String id = 'svc-1',
  String titleEn = 'Wedding photo & video coverage',
  String titleAr = 'تغطية زفاف',
  String descriptionEn = 'Full-day coverage.',
  String descriptionAr = 'تغطية كاملة.',
  String status = 'published',
  bool visibleInApp = true,
  String basePrice = '45000.00',
  String priceType = 'per_day',
  List<String> publishMissing = const <String>[],
  List<String> visibilityReasons = const <String>[],
  Map<String, Object?>? hidden,
  List<Map<String, Object?>>? photos,
  List<int> wilayas = const <int>[16],
  Set<int> closedWilayas = const <int>{},
  List<Map<String, Object?>> facts = const <Map<String, Object?>>[],
  List<Map<String, Object?>> extras = const <Map<String, Object?>>[],
  int maxEventsPerDay = 1,
  int? maxGuests,
}) =>
    <String, Object?>{
      'id': id,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'cancellationPolicyEn': null,
      'cancellationPolicyAr': null,
      'category': <String, Object?>{'id': 'cat-photo', 'nameEn': 'Photography', 'nameAr': 'التصوير'},
      'basePrice': basePrice,
      'priceType': priceType,
      'status': status,
      'visibleInApp': visibleInApp,
      'coverUrl': null,
      'facts': facts,
      'extras': extras,
      'wilayas': <Map<String, Object?>>[
        for (final int code in wilayas) <String, Object?>{'code': code, 'name': 'W$code', 'nameAr': 'و$code'},
      ],
      'wilayaDetails': <Map<String, Object?>>[
        for (final int code in wilayas)
          <String, Object?>{
            'code': code,
            'name': 'W$code',
            'nameAr': 'و$code',
            'isOpen': !closedWilayas.contains(code),
          },
      ],
      'maxEventsPerDay': maxEventsPerDay,
      'maxGuests': maxGuests,
      'photos': photos ??
          <Map<String, Object?>>[
            catalogPhotoJson('$id-p1'),
            catalogPhotoJson('$id-p2', position: 1),
          ],
      'hidden': hidden,
      'visibilityReasons': visibilityReasons,
      'publishMissing': publishMissing,
      'rating': 4.8,
      'ratingCount': 32,
      'bookingsCount': 12,
      'stats': <String, Object?>{'packsCount': 0, 'packs': <Object?>[]},
    };

/// A P10 row — `PackRowDto`.
Map<String, Object?> packRowJson({
  String id = 'pack-1',
  String nameEn = 'Essentiel Mariage',
  String nameAr = 'باقة الزفاف',
  String status = 'published',
  String price = '320000.00',
  String sumOfItems = '365000.00',
  bool needsAttention = false,
  List<Map<String, Object?>> attentionReasons = const <Map<String, Object?>>[],
}) =>
    <String, Object?>{
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'coverUrl': null,
      'itemsCount': 3,
      'itemsSummary': <Map<String, Object?>>[
        <String, Object?>{'nameEn': 'Venues', 'nameAr': 'قاعات'},
      ],
      'price': price,
      'sumOfItems': sumOfItems,
      'savings': '45000.00',
      'savingsPercent': 12.3,
      'eventType': 'wedding',
      'wilaya': <String, Object?>{'code': 16, 'name': 'Alger', 'nameAr': 'الجزائر'},
      'rating': 4.9,
      'ratingCount': 18,
      'bookingsCount': 21,
      'status': status,
      'needsAttention': needsAttention,
      'attentionReasons': attentionReasons,
      'visibleInApp': status == 'published' && !needsAttention,
      'createdAt': '2026-09-01T10:00:00.000Z',
      'updatedAt': '2026-09-01T10:00:00.000Z',
    };

/// P12's source — `PackDetailDto`.
Map<String, Object?> packDetailJson({
  String id = 'pack-1',
  String nameEn = 'Essentiel Mariage',
  String nameAr = 'باقة الزفاف',
  String status = 'draft',
  String price = '320000.00',
  List<String> serviceIds = const <String>['svc-1', 'svc-2'],
  List<String> publishMissing = const <String>[],
  int wilaya = 16,
}) =>
    <String, Object?>{
      ...packRowJson(id: id, nameEn: nameEn, nameAr: nameAr, status: status, price: price),
      'wilaya': <String, Object?>{'code': wilaya, 'name': 'W$wilaya', 'nameAr': 'و$wilaya'},
      'descriptionEn': 'Everything together.',
      'descriptionAr': null,
      'maxGuests': 150,
      'items': <Map<String, Object?>>[
        for (final (int i, String serviceId) in serviceIds.indexed)
          <String, Object?>{
            'position': i,
            'price': '100000.00',
            'availability': 'available',
            'service': <String, Object?>{
              'id': serviceId,
              'titleEn': 'Service $serviceId',
              'titleAr': 'خدمة',
              'coverUrl': null,
              'category': <String, Object?>{'id': 'cat-venue', 'nameEn': 'Venues', 'nameAr': 'قاعات'},
              'status': 'published',
              'priceType': 'per_event',
              'rating': 4.5,
            },
          },
      ],
      'photos': <Map<String, Object?>>[],
      'publishMissing': publishMissing,
      'stats': <String, Object?>{'total': serviceIds.length, 'published': serviceIds.length},
      'createdBy': null,
    };

/// A picked image, `size` bytes long.
PickedImage testImage({String extension = 'jpg', int size = 1024}) => PickedImage(
      name: 'photo.$extension',
      bytes: Uint8List(size),
      extension: extension,
    );

/// [ProviderCatalogRepository] over scripted JSON. Writes change what later
/// reads answer, roughly as the server would.
class FakeProviderCatalogRepository implements ProviderCatalogRepository {
  FakeProviderCatalogRepository({
    List<Map<String, Object?>>? serviceRows,
    Map<String, Map<String, Object?>>? serviceDetails,
    List<Map<String, Object?>>? packRows,
    Map<String, Map<String, Object?>>? packDetails,
  })  : serviceRows = serviceRows ?? <Map<String, Object?>>[serviceRowJson()],
        serviceDetails = serviceDetails ?? <String, Map<String, Object?>>{'svc-1': serviceDetailJson()},
        packRows = packRows ?? <Map<String, Object?>>[],
        packDetails = packDetails ?? <String, Map<String, Object?>>{};

  List<Map<String, Object?>> serviceRows;
  Map<String, Map<String, Object?>> serviceDetails;
  List<Map<String, Object?>> packRows;
  Map<String, Map<String, Object?>> packDetails;

  /// `services`, `service:<id>`, `createService`, `updateService:<id>`,
  /// `publishService:<id>`, `addServicePhoto:<id>`, `orderServicePhotos:<id>`…
  final List<String> calls = <String>[];

  /// A failure for the next call whose name starts with the key — one-shot.
  final Map<String, Failure> failNext = <String, Failure>{};

  /// When set, calls wait on it.
  Completer<void>? gate;

  ServiceInput? lastServiceInput;
  PackInput? lastPackInput;
  List<String>? lastOrder;

  Future<void> _enter(String call) async {
    calls.add(call);
    final Completer<void>? pending = gate;
    if (pending != null) await pending.future;
    for (final String key in failNext.keys.toList()) {
      if (call.startsWith(key)) throw failNext.remove(key)!;
    }
  }

  Map<String, Object?> _service(String id) =>
      serviceDetails[id] ??
      (throw const ApiFailure(statusCode: 404, code: ApiErrorCode.serviceNotFound, message: 'Gone'));

  Map<String, Object?> _pack(String id) =>
      packDetails[id] ??
      (throw const ApiFailure(statusCode: 404, code: ApiErrorCode.packNotFound, message: 'Gone'));

  @override
  Future<List<ProviderServiceSummary>> services() async {
    await _enter('services');
    return serviceRows.map(ProviderServiceSummary.fromJson).toList();
  }

  @override
  Future<ProviderServiceDetail> service(String id) async {
    await _enter('service:$id');
    return ProviderServiceDetail.fromJson(_service(id));
  }

  @override
  Future<ProviderServiceDetail> createService(ServiceInput input) async {
    await _enter('createService');
    lastServiceInput = input;
    final Map<String, Object?> json = input.toJson();
    final Map<String, Object?> detail = serviceDetailJson(
      id: 'svc-new',
      titleEn: json['titleEn'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      status: 'draft',
      visibleInApp: false,
      basePrice: json['basePrice'] as String? ?? '0.00',
      priceType: json['priceType'] as String? ?? 'per_event',
      photos: <Map<String, Object?>>[],
      wilayas: (json['wilayaCodes'] as List<Object?>? ?? <Object?>[]).whereType<int>().toList(),
    );
    detail['publishMissing'] = _missing(detail);
    serviceDetails['svc-new'] = detail;
    return ProviderServiceDetail.fromJson(detail);
  }

  static List<String> _missing(Map<String, Object?> d) => <String>[
        for (final String key in <String>['titleEn', 'titleAr', 'descriptionEn', 'descriptionAr'])
          if ((d[key] as String? ?? '').isEmpty) key,
        if ((d['photos']! as List<Object?>).isEmpty) 'photos',
        if ((d['wilayaDetails']! as List<Object?>).isEmpty) 'wilayas',
      ];

  @override
  Future<ProviderServiceDetail> updateService(String id, ServiceInput input) async {
    await _enter('updateService:$id');
    lastServiceInput = input;
    final Map<String, Object?> detail = _service(id);
    input.toJson().forEach((String key, Object? value) {
      if (key != 'wilayaCodes' && key != 'categoryId') detail[key] = value;
    });
    detail['publishMissing'] = _missing(detail);
    return ProviderServiceDetail.fromJson(detail);
  }

  @override
  Future<void> deleteService(String id) async {
    await _enter('deleteService:$id');
    _service(id);
    serviceDetails.remove(id);
    serviceRows.removeWhere((Map<String, Object?> r) => r['id'] == id);
  }

  @override
  Future<ProviderServiceDetail> publishService(String id) async {
    await _enter('publishService:$id');
    final Map<String, Object?> detail = _service(id);
    final List<Object?> missing = detail['publishMissing']! as List<Object?>;
    if (missing.isNotEmpty) {
      throw ApiFailure(
        statusCode: 422,
        code: ApiErrorCode.servicePublishInvalid,
        message: 'Not yet',
        details: <String, Object?>{'missing': missing},
      );
    }
    detail['status'] = 'published';
    _setRowStatus(id, 'published');
    return ProviderServiceDetail.fromJson(detail);
  }

  @override
  Future<ProviderServiceDetail> unpublishService(String id) async {
    await _enter('unpublishService:$id');
    final Map<String, Object?> detail = _service(id);
    detail['status'] = 'draft';
    _setRowStatus(id, 'draft');
    return ProviderServiceDetail.fromJson(detail);
  }

  void _setRowStatus(String id, String status) {
    for (final Map<String, Object?> row in serviceRows) {
      if (row['id'] == id) row['status'] = status;
    }
  }

  List<CatalogPhoto> _addPhoto(Map<String, Object?> owner, ValueChanged<double>? onProgress) {
    final List<Object?> photos = owner['photos']! as List<Object?>;
    final Map<String, Object?> photo =
        catalogPhotoJson('${owner['id']}-new${photos.length}', position: photos.length);
    owner['photos'] = <Object?>[...photos, photo];
    onProgress?.call(1);
    return readPhotos(owner['photos']);
  }

  List<CatalogPhoto> _removePhoto(Map<String, Object?> owner, String photoId) {
    owner['photos'] = <Object?>[
      for (final Object? p in owner['photos']! as List<Object?>)
        if ((p! as Map<String, Object?>)['id'] != photoId) p,
    ];
    return readPhotos(owner['photos']);
  }

  List<CatalogPhoto> _order(Map<String, Object?> owner, List<String> ids) {
    lastOrder = ids;
    final List<Object?> photos = owner['photos']! as List<Object?>;
    owner['photos'] = <Object?>[
      for (final (int i, String id) in ids.indexed)
        <String, Object?>{
          ...photos.cast<Map<String, Object?>>().firstWhere((Map<String, Object?> p) => p['id'] == id),
          'position': i,
          'isCover': i == 0,
        },
    ];
    return readPhotos(owner['photos']);
  }

  @override
  Future<List<CatalogPhoto>> addServicePhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) async {
    await _enter('addServicePhoto:$id');
    return _addPhoto(_service(id), onProgress);
  }

  @override
  Future<List<CatalogPhoto>> removeServicePhoto(String id, String photoId) async {
    await _enter('removeServicePhoto:$id:$photoId');
    return _removePhoto(_service(id), photoId);
  }

  @override
  Future<List<CatalogPhoto>> orderServicePhotos(String id, List<String> photoIds) async {
    await _enter('orderServicePhotos:$id');
    return _order(_service(id), photoIds);
  }

  @override
  Future<List<ProviderPackSummary>> packs() async {
    await _enter('packs');
    return packRows.map(ProviderPackSummary.fromJson).toList();
  }

  @override
  Future<ProviderPackDetail> pack(String id) async {
    await _enter('pack:$id');
    return ProviderPackDetail.fromJson(_pack(id));
  }

  @override
  Future<ProviderPackDetail> createPack(PackInput input) async {
    await _enter('createPack');
    lastPackInput = input;
    final Map<String, Object?> json = input.toJson();
    final Map<String, Object?> detail = packDetailJson(
      id: 'pack-new',
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
      serviceIds: (json['serviceIds'] as List<Object?>? ?? <Object?>[]).whereType<String>().toList(),
      publishMissing: <String>[if ((json['nameAr'] as String? ?? '').isEmpty) 'nameAr'],
    );
    packDetails['pack-new'] = detail;
    return ProviderPackDetail.fromJson(detail);
  }

  @override
  Future<ProviderPackDetail> updatePack(String id, PackInput input) async {
    await _enter('updatePack:$id');
    lastPackInput = input;
    final Map<String, Object?> detail = _pack(id);
    input.toJson().forEach((String key, Object? value) {
      if (key == 'nameEn' || key == 'nameAr' || key == 'price') detail[key] = value;
    });
    return ProviderPackDetail.fromJson(detail);
  }

  @override
  Future<void> deletePack(String id) async {
    await _enter('deletePack:$id');
    _pack(id);
    packDetails.remove(id);
    packRows.removeWhere((Map<String, Object?> r) => r['id'] == id);
  }

  @override
  Future<ProviderPackDetail> publishPack(String id) async {
    await _enter('publishPack:$id');
    final Map<String, Object?> detail = _pack(id);
    final List<Object?> missing = detail['publishMissing']! as List<Object?>;
    if (missing.isNotEmpty) {
      throw ApiFailure(
        statusCode: 422,
        code: ApiErrorCode.packPublishInvalid,
        message: 'Not yet',
        details: <String, Object?>{'missing': missing},
      );
    }
    detail['status'] = 'published';
    return ProviderPackDetail.fromJson(detail);
  }

  @override
  Future<ProviderPackDetail> unpublishPack(String id) async {
    await _enter('unpublishPack:$id');
    final Map<String, Object?> detail = _pack(id);
    detail['status'] = 'unpublished';
    return ProviderPackDetail.fromJson(detail);
  }

  @override
  Future<List<CatalogPhoto>> addPackPhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) async {
    await _enter('addPackPhoto:$id');
    return _addPhoto(_pack(id), onProgress);
  }

  @override
  Future<List<CatalogPhoto>> removePackPhoto(String id, String photoId) async {
    await _enter('removePackPhoto:$id:$photoId');
    return _removePhoto(_pack(id), photoId);
  }

  @override
  Future<List<CatalogPhoto>> orderPackPhotos(String id, List<String> photoIds) async {
    await _enter('orderPackPhotos:$id');
    return _order(_pack(id), photoIds);
  }
}
