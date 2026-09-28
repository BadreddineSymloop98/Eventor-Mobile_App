import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/catalog/month_availability.dart';
import '../../../core/errors/failure.dart';

/// Screen 20 — one Ready Pack: its detail, then its calendar, where a day is
/// available only when every service in the pack is free.
///
/// "Request pack" opens B9 on the day picked here (section 9 decision 2).
class PackDetailViewModel extends BaseViewModel with MonthAvailability {
  PackDetailViewModel({
    required this.id,
    required this._catalog,
    this._today = DateTime.now,
  }) {
    load();
  }

  final String id;
  final CatalogRepository _catalog;
  final DateTime Function() _today;

  PackDetail? _pack;
  bool _isLoading = false;
  bool _isGone = false;

  PackDetail? get pack => _pack;
  bool get isFirstLoad => _isLoading && _pack == null;
  bool get isGone => _isGone;
  bool get canBook => _pack?.provider.acceptingBookings ?? false;

  @override
  bool get canPickDates => canBook;

  @override
  DateTime today() => _today();

  @override
  Future<Availability> fetchMonth(DateTime month) =>
      _catalog.packAvailability(id, month);

  Future<void> load() async {
    _isLoading = true;
    _isGone = false;
    notifyListeners();
    final PackDetail? pack = await runGuarded(() => _catalog.pack(id));
    final Failure? failure = this.failure;
    if (pack != null) {
      _pack = pack;
    } else if (failure is ApiFailure &&
        (failure.code == ApiErrorCode.packNotFound || failure.statusCode == 404)) {
      _isGone = true;
      clearFailure();
    }
    _isLoading = false;
    notifyListeners();
    if (pack != null) await showMonth(visibleMonth);
  }
}
