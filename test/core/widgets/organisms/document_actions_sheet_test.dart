import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/organisms/app_bottom_sheet.dart';
import 'package:eventor/core/widgets/organisms/document_actions_sheet.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

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
    testWidgets('is built on the shared sheet scaffold',
        (WidgetTester tester) async {
      await pumpOpener(tester);

      expect(find.byType(AppSheetScaffold), findsOneWidget);
    });

    testWidgets('names the file it is about', (WidgetTester tester) async {
      await pumpOpener(tester);

      // Every attached field looks alike, so the sheet has to say which one.
      expect(
        tester.widget<AppSheetScaffold>(find.byType(AppSheetScaffold)).title,
        fileName,
      );
      expect(find.text(fileName), findsOneWidget);
    });

    testWidgets('offers replacing and removing', (WidgetTester tester) async {
      await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.documentReplace), findsOneWidget);
      expect(find.text(strings.documentRemove), findsOneWidget);
    });

    testWidgets('marks only removing as destructive',
        (WidgetTester tester) async {
      await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        tester.widget<Text>(find.text(strings.documentRemove)).style?.color,
        AppColors.textDanger,
      );
      expect(
        tester.widget<Text>(find.text(strings.documentReplace)).style?.color,
        AppColors.textPrimary,
      );
    });

    testWidgets('answers replace', (WidgetTester tester) async {
      final List<DocumentAction?> answers = await pumpOpener(tester);

      await tester.tap(find.text(l10n(tester).documentReplace));
      await tester.pumpAndSettle();

      expect(answers, <DocumentAction?>[DocumentAction.replace]);
      expect(find.byType(AppSheetScaffold), findsNothing);
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

    testWidgets('lays the scrim over the screen at half strength',
        (WidgetTester tester) async {
      await pumpOpener(tester);

      final ModalBarrier barrier = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .last;
      expect(
        barrier.color,
        AppColors.bgScrim.withValues(alpha: AppColors.scrimOpacity),
      );
    });

    testWidgets('reads in Arabic too', (WidgetTester tester) async {
      await pumpOpener(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.documentRemove), findsOneWidget);
    });
  });
}
