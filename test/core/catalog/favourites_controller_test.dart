import 'dart:async';

import 'package:eventor/core/catalog/favourites_controller.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const FavouriteTarget studio = FavouriteTarget.service('s-1');

  late FakeFavouritesRepository repository;
  late FavouritesController controller;
  late int notifications;

  setUp(() {
    repository = FakeFavouritesRepository();
    controller = FavouritesController(repository);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  group('FavouritesController', () {
    test('reads the card\'s own flag until something is toggled', () {
      expect(controller.isFavourite(studio, fallback: true), isTrue);
      expect(controller.isFavourite(studio, fallback: false), isFalse);
    });

    test('flips at once, before the server answers', () async {
      repository.gate = Completer<void>();

      final Future<Failure?> saving = controller.toggle(studio, current: false);

      expect(controller.isFavourite(studio, fallback: false), isTrue);
      expect(notifications, 1);

      repository.gate!.complete();
      expect(await saving, isNull);
      expect(repository.calls, <String>['add:$studio']);
    });

    test('un-saves through the repository', () async {
      await controller.toggle(studio, current: true);

      expect(controller.isFavourite(studio, fallback: true), isFalse);
      expect(repository.calls, <String>['remove:$studio']);
    });

    test('rolls back and reports a failure', () async {
      repository.failNext = const NetworkFailure();

      final Failure? failure = await controller.toggle(studio, current: false);

      expect(failure, isA<NetworkFailure>());
      expect(controller.isFavourite(studio, fallback: false), isFalse);
    });

    test('ends in the last tapped state when two taps overlap', () async {
      // Tap, tap again before the first answers, then the first fails: the
      // heart must show the second tap, and the server must see the two
      // requests in the order they were made.
      repository.gate = Completer<void>();
      repository.failNext = const NetworkFailure();

      final Future<Failure?> first = controller.toggle(studio, current: false);
      final Future<Failure?> second = controller.toggle(studio, current: true);
      expect(controller.isFavourite(studio, fallback: false), isFalse);

      repository.gate!.complete();
      // The older request failed, but a newer tap replaced it: no error for
      // a state the user already moved on from.
      expect(await first, isNull);
      expect(await second, isNull);

      expect(controller.isFavourite(studio, fallback: false), isFalse);
      expect(repository.calls, <String>['add:$studio', 'remove:$studio']);
    });

    test('returns to the last confirmed state when two overlapping taps both fail',
        () async {
      // Heart off; tap (add) then tap again (remove); the network drops both.
      // The server never saved it, so the heart must end empty — not on the
      // unconfirmed "saved" the second tap started from.
      repository.gate = Completer<void>();
      repository.failAll = const NetworkFailure();

      final Future<Failure?> first = controller.toggle(studio, current: false);
      final Future<Failure?> second = controller.toggle(studio, current: true);
      repository.gate!.complete();

      expect(await first, isNull);
      expect(await second, isA<NetworkFailure>());
      expect(controller.isFavourite(studio, fallback: false), isFalse);
    });

    test('rolls back to what the server last confirmed, not the tap before',
        () async {
      // A save lands, then a later removal fails: the heart stays saved.
      await controller.toggle(studio, current: false);
      repository.failNext = const NetworkFailure();

      await controller.toggle(studio, current: true);

      expect(controller.isFavourite(studio, fallback: false), isTrue);
    });

    test('moves the version on when a save lands, so lists can reload', () async {
      final int before = controller.version;

      await controller.toggle(studio, current: false);

      expect(controller.version, greaterThan(before));
    });

    test('keeps the version when a save fails', () async {
      repository.failNext = const NetworkFailure();
      final int before = controller.version;

      await controller.toggle(studio, current: false);

      expect(controller.version, before);
    });

    test('forgets everything on clear — the next account starts fresh', () async {
      await controller.toggle(studio, current: false);

      controller.clear();

      expect(controller.isFavourite(studio, fallback: false), isFalse);
    });

    test('records a removal made elsewhere', () {
      controller.markRemoved(studio);

      expect(controller.isFavourite(studio, fallback: true), isFalse);
    });
  });
}
