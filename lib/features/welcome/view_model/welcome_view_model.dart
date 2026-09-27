import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/services/preferences_service.dart';

/// Remembers that Welcome has done its job.
///
/// Welcome only asks a newcomer which door they want — create an account or
/// log in. Once they have taken either, it has nothing left to say, so the
/// next signed-out launch opens on Login, like onboarding is shown only once.
class WelcomeViewModel extends BaseViewModel {
  WelcomeViewModel(this._preferences);

  final PreferencesService _preferences;

  /// Called when the user takes either door.
  ///
  /// A storage failure is recorded but does not hold the user back: the worst
  /// it costs them is seeing Welcome once more on the next launch.
  Future<void> markAsSeen() async {
    if (_preferences.hasSeenWelcome) return;
    await runGuarded(
      _preferences.markWelcomeAsSeen,
      onError: (Object error) => StorageFailure(cause: error),
    );
  }
}
