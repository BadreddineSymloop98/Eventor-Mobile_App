import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/models/json_read.dart';
import '../../../core/catalog/models/pack.dart' show EventType;
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/reference/reference_repository.dart';
import 'catalog_outcomes.dart';
import 'provider_services_view_model.dart' show packRefusal;
import 'service_form_view_model.dart' show FieldProblem;

export 'service_form_view_model.dart' show FieldProblem;

/// The fields of P11 / P12.
enum PackField {
  nameEn,
  nameAr,
  descriptionEn,
  descriptionAr,
  services,
  price,
  eventType,
  wilaya,
  maxGuests,
}

enum PackFormAction { save, publish, unpublish, delete, photos }

/// One row of "Services in this pack".
class PackFormItem {
  const PackFormItem({
    required this.serviceId,
    required this.title,
    required this.price,
    required this.status,
    required this.coversWilaya,
  });

  final String serviceId;
  final LocalizedText title;

  /// The service's base price, as the pack counts it.
  final String price;
  final ProviderServiceStatus status;

  /// Whether it covers the pack's wilaya — `true` while none is picked.
  final bool coversWilaya;

  bool get isPublished => status == ProviderServiceStatus.published;
}

sealed class PackSaveOutcome {
  const PackSaveOutcome();
}

final class PackSaveDone extends PackSaveOutcome {
  const PackSaveDone({required this.created});

  final bool created;
}

final class PackSaveInvalid extends PackSaveOutcome {
  const PackSaveInvalid(this.fields);

  final List<PackField> fields;
}

final class PackSaveFailed extends PackSaveOutcome {
  const PackSaveFailed(this.failure);

  final Failure failure;
}

/// Whether P13 can open for this pack — a new one is saved first.
sealed class PackPhotosAccess {
  const PackPhotosAccess();
}

final class PackPhotosReady extends PackPhotosAccess {
  const PackPhotosReady(this.packId);

  final String packId;
}

final class PackPhotosNeedDraft extends PackPhotosAccess {
  const PackPhotosNeedDraft(this.fields);

  final List<PackField> fields;
}

final class PackPhotosFailed extends PackPhotosAccess {
  const PackPhotosFailed(this.failure);

  final Failure failure;
}

/// P11 Create pack and P12 Edit pack.
///
/// A pack is 2–6 of the provider's own services, in one wilaya they all
/// cover, at one price below what they cost one by one. The sum and the
/// saving are worked out here, live, from the services' base prices — the
/// same figure the server computes — so the price field can say at once
/// whether it is low enough. Everything else the checklist (P14) asks for
/// comes from the server's `publishMissing`.
class PackFormViewModel extends BaseViewModel {
  PackFormViewModel({
    required this._catalog,
    required this._reference,
    this._packId,
    PackChecklistItem? fix,
  }) : _pendingFix = fix {
    load();
  }

  final ProviderCatalogRepository _catalog;
  final ReferenceRepository _reference;
  final String? _packId;
  PackChecklistItem? _pendingFix;

  static const int maxNameLength = ProviderPackDetail.maxNameLength;
  static const int maxDescriptionLength = ProviderPackDetail.maxDescriptionLength;
  static const int minItems = ProviderPackDetail.minItems;
  static const int maxItems = ProviderPackDetail.maxItems;
  static const int maxGuestsLimit = 100000;

  List<ProviderServiceSummary>? _services;
  ProviderPackDetail? _saved;
  bool _isGone = false;
  PackFormAction? _action;

  ContentLanguage _language = ContentLanguage.english;
  String _nameEn = '';
  String _nameAr = '';
  String _descriptionEn = '';
  String _descriptionAr = '';
  List<String> _serviceIds = <String>[];
  int? _price;
  EventType? _eventType;
  Wilaya? _wilaya;
  int? _maxGuests;

  final Map<PackField, FieldProblem> _problems = <PackField, FieldProblem>{};
  final Map<PackField, String> _serverErrors = <PackField, String>{};
  List<Wilaya>? _openWilayas;
  bool _isLoadingWilayas = false;

