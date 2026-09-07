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

      test('lands on welcome once onboarding has been completed', () {
        // Welcome, not login: it is the design's landing point for anyone
        // without a session, and logging in is one of the two choices it
        // offers rather than the default one.
        expect(
          AppRoutes.afterSplash(hasSeenOnboarding: true),
          AppRoutes.welcome,
        );
      });
    });
  });
}
