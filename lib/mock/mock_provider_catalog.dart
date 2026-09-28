import 'package:flutter/foundation.dart' show ValueChanged;

import '../core/config/app_config.dart';
import '../core/errors/failure.dart';
import '../core/formatting/money_format.dart';
import '../core/models/account.dart';
import '../core/provider_catalog/provider_catalog_repository.dart';
import 'mock_backend.dart';
import 'mock_catalog_data.dart';
import 'mock_reference_data.dart';

/// [ProviderCatalogRepository] on the in-app [MockBackend], with the live
/// rules and error codes: the publish checklists, the photo limits, a pack's
/// 2–6 own services priced below their sum in one wilaya they all cover, and
/// the refusals to delete what still has bookings ahead.
///
/// Each provider's catalog is kept per account email in the backend's
/// `providerCatalog` store. `verified.provider@` starts from the const
/// catalog — the same service ids `MockCatalogLookups.providerServices`
/// lists, so bookings and services agree — plus a draft missing its Arabic,
/// an admin-hidden service and one covering only a closed wilaya, so P6
/// shows every card state; every other provider starts empty.
///
/// Photos: the mock cannot keep uploaded bytes in SharedPreferences, so an
/// upload stores one of the bundled mock photos (`asset:` URLs, the ones
/// `mock_catalog_data.dart` uses) in the category's style instead.
class MockProviderCatalogRepository implements ProviderCatalogRepository {
  MockProviderCatalogRepository(
    this._backend, {
    required this._languageCode,
    bool Function(String serviceId)? hasUpcomingBookings,
    bool Function(String packId)? packHasUpcomingBookings,
    this._config = const AppConfig(),
  })  : _hasUpcomingBookings = hasUpcomingBookings ?? _none,
        _packHasUpcomingBookings = packHasUpcomingBookings ?? _none;

  final MockBackend _backend;
  final String Function() _languageCode;

  /// Whether an accepted booking is still ahead on a service — the booking
  /// store knows, this repository does not; the integrator wires it.
  final bool Function(String serviceId) _hasUpcomingBookings;
  final bool Function(String packId) _packHasUpcomingBookings;
  final AppConfig _config;

  static bool _none(String _) => false;

  static const String storeName = 'providerCatalog';

  /// Wilayas the mock treats as closed on Eventor — Tizi Ouzou, as P6's
  /// "Not visible" card draws. The reference list still offers it, so
  /// choosing it shows the server's `WILAYA_CLOSED`.
  static const Set<int> closedWilayas = <int>{15};

  /// The seeded provider, and the const-catalog provider it trades as.
  static const String seededEmail = 'verified.provider@eventor.test';
  static const String catalogProviderId = 'c62532f4-6fa9-4752-9f82-cdbea4b0dd07';

  /// Bundled photos per category slug, and how many of each exist.
  static const Map<String, int> _photoSets = <String, int>{
    'salles-des-fetes': 6,
    'photographie': 6,
    'traiteur': 4,
    'musique-dj': 4,
    'decoration': 4,
    'fleurs': 4,
    'gateaux-patisserie': 6,
    'transport': 4,
  };

  static final RegExp _amount = RegExp(r'^\d{1,12}(\.\d{1,2})?$');

  bool get _isArabic => _languageCode() == 'ar';

  // ------------------------------------------------------------ helpers

  /// The ids of [provider]'s services — what the availability mock checks a
  /// block's `serviceId` against (`AVAILABILITY_SERVICE_INVALID`).
  Set<String> serviceIdsOf(MockAccount provider) => <String>{
        for (final Map<String, Object?> s in _servicesOf(_catalogOf(provider)))
          s['id']! as String,
      };

  /// [provider]'s services as `AppProviderServiceRowDto`s — what the home's
  /// "Your services" could list instead of the const catalog.
  List<Map<String, Object?>> serviceRowsOf(MockAccount provider) =>
      <Map<String, Object?>>[
        for (final Map<String, Object?> s in _servicesOf(_catalogOf(provider)))
          _serviceRow(provider, s),
      ];

  // ----------------------------------------------------------- services

