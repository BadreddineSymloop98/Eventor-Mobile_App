import 'package:eventor/core/bookings/bookings_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_calendar_booking.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_provider.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shared booking store (user decision 1, 2026-09-28): what a client
/// asks for is what the provider answers, and each side reads it from its
/// own end.
void main() {
  final DateTime today = DateTime(2026, 9, 24, 10);
  const String client = 'client@eventor.test';
  const String yasmine = 'verified.provider@eventor.test';
  // Salle Yasmine's "Grande salle · 150 seats".
  const String grandeSalle = 'f491ca64-3892-4191-b146-e557b441374d';

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockBookingsRepository bookings;
  late MockProviderRepository provider;
  late MockCatalogRepository catalog;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    bookings = MockBookingsRepository(backend, languageCode: () => 'en');
    provider = MockProviderRepository(
      backend,
      MockCatalogLookups(backend, languageCode: () => 'en'),
    );
    catalog = MockCatalogRepository(backend, languageCode: () => 'en');
  });

  Future<void> signIn(String email) async {
    if (backend.hasSession) await auth.logout();
    await auth.login(email: email, password: MockBackend.seedPassword);
  }

  Future<void> expectCode(Future<Object?> call, String code) => expectLater(
        call,
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
      );

  /// A request from the seeded client to the Grande salle, on its first
  /// day that takes one.
  Future<BookingDetail> clientRequest() async {
    await signIn(client);
    final DateTime month = DateTime(today.year, today.month + 1);
    final Availability days = await catalog.serviceAvailability(grandeSalle, month);
    for (int d = 1; d <= 28; d++) {
      final DateTime day = DateTime(month.year, month.month, d);
      if (days.stateOf(day) != DayState.available) continue;
      try {
        return await bookings.create(
          BookingRequest(
            serviceId: grandeSalle,
            eventDate: day,
            wilayaCode: 9,
            eventType: EventType.wedding,
            guests: 100,
          ),
        );
      } on ApiFailure catch (failure) {
        // One day in eleven is "taken meanwhile" — B1b on demand.
        expect(failure.code, ApiErrorCode.dateUnavailable);
      }
    }
    fail('No free day for the Grande salle.');
  }

  group('the provider seeds reach every state of P1–P5', () {
    setUp(() => signIn(yasmine));

    test('two requests, newest first, each with its answers', () async {
      final ApiPage<BookingCard> requests = await provider.bookings(tab: ProviderBookingTab.requests);

      expect(requests.items.map((BookingCard b) => b.counterpartyName), <String>['Nadia Kaci', 'Yacine Meddour']);
      expect(requests.items.first.can(BookingAction.accept), isTrue);
      expect(requests.items.first.can(BookingAction.decline), isTrue);
    });

    test('a date the client proposed (P4a), and one the provider did', () async {
      final ProviderBooking sofiane = await provider.booking('mock-request-4');
      final ProviderBooking amina = await provider.booking('mock-booking-3');

      expect(sofiane.can(BookingAction.respondReschedule), isTrue);
      expect(sofiane.proposalForMe, isNotNull);
      expect(amina.clientName, 'Amina Benali');
      expect(amina.myPendingProposal, isNotNull);
      expect(amina.can(BookingAction.respondReschedule), isFalse);
      expect(amina.can(BookingAction.reschedule), isFalse, reason: 'one proposal at a time');
    });

    test('an event behind us to confirm (P2b), one completed (P2e)', () async {
      final ApiPage<BookingCard> past = await provider.bookings(tab: ProviderBookingTab.past);
      final ProviderBooking karima = await provider.booking('mock-request-5');
      final ProviderBooking samir = await provider.booking('mock-request-6');

      expect(past.items.map((BookingCard b) => b.id), containsAll(<String>['mock-request-5', 'mock-request-6']));
      expect(karima.can(BookingAction.checkIn), isTrue);
      expect(samir.status, 'completed');
      expect(samir.checkedIn && samir.otherCheckedIn, isTrue);
    });

    test('one declined (P2c) and one the client cancelled (P2d), by link only', () async {
      final ProviderBooking meriem = await provider.booking('mock-request-7');
      final ProviderBooking rachid = await provider.booking('mock-request-8');

      expect(meriem.status, 'declined');
      expect(meriem.declineReason, isNotEmpty);
      expect(rachid.cancelledBy, CancelledBy.client);
      expect(rachid.wasAccepted, isTrue);
      for (final ProviderBookingTab tab in ProviderBookingTab.values) {
        final ApiPage<BookingCard> page = await provider.bookings(tab: tab);
        expect(page.items.map((BookingCard b) => b.id), isNot(contains('mock-request-7')));
      }
    });

    test('pages the lists', () async {
      final ApiPage<BookingCard> first = await provider.bookings(tab: ProviderBookingTab.upcoming, limit: 2);
      final ApiPage<BookingCard> second =
          await provider.bookings(tab: ProviderBookingTab.upcoming, page: 2, limit: 2);

      expect(first.items, hasLength(2));
      expect(first.hasMore, isTrue);
      expect(second.items, hasLength(1));
      expect(second.hasMore, isFalse);
    });

    test('another provider’s booking is not theirs to read', () async {
      await expectCode(provider.booking('mock-booking-1'), ApiErrorCode.notOwner);
      await expectCode(provider.booking('nope'), ApiErrorCode.bookingNotFound);
    });
  });

  group('contact details', () {
    setUp(() => signIn(yasmine));

    test('stay hidden until the provider accepts', () async {
      final ProviderBooking pending = await provider.booking('mock-request-1');
      expect(pending.client.phone, isNull);
      expect(pending.client.email, isNull);

      final ProviderBooking accepted = await provider.accept('mock-request-1');
      expect(accepted.client.phone, isNotNull);
      expect(accepted.client.email, isNotNull);
    });

    test('stay in the history of a booking the client cancelled, not of a declined request', () async {
      expect((await provider.booking('mock-request-8')).client.phone, isNotNull);
      expect((await provider.booking('mock-request-7')).client.phone, isNull);
    });
  });

  group('one store, two sides', () {
    test('a client’s request is on the provider’s P1 at once', () async {
      final BookingDetail sent = await clientRequest();
      await signIn(yasmine);

      final ApiPage<BookingCard> requests = await provider.bookings(tab: ProviderBookingTab.requests);
      final ProviderBooking seen = await provider.booking(sent.id);

      expect(requests.items.map((BookingCard b) => b.id), contains(sent.id));
      expect(seen.clientName, 'Amina Benali');
      expect(seen.client.phone, isNull);
      expect(seen.can(BookingAction.accept), isTrue);
      expect(seen.can(BookingAction.cancel), isFalse, reason: 'a request is declined, not cancelled');
    });

    test('the provider’s Accept is what the client then sees', () async {
      final BookingDetail sent = await clientRequest();
      await signIn(yasmine);
      await provider.accept(sent.id);

      await signIn(client);
      final BookingDetail seen = await bookings.detail(sent.id);

      expect(seen.status, 'accepted');
      expect(seen.providerPhone, isNotNull);
      expect(seen.can(BookingAction.cancel), isTrue);
      expect(seen.can(BookingAction.accept), isFalse, reason: 'the client’s own rules');
    });

    test('a decline reaches the client with its reason', () async {
      final BookingDetail sent = await clientRequest();
      await signIn(yasmine);
      await expectCode(provider.decline(sent.id, reason: ' '), ApiErrorCode.validationFailed);
      await provider.decline(sent.id, reason: 'Already booked that day.');

      await signIn(client);
      final BookingDetail seen = await bookings.detail(sent.id);

      expect(seen.status, 'declined');
      expect(seen.declineReason, 'Already booked that day.');
    });

    test('the client’s cancel is P2d for the provider', () async {
      final BookingDetail sent = await clientRequest();
      await signIn(yasmine);
      await provider.accept(sent.id);
      await signIn(client);
      await bookings.cancel(sent.id, reason: 'Our plans changed.');

      await signIn(yasmine);
      final ProviderBooking seen = await provider.booking(sent.id);

      expect(seen.status, 'cancelled');
      expect(seen.cancelledBy, CancelledBy.client);
      expect(seen.cancelReason, 'Our plans changed.');
    });

    test('the provider cancels only an accepted booking, and the client sees who did', () async {
      await signIn(yasmine);
      await expectCode(provider.cancel('mock-request-1', reason: 'No'), ApiErrorCode.bookingInvalidTransition);
      await provider.cancel('mock-booking-3', reason: 'The hall is closed for repairs.');

      await signIn(client);
      final BookingDetail seen = await bookings.detail('mock-booking-3');

      expect(seen.status, 'cancelled');
      expect(seen.cancelledByClient, isFalse);
      expect(seen.proposalForMe, isNull, reason: 'the open proposal closes with it');
    });

    test('the provider withdraws their proposal; the client no longer has it to answer', () async {
      await signIn(yasmine);
      final ProviderBooking amina = await provider.booking('mock-booking-3');
      await expectCode(
        provider.acceptReschedule('mock-booking-3', amina.myPendingProposal!.id),
        ApiErrorCode.notOwner,
      );
      await provider.withdrawReschedule('mock-booking-3', amina.myPendingProposal!.id);

      await signIn(client);
      expect((await bookings.detail('mock-booking-3')).proposalForMe, isNull);
    });

    test('the provider answers the client’s proposal (P4a)', () async {
      await signIn(yasmine);
      final ProviderBooking before = await provider.booking('mock-request-4');
      final Reschedule proposal = before.proposalForMe!;

      final ProviderBooking after = await provider.acceptReschedule('mock-request-4', proposal.id);

      expect(after.card.eventDate, proposal.newDate);
      expect(after.proposalForMe, isNull);
      await expectCode(
        provider.rejectReschedule('mock-request-4', proposal.id),
        ApiErrorCode.rescheduleNotPending,
      );
    });
  });

  group('P4 · a new date from the provider', () {
    setUp(() => signIn(yasmine));

    DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);

    test('moves a request at once', () async {
      final ProviderBooking moved = await provider.reschedule(
        'mock-request-2',
        date: inDays(50),
        reason: 'The hall is only free later.',
        startTime: '15:00',
        endTime: '01:00',
      );

      expect(moved.status, 'pending');
      expect(moved.card.eventDate, inDays(50));
      expect(moved.card.endTime, '01:00');
      expect(moved.reschedules, isEmpty);
    });

    test('proposes on an accepted booking, one at a time, never in the past', () async {
      await expectCode(
        provider.reschedule('mock-request-3', date: inDays(-3), reason: 'Moved.'),
        ApiErrorCode.bookingDatePast,
      );
      await expectCode(
        provider.reschedule('mock-request-3', date: inDays(40), reason: 'x' * 201),
        ApiErrorCode.validationFailed,
      );

      final ProviderBooking proposed =
          await provider.reschedule('mock-request-3', date: inDays(41), reason: 'The team is away.');

      expect(proposed.card.eventDate, inDays(25), reason: 'the booking keeps its date meanwhile');
      expect(proposed.myPendingProposal?.newDate, inDays(41));
      await expectCode(
        provider.reschedule('mock-request-3', date: inDays(42), reason: 'Again.'),
        ApiErrorCode.reschedulePendingExists,
      );
    });

    test('refuses a day the service is already taken', () async {
      // Sofiane's wedding holds the Salle des fêtes on day 33; Nadia's
      // request is on the same service.
      await expectCode(
        provider.reschedule('mock-request-1', date: inDays(33), reason: 'Move.'),
        ApiErrorCode.dateUnavailable,
      );
    });

    test('reads its own month: a request holds its day', () async {
      final DateTime nadia = inDays(18);
      final ProviderCalendarMonth month = await provider.availabilityMonth(nadia);

      expect(month.dayOf(nadia)?.status, ProviderDayStatus.held);
      expect(month.dayOf(nadia)?.bookingIds, contains('mock-request-1'));
    });
  });

  group('P5 · after the event', () {
    setUp(() => signIn(yasmine));

    test('"All good" once, after the event only', () async {
      await expectCode(provider.checkIn('mock-request-3'), ApiErrorCode.checkInTooEarly);

      final ProviderBooking confirmed = await provider.checkIn('mock-request-5');

      expect(confirmed.checkedIn, isTrue);
      expect(confirmed.status, 'accepted', reason: 'the client has not said so yet');
      expect(confirmed.can(BookingAction.checkIn), isFalse);
      await expectCode(provider.checkIn('mock-request-5'), ApiErrorCode.checkInNotAllowed);
    });

    test('a problem opens a dispute, which holds the check-in', () async {
      await expectCode(
        provider.openDispute('mock-request-5', type: ProviderDisputeType.clientNoShow, description: 'Too short'),
        ApiErrorCode.validationFailed,
      );

      final BookingDisputeSummary dispute = await provider.openDispute(
        'mock-request-5',
        type: ProviderDisputeType.clientNoShow,
        description: 'Nobody came and nobody answered the phone that evening.',
      );

      expect(dispute.reference, startsWith('DSP-'));
      await expectCode(provider.checkIn('mock-request-5'), ApiErrorCode.checkInDisputed);
    });

    test('the provider’s "All good" completes a booking the client confirmed', () async {
      expect((await provider.booking('mock-request-5')).otherCheckedIn, isFalse);
      // Karima has no account here to tap "All good" with: say it in the
      // store, as her B7 would.
      final List<Object?> records =
          backend.store('bookings', () => <String, Object?>{})['records']! as List<Object?>;
      final Map<String, Object?> karima = records
          .cast<Map<String, Object?>>()
          .firstWhere((Map<String, Object?> r) => r['id'] == 'mock-request-5');
      karima['clientCheckedIn'] = true;

      final ProviderBooking closed = await provider.checkIn('mock-request-5');

      expect(closed.status, 'completed');
      expect(closed.checkedIn && closed.otherCheckedIn, isTrue);
    });
  });

  test('the availability calendar sees the live bookings, from the store', () async {
    final MockAccount account = backend.accountByEmail(yasmine)!;

    final List<MockCalendarBooking> live = mockCalendarBookings(backend, account);

    expect(live.map((MockCalendarBooking b) => b.clientName), containsAll(<String>['Nadia Kaci', 'Lila Hamadi']));
    expect(live.firstWhere((MockCalendarBooking b) => b.id == 'mock-request-1').isAccepted, isFalse);
    expect(live.firstWhere((MockCalendarBooking b) => b.id == 'mock-request-3').isAccepted, isTrue);
    expect(live.map((MockCalendarBooking b) => b.id), isNot(contains('mock-request-7')));
    expect(live.map((MockCalendarBooking b) => b.id), isNot(contains('mock-request-6')));
  });

  test('a client cannot use the provider routes, nor a provider the client ones', () async {
    await signIn(client);
    await expectCode(provider.bookings(tab: ProviderBookingTab.requests), ApiErrorCode.notAProvider);

    await signIn(yasmine);
    await expectCode(bookings.detail('mock-booking-3'), ApiErrorCode.forbiddenRole);
  });
}
