import 'dart:async';

import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/home/view_model/home_view_model.dart';
import 'package:eventor/features/shell/shell_badges.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeCatalogRepository catalog;
  late FakeAuthRepository auth;
  late SessionController session;
  late ShellBadges badges;
  late DateTime now;

  setUp(() {
    catalog = FakeCatalogRepository();
    auth = FakeAuthRepository();
    session = SessionController(auth)..signedIn(testUser());
    badges = ShellBadges();
    now = DateTime(2026, 9, 24, 19);
  });

  Future<HomeViewModel> build() async {
    final HomeViewModel viewModel = HomeViewModel(
      catalog: catalog,
      auth: auth,
      session: session,
      badges: badges,
      reference: FakeReferenceRepository(),
      now: () => now,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  group('HomeViewModel loading', () {
    test('loads the feed on start', () async {
      final HomeViewModel viewModel = await build();

      expect(viewModel.feed?.fullName, 'Amina Benali');
      expect(viewModel.isFirstLoad, isFalse);
      expect(viewModel.hasError, isFalse);
    });

    test('is a first load until the feed arrives', () async {
      catalog.gate = Completer<void>();
      final HomeViewModel viewModel = HomeViewModel(
        catalog: catalog,
        auth: auth,
        session: session,
        badges: badges,
        reference: FakeReferenceRepository(),
        now: () => now,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.isFirstLoad, isTrue);
      expect(viewModel.feed, isNull);

      catalog.gate!.complete();
      await flushAsync();
      expect(viewModel.isFirstLoad, isFalse);
    });

    test('reports a failed first load, with no feed', () async {
      catalog.homeError = const NetworkFailure();

      final HomeViewModel viewModel = await build();

      expect(viewModel.feed, isNull);
      expect(viewModel.failure, isA<NetworkFailure>());
    });

    test('tries again after a failure', () async {
      catalog.homeError = const NetworkFailure();
      final HomeViewModel viewModel = await build();

      catalog.homeError = null;
      await viewModel.load();

      expect(viewModel.feed, isNotNull);
      expect(viewModel.failure, isNull);
    });

    test('keeps the feed when a refresh fails, and says why', () async {
      final HomeViewModel viewModel = await build();
      catalog.homeError = const NetworkFailure();

      final Failure? failure = await viewModel.refresh();

      expect(failure, isA<NetworkFailure>());
      expect(viewModel.feed, isNotNull);
      expect(viewModel.hasError, isFalse);
    });

    test('puts the unread conversations on the nav', () async {
      await build();

      expect(badges.unreadConversations, 3);
    });
  });

  group('HomeViewModel greeting', () {
    Future<Greeting> at(int hour, int minute) async {
      now = DateTime(2026, 9, 24, hour, minute);
      return (await build()).greeting;
    }

    test('follows the clock', () async {
      expect(await at(4, 59), Greeting.evening);
      expect(await at(5, 0), Greeting.morning);
      expect(await at(11, 59), Greeting.morning);
      expect(await at(12, 0), Greeting.afternoon);
      expect(await at(17, 59), Greeting.afternoon);
      expect(await at(18, 0), Greeting.evening);
    });
  });

  group('HomeViewModel city', () {
    test('saves the city to the profile, then reloads', () async {
      final HomeViewModel viewModel = await build();
      final int loadsBefore = catalog.homeCalls;

      final Failure? failure = await viewModel.changeCity(31);

      expect(failure, isNull);
      expect(auth.wilayaUpdates, <int>[31]);
      expect(session.user?.wilaya?.code, 31);
      expect(catalog.homeCalls, loadsBefore + 1);
    });

    test('keeps the old city when saving fails', () async {
      final HomeViewModel viewModel = await build();
      auth.updateWilayaError = const NetworkFailure();
      final int loadsBefore = catalog.homeCalls;

      final Failure? failure = await viewModel.changeCity(31);

      expect(failure, isA<NetworkFailure>());
      expect(session.user?.wilaya, isNull);
      expect(catalog.homeCalls, loadsBefore);
      expect(viewModel.isChangingCity, isFalse);
    });

    test('offers the open wilayas', () async {
      final HomeViewModel viewModel = await build();

      final List<Wilaya> wilayas = await viewModel.wilayas();

      expect(wilayas, FakeReferenceRepository.sampleWilayas);
    });
  });
}
