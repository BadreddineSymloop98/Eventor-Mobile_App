import '../../../core/base/base_view_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/services/preferences_service.dart';

/// Drives the splash screen.
///
/// The splash exists to cover the moment the app is deciding where to send the
/// user, so that decision lives here rather than in the view.
class SplashViewModel extends BaseViewModel {
  SplashViewModel(this._preferences);

  /// How long the splash is held before handing over.
  ///
  /// Right now there is nothing to wait *for* — the preference it reads was
  /// loaded before the first frame — so this is purely so the brand is seen
  /// rather than flashed. Once a session has to be restored from secure
  /// storage, this becomes a floor under real work instead of a delay of its
  /// own: whichever of the two takes longer, wins.
  static const Duration _minimumVisible = Duration(milliseconds: 1600);

  final PreferencesService _preferences;

  /// Where to go once the splash is done, having waited [_minimumVisible].
  Future<String> resolveNextRoute() async {
    await Future<void>.delayed(_minimumVisible);

    return AppRoutes.afterSplash(
      hasSeenOnboarding: _preferences.hasSeenOnboarding,
    );
  }
}
