import '../../../core/base/base_view_model.dart';
import '../../../core/catalog/catalog_repository.dart';
import '../../../core/catalog/models/catalog_models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/reference/reference_repository.dart';
import '../../../core/session/session_controller.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../shell/shell_badges.dart';

/// Which greeting the header shows — worded by the view.
enum Greeting { morning, afternoon, evening }

/// Screen 11: the client's Home, from one `/app/home` call.
///
/// A first load shows the design's skeleton; a failed one, the error card. A
/// refresh keeps what is on screen and only reports when it fails. Changing
/// the city saves it to the profile — the API's "near you" follows the
/// profile — and reloads.
class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required this._catalog,
    required this._auth,
    required this._session,
    required this._badges,
    required this._reference,
    this._now = DateTime.now,
  }) {
    load();
  }

  final CatalogRepository _catalog;
  final AuthRepository _auth;
  final SessionController _session;
  final ShellBadges _badges;
  final ReferenceRepository _reference;
  final DateTime Function() _now;

  HomeFeed? _feed;
  bool _isLoading = false;
  bool _isChangingCity = false;

  HomeFeed? get feed => _feed;

  /// Nothing to show yet — the skeleton.
  bool get isFirstLoad => _feed == null && _isLoading;

  bool get isChangingCity => _isChangingCity;

  /// The signed-in name, for the header before the feed arrives.
  String get fullName => _feed?.fullName ?? _session.user?.fullName ?? '';

  /// The city on the pill, before the feed arrives too.
  Wilaya? get city => _feed?.wilaya ?? _session.user?.wilaya;

  /// Morning from 05:00, afternoon from 12:00, evening from 18:00.
  Greeting get greeting {
    final int hour = _now().hour;
    if (hour >= 5 && hour < 12) return Greeting.morning;
    if (hour >= 12 && hour < 18) return Greeting.afternoon;
    return Greeting.evening;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final HomeFeed? feed = await runGuarded(_catalog.home);
    if (feed != null) _apply(feed);
    _isLoading = false;
    notifyListeners();
  }

  /// Pull to refresh. The feed on screen stays when this fails; the failure
  /// is returned for a toast instead of replacing the content.
  Future<Failure?> refresh() async {
    try {
      _apply(await _catalog.home());
      notifyListeners();
      return null;
    } on Failure catch (failure) {
      return failure;
    } catch (error) {
      return UnexpectedFailure(cause: error);
    }
  }

  /// The wilayas the city sheet lists — the open ones.
  Future<List<Wilaya>> wilayas() => _reference.wilayas();

  /// Saves [wilayaCode] as the client's city and reloads Home for it.
  Future<Failure?> changeCity(int wilayaCode) async {
    if (_isChangingCity) return null;
    _isChangingCity = true;
    notifyListeners();
    try {
      _session.updateUser(await _auth.updateWilaya(wilayaCode));
    } on Failure catch (failure) {
      _isChangingCity = false;
      notifyListeners();
      return failure;
    }
    await load();
    _isChangingCity = false;
    notifyListeners();
    return null;
  }

  void _apply(HomeFeed feed) {
    _feed = feed;
    _badges.update(unreadConversations: feed.unreadConversations);
  }
}
