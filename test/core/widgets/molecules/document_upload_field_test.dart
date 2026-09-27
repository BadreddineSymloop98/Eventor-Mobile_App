import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/atoms/app_spinner.dart';
import 'package:eventor/core/widgets/molecules/document_upload_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _label = 'National ID card';
const String _helper = 'Front and back, in one file';
const String _error = 'This file is over 5 MB. Attach a smaller one.';
const String _file = 'id-card.pdf';

Finder _icon(AppIcons icon) => find.byWidgetPredicate(
      (Widget widget) => widget is AppIcon && widget.icon == icon,
    );

/// The outline of the box, which is what carries the state.
BorderSide _edge(WidgetTester tester) => ((tester
            .widget<AnimatedContainer>(find.descendant(
              of: find.byType(DocumentUploadField),
              matching: find.byType(AnimatedContainer),
            ))
            .decoration! as BoxDecoration)
        .border! as Border)
    .top;

/// What the box tells a screen reader — the [Semantics] wrapped around it.
SemanticsProperties _boxSemantics(WidgetTester tester) => tester
    .widget<Semantics>(find
        .ancestor(
          of: find.byType(AnimatedContainer),
          matching: find.byType(Semantics),
        )
        .first)
    .properties;

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  /// Pumps one field; hands back a list that grows with each tap.
  Future<List<int>> pumpField(
    WidgetTester tester, {
    String? fileName,
    String? helperText = _helper,
    String? errorText,
    bool isUploading = false,
    bool tappable = true,
    Locale locale = englishLocale,
  }) async {
    final List<int> taps = <int>[];
    await pumpAppWidget(
      tester,
      DocumentUploadField(
        label: _label,
        fileName: fileName,
        helperText: helperText,
        errorText: errorText,
        isUploading: isUploading,
        onTap: tappable ? () => taps.add(1) : null,
      ),
      locale: locale,
    );
    return taps;
  }

  group('DocumentUploadField.state', () {
    DocumentUploadState stateOf({
      String? fileName,
      String? errorText,
      bool isUploading = false,
    }) =>
        DocumentUploadField(
          label: _label,
          onTap: null,
          fileName: fileName,
          errorText: errorText,
          isUploading: isUploading,
        ).state;

    test('is empty with nothing attached', () {
      expect(stateOf(), DocumentUploadState.empty);
    });

    test('is uploaded once a file is attached', () {
      expect(stateOf(fileName: _file), DocumentUploadState.uploaded);
    });

    test('is rejected when there is an error, file or not', () {
      expect(stateOf(errorText: _error), DocumentUploadState.rejected);
      expect(
        stateOf(fileName: _file, errorText: _error),
        DocumentUploadState.rejected,
      );
    });

    test('is uploading above everything else', () {
      // A new file is on its way; the old verdict no longer applies.
      expect(
        stateOf(fileName: _file, errorText: _error, isUploading: true),
        DocumentUploadState.uploading,
      );
    });
  });

  group('DocumentUploadField empty', () {
    testWidgets('invites an upload, with the grey instruction under it',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(find.text(_label), findsOneWidget);
      expect(find.text(l10n(tester).documentUploadAction), findsOneWidget);
      expect(_colorOf(tester, _helper), AppColors.textSecondary);
      expect(_icon(AppIcons.upload), findsOneWidget);
      expect(_icon(AppIcons.plus), findsOneWidget);
    });

    testWidgets('has a plain solid outline', (WidgetTester tester) async {
      // The dashed border is gone: the field now shares the text field's box.
      await pumpField(tester);

      expect(_edge(tester).color, AppColors.borderDefault);
      expect(_edge(tester).width, 1);
      expect(_edge(tester).style, BorderStyle.solid);
    });
  });

  group('DocumentUploadField uploading', () {
    testWidgets('spins in brand and keeps the file name',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: _file, isUploading: true);

      expect(find.byType(AppSpinner), findsOneWidget);
      expect(find.text(_file), findsOneWidget);
      expect(_edge(tester).color, AppColors.borderBrand);
      expect(_colorOf(tester, _helper), AppColors.textBrand);
    });
  });

  group('DocumentUploadField uploaded', () {
    testWidgets('names the file and ticks it off', (WidgetTester tester) async {
      await pumpField(tester, fileName: _file);

      expect(find.text(_file), findsOneWidget);
      expect(_colorOf(tester, _file), AppColors.textPrimary);
      expect(_icon(AppIcons.fileText), findsOneWidget);
      expect(_icon(AppIcons.check), findsOneWidget);
      expect(tester.widget<AppIcon>(_icon(AppIcons.check)).color,
          AppColors.statusAccepted);
      expect(_edge(tester).color, AppColors.borderBrandSubtle);
    });

    testWidgets('keeps the instruction in grey', (WidgetTester tester) async {
      await pumpField(tester, fileName: _file);

      expect(_colorOf(tester, _helper), AppColors.textSecondary);
    });
  });

  group('DocumentUploadField rejected', () {
    testWidgets('outlines in red and says why, in place of the helper',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: _file, errorText: _error);

      expect(find.text(_error), findsOneWidget);
      expect(find.text(_helper), findsNothing);
      expect(_colorOf(tester, _error), AppColors.textDanger);
      expect(_edge(tester).color, AppColors.borderDanger);
      expect(_edge(tester).width, 1.5);
      expect(_icon(AppIcons.close), findsOneWidget);
    });
  });

  group('DocumentUploadField taps', () {
    testWidgets('opens the picker from the box, not the label',
        (WidgetTester tester) async {
      final List<int> taps = await pumpField(tester);

      await tester.tap(find.text(_label));
      expect(taps, isEmpty);

      await tester.tap(find.text(l10n(tester).documentUploadAction));
      expect(taps, hasLength(1));
    });

    testWidgets('announces itself as a button carrying its file',
        (WidgetTester tester) async {
      await pumpField(tester, fileName: _file, helperText: null);

      final SemanticsProperties box = _boxSemantics(tester);
      expect(box.button, isTrue);
      expect(box.label, _label);
      expect(box.value, _file);
    });

    testWidgets('announces the invitation while empty',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(_boxSemantics(tester).value, l10n(tester).documentUploadAction);
    });

    testWidgets('is not a button without a handler',
        (WidgetTester tester) async {
      final List<int> taps = await pumpField(tester, tappable: false);

      await tester.tap(find.text(l10n(tester).documentUploadAction));

      expect(taps, isEmpty);
      expect(_boxSemantics(tester).button, isFalse);
    });
  });

  group('DocumentUploadField in Arabic', () {
    testWidgets('puts the state glyph on the left', (WidgetTester tester) async {
      await pumpField(tester, fileName: _file, locale: arabicLocale);

      expect(
        tester.getCenter(_icon(AppIcons.check)).dx,
        lessThan(tester.getCenter(_icon(AppIcons.fileText)).dx),
      );
    });
  });
}