  ProviderPackDetail? get saved => _saved;
  bool get isNew => _saved == null;
  bool get isEditing => _packId != null || _saved != null;

  /// Waiting for the services (and, on P12, the pack) — the skeleton.
  bool get isFirstLoad => (_services == null || (_packId != null && _saved == null)) &&
      !hasError &&
      !_isGone;
  bool get loadFailed => !isFirstLoad && (_services == null || (_packId != null && _saved == null));
  bool get isGone => _isGone;

  PackFormAction? get action => _action;
  bool get isWorking => _action != null;
  ContentLanguage get language => _language;
  String get nameEn => _nameEn;
  String get nameAr => _nameAr;
  String get name => _language == ContentLanguage.arabic ? _nameAr : _nameEn;
  String get description =>
      _language == ContentLanguage.arabic ? _descriptionAr : _descriptionEn;
  List<String> get serviceIds => List<String>.unmodifiable(_serviceIds);
  int? get price => _price;
  EventType? get eventType => _eventType;
  Wilaya? get wilaya => _wilaya;
  int? get maxGuests => _maxGuests;
  int get photosCount => _saved?.photos.length ?? 0;
  bool get isLoadingWilayas => _isLoadingWilayas;

  bool get isPublished => _saved?.isPublished ?? false;

  /// Live, so an edit shows to clients straight away.
  bool get isLive => (_saved?.isPublished ?? false) && (_saved?.visibleInApp ?? false);

  FieldProblem? problemOf(PackField field) => _problems[field];
  String? serverErrorOf(PackField field) => _serverErrors[field];

  PackChecklistItem? takeFix() {
    final PackChecklistItem? fix = _pendingFix;
    _pendingFix = null;
    return fix;
  }

  /// The names the languages still lack — the helper under the control.
  List<PackMissing> get nameGaps => <PackMissing>[
        if (_nameEn.trim().isEmpty) PackMissing.nameEn,
        if (_nameAr.trim().isEmpty) PackMissing.nameAr,
      ];

  /// "Services in this pack", in order.
  List<PackFormItem> get items {
    final List<ProviderServiceSummary> services = _services ?? const <ProviderServiceSummary>[];
    final List<ProviderPackItem> savedItems = _saved?.items ?? const <ProviderPackItem>[];
    final int? code = _wilaya?.code;
    return <PackFormItem>[
      for (final String id in _serviceIds)
        if (_find(services, id) case final ProviderServiceSummary s)
          PackFormItem(
            serviceId: s.id,
            title: s.title,
            price: s.basePrice,
            status: s.status,
            coversWilaya: code == null || s.covers(code),
          )
        else
          for (final ProviderPackItem item in savedItems)
            if (item.serviceId == id)
              PackFormItem(
                serviceId: id,
                title: item.title,
                price: item.price,
                status: item.status,
                coversWilaya: true,
              ),
    ];
  }

