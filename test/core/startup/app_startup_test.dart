import 'dart:async';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/core/startup/app_startup.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// Counts restores, and holds each one until [gate] is completed when set.
class _SlowAuth extends FakeAuthRepository {
  int restores = 0;
  Completer<void>? restoreGate;

  @override
  Future<AppUser?> restoreSession() async {
    restores++;
    await restoreGate?.future;
    return restoredUser;
  }
}

/// Counts loads of the config.
class _CountingConfig extends FakeConfigRepository {
  _CountingConfig(super.config);

  int loads = 0;

  @override
  Future<AppConfig> load() async {
    loads++;
    return config;
  }
}

void main() {
  late _SlowAuth auth;
  late _CountingConfig config;
  late SessionController session;
  late AppStartup startup;
  late int notifications;

  setUp(() {
    auth = _SlowAuth();
    config = _CountingConfig(const AppConfig());
    session = SessionController(auth);
    startup = AppStartup(config: config, session: session);
    notifications = 0;
    startup.addListener(() => notifications++);
  });

  tearDown(() {
    startup.dispose();
    session.dispose();
  });

  group('AppStartup', () {
    test('is not ready until it has run', () {
      expect(startup.isReady, isFalse);
    });

    test('loads the config and restores the session', () async {
      auth.restoredUser = testUser();

      await startup.run(floor: Duration.zero);

      expect(config.loads, 1);
      expect(auth.restores, 1);
      expect(session.isSignedIn, isTrue);
      expect(startup.isReady, isTrue);
      expect(notifications, 1);
    });

    test('becomes ready signed out when there is no session', () async {
      await startup.run(floor: Duration.zero);

      expect(startup.isReady, isTrue);
      expect(session.status, SessionStatus.signedOut);
    });

    test('runs only once', () async {
      await startup.run(floor: Duration.zero);
      await startup.run(floor: Duration.zero);

      expect(config.loads, 1);
      expect(auth.restores, 1);
      expect(notifications, 1);
    });

    testWidgets('keeps the splash up for at least the floor',
        (WidgetTester tester) async {
      // Restoring is instant here; the brand should still be seen rather
      // than flashed.
      final Future<void> running = startup.run(
        floor: const Duration(seconds: 1),
      );

      await tester.pump(const Duration(milliseconds: 900));
      expect(startup.isReady, isFalse);

      await tester.pump(const Duration(milliseconds: 200));
      expect(startup.isReady, isTrue);
      await running;
    });

    testWidgets('holds the splash longer for a slow restore',
        (WidgetTester tester) async {
      auth.restoreGate = Completer<void>();
      final Future<void> running = startup.run(
        floor: const Duration(milliseconds: 100),
      );

      await tester.pump(const Duration(seconds: 5));
      expect(startup.isReady, isFalse);

      auth.restoreGate!.complete();
      await tester.pump();
      expect(startup.isReady, isTrue);
      await running;
    });

    test('uses the default floor unless told otherwise', () {
      expect(AppStartup.minimumVisible, greaterThan(Duration.zero));
    });
  });
}
