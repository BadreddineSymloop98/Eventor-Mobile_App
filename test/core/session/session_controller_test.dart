import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// An auth repository whose stored session cannot be read.
class _BrokenRestoreAuth extends FakeAuthRepository {
  @override
  Future<AppUser?> restoreSession() async => throw const NetworkFailure();
}

/// An auth repository whose account refresh fails.
class _BrokenCurrentUserAuth extends FakeAuthRepository {
  @override
  Future<AppUser> currentUser() async => throw const NetworkFailure();
}

void main() {
  late FakeAuthRepository auth;
  late SessionController session;
  late int notifications;

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionController(auth);
    notifications = 0;
    session.addListener(() => notifications++);
  });

  tearDown(() => session.dispose());

  group('SessionController', () {
    test('starts undecided', () {
      // The splash covers this state; nothing routes on it.
      expect(session.status, SessionStatus.unknown);
      expect(session.isSignedIn, isFalse);
      expect(session.user, isNull);
    });

    group('restore', () {
      test('signs in with a stored session', () async {
        final AppUser user = testUser();
        auth.restoredUser = user;

        await session.restore();

        expect(session.status, SessionStatus.signedIn);
        expect(session.user, same(user));
        expect(notifications, 1);
      });

      test('settles on signed out when there is none', () async {
        await session.restore();

        expect(session.status, SessionStatus.signedOut);
        expect(session.user, isNull);
        expect(notifications, 1);
      });

      test('settles on signed out rather than throwing', () async {
        final SessionController broken =
            SessionController(_BrokenRestoreAuth());
        addTearDown(broken.dispose);

        await broken.restore();

        expect(broken.status, SessionStatus.signedOut);
      });
    });

    group('signedIn', () {
      test('signs the user in and tells the router', () {
        session.signedIn(testUser());

        expect(session.isSignedIn, isTrue);
        expect(notifications, 1);
      });

      test('holds a one-off landing through repeated reads', () {
        // The router may evaluate its redirect several times for one change;
        // every evaluation has to see the same answer.
        session.signedIn(
          testUser(role: UserRole.provider),
          landing: '/documents',
        );

        expect(session.landing, '/documents');
        expect(session.landing, '/documents');
      });

      test('has no landing unless one was given', () {
        session.signedIn(testUser());

        expect(session.landing, isNull);
      });

      test('replaces a landing left over from an earlier sign-in', () {
        session.signedIn(testUser(), landing: '/documents');
        session.signedIn(testUser());

        expect(session.landing, isNull);
      });
    });

    group('arrivedAt', () {
      setUp(() => session.signedIn(
            testUser(role: UserRole.provider),
            landing: '/documents',
          ));

      test('retires the landing once the user is there', () {
        session.arrivedAt('/documents');

        expect(session.landing, isNull);
      });

      test('keeps it while the user is anywhere else', () {
        session.arrivedAt('/home');

        expect(session.landing, '/documents');
      });

      test('says nothing to listeners', () {
        // It is called from inside the redirect; a notification there would
        // make the router re-enter itself.
        final int before = notifications;

        session.arrivedAt('/documents');

        expect(notifications, before);
      });
    });

    group('the landing', () {
      test('does not outlive a sign-out', () async {
        session.signedIn(testUser(), landing: '/documents');

        await session.signOut();

        expect(session.landing, isNull);
      });

      test('does not outlive an expiry', () {
        session.signedIn(testUser(), landing: '/documents');

        session.expire();

        expect(session.landing, isNull);
      });
    });

    group('signOut', () {
      test('ends the session on the server and here', () async {
        session.signedIn(testUser());

        await session.signOut();

        expect(auth.logoutCalls, 1);
        expect(session.status, SessionStatus.signedOut);
        expect(session.user, isNull);
      });

      test('is not an expiry', () async {
        session.signedIn(testUser());

        await session.signOut();

        expect(session.consumeExpired(), isFalse);
      });
    });

    group('expire', () {
      test('signs out and remembers why, once', () {
        session.signedIn(testUser());

        session.expire();

        expect(session.status, SessionStatus.signedOut);
        expect(session.consumeExpired(), isTrue);
        expect(session.consumeExpired(), isFalse);
      });

      test('does nothing when nobody was signed in', () async {
        // A refused refresh during the startup restore is not a session that
        // "ended" — the user never had one this launch.
        await session.restore();
        final int before = notifications;

        session.expire();

        expect(session.consumeExpired(), isFalse);
        expect(notifications, before);
      });
    });

    group('refreshUser', () {
      test('re-reads the account', () async {
        session.signedIn(testUser(role: UserRole.provider));
        auth.user = testUser(
          role: UserRole.provider,
          verificationStatus: VerificationStatus.verified,
        );

        await session.refreshUser();

        expect(
          session.user?.verificationStatus,
          VerificationStatus.verified,
        );
      });

      test('does nothing while signed out', () async {
        await session.restore();

        await session.refreshUser();

        expect(session.isSignedIn, isFalse);
      });

      test('keeps the account it has when the read fails', () async {
        final SessionController broken =
            SessionController(_BrokenCurrentUserAuth());
        addTearDown(broken.dispose);
        final AppUser user = testUser();
        broken.signedIn(user);

        await broken.refreshUser();

        expect(broken.user, same(user));
        expect(broken.isSignedIn, isTrue);
      });
    });

    group('updateUser', () {
      test('replaces the signed-in account and says so', () async {
        session.signedIn(testUser());
        notifications = 0;
        const Wilaya oran = Wilaya(code: 31, nameEn: 'Oran', nameAr: 'وهران');

        session.updateUser(testUser(wilaya: oran));

        expect(session.user?.wilaya, oran);
        expect(notifications, 1);
      });

      test('does nothing once signed out', () async {
        await session.restore();
        notifications = 0;

        session.updateUser(testUser());

        expect(session.isSignedIn, isFalse);
        expect(notifications, 0);
      });
    });
  });
}
