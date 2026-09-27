import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/chat_launcher.dart';
import '../../../core/messaging/messaging_repository.dart';

/// Screen 13 — a provider's profile.
///
/// A provider no longer listed answers `PROVIDER_NOT_FOUND`: [isGone], not an
/// error to retry.
class ProviderProfileViewModel extends BaseViewModel with ChatLauncher {
  ProviderProfileViewModel({
    required this.id,
    required this._catalog,
    required this._messaging,
  }) {
    load();
  }

  final String id;
  final CatalogRepository _catalog;
  final MessagingRepository _messaging;

  @override
  MessagingRepository get chatMessaging => _messaging;

  ProviderDetail? _provider;
  bool _isLoading = false;
  bool _isGone = false;

  ProviderDetail? get provider => _provider;
  bool get isFirstLoad => _isLoading && _provider == null;
  bool get isGone => _isGone;

  /// The checks worth showing — the ones the provider passed.
  List<ProviderCheck> get passedChecks => <ProviderCheck>[
    for (final ProviderCheck check in _provider?.checks ?? <ProviderCheck>[])
      if (check.passed) check,
  ];

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final ProviderDetail? provider = await runGuarded(
      () => _catalog.provider(id),
    );
    final Failure? failure = this.failure;
    if (provider != null) {
      _provider = provider;
    } else if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.providerNotFound ||
            failure.statusCode == 404)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
  }
}
