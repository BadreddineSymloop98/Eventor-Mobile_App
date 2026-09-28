import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// The knob: the only box inside the sliding alignment.
  Finder knob() => find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Container),
      );

  /// The track the knob slides along.
  Finder track() => find.descendant(
        of: find.byType(AppSwitch),
        matching: find.byType(AnimatedContainer),
      );

  /// Which side of the track the knob sits on, as drawn.
  bool knobIsOnTheRight(WidgetTester tester) =>
      tester.getCenter(knob()).dx > tester.getCenter(track()).dx;

  Future<List<bool>> pumpSwitch(
    WidgetTester tester, {
    required bool value,
    bool enabled = true,
    Locale locale = englishLocale,
  }) async {
    final List<bool> changes = <bool>[];
    await pumpAppWidget(
      tester,
      Center(
        child: AppSwitch(
          value: value,
          onChanged: enabled ? changes.add : null,
          semanticLabel: 'Notifications',
        ),
      ),
      locale: locale,
    );
    return changes;
  }

  group('AppSwitch', () {
    testWidgets('asks to turn on when off', (WidgetTester tester) async {
      final List<bool> changes = await pumpSwitch(tester, value: false);

      await tester.tap(find.byType(AppSwitch));

      expect(changes, <bool>[true]);
    });

    testWidgets('asks to turn off when on', (WidgetTester tester) async {
      final List<bool> changes = await pumpSwitch(tester, value: true);

      await tester.tap(find.byType(AppSwitch));

      expect(changes, <bool>[false]);
    });

    testWidgets('holds no state of its own', (WidgetTester tester) async {
      // The caller decides; a tap that is not written back changes nothing.
      await pumpSwitch(tester, value: false);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      expect(knobIsOnTheRight(tester), isFalse);
    });

    testWidgets('puts the knob at the end on a brand track when on',
        (WidgetTester tester) async {
      await pumpSwitch(tester, value: true);

      expect(knobIsOnTheRight(tester), isTrue);
      expect(
        (tester.widget<AnimatedContainer>(track()).decoration! as BoxDecoration)
            .color,
        AppColors.bgBrand,
      );
    });

    testWidgets('puts the knob at the start on a grey track when off',
        (WidgetTester tester) async {
      await pumpSwitch(tester, value: false);

      expect(knobIsOnTheRight(tester), isFalse);
      expect(
        (tester.widget<AnimatedContainer>(track()).decoration! as BoxDecoration)
            .color,
        AppColors.bgDisabled,
      );
    });

    testWidgets('mirrors in Arabic: on is the left', (WidgetTester tester) async {
      await pumpSwitch(tester, value: true, locale: arabicLocale);

      expect(knobIsOnTheRight(tester), isFalse);
    });

    testWidgets('mirrors in Arabic: off is the right',
        (WidgetTester tester) async {
      await pumpSwitch(tester, value: false, locale: arabicLocale);

      expect(knobIsOnTheRight(tester), isTrue);
    });

    testWidgets('ignores taps and fades when disabled',
        (WidgetTester tester) async {
      final List<bool> changes =
          await pumpSwitch(tester, value: true, enabled: false);

      await tester.tap(find.byType(AppSwitch), warnIfMissed: false);

      expect(changes, isEmpty);
      expect(
        tester
            .widget<Opacity>(find.descendant(
              of: find.byType(AppSwitch),
              matching: find.byType(Opacity),
            ))
            .opacity,
        0.5,
      );
    });

    testWidgets('reports its state to screen readers',
        (WidgetTester tester) async {
      await pumpSwitch(tester, value: true);

      expect(
        tester.getSemantics(find.byType(AppSwitch)),
        isSemantics(label: 'Notifications', isToggled: true, isEnabled: true),
      );
    });

    testWidgets('sits inside a full tap target', (WidgetTester tester) async {
      await pumpSwitch(tester, value: false);

      expect(
        tester.getSize(find.byType(AppSwitch)).height,
        greaterThanOrEqualTo(AppSizes.touchTarget.dh),
      );
    });
  });
}
