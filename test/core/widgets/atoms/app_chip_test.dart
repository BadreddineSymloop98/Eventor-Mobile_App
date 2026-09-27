import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  const String label = 'Photography';

  BoxDecoration pillOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.descendant(
        of: find.byType(AppChip),
        matching: find.byType(AnimatedContainer),
      ))
      .decoration! as BoxDecoration;

  Color? labelColor(WidgetTester tester) =>
      tester.widget<Text>(find.text(label)).style?.color;

  Future<List<int>> pumpChip(
    WidgetTester tester, {
    required bool isSelected,
    bool enabled = true,
  }) async {
    final List<int> taps = <int>[];
    await pumpAppWidget(
      tester,
      Center(
        child: AppChip(
          label: label,
          isSelected: isSelected,
          onTap: enabled ? () => taps.add(1) : null,
        ),
      ),
    );
    return taps;
  }

  group('AppChip', () {
    testWidgets('is outlined with a grey label by default',
        (WidgetTester tester) async {
      await pumpChip(tester, isSelected: false);

      expect(pillOf(tester).color, AppColors.bgSurface);
      expect(pillOf(tester).border, isNotNull);
      expect(labelColor(tester), AppColors.textSecondary);
    });

    testWidgets('fills with brand and drops the outline when selected',
        (WidgetTester tester) async {
      await pumpChip(tester, isSelected: true);

      expect(pillOf(tester).color, AppColors.bgBrand);
      expect(pillOf(tester).border, isNull);
      expect(labelColor(tester), AppColors.textOnBrand);
    });

    testWidgets('greys out when disabled, even if selected',
        (WidgetTester tester) async {
      await pumpChip(tester, isSelected: true, enabled: false);

      expect(pillOf(tester).color, AppColors.bgDisabled);
      expect(labelColor(tester), AppColors.textSecondary);
    });

    testWidgets('reports the tap', (WidgetTester tester) async {
      final List<int> taps = await pumpChip(tester, isSelected: false);

      await tester.tap(find.byType(AppChip));

      expect(taps, hasLength(1));
    });

    testWidgets('ignores the tap when disabled', (WidgetTester tester) async {
      final List<int> taps =
          await pumpChip(tester, isSelected: false, enabled: false);

      await tester.tap(find.byType(AppChip));

      expect(taps, isEmpty);
    });

    testWidgets('carries its selection to screen readers',
        (WidgetTester tester) async {
      await pumpChip(tester, isSelected: true);

      expect(
        tester.getSemantics(find.byType(AppChip)),
        isSemantics(
          label: label,
          isButton: true,
          isSelected: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('extends its tap area to a finger without drawing bigger',
        (WidgetTester tester) async {
      await pumpChip(tester, isSelected: false);

      expect(
        tester.getSize(find.byType(AppChip)).height,
        greaterThanOrEqualTo(AppSizes.touchTarget.dh),
      );
      expect(
        tester
            .getSize(find.descendant(
              of: find.byType(AppChip),
              matching: find.byType(AnimatedContainer),
            ))
            .height,
        AppSizes.controlSm.dh,
      );
    });
  });
}
