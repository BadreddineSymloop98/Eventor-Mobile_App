import '../../../core/base/base_view_model.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/models/account.dart';
import '../../../core/provider_catalog/provider_catalog_repository.dart';
import '../../../core/reference/reference_repository.dart';
import '../../../core/routing/app_routes.dart' show ChooseServicesArgs;

/// Whether a service can go in the pack — P11a greys out the rest, with the
/// reason.
enum PackEligibility {
  eligible,

  /// "Draft — cannot go in a pack".
  draft,

  /// Hidden by an admin.
  hidden,

  /// "Doesn't cover Blida".
  notCovering,
}

/// What a tap on a P11a row did.
enum ChooseToggle { toggled, full, ineligible }

/// P11a Choose services — 2 to 6 of the provider's published services that
/// cover the pack's wilaya. The eligibility is worked out here: the API has
/// no "eligible for a pack" filter. A chosen service that has since stopped
/// qualifying stays chosen, so it can be seen and taken out.
class ChooseServicesViewModel extends BaseViewModel {
  ChooseServicesViewModel({
    required this._catalog,
    required this._reference,
    required ChooseServicesArgs args,
  })  : _selected = List<String>.of(args.selected),
        _wilayaCode = args.wilayaCode {
    load();
  }

  final ProviderCatalogRepository _catalog;
  final ReferenceRepository _reference;
  final int? _wilayaCode;
  final List<String> _selected;

  static const int minItems = ProviderPackDetail.minItems;
  static const int maxItems = ProviderPackDetail.maxItems;

  List<ProviderServiceSummary>? _services;
  Wilaya? _wilaya;

  bool get isFirstLoad => _services == null && !hasError;
  bool get loadFailed => _services == null && hasError;

  /// The pack's wilaya, for "Doesn't cover Blida".
  Wilaya? get wilaya => _wilaya;

  /// Eligible services first, in the server's order, then the rest.
  List<ProviderServiceSummary> get services {
    final List<ProviderServiceSummary> all = _services ?? const <ProviderServiceSummary>[];
    return <ProviderServiceSummary>[
      ...all.where((ProviderServiceSummary s) => eligibilityOf(s) == PackEligibility.eligible),
      ...all.where((ProviderServiceSummary s) => eligibilityOf(s) != PackEligibility.eligible),
    ];
  }

  List<String> get selected => List<String>.unmodifiable(_selected);
  int get count => _selected.length;
  bool isSelected(ProviderServiceSummary service) => _selected.contains(service.id);

  bool get canFinish => count >= minItems && count <= maxItems;

  /// What the chosen services cost one by one, in centimes.
  int get sumCents => (_services ?? const <ProviderServiceSummary>[])
      .where((ProviderServiceSummary s) => _selected.contains(s.id))
      .fold(0, (int sum, ProviderServiceSummary s) => sum + amountCents(s.basePrice));

  PackEligibility eligibilityOf(ProviderServiceSummary service) {
    if (service.isHidden) return PackEligibility.hidden;
    if (!service.isPublished) return PackEligibility.draft;
    final int? code = _wilayaCode;
    if (code != null && !service.covers(code)) return PackEligibility.notCovering;
    return PackEligibility.eligible;
  }

  Future<void> load() async {
    final List<ProviderServiceSummary>? services = await runGuarded(_catalog.services);
    if (services != null) _services = services;
    notifyListeners();
    final int? code = _wilayaCode;
    if (code == null || _wilaya != null) return;
    try {
      for (final Wilaya w in await _reference.wilayas()) {
        if (w.code == code) _wilaya = w;
      }
      notifyListeners();
    } catch (_) {
      // The reason then names no wilaya.
    }
  }

  ChooseToggle toggle(ProviderServiceSummary service) {
    if (_selected.remove(service.id)) {
      notifyListeners();
      return ChooseToggle.toggled;
    }
    if (eligibilityOf(service) != PackEligibility.eligible) return ChooseToggle.ineligible;
    if (_selected.length >= maxItems) return ChooseToggle.full;
    _selected.add(service.id);
    notifyListeners();
    return ChooseToggle.toggled;
  }
}
