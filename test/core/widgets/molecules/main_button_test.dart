import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/atoms/app_spinner.dart';
import 'package:eventor/core/widgets/molecules/main_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _label = 'Tap me';

/// What a button should look like in one state: its fill, its outline and
/// the colour of its label.
typedef _Look = ({Color? fill, Color? border, Color label});

/// Resting colours for every style × tone, as the design draws them.
const Map<MainButtonStyle, Map<MainButtonTone, _Look>> _resting =
    <MainButtonStyle, Map<MainButtonTone, _Look>>{
  MainButtonStyle.primary: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: AppColors.bgBrand,
      border: null,
      label: AppColors.textOnBrand,
    ),
    MainButtonTone.inverse: (
      fill: AppColors.bgSurface,
      border: null,
      label: AppColors.textBrand,
    ),
    MainButtonTone.danger: (
      fill: AppColors.bgDanger,
      border: null,
      label: AppColors.textOnDanger,
    ),
  },
  MainButtonStyle.secondary: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: AppColors.bgSurface,
      border: AppColors.borderBrand,
      label: AppColors.textBrand,
    ),
    // Over a photograph: no fill, a white outline.
    MainButtonTone.inverse: (
      fill: null,
      border: AppColors.borderOnBrand,
      label: AppColors.textOnBrand,
    ),
    MainButtonTone.danger: (
      fill: AppColors.bgSurface,
      border: AppColors.borderDanger,
      label: AppColors.textDanger,
    ),
  },
  MainButtonStyle.ghost: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: null,
      border: null,
      label: AppColors.textBrand,
    ),
    MainButtonTone.inverse: (
      fill: null,
      border: null,
      label: AppColors.textOnBrand,
    ),
    MainButtonTone.danger: (
      fill: null,
      border: null,
      label: AppColors.textDanger,
    ),
  },
};

/// The fill under a finger, for every style × tone.
final Map<MainButtonStyle, Map<MainButtonTone, Color>> _pressed =
    <MainButtonStyle, Map<MainButtonTone, Color>>{
  MainButtonStyle.primary: <MainButtonTone, Color>{
    MainButtonTone.normal: AppColors.bgBrandPressed,
    MainButtonTone.inverse: AppColors.bgSurfacePressed,
    MainButtonTone.danger: AppColors.bgDangerPressed,
  },
  for (final MainButtonStyle style in <MainButtonStyle>[
    MainButtonStyle.secondary,
    MainButtonStyle.ghost,
  ])
    style: <MainButtonTone, Color>{
      MainButtonTone.normal: AppColors.bgBrandSubtle,
      // A solid white wash would hide the white label, so it is 16%.
      MainButtonTone.inverse: AppColors.bgSurface.withValues(alpha: 0.16),
      MainButtonTone.danger: AppColors.bgDangerSubtle,
    },
};

/// Disabled colours. Only the inverse outlined and ghost buttons differ,
/// fading to the lighter grey so they still show on a photograph.
const Map<MainButtonStyle, Map<MainButtonTone, _Look>> _disabled =
    <MainButtonStyle, Map<MainButtonTone, _Look>>{
  MainButtonStyle.primary: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: AppColors.bgDisabled,
      border: null,
      label: AppColors.textSecondary,
    ),
    MainButtonTone.inverse: (
      fill: AppColors.bgDisabled,
      border: null,
      label: AppColors.textSecondary,
    ),
    MainButtonTone.danger: (
      fill: AppColors.bgDisabled,
      border: null,
      label: AppColors.textSecondary,
    ),
  },
  MainButtonStyle.secondary: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: AppColors.bgSurface,
      border: AppColors.borderDefault,
      label: AppColors.textSecondary,
    ),
    MainButtonTone.inverse: (
      fill: null,
      border: AppColors.borderDefault,
      label: AppColors.textDisabled,
    ),
    MainButtonTone.danger: (
      fill: AppColors.bgSurface,
      border: AppColors.borderDefault,
      label: AppColors.textSecondary,
    ),
  },
  MainButtonStyle.ghost: <MainButtonTone, _Look>{
    MainButtonTone.normal: (
      fill: null,
      border: null,
      label: AppColors.textSecondary,
    ),
    MainButtonTone.inverse: (
      fill: null,
      border: null,
      label: AppColors.textDisabled,
    ),
    MainButtonTone.danger: (
      fill: null,
      border: null,
      label: AppColors.textSecondary,
    ),
  },
};