  static ProviderServiceSummary? _find(List<ProviderServiceSummary> services, String id) {
    for (final ProviderServiceSummary s in services) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// What the items cost one by one, in centimes.
  int get sumCents =>
      items.fold(0, (int sum, PackFormItem item) => sum + amountCents(item.price));

  /// The client's saving at the typed price; `null` without a price or items.
  int? get savingsCents {
    final int? price = _price;
    if (price == null || _serviceIds.isEmpty) return null;
    return sumCents - price * 100;
  }

  /// "12%" off booking them separately, rounded.
  int? get savingsPercent {
    final int? savings = savingsCents;
    final int sum = sumCents;
    if (savings == null || sum <= 0 || savings <= 0) return null;
    return (savings * 100 / sum).round();
  }

  /// The price rule of P11: below the sum. `null` until both are known.
  bool? get isPriceBelowSum {
    final int? savings = savingsCents;
    if (savings == null || sumCents <= 0) return null;
    return savings > 0;
  }

  bool get isDirty {
    final ProviderPackDetail? saved = _saved;
    if (saved == null) {
      return _nameEn.trim().isNotEmpty ||
          _nameAr.trim().isNotEmpty ||
          _descriptionEn.trim().isNotEmpty ||
          _descriptionAr.trim().isNotEmpty ||
          _serviceIds.isNotEmpty ||
          _price != null ||
          _eventType != null ||
          _wilaya != null ||
          _maxGuests != null;
    }
    return !_changes(saved).isEmpty;
  }

  Future<void> load() async {
    _isGone = false;
    notifyListeners();
    final String? id = _packId;
    final bool? loaded = await runGuarded(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _catalog.services(),
        if (id != null) _catalog.pack(id),
      ]);
      _services = results[0] as List<ProviderServiceSummary>;
      if (id != null && _saved == null) _fill(results[1] as ProviderPackDetail);
      return true;
    });
    if (loaded == null) {
      final Failure? problem = failure;
      _isGone = problem is ApiFailure &&
          (problem.code == ApiErrorCode.packNotFound || problem.code == ApiErrorCode.notOwner);
    }
    notifyListeners();
  }

  void _fill(ProviderPackDetail detail) {
    _saved = detail;
    _nameEn = detail.name.en;
    _nameAr = detail.name.ar;
    _descriptionEn = detail.descriptionEn;
    _descriptionAr = detail.descriptionAr;
    _serviceIds = List<String>.of(detail.serviceIds);
    _price = amountCents(detail.price) ~/ 100;
    _eventType = detail.eventType;
    _wilaya = detail.wilaya.code == 0 ? null : detail.wilaya;
    _maxGuests = detail.maxGuests;
  }

  // ------------------------------------------------------------ editing

  void setLanguage(ContentLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void setName(String value) {
    if (_language == ContentLanguage.arabic) {
      _nameAr = value;
      _clear(PackField.nameAr);
    } else {
      _nameEn = value;
      _clear(PackField.nameEn);
    }
  }

  void setDescription(String value) {
    if (_language == ContentLanguage.arabic) {
      _descriptionAr = value;
      _clear(PackField.descriptionAr);
    } else {
      _descriptionEn = value;
      _clear(PackField.descriptionEn);
    }
  }

  /// P11a's answer, in order.
  void setServices(List<String> ids) {
    _serviceIds = List<String>.of(ids);
    _clear(PackField.services);
  }

  void setPrice(int? dinars) {
    _price = dinars;
    _clear(PackField.price);
  }

  void setEventType(EventType type) {
    _eventType = type;
    _clear(PackField.eventType);
  }

  void setWilaya(Wilaya wilaya) {
    _wilaya = wilaya;
    _clear(PackField.wilaya);
  }

  void setMaxGuests(int? value) {
    _maxGuests = value;
    _clear(PackField.maxGuests);
  }

  void _clear(PackField field) {
    _problems.remove(field);
    _serverErrors.remove(field);
    notifyListeners();
  }

  /// The open wilayas, loaded once.
  Future<List<Wilaya>> openWilayas() async {
    final List<Wilaya>? loaded = _openWilayas;
    if (loaded != null) return loaded;
    _isLoadingWilayas = true;
    notifyListeners();
    try {
      return _openWilayas = await _reference.wilayas();
    } finally {
      _isLoadingWilayas = false;
      notifyListeners();
    }
  }

  /// How many of the provider's services cover [wilaya] — the wilaya
  /// picker's hint.
  int servicesCovering(Wilaya wilaya) => (_services ?? const <ProviderServiceSummary>[])
      .where((ProviderServiceSummary s) => s.isPublished && s.covers(wilaya.code))
      .length;

  // ------------------------------------------------------------ saving

  List<PackField> _validate() {
    _problems.clear();
    if (_nameEn.trim().isEmpty) _problems[PackField.nameEn] = FieldProblem.required;
    if (_eventType == null) _problems[PackField.eventType] = FieldProblem.required;
    if (_wilaya == null) _problems[PackField.wilaya] = FieldProblem.required;
    if (_price == null) _problems[PackField.price] = FieldProblem.required;
    if (_serviceIds.length < minItems || _serviceIds.length > maxItems) {
      _problems[PackField.services] =
          _serviceIds.isEmpty ? FieldProblem.required : FieldProblem.outOfRange;
    }
    final int? guests = _maxGuests;
    if (guests != null && (guests < 1 || guests > maxGuestsLimit)) {
      _problems[PackField.maxGuests] = FieldProblem.outOfRange;
    }
    return <PackField>[
      for (final PackField field in PackField.values)
        if (_problems.containsKey(field)) field,
    ];
  }

  Future<PackSaveOutcome?> save() async {
    if (_action != null) return null;
    _action = PackFormAction.save;
    notifyListeners();
    final PackSaveOutcome outcome = await _save();
    _action = null;
    notifyListeners();
    return outcome;
  }

  Future<PackSaveOutcome> _save() async {
    final List<PackField> invalid = _validate();
    if (invalid.isNotEmpty) return PackSaveInvalid(invalid);
    final ProviderPackDetail? saved = _saved;
    try {
      if (saved == null) {
        _saved = await _catalog.createPack(_fullInput());
        return const PackSaveDone(created: true);
      }
      final PackInput changes = _changes(saved);
      if (!changes.isEmpty) _saved = await _catalog.updatePack(saved.id, changes);
      return const PackSaveDone(created: false);
    } on Failure catch (failure) {
      _takeFieldErrors(failure);
      return PackSaveFailed(failure);
    } catch (error) {
      return PackSaveFailed(UnexpectedFailure(cause: error));
    }
  }

  Future<PublishOutcome<PackMissing>?> publish() async {
    if (_action != null) return null;
    _action = PackFormAction.publish;
    notifyListeners();
    final PublishOutcome<PackMissing> outcome = await _publish();
    _action = null;
    notifyListeners();
    return outcome;
  }

  Future<PublishOutcome<PackMissing>> _publish() async {
    switch (await _save()) {
      case PackSaveInvalid():
        return const PublishInvalid<PackMissing>();
      case PackSaveFailed(:final Failure failure):
        return PublishFailed<PackMissing>(failure);
      case PackSaveDone():
        break;
    }
    final ProviderPackDetail saved = _saved!;
    final List<PackMissing> content = saved.publishMissing
        .where((PackMissing m) =>
            m != PackMissing.providerNotVerified && m != PackMissing.providerBlocked)
        .toList();
    if (content.isNotEmpty) return PublishChecklist<PackMissing>(saved.publishMissing);
    try {
      _saved = await _catalog.publishPack(saved.id);
      return const PublishDone<PackMissing>();
    } on ApiFailure catch (failure) {
      return packRefusal(_catalog, saved.id, failure);
    } on Failure catch (failure) {
      return PublishFailed<PackMissing>(failure);
    }
  }

  Future<Failure?> unpublish() async {
    final ProviderPackDetail? saved = _saved;
    if (saved == null || _action != null) return null;
    _action = PackFormAction.unpublish;
    notifyListeners();
    Failure? failure;
    try {
      // What was typed stays on screen, unsaved, against the new status.
      _saved = await _catalog.unpublishPack(saved.id);
    } on Failure catch (error) {
      failure = error;
    }
    _action = null;
    notifyListeners();
    return failure;
  }

  Future<DeleteOutcome?> delete() async {
    final ProviderPackDetail? saved = _saved;
    if (saved == null || _action != null) return null;
    _action = PackFormAction.delete;
    notifyListeners();
    DeleteOutcome outcome;
    try {
      await _catalog.deletePack(saved.id);
      outcome = const DeleteDone();
    } on Failure catch (failure) {
      final DeleteBlocker? blocker = deleteBlockerOf(failure);
      outcome = blocker == null ? DeleteFailed(failure) : DeleteRefused(<DeleteBlocker>[blocker]);
    }
    _action = null;
    notifyListeners();
    return outcome;
  }

  /// P13 needs a saved pack: a new one is saved as a draft first.
  Future<PackPhotosAccess?> openPhotos() async {
    final ProviderPackDetail? saved = _saved;
    if (saved != null) return PackPhotosReady(saved.id);
    if (_action != null) return null;
    _action = PackFormAction.photos;
    notifyListeners();
    final PackSaveOutcome outcome = await _save();
    _action = null;
    notifyListeners();
    return switch (outcome) {
      PackSaveDone() => PackPhotosReady(_saved!.id),
      PackSaveInvalid(:final List<PackField> fields) => PackPhotosNeedDraft(fields),
      PackSaveFailed(:final Failure failure) => PackPhotosFailed(failure),
    };
  }

  Future<void> reloadPhotos() async {
    final ProviderPackDetail? saved = _saved;
    if (saved == null) return;
    try {
      _saved = saved.withPhotosOf(await _catalog.pack(saved.id));
      notifyListeners();
    } catch (_) {
      // The count stays as it was.
    }
  }

  // ------------------------------------------------------------ inputs

  PackInput _fullInput() => PackInput(
        nameEn: _nameEn.trim(),
        nameAr: _nameAr.trim().isEmpty ? null : _nameAr.trim(),
        descriptionEn: _descriptionEn.trim().isEmpty ? null : _descriptionEn.trim(),
        descriptionAr: _descriptionAr.trim().isEmpty ? null : _descriptionAr.trim(),
        eventType: _eventType,
        wilayaCode: _wilaya?.code,
        price: apiAmountOf(_price ?? 0),
        maxGuests: _maxGuests,
        serviceIds: _serviceIds,
      );

  PackInput _changes(ProviderPackDetail saved) {
    String? changed(String typed, String stored) =>
        typed.trim() == stored.trim() ? null : typed.trim();
    final bool guestsChanged = _maxGuests != saved.maxGuests;
    final int? price = _price;
    final bool sameItems = _serviceIds.length == saved.serviceIds.length &&
        <int>[for (int i = 0; i < _serviceIds.length; i++) i]
            .every((int i) => _serviceIds[i] == saved.serviceIds[i]);
    return PackInput(
      nameEn: changed(_nameEn, saved.name.en),
      nameAr: changed(_nameAr, saved.name.ar),
      descriptionEn: changed(_descriptionEn, saved.descriptionEn),
      descriptionAr: changed(_descriptionAr, saved.descriptionAr),
      eventType: _eventType != saved.eventType ? _eventType : null,
      wilayaCode: _wilaya != null && _wilaya!.code != saved.wilaya.code ? _wilaya!.code : null,
      price: price != null && price * 100 != amountCents(saved.price) ? apiAmountOf(price) : null,
      maxGuests: guestsChanged ? _maxGuests : null,
      clearMaxGuests: guestsChanged && _maxGuests == null,
      serviceIds: sameItems ? null : _serviceIds,
    );
  }

  void _takeFieldErrors(Failure failure) {
    if (failure is! ApiFailure) return;
    switch (failure.code) {
      case ApiErrorCode.validationFailed:
        for (final FieldError error in failure.fieldErrors) {
          final PackField? field = switch (error.field.split('.').first) {
            'nameEn' => PackField.nameEn,
            'nameAr' => PackField.nameAr,
            'descriptionEn' => PackField.descriptionEn,
            'descriptionAr' => PackField.descriptionAr,
            'serviceIds' => PackField.services,
            'price' => PackField.price,
            'eventType' => PackField.eventType,
            'wilayaCode' => PackField.wilaya,
            'maxGuests' => PackField.maxGuests,
            _ => null,
          };
          if (field != null) _serverErrors[field] = error.message;
        }
      case ApiErrorCode.wilayaClosed || ApiErrorCode.wilayaNotFound:
        _serverErrors[PackField.wilaya] = failure.message;
      case ApiErrorCode.packServiceNotFound || ApiErrorCode.packServiceOtherProvider:
        _serverErrors[PackField.services] = failure.message;
    }
  }
}
