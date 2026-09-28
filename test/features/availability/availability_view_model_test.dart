import 'dart:async';

import 'package:eventor/core/availability/availability_repository.dart';
import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/provider/models/provider_home.dart';
import 'package:eventor/features/availability/view_model/availability_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/availability_fakes.dart';
import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  // Tuesday 10 March 2026, mid-morning.
  final DateTime now = DateTime(2026, 3, 10, 9, 30);
  final DateTime blockedDay = DateTime(2026, 3, 14);
  final DateTime slotDay = DateTime(2026, 3, 21);
  final DateTime heldDay = DateTime(2026, 3, 18);
  final DateTime bookedDay = DateTime(2026, 3, 26);

  late FakeAvailabilityRepository repository;
  late int serviceLoads;
  late List<AvailabilityViewModel> models;

  FakeAvailabilityRepository seeded() => FakeAvailabilityRepository(
        items: <Map<String, Object?>>[
          blockItemJson(id: 'b-whole', date: blockedDay),
          blockItemJson(
            id: 'b-slot',
            date: slotDay,
            startTime: '14:00',
            endTime: '18:00',
            serviceId: 'svc-1',
            note: 'Family wedding',
          ),
          bookingItemJson(bookingId: 'bk-held', date: heldDay, accepted: false),
          bookingItemJson(bookingId: 'bk-booked', date: bookedDay),
        ],
      );

  AvailabilityViewModel build({
    Future<List<ProviderServiceRow>> Function()? loadServices,
    AppConfig config = const AppConfig(bookingMinNoticeDays: 3),
  }) {
    final AvailabilityViewModel model = AvailabilityViewModel(
      availability: repository,
      loadServices: loadServices ??
          () async {
            serviceLoads++;
            return <ProviderServiceRow>[
              testServiceRow('svc-1', 'Grande salle'),
              testServiceRow('svc-2', 'Menu mariage'),
            ];
          },
      config: config,
      today: () => now,
    );
    models.add(model);
    return model;
  }

  setUp(() {
    repository = seeded();
    serviceLoads = 0;
    models = <AvailabilityViewModel>[];
  });

  tearDown(() {
    for (final AvailabilityViewModel model in models) {
      model.dispose();
    }
  });

  group('the month', () {
    test('opens on this month with a skeleton, then its days', () async {
      repository.monthGate = Completer<void>();
      final AvailabilityViewModel model = build();

      expect(model.visibleMonth, DateTime(2026, 3));
      expect(model.isFirstLoad, isTrue);
      expect(model.month, isNull);

      repository.monthGate!.complete();
      repository.monthGate = null;
      await flushAsync();

      expect(model.isFirstLoad, isFalse);
      expect(model.dayOf(blockedDay)!.status, ProviderDayStatus.blocked);
      expect(model.dayOf(slotDay)!.status, ProviderDayStatus.partial);
      expect(model.dayOf(heldDay)!.status, ProviderDayStatus.held);
      expect(model.dayOf(bookedDay)!.status, ProviderDayStatus.booked);
      expect(model.dayOf(DateTime(2026, 3, 11))!.status, ProviderDayStatus.free);
      expect(model.minNoticeDays, 3);
    });

    test('pages forward, keeps each month, and cannot go before this one', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      expect(model.canGoBack, isFalse);

      await model.showMonth(DateTime(2026, 4, 20));
      expect(model.visibleMonth, DateTime(2026, 4));
      expect(model.canGoBack, isTrue);

      await model.showMonth(DateTime(2026, 3));
      await model.showMonth(DateTime(2026, 4));
      await model.showMonth(DateTime(2026, 2));

      expect(model.visibleMonth, DateTime(2026, 4));
      expect(repository.calls, <String>['month:2026-03', 'month:2026-04']);
    });

    test('a month that fails shows its failure until retried', () async {
      repository.failNext['month'] = const NetworkFailure();
      final AvailabilityViewModel model = build();
      await flushAsync();

      expect(model.month, isNull);
      expect(model.monthFailure, isA<NetworkFailure>());
      expect(model.isFirstLoad, isFalse);

      await model.retryMonth();

      expect(model.monthFailure, isNull);
      expect(model.month, isNotNull);
    });

    test('refresh keeps the month on failure and marks the others stale', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      await model.showMonth(DateTime(2026, 4));
      await model.showMonth(DateTime(2026, 3));

      repository.failNext['month'] = apiFailure('INTERNAL_ERROR', statusCode: 500);
      final Failure? failure = await model.refresh();

      expect(failure, isA<ApiFailure>());
      expect(model.month, isNotNull, reason: 'what was on screen stays');

      repository.calls.clear();
      await model.showMonth(DateTime(2026, 4));
      expect(repository.calls, <String>['month:2026-04'], reason: 'April went stale');
    });

    test('an older answer landing after a newer one is dropped', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();

      repository.monthGate = Completer<void>();
      final Future<Failure?> first = model.refresh();
      repository.dropRow('b-whole');
      final Completer<void> slow = repository.monthGate!;
      repository.monthGate = null;
      final Future<Failure?> second = model.refresh();
      await second;
      expect(model.dayOf(blockedDay)!.status, ProviderDayStatus.free);

      // The first answer still has the block — it was read before the
      // drop — but it is the older fetch and must not overwrite the newer.
      slow.complete();
      await first;
      expect(model.dayOf(blockedDay)!.status, ProviderDayStatus.free);
    });
  });

  group('picking a day', () {
    test('picks today and later, never a past day', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();

      model.selectDay(DateTime(2026, 3, 9));
      expect(model.selectedDate, isNull);

      model.selectDay(DateTime(2026, 3, 10, 18));
      expect(model.selectedDate, DateTime(2026, 3, 10));
      expect(model.canBlockSelected, isTrue);
    });

    test('the pick hides on another month and comes back with its own', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      model.selectDay(slotDay);

      await model.showMonth(DateTime(2026, 4));
      expect(model.selectedDate, isNull);
      expect(model.canBlockSelected, isFalse);

      await model.showMonth(DateTime(2026, 3));
      expect(model.selectedDate, slotDay);
      expect(model.selectedDay!.items.single.note, 'Family wedding');
    });

    test('says why a day cannot take a block', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();

      expect(model.whyNotBlockable(DateTime(2026, 3, 9)), BlockRefusal.past);
      expect(model.whyNotBlockable(blockedDay), BlockRefusal.alreadyBlocked);
      expect(model.whyNotBlockable(bookedDay), BlockRefusal.fullyBooked);
      // A held day can be blocked: it does not decline the request.
      expect(model.whyNotBlockable(heldDay), isNull);
      expect(model.whyNotBlockable(slotDay), isNull);
    });

    test('a booked day with room for more events can still be blocked', () async {
      repository.maxEventsPerDay = 2;
      final AvailabilityViewModel model = build();
      await flushAsync();

      expect(model.whyNotBlockable(bookedDay), isNull);
    });
  });

  group('blocking', () {
    test('a whole day shows at once and reloads its month', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final DateTime day = DateTime(2026, 3, 12);
      repository.calls.clear();

      final Failure? failure = await model.block(BlockRequest(date: day, note: '  Family wedding '));

      expect(failure, isNull);
      expect(model.dayOf(day)!.status, ProviderDayStatus.blocked);
      expect(repository.blocks.single.toJson(), <String, Object?>{
        'date': '2026-03-12',
        'note': 'Family wedding',
      });
      await flushAsync();
      expect(repository.calls, <String>['block', 'month:2026-03']);
    });

    test('a time slot for one service sends both times and the service', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final DateTime day = DateTime(2026, 3, 12);

      await model.block(BlockRequest(date: day, startTime: '22:00', endTime: '02:00', serviceId: 'svc-2'));

      expect(repository.blocks.single.toJson(), <String, Object?>{
        'date': '2026-03-12',
        'startTime': '22:00',
        'endTime': '02:00',
        'serviceId': 'svc-2',
      });
      expect(model.dayOf(day)!.status, ProviderDayStatus.partial);
    });

    test('a past date comes back to the sheet and reloads the month', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      repository.calls.clear();
      repository.failNext['block'] = apiFailure(ApiErrorCode.availabilityDatePast);

      final Failure? failure = await model.block(BlockRequest(date: DateTime(2026, 3, 10)));
      await flushAsync();

      expect((failure! as ApiFailure).code, ApiErrorCode.availabilityDatePast);
      expect(repository.calls, <String>['block', 'month:2026-03']);
    });

    test('a service that is no longer the provider\'s drops the service list', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      await model.loadServices();
      expect(model.services, hasLength(2));

      repository.failNext['block'] = apiFailure(ApiErrorCode.availabilityServiceInvalid);
      final Failure? failure =
          await model.block(BlockRequest(date: DateTime(2026, 3, 12), serviceId: 'svc-gone'));

      expect((failure! as ApiFailure).code, ApiErrorCode.availabilityServiceInvalid);
      expect(model.services, isNull);
      await model.loadServices();
      expect(serviceLoads, 2);
    });

    test('field errors come back as they are, for the sheet to place', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      repository.failNext['block'] = const ApiFailure(
        statusCode: 400,
        code: ApiErrorCode.validationFailed,
        message: 'Some fields are invalid.',
        fieldErrors: <FieldError>[FieldError(field: 'note', code: 'MAX_LENGTH', message: 'Too long.')],
      );

      final Failure? failure = await model.block(BlockRequest(date: DateTime(2026, 3, 12), note: 'x'));

      expect((failure! as ApiFailure).fieldErrors.single.field, 'note');
      expect(model.dayOf(DateTime(2026, 3, 12))!.status, ProviderDayStatus.free);
    });
  });

  group('removing', () {
    ProviderDayItem slotBlock(AvailabilityViewModel model) => model.dayOf(slotDay)!.items.single;

    test('removes at once, then Undo puts the same block back', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final ProviderDayItem item = slotBlock(model);

      final Future<Failure?> removing = model.remove(item);
      expect(model.dayOf(slotDay)!.status, ProviderDayStatus.free, reason: 'shown before the answer');
      expect(model.isRemoving(item), isTrue);
      expect(await removing, isNull);
      expect(model.isRemoving(item), isFalse);
      expect(repository.calls, contains('unblock:b-slot'));

      final Failure? restored = await model.restore(item);
      await flushAsync();

      expect(restored, isNull);
      final BlockRequest again = repository.blocks.single;
      expect(again.date, slotDay);
      expect(again.startTime, '14:00');
      expect(again.endTime, '18:00');
      expect(again.serviceId, 'svc-1');
      expect(again.note, 'Family wedding');
      expect(model.dayOf(slotDay)!.status, ProviderDayStatus.partial);
    });

    test('a block already gone reloads the month', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final ProviderDayItem item = slotBlock(model);
      repository.dropRow('b-slot');
      repository.calls.clear();

      final Failure? failure = await model.remove(item);

      expect((failure! as ApiFailure).code, ApiErrorCode.availabilityBlockNotFound);
      expect(repository.calls, <String>['unblock:b-slot', 'month:2026-03']);
      expect(model.dayOf(slotDay)!.items, isEmpty);
    });

    test('any other failure puts the block back where it was', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final ProviderDayItem item = slotBlock(model);
      repository.failNext['unblock'] = const NetworkFailure();

      final Failure? failure = await model.remove(item);

      expect(failure, isA<NetworkFailure>());
      expect(model.dayOf(slotDay)!.items.single.id, 'b-slot');
      expect(model.dayOf(slotDay)!.status, ProviderDayStatus.partial);
    });

    test('a booking row is never sent for removal', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final ProviderDayItem booking = model.dayOf(bookedDay)!.items.single;

      final Failure? failure = await model.remove(booking);

      expect((failure! as ApiFailure).code, ApiErrorCode.availabilityBlockNotRemovable);
      expect(repository.calls.where((String c) => c.startsWith('unblock')), isEmpty);
    });

    test('a second tap while removing does nothing', () async {
      final AvailabilityViewModel model = build();
      await flushAsync();
      final ProviderDayItem item = slotBlock(model);

      final Future<Failure?> first = model.remove(item);
      final Failure? second = await model.remove(item);
      await first;

      expect(second, isNull);
      expect(repository.calls.where((String c) => c == 'unblock:b-slot'), hasLength(1));
    });
  });

  group('services', () {
    test('load once, shared by concurrent calls', () async {
      final Completer<List<ProviderServiceRow>> answer = Completer<List<ProviderServiceRow>>();
      int loads = 0;
      final AvailabilityViewModel model = build(loadServices: () {
        loads++;
        return answer.future;
      });

      final Future<Failure?> a = model.loadServices();
      final Future<Failure?> b = model.loadServices();
      answer.complete(<ProviderServiceRow>[testServiceRow('svc-1', 'Grande salle')]);

      expect(await a, isNull);
      expect(await b, isNull);
      expect(loads, 1);
      expect(model.services!.single.id, 'svc-1');
      await model.loadServices();
      expect(loads, 1);
    });

    test('a failed load says so and can be tried again', () async {
      int loads = 0;
      final AvailabilityViewModel model = build(loadServices: () async {
        loads++;
        if (loads == 1) throw const NetworkFailure();
        return <ProviderServiceRow>[];
      });

      expect(await model.loadServices(), isA<NetworkFailure>());
      expect(model.services, isNull);
      expect(await model.loadServices(), isNull);
      expect(model.services, isEmpty);
    });
  });
}
