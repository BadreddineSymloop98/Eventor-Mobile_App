import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _title = 'I offer services';
const String _description = 'Photographers, venues, caterers and more.';

BorderSide _edge(WidgetTester tester) => ((tester
            .widget<AnimatedContainer>(find.descendant(
              of: find.byType(RoleCard),
              matching: find.byType(AnimatedContainer),
            ))
            .decoration! as BoxDecoration)
        .border! as Border)
    .top;

/// How visible the check is.
double _checkOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  Future<List<int>> pumpCard(
    WidgetTester tester, {
    required bool isSelected,
    String title = _title,
    Locale locale = englishLocale,
  }) async {
    final List<int> taps = <int>[];
    await pumpAppWidget(
      tester,
      RoleCard(
        icon: AppIcons.briefcase,
        title: title,
        description: _description,
        isSelected: isSelected,
        onTap: () => taps.add(1),
      ),
      locale: locale,
    );
    return taps;
  }

  group('RoleCard', () {
    testWidgets('shows its glyph, title and description',
        (WidgetTester tester) async {
      await pumpCard(tester, isSelected: false);

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_description), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is AppIcon && widget.icon == AppIcons.briefcase,
        ),
        findsOneWidget,
      );
    });

    testWidgets('is a thin grey outline with no check when not selected',
        (WidgetTester tester) async {
      await pumpCard(tester, isSelected: false);

      expect(_edge(tester).color, AppColors.borderDefault);
      expect(_edge(tester).width, 1);
      expect(_checkOpacity(tester), 0);
    });

    testWidgets('carries a 2pt brand outline and a check when selected',
        (WidgetTester tester) async {
      // Colour alone never carries a selection: the check is there too.
      await pumpCard(tester, isSelected: true);

      expect(_edge(tester).color, AppColors.borderBrand);
      expect(_edge(tester).width, 2);
      expect(_checkOpacity(tester), 1);
    });

    testWidgets('reports the tap', (WidgetTester tester) async {
      final List<int> taps = await pumpCard(tester, isSelected: false);

      await tester.tap(find.text(_description));

      expect(taps, hasLength(1));
    });

    testWidgets('tells screen readers it is selected',
        (WidgetTester tester) async {
      await pumpCard(tester, isSelected: true);

      final Semantics semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(RoleCard),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.selected, isTrue);
    });

    testWidgets('mirrors in Arabic: glyph on the right, check on the left',
        (WidgetTester tester) async {
      await pumpCard(tester, isSelected: true, title: 'أقدّم خدمات',
          locale: arabicLocale);
      final Finder glyph = find.byWidgetPredicate(
        (Widget widget) => widget is AppIcon && widget.icon == AppIcons.briefcase,
      );
      final Finder check = find.byWidgetPredicate(
        (Widget widget) => widget is AppIcon && widget.icon == AppIcons.check,
      );
      final double title = tester.getCenter(find.text('أقدّم خدمات')).dx;

      expect(tester.getCenter(glyph).dx, greaterThan(title));
      expect(tester.getCenter(check).dx, lessThan(title));
    });
  });
}
