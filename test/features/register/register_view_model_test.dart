import 'dart:async';

import 'package:eventor/core/config/app_config.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/register/view_model/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeReferenceRepository reference;

  setUp(() {
    auth = FakeAuthRepository();
    reference = FakeReferenceRepository();
  });

  /// A view model for [role], with its reference lists already loaded.
  Future<RegisterViewModel> build({
    UserRole role = UserRole.client,
    AppConfig config = const AppConfig(),
    String language = 'en',
  }) async {
    final RegisterViewModel viewModel = RegisterViewModel(
      auth: auth,
      reference: reference,
      config: config,
      role: role,
      languageCode: () => language,
    );
    addTearDown(viewModel.dispose);
    await flushAsync();
    return viewModel;
  }

  /// Fills the personal fields with values that pass, so a test can spoil
  /// one and watch only that one's answer change.
  void fillPersonal(RegisterViewModel viewModel) {
    viewModel.nameController.text = 'Amina Benali';
    viewModel.emailController.text = '  amina@example.com ';
    viewModel.phoneController.text = '0555 12 34 56';
    viewModel.passwordController.text = 'secret12345';
  }

  /// Fills the provider's business section on top of [fillPersonal].
  void fillBusiness(RegisterViewModel viewModel) {
    viewModel.businessNameController.text = ' Studio 21 ';
    viewModel.selectCategory(FakeReferenceRepository.sampleCategories.first);
    viewModel.selectWilayasServed(<Wilaya>{
      FakeReferenceRepository.sampleWilayas[1],
      FakeReferenceRepository.sampleWilayas[0],
    });
  }

  group('RegisterViewModel reference lists', () {
    test('a client loads the wilayas but not the categories', () async {
      final RegisterViewModel viewModel = await build();

      expect(viewModel.wilayas, FakeReferenceRepository.sampleWilayas);
      expect(viewModel.categories, isEmpty);
      expect(viewModel.isLoadingReference, isFalse);
      expect(viewModel.referenceFailed, isFalse);
    });

    test('a provider loads both', () async {
      final RegisterViewModel viewModel = await build(role: UserRole.provider);

      expect(viewModel.wilayas, FakeReferenceRepository.sampleWilayas);
      expect(viewModel.categories, FakeReferenceRepository.sampleCategories);
    });

    test('a failed load is reported and can be retried', () async {
      reference.fail = true;
      final RegisterViewModel viewModel = await build();

      expect(viewModel.referenceFailed, isTrue);
      expect(viewModel.wilayas, isEmpty);

      reference.fail = false;
      await viewModel.loadReference();

      expect(viewModel.referenceFailed, isFalse);
      expect(viewModel.wilayas, isNotEmpty);
    });
  });

  group('RegisterViewModel canSubmit', () {
    test('a client needs the four personal fields and nothing else', () async {
      final RegisterViewModel viewModel = await build();
      expect(viewModel.canSubmit, isFalse);

      fillPersonal(viewModel);

      // The wilaya is optional for a client.
      expect(viewModel.canSubmit, isTrue);
    });

    test('a provider also needs a business, a category and wilayas', () async {
      final RegisterViewModel viewModel = await build(role: UserRole.provider);
      fillPersonal(viewModel);
      expect(viewModel.canSubmit, isFalse);

      viewModel.businessNameController.text = 'Studio 21';
      expect(viewModel.canSubmit, isFalse);

      viewModel.selectCategory(FakeReferenceRepository.sampleCategories.first);
      expect(viewModel.canSubmit, isFalse);

      viewModel.selectWilayasServed(<Wilaya>{
        FakeReferenceRepository.sampleWilayas.first,
      });
      expect(viewModel.canSubmit, isTrue);
    });
  });

  group('RegisterViewModel validation', () {
    test(
      'an empty form reports every personal field and sends nothing',
      () async {
        final RegisterViewModel viewModel = await build();

        expect(await viewModel.submit(), isNull);

        expect(viewModel.nameError, isA<NameRequired>());
        expect(viewModel.emailError, isA<EmailRequired>());
        expect(viewModel.phoneError, isA<PhoneRequired>());
        expect(viewModel.passwordError, isA<PasswordRequired>());
        expect(auth.registrations, isEmpty);
      },
    );

    test('a one-letter name is too short', () async {
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);
      viewModel.nameController.text = 'A';

      expect(await viewModel.submit(), isNull);
      expect(viewModel.nameError, isA<NameTooShort>());
    });

    test('an address without a domain is invalid', () async {
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);
      viewModel.emailController.text = 'amina@';

      expect(await viewModel.submit(), isNull);
      expect(viewModel.emailError, isA<EmailInvalid>());
    });

    test(
      'a phone number that is neither 0XXXXXXXXX nor +213 is invalid',
      () async {
        final RegisterViewModel viewModel = await build();
        fillPersonal(viewModel);
        viewModel.phoneController.text = '555 12 34';

        expect(await viewModel.submit(), isNull);
        expect(viewModel.phoneError, isA<PhoneInvalid>());
        expect(auth.registrations, isEmpty);
      },
    );

    test('the password follows the server policy: 10 characters', () async {
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);
      viewModel.passwordController.text = 'abc123';

      expect(await viewModel.submit(), isNull);
      expect(
        viewModel.passwordError,
        isA<PasswordTooShort>().having(
          (PasswordTooShort e) => e.minimumLength,
          'minimumLength',
          10,
        ),
      );
    });

    test(
      'the password follows the server policy: a letter and a digit',
      () async {
        final RegisterViewModel viewModel = await build();
        fillPersonal(viewModel);
        viewModel.passwordController.text = 'abcdefghijkl';

        expect(await viewModel.submit(), isNull);
        expect(viewModel.passwordError, isA<PasswordNeedsLetterAndDigit>());
      },
    );

    test('a stricter policy from the config is the one enforced', () async {
      final RegisterViewModel viewModel = await build(
        config: const AppConfig(passwordMinLength: 14),
      );
      fillPersonal(viewModel);

      expect(viewModel.minPasswordLength, 14);
      expect(await viewModel.submit(), isNull);
      expect(
        viewModel.passwordError,
        isA<PasswordTooShort>().having(
          (PasswordTooShort e) => e.minimumLength,
          'minimumLength',
          14,
        ),
      );
    });

    test(
      'a provider missing the business section is told what is missing',
      () async {
        final RegisterViewModel viewModel = await build(
          role: UserRole.provider,
        );
        fillPersonal(viewModel);

        expect(await viewModel.submit(), isNull);
        expect(viewModel.businessNameError, isA<NameRequired>());
        expect(viewModel.categoryError, isA<SelectionRequired>());
        expect(viewModel.wilayasError, isA<SelectionRequired>());
        expect(auth.registrations, isEmpty);
      },
    );

    test('an error clears once its own field changes, not before', () async {
      final RegisterViewModel viewModel = await build();
      await viewModel.submit();

      viewModel.emailController.text = 'a';
      expect(viewModel.emailError, isNull);
      // Untouched fields keep their verdicts.
      expect(viewModel.nameError, isA<NameRequired>());
    });

    test('picking what was missing clears its error', () async {
      final RegisterViewModel viewModel = await build(role: UserRole.provider);
      await viewModel.submit();

      viewModel.selectCategory(FakeReferenceRepository.sampleCategories.first);
      viewModel.selectWilayasServed(<Wilaya>{
        FakeReferenceRepository.sampleWilayas.first,
      });

      expect(viewModel.categoryError, isNull);
      expect(viewModel.wilayasError, isNull);
    });
  });

  group('RegisterViewModel submit', () {
    test(
      'a client sends the personal fields, trimmed and normalised',
      () async {
        final RegisterViewModel viewModel = await build(language: 'ar');
        fillPersonal(viewModel);
        viewModel.selectWilaya(FakeReferenceRepository.sampleWilayas[1]);

        final VerifyEmailArgs? args = await viewModel.submit();

        expect(auth.registrations, hasLength(1));
        final RegistrationRequest sent = auth.registrations.single;
        expect(sent.role, UserRole.client);
        expect(sent.fullName, 'Amina Benali');
        expect(sent.email, 'amina@example.com');
        // Spaces typed between groups are not part of the number.
        expect(sent.phone, '0555123456');
        expect(sent.password, 'secret12345');
        // The emails the account receives follow the language on screen.
        expect(sent.language, 'ar');
        expect(sent.wilayaCode, 16);
        // A client never sends provider fields — the API refuses them.
        expect(sent.businessName, isNull);
        expect(sent.categoryId, isNull);
        expect(sent.wilayaCodes, isEmpty);
        expect(sent.toJson().containsKey('businessName'), isFalse);

        expect(args, isNotNull);
        expect(args!.email, 'amina@example.com');
        expect(args.resendAfterSeconds, auth.resendAfterSeconds);
      },
    );

    test('a client without a wilaya sends none', () async {
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);

      await viewModel.submit();

      expect(auth.registrations.single.wilayaCode, isNull);
    });

    test('a +213 number is accepted and sent in the local form', () async {
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);
      viewModel.phoneController.text = '+213 555 12 34 56';

      await viewModel.submit();

      expect(auth.registrations.single.phone, '0555123456');
    });

    test('a provider sends the business section as well', () async {
      final RegisterViewModel viewModel = await build(role: UserRole.provider);
      fillPersonal(viewModel);
      fillBusiness(viewModel);

      final VerifyEmailArgs? args = await viewModel.submit();

      final RegistrationRequest sent = auth.registrations.single;
      expect(sent.role, UserRole.provider);
      expect(sent.businessName, 'Studio 21');
      expect(sent.categoryId, 'cat-photo');
      expect(sent.wilayaCodes, unorderedEquals(<int>[16, 9]));
      // The single wilaya is the client's own; for a provider it would be an
      // arbitrary pick from the served set.
      expect(sent.wilayaCode, isNull);
      expect(sent.language, 'en');
      expect(args, isNotNull);
    });

    test(
      'is busy while the request is out, and ignores a second tap',
      () async {
        final RegisterViewModel viewModel = await build();
        fillPersonal(viewModel);
        final Completer<void> gate = Completer<void>();
        auth.gate = gate;

        final Future<VerifyEmailArgs?> pending = viewModel.submit();
        await flushAsync();

        expect(viewModel.isBusy, isTrue);
        expect(await viewModel.submit(), isNull);

        gate.complete();
        expect(await pending, isNotNull);
        expect(viewModel.isBusy, isFalse);
        expect(auth.registrations, hasLength(1));
      },
    );
  });

  group('RegisterViewModel server refusals', () {
    test('EMAIL_TAKEN raises the 08b banner and marks the address', () async {
      auth.registerError = apiFailure(ApiErrorCode.emailTaken, statusCode: 409);
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.emailTaken, isTrue);
      expect(viewModel.emailError, isA<EmailTaken>());
      // Turned into a banner, so nothing is left for a generic toast.
      expect(viewModel.failure, isNull);
      expect(viewModel.hasError, isFalse);
    });

    test('editing the address retires the 08b banner', () async {
      auth.registerError = apiFailure(ApiErrorCode.emailTaken, statusCode: 409);
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);
      await viewModel.submit();

      viewModel.emailController.text = 'other@example.com';

      expect(viewModel.emailTaken, isFalse);
      expect(viewModel.emailError, isNull);
    });

    test('PHONE_TAKEN is an error on the phone field', () async {
      auth.registerError = apiFailure(ApiErrorCode.phoneTaken, statusCode: 409);
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);

      await viewModel.submit();

      expect(viewModel.phoneError, isA<PhoneTaken>());
      expect(viewModel.emailTaken, isFalse);
      expect(viewModel.failure, isNull);
    });

    test('PASSWORD_WEAK is an error on the password field', () async {
      auth.registerError = apiFailure(ApiErrorCode.passwordWeak);
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);

      await viewModel.submit();

      expect(viewModel.passwordError, isA<PasswordWeak>());
      expect(viewModel.failure, isNull);
    });

    test('CATEGORY_NOT_FOUND clears the pick and asks for another', () async {
      auth.registerError = apiFailure(
        ApiErrorCode.categoryNotFound,
        statusCode: 404,
      );
      final RegisterViewModel viewModel = await build(role: UserRole.provider);
      fillPersonal(viewModel);
      fillBusiness(viewModel);

      await viewModel.submit();
      await flushAsync();

      expect(viewModel.category, isNull);
      expect(viewModel.categoryError, isA<SelectionRequired>());
      expect(viewModel.failure, isNull);
      // The list is reloaded, since the category vanished from it.
      expect(viewModel.categories, isNotEmpty);
    });

    test(
      'WILAYA_NOT_FOUND clears a provider\'s wilayas and asks again',
      () async {
        auth.registerError = apiFailure(
          ApiErrorCode.wilayaNotFound,
          statusCode: 404,
        );
        final RegisterViewModel viewModel = await build(
          role: UserRole.provider,
        );
        fillPersonal(viewModel);
        fillBusiness(viewModel);

        await viewModel.submit();

        expect(viewModel.wilayasServed, isEmpty);
        expect(viewModel.wilayasError, isA<SelectionRequired>());
      },
    );

    test(
      'WILAYA_NOT_FOUND clears a client\'s wilaya and leaves the reason to '
      'the view',
      () async {
        auth.registerError = apiFailure(
          ApiErrorCode.wilayaNotFound,
          statusCode: 404,
        );
        final RegisterViewModel viewModel = await build();
        fillPersonal(viewModel);
        viewModel.selectWilaya(FakeReferenceRepository.sampleWilayas[1]);

        await viewModel.submit();

        expect(viewModel.wilaya, isNull);
        // The optional field has no error line, so the failure stays for the
        // view to report instead of the choice silently vanishing.
        expect(viewModel.failure, isA<ApiFailure>());
      },
    );

    test('anything else is left for the view to report', () async {
      auth.registerError = const NetworkFailure();
      final RegisterViewModel viewModel = await build();
      fillPersonal(viewModel);

      expect(await viewModel.submit(), isNull);

      expect(viewModel.failure, isA<NetworkFailure>());
      expect(viewModel.emailTaken, isFalse);
    });
  });
}
