import 'dart:convert';
import 'dart:typed_data';

import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_catalog_data.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // A fixed "today", so the seeded dates are stable.
  final DateTime today = DateTime(2026, 9, 24, 10);
  late MockBackend backend;
  late MockAuthRepository auth;
  late MockBookingsRepository bookings;
  late MockCatalogRepository catalog;

  Future<void> expectCode(Future<Object?> call, String code) => expectLater(
        call,
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    bookings = MockBookingsRepository(backend, languageCode: () => 'en');
    catalog = MockCatalogRepository(backend, languageCode: () => 'en');
    await auth.login(email: 'client@eventor.test', password: MockBackend.seedPassword);
  });

  final String lumiere = mockCatalogServices[0]['id']! as String;

  /// The available days of [serviceId] from next month on.
  Future<List<DateTime>> freeDays(String serviceId) async {
    final Availability month = await catalog.serviceAvailability(
      serviceId,
      DateTime(today.year, today.month + 1),
    );
    final List<DateTime> days = <DateTime>[];
    for (int d = 1; d <= 28; d++) {
      final DateTime day = DateTime(today.year, today.month + 1, d);
      if (month.stateOf(day) == DayState.available) days.add(day);
    }
    return days;
  }

  BookingRequest request(DateTime day, {String? serviceId}) => BookingRequest(
        serviceId: serviceId ?? lumiere,
        eventDate: day,
        wilayaCode: 16,
        eventType: EventType.wedding,
        guests: 120,
      );

  group('the seeded bookings', () {
    test('cover every state the booking screens draw', () async {
      expect((await bookings.detail('mock-booking-2')).status, 'pending');
      expect((await bookings.detail('mock-booking-3')).proposalForMe, isNotNull);
      expect((await bookings.detail('mock-booking-5')).can(BookingAction.review), isTrue);
      expect((await bookings.detail('mock-booking-6')).cancelledByClient, isTrue);
      expect((await bookings.detail('mock-booking-7')).declineReason, isNotEmpty);
      expect((await bookings.detail('mock-booking-8')).can(BookingAction.checkIn), isTrue);
      expect((await bookings.detail('mock-booking-9')).isPack, isTrue);
    });

    test('share the phone only once accepted', () async {
      expect((await bookings.detail('mock-booking-1')).providerPhone, isNotNull);
      expect((await bookings.detail('mock-booking-2')).providerPhone, isNull);
    });

    test('are for clients only', () async {
      await auth.logout();
      await auth.login(email: 'provider@eventor.test', password: MockBackend.seedPassword);

      final ApiPage<BookingCard> page = await bookings.list(tab: BookingTab.upcoming);
      expect(page.items, isEmpty);
    });
  });

  group('requesting', () {
    test('a request waits as pending and holds the day', () async {
      BookingDetail? created;
      for (final DateTime day in await freeDays(lumiere)) {
        try {
          created = await bookings.create(request(day));
          break;
        } on ApiFailure catch (failure) {
          // One day in eleven is "taken meanwhile" — B1b on demand.
          expect(failure.code, ApiErrorCode.dateUnavailable);
        }
      }

      expect(created, isNotNull);
      expect(created!.status, 'pending');
      expect(created.card.reference, startsWith('EVT-'));
      final ApiPage<BookingCard> pending = await bookings.list(tab: BookingTab.pending);
      expect(pending.items.map((BookingCard b) => b.id), contains(created.id));
      final Availability month = await catalog.serviceAvailability(lumiere, created.card.eventDate);
      expect(month.stateOf(created.card.eventDate), DayState.busy);
    });

    test('too soon is refused, and the quote says so without failing', () async {
      await expectCode(bookings.create(request(today)), ApiErrorCode.minNotice);

      final BookingQuote quote = await bookings.quote(request(today));
      expect(quote.available, isFalse);
      expect(quote.refusal, QuoteRefusal.minNotice);
    });

    test('the quote prices extras and a pack saving', () async {
      final DateTime day = (await freeDays(lumiere)).first;
      final String extra = '$lumiere-x1';
      final BookingQuote service = await bookings.quote(
        BookingRequest(
          serviceId: lumiere,
          eventDate: day,
          wilayaCode: 16,
          eventType: EventType.wedding,
          extras: <String, int>{extra: 2},
        ),
      );
      expect(service.lines.last.kind, BookingLineKind.extra);
      expect(service.lines.last.quantity, 2);

      final String packId = mockCatalogPacks[1]['id']! as String;
      final BookingQuote pack = await bookings.quote(
        BookingRequest(packId: packId, eventDate: day, wilayaCode: 16, eventType: EventType.wedding),
      );
      expect(pack.total, mockCatalogPacks[1]['price']);
      expect(pack.lines.last.kind, BookingLineKind.discount);
    });

    test('an extra from another service is refused', () async {
      final DateTime day = (await freeDays(lumiere)).first;
      await expectCode(
        bookings.create(
          BookingRequest(
            serviceId: lumiere,
            eventDate: day,
            wilayaCode: 16,
            eventType: EventType.wedding,
            extras: const <String, int>{'someone-else': 1},
          ),
        ),
        ApiErrorCode.bookingExtraInvalid,
      );
    });
  });

  group('changing a booking', () {
    test('cancelling once, not twice', () async {
      final BookingDetail cancelled = await bookings.cancel('mock-booking-1', reason: 'Venue changed.');

      expect(cancelled.status, 'cancelled');
      expect(cancelled.cancelReason, 'Venue changed.');
      expect(cancelled.invoice?.voided, isTrue);
      await expectCode(
        bookings.cancel('mock-booking-1', reason: 'Again'),
        ApiErrorCode.bookingInvalidTransition,
      );
    });

    test('a new date on an accepted booking is a proposal, one at a time', () async {
      final DateTime day = (await freeDays(lumiere)).first;
      final BookingDetail proposed = await bookings.reschedule(
        'mock-booking-1',
        date: day,
        reason: 'The hall moved us.',
      );

      expect(proposed.card.eventDate, isNot(day));
      expect(proposed.myPendingProposal?.newDate, day);
      await expectCode(
        bookings.reschedule('mock-booking-1', date: day, reason: 'Again'),
        ApiErrorCode.reschedulePendingExists,
      );

      final BookingDetail withdrawn = await bookings.withdrawReschedule(
        'mock-booking-1',
        proposed.myPendingProposal!.id,
      );
      expect(withdrawn.myPendingProposal, isNull);
    });

    test('accepting the provider’s date moves the booking', () async {
      final BookingDetail before = await bookings.detail('mock-booking-3');
      final Reschedule proposal = before.proposalForMe!;

      final BookingDetail after = await bookings.acceptReschedule('mock-booking-3', proposal.id);

      expect(after.card.eventDate, proposal.newDate);
      expect(after.proposalForMe, isNull);
      await expectCode(
        bookings.withdrawReschedule('mock-booking-3', proposal.id),
        ApiErrorCode.rescheduleNotPending,
      );
    });

    test('the client cannot answer its own proposal', () async {
      final DateTime day = (await freeDays(lumiere)).first;
      final BookingDetail proposed = await bookings.reschedule(
        'mock-booking-1',
        date: day,
        reason: 'Moved.',
      );

      await expectCode(
        bookings.acceptReschedule('mock-booking-1', proposed.myPendingProposal!.id),
        ApiErrorCode.notOwner,
      );
    });
  });

  group('after the event', () {
    test('check-in waits for the event, then closes it with the provider', () async {
      await expectCode(bookings.checkIn('mock-booking-1'), ApiErrorCode.checkInTooEarly);

      final BookingDetail closed = await bookings.checkIn('mock-booking-8');

      expect(closed.status, 'completed');
      expect(closed.checkedIn, isTrue);
    });

    test('a review once, in its window', () async {
      await bookings.review('mock-booking-5', rating: 5, comment: 'Wonderful team, thank you.');

      await expectCode(
        bookings.review('mock-booking-5', rating: 4, comment: 'Second thoughts here.'),
        ApiErrorCode.reviewExists,
      );
      await expectCode(
        bookings.review('mock-booking-1', rating: 5, comment: 'Not yet happened.'),
        ApiErrorCode.reviewNotAllowed,
      );
    });

    test('a problem needs a real description, then holds the check-in', () async {
      await expectCode(
        bookings.openDispute('mock-booking-8', type: DisputeType.providerNoShow, description: 'Too short'),
        ApiErrorCode.validationFailed,
      );

      final BookingDisputeSummary dispute = await bookings.openDispute(
        'mock-booking-8',
        type: DisputeType.providerNoShow,
        description: 'The photographer never came and did not answer our calls.',
      );

      expect(dispute.reference, startsWith('DSP-'));
      await expectCode(bookings.checkIn('mock-booking-8'), ApiErrorCode.checkInDisputed);
    });
  });

  group('the invoice', () {
    test('is Eventor’s, from acceptance on', () async {
      final Invoice invoice = await bookings.invoice('mock-booking-1');

      expect(invoice.issuer.name, contains('Eventor'));
      expect(invoice.bookingReference, 'EVT-002041');
      await expectCode(bookings.invoice('mock-booking-2'), ApiErrorCode.invoiceNotFound);
    });

    test('comes as a real PDF', () async {
      final Uint8List pdf = await bookings.invoicePdf('mock-booking-1');

      expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(latin1.decode(pdf).trimRight(), endsWith('%%EOF'));
    });
  });
}
