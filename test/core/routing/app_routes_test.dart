import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes', () {
    test('opens on the splash', () {
      // The splash covers the moment the app is deciding where to go, so it
      // cannot itself be chosen by that decision.
      expect(AppRoutes.splash, '/');
    });

    test('keeps the invite path the email links to', () {
      // An admin's invite email opens `${APP_PUBLIC_URL}/set-password`; the
      // path is a contract with the backend, not a name the app may change.
      expect(AppRoutes.setPassword, '/set-password');
    });

    group('public', () {
      test('holds every pre-auth screen', () {
        expect(
          AppRoutes.public,
          containsAll(<String>[
            AppRoutes.onboarding,
            AppRoutes.welcome,
            AppRoutes.roleSelection,
            AppRoutes.register,
            AppRoutes.verifyEmail,
            AppRoutes.login,
            AppRoutes.forgotPassword,
            AppRoutes.resetCode,
            AppRoutes.resetPassword,
            AppRoutes.setPassword,
          ]),
        );
      });

      test('holds none of the signed-in screens', () {
        expect(AppRoutes.public, isNot(contains(AppRoutes.home)));
        expect(AppRoutes.public, isNot(contains(AppRoutes.documents)));
      });

      test('leaves the splash out', () {
        // The splash is handled before the public check ever runs.
        expect(AppRoutes.public, isNot(contains(AppRoutes.splash)));
      });
    });

    group('registerFor', () {
      test('carries the role in its API spelling', () {
        expect(AppRoutes.registerFor(UserRole.client), '/register?role=client');
        expect(
          AppRoutes.registerFor(UserRole.provider),
          '/register?role=provider',
        );
      });

      test('round-trips through UserRole.fromApi', () {
        for (final UserRole role in UserRole.values) {
          final Uri uri = Uri.parse(AppRoutes.registerFor(role));

          expect(uri.path, AppRoutes.register);
          expect(UserRole.fromApi(uri.queryParameters['role']), role);
        }
      });
    });

    group('loginWith', () {
      test('is plain login with nothing to carry', () {
        final Uri uri = Uri.parse(AppRoutes.loginWith());

        expect(uri.path, AppRoutes.login);
        expect(uri.queryParameters, isEmpty);
      });

      test('has no dangling "?" when there is nothing to carry', () {
        // Parsing forgives "/login?", so the raw string is what pins it.
        expect(AppRoutes.loginWith(), AppRoutes.login);
      });

      test('prefills the email, encoded', () {
        final String location = AppRoutes.loginWith(email: 'a+b@example.com');
        final Uri uri = Uri.parse(location);

        // A raw `+` in a query reads back as a space, so it must be escaped.
        expect(location, isNot(contains('+')));
        expect(uri.queryParameters, <String, String>{'email': 'a+b@example.com'});
      });

      test('skips an empty email', () {
        expect(
          Uri.parse(AppRoutes.loginWith(email: '')).queryParameters,
          isEmpty,
        );
      });

      test('announces a finished reset', () {
        final Uri uri = Uri.parse(
          AppRoutes.loginWith(email: 'amina@example.com', afterReset: true),
        );

        expect(uri.queryParameters, <String, String>{
          'email': 'amina@example.com',
          'reset': '1',
        });
      });
    });

    group('resetCodeFor', () {
      test('carries the email the code went to', () {
        final Uri uri = Uri.parse(AppRoutes.resetCodeFor('amina@example.com'));

        expect(uri.path, AppRoutes.resetCode);
        expect(uri.queryParameters['email'], 'amina@example.com');
      });
    });
  });
}
