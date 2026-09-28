import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/features/welcome/view_model/welcome_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await PreferencesService.load();
  });

  group('WelcomeViewModel', () {
    test('Welcome counts as unseen on a fresh install', () {
      expect(preferences.hasSeenWelcome, isFalse);
    });

    test('remembers that Welcome was seen', () async {
      final WelcomeViewModel viewModel = WelcomeViewModel(preferences);
      addTearDown(viewModel.dispose);

      await viewModel.markAsSeen();

      expect(preferences.hasSeenWelcome, isTrue);
      expect(viewModel.failure, isNull);
    });

    test('marking it twice is harmless', () async {
      // Back from role selection leaves Welcome open, so the other door can
      // still be taken after the first one was.
      final WelcomeViewModel viewModel = WelcomeViewModel(preferences);
      addTearDown(viewModel.dispose);

      await viewModel.markAsSeen();
      await viewModel.markAsSeen();

      expect(preferences.hasSeenWelcome, isTrue);
      expect(viewModel.failure, isNull);
    });
  });
}
