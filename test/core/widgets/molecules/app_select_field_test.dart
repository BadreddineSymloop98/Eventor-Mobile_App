import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/app_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _label = 'Wilaya';
const String _placeholder = 'Choose your wilaya';
const String _helper = 'Where you are based.';
const String _error = 'Choose a wilaya.';

BoxDecoration _box(WidgetTester tester) => tester
    .widget<Container>(find
        .descendant(
          of: find.descendant(
            of: find.byType(AppSelectField),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byType(Container),
        )
        .first)
    .decoration! as BoxDecoration;

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  Future<List<int>> pumpField(
    WidgetTester tester, {
    String? value,
    String? helperText,
    String? errorText,
    bool enabled = true,
    Locale locale = englishLocale,
  }) async {
    final List<int> taps = <int>[];
    await pumpAppWidget(
      tester,
      AppSelectField(
        label: _label,
        value: value,
        placeholder: _placeholder,
        helperText: helperText,
        errorText: errorText,
        onTap: enabled ? () => taps.add(1) : null,
      ),
      locale: locale,
    );
    return taps;
  }

  group('AppSelectField', () {
    testWidgets('shows the placeholder in grey until something is chosen',
        (WidgetTester tester) async {
      await pumpField(tester);

      expect(find.text(_placeholder), findsOneWidget);
      expect(_colorOf(tester, _placeholder), AppColors.textSecondary);
    });

    testWidgets('shows the choice in full colour once made',
        (WidgetTester tester) async {
      await pumpField(tester, value: 'Alger');

      expect(find.text('Alger'), findsOneWidget);
      expect(find.text(_placeholder), findsNothing);
      expect(_colorOf(tester, 'Alger'), AppColors.textPrimary);
    });

    testWidgets('reports the tap that opens the list',
        (WidgetTester tester) async {
      final List<int> taps = await pumpField(tester);

      await tester.tap(find.text(_placeholder));

      expect(taps, hasLength(1));
    });

    testWidgets('carries a down chevron', (WidgetTester tester) async {
      await pumpField(tester);

      expect(
        tester.widget<AppIcon>(find.byType(AppIcon)).icon,
        AppIcons.chevronDown,
      );
    });

    testWidgets('shows the helper in grey', (WidgetTester tester) async {
      await pumpField(tester, helperText: _helper);

      expect(_colorOf(tester, _helper), AppColors.textSecondary);
      expect((_box(tester).border! as Border).top.width, 1);
    });

    testWidgets('replaces the helper with a red error and outline',
        (WidgetTester tester) async {
      await pumpField(tester, helperText: _helper, errorText: _error);

      expect(find.text(_helper), findsNothing);
      expect(_colorOf(tester, _error), AppColors.statusDeclined);
      final BorderSide edge = (_box(tester).border! as Border).top;
      expect(edge.color, AppColors.statusDeclined);
      expect(edge.width, 1.5);
    });

    testWidgets('greys out and ignores taps when disabled',
        (WidgetTester tester) async {
      final List<int> taps =
          await pumpField(tester, value: 'Alger', enabled: false);

      await tester.tap(find.text('Alger'));

      expect(taps, isEmpty);
      expect(_box(tester).color, AppColors.bgDisabled);
      expect(_colorOf(tester, 'Alger'), AppColors.textSecondary);
    });

    testWidgets('announces the label and the choice',
        (WidgetTester tester) async {
      await pumpField(tester, value: 'Alger');

      final Semantics semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(AppSelectField),
                matching: find.byType(GestureDetector),
              ),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.label, _label);
      expect(semantics.properties.value, 'Alger');
    });

    testWidgets('puts the chevron on the left in Arabic',
        (WidgetTester tester) async {
      await pumpField(tester, value: 'الجزائر', locale: arabicLocale);

      expect(
        tester.getCenter(find.byType(AppIcon)).dx,
        lessThan(tester.getCenter(find.text('الجزائر')).dx),
      );
    });
  });
}
