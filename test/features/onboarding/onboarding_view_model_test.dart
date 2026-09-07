import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/features/onboarding/view_model/onboarding_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService preferences;
  late OnboardingViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await PreferencesService.load();
    viewModel = OnboardingViewModel(preferences);
  });

  tearDown(() => viewModel.dispose());

  group('OnboardingViewModel', () {
    test('starts on the first of three sections', () {
      expect(viewModel.sectionCount, 3);
      expect(viewModel.currentIndex, 0);
      expect(viewModel.isLastSection, isFalse);
    });

    test('tracks the section the user swiped to', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.onSectionChanged(2);

      expect(viewModel.currentIndex, 2);
      expect(viewModel.isLastSection, isTrue);
      expect(notifications, 1);
    });

    test('ignores a change to the section already showing', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.onSectionChanged(0);

      expect(notifications, 0);
    });

    test('stays in onboarding while sections remain', () async {
      expect(await viewModel.goToNextSection(), isNull);
      expect(preferences.hasSeenOnboarding, isFalse);
    });

    test('leaves for the welcome screen from the last section', () async {
      viewModel.onSectionChanged(2);

      expect(await viewModel.goToNextSection(), AppRoutes.welcome);
      expect(preferences.hasSeenOnboarding, isTrue);
    });

    test('skipping records onboarding as seen', () async {
      expect(await viewModel.finish(), AppRoutes.welcome);
      expect(preferences.hasSeenOnboarding, isTrue);
      expect(viewModel.hasError, isFalse);
    });
  });
}
