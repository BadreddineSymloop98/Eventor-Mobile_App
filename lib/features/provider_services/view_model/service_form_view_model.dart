import 'package:flutter/foundation.dart' show listEquals;

import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/models/price_type.dart';
import '../../../core/errors/failure.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/reference/reference_repository.dart';
import 'catalog_outcomes.dart';

/// The fields of P7 / P7a, for errors and for jumping to one.
enum ServiceField {
  category,
  titleEn,
  titleAr,
  descriptionEn,
  descriptionAr,
  basePrice,
  priceType,
  maxEventsPerDay,
  maxGuests,
  facts,
  extras,
  wilayas,
  cancellationEn,
  cancellationAr,
}

/// What is wrong with a field before anything is sent.
enum FieldProblem { required, outOfRange }

/// What a busy form is doing — the button that spins.
enum ServiceFormAction { save, publish, unpublish, delete, photos }

/// Whether P8 can open for this service (decision 5).
sealed class PhotosAccess {
  const PhotosAccess();
}

final class PhotosReady extends PhotosAccess {
  const PhotosReady(this.serviceId);

  final String serviceId;
}

/// A new service cannot be saved yet; the fields it needs are flagged.
final class PhotosNeedDraft extends PhotosAccess {
  const PhotosNeedDraft(this.fields);

  final List<ServiceField> fields;
}

final class PhotosFailed extends PhotosAccess {
  const PhotosFailed(this.failure);

  final Failure failure;
}

sealed class SaveOutcome {
  const SaveOutcome();
}

final class SaveDone extends SaveOutcome {
  const SaveDone({required this.created});

  /// The first save of a new service — the form is now P7a.
  final bool created;
}

final class SaveInvalid extends SaveOutcome {
  const SaveInvalid(this.fields);

  final List<ServiceField> fields;
}

final class SaveFailed extends SaveOutcome {
  const SaveFailed(this.failure);

  final Failure failure;
}

/// P7 Add a service and P7a Edit service — one scrolling form.
///
/// A draft needs only a category, an English title, a base price and a price
/// type; everything else the publish checklist asks for (P9) comes from the
/// server's `publishMissing`, not from rules copied here. An edit sends only
/// the fields that changed. Facts carry both languages at once (the API
/// requires all four texts), so they are edited in a sheet, not per
/// language.
class ServiceFormViewModel extends BaseViewModel {
  ServiceFormViewModel({
    required this._catalog,
    required this._reference,
    String? serviceId,
    ServiceChecklistItem? fix,
  })  : _serviceId = serviceId,
        _pendingFix = fix {
    if (serviceId != null) load();
  }

  final ProviderCatalogRepository _catalog;
  final ReferenceRepository _reference;
  final String? _serviceId;
  ServiceChecklistItem? _pendingFix;

  static const int maxTitleLength = ProviderServiceDetail.maxTitleLength;
  static const int maxTextLength = ProviderServiceDetail.maxTextLength;
  static const int maxEventsPerDayLimit = ProviderServiceDetail.maxEventsPerDayLimit;

  /// QuantityInput needs a ceiling; the API sets none on guests.
  static const int maxGuestsLimit = 100000;

  ProviderServiceDetail? _saved;
  bool _isLoading = false;
  bool _isGone = false;
  ServiceFormAction? _action;

  ContentLanguage _language = ContentLanguage.english;
  ServiceCategory? _category;
  String _titleEn = '';
  String _titleAr = '';
  String _descriptionEn = '';
  String _descriptionAr = '';
  String _policyEn = '';
  String _policyAr = '';
  int? _basePrice;
  PriceType? _priceType;
  int? _maxEventsPerDay = 1;
  int? _maxGuests;
  List<ServiceFact> _facts = <ServiceFact>[];
  List<ServiceExtra> _extras = <ServiceExtra>[];
  List<Wilaya> _wilayas = <Wilaya>[];

  final Map<ServiceField, FieldProblem> _problems = <ServiceField, FieldProblem>{};
  final Map<ServiceField, String> _serverErrors = <ServiceField, String>{};