/// The box the button paints its state into.
Finder _box() => find.descendant(
      of: find.byType(MainButton),
      matching: find.byType(AnimatedContainer),
    );

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_box()).decoration! as BoxDecoration;

/// What the button currently looks like.
_Look _lookOf(WidgetTester tester) {
  final BoxDecoration decoration = _decoration(tester);
  final Border? border = decoration.border as Border?;
  return (
    fill: decoration.color,
    border: border?.top.color,
    label: tester.widget<Text>(find.text(_label)).style!.color!,
  );
}

/// Pumps one button and hands back how many times it was activated.
Future<List<int>> _pump(
  WidgetTester tester, {
  MainButtonStyle style = MainButtonStyle.primary,
  MainButtonTone tone = MainButtonTone.normal,
  bool enabled = true,
  bool canBeTapped = true,
  bool isLoading = false,
  bool flushStart = false,
  AppIcons? icon,
  Locale locale = englishLocale,
}) async {
  final List<int> presses = <int>[];
  await pumpAppWidget(
    tester,
    Center(
      child: MainButton(
        label: _label,
        onPressed: enabled ? () => presses.add(1) : null,
        style: style,
        tone: tone,
        canBeTapped: canBeTapped,
        isLoading: isLoading,
        flushStart: flushStart,
        icon: icon,
      ),
    ),
    locale: locale,
  );
  return presses;
}

