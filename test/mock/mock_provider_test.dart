import 'package:eventor/core/bookings/models/booking_card.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/provider/provider_repository.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_provider.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final DateTime today = DateTime(2026, 9, 24, 10);

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockProviderRepository provider;
  late MockDocumentsRepository documents;

  Future<void> start() async {
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    provider = MockProviderRepository(
      backend,
      MockCatalogLookups(backend, languageCode: () => 'en'),
    );
    documents = MockDocumentsRepository(backend);
  }

  Future<void> signIn(String email) =>
      auth.login(email: email, password: MockBackend.seedPassword);

  Future<void> expectCode(Future<Object?> call, String code) => expectLater(
        call,
        throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await start();
  });

  group('the verified provider (21)', () {
    setUp(() => signIn('verified.provider@eventor.test'));

    test('has two requests, two bookings ahead and their services', () async {
      final ProviderHome home = await provider.home();

      expect(home.state, ProviderHomeState.verified);
      expect(home.documents, isNull);
      expect(home.requests.map((BookingCard b) => b.counterpartyName),
          <String>['Nadia Kaci', 'Yacine Meddour']);
      expect(home.upcoming, hasLength(2));
      expect(home.counts.requests, 2);
      expect(home.services, isNotEmpty);
      expect(home.acceptingBookings, isTrue);
    });

    test('accepts a request, which moves to upcoming', () async {
      final ProviderHome before = await provider.home();

      await provider.accept(before.requests.first.id);
      final ProviderHome after = await provider.home();

      expect(after.requests, hasLength(1));
      expect(after.counts.upcoming, 3);
    });

    test('declines with a reason, and refuses an empty or long one', () async {
      final String id = (await provider.home()).requests.first.id;

      await expectCode(provider.decline(id, reason: '  '), ApiErrorCode.validationFailed);
      await expectCode(provider.decline(id, reason: 'x' * 61), ApiErrorCode.validationFailed);

      await provider.decline(id, reason: 'Already booked that day.');
      expect((await provider.home()).requests, hasLength(1));
    });

    test('answers a request only once', () async {
      final String id = (await provider.home()).requests.first.id;
      await provider.accept(id);

      await expectCode(provider.accept(id), ApiErrorCode.bookingInvalidTransition);
      await expectCode(provider.accept('nope'), ApiErrorCode.bookingNotFound);
    });

    test('pauses bookings, and keeps it across a restart', () async {
      await provider.setAcceptingBookings(false);

      await start();

      expect((await provider.home()).acceptingBookings, isFalse);
    });
  });

  group('the pending provider (21a)', () {
    setUp(() => signIn('provider@eventor.test'));

    test('has two in review and the tax card missing', () async {
      final ProviderHome home = await provider.home();

      expect(home.state, ProviderHomeState.pending);
      expect(home.documents?.sentCount, 2);
      expect(home.documents?.needingAction.single.type, ProviderDocumentType.taxCard);
      expect(home.requests, isEmpty);
      expect(home.services, isEmpty);
    });

    test('cannot accept yet', () async {
      await expectCode(provider.accept('any'), ApiErrorCode.providerNotVerified);
    });

    test('moves on to "under review" once all three are sent', () async {
      await documents.upload(type: ProviderDocumentType.taxCard, path: 'x', fileName: 'nif.pdf');

      final ProviderHome home = await provider.home();

      expect(home.documents?.needingAction, isEmpty);
      expect(
        home.steps.firstWhere((VerificationStep s) => s.current).key,
        VerificationStepKey.underReview,
      );
    });
  });

  group('the rejected provider (21b / 08d)', () {
    setUp(() => signIn('rejected.provider@eventor.test'));

    test('has the tax card refused, with its reason', () async {
      final ProviderHome home = await provider.home();
      final ProviderDocument tax = home.documents!.byType(ProviderDocumentType.taxCard)!;

      expect(home.state, ProviderHomeState.rejected);
      expect(tax.status, ProviderDocumentStatus.rejected);
      expect(tax.rejectReason, 'Details do not match the account');
      expect(tax.rejectNote, isNotEmpty);
      expect(tax.reviewedAt, isNotNull);
    });

    test('goes back into review once the refused document is sent again', () async {
      await documents.upload(type: ProviderDocumentType.taxCard, path: 'x', fileName: 'nif.pdf');

      final ProviderHome home = await provider.home();

      expect(home.state, ProviderHomeState.pending);
      expect(backend.accountByEmail('rejected.provider@eventor.test')!.verificationStatus,
          VerificationStatus.pending);
      expect(home.documents!.byType(ProviderDocumentType.taxCard)!.rejectNote, isNull);
    });
  });

  test('refuses a client', () async {
    await signIn('client@eventor.test');

    await expectCode(provider.home(), ApiErrorCode.notAProvider);
  });
}
