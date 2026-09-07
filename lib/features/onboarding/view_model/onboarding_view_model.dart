import 'package:flutter/widgets.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/errors/failure.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/services/preferences_service.dart';
import '../model/onboarding_section.dart';

/// Drives the onboarding flow.
///
/// It owns the sections, which one is showing, and the [PageController] that
/// moves between them — so the view only has to render what it is told.
class OnboardingViewModel extends BaseViewModel {
  OnboardingViewModel(this._preferences);

  /// The pages of the flow, in order.
  static const List<OnboardingSection> sections = OnboardingSection.values;

  static const Duration _transitionDuration = Duration(milliseconds: 300);
  static const Curve _transitionCurve = Curves.easeOut;

  final PreferencesService _preferences;
  final PageController pageController = PageController();

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  int get sectionCount => sections.length;
  bool get isLastSection => _currentIndex == sectionCount - 1;

  /// Called by the view when the user swipes to another section.
  void onSectionChanged(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  /// Advances to the next section, or finishes onboarding on the last one.
  ///
  /// Returns the route to leave for, or `null` while onboarding continues.
  Future<String?> goToNextSection() async {
    if (isLastSection) return finish();

    // Guarded because the controller has no page to animate until a PageView
    // is attached to it.
    if (pageController.hasClients) {
      await pageController.nextPage(
        duration: _transitionDuration,
        curve: _transitionCurve,
      );
    }
    return null;
  }

  /// Marks onboarding as completed and returns the route to continue with.
  ///
  /// A storage failure is recorded but does not hold the user back: the worst
  /// it costs them is seeing onboarding once more on the next launch.
  Future<String> finish() async {
    await runGuarded(
      _preferences.markOnboardingAsSeen,
      onError: (Object error) => StorageFailure(cause: error),
    );
    return AppRoutes.welcome;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
