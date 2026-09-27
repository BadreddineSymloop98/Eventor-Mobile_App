import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_router.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/core/startup/app_startup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';

/// Everything [AppRedirect] reads, on fakes.
class _World {
  _World(this.redirect, this.session, this.startup);

  final AppRedirect redirect;
  final SessionController session;
  final AppStartup startup;

  String? go(String location) => redirect(Uri.parse(location));
}

/// Builds the redirect in a known state.
///
/// [ready] runs startup to completion; [user] is the session it restores.
Future<_World> _world({
  bool ready = true,
  bool hasSeenOnboarding = true,
  bool hasSeenWelcome = false,
  AppUser? user,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'has_seen_onboarding': hasSeenOnboarding,
    'has_seen_welcome': hasSeenWelcome,
  });
  final PreferencesService preferences = await PreferencesService.load();
  final FakeAuthRepository auth = FakeAuthRepository()..restoredUser = user;
  final SessionController session = SessionController(auth);
  final AppStartup startup = AppStartup(
    config: FakeConfigRepository(),
    session: session,
  );
  if (ready) await startup.run(floor: Duration.zero);

  return _World(
    AppRedirect(
      startup: startup,
      session: session,
      preferences: preferences,
    ),
    session,
    startup,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRedirect before startup is done', () {
    test('lets the splash show', () async {
      final _World world = await _world(ready: false);

      expect(world.go(AppRoutes.splash), isNull);
    });

    test('holds every other path on the splash, remembering it', () async {
      final _World world = await _world(ready: false);

      final Uri held = Uri.parse(world.go(AppRoutes.home)!);

      expect(held.path, AppRoutes.splash);
      expect(held.queryParameters['next'], AppRoutes.home);
    });

    test('remembers a deep link whole, query and all', () async {
      final _World world = await _world(ready: false);

      final Uri held = Uri.parse(world.go('/set-password?token=abc')!);

      expect(held.path, AppRoutes.splash);
      expect(held.queryParameters['next'], '/set-password?token=abc');
    });
  });

  group('AppRedirect leaving the splash', () {
    test('goes to onboarding on the first launch', () async {
      final _World world = await _world(hasSeenOnboarding: false);

      expect(world.go(AppRoutes.splash), AppRoutes.onboarding);
    });

    test('goes to Welcome once onboarding has been seen', () async {
      // Welcome, not login: it is the design's landing point for a newcomer,
      // and logging in is one of the two choices on it.
      final _World world = await _world();

      expect(world.go(AppRoutes.splash), AppRoutes.welcome);
    });

    test('goes straight to Login once Welcome has been seen too', () async {
      final _World world = await _world(hasSeenWelcome: true);

      expect(world.go(AppRoutes.splash), AppRoutes.login);
    });

    test('still shows onboarding first, whatever Welcome says', () async {
      final _World world = await _world(
        hasSeenOnboarding: false,
        hasSeenWelcome: true,
      );

      expect(world.go(AppRoutes.splash), AppRoutes.onboarding);
    });

    test('goes home with a restored session', () async {
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.splash), AppRoutes.home);
    });

    test('skips onboarding for a signed-in user, even the first time',
        () async {
      final _World world = await _world(
        hasSeenOnboarding: false,
        user: testUser(),
      );

      expect(world.go(AppRoutes.splash), AppRoutes.home);
    });

    test('honours an invite link that arrived during startup', () async {
      final _World world = await _world(ready: false);
      final String held = world.go('/set-password?token=abc')!;

      await world.startup.run(floor: Duration.zero);

      expect(world.go(held), '/set-password?token=abc');
    });

    test('lands normally for any other remembered path', () async {
      // Only the invite link is worth resuming; a cold start on /home with
      // no session should not bounce through it.
      final _World world = await _world(ready: false);
      final String held = world.go(AppRoutes.home)!;

      await world.startup.run(floor: Duration.zero);

      expect(world.go(held), AppRoutes.welcome);
    });
  });

  group('AppRedirect with a session', () {
    test('sends the user to a one-off landing', () async {
      final _World world = await _world();
      world.session.signedIn(
        testUser(role: UserRole.provider),
        landing: AppRoutes.documents,
      );

      expect(world.go(AppRoutes.login), AppRoutes.documents);
    });

    test('keeps the landing across repeated evaluations', () async {
      // go_router can run the redirect more than once for one change; a
      // landing consumed on the first pass would send the second one home.
      final _World world = await _world();
      world.session.signedIn(
        testUser(role: UserRole.provider),
        landing: AppRoutes.documents,
      );

      expect(world.go(AppRoutes.login), AppRoutes.documents);
      expect(world.go(AppRoutes.login), AppRoutes.documents);
      expect(world.go(AppRoutes.splash), AppRoutes.documents);
    });

    test('retires the landing once the user reaches it', () async {
      final _World world = await _world();
      world.session.signedIn(
        testUser(role: UserRole.provider),
        landing: AppRoutes.documents,
      );

      expect(world.go(AppRoutes.documents), isNull);

      expect(world.session.landing, isNull);
      // A provider's home, not the client's.
      expect(world.go(AppRoutes.login), AppRoutes.providerHome);
    });

    test('keeps the landing while the user is elsewhere', () async {
      final _World world = await _world();
      world.session.signedIn(
        testUser(role: UserRole.provider),
        landing: AppRoutes.documents,
      );

      expect(world.go(AppRoutes.providerHome), isNull);

      expect(world.session.landing, AppRoutes.documents);
    });

    test('forgets the landing on sign-out', () async {
      final _World world = await _world();
      world.session.signedIn(
        testUser(role: UserRole.provider),
        landing: AppRoutes.documents,
      );
      await world.session.signOut();
      world.session.signedIn(testUser(role: UserRole.provider));

      expect(world.go(AppRoutes.login), AppRoutes.providerHome);
    });

    test('keeps a signed-in user off the pre-auth screens', () async {
      final _World world = await _world(user: testUser());

      for (final String path in <String>[
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.onboarding,
        AppRoutes.forgotPassword,
      ]) {
        expect(world.go(path), AppRoutes.home, reason: path);
      }
    });

    test('lets a signed-in user be where they are', () async {
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.home), isNull);
    });

    test('lets a provider reach their documents', () async {
      final _World world = await _world(
        user: testUser(role: UserRole.provider),
      );

      expect(world.go(AppRoutes.documents), isNull);
    });

    test('turns a client away from the documents screen', () async {
      // A client has no documents to upload.
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.documents), AppRoutes.home);
    });

    test('sends a signed-in user who follows an invite link home', () async {
      final _World world = await _world(ready: false);
      final String held = world.go('/set-password?token=abc')!;
      await world.startup.run(floor: Duration.zero);
      world.session.signedIn(testUser());

      final String resumed = world.go(held)!;

      expect(resumed, '/set-password?token=abc');
      expect(world.go(resumed), AppRoutes.home);
    });
  });

  group('AppRedirect with two homes', () {
    test('lands a client on the client shell', () async {
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.splash), AppRoutes.home);
    });

    test('lands a provider on their placeholder home', () async {
      final _World world = await _world(user: testUser(role: UserRole.provider));

      expect(world.go(AppRoutes.splash), AppRoutes.providerHome);
    });

    test('keeps a provider out of every client screen', () async {
      final _World world = await _world(user: testUser(role: UserRole.provider));

      for (final String path in <String>[
        AppRoutes.home,
        AppRoutes.search,
        AppRoutes.results,
        AppRoutes.homeResults,
        AppRoutes.bookings,
        AppRoutes.messages,
        AppRoutes.profile,
        AppRoutes.serviceFor('s-1'),
        AppRoutes.providerFor('p-1'),
        AppRoutes.packs,
        AppRoutes.packFor('k-1'),
        AppRoutes.favourites,
        AppRoutes.budget,
        AppRoutes.budgetEdit,
      ]) {
        expect(world.go(path), AppRoutes.providerHome, reason: path);
      }
    });

    test('lets a provider into chat, the bell and their own tabs', () async {
      final _World world = await _world(user: testUser(role: UserRole.provider));

      for (final String path in <String>[
        AppRoutes.chatFor('x'),
        AppRoutes.notifications,
        AppRoutes.providerRequests,
        AppRoutes.providerMessages,
        AppRoutes.providerProfile,
        AppRoutes.resubmitDocuments,
      ]) {
        expect(world.go(path), isNull, reason: path);
      }
    });

    test('keeps a client out of every provider screen', () async {
      final _World world = await _world(user: testUser());

      for (final String path in <String>[
        AppRoutes.providerRequests,
        AppRoutes.providerMessages,
        AppRoutes.documents,
        AppRoutes.resubmitDocuments,
      ]) {
        expect(world.go(path), AppRoutes.home, reason: path);
      }
    });

    test('keeps a client out of the provider home', () async {
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.providerHome), AppRoutes.home);
    });

    test('lets a client open the catalog', () async {
      final _World world = await _world(user: testUser());

      expect(world.go(AppRoutes.serviceFor('s-1')), isNull);
      expect(world.go(AppRoutes.packs), isNull);
      expect(world.go('${AppRoutes.results}?q=photo'), isNull);
    });

    test('does not mistake the providers catalog for the provider home', () {
      expect(AppRoutes.isClientOnly(AppRoutes.providerFor('p-1')), isTrue);
      expect(AppRoutes.isClientOnly(AppRoutes.providerHome), isFalse);
    });
  });

  group('AppRedirect without a session', () {
    test('lets the public screens through', () async {
      final _World world = await _world();

      for (final String path in AppRoutes.public) {
        expect(world.go(path), isNull, reason: path);
      }
    });

    test('lets a public screen through with its query', () async {
      final _World world = await _world();

      expect(world.go('/login?email=amina%40example.com'), isNull);
    });

    test('sends a private path to Welcome', () async {
      final _World world = await _world();

      expect(world.go(AppRoutes.home), AppRoutes.welcome);
      expect(world.go(AppRoutes.documents), AppRoutes.welcome);
    });

    test('sends an unknown path to Welcome too', () async {
      final _World world = await _world();

      expect(world.go('/no-such-screen'), AppRoutes.welcome);
    });

    test('sends a private path to Login once Welcome has been seen', () async {
      final _World world = await _world(hasSeenWelcome: true);

      expect(world.go(AppRoutes.home), AppRoutes.login);
      expect(world.go(AppRoutes.documents), AppRoutes.login);
    });

    test('still lets Welcome through once it has been seen', () async {
      // Seen once means it is no longer the landing — not that it is barred.
      final _World world = await _world(hasSeenWelcome: true);

      expect(world.go(AppRoutes.welcome), isNull);
    });

    test('lands a deliberate sign-out on Login once Welcome was seen',
        () async {
      final _World world = await _world(
        hasSeenWelcome: true,
        user: testUser(),
      );

      await world.session.signOut();

      expect(world.go(AppRoutes.home), AppRoutes.login);
    });

    test('says so on Login when the session died mid-use', () async {
      final _World world = await _world(user: testUser());

      world.session.expire();
      final Uri uri = Uri.parse(world.go(AppRoutes.home)!);

      expect(uri.path, AppRoutes.login);
      expect(uri.queryParameters[AppRedirect.expiredKey], '1');
    });

    test('says it only once', () async {
      final _World world = await _world(user: testUser());

      world.session.expire();
      world.go(AppRoutes.home);

      expect(world.go(AppRoutes.home), AppRoutes.welcome);
    });

    test('does not call a deliberate sign-out an expiry', () async {
      final _World world = await _world(user: testUser());

      await world.session.signOut();

      expect(world.go(AppRoutes.home), AppRoutes.welcome);
    });
  });

  group('AppRedirect for the gallery', () {
    test('lets it through in every state', () async {
      final _World starting = await _world(ready: false);
      final _World signedOut = await _world();
      final _World signedIn = await _world(user: testUser());

      expect(starting.go(AppRoutes.gallery), isNull);
      expect(signedOut.go(AppRoutes.gallery), isNull);
      expect(signedIn.go(AppRoutes.gallery), isNull);
    });
  });
}
