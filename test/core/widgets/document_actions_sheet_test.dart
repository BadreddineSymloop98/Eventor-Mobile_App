import 'package:eventor/core/widgets/document_actions_sheet.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  const String fileName = 'registre-commerce.pdf';

  /// Puts a button on screen that opens the sheet, and records what it
  /// answered — the sheet needs a route to pop, so it cannot be pumped bare.
  Future<List<DocumentAction?>> pumpOpener(
    WidgetTester tester, {
    Locale locale = englishLocale,
  }) async {
    final List<DocumentAction?> answers = <DocumentAction?>[];

    await pumpAppWidget(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async => answers.add(
            await showDocumentActionsSheet(context, fileName: fileName),
          ),
          child: const Text('open'),
        ),
      ),
      locale: locale,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return answers;
  }

  group('showDocumentActionsSheet', () {
    testWidgets('names the file it is about', (WidgetTester tester) async {
      await pumpOpener(tester);

      // Every attached field looks alike, so the sheet has to say which one.
      expect(find.text(fileName), findsOneWidget);
    });

    testWidgets('offers replacing and removing', (WidgetTester tester) async {
      await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.documentReplace), findsOneWidget);
      expect(find.text(strings.documentRemove), findsOneWidget);
    });

    testWidgets('answers replace', (WidgetTester tester) async {
      final List<DocumentAction?> answers = await pumpOpener(tester);

      await tester.tap(find.text(l10n(tester).documentReplace));
      await tester.pumpAndSettle();

      expect(answers, <DocumentAction?>[DocumentAction.replace]);
    });

    testWidgets('answers remove', (WidgetTester tester) async {
      final List<DocumentAction?> answers = await pumpOpener(tester);

      await tester.tap(find.text(l10n(tester).documentRemove));
      await tester.pumpAndSettle();

      expect(answers, <DocumentAction?>[DocumentAction.remove]);
    });

    testWidgets('answers nothing when it is dismissed',
        (WidgetTester tester) async {
      final List<DocumentAction?> answers = await pumpOpener(tester);

      // Tapping the scrim is how a sheet is usually left, and backing out is
      // not a choice between the two actions.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(answers, <DocumentAction?>[null]);
    });

    testWidgets('reads in Arabic too', (WidgetTester tester) async {
      await pumpOpener(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.documentRemove), findsOneWidget);
    });
  });
}
