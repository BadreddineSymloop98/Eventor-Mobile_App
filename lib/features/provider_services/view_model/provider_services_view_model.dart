import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import 'catalog_outcomes.dart';

/// The Services tab's two chip-tabs.
enum CatalogTab { services, packs }

/// The line under a service card's price that explains why it is not live
/// (decision 4). Worded by the view.
sealed class ServiceNote {
  const ServiceNote();
}

/// A draft: "Missing before publishing: …".
final class MissingNote extends ServiceNote {
  const MissingNote(this.missing);

  final List<ServiceMissing> missing;
}

/// Published, but clients cannot see it: "Not visible — …".
final class NotVisibleNote extends ServiceNote {
  const NotVisibleNote(this.reasons, {this.closedWilayas = const <Wilaya>[]});

  final List<ServiceVisibilityReason> reasons;
  final List<Wilaya> closedWilayas;
}

/// Hidden by an admin — P6b. [info] is `null` until the detail arrives.
final class HiddenNote extends ServiceNote {
  const HiddenNote(this.info);

  final HiddenInfo? info;
}

/// P6 / P10 — the provider's services and packs, one chip each.
///
/// Both lists load together: the Packs chip's empty state (P10a) needs the
/// count of published services, and switching chips should never wait.
/// Once the services show, the detail of every service that is not live is
/// fetched in the background to explain why (decision 4); a card shows its
/// note as soon as its detail lands, and a failed one simply shows none.
class ProviderServicesViewModel extends BaseViewModel {
  ProviderServicesViewModel({
    required this._catalog,
    bool openPacks = false,
  }) : _tab = openPacks ? CatalogTab.packs : CatalogTab.services {
    load();
  }

  final ProviderCatalogRepository _catalog;

  CatalogTab _tab;
  List<ProviderServiceSummary>? _services;
  List<ProviderPackSummary>? _packs;
  Failure? _servicesFailure;
  Failure? _packsFailure;
  bool _isLoading = false;
  final Map<String, ProviderServiceDetail> _details = <String, ProviderServiceDetail>{};

  /// Bumped on every reload, so a background detail from an older list
  /// cannot land on a newer one.
  int _generation = 0;

  /// The card whose Publish or Unpublish is running.
  String? _busyId;

  CatalogTab get tab => _tab;
  List<ProviderServiceSummary> get services => _services ?? const <ProviderServiceSummary>[];
  List<ProviderPackSummary> get packs => _packs ?? const <ProviderPackSummary>[];
  String? get busyId => _busyId;

  /// Nothing to show on the current chip yet — its skeleton.
  bool get isFirstLoad => switch (_tab) {
        CatalogTab.services => _services == null && _servicesFailure == null,
        CatalogTab.packs =>
          (_packs == null || _services == null) && _packsFailure == null && _servicesFailure == null,
      };

  /// The current chip could not be loaded at all.
  bool get loadFailed => !_isLoading &&
      switch (_tab) {
        CatalogTab.services => _services == null && _servicesFailure != null,
        CatalogTab.packs => (_packs == null && _packsFailure != null) ||
            (_services == null && _servicesFailure != null),
      };

  bool get isEmpty => switch (_tab) {
        CatalogTab.services => _services?.isEmpty ?? false,
        CatalogTab.packs => _packs?.isEmpty ?? false,
      };

  /// P10a: a pack needs two published services to exist at all.
  int get publishedServicesCount =>
      services.where((ProviderServiceSummary s) => s.isPublished).length;

  bool get canBuildPack => publishedServicesCount >= ProviderPackDetail.minItems;