  @override
  Future<List<ProviderServiceSummary>> services() async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    return <ProviderServiceSummary>[
      for (final Map<String, Object?> s in _servicesOf(_catalogOf(account)))
        ProviderServiceSummary.fromJson(_serviceRow(account, s)),
    ];
  }

  @override
  Future<ProviderServiceDetail> service(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    return _serviceDetail(account, _service(account, id));
  }

  @override
  Future<ProviderServiceDetail> createService(ServiceInput input) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> json = input.toJson();
    _validateService(json, creating: true);
    final Map<String, Object?> catalog = _catalogOf(account);
    final String now = _backend.now.toUtc().toIso8601String();
    final Map<String, Object?> record = <String, Object?>{
      'id': 'mock-service-${_nextId(catalog)}',
      'titleEn': '',
      'titleAr': '',
      'descriptionEn': '',
      'descriptionAr': '',
      'cancellationPolicyEn': null,
      'cancellationPolicyAr': null,
      'categoryId': null,
      'basePrice': '0.00',
      'priceType': 'per_event',
      'status': 'draft',
      'facts': <Object?>[],
      'extras': <Object?>[],
      'wilayaCodes': <Object?>[],
      'maxEventsPerDay': 1,
      'maxGuests': null,
      'photos': <Object?>[],
      'hidden': null,
      'avgRating': '0.00',
      'ratingCount': 0,
      'bookingsCount': 0,
      'createdAt': now,
      'updatedAt': now,
    };
    _applyService(record, json);
    // Newest first, as the list shows them.
    (catalog['services']! as List<Object?>).insert(0, record);
    await _backend.saveStores();
    return _serviceDetail(account, record);
  }

  @override
  Future<ProviderServiceDetail> updateService(String id, ServiceInput input) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _service(account, id);
    final Map<String, Object?> json = input.toJson();
    _validateService(json, creating: false);
    _applyService(record, json);
    record['updatedAt'] = _backend.now.toUtc().toIso8601String();
    await _backend.saveStores();
    return _serviceDetail(account, record);
  }

  @override
  Future<void> deleteService(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    _service(account, id);
    if (_hasUpcomingBookings(id)) {
      throw _failure(
        409,
        ApiErrorCode.serviceHasBookings,
        'This service has accepted upcoming bookings.',
      );
    }
    final int packsCount = _packsOf(catalog)
        .where((Map<String, Object?> p) => _ids(p['serviceIds']).contains(id))
        .length;
    if (packsCount > 0) {
      throw _failure(
        409,
        ApiErrorCode.serviceInPacks,
        'This service is part of $packsCount of your packs.',
        details: <String, Object?>{'packsCount': packsCount},
      );
    }
    (catalog['services']! as List<Object?>)
        .removeWhere((Object? s) => s is Map<String, Object?> && s['id'] == id);
    await _backend.saveStores();
  }

  @override
  Future<ProviderServiceDetail> publishService(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _service(account, id);
    final String status = record['status']! as String;
    if (status != 'draft') {
      throw _failure(
        409,
        ApiErrorCode.serviceInvalidTransition,
        'This action is not possible while the service is $status.',
      );
    }
    final List<String> missing = _serviceMissing(record);
    if (missing.isNotEmpty) {
      throw _failure(
        422,
        ApiErrorCode.servicePublishInvalid,
        'The service cannot be published yet: ${missing.join(', ')}.',
        details: <String, Object?>{'missing': missing},
      );
    }
    if (account.verificationStatus != VerificationStatus.verified) {
      throw _notVerified();
    }
    record['status'] = 'published';
    await _backend.saveStores();
    return _serviceDetail(account, record);
  }

  @override
  Future<ProviderServiceDetail> unpublishService(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _service(account, id);
    final String status = record['status']! as String;
    if (status != 'published') {
      throw _failure(
        409,
        ApiErrorCode.serviceInvalidTransition,
        'This action is not possible while the service is $status.',
      );
    }
    record['status'] = 'draft';
    await _backend.saveStores();
    return _serviceDetail(account, record);
  }

  @override
  Future<List<CatalogPhoto>> addServicePhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) async {
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _service(account, id);
    return _addPhoto(
      record,
      image,
      limit: _config.photosPerService,
      slug: _slugOf(record['categoryId'] as String?),
      onProgress: onProgress,
    );
  }

  @override
  Future<List<CatalogPhoto>> removeServicePhoto(String id, String photoId) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _service(account, id);
    final List<Object?> photos = record['photos']! as List<Object?>;
    _photo(photos, photoId);
    if (photos.length == 1 && record['status'] == 'published') {
      throw _failure(
        422,
        ApiErrorCode.servicePublishInvalid,
        'The service cannot be published yet: photos.',
        details: <String, Object?>{
          'missing': <String>['photos'],
        },
      );
    }
    photos.removeWhere((Object? p) => p is Map<String, Object?> && p['id'] == photoId);
    await _backend.saveStores();
    return readPhotos(_photosJson(photos));
  }

  @override
  Future<List<CatalogPhoto>> orderServicePhotos(String id, List<String> photoIds) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    return _order(_service(account, id), photoIds);
  }

  // -------------------------------------------------------------- packs

  @override
  Future<List<ProviderPackSummary>> packs() async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    return <ProviderPackSummary>[
      for (final Map<String, Object?> p in _packsOf(catalog))
        ProviderPackSummary.fromJson(_packJson(account, catalog, p)),
    ];
  }

  @override
  Future<ProviderPackDetail> pack(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    return ProviderPackDetail.fromJson(
      _packJson(account, catalog, _pack(catalog, id)),
    );
  }

  @override
  Future<ProviderPackDetail> createPack(PackInput input) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    final Map<String, Object?> json = input.toJson();
    _validatePack(catalog, json, creating: true);
    final String now = _backend.now.toUtc().toIso8601String();
    final Map<String, Object?> record = <String, Object?>{
      'id': 'mock-pack-${_nextId(catalog)}',
      'nameEn': '',
      'nameAr': '',
      'descriptionEn': null,
      'descriptionAr': null,
      'eventType': 'other',
      'wilayaCode': 16,
      'price': '0.00',
      'maxGuests': null,
      'serviceIds': <Object?>[],
      'photos': <Object?>[],
      'status': 'draft',
      'avgRating': '0.00',
      'ratingCount': 0,
      'bookingsCount': 0,
      'createdAt': now,
      'updatedAt': now,
    };
    _applyPack(record, json);
    (catalog['packs']! as List<Object?>).insert(0, record);
    await _backend.saveStores();
    return ProviderPackDetail.fromJson(_packJson(account, catalog, record));
  }

  @override
  Future<ProviderPackDetail> updatePack(String id, PackInput input) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    final Map<String, Object?> record = _pack(catalog, id);
    final Map<String, Object?> json = input.toJson();
    _validatePack(catalog, json, creating: false);
    _applyPack(record, json);
    record['updatedAt'] = _backend.now.toUtc().toIso8601String();
    await _backend.saveStores();
    return ProviderPackDetail.fromJson(_packJson(account, catalog, record));
  }

  @override
  Future<void> deletePack(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    _pack(catalog, id);
    if (_packHasUpcomingBookings(id)) {
      throw _failure(
        409,
        ApiErrorCode.packHasBookings,
        'This pack has accepted upcoming bookings.',
      );
    }
    (catalog['packs']! as List<Object?>)
        .removeWhere((Object? p) => p is Map<String, Object?> && p['id'] == id);
    await _backend.saveStores();
  }

  @override
  Future<ProviderPackDetail> publishPack(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    final Map<String, Object?> record = _pack(catalog, id);
    final String status = record['status']! as String;
    if (status == 'published') {
      throw _failure(
        409,
        ApiErrorCode.packInvalidTransition,
        'This action is not possible while the pack is $status.',
      );
    }
    final List<String> missing = _packMissing(account, catalog, record);
    final List<String> content = missing
        .where((String m) => m != 'providerNotVerified' && m != 'providerBlocked')
        .toList();
    if (content.length == 1 && content.single == 'wilayaNotCovered') {
      throw _failure(
        422,
        ApiErrorCode.packWilayaNotCovered,
        'Every service of the pack must cover its wilaya.',
        details: <String, Object?>{'missing': missing},
      );
    }
    if (content.isNotEmpty) {
      throw _failure(
        422,
        ApiErrorCode.packPublishInvalid,
        'The pack cannot be published yet: ${missing.join(', ')}.',
        details: <String, Object?>{'missing': missing},
      );
    }
    if (account.verificationStatus != VerificationStatus.verified) {
      throw _notVerified();
    }
    record['status'] = 'published';
    await _backend.saveStores();
    return ProviderPackDetail.fromJson(_packJson(account, catalog, record));
  }

  @override
  Future<ProviderPackDetail> unpublishPack(String id) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    final Map<String, Object?> record = _pack(catalog, id);
    final String status = record['status']! as String;
    if (status != 'published') {
      throw _failure(
        409,
        ApiErrorCode.packInvalidTransition,
        'This action is not possible while the pack is $status.',
      );
    }
    record['status'] = 'unpublished';
    await _backend.saveStores();
    return ProviderPackDetail.fromJson(_packJson(account, catalog, record));
  }

  @override
  Future<List<CatalogPhoto>> addPackPhoto(
    String id,
    PickedImage image, {
    ValueChanged<double>? onProgress,
  }) async {
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> catalog = _catalogOf(account);
    final Map<String, Object?> record = _pack(catalog, id);
    final List<String> items = _ids(record['serviceIds']);
    String? categoryId;
    for (final Map<String, Object?> s in _servicesOf(catalog)) {
      if (items.isNotEmpty && s['id'] == items.first) {
        categoryId = s['categoryId'] as String?;
      }
    }
    return _addPhoto(
      record,
      image,
      limit: _config.photosPerPack,
      slug: _slugOf(categoryId),
      onProgress: onProgress,
    );
  }

  @override
  Future<List<CatalogPhoto>> removePackPhoto(String id, String photoId) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    final Map<String, Object?> record = _pack(_catalogOf(account), id);
    final List<Object?> photos = record['photos']! as List<Object?>;
    _photo(photos, photoId);
    photos.removeWhere((Object? p) => p is Map<String, Object?> && p['id'] == photoId);
    await _backend.saveStores();
    return readPhotos(_photosJson(photos));
  }

  @override
  Future<List<CatalogPhoto>> orderPackPhotos(String id, List<String> photoIds) async {
    await _backend.delay();
    final MockAccount account = _backend.requireProvider();
    return _order(_pack(_catalogOf(account), id), photoIds);
  }

  // ------------------------------------------------------------- photos

  Future<List<CatalogPhoto>> _addPhoto(
    Map<String, Object?> record,
    PickedImage image, {
    required int limit,
    required String slug,
    ValueChanged<double>? onProgress,
  }) async {
    final List<Object?> photos = record['photos']! as List<Object?>;
    if (photos.length >= limit) {
      await _backend.delay();
      throw _failure(
        422,
        ApiErrorCode.photoLimitReached,
        'The photo limit ($limit) is reached.',
        details: <String, Object?>{'max': limit},
      );
    }
    final String extension =
        image.extension.toLowerCase() == 'jpg' ? 'jpeg' : image.extension.toLowerCase();
    if (!_config.imageTypes.contains(extension)) {
      await _backend.delay();
      throw _failure(415, ApiErrorCode.fileTypeNotAllowed, 'This file type is not allowed.');
    }
    if (image.bytes.length > _config.maxPhotoMb * 1024 * 1024) {
      await _backend.delay();
      throw _failure(
        413,
        ApiErrorCode.fileTooLarge,
        'The file is larger than ${_config.maxPhotoMb} MB.',
      );
    }
    // A short, visible upload.
    for (int step = 1; step <= 4; step++) {
      await _backend.delay();
      onProgress?.call(step / 4);
      if (_backend.latency == Duration.zero) break;
    }
    final int count = _photoSets[slug] ?? _photoSets['salles-des-fetes']!;
    final int seq = (record['photoSeq'] as num? ?? photos.length).toInt() + 1;
    record['photoSeq'] = seq;
    photos.add(<String, Object?>{
      'id': '${record['id']}-photo-$seq',
      'file': 'pexels-$slug-${(seq - 1) % count + 1}.webp',
      // "Processing" for a moment, as the server's variants lag the upload.
      'readyAt': _backend.now
          .add(_backend.latency * 3)
          .millisecondsSinceEpoch,
      'createdAt': _backend.now.toUtc().toIso8601String(),
    });
    await _backend.saveStores();
    return readPhotos(_photosJson(photos));
  }

  Future<List<CatalogPhoto>> _order(Map<String, Object?> record, List<String> ids) async {
    final List<Object?> photos = record['photos']! as List<Object?>;
    final List<String> current = <String>[
      for (final Object? p in photos) (p! as Map<String, Object?>)['id']! as String,
    ];
    final bool valid = ids.length == current.length &&
        ids.toSet().length == ids.length &&
        ids.every(current.contains);
    if (!valid) {
      throw _failure(
        422,
        ApiErrorCode.photoOrderInvalid,
        'The order must list every photo exactly once.',
      );
    }
    final List<Object?> ordered = <Object?>[
      for (final String id in ids)
        photos.firstWhere((Object? p) => (p! as Map<String, Object?>)['id'] == id),
    ];
    photos
      ..clear()
      ..addAll(ordered);
    await _backend.saveStores();
    return readPhotos(_photosJson(photos));
  }

  Map<String, Object?> _photo(List<Object?> photos, String photoId) {
    for (final Object? p in photos) {
      if (p is Map<String, Object?> && p['id'] == photoId) return p;
    }
    throw _failure(404, ApiErrorCode.photoNotFound, 'The photo was not found.');
  }

  List<Map<String, Object?>> _photosJson(List<Object?> photos) {
    final int nowMs = _backend.now.millisecondsSinceEpoch;
    return <Map<String, Object?>>[
      for (int i = 0; i < photos.length; i++)
        () {
          final Map<String, Object?> p = photos[i]! as Map<String, Object?>;
          final String url = 'asset:assets/mock/photos/${p['file']}';
          final int readyAt = (p['readyAt'] as num? ?? 0).toInt();
          return <String, Object?>{
            'id': p['id'],
            'fileId': p['id'],
            'position': i,
            'isCover': i == 0,
            'url': url,
            'thumbUrl': url,
            'mediumUrl': url,
            'width': 1200,
            'height': 800,
            'processingStatus': nowMs < readyAt ? 'pending' : 'ready',
            'createdAt': p['createdAt'],
          };
        }(),
    ];
  }

  // ------------------------------------------------------ service rules

  void _validateService(Map<String, Object?> json, {required bool creating}) {
    final List<FieldError> errors = <FieldError>[];
    void error(String field, String code, String message) =>
        errors.add(FieldError(field: field, code: code, message: message));

    if (creating) {
      for (final String field in <String>['categoryId', 'titleEn', 'basePrice', 'priceType']) {
        if (json[field] == null) error(field, 'IS_DEFINED', '$field should not be empty');
      }
    }
    if (json.containsKey('titleEn') && (json['titleEn'] as String? ?? '').trim().isEmpty) {
      error('titleEn', 'IS_NOT_EMPTY', 'titleEn should not be empty');
    }
    for (final String field in <String>['titleEn', 'titleAr']) {
      if ((json[field] as String? ?? '').length > ProviderServiceDetail.maxTitleLength) {
        error(field, 'MAX_LENGTH', '$field must be shorter than or equal to 160 characters');
      }
    }
    for (final String field in <String>[
      'descriptionEn',
      'descriptionAr',
      'cancellationPolicyEn',
      'cancellationPolicyAr',
    ]) {
      if ((json[field] as String? ?? '').length > ProviderServiceDetail.maxTextLength) {
        error(field, 'MAX_LENGTH', '$field must be shorter than or equal to 5000 characters');
      }
    }
    if (json['basePrice'] case final String price when !_amount.hasMatch(price)) {
      error('basePrice', 'IS_DECIMAL', 'basePrice must be a decimal amount');
    }
    if (json['maxEventsPerDay'] case final int events when events < 1 || events > 20) {
      error('maxEventsPerDay', 'MAX', 'maxEventsPerDay must be between 1 and 20');
    }
    if (json['maxGuests'] case final int guests when guests < 1) {
      error('maxGuests', 'MIN', 'maxGuests must not be less than 1');
    }
    if (json['facts'] case final List<Object?> facts) {
      for (final Map<String, Object?> fact in facts.whereType<Map<String, Object?>>()) {
        final bool complete = <String>['label_en', 'label_ar', 'value_en', 'value_ar']
            .every((String k) => (fact[k] as String? ?? '').trim().isNotEmpty);
        final bool fits = (fact['label_en'] as String? ?? '').length <= ServiceFact.maxLabelLength &&
            (fact['label_ar'] as String? ?? '').length <= ServiceFact.maxLabelLength &&
            (fact['value_en'] as String? ?? '').length <= ServiceFact.maxValueLength &&
            (fact['value_ar'] as String? ?? '').length <= ServiceFact.maxValueLength;
        if (!complete || !fits) {
          error('facts', 'VALIDATE_NESTED', 'each fact needs a label and a value in both languages');
          break;
        }
      }
    }
    if (json['extras'] case final List<Object?> extras) {
      for (final Map<String, Object?> extra in extras.whereType<Map<String, Object?>>()) {
        if ((extra['nameEn'] as String? ?? '').trim().isEmpty ||
            !_amount.hasMatch(extra['price'] as String? ?? '')) {
          error('extras', 'VALIDATE_NESTED', 'each extra needs an English name and a price');
          break;
        }
      }
    }
    if (errors.isNotEmpty) {
      throw ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: errors,
      );
    }
    if (json['categoryId'] case final String id when _category(id) == null) {
      throw _failure(404, ApiErrorCode.categoryNotFound, 'The category was not found.');
    }
    if (json['wilayaCodes'] case final List<Object?> codes) {
      _checkWilayas(codes.whereType<int>());
    }
  }

  void _checkWilayas(Iterable<int> codes) {
    final List<String> closed = <String>[];
    for (final int code in codes) {
      final Wilaya? wilaya = _wilaya(code);
      if (wilaya == null) {
        throw _failure(404, ApiErrorCode.wilayaNotFound, 'The wilaya was not found.');
      }
      if (closedWilayas.contains(code)) closed.add(wilaya.nameFor(_languageCode()));
    }
    if (closed.isNotEmpty) {
      throw _failure(
        422,
        ApiErrorCode.wilayaClosed,
        'Some wilayas are closed: ${closed.join(', ')}.',
        details: <String, Object?>{'closed': closed},
      );
    }
  }

  void _applyService(Map<String, Object?> record, Map<String, Object?> json) {
    for (final String field in <String>[
      'categoryId',
      'titleEn',
      'titleAr',
      'descriptionEn',
      'descriptionAr',
      'cancellationPolicyEn',
      'cancellationPolicyAr',
      'basePrice',
      'priceType',
      'maxEventsPerDay',
      'maxGuests',
    ]) {
      if (json.containsKey(field)) record[field] = json[field];
    }
    if (json['basePrice'] case final String price) {
      record['basePrice'] = _twoDecimals(price);
    }
    if (json['facts'] case final List<Object?> facts) {
      record['facts'] = <Object?>[
        for (final Map<String, Object?> f in facts.whereType<Map<String, Object?>>())
          Map<String, Object?>.of(f),
      ];
    }
    if (json['extras'] case final List<Object?> extras) {
      final List<Object?> rows = <Object?>[];
      for (final Map<String, Object?> e in extras.whereType<Map<String, Object?>>()) {
        rows.add(<String, Object?>{
          'id': '${record['id']}-extra-${rows.length}',
          'nameEn': e['nameEn'],
          'nameAr': e['nameAr'] ?? '',
          'price': _twoDecimals(e['price']! as String),
        });
      }
      record['extras'] = rows;
    }
    if (json['wilayaCodes'] case final List<Object?> codes) {
      record['wilayaCodes'] = <Object?>[...codes.whereType<int>().toSet()];
    }
  }

  List<String> _serviceMissing(Map<String, Object?> s) => <String>[
        if ((s['titleEn'] as String? ?? '').trim().isEmpty) 'titleEn',
        if ((s['titleAr'] as String? ?? '').trim().isEmpty) 'titleAr',
        if ((s['descriptionEn'] as String? ?? '').trim().isEmpty) 'descriptionEn',
        if ((s['descriptionAr'] as String? ?? '').trim().isEmpty) 'descriptionAr',
        if (amountCents(s['basePrice'] as String? ?? '0') <= 0) 'price',
        if ((s['photos']! as List<Object?>).isEmpty) 'photos',
        if (_category(s['categoryId'] as String?) == null) 'category',
        if (!_hasOpenWilaya(s)) 'wilayas',
      ];

  bool _hasOpenWilaya(Map<String, Object?> s) =>
      _codes(s['wilayaCodes']).any((int code) => !closedWilayas.contains(code));

  List<String> _visibility(MockAccount account, Map<String, Object?> s) => <String>[
        if (s['status'] != 'published') 'not_published',
        if (account.blockedMessage != null) 'provider_blocked',
        if (account.verificationStatus != VerificationStatus.verified)
          'provider_not_verified',
        if (!_hasOpenWilaya(s)) 'no_open_wilaya',
      ];

  // --------------------------------------------------------- pack rules

  void _validatePack(
    Map<String, Object?> catalog,
    Map<String, Object?> json, {
    required bool creating,
  }) {
    final List<FieldError> errors = <FieldError>[];
    void error(String field, String code, String message) =>
        errors.add(FieldError(field: field, code: code, message: message));

    if (creating) {
      for (final String field in <String>['nameEn', 'eventType', 'wilayaCode', 'price', 'serviceIds']) {
        if (json[field] == null) error(field, 'IS_DEFINED', '$field should not be empty');
      }
    }
    if (json.containsKey('nameEn') && (json['nameEn'] as String? ?? '').trim().isEmpty) {
      error('nameEn', 'IS_NOT_EMPTY', 'nameEn should not be empty');
    }
    for (final String field in <String>['nameEn', 'nameAr']) {
      if ((json[field] as String? ?? '').length > ProviderPackDetail.maxNameLength) {
        error(field, 'MAX_LENGTH', '$field must be shorter than or equal to 160 characters');
      }
    }
    if (json['price'] case final String price when !_amount.hasMatch(price)) {
      error('price', 'IS_DECIMAL', 'price must be a decimal amount');
    }
    if (json['wilayaCode'] case final int code when code < 1 || code > 58) {
      error('wilayaCode', 'MAX', 'wilayaCode must be between 1 and 58');
    }
    if (json['maxGuests'] case final int guests when guests < 1) {
      error('maxGuests', 'MIN', 'maxGuests must not be less than 1');
    }
    final List<String>? ids = json['serviceIds'] == null ? null : _ids(json['serviceIds']);
    if (ids != null &&
        (ids.length < ProviderPackDetail.minItems ||
            ids.length > ProviderPackDetail.maxItems ||
            ids.toSet().length != ids.length)) {
      error('serviceIds', 'ARRAY_SIZE', 'serviceIds must hold 2 to 6 different services');
    }
    if (errors.isNotEmpty) {
      throw ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: errors,
      );
    }
    if (json['wilayaCode'] case final int code) _checkWilayas(<int>[code]);
    if (ids != null) {
      final Set<String> mine = <String>{
        for (final Map<String, Object?> s in _servicesOf(catalog)) s['id']! as String,
      };
      for (final String id in ids) {
        if (mine.contains(id)) continue;
        final bool elsewhere =
            mockCatalogServices.any((Map<String, Object?> s) => s['id'] == id);
        throw elsewhere
            ? _failure(
                422,
                ApiErrorCode.packServiceOtherProvider,
                'Every service of a pack must belong to the pack’s provider.',
              )
            : _failure(
                422,
                ApiErrorCode.packServiceNotFound,
                'Some services of the pack were not found.',
              );
      }
    }
  }

  void _applyPack(Map<String, Object?> record, Map<String, Object?> json) {
    for (final String field in <String>[
      'nameEn',
      'nameAr',
      'descriptionEn',
      'descriptionAr',
      'eventType',
      'wilayaCode',
      'maxGuests',
    ]) {
      if (json.containsKey(field)) record[field] = json[field];
    }
    if (json['price'] case final String price) record['price'] = _twoDecimals(price);
    if (json['serviceIds'] case final List<Object?> ids) {
      record['serviceIds'] = <Object?>[...ids.whereType<String>()];
    }
  }

  /// The pack's items that still exist, in order.
  List<Map<String, Object?>> _items(Map<String, Object?> catalog, Map<String, Object?> pack) {
    final List<Map<String, Object?>> services = _servicesOf(catalog);
    return <Map<String, Object?>>[
      for (final String id in _ids(pack['serviceIds']))
        for (final Map<String, Object?> s in services)
          if (s['id'] == id) s,
    ];
  }

  int _sumCents(List<Map<String, Object?>> items) => items.fold(
        0,
        (int sum, Map<String, Object?> s) => sum + amountCents(s['basePrice']! as String),
      );

  List<String> _packMissing(
    MockAccount account,
    Map<String, Object?> catalog,
    Map<String, Object?> pack,
  ) {
    final List<Map<String, Object?>> items = _items(catalog, pack);
    final int wilaya = (pack['wilayaCode'] as num).toInt();
    return <String>[
      if ((pack['nameEn'] as String? ?? '').trim().isEmpty) 'nameEn',
      if ((pack['nameAr'] as String? ?? '').trim().isEmpty) 'nameAr',
      if (items.length < ProviderPackDetail.minItems) 'items',
      if (items.any((Map<String, Object?> s) => s['status'] != 'published'))
        'unpublishedItems',
      if (account.blockedMessage != null) 'providerBlocked',
      if (account.verificationStatus != VerificationStatus.verified)
        'providerNotVerified',
      if (amountCents(pack['price']! as String) >= _sumCents(items)) 'priceNotBelowSum',
      if (items.any((Map<String, Object?> s) => !_codes(s['wilayaCodes']).contains(wilaya)))
        'wilayaNotCovered',
    ];
  }

  List<Map<String, Object?>> _attention(
    MockAccount account,
    Map<String, Object?> catalog,
    Map<String, Object?> pack,
  ) {
    if (pack['status'] != 'published') return <Map<String, Object?>>[];
    final List<String> ids = _ids(pack['serviceIds']);
    final List<Map<String, Object?>> items = _items(catalog, pack);
    return <Map<String, Object?>>[
      for (final String id in ids)
        if (!items.any((Map<String, Object?> s) => s['id'] == id))
          <String, Object?>{'code': 'item_deleted', 'serviceId': id},
      for (final Map<String, Object?> s in items)
        if (s['status'] != 'published')
          <String, Object?>{'code': 'item_not_published', 'serviceId': s['id']},
      if (account.blockedMessage != null)
        <String, Object?>{'code': 'provider_blocked', 'serviceId': null},
      if (account.verificationStatus != VerificationStatus.verified)
        <String, Object?>{'code': 'provider_not_verified', 'serviceId': null},
    ];
  }

  // ------------------------------------------------------------ render

  Map<String, Object?> _serviceRow(MockAccount account, Map<String, Object?> s) {
    final List<Object?> photos = s['photos']! as List<Object?>;
    return <String, Object?>{
      'id': s['id'],
      'title': _isArabic && (s['titleAr'] as String? ?? '').isNotEmpty ? s['titleAr'] : s['titleEn'],
      'titleEn': s['titleEn'],
      'titleAr': s['titleAr'],
      'status': s['status'],
      'visibleInApp': _visibility(account, s).isEmpty,
      'basePrice': s['basePrice'],
      'priceType': s['priceType'],
      'avgRating': s['avgRating'],
      'ratingCount': s['ratingCount'],
      'bookingsCount': s['bookingsCount'],
      'photosCount': photos.length,
      'coverUrl': photos.isEmpty ? null : _photosJson(photos).first['thumbUrl'],
      'wilayas': <Map<String, Object?>>[
        for (final int code in _codes(s['wilayaCodes'])) ?_wilayaJson(code),
      ],
    };
  }

  ProviderServiceDetail _serviceDetail(MockAccount account, Map<String, Object?> s) {
    final List<Object?> photos = s['photos']! as List<Object?>;
    final Map<String, Object?> catalog = _catalogOf(account);
    final List<Map<String, Object?>> packs = <Map<String, Object?>>[
      for (final Map<String, Object?> p in _packsOf(catalog))
        if (_ids(p['serviceIds']).contains(s['id'])) p,
    ];
    final List<Map<String, Object?>> photoJson = _photosJson(photos);
    return ProviderServiceDetail.fromJson(<String, Object?>{
      'id': s['id'],
      'titleEn': s['titleEn'],
      'titleAr': s['titleAr'],
      'coverUrl': photoJson.isEmpty ? null : photoJson.first['thumbUrl'],
      'category': _category(s['categoryId'] as String?),
      'basePrice': s['basePrice'],
      'priceType': s['priceType'],
      'rating': double.tryParse(s['avgRating'] as String? ?? '0') ?? 0,
      'ratingCount': s['ratingCount'],
      'bookingsCount': s['bookingsCount'],
      'status': s['status'],
      'visibleInApp': _visibility(account, s).isEmpty,
      'wilayas': <Map<String, Object?>>[
        for (final int code in _codes(s['wilayaCodes'])) ?_wilayaJson(code),
      ],
      'descriptionEn': s['descriptionEn'],
      'descriptionAr': s['descriptionAr'],
      'cancellationPolicyEn': s['cancellationPolicyEn'],
      'cancellationPolicyAr': s['cancellationPolicyAr'],
      'facts': s['facts'],
      'maxEventsPerDay': s['maxEventsPerDay'],
      'maxGuests': s['maxGuests'],
      'extras': <Map<String, Object?>>[
        for (final (int i, Object? e) in (s['extras']! as List<Object?>).indexed)
          <String, Object?>{...(e! as Map<String, Object?>), 'position': i},
      ],
      'photos': photoJson,
      'wilayaDetails': <Map<String, Object?>>[
        for (final int code in _codes(s['wilayaCodes']))
          if (_wilayaJson(code) case final Map<String, Object?> w)
            <String, Object?>{...w, 'isOpen': !closedWilayas.contains(code)},
      ],
      'hidden': s['status'] == 'hidden' ? s['hidden'] : null,
      'visibilityReasons': _visibility(account, s),
      'publishMissing': _serviceMissing(s),
      'stats': <String, Object?>{
        'packsCount': packs.length,
        'packs': <Map<String, Object?>>[
          for (final Map<String, Object?> p in packs)
            <String, Object?>{
              'id': p['id'],
              'nameEn': p['nameEn'],
              'nameAr': p['nameAr'],
              'status': p['status'],
              'needsAttention': _attention(account, catalog, p).isNotEmpty,
            },
        ],
      },
    });
  }

  Map<String, Object?> _packJson(
    MockAccount account,
    Map<String, Object?> catalog,
    Map<String, Object?> p,
  ) {
    final List<Map<String, Object?>> items = _items(catalog, p);
    final int sum = _sumCents(items);
    final int price = amountCents(p['price']! as String);
    final List<Map<String, Object?>> attention = _attention(account, catalog, p);
    final List<Map<String, Object?>> photos = _photosJson(p['photos']! as List<Object?>);
    final int wilaya = (p['wilayaCode'] as num).toInt();
    String money(int cents) =>
        '${cents < 0 ? '-' : ''}${cents.abs() ~/ 100}.${(cents.abs() % 100).toString().padLeft(2, '0')}';
    return <String, Object?>{
      'id': p['id'],
      'nameEn': p['nameEn'],
      'nameAr': p['nameAr'],
      'coverUrl': photos.isEmpty ? null : photos.first['thumbUrl'],
      'provider': <String, Object?>{
        'id': account.id,
        'fullName': account.fullName,
        'businessName': account.businessName,
        'status': account.blockedMessage == null ? 'active' : 'blocked',
        'verificationStatus': account.verificationStatus.apiValue,
      },
      'itemsCount': items.length,
      'itemsSummary': <Map<String, Object?>>[
        for (final Map<String, Object?> s in items)
          if (_category(s['categoryId'] as String?) case final Map<String, Object?> c)
            <String, Object?>{'nameEn': c['nameEn'], 'nameAr': c['nameAr']},
      ],
      'price': p['price'],
      'sumOfItems': money(sum),
      'savings': money(sum - price),
      'savingsPercent': sum == 0 ? 0 : ((sum - price) * 1000 ~/ sum) / 10,
      'eventType': p['eventType'],
      'wilaya': _wilayaJson(wilaya) ?? <String, Object?>{'code': wilaya},
      'rating': double.tryParse(p['avgRating'] as String? ?? '0') ?? 0,
      'ratingCount': p['ratingCount'],
      'bookingsCount': p['bookingsCount'],
      'status': p['status'],
      'needsAttention': attention.isNotEmpty,
      'attentionReasons': attention,
      'visibleInApp': p['status'] == 'published' &&
          attention.isEmpty &&
          !closedWilayas.contains(wilaya),
      'createdAt': p['createdAt'],
      'updatedAt': p['updatedAt'],
      'descriptionEn': p['descriptionEn'],
      'descriptionAr': p['descriptionAr'],
      'maxGuests': p['maxGuests'],
      'items': <Map<String, Object?>>[
        for (final (int i, Map<String, Object?> s) in items.indexed)
          <String, Object?>{
            'position': i,
            'price': s['basePrice'],
            'availability': switch (s['status']) {
              'published' => 'available',
              'hidden' => 'hidden',
              _ => 'not_published',
            },
            'service': <String, Object?>{
              'id': s['id'],
              'titleEn': s['titleEn'],
              'titleAr': s['titleAr'],
              'coverUrl': (s['photos']! as List<Object?>).isEmpty
                  ? null
                  : _photosJson(s['photos']! as List<Object?>).first['thumbUrl'],
              'category': _category(s['categoryId'] as String?),
              'status': s['status'],
              'priceType': s['priceType'],
              'rating': double.tryParse(s['avgRating'] as String? ?? '0') ?? 0,
            },
          },
      ],
      'photos': photos,
      'publishMissing': _packMissing(account, catalog, p),
      'stats': <String, Object?>{
        'total': items.length,
        'published':
            items.where((Map<String, Object?> s) => s['status'] == 'published').length,
      },
      'createdBy': null,
    };
  }

  Map<String, Object?>? _category(String? id) {
    if (id == null) return null;
    for (final Map<String, Object?> c in mockCatalogCategories) {
      if (c['id'] == id) {
        return <String, Object?>{
          'id': c['id'],
          'slug': c['slug'],
          'name': _isArabic ? c['nameAr'] : c['nameEn'],
          'nameEn': c['nameEn'],
          'nameAr': c['nameAr'],
          'icon': c['icon'],
        };
      }
    }
    return null;
  }

  String _slugOf(String? categoryId) {
    final String? slug = _category(categoryId)?['slug'] as String?;
    return slug != null && _photoSets.containsKey(slug) ? slug : 'salles-des-fetes';
  }

  static Wilaya? _wilaya(int code) {
    for (final Wilaya w in mockWilayas) {
      if (w.code == code) return w;
    }
    return null;
  }

  Map<String, Object?>? _wilayaJson(int code) {
    final Wilaya? w = _wilaya(code);
    if (w == null) return null;
    return <String, Object?>{
      'code': w.code,
      'name': w.nameFor(_languageCode()),
      'nameEn': w.nameEn,
      'nameAr': w.nameAr,
    };
  }

  // ------------------------------------------------------------- store

  Map<String, Object?> _catalogOf(MockAccount account) {
    final Map<String, Object?> store =
        _backend.store(storeName, () => <String, Object?>{});
    final Object? existing = store[account.email];
    if (existing is Map<String, Object?>) return existing;
    final Map<String, Object?> seeded = account.email == seededEmail
        ? _seed()
        : <String, Object?>{
            'services': <Object?>[],
            'packs': <Object?>[],
            'seq': 0,
          };
    store[account.email] = seeded;
    return seeded;
  }

  static List<Map<String, Object?>> _servicesOf(Map<String, Object?> catalog) =>
      (catalog['services']! as List<Object?>).whereType<Map<String, Object?>>().toList();

  static List<Map<String, Object?>> _packsOf(Map<String, Object?> catalog) =>
      (catalog['packs']! as List<Object?>).whereType<Map<String, Object?>>().toList();

  Map<String, Object?> _service(MockAccount account, String id) {
    for (final Map<String, Object?> s in _servicesOf(_catalogOf(account))) {
      if (s['id'] == id) return s;
    }
    // Another provider's service is NOT_OWNER on the live API.
    for (final Map<String, Object?> s in mockCatalogServices) {
      if (s['id'] == id) {
        throw _failure(403, ApiErrorCode.notOwner, 'You do not own this item.');
      }
    }
    throw _failure(404, ApiErrorCode.serviceNotFound, 'The service was not found.');
  }

  Map<String, Object?> _pack(Map<String, Object?> catalog, String id) {
    for (final Map<String, Object?> p in _packsOf(catalog)) {
      if (p['id'] == id) return p;
    }
    throw _failure(404, ApiErrorCode.packNotFound, 'The pack was not found.');
  }

  static int _nextId(Map<String, Object?> catalog) {
    final int next = (catalog['seq'] as num? ?? 0).toInt() + 1;
    catalog['seq'] = next;
    return next;
  }

  static List<String> _ids(Object? value) =>
      value is List<Object?> ? value.whereType<String>().toList() : <String>[];

  static List<int> _codes(Object? value) => value is List<Object?>
      ? <int>[for (final num code in value.whereType<num>()) code.toInt()]
      : <int>[];

  static String _twoDecimals(String amount) {
    final int cents = amountCents(amount);
    return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  }

  ApiFailure _notVerified() => _failure(
        422,
        ApiErrorCode.providerNotVerified,
        'Your profile is still being reviewed. You can publish and accept bookings once it is approved.',
      );

  static ApiFailure _failure(
    int status,
    String code,
    String message, {
    Map<String, Object?>? details,
  }) =>
      ApiFailure(statusCode: status, code: code, message: message, details: details);

  // -------------------------------------------------------------- seed

  /// `verified.provider@`'s catalog: the const catalog's services and pack
  /// for Salle Yasmine, plus one card of every other state P6 draws.
  Map<String, Object?> _seed() {
    final DateTime now = _backend.now;
    String ago(int days) => now.subtract(Duration(days: days)).toUtc().toIso8601String();
    List<Object?> photos(String owner, List<String> files) => <Object?>[
          for (final (int i, String file) in files.indexed)
            <String, Object?>{
              'id': '$owner-photo-${i + 1}',
              'file': file,
              'readyAt': 0,
              'createdAt': ago(30),
            },
        ];

    final List<Object?> services = <Object?>[
      <String, Object?>{
        'id': 'mock-service-garden-terrace',
        'titleEn': 'Garden terrace · 80 guests',
        'titleAr': 'تراس الحديقة · 80 ضيفًا',
        'descriptionEn':
            'An open-air terrace for engagements and small receptions, with lighting and seating for 80.',
        'descriptionAr': 'تراس في الهواء الطلق للخطوبة والحفلات الصغيرة، مع الإضاءة والمقاعد لثمانين ضيفًا.',
        'cancellationPolicyEn': null,
        'cancellationPolicyAr': null,
        'categoryId': 'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6',
        'basePrice': '180000.00',
        'priceType': 'per_event',
        'status': 'hidden',
        'facts': <Object?>[],
        'extras': <Object?>[],
        'wilayaCodes': <Object?>[16],
        'maxEventsPerDay': 1,
        'maxGuests': 80,
        'photos': photos('mock-service-garden-terrace', <String>[
          'pexels-salles-des-fetes-6.webp',
          'pexels-fleurs-2.webp',
        ]),
        'hidden': <String, Object?>{
          'reason': 'misleading_content',
          'message': 'The photos show a different venue. Replace them with photos of this terrace.',
          'allowResubmit': true,
          'hiddenBy': null,
          'hiddenAt': ago(10),
        },
        'avgRating': '4.90',
        'ratingCount': 7,
        'bookingsCount': 3,
        'createdAt': ago(90),
        'updatedAt': ago(10),
      },
      <String, Object?>{
        'id': 'mock-service-henna-decor',
        'titleEn': 'Henna night décor',
        'titleAr': '',
        'descriptionEn':
            'A traditional henna-night setting — low seating, brass trays, candles and draped fabrics, set up and cleared by our team.',
        'descriptionAr': '',
        'cancellationPolicyEn': 'Free cancellation up to 14 days before the event.',
        'cancellationPolicyAr': null,
        'categoryId': '9ec8cbe5-ead7-42b4-99d1-fccc49fdad50',
        'basePrice': '34000.00',
        'priceType': 'per_event',
        'status': 'draft',
        'facts': <Object?>[
          <String, Object?>{
            'label_en': 'Set-up',
            'label_ar': 'التركيب',
            'value_en': '3 hours before',
            'value_ar': 'قبل 3 ساعات',
          },
        ],
        'extras': <Object?>[],
        'wilayaCodes': <Object?>[16],
        'maxEventsPerDay': 1,
        'maxGuests': null,
        'photos': photos('mock-service-henna-decor', <String>[
          'pexels-decoration-4.webp',
          'pexels-fleurs-1.webp',
        ]),
        'hidden': null,
        'avgRating': '0.00',
        'ratingCount': 0,
        'bookingsCount': 0,
        'createdAt': ago(3),
        'updatedAt': ago(1),
      },
      <String, Object?>{
        'id': 'mock-service-reception-tent',
        'titleEn': 'Reception tent · Kabylie',
        'titleAr': 'خيمة استقبال · القبائل',
        'descriptionEn':
            'A furnished reception tent for 250 guests, set up on your land and taken down the day after.',
        'descriptionAr': 'خيمة استقبال مجهزة لـ250 ضيفًا، تُنصب في أرضك وتُفكّ في اليوم التالي.',
        'cancellationPolicyEn': null,
        'cancellationPolicyAr': null,
        'categoryId': 'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6',
        'basePrice': '150000.00',
        'priceType': 'per_day',
        'status': 'published',
        'facts': <Object?>[],
        'extras': <Object?>[],
        'wilayaCodes': <Object?>[15],
        'maxEventsPerDay': 1,
        'maxGuests': 250,
        'photos': photos('mock-service-reception-tent', <String>[
          'pexels-salles-des-fetes-4.webp',
        ]),
        'hidden': null,
        'avgRating': '4.90',
        'ratingCount': 7,
        'bookingsCount': 3,
        'createdAt': ago(120),
        'updatedAt': ago(20),
      },
      for (final Map<String, Object?> s in mockCatalogServices)
        if (s['providerId'] == catalogProviderId)
          <String, Object?>{
            'id': s['id'],
            'titleEn': s['titleEn'],
            'titleAr': s['titleAr'],
            'descriptionEn': s['descriptionEn'],
            'descriptionAr': s['descriptionAr'],
            'cancellationPolicyEn': s['cancellationEn'],
            'cancellationPolicyAr': s['cancellationAr'],
            'categoryId': s['categoryId'],
            'basePrice': s['basePrice'],
            'priceType': s['priceType'],
            'status': 'published',
            'facts': <Object?>[
              for (final Map<String, Object?> f
                  in (s['facts'] as List<Object?>? ?? <Object?>[]).whereType<Map<String, Object?>>())
                <String, Object?>{
                  'label_en': f['labelEn'],
                  'label_ar': f['labelAr'],
                  'value_en': f['valueEn'],
                  'value_ar': f['valueAr'],
                },
            ],
            'extras': <Object?>[
              for (final Map<String, Object?> e
                  in (s['extras'] as List<Object?>? ?? <Object?>[]).whereType<Map<String, Object?>>())
                Map<String, Object?>.of(e),
            ],
            'wilayaCodes': <Object?>[...(s['wilayas']! as List<Object?>)],
            'maxEventsPerDay': s['maxEventsPerDay'] ?? 1,
            'maxGuests': s['maxGuests'],
            'photos': photos(
              s['id']! as String,
              (s['photos']! as List<Object?>).cast<String>(),
            ),
            'hidden': null,
            'avgRating': s['avgRating'],
            'ratingCount': s['ratingCount'],
            'bookingsCount': s['bookingsCount'],
            'createdAt': ago(200),
            'updatedAt': ago(40),
          },
    ];

    final List<Object?> packs = <Object?>[
      <String, Object?>{
        'id': 'mock-pack-decor-menu',
        'nameEn': 'Décor & Menu',
        'nameAr': '',
        'descriptionEn': 'Floral décor and the traditional menu, booked together.',
        'descriptionAr': null,
        'eventType': 'engagement',
        'wilayaCode': 16,
        'price': '70000.00',
        'maxGuests': 200,
        'serviceIds': <Object?>[
          'b15c4ecc-6ada-4da7-85b2-684aeefaa4fa',
          '6252a3b3-cd93-4126-ad2a-2010a598aaa8',
        ],
        'photos': <Object?>[],
        'status': 'draft',
        'avgRating': '0.00',
        'ratingCount': 0,
        'bookingsCount': 0,
        'createdAt': ago(2),
        'updatedAt': ago(2),
      },
      for (final Map<String, Object?> p in mockCatalogPacks)
        if (p['providerId'] == catalogProviderId)
          <String, Object?>{
            'id': p['id'],
            'nameEn': p['nameEn'],
            'nameAr': p['nameAr'],
            'descriptionEn': p['descriptionEn'],
            'descriptionAr': p['descriptionAr'],
            'eventType': p['eventType'],
            'wilayaCode': p['wilayaCode'],
            'price': p['price'],
            'maxGuests': p['maxGuests'],
            'serviceIds': <Object?>[...(p['items']! as List<Object?>)],
            'photos': photos(p['id']! as String, (p['photos']! as List<Object?>).cast<String>()),
            'status': 'published',
            'avgRating': p['avgRating'],
            'ratingCount': p['ratingCount'],
            'bookingsCount': p['bookingsCount'],
            'createdAt': ago(150),
            'updatedAt': ago(30),
          },
    ];

    return <String, Object?>{'services': services, 'packs': packs, 'seq': 0};
  }
}
