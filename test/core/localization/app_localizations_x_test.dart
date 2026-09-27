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
      expect(en.forFailure(const NetworkFailure()), en.errorNetwork);
      expect(
        en.forFailure(const SessionExpiredFailure()),
        en.errorSessionExpired,
      );
      expect(en.forFailure(const UnexpectedFailure()), en.errorUnexpected);
    });

    test('the cause never reaches the message', () {
      final String message = en.forFailure(
        UnexpectedFailure(cause: Exception('SocketException: host lookup')),
      );

      expect(message, en.errorUnexpected);
      expect(message, isNot(contains('SocketException')));
    });

    test("shows the server's own sentence for an API failure", () {
      // It arrives already translated through Accept-Language, and is more
      // specific than anything generic the app could say.
      const ApiFailure failure = ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.emailTaken,
        message: 'هذا البريد مستخدم بالفعل.',
      );

      expect(en.forFailure(failure), 'هذا البريد مستخدم بالفعل.');
      expect(ar.forFailure(failure), 'هذا البريد مستخدم بالفعل.');
    });

    test('falls back to the generic wording when the server says nothing',
        () {
      for (final String message in <String>['', '   ']) {
        final ApiFailure failure = ApiFailure(
          statusCode: 500,
          code: 'INTERNAL_ERROR',
          message: message,
        );

        expect(en.forFailure(failure), en.errorUnexpected);
        expect(ar.forFailure(failure), ar.errorUnexpected);
      }
    });

    test('are translated', () {
      expect(ar.forFailure(const StorageFailure()), ar.errorStorage);
      expect(
        ar.forFailure(const StorageFailure()),
        isNot(en.forFailure(const StorageFailure())),
      );
      expect(
        ar.forFailure(const NetworkFailure()),
        isNot(en.forFailure(const NetworkFailure())),
      );
    });
  });

  group('validation messages', () {
    test('cover every email error', () {
      expect(en.forEmailError(const EmailRequired()), en.emailRequired);
      expect(en.forEmailError(const EmailInvalid()), en.emailInvalid);
      expect(en.forEmailError(const EmailTaken()), en.emailTaken);
    });

    test('cover every name error', () {
      expect(en.forNameError(const NameRequired()), en.nameRequired);
      expect(en.forNameError(const NameTooShort(2)), en.nameTooShort(2));
    });

    test('cover every phone error', () {
      expect(en.forPhoneError(const PhoneRequired()), en.phoneRequired);
      expect(en.forPhoneError(const PhoneInvalid()), en.phoneInvalid);
      expect(en.forPhoneError(const PhoneTaken()), en.phoneTaken);
    });

    test('cover every password error', () {
      expect(en.forPasswordError(const PasswordRequired()), en.passwordRequired);
      expect(
        en.forPasswordError(const PasswordTooShort(10)),
        en.passwordTooShort(10),
      );
      expect(
        en.forPasswordError(const PasswordNeedsLetterAndDigit()),
        en.passwordNeedsLetterAndDigit,
      );
      expect(en.forPasswordError(const PasswordWeak()), en.passwordWeak);
      expect(
        en.forPasswordError(const PasswordMismatch()),
        en.passwordMismatch,
      );
    });

    test('cover every document error', () {
      expect(en.forDocumentError(const DocumentMissing()), en.documentMissing);
      expect(
        en.forDocumentError(const DocumentTooLarge(5)),
        en.documentTooLarge(5),
      );
      expect(
        en.forDocumentError(const DocumentWrongType()),
        en.documentWrongType,
      );
      expect(
        en.forDocumentError(const DocumentUploadFailed()),
        en.documentUploadFailed,
      );
    });

    test('state the bound the error carries, not a hard-coded one', () {
      expect(en.forPasswordError(const PasswordTooShort(6)), contains('6'));
      expect(en.forPasswordError(const PasswordTooShort(12)), contains('12'));
      expect(en.forDocumentError(const DocumentTooLarge(8)), contains('8'));
    });

    test('never leave a message blank, in either language', () {
      for (final AppLocalizations strings in <AppLocalizations>[en, ar]) {
        final List<String> messages = <String>[
          strings.forEmailError(const EmailTaken()),
          strings.forPhoneError(const PhoneInvalid()),
          strings.forPhoneError(const PhoneTaken()),
          strings.forPasswordError(const PasswordNeedsLetterAndDigit()),
          strings.forPasswordError(const PasswordWeak()),
          strings.forPasswordError(const PasswordMismatch()),
          strings.forDocumentError(const DocumentUploadFailed()),
          strings.forFailure(const NetworkFailure()),
          strings.forFailure(const SessionExpiredFailure()),
        ];

        for (final String message in messages) {
          expect(message.trim(), isNotEmpty);
        }
      }
    });

    test('are translated', () {
      expect(ar.forEmailError(const EmailInvalid()), ar.emailInvalid);
      expect(
        ar.forEmailError(const EmailInvalid()),
        isNot(en.forEmailError(const EmailInvalid())),
      );
      expect(
        ar.forPasswordError(const PasswordMismatch()),
        isNot(en.forPasswordError(const PasswordMismatch())),
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
