import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/models/account.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/app_text_field.dart';
import 'package:eventor/core/widgets/molecules/inline_banner.dart';
import 'package:eventor/features/auth/data/auth_repository.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/register/view/register_view.dart';
import 'package:eventor/features/verify_email/view/verify_email_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<TestApp> pumpRegister(
    WidgetTester tester, {
    UserRole role = UserRole.client,
    Locale? locale,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
    );
    await startAt(tester, app, AppRoutes.registerFor(role));
    expect(find.byType(RegisterView), findsOneWidget);
    return app;
  }

  Finder field(String label) => find.widgetWithText(AppTextField, label);

  /// Fills the four personal fields with values that pass.
  Future<void> fillPersonal(WidgetTester tester) async {
    final AppLocalizations strings = l10n(tester);
    await typeInto(tester, field(strings.nameLabel), 'Amina Benali');
    await typeInto(tester, field(strings.emailLabel), 'amina@example.com');
    await typeInto(tester, field(strings.phoneLabel), '0555123456');
    await typeInto(tester, field(strings.passwordLabel), 'secret12345');
  }

  Future<void> submit(WidgetTester tester) async {
    await tapAndSettle(tester, button(l10n(tester).registerCreateAccount));
  }

  group('RegisterView as a client (08)', () {
    testWidgets('asks for the personal fields and an optional wilaya', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.registerTitle), findsOneWidget);
      expect(find.text(strings.registerSubtitle), findsOneWidget);
      expect(field(strings.nameLabel), findsOneWidget);
      expect(field(strings.emailLabel), findsOneWidget);
      expect(field(strings.phoneLabel), findsOneWidget);
      expect(field(strings.passwordLabel), findsOneWidget);
      expect(find.text(strings.wilayaOptionalLabel), findsOneWidget);
      // None of the business section.
      expect(find.text(strings.registerBusinessTitle), findsNothing);
      expect(field(strings.businessNameLabel), findsNothing);
      expect(find.text(strings.categoryLabel), findsNothing);
      expect(find.text(strings.wilayasServedLabel), findsNothing);
    });

    testWidgets('Create account waits for the four fields', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      final String create = l10n(tester).registerCreateAccount;

      expect(isTappable(tester, create), isFalse);
      await fillPersonal(tester);
      expect(isTappable(tester, create), isTrue);
    });

    testWidgets('a valid form goes on to confirm the email', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      await fillPersonal(tester);

      await submit(tester);

      expect(app.auth.registrations.single.email, 'amina@example.com');
      expect(find.byType(VerifyEmailView), findsOneWidget);
      expect(
        find.text(l10n(tester).verifyEmailSubtitle('amina@example.com')),
        findsOneWidget,
      );
    });

    testWidgets('explains a rule the password breaks', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      await fillPersonal(tester);
      await typeInto(tester, field(l10n(tester).passwordLabel), 'short1');

      await submit(tester);

      expect(find.text(l10n(tester).passwordTooShort(10)), findsOneWidget);
      expect(find.byType(RegisterView), findsOneWidget);
    });

    testWidgets('EMAIL_TAKEN shows the 08b banner, not a field error', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      app.auth.registerError = apiFailure(
        ApiErrorCode.emailTaken,
        statusCode: 409,
      );
      await fillPersonal(tester);

      await submit(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.widgetWithText(InlineBanner, strings.registerEmailTakenTitle),
        findsOneWidget,
      );
      expect(find.text(strings.registerEmailTakenBody), findsOneWidget);
      // The banner already says it; repeating it under the field is noise.
      expect(find.text(strings.emailTaken), findsNothing);
    });

    testWidgets('after 08b, Log in carries the address over', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      app.auth.registerError = apiFailure(
        ApiErrorCode.emailTaken,
        statusCode: 409,
      );
      await fillPersonal(tester);
      await submit(tester);

      await tapAndSettle(tester, find.text(l10n(tester).logIn));

      expect(find.byType(LoginView), findsOneWidget);
      final AppTextField email = tester.widget<AppTextField>(
        field(l10n(tester).emailLabel),
      );
      expect(email.controller.text, 'amina@example.com');
    });

    testWidgets('editing the address retires the 08b banner', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      app.auth.registerError = apiFailure(
        ApiErrorCode.emailTaken,
        statusCode: 409,
      );
      await fillPersonal(tester);
      await submit(tester);

      await typeInto(tester, field(l10n(tester).emailLabel), 'new@example.com');

      expect(find.byType(InlineBanner), findsNothing);
    });

    testWidgets('PHONE_TAKEN is shown under the phone field', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      app.auth.registerError = apiFailure(
        ApiErrorCode.phoneTaken,
        statusCode: 409,
      );
      await fillPersonal(tester);

      await submit(tester);

      expect(find.text(l10n(tester).phoneTaken), findsOneWidget);
      expect(find.byType(InlineBanner), findsNothing);
    });

    testWidgets('the optional wilaya is picked from a sheet', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester);
      await fillPersonal(tester);

      await tapAndSettle(tester, find.text(l10n(tester).wilayaPlaceholder));
      await tapAndSettle(tester, find.text('16 — Alger'));
      expect(find.text('Alger'), findsOneWidget);

      await submit(tester);
      expect(app.auth.registrations.single.wilayaCode, 16);
    });
  });

  group('RegisterView as a provider (08a)', () {
    testWidgets('adds the business section instead of the wilaya', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester, role: UserRole.provider);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.registerSubtitleProvider), findsOneWidget);
      expect(find.text(strings.registerBusinessTitle), findsOneWidget);
      expect(field(strings.businessNameLabel), findsOneWidget);
      expect(find.text(strings.categoryLabel), findsOneWidget);
      expect(find.text(strings.wilayasServedLabel), findsOneWidget);
      expect(find.text(strings.wilayaOptionalLabel), findsNothing);
    });

    testWidgets('sends the business picked through the sheets', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester, role: UserRole.provider);
      final AppLocalizations strings = l10n(tester);
      await fillPersonal(tester);
      await typeInto(tester, field(strings.businessNameLabel), 'Studio 21');
      expect(isTappable(tester, strings.registerCreateAccount), isFalse);

      await tapAndSettle(tester, find.text(strings.categoryPlaceholder));
      await tapAndSettle(tester, find.text('Photography'));

      await tapAndSettle(tester, find.text(strings.wilayasServedPlaceholder));
      await tapAndSettle(tester, find.text('09 — Blida'));
      await tapAndSettle(tester, find.text('16 — Alger'));
      await tapAndSettle(tester, button(strings.selectionDoneCount(2)));

      expect(find.text('Photography'), findsOneWidget);
      expect(find.text('Blida, Alger'), findsOneWidget);
      expect(isTappable(tester, strings.registerCreateAccount), isTrue);

      await submit(tester);

      final RegistrationRequest sent = app.auth.registrations.single;
      expect(sent.role, UserRole.provider);
      expect(sent.businessName, 'Studio 21');
      expect(sent.categoryId, 'cat-photo');
      expect(sent.wilayaCodes, unorderedEquals(<int>[9, 16]));
      expect(find.byType(VerifyEmailView), findsOneWidget);
    });

    testWidgets('CATEGORY_NOT_FOUND asks for the category again', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpRegister(tester, role: UserRole.provider);
      final AppLocalizations strings = l10n(tester);
      app.auth.registerError = apiFailure(
        ApiErrorCode.categoryNotFound,
        statusCode: 404,
      );
      await fillPersonal(tester);
      await typeInto(tester, field(strings.businessNameLabel), 'Studio 21');
      await tapAndSettle(tester, find.text(strings.categoryPlaceholder));
      await tapAndSettle(tester, find.text('Photography'));
      await tapAndSettle(tester, find.text(strings.wilayasServedPlaceholder));
      await tapAndSettle(tester, find.text('16 — Alger'));
      await tapAndSettle(tester, button(strings.selectionDoneCount(1)));

      await submit(tester);

      expect(find.text(strings.categoryRequired), findsOneWidget);
      expect(find.text(strings.categoryPlaceholder), findsOneWidget);
    });
  });

  group('RegisterView in Arabic', () {
    testWidgets('mirrors the form but keeps email and phone left to right', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(
        Directionality.of(tester.element(find.byType(RegisterView))),
        TextDirection.rtl,
      );
      expect(find.text(strings.registerTitle), findsOneWidget);
      for (final String label in <String>[
        strings.emailLabel,
        strings.phoneLabel,
        strings.passwordLabel,
      ]) {
        expect(
          tester.widget<AppTextField>(field(label)).textDirection,
          TextDirection.ltr,
        );
      }
    });

    testWidgets('names the wilayas in Arabic', (WidgetTester tester) async {
      await pumpRegister(tester, locale: arabicLocale);

      await tapAndSettle(tester, find.text(l10n(tester).wilayaPlaceholder));

      expect(find.text('16 — الجزائر'), findsOneWidget);
    });
  });
}