  List<ServiceCategory>? _categories;
  List<Wilaya>? _openWilayas;
  bool _isLoadingCategories = false;
  bool _isLoadingWilayas = false;

  /// What the server holds — `null` until a new service's first save.
  ProviderServiceDetail? get saved => _saved;
  bool get isNew => _saved == null;
  bool get isEditing => _serviceId != null || _saved != null;

  /// P7a waiting for its detail — the skeleton.
  bool get isFirstLoad => _serviceId != null && _saved == null && !hasError && !_isGone;

  /// P7a could not load; [isGone] when the service no longer exists.
  bool get loadFailed => _serviceId != null && _saved == null && (hasError || _isGone);
  bool get isGone => _isGone;

  ServiceFormAction? get action => _action;
  bool get isWorking => _action != null;

  ContentLanguage get language => _language;
  ServiceCategory? get category => _category;
  String get titleEn => _titleEn;
  String get titleAr => _titleAr;
  String get descriptionEn => _descriptionEn;
  String get descriptionAr => _descriptionAr;
  String get policyEn => _policyEn;
  String get policyAr => _policyAr;
  int? get basePrice => _basePrice;
  PriceType? get priceType => _priceType;
  int? get maxEventsPerDay => _maxEventsPerDay;
  int? get maxGuests => _maxGuests;
  List<ServiceFact> get facts => List<ServiceFact>.unmodifiable(_facts);
  List<ServiceExtra> get extras => List<ServiceExtra>.unmodifiable(_extras);
  List<Wilaya> get wilayas => List<Wilaya>.unmodifiable(_wilayas);
  int get photosCount => _saved?.photos.length ?? 0;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingWilayas => _isLoadingWilayas;

  bool get isPublished => _saved?.isPublished ?? false;
  bool get isHidden => _saved?.isHidden ?? false;

  /// Live, so an edit shows to clients straight away.
  bool get isLive => (_saved?.isPublished ?? false) && (_saved?.visibleInApp ?? false);

  /// The copy the languages still lack, from what is typed now — the
  /// helper under the `English | عربي` control.
  List<ServiceMissing> get textGaps => <ServiceMissing>[
        if (_titleEn.trim().isEmpty) ServiceMissing.titleEn,
        if (_descriptionEn.trim().isEmpty) ServiceMissing.descriptionEn,
        if (_titleAr.trim().isEmpty) ServiceMissing.titleAr,
        if (_descriptionAr.trim().isEmpty) ServiceMissing.descriptionAr,
      ];

  FieldProblem? problemOf(ServiceField field) => _problems[field];

  /// The server's own words for a field it refused.
  String? serverErrorOf(ServiceField field) => _serverErrors[field];

  /// A fix P9 asked for before this form opened — the view acts on it once
  /// the form is on screen.
  ServiceChecklistItem? takeFix() {
    final ServiceChecklistItem? fix = _pendingFix;
    _pendingFix = null;
    return fix;
  }

  bool get isDirty {
    final ProviderServiceDetail? saved = _saved;
    if (saved == null) {
      return _category != null ||
          _titleEn.trim().isNotEmpty ||
          _titleAr.trim().isNotEmpty ||
          _descriptionEn.trim().isNotEmpty ||
          _descriptionAr.trim().isNotEmpty ||
          _policyEn.trim().isNotEmpty ||
          _policyAr.trim().isNotEmpty ||
          _basePrice != null ||
          _priceType != null ||
          _maxEventsPerDay != 1 ||
          _maxGuests != null ||
          _facts.isNotEmpty ||
          _extras.isNotEmpty ||
          _wilayas.isNotEmpty;
    }
    return !_changes(saved).isEmpty;
  }

