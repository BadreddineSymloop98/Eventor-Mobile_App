import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/errors/validation_error.dart';
import 'package:eventor/core/localization/app_localizations_x.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(englishLocale);
    ar = await AppLocalizations.delegate.load(arabicLocale);
  });

  group('failure messages', () {
    test('each failure has its own wording', () {
      expect(en.forFailure(const StorageFailure()), en.errorStorage);
      expect(en.forFailure(const UnexpectedFailure()), en.errorUnexpected);
    });

    test('the cause never reaches the message', () {
      final String message = en.forFailure(
        UnexpectedFailure(cause: Exception('SocketException: host lookup')),
      );

      expect(message, en.errorUnexpected);
      expect(message, isNot(contains('SocketException')));
    });

    test('are translated', () {
      expect(ar.forFailure(const StorageFailure()), ar.errorStorage);
      expect(
        ar.forFailure(const StorageFailure()),
        isNot(en.forFailure(const StorageFailure())),
      );
    });
  });

  group('validation messages', () {
    test('cover every email error', () {
      expect(en.forEmailError(const EmailRequired()), en.emailRequired);
      expect(en.forEmailError(const EmailInvalid()), en.emailInvalid);
    });

    test('cover every password error', () {
      expect(en.forPasswordError(const PasswordRequired()), en.passwordRequired);
      expect(
        en.forPasswordError(const PasswordTooShort(6)),
        en.passwordTooShort(6),
      );
    });

    test('state the bound the error carries, not a hard-coded one', () {
      expect(en.forPasswordError(const PasswordTooShort(6)), contains('6'));
      expect(en.forPasswordError(const PasswordTooShort(12)), contains('12'));
    });

    test('are translated', () {
      expect(ar.forEmailError(const EmailInvalid()), ar.emailInvalid);
      expect(
        ar.forEmailError(const EmailInvalid()),
        isNot(en.forEmailError(const EmailInvalid())),
      );
    });

    test('use the right Arabic plural for the count', () {
      // Arabic distinguishes one, two and few, where English has only one and
      // other. Getting three different sentences out is the proof that the
      // ICU categories are wired up rather than collapsed.
      final Set<String> forms = <String>{
        ar.forPasswordError(const PasswordTooShort(1)),
        ar.forPasswordError(const PasswordTooShort(2)),
        ar.forPasswordError(const PasswordTooShort(6)),
      };

      expect(forms, hasLength(3));
    });
  });

  group('context.l10n', () {
    testWidgets('resolves the strings of the surrounding app',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => Text(context.l10n.logIn),
        ),
        locale: arabicLocale,
      );

      expect(find.text(ar.logIn), findsOneWidget);
    });
  });
}
