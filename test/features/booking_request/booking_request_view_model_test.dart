import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/session/session_controller.dart';
import 'package:eventor/features/booking_request/view_model/booking_request_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/booking_fakes.dart';
import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeCatalogRepository catalog;
  late ScriptedBookingsRepository bookings;
  late FakeReferenceRepository reference;
  late SessionController session;

  final DateTime day = DateTime(2026, 3, 14);

  setUp(() {
    catalog = FakeCatalogRepository();
    bookings = ScriptedBookingsRepository();
    reference = FakeReferenceRepository();
    session = SessionController(FakeAuthRepository())
      ..signedIn(
        testUser(wilaya: const Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر')),
      );
  });

  Future<BookingRequestViewModel> build({
    String? packId,
    DateTime? initialDate,
  }) async {
    final BookingRequestViewModel viewModel = BookingRequestViewModel(
      catalog: catalog,
      bookings: bookings,
      reference: reference,
      session: session,
      serviceId: packId == null ? catalog.serviceDetail.id : null,
      packId: packId,
      initialDate: initialDate ?? day,
      today: () => DateTime(2026, 3, 1, 9),
      quoteDelay: Duration.zero,
    );
    addTearDown(viewModel.dispose);
    for (int i = 0; i < 4; i++) {
      await flushAsync();
    }
    return viewModel;
  }

  group('opening B1', () {
    test('opens on the day picked on 12 and prices it', () async {
      final BookingRequestViewModel viewModel = await build();

      expect(viewModel.selectedDate, day);
      expect(bookings.quoted.single.eventDate, day);
      expect(viewModel.quote, isNotNull);
    });

    test('starts in the client’s own wilaya when the service covers it', () async {
      final BookingRequestViewModel viewModel = await build();

      expect(viewModel.wilaya?.code, 16);
      expect(viewModel.communes, reference.communeList);
    });

    test('a day that is not bookable is not picked', () async {
      // The 10th is busy in the fake calendar.
      final BookingRequestViewModel viewModel = await build(initialDate: DateTime(2026, 3, 10));

      expect(viewModel.selectedDate, isNull);
      expect(bookings.quoted, isEmpty);
    });
  });

  group('sending', () {
    test('says what is missing, and sends nothing', () async {
      final BookingRequestViewModel viewModel = await build();

      expect(await viewModel.send(), isNull);

      expect(viewModel.missing, contains(BookingField.eventType));
      expect(bookings.created, isEmpty);
    });

    test('sends the request as filled in', () async {
      final BookingRequestViewModel viewModel = await build();
      viewModel
        ..setEventType(EventType.wedding)
        ..setGuests(150)
        ..setStartTime('13:00')
        ..setEndTime('23:00')
        ..setAddress('Salle Yasmine')
        ..setNote('The ceremony starts at 15:00.');

      final BookingDetail? created = await viewModel.send();

      expect(created, isNotNull);
      final BookingRequest sent = bookings.created.single;
      expect(sent.serviceId, catalog.serviceDetail.id);
      expect(sent.eventDate, day);
      expect(sent.wilayaCode, 16);
      expect(sent.eventType, EventType.wedding);
      expect(sent.guests, 150);
      expect(sent.startTime, '13:00');
      expect(sent.endTime, '23:00');
      expect(viewModel.isDirty, isFalse);
    });

    test('B1b: a date taken meanwhile is struck through and let go', () async {
      final BookingRequestViewModel viewModel = await build();
      viewModel.setEventType(EventType.wedding);
      bookings.failNext = apiFailure(ApiErrorCode.dateUnavailable, statusCode: 409);

      expect(await viewModel.send(), isNull);

      expect(viewModel.problem, SendProblem.dateTaken);
      expect(viewModel.takenDate, day);
      expect(viewModel.selectedDate, isNull);
      expect(viewModel.availability!.stateOf(day), DayState.busy);
      // Everything else is kept.
      expect(viewModel.eventType, EventType.wedding);
    });

    test('B1a: offline keeps the whole form for Try again', () async {
      final BookingRequestViewModel viewModel = await build();
      viewModel.setEventType(EventType.wedding);
      bookings.failNext = const NetworkFailure();

      expect(await viewModel.send(), isNull);

      expect(viewModel.problem, SendProblem.failed);
      expect(viewModel.selectedDate, day);
      expect(viewModel.canSend, isTrue);

      expect(await viewModel.send(), isNotNull);
      expect(viewModel.problem, isNull);
    });

    test('a per-hour service needs both times', () async {
      catalog.serviceDetail = ServiceDetail.fromJson(
        <String, Object?>{...fixtureData('service_detail.json'), 'priceType': 'per_hour'},
      );
      final BookingRequestViewModel viewModel = await build();
      viewModel
        ..setEventType(EventType.wedding)
        ..setStartTime('18:00');

      expect(await viewModel.send(), isNull);
      expect(viewModel.missing, contains(BookingField.time));
    });

    test('a per-person service is priced by the guests before any quote', () async {
      catalog.serviceDetail = ServiceDetail.fromJson(
        <String, Object?>{...fixtureData('service_detail.json'), 'priceType': 'per_person'},
      );
      final BookingRequestViewModel viewModel = await build(initialDate: DateTime(2026, 3, 10));
      viewModel.setGuests(100);

      final String base = catalog.serviceDetail.basePrice;
      final BookingLine line = viewModel.lines('en', packSavingLabel: '').first;
      expect(line.quantity, 100);
      expect(line.unitAmount, base);
    });
  });

  group('times past midnight', () {
    Future<BookingRequestViewModel> hourly() async {
      catalog.serviceDetail = ServiceDetail.fromJson(
        <String, Object?>{...fixtureData('service_detail.json'), 'priceType': 'per_hour'},
      );
      // An unbookable day: no quote, so the listed price shows the count.
      return build(initialDate: DateTime(2026, 3, 10));
    }

    test('an end after midnight is priced across it', () async {
      final BookingRequestViewModel viewModel = await hourly();
      viewModel
        ..setStartTime('20:00')
        ..setEndTime('02:00');

      expect(viewModel.lines('en', packSavingLabel: '').first.quantity, 6);
    });

    test('a started half hour counts as an hour', () async {
      final BookingRequestViewModel viewModel = await hourly();
      viewModel
        ..setStartTime('18:00')
        ..setEndTime('23:30');

      expect(viewModel.lines('en', packSavingLabel: '').first.quantity, 6);
    });

    test('a new start equal to the end lets the end go', () async {
      final BookingRequestViewModel viewModel = await hourly();
      viewModel
        ..setStartTime('18:00')
        ..setEndTime('23:00')
        ..setStartTime('23:00');

      expect(viewModel.startTime, '23:00');
      expect(viewModel.endTime, isNull);
    });

    test('a new start before the end keeps it', () async {
      final BookingRequestViewModel viewModel = await hourly();
      viewModel
        ..setStartTime('18:00')
        ..setEndTime('23:00')
        ..setStartTime('17:00');

      expect(viewModel.endTime, '23:00');
    });

    test('clearing the start clears the end', () async {
      final BookingRequestViewModel viewModel = await hourly();
      viewModel
        ..setStartTime('18:00')
        ..setEndTime('02:00')
        ..setStartTime(null);

      expect(viewModel.endTime, isNull);
    });
  });

  group('guests', () {
    Future<BookingRequestViewModel> perPerson({int? maxGuests}) async {
      catalog.serviceDetail = ServiceDetail.fromJson(<String, Object?>{
        ...fixtureData('service_detail.json'),
        'priceType': 'per_person',
        'maxGuests': maxGuests,
      });
      return build();
    }

    test('a per-person service starts empty and asks for the count', () async {
      final BookingRequestViewModel viewModel = await perPerson();
      viewModel.setEventType(EventType.wedding);

      expect(viewModel.guests, isNull);
      expect(await viewModel.send(), isNull);
      expect(viewModel.missing, contains(BookingField.guests));

      viewModel.setGuests(185);
      expect(viewModel.missing, isNot(contains(BookingField.guests)));
      expect(await viewModel.send(), isNotNull);
      expect(bookings.created.single.guests, 185);
    });

    test('more than the cap is flagged at once and stops the send', () async {
      final BookingRequestViewModel viewModel = await perPerson(maxGuests: 300);
      viewModel
        ..setEventType(EventType.wedding)
        ..setGuests(301);

      expect(viewModel.guestLimit, 300);
      expect(viewModel.guestsOverLimit, isTrue);
      expect(await viewModel.send(), isNull);
      expect(viewModel.missing, contains(BookingField.guests));
      expect(bookings.created, isEmpty);

      // Still over: the error stays.
      viewModel.setGuests(350);
      expect(viewModel.missing, contains(BookingField.guests));

      viewModel.setGuests(300);
      expect(viewModel.guestsOverLimit, isFalse);
      expect(viewModel.missing, isNot(contains(BookingField.guests)));
      expect(await viewModel.send(), isNotNull);
    });

    test('without a cap the field takes up to 5000', () async {
      final BookingRequestViewModel viewModel = await perPerson();

      expect(viewModel.guestLimit, BookingRequestViewModel.defaultMaxGuests);
      viewModel.setGuests(5001);
      expect(viewModel.guestsOverLimit, isTrue);
    });

    test('optional guests emptied again are not sent', () async {
      final BookingRequestViewModel viewModel = await build();
      viewModel
        ..setEventType(EventType.wedding)
        ..setGuests(40)
        ..setGuests(null);

      expect(await viewModel.send(), isNotNull);
      expect(bookings.created.single.guests, isNull);
    });

    test('a typed count makes the form dirty', () async {
      final BookingRequestViewModel viewModel = await build();
      viewModel.clearSelection();
      expect(viewModel.isDirty, isFalse);

      viewModel.setGuests(12);
      expect(viewModel.isDirty, isTrue);
    });
  });

  group('B9: a pack', () {
    test('takes the pack’s event type and sends no extras', () async {
      final BookingRequestViewModel viewModel = await build(packId: catalog.packDetail.id);

      expect(viewModel.eventType, catalog.packDetail.eventType);
      expect(await viewModel.review(), isNotNull);
      expect(await viewModel.send(), isNotNull);
      expect(bookings.created.single.packId, catalog.packDetail.id);
      expect(bookings.created.single.extras, isEmpty);
    });

    test('a pack’s listed price stands in before the quote', () async {
      final BookingRequestViewModel viewModel =
          await build(packId: catalog.packDetail.id, initialDate: DateTime(2026, 3, 10));

      expect(viewModel.total, catalog.packDetail.price);
    });
  });
}