  void setTab(CatalogTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _servicesFailure = null;
    _packsFailure = null;
    notifyListeners();
    await Future.wait(<Future<void>>[_loadServices(), _loadPacks()]);
    _isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh, and the reload after a form closes. What is on screen
  /// stays when it fails.
  Future<Failure?> refresh() async {
    try {
      final List<Object> lists = await Future.wait(<Future<Object>>[
        _catalog.services(),
        _catalog.packs(),
      ]);
      _applyServices(lists[0] as List<ProviderServiceSummary>);
      _packs = lists[1] as List<ProviderPackSummary>;
      _servicesFailure = null;
      _packsFailure = null;
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  Future<void> _loadServices() async {
    try {
      _applyServices(await _catalog.services());
    } on Failure catch (failure) {
      _servicesFailure = failure;
    } catch (error) {
      _servicesFailure = UnexpectedFailure(cause: error);
    }
  }

  Future<void> _loadPacks() async {
    try {
      _packs = await _catalog.packs();
    } on Failure catch (failure) {
      _packsFailure = failure;
    } catch (error) {
      _packsFailure = UnexpectedFailure(cause: error);
    }
  }

  void _applyServices(List<ProviderServiceSummary> services) {
    _services = services;
    final int generation = ++_generation;
    _details.removeWhere(
      (String id, _) => !services.any((ProviderServiceSummary s) => s.id == id && !s.isLive),
    );
    for (final ProviderServiceSummary service in services) {
      if (!service.isLive) _loadDetail(service.id, generation);
    }
  }

  Future<void> _loadDetail(String id, int generation) async {
    try {
      final ProviderServiceDetail detail = await _catalog.service(id);
      if (generation != _generation) return;
      _details[id] = detail;
      notifyListeners();
    } catch (_) {
      // A note is a nicety: without its detail the card simply has none.
    }
  }

  /// Decision 4's note for [service], or `null` while there is nothing (yet)
  /// to say.
  ServiceNote? noteFor(ProviderServiceSummary service) {
    final ProviderServiceDetail? detail = _details[service.id];
    if (service.isHidden) return HiddenNote(detail?.hidden);
    if (detail == null || service.isLive) return null;
    if (!service.isPublished) {
      return detail.publishMissing.isEmpty ? null : MissingNote(detail.publishMissing);
    }
    final List<ServiceVisibilityReason> reasons = detail.visibilityReasons
        .where((ServiceVisibilityReason r) =>
            r != ServiceVisibilityReason.notPublished &&
            r != ServiceVisibilityReason.deleted &&
            r != ServiceVisibilityReason.providerDeleted)
        .toList();
    if (reasons.isEmpty) return null;
    return NotVisibleNote(reasons, closedWilayas: detail.closedWilayas);
  }

  /// When an admin hid [service] — P6b's "Hidden on 12 March".
  DateTime? hiddenAt(ProviderServiceSummary service) =>
      _details[service.id]?.hidden?.hiddenAt;

  /// The known checklist of [service], from its background detail.
  List<ServiceMissing>? knownMissing(String serviceId) =>
      _details[serviceId]?.publishMissing;

  /// A draft card's Publish. A checklist already known from the background
  /// detail opens P9 without a round trip.
  Future<PublishOutcome<ServiceMissing>?> publishService(ProviderServiceSummary service) async {
    if (_busyId != null) return null;
    final List<ServiceMissing>? known = knownMissing(service.id);
    if (known != null && known.isNotEmpty) return PublishChecklist<ServiceMissing>(known);
    _busyId = service.id;
    notifyListeners();
    PublishOutcome<ServiceMissing> outcome;
    try {
      await _catalog.publishService(service.id);
      outcome = const PublishDone<ServiceMissing>();
    } on ApiFailure catch (failure) {
      outcome = await _serviceRefusal(service.id, failure);
    } on Failure catch (failure) {
      outcome = PublishFailed<ServiceMissing>(failure);
    }
    await refresh();
    _busyId = null;
    notifyListeners();
    return outcome;
  }

  Future<PublishOutcome<ServiceMissing>> _serviceRefusal(String id, ApiFailure failure) async {
    if (failure.code == ApiErrorCode.providerNotVerified) {
      return const PublishNotVerified<ServiceMissing>();
    }
    if (failure.code != ApiErrorCode.servicePublishInvalid) {
      return PublishFailed<ServiceMissing>(failure);
    }
    List<ServiceMissing> missing = ServiceMissing.fromApi(missingKeysOf(failure));
    if (missing.isEmpty) {
      try {
        missing = (await _catalog.service(id)).publishMissing;
      } catch (_) {
        // The checklist then shows every row as it can: nothing ticked.
      }
    }
    return PublishChecklist<ServiceMissing>(missing);
  }

  /// A published card's Unpublish, once confirmed. `null` when it went.
  Future<Failure?> unpublishService(ProviderServiceSummary service) =>
      _act(service.id, () => _catalog.unpublishService(service.id));

  /// A draft or unpublished pack's Publish.
  Future<PublishOutcome<PackMissing>?> publishPack(ProviderPackSummary pack) async {
    if (_busyId != null) return null;
    _busyId = pack.id;
    notifyListeners();
    PublishOutcome<PackMissing> outcome;
    try {
      await _catalog.publishPack(pack.id);
      outcome = const PublishDone<PackMissing>();
    } on ApiFailure catch (failure) {
      outcome = await packRefusal(_catalog, pack.id, failure);
    } on Failure catch (failure) {
      outcome = PublishFailed<PackMissing>(failure);
    }
    await refresh();
    _busyId = null;
    notifyListeners();
    return outcome;
  }

  Future<Failure?> unpublishPack(ProviderPackSummary pack) =>
      _act(pack.id, () => _catalog.unpublishPack(pack.id));

  Future<Failure?> _act(String id, Future<Object?> Function() action) async {
    if (_busyId != null) return null;
    _busyId = id;
    notifyListeners();
    Failure? failure;
    try {
      await action();
    } on Failure catch (error) {
      failure = error;
    } catch (error) {
      failure = UnexpectedFailure(cause: error);
    }
    // Either way the list may be stale: changed, or changed meanwhile.
    await refresh();
    _busyId = null;
    notifyListeners();
    return failure;
  }
}

/// What a pack's publish refusal means — shared by P10 and P12.
Future<PublishOutcome<PackMissing>> packRefusal(
  ProviderCatalogRepository catalog,
  String id,
  ApiFailure failure,
) async {
  if (failure.code == ApiErrorCode.providerNotVerified) {
    return const PublishNotVerified<PackMissing>();
  }
  if (failure.code != ApiErrorCode.packPublishInvalid &&
      failure.code != ApiErrorCode.packWilayaNotCovered) {
    return PublishFailed<PackMissing>(failure);
  }
  List<PackMissing> missing = PackMissing.fromApi(missingKeysOf(failure));
  if (missing.isEmpty && failure.code == ApiErrorCode.packWilayaNotCovered) {
    missing = <PackMissing>[PackMissing.wilayaNotCovered];
  }
  if (missing.isEmpty) {
    try {
      missing = (await catalog.pack(id)).publishMissing;
    } catch (_) {
      // Shown with nothing ticked.
    }
  }
  // The account itself, not the pack: say so rather than list it.
  if (missing.isNotEmpty &&
      missing.every((PackMissing m) =>
          m == PackMissing.providerNotVerified || m == PackMissing.providerBlocked) &&
      missing.contains(PackMissing.providerNotVerified)) {
    return const PublishNotVerified<PackMissing>();
  }
  return PublishChecklist<PackMissing>(missing);
}