  Future<void> load() async {
    final String? id = _serviceId;
    if (id == null) return;
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final ProviderServiceDetail? detail = await runGuarded(() => _catalog.service(id));
    _isLoading = false;
    if (detail != null) {
      _fill(detail);
    } else if (_isGoneFailure(failure)) {
      _isGone = true;
    }
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  void _fill(ProviderServiceDetail detail) {
    _saved = detail;
    _category = detail.category;
    _titleEn = detail.titleEn;
    _titleAr = detail.titleAr;
    _descriptionEn = detail.descriptionEn;
    _descriptionAr = detail.descriptionAr;
    _policyEn = detail.cancellationPolicyEn ?? '';
    _policyAr = detail.cancellationPolicyAr ?? '';
    _basePrice = _dinars(detail.basePrice);
    _priceType = detail.priceType;
    _maxEventsPerDay = detail.maxEventsPerDay;
    _maxGuests = detail.maxGuests;
    _facts = List<ServiceFact>.of(detail.facts);
    _extras = List<ServiceExtra>.of(detail.extras);
    _wilayas = <Wilaya>[for (final CoveredWilaya w in detail.wilayas) w.wilaya];
  }

  // ------------------------------------------------------------ editing

  void setLanguage(ContentLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  void setCategory(ServiceCategory category) {
    _category = category;
    _clear(ServiceField.category);
  }

  void setTitle(String value) {
    if (_language == ContentLanguage.arabic) {
      _titleAr = value;
      _clear(ServiceField.titleAr);
    } else {
      _titleEn = value;
      _clear(ServiceField.titleEn);
    }
  }

  void setDescription(String value) {
    if (_language == ContentLanguage.arabic) {
      _descriptionAr = value;
      _clear(ServiceField.descriptionAr);
    } else {
      _descriptionEn = value;
      _clear(ServiceField.descriptionEn);
    }
  }

  void setPolicy(String value) {
    if (_language == ContentLanguage.arabic) {
      _policyAr = value;
      _clear(ServiceField.cancellationAr);
    } else {
      _policyEn = value;
      _clear(ServiceField.cancellationEn);
    }
  }

  /// The title, description and policy of the language on screen.
  String get title => _language == ContentLanguage.arabic ? _titleAr : _titleEn;
  String get description =>
      _language == ContentLanguage.arabic ? _descriptionAr : _descriptionEn;
  String get policy => _language == ContentLanguage.arabic ? _policyAr : _policyEn;

  void setBasePrice(int? dinars) {
    _basePrice = dinars;
    _clear(ServiceField.basePrice);
  }

  void setPriceType(PriceType type) {
    _priceType = type;
    _clear(ServiceField.priceType);
  }

  void setMaxEventsPerDay(int? value) {
    _maxEventsPerDay = value;
    _clear(ServiceField.maxEventsPerDay);
  }

  void setMaxGuests(int? value) {
    _maxGuests = value;
    _clear(ServiceField.maxGuests);
  }

  /// Adds [fact], or replaces the one at [index].
  void putFact(ServiceFact fact, {int? index}) {
    if (index == null) {
      _facts.add(fact);
    } else {
      _facts[index] = fact;
    }
    _clear(ServiceField.facts);
  }

  void removeFact(int index) {
    _facts.removeAt(index);
    _clear(ServiceField.facts);
  }

  void putExtra(ServiceExtra extra, {int? index}) {
    if (index == null) {
      _extras.add(extra);
    } else {
      _extras[index] = extra;
    }
    _clear(ServiceField.extras);
  }

  void removeExtra(int index) {
    _extras.removeAt(index);
    _clear(ServiceField.extras);
  }

  /// The wilayas picked in the sheet, in the order they were listed.
  void setWilayas(List<Wilaya> wilayas) {
    _wilayas = List<Wilaya>.of(wilayas);
    _clear(ServiceField.wilayas);
  }

  void removeWilaya(Wilaya wilaya) {
    _wilayas.remove(wilaya);
    _clear(ServiceField.wilayas);
  }

  void _clear(ServiceField field) {
    _problems.remove(field);
    _serverErrors.remove(field);
    notifyListeners();
  }

  /// The categories to pick from, loaded once. Throws the load's [Failure];
  /// a failed load is not kept, so the next tap tries again.
  Future<List<ServiceCategory>> categories() async {
    final List<ServiceCategory>? loaded = _categories;
    if (loaded != null) return loaded;
    _isLoadingCategories = true;
    notifyListeners();
    try {
      return _categories = await _reference.categories();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// The open wilayas — the API lists only those.
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

  // ------------------------------------------------------------ saving

  /// What a draft cannot be saved without — flagged on the form.
  List<ServiceField> _validate() {
    _problems.clear();
    if (_category == null) _problems[ServiceField.category] = FieldProblem.required;
    if (_titleEn.trim().isEmpty) _problems[ServiceField.titleEn] = FieldProblem.required;
    if (_basePrice == null) _problems[ServiceField.basePrice] = FieldProblem.required;
    if (_priceType == null) _problems[ServiceField.priceType] = FieldProblem.required;
    final int? events = _maxEventsPerDay;
    if (events == null) {
      _problems[ServiceField.maxEventsPerDay] = FieldProblem.required;
    } else if (events < 1 || events > maxEventsPerDayLimit) {
      _problems[ServiceField.maxEventsPerDay] = FieldProblem.outOfRange;
    }
    final int? guests = _maxGuests;
    if (guests != null && (guests < 1 || guests > maxGuestsLimit)) {
      _problems[ServiceField.maxGuests] = FieldProblem.outOfRange;
    }
    return <ServiceField>[
      for (final ServiceField field in ServiceField.values)
        if (_problems.containsKey(field)) field,
    ];
  }

  /// Save draft / Save / Save changes.
  Future<SaveOutcome?> save() async {
    if (_action != null) return null;
    _action = ServiceFormAction.save;
    notifyListeners();
    final SaveOutcome outcome = await _save();
    _action = null;
    notifyListeners();
    return outcome;
  }

  Future<SaveOutcome> _save() async {
    final List<ServiceField> invalid = _validate();
    if (invalid.isNotEmpty) return SaveInvalid(invalid);
    final ProviderServiceDetail? saved = _saved;
    try {
      if (saved == null) {
        _saved = await _catalog.createService(_fullInput());
        return const SaveDone(created: true);
      }
      final ServiceInput changes = _changes(saved);
      if (!changes.isEmpty) _saved = await _catalog.updateService(saved.id, changes);
      return const SaveDone(created: false);
    } on Failure catch (failure) {
      _takeFieldErrors(failure);
      return SaveFailed(failure);
    } catch (error) {
      return SaveFailed(UnexpectedFailure(cause: error));
    }
  }

  /// Publish: save what is on screen, then ask the server. A checklist
  /// already known from the save opens P9 without another round trip.
  Future<PublishOutcome<ServiceMissing>?> publish() async {
    if (_action != null) return null;
    _action = ServiceFormAction.publish;
    notifyListeners();
    final PublishOutcome<ServiceMissing> outcome = await _publish();
    _action = null;
    notifyListeners();
    return outcome;
  }

  Future<PublishOutcome<ServiceMissing>> _publish() async {
    switch (await _save()) {
      case SaveInvalid():
        return const PublishInvalid<ServiceMissing>();
      case SaveFailed(:final Failure failure):
        return PublishFailed<ServiceMissing>(failure);
      case SaveDone():
        break;
    }
    final ProviderServiceDetail saved = _saved!;
    if (saved.publishMissing.isNotEmpty) {
      return PublishChecklist<ServiceMissing>(saved.publishMissing);
    }
    try {
      _saved = await _catalog.publishService(saved.id);
      return const PublishDone<ServiceMissing>();
    } on ApiFailure catch (failure) {
      if (failure.code == ApiErrorCode.providerNotVerified) {
        return const PublishNotVerified<ServiceMissing>();
      }
      if (failure.code == ApiErrorCode.servicePublishInvalid) {
        final List<ServiceMissing> missing = ServiceMissing.fromApi(missingKeysOf(failure));
        return PublishChecklist<ServiceMissing>(
          missing.isEmpty ? saved.publishMissing : missing,
        );
      }
      if (failure.code == ApiErrorCode.serviceInvalidTransition) await _reload();
      return PublishFailed<ServiceMissing>(failure);
    } on Failure catch (failure) {
      return PublishFailed<ServiceMissing>(failure);
    }
  }

  /// Unpublish, once confirmed. Edits on screen stay unsaved. `null` when
  /// it went through.
  Future<Failure?> unpublish() async {
    final ProviderServiceDetail? saved = _saved;
    if (saved == null || _action != null) return null;
    _action = ServiceFormAction.unpublish;
    notifyListeners();
    Failure? failure;
    try {
      final ProviderServiceDetail fresh = await _catalog.unpublishService(saved.id);
      // The form holds its own copy of every field, so what was typed stays
      // on screen, unsaved, against the new status.
      _saved = fresh;
    } on Failure catch (error) {
      failure = error;
      if (error is ApiFailure && error.code == ApiErrorCode.serviceInvalidTransition) {
        await _reload();
      }
    }
    _action = null;
    notifyListeners();
    return failure;
  }

  /// Delete, once confirmed; P7b when the server refuses.
  Future<DeleteOutcome?> delete() async {
    final ProviderServiceDetail? saved = _saved;
    if (saved == null || _action != null) return null;
    _action = ServiceFormAction.delete;
    notifyListeners();
    DeleteOutcome outcome;
    try {
      await _catalog.deleteService(saved.id);
      outcome = const DeleteDone();
    } on Failure catch (failure) {
      final DeleteBlocker? blocker = deleteBlockerOf(failure);
      outcome = blocker == null ? DeleteFailed(failure) : DeleteRefused(<DeleteBlocker>[blocker]);
    }
    _action = null;
    notifyListeners();
    return outcome;
  }

  /// P8 needs a saved service: a new one is saved as a draft first
  /// (decision 5), and the form is P7a from then on.
  Future<PhotosAccess?> openPhotos() async {
    final ProviderServiceDetail? saved = _saved;
    if (saved != null) return PhotosReady(saved.id);
    if (_action != null) return null;
    _action = ServiceFormAction.photos;
    notifyListeners();
    final SaveOutcome outcome = await _save();
    _action = null;
    notifyListeners();
    return switch (outcome) {
      SaveDone() => PhotosReady(_saved!.id),
      SaveInvalid(:final List<ServiceField> fields) => PhotosNeedDraft(fields),
      SaveFailed(:final Failure failure) => PhotosFailed(failure),
    };
  }

  /// Back from P8: the gallery (and whether it ticks "a photo") changed;
  /// the rest of the form keeps its edits.
  Future<void> reloadPhotos() async {
    final ProviderServiceDetail? saved = _saved;
    if (saved == null) return;
    try {
      final ProviderServiceDetail fresh = await _catalog.service(saved.id);
      _saved = saved.withPhotosOf(fresh);
      notifyListeners();
    } catch (_) {
      // The count stays as it was; the next save answers with the truth.
    }
  }

  Future<void> _reload() async {
    final ProviderServiceDetail? saved = _saved;
    if (saved == null) return;
    try {
      _saved = await _catalog.service(saved.id);
    } catch (_) {
      // Kept as it was.
    }
  }

  // ------------------------------------------------------------ inputs

  ServiceInput _fullInput() => ServiceInput(
        categoryId: _category?.id,
        titleEn: _titleEn.trim(),
        titleAr: _titleAr.trim().isEmpty ? null : _titleAr.trim(),
        descriptionEn: _descriptionEn.trim().isEmpty ? null : _descriptionEn.trim(),
        descriptionAr: _descriptionAr.trim().isEmpty ? null : _descriptionAr.trim(),
        cancellationPolicyEn: _policyEn.trim().isEmpty ? null : _policyEn.trim(),
        cancellationPolicyAr: _policyAr.trim().isEmpty ? null : _policyAr.trim(),
        basePrice: apiAmountOf(_basePrice ?? 0),
        priceType: _priceType,
        maxEventsPerDay: _maxEventsPerDay,
        maxGuests: _maxGuests,
        facts: _facts.isEmpty ? null : _facts,
        extras: _extras.isEmpty ? null : _extras,
        wilayaCodes: _wilayas.isEmpty ? null : _codes(_wilayas),
      );

  /// Only what differs from [saved] — the PATCH is partial.
  ServiceInput _changes(ProviderServiceDetail saved) {
    String? changed(String typed, String stored) =>
        typed.trim() == stored.trim() ? null : typed.trim();
    final int? price = _basePrice;
    final bool priceChanged = (price ?? 0) != (_dinars(saved.basePrice) ?? 0);
    final bool guestsChanged = _maxGuests != saved.maxGuests;
    final List<int> codes = _codes(_wilayas);
    final List<int> savedCodes = <int>[for (final CoveredWilaya w in saved.wilayas) w.code];
    return ServiceInput(
      categoryId: _category != null && _category!.id != saved.category?.id ? _category!.id : null,
      titleEn: changed(_titleEn, saved.titleEn),
      titleAr: changed(_titleAr, saved.titleAr),
      descriptionEn: changed(_descriptionEn, saved.descriptionEn),
      descriptionAr: changed(_descriptionAr, saved.descriptionAr),
      cancellationPolicyEn: changed(_policyEn, saved.cancellationPolicyEn ?? ''),
      cancellationPolicyAr: changed(_policyAr, saved.cancellationPolicyAr ?? ''),
      basePrice: priceChanged && price != null ? apiAmountOf(price) : null,
      priceType: _priceType != saved.priceType ? _priceType : null,
      maxEventsPerDay:
          _maxEventsPerDay != saved.maxEventsPerDay ? _maxEventsPerDay : null,
      maxGuests: guestsChanged ? _maxGuests : null,
      clearMaxGuests: guestsChanged && _maxGuests == null,
      facts: listEquals(_facts, saved.facts) ? null : _facts,
      extras: listEquals(_extras, saved.extras) ? null : _extras,
      wilayaCodes: _sameSet(codes, savedCodes) ? null : codes,
    );
  }

  static bool _sameSet(List<int> a, List<int> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  static List<int> _codes(List<Wilaya> wilayas) =>
      <int>[for (final Wilaya w in wilayas) w.code];

  static int? _dinars(String apiAmount) {
    if (apiAmount.isEmpty) return null;
    return amountCents(apiAmount) ~/ 100;
  }

  /// The server's refusal, on the fields it names.
  void _takeFieldErrors(Failure failure) {
    if (failure is! ApiFailure) return;
    switch (failure.code) {
      case ApiErrorCode.validationFailed:
        for (final FieldError error in failure.fieldErrors) {
          final ServiceField? field = _fieldOf(error.field);
          if (field != null) _serverErrors[field] = error.message;
        }
      case ApiErrorCode.categoryHidden || ApiErrorCode.categoryNotFound:
        _serverErrors[ServiceField.category] = failure.message;
      case ApiErrorCode.wilayaClosed || ApiErrorCode.wilayaNotFound:
        _serverErrors[ServiceField.wilayas] = failure.message;
    }
  }

  /// `titleEn`, `facts.0.label_en` → the field it belongs to.
  static ServiceField? _fieldOf(String apiField) => switch (apiField.split('.').first) {
        'categoryId' => ServiceField.category,
        'titleEn' => ServiceField.titleEn,
        'titleAr' => ServiceField.titleAr,
        'descriptionEn' => ServiceField.descriptionEn,
        'descriptionAr' => ServiceField.descriptionAr,
        'cancellationPolicyEn' => ServiceField.cancellationEn,
        'cancellationPolicyAr' => ServiceField.cancellationAr,
        'basePrice' => ServiceField.basePrice,
        'priceType' => ServiceField.priceType,
        'maxEventsPerDay' => ServiceField.maxEventsPerDay,
        'maxGuests' => ServiceField.maxGuests,
        'facts' => ServiceField.facts,
        'extras' => ServiceField.extras,
        'wilayaCodes' => ServiceField.wilayas,
        _ => null,
      };

  static bool _isGoneFailure(Failure? failure) =>
      failure is ApiFailure &&
      (failure.code == ApiErrorCode.serviceNotFound || failure.code == ApiErrorCode.notOwner);

  /// Whether [failure] means the service is gone from under the form.
  static bool isGoneFailure(Failure failure) => _isGoneFailure(failure);
}