void main() {
  group('MainButton colours', () {
    for (final MainButtonStyle style in MainButtonStyle.values) {
      for (final MainButtonTone tone in MainButtonTone.values) {
        final String variant = '${style.name}/${tone.name}';

        testWidgets('$variant at rest', (WidgetTester tester) async {
          await _pump(tester, style: style, tone: tone);

          expect(_lookOf(tester), _resting[style]![tone]);
        });

        testWidgets('$variant under a finger, and back after',
            (WidgetTester tester) async {
          final List<int> presses =
              await _pump(tester, style: style, tone: tone);

          final TestGesture finger =
              await tester.startGesture(tester.getCenter(find.byType(MainButton)));
          await tester.pump(kPressTimeout);

          expect(_decoration(tester).color, _pressed[style]![tone]);
          // The label keeps its colour; only the fill says "pressed".
          expect(_lookOf(tester).label, _resting[style]![tone]!.label);

          await finger.up();
          await tester.pump();

          expect(_lookOf(tester), _resting[style]![tone]);
          expect(presses, hasLength(1));
        });

        testWidgets('$variant disabled', (WidgetTester tester) async {
          await _pump(tester, style: style, tone: tone, canBeTapped: false);

          expect(_lookOf(tester), _disabled[style]![tone]);
        });
      }
    }

    testWidgets('does not show a press while disabled',
        (WidgetTester tester) async {
      await _pump(tester, enabled: false);

      final TestGesture finger =
          await tester.startGesture(tester.getCenter(find.byType(MainButton)));
      await tester.pump(kPressTimeout);

      expect(_decoration(tester).color, AppColors.bgDisabled);
      await finger.up();
    });

    testWidgets('lets go of the press when the finger slides away',
        (WidgetTester tester) async {
      final List<int> presses = await _pump(tester);

      final TestGesture finger =
          await tester.startGesture(tester.getCenter(find.byType(MainButton)));
      await tester.pump(kPressTimeout);
      await finger.moveBy(const Offset(0, 100));
      await tester.pump();
      await finger.up();
      await tester.pump();

      expect(_decoration(tester).color, AppColors.bgBrand);
      expect(presses, isEmpty);
    });
  });

  group('MainButton taps', () {
    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      final List<int> presses = await _pump(tester);

      await tester.tap(find.byType(MainButton));

      expect(presses, hasLength(1));
    });

    testWidgets('does nothing while canBeTapped is false',
        (WidgetTester tester) async {
      final List<int> presses = await _pump(tester, canBeTapped: false);

      await tester.tap(find.byType(MainButton));

      expect(presses, isEmpty);
    });

    testWidgets('does nothing without an onPressed',
        (WidgetTester tester) async {
      await _pump(tester, enabled: false);

      // Must not throw: a null onPressed simply ignores the tap.
      await tester.tap(find.byType(MainButton));
    });
  });

  group('MainButton loading', () {
    testWidgets('shows a spinner beside the label, not instead of it',
        (WidgetTester tester) async {
      await _pump(tester, isLoading: true);

      expect(find.byType(AppSpinner), findsOneWidget);
      expect(find.text(_label), findsOneWidget);
      // Spinner first, then the label, in reading order.
      expect(
        tester.getCenter(find.byType(AppSpinner)).dx,
        lessThan(tester.getCenter(find.text(_label)).dx),
      );
    });

    testWidgets('puts the spinner on the reading side in Arabic',
        (WidgetTester tester) async {
      await _pump(tester, isLoading: true, locale: arabicLocale);

      expect(
        tester.getCenter(find.byType(AppSpinner)).dx,
        greaterThan(tester.getCenter(find.text(_label)).dx),
      );
    });

    testWidgets('keeps the enabled colours', (WidgetTester tester) async {
      // A greyed-out spinner reads as broken rather than busy.
      await _pump(tester, isLoading: true);

      expect(_lookOf(tester), _resting[MainButtonStyle.primary]![
          MainButtonTone.normal]);
      expect(
        tester.widget<AppSpinner>(find.byType(AppSpinner)).color,
        AppColors.textOnBrand,
      );
    });

    testWidgets('cannot be started twice', (WidgetTester tester) async {
      final List<int> presses = await _pump(tester, isLoading: true);

      await tester.tap(find.byType(MainButton));
      await tester.pump();

      expect(presses, isEmpty);
    });

    testWidgets('replaces the icon with the spinner',
        (WidgetTester tester) async {
      await _pump(tester, isLoading: true, icon: AppIcons.plus);

      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is AppIcon && widget.icon == AppIcons.plus,
        ),
        findsNothing,
      );
    });

    testWidgets('reports itself as not enabled', (WidgetTester tester) async {
      await _pump(tester, isLoading: true);

      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(isButton: true, isEnabled: false),
      );
    });
  });

  group('MainButton focus', () {
    testWidgets('draws the focus ring while it holds keyboard focus',
        (WidgetTester tester) async {
      await _pump(tester);
      expect(_decoration(tester).boxShadow, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_decoration(tester).boxShadow, AppElevation.focusRing);
    });

    testWidgets('activates from the keyboard', (WidgetTester tester) async {
      final List<int> presses = await _pump(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(presses, hasLength(1));
    });

    testWidgets('cannot be focused while disabled',
        (WidgetTester tester) async {
      await _pump(tester, canBeTapped: false);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_decoration(tester).boxShadow, isNull);
    });
  });

  group('MainButton anatomy', () {
    testWidgets('leads with the icon it is given', (WidgetTester tester) async {
      await _pump(tester, icon: AppIcons.plus);
      final Finder icon = find.byWidgetPredicate(
        (Widget widget) => widget is AppIcon && widget.icon == AppIcons.plus,
      );

      expect(icon, findsOneWidget);
      expect(tester.widget<AppIcon>(icon).color, AppColors.textOnBrand);
      expect(
        tester.getCenter(icon).dx,
        lessThan(tester.getCenter(find.text(_label)).dx),
      );
    });

    testWidgets('drops only the leading padding when flush',
        (WidgetTester tester) async {
      await _pump(tester, style: MainButtonStyle.ghost, flushStart: true);
      final EdgeInsetsDirectional padding = tester
          .widget<AnimatedContainer>(_box())
          .padding! as EdgeInsetsDirectional;

      expect(padding.start, 0);
      expect(padding.end, AppSpacing.xl.dw);
    });

    testWidgets('lines the flush label up with the start edge in Arabic',
        (WidgetTester tester) async {
      await _pump(
        tester,
        style: MainButtonStyle.ghost,
        flushStart: true,
        locale: arabicLocale,
      );

      // Start is the right in Arabic: the label touches the box's right edge.
      expect(
        tester.getTopRight(find.text(_label)).dx,
        moreOrLessEquals(tester.getTopRight(_box()).dx),
      );
    });

    testWidgets('is at least the design control height',
        (WidgetTester tester) async {
      await _pump(tester);

      expect(
        tester.getSize(find.byType(MainButton)).height,
        greaterThanOrEqualTo(AppSizes.controlMd.dh),
      );
    });

    testWidgets('exposes itself as a button to accessibility tools',
        (WidgetTester tester) async {
      await _pump(tester);

      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(label: _label, isButton: true, isEnabled: true),
      );
    });

    testWidgets('reports itself disabled when canBeTapped is false',
        (WidgetTester tester) async {
      await _pump(tester, canBeTapped: false);

      expect(
        tester.getSemantics(find.byType(MainButton)),
        isSemantics(label: _label, isButton: true, isEnabled: false),
      );
    });
  });
}
