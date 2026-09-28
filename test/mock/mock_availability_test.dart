import 'package:eventor/core/availability/availability_repository.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/mock/mock_availability.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_calendar_booking.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Thursday 24 September 2026, 10:00.
  final DateTime today = DateTime(2026, 9, 24, 10);

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockAvailabilityRepository availability;
  late List<MockCalendarBooking> bookings;

  Set<String> catalogServiceIds(MockAccount provider) => <String>{
        for (final Map<String, Object?> s
            in MockCatalogLookups(backend, languageCode: () => 'en').providerServices(provider.businessName))
          s['id']! as String,
      };

  Future<void> start({SharedPreferences? prefs}) async {
    backend = await MockBackend.load(
      prefs: prefs ?? await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    availability = MockAvailabilityRepository(
      backend,
      bookings: (MockAccount provider) => bookings,
      serviceIdsOf: catalogServiceIds,
    );
  }

  Future<void> signIn(String email) => auth.login(email: email, password: MockBackend.seedPassword);

  Future<void> expectCode(Future<Object?> call, String code, {int? status}) => expectLater(
        call,
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.code, 'code', code)
              .having((ApiFailure f) => f.statusCode, 'statusCode', status ?? anything),
        ),
      );

  MockCalendarBooking booking(String id, String date, {required bool accepted}) => MockCalendarBooking(
        id: id,
        reference: 'EVT-2026-$id',
        clientName: 'Nadia Kaci',
        date: date,
        isAccepted: accepted,
        startTime: '13:00',
        endTime: '23:00',
        serviceId: 'svc-x',
        titleEn: 'Grande salle',
        titleAr: 'القاعة الكبرى',
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    bookings = <MockCalendarBooking>[];
    await start();
  });

  group('the seeded provider', () {
    setUp(() => signIn(MockAvailabilityRepository.seededProviderEmail));

    test('has a whole day blocked this month and a noted slot next month', () async {
      final AvailabilityMonth september = await availability.month(DateTime(2026, 9));
      final ProviderDay whole = september.dayOf(DateTime(2026, 9, 26));

      expect(september.month, DateTime(2026, 9));
      expect(whole.status, ProviderDayStatus.blocked);
      expect(whole.items.single.isWholeDay, isTrue);
      expect(whole.items.single.service, isNull);
      expect(whole.items.single.removable, isTrue);
      expect(september.dayOf(DateTime(2026, 9, 25)).status, ProviderDayStatus.free);

      final AvailabilityMonth october = await availability.month(DateTime(2026, 10, 3));
      final ProviderDay slot = october.dayOf(DateTime(2026, 10, 10));
      expect(slot.status, ProviderDayStatus.partial);
      expect(slot.items.single.startTime, '14:00');
      expect(slot.items.single.endTime, '18:00');
      expect(slot.items.single.note, 'Family wedding');
      expect(slot.items.single.service!.title.en, isNotEmpty);
    });

    test('lists every day of the month', () async {
      final AvailabilityMonth february = await availability.month(DateTime(2027, 2));
      expect(february.dayOf(DateTime(2027, 2, 28)).date, DateTime(2027, 2, 28));
    });

    test('a pending request holds its day, an accepted booking takes it', () async {
      bookings = <MockCalendarBooking>[
        booking('0142', '2026-09-28', accepted: false),
        booking('0143', '2026-09-29', accepted: true),
      ];

      final AvailabilityMonth month = await availability.month(DateTime(2026, 9));
      final ProviderDay held = month.dayOf(DateTime(2026, 9, 28));
      final ProviderDay booked = month.dayOf(DateTime(2026, 9, 29));

      expect(held.status, ProviderDayStatus.held);
      expect(held.items.single.kind, ProviderDayItemKind.held);
      expect(held.items.single.booking!.reference, 'EVT-2026-0142');
      expect(held.items.single.booking!.status, 'pending');
      expect(held.items.single.removable, isFalse);
      expect(booked.status, ProviderDayStatus.booked);
      expect(booked.items.single.booking!.id, '0143');
      expect(booked.items.single.startTime, '13:00');
    });

    test('status precedence: booked > held > blocked > partial > free', () async {
      bookings = <MockCalendarBooking>[
        // On the seeded whole-day block.
        booking('a', '2026-09-26', accepted: true),
        booking('b', '2026-09-26', accepted: false),
        booking('c', '2026-09-30', accepted: false),
      ];
      await availability.block(BlockRequest(date: DateTime(2026, 9, 30)));
      await availability.block(BlockRequest(date: DateTime(2026, 9, 27), startTime: '10:00', endTime: '12:00'));
      await availability.block(BlockRequest(date: DateTime(2026, 9, 27)));
      final String service = catalogServiceIds(backend.accountByEmail(MockAvailabilityRepository.seededProviderEmail)!).first;
      await availability.block(BlockRequest(date: DateTime(2026, 9, 25), serviceId: service));

      final AvailabilityMonth month = await availability.month(DateTime(2026, 9));

      expect(month.dayOf(DateTime(2026, 9, 26)).status, ProviderDayStatus.booked);
      expect(month.dayOf(DateTime(2026, 9, 26)).items, hasLength(3));
      expect(month.dayOf(DateTime(2026, 9, 30)).status, ProviderDayStatus.held);
      expect(month.dayOf(DateTime(2026, 9, 27)).status, ProviderDayStatus.blocked);
      // A whole day for one service is only partial.
      expect(month.dayOf(DateTime(2026, 9, 25)).status, ProviderDayStatus.partial);
    });

    test('a block is added, listed, kept, and removed', () async {
      final ProviderDayItem created = await availability.block(
        BlockRequest(date: DateTime(2026, 9, 24), startTime: '18:00', endTime: '02:00', note: ' Dinner '),
      );
      expect(created.id, isNotNull);
      expect(created.kind, ProviderDayItemKind.blocked);
      expect(created.note, 'Dinner');
      expect(created.removable, isTrue);

      // Persisted: a fresh backend on the same storage still has it.
      await start(prefs: await SharedPreferences.getInstance());
      await signIn(MockAvailabilityRepository.seededProviderEmail);
      AvailabilityMonth month = await availability.month(DateTime(2026, 9));
      expect(month.dayOf(DateTime(2026, 9, 24)).items.single.id, created.id);

      await availability.unblock(created.id!);
      month = await availability.month(DateTime(2026, 9));
      expect(month.dayOf(DateTime(2026, 9, 24)).items, isEmpty);
    });

    test('every new block gets its own id', () async {
      final ProviderDayItem a = await availability.block(BlockRequest(date: DateTime(2026, 9, 25)));
      await availability.unblock(a.id!);
      final ProviderDayItem b = await availability.block(BlockRequest(date: DateTime(2026, 9, 25)));

      expect(b.id, isNot(a.id));
    });
  });

  group('the API\'s rules', () {
    setUp(() => signIn(MockAvailabilityRepository.seededProviderEmail));

    test('a past date is refused; today is fine', () async {
      await expectCode(
        availability.block(BlockRequest(date: DateTime(2026, 9, 23))),
        ApiErrorCode.availabilityDatePast,
        status: 422,
      );
      await availability.block(BlockRequest(date: DateTime(2026, 9, 24)));
    });

    test('a service that is not the provider\'s is refused', () => expectCode(
          availability.block(BlockRequest(date: DateTime(2026, 9, 25), serviceId: 'not-mine')),
          ApiErrorCode.availabilityServiceInvalid,
          status: 422,
        ));

    test('times are both or neither', () async {
      await expectLater(
        availability.block(BlockRequest(date: DateTime(2026, 9, 25), startTime: '14:00')),
        throwsA(
          isA<ApiFailure>()
              .having((ApiFailure f) => f.code, 'code', ApiErrorCode.validationFailed)
              .having((ApiFailure f) => f.fieldErrors.single.field, 'field', 'endTime'),
        ),
      );
      await expectCode(
        availability.block(BlockRequest(date: DateTime(2026, 9, 25), startTime: '14:00', endTime: '14:00')),
        ApiErrorCode.validationFailed,
        status: 400,
      );
      await expectCode(
        availability.block(BlockRequest(date: DateTime(2026, 9, 25), startTime: '25:00', endTime: '02:00')),
        ApiErrorCode.validationFailed,
      );
    });

    test('a note is at most 255 characters', () async {
      await expectLater(
        availability.block(BlockRequest(date: DateTime(2026, 9, 25), note: 'x' * 256)),
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.fieldErrors.single.field, 'field', 'note')),
      );
      await availability.block(BlockRequest(date: DateTime(2026, 9, 25), note: 'x' * 255));
    });

    test('the body is checked before the date', () => expectCode(
          availability.block(BlockRequest(date: DateTime(2026, 1, 1), startTime: '14:00')),
          ApiErrorCode.validationFailed,
        ));

    test('a booking\'s row cannot be removed', () async {
      bookings = <MockCalendarBooking>[booking('0142', '2026-09-28', accepted: true)];
      final AvailabilityMonth month = await availability.month(DateTime(2026, 9));
      final String id = month.dayOf(DateTime(2026, 9, 28)).items.single.id!;

      await expectCode(availability.unblock(id), ApiErrorCode.availabilityBlockNotRemovable, status: 409);
    });

    test('an unknown block is not found', () =>
        expectCode(availability.unblock('nope'), ApiErrorCode.availabilityBlockNotFound, status: 404));

    test('another provider\'s block is not the provider\'s to remove', () async {
      final ProviderDayItem mine = await availability.block(BlockRequest(date: DateTime(2026, 9, 25)));
      await auth.logout();
      await signIn('provider@eventor.test');

      await expectCode(availability.unblock(mine.id!), ApiErrorCode.notOwner, status: 403);
      final AvailabilityMonth theirs = await availability.month(DateTime(2026, 9));
      expect(theirs.dayOf(DateTime(2026, 9, 25)).items, isEmpty, reason: 'their calendar starts empty');
    });

    test('a client is refused', () async {
      await auth.logout();
      await signIn('client@eventor.test');

      await expectCode(availability.month(DateTime(2026, 9)), ApiErrorCode.notAProvider, status: 422);
      await expectCode(
        availability.block(BlockRequest(date: DateTime(2026, 9, 25))),
        ApiErrorCode.notAProvider,
      );
    });
  });
}
