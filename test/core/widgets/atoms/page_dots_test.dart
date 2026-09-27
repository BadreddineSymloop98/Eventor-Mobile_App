import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/page_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// The painted dots, in order — the boxes inside each dot's margin.
  Finder dots() => find.descendant(
        of: find.byType(PageDots),
        matching: find.byType(DecoratedBox),
      );

  Color? colorOf(WidgetTester tester, int index) =>
      (tester.widget<DecoratedBox>(dots().at(index)).decoration
              as BoxDecoration)
          .color;

  group('PageDots', () {
    testWidgets('draws one dot per step', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: PageDots(count: 4, currentIndex: 0)),
      );

      expect(dots(), findsNWidgets(4));
    });

    testWidgets('stretches the current step into a pill',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: PageDots(count: 3, currentIndex: 1)),
      );
      final Size first = tester.getSize(dots().at(0));
      final Size current = tester.getSize(dots().at(1));
      final Size last = tester.getSize(dots().at(2));

      expect(current.width, greaterThan(first.width));
      expect(first.width, last.width);
      // Round, not squashed into an ellipse on a tall screen.
      expect(first.height, first.width);
    });

    testWidgets('uses brand and grey on a light surface',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: PageDots(count: 3, currentIndex: 0)),
      );

      expect(colorOf(tester, 0), AppColors.bgBrand);
      expect(colorOf(tester, 1), AppColors.bgDisabled);
    });

    testWidgets('uses white and faded white over a photograph',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(
          child: PageDots(
            count: 3,
            currentIndex: 2,
            tone: PageDotsTone.inverse,
          ),
        ),
      );

      expect(colorOf(tester, 2), AppColors.textOnBrand);
      expect(
        colorOf(tester, 0),
        AppColors.textOnBrand.withValues(alpha: 0.35),
      );
    });

    testWidgets('announces the position, counting from one',
        (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        const Center(child: PageDots(count: 3, currentIndex: 1)),
      );

      expect(
        tester.getSemantics(find.byType(PageDots)),
        isSemantics(label: l10n(tester).sectionProgress(2, 3)),
      );
    });

    testWidgets('starts from the right in Arabic', (WidgetTester tester) async {
      // A paged flow reads right to left in Arabic, so step one is the
      // rightmost dot.
      await pumpAppWidget(
        tester,
        const Center(child: PageDots(count: 3, currentIndex: 0)),
        locale: arabicLocale,
      );

      expect(
        tester.getCenter(dots().at(0)).dx,
        greaterThan(tester.getCenter(dots().at(2)).dx),
      );
    });
  });
}
