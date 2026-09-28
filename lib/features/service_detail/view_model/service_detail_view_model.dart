import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/month_availability.dart';
import '../../../core/errors/failure.dart';
import '../../../core/messaging/chat_launcher.dart';
import '../../../core/messaging/messaging_repository.dart';

/// Screen 12 — one service: its detail, then its calendar.
///
/// A service that is no longer listed answers `SERVICE_NOT_FOUND`; that is
/// [isGone], a state of its own, not an error to retry.
class ServiceDetailViewModel extends BaseViewModel
    with MonthAvailability, ChatLauncher {
  ServiceDetailViewModel({
    required this.id,
    required this._catalog,
    required this._messaging,
    this._today = DateTime.now,
  }) {
    load();
  }

  final String id;
  final CatalogRepository _catalog;
  final MessagingRepository _messaging;

  @override
  MessagingRepository get chatMessaging => _messaging;
  final DateTime Function() _today;

  ServiceDetail? _service;
  bool _isLoading = false;
  bool _isGone = false;

  ServiceDetail? get service => _service;
  bool get isFirstLoad => _isLoading && _service == null;
  bool get isGone => _isGone;

  /// The provider takes bookings — the Request button and date picking.
  bool get canBook => _service?.provider.acceptingBookings ?? false;

  @override
  bool get canPickDates => canBook;

  @override
  DateTime today() => _today();

  @override
  Future<Availability> fetchMonth(DateTime month) =>
      _catalog.serviceAvailability(id, month);

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final ServiceDetail? service = await runGuarded(() => _catalog.service(id));
    final Failure? failure = this.failure;
    if (service != null) {
      _service = service;
    } else if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.serviceNotFound ||
            failure.statusCode == 404)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
    if (service != null) await showMonth(visibleMonth);
  }
}
