import 'package:eventor/core/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes', () {
    test('always opens on the splash', () {
      // The splash covers the moment the app is deciding where to go, so it
      // cannot itself be chosen by that decision.
      expect(AppRoutes.initial, AppRoutes.splash);
    });

    group('afterSplash', () {
      test('goes to onboarding on the first launch', () {
        expect(
          AppRoutes.afterSplash(hasSeenOnboarding: false),
          AppRoutes.onboarding,
        );
      });

      test('skips onboarding once it has been completed', () {
        expect(
          AppRoutes.afterSplash(hasSeenOnboarding: true),
          AppRoutes.login,
        );
      });
    });
  });
}
