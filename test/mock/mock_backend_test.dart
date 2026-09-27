import 'package:eventor/core/config/data_source.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/auth/data/documents_repository.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_reference_data.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expects [call] to throw an [ApiFailure] carrying [code].
Future<ApiFailure> expectApiFailure(Future<Object?> call, String code) async {
  try {
    await call;
  } on ApiFailure catch (failure) {
    expect(failure.code, code);
    return failure;
  }
  fail('Expected ApiFailure $code, but the call succeeded.');
}

void main() {
  late DateTime now;
  late MockBackend backend;
  late MockAuthRepository auth;

  Future<void> start() async {
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => now,
    );
    auth = MockAuthRepository(backend);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    now = DateTime(2026, 9, 23, 12);
    await start();
  });

  RegistrationRequest client({
    String email = 'new@eventor.test',
    String phone = '0555123456',
    String password = 'Eventor2026',
  }) =>
      RegistrationRequest(
        role: UserRole.client,
        fullName: 'New Client',
        email: email,
        phone: phone,
        password: password,
        language: 'en',
      );

  test('builds default to mock until the backend is fixed', () {
    // No --dart-define in tests, so this is the build default.
    expect(DataSource.current, DataSource.mock);
  });

  group('seeded accounts', () {
    test('the verified client logs in', () async {
      final AppUser user = await auth.login(
        email: 'client@eventor.test',
        password: MockBackend.seedPassword,
      );
      expect(user.role, UserRole.client);
      expect(backend.hasSession, isTrue);
    });

    test('the unverified account gets EMAIL_NOT_VERIFIED with its address',
        () async {
      final ApiFailure failure = await expectApiFailure(
        auth.login(email: 'unverified@eventor.test', password: 'Eventor2026'),
        ApiErrorCode.emailNotVerified,
      );
      expect(failure.statusCode, 403);
      expect(failure.details?['email'], 'unverified@eventor.test');
    });

    test('the blocked account gets ACCOUNT_BLOCKED with the admin message',
        () async {
      final ApiFailure failure = await expectApiFailure(
        auth.login(email: 'blocked@eventor.test', password: 'Eventor2026'),
        ApiErrorCode.accountBlocked,
      );
      expect(failure.details?['message'], isA<String>());
    });

    test('the provider is pending and the verified provider verified',
        () async {
      expect(
        (await auth.login(
          email: 'provider@eventor.test',
          password: 'Eventor2026',
        ))
            .verificationStatus,
        VerificationStatus.pending,
      );
      expect(
        (await auth.login(
          email: 'verified.provider@eventor.test',
          password: 'Eventor2026',
        ))
            .verificationStatus,
        VerificationStatus.verified,
      );
    });
  });

  group('login', () {
    test('a wrong password or unknown address is the same 401', () async {
      await expectApiFailure(
        auth.login(email: 'client@eventor.test', password: 'Wrong-1234'),
        ApiErrorCode.invalidCredentials,
      );
      await expectApiFailure(
        auth.login(email: 'nobody@eventor.test', password: 'Wrong-1234'),
        ApiErrorCode.invalidCredentials,
      );
    });

    test('five failures still answer 401; the sixth attempt is locked',
        () async {
      for (int i = 0; i < 5; i++) {
        await expectApiFailure(
          auth.login(email: 'client@eventor.test', password: 'Wrong-1234'),
          ApiErrorCode.invalidCredentials,
        );
      }
      final ApiFailure locked = await expectApiFailure(
        // Even the right password is refused while locked.
        auth.login(email: 'client@eventor.test', password: 'Eventor2026'),
        ApiErrorCode.accountLocked,
      );
      expect(locked.statusCode, 429);
      expect(locked.retryAfterSeconds, 15 * 60);
    });

    test('the lock lifts after 15 minutes', () async {
      for (int i = 0; i < 5; i++) {
        await expectApiFailure(
          auth.login(email: 'client@eventor.test', password: 'Wrong-1234'),
          ApiErrorCode.invalidCredentials,
        );
      }
      now = now.add(const Duration(minutes: 15, seconds: 1));
      final AppUser user = await auth.login(
        email: 'client@eventor.test',
        password: 'Eventor2026',
      );
      expect(user.email, 'client@eventor.test');
    });
  });

  group('register', () {
    test('creates an unverified account and sends a code', () async {
      final CodeSent sent = await auth.register(client());
      expect(sent.email, 'new@eventor.test');
      expect(sent.resendAfterSeconds, 60);
      await expectApiFailure(
        auth.login(email: 'new@eventor.test', password: 'Eventor2026'),
        ApiErrorCode.emailNotVerified,
      );
    });

    test('refuses a taken email and a taken phone (either form)', () async {
      await expectApiFailure(
        auth.register(client(email: 'Client@Eventor.test')),
        ApiErrorCode.emailTaken,
      );
      await expectApiFailure(
        // The seeded client's phone, written the international way.
        auth.register(client(phone: '+213 555 00 00 01')),
        ApiErrorCode.phoneTaken,
      );
    });

    test('applies the password policy with the minimum in details', () async {
      for (final String weak in <String>[
        'Short1',
        'OnlyLettersHere',
        '1234567890',
        'password123',
      ]) {
        final ApiFailure failure = await expectApiFailure(
          auth.register(client(password: weak)),
          ApiErrorCode.passwordWeak,
        );
        expect(failure.details?['minLength'], 10, reason: weak);
      }
    });

    test('a provider needs business fields; a client may not send them',
        () async {
      await expectApiFailure(
        auth.register(
          const RegistrationRequest(
            role: UserRole.provider,
            fullName: 'P',
            email: 'p@eventor.test',
            phone: '0555123999',
            password: 'Eventor2026',
            language: 'en',
          ),
        ),
        ApiErrorCode.providerFieldsRequired,
      );
      await expectApiFailure(
        auth.register(
          RegistrationRequest(
            role: UserRole.provider,
            fullName: 'P',
            email: 'p@eventor.test',
            phone: '0555123999',
            password: 'Eventor2026',
            language: 'en',
            businessName: 'Studio',
            categoryId: 'no-such-category',
            wilayaCodes: <int>[mockWilayas.first.code],
          ),
        ),
        ApiErrorCode.categoryNotFound,
      );
    });
  });

  group('codes', () {
    setUp(() => auth.register(client()));

    test('123456 verifies and signs in', () async {
      final AppUser user = await auth.verifyEmail(
        email: 'new@eventor.test',
        code: MockBackend.code,
      );
      expect(user.emailVerified, isTrue);
      expect(backend.sessionAccount?.email, 'new@eventor.test');
    });

    test('000000 is expired and anything else is wrong', () async {
      await expectApiFailure(
        auth.verifyEmail(email: 'new@eventor.test', code: '000000'),
        ApiErrorCode.codeExpired,
      );
      await expectApiFailure(
        auth.verifyEmail(email: 'new@eventor.test', code: '111111'),
        ApiErrorCode.codeInvalid,
      );
    });

    test('resend waits out the 60 s cooldown', () async {
      final ApiFailure early = await expectApiFailure(
        auth.resendVerification('new@eventor.test'),
        ApiErrorCode.codeResendTooSoon,
      );
      expect(early.retryAfterSeconds, 60);

      now = now.add(const Duration(seconds: 61));
      final CodeSent sent = await auth.resendVerification('new@eventor.test');
      expect(sent.resendAfterSeconds, 60);
    });
  });

  group('password reset', () {
    test('a correct code sets the password and signs everyone out', () async {
      await auth.login(email: 'client@eventor.test', password: 'Eventor2026');
      await auth.resetPassword(
        email: 'client@eventor.test',
        code: MockBackend.code,
        password: 'Brand-New-2027',
      );
      expect(backend.hasSession, isFalse);
      await expectApiFailure(
        auth.login(email: 'client@eventor.test', password: 'Eventor2026'),
        ApiErrorCode.invalidCredentials,
      );
      expect(
        (await auth.login(
          email: 'client@eventor.test',
          password: 'Brand-New-2027',
        ))
            .email,
        'client@eventor.test',
      );
    });

    test('a wrong code is refused', () async {
      await expectApiFailure(
        auth.resetPassword(
          email: 'client@eventor.test',
          code: '999999',
          password: 'Brand-New-2027',
        ),
        ApiErrorCode.codeInvalid,
      );
    });
  });

  group('invite links', () {
    test('the valid invite sets a password once and signs in', () async {
      final AppUser user = await auth.setPassword(
        token: MockBackend.validInviteToken,
        password: 'Invited-2026',
      );
      expect(user.email, 'invited@eventor.test');
      await expectApiFailure(
        auth.setPassword(
          token: MockBackend.validInviteToken,
          password: 'Invited-2026',
        ),
        ApiErrorCode.resetTokenInvalid,
      );
    });

    test('the expired invite is 410 and a made-up one 400', () async {
      final ApiFailure expired = await expectApiFailure(
        auth.setPassword(
          token: MockBackend.expiredInviteToken,
          password: 'Invited-2026',
        ),
        ApiErrorCode.resetTokenExpired,
      );
      expect(expired.statusCode, 410);
      await expectApiFailure(
        auth.setPassword(token: 'made-up', password: 'Invited-2026'),
        ApiErrorCode.resetTokenInvalid,
      );
    });
  });

  group('persistence', () {
    test('a restart keeps new accounts and the session', () async {
      await auth.register(client());
      await auth.verifyEmail(email: 'new@eventor.test', code: '123456');

      await start(); // A new backend over the same stored state.

      final AppUser? restored = await auth.restoreSession();
      expect(restored?.email, 'new@eventor.test');
    });

    test('reset goes back to the seeds, signed out', () async {
      await auth.register(client());
      await auth.login(email: 'client@eventor.test', password: 'Eventor2026');

      await backend.reset();

      expect(backend.hasSession, isFalse);
      expect(backend.accountByEmail('new@eventor.test'), isNull);
      expect(backend.accountByEmail('client@eventor.test'), isNotNull);
    });
  });

  group('documents', () {
    late MockDocumentsRepository documents;

    setUp(() async {
      documents = MockDocumentsRepository(backend);
      await auth.login(email: 'provider@eventor.test', password: 'Eventor2026');
    });

    test('start as 21a draws them, and an upload lands as pending', () async {
      final ProviderDocuments before = await documents.fetch();
      expect(
        before.documents.map((ProviderDocument d) => d.status),
        <ProviderDocumentStatus>[
          ProviderDocumentStatus.pending,
          ProviderDocumentStatus.pending,
          ProviderDocumentStatus.missing,
        ],
      );

      final ProviderDocuments after = await documents.upload(
        type: ProviderDocumentType.taxCard,
        path: 'unused',
        fileName: 'nif.pdf',
      );
      expect(
        after.byType(ProviderDocumentType.taxCard)?.status,
        ProviderDocumentStatus.pending,
      );
    });

    test('without a session they are a SessionExpiredFailure', () async {
      await auth.logout();
      await expectLater(documents.fetch(), throwsA(isA<SessionExpiredFailure>()));
    });
  });

  test('reference data is the live snapshot', () async {
    final MockReferenceRepository reference = MockReferenceRepository(backend);
    expect(await reference.wilayas(), hasLength(58));
    expect(await reference.categories(), isNotEmpty);
  });

  group('the client\'s city', () {
    test('comes with the account — the seeded client lives in Alger', () async {
      final AppUser user = await auth.login(
        email: 'client@eventor.test',
        password: MockBackend.seedPassword,
      );

      expect(user.wilaya?.code, 16);
      expect(user.wilaya?.nameEn, 'Alger');
    });

    test('can be changed, and the change is kept', () async {
      await auth.login(
        email: 'client@eventor.test',
        password: MockBackend.seedPassword,
      );

      final AppUser user = await auth.updateWilaya(31);
      expect(user.wilaya?.code, 31);

      await start(); // Same stored state, as after a restart.
      expect((await auth.currentUser()).wilaya?.code, 31);
    });

    test('refuses a wilaya that does not exist', () async {
      await auth.login(
        email: 'client@eventor.test',
        password: MockBackend.seedPassword,
      );

      await expectApiFailure(auth.updateWilaya(99), ApiErrorCode.wilayaNotFound);
    });

    test('needs a session', () async {
      await expectLater(
        auth.updateWilaya(16),
        throwsA(isA<SessionExpiredFailure>()),
      );
    });
  });
}
