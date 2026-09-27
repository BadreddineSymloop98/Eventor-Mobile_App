import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  // ScreenMetrics is global by design — that is what lets `.h` and `.w` work
  // without a BuildContext — so each test starts from a known state.
  setUp(ScreenMetrics.reset);
  tearDown(ScreenMetrics.reset);

  group('ScreenMetrics', () {
    test('falls back to the design frame until a real size arrives', () {
      expect(ScreenMetrics.isInitialized, isFalse);
      expect(ScreenMetrics.width, ScreenMetrics.designSize.width);
      expect(ScreenMetrics.height, ScreenMetrics.designSize.height);
    });

    test('takes the size it is given', () {
      ScreenMetrics.update(const Size(400, 800));

      expect(ScreenMetrics.isInitialized, isTrue);
      expect(ScreenMetrics.width, 400);
      expect(ScreenMetrics.height, 800);
    });

    testWidgets('is kept in step with the window by the app root',
        (WidgetTester tester) async {
      await pumpAppWidget(tester, const SizedBox.shrink());

      final Size surface = tester.view.physicalSize / tester.view.devicePixelRatio;

      expect(ScreenMetrics.isInitialized, isTrue);
      expect(ScreenMetrics.width, surface.width);
      expect(ScreenMetrics.height, surface.height);
    });
  });

  group('ResponsiveNum', () {
    setUp(() => ScreenMetrics.update(const Size(400, 800)));

    test('reads as a percentage of the window', () {
      expect(50.w, 200);
      expect(25.h, 200);
      expect(100.w, 400);
      expect(100.h, 800);
    });

    test('works on fractional percentages too', () {
      expect(12.5.w, 50);
      expect(0.h, 0);
    });

    test('follows a change of size', () {
      expect(50.w, 200);

      ScreenMetrics.update(const Size(800, 800));

      expect(50.w, 400);
    });
  });

  group('the fixed tokens', () {
    test('do not scale with the window', () {
      ScreenMetrics.update(const Size(400, 800));
      const double gapOnAPhone = AppSpacing.md;

      ScreenMetrics.update(const Size(1200, 1600));

      // The point of keeping spacing in logical pixels: a tablet gets the same
      // gap as a phone, rather than one inflated by the extra screen.
      expect(AppSpacing.md, gapOnAPhone);
    });

    test('keep the tap target at the accessible minimum', () {
      expect(AppSizes.touchTarget, greaterThanOrEqualTo(48));
    });
  });

  group('AppColors', () {
    /// Whether [color] is a true grey — no channel pulling towards a hue by
    /// more than the few steps Figma's neutral ramp allows.
    bool isNeutral(Color color) {
      final List<double> channels = <double>[color.r, color.g, color.b];
      final double spread = channels.reduce((double a, double b) => a > b ? a : b) -
          channels.reduce((double a, double b) => a < b ? a : b);
      // 0x6B6B75 is the widest of the ramp: 10 steps out of 255.
      return spread <= 12 / 255;
    }

    test('keep the brand purple exact', () {
      expect(AppColors.brand, const Color(0xFF2B075D));
      expect(AppColors.bgBrand, AppColors.brand);
      expect(AppColors.textBrand, AppColors.brand);
    });

    test('draw text, borders and canvas from the grey neutrals', () {
      // The ramp moved from purple-tinted to Figma's true greys; a purple
      // cast creeping back into the chrome is what this guards against.
      final List<Color> neutrals = <Color>[
        AppColors.bgCanvas,
        AppColors.bgSurface,
        AppColors.bgSurfacePressed,
        AppColors.bgDisabled,
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.borderDefault,
        AppColors.iconDefault,
        AppColors.bgScrim,
      ];

      for (final Color color in neutrals) {
        expect(isNeutral(color), isTrue, reason: '$color is not a grey');
      }
    });

    test('give every pressable fill its own pressed colour', () {
      expect(AppColors.bgBrandPressed, isNot(AppColors.bgBrand));
      expect(AppColors.bgDangerPressed, isNot(AppColors.bgDanger));
      expect(AppColors.bgSurfacePressed, isNot(AppColors.bgSurface));
    });

    test('use one red for every danger role', () {
      // A destructive action reads as one colour whether it is a fill, a
      // label, an outline or a glyph.
      expect(AppColors.textDanger, AppColors.bgDanger);
      expect(AppColors.borderDanger, AppColors.bgDanger);
      expect(AppColors.iconDanger, AppColors.bgDanger);
      expect(AppColors.bgDangerSubtle, isNot(AppColors.bgDanger));
    });

    test('paint the scrim neutral and at half strength', () {
      expect(AppColors.scrimOpacity, 0.5);
      expect(isNeutral(AppColors.bgScrim), isTrue);
    });
  });

  group('AppElevation', () {
    test('builds each level from two neutral layers', () {
      for (final List<BoxShadow> level in <List<BoxShadow>>[
        AppElevation.sm,
        AppElevation.md,
        AppElevation.lg,
      ]) {
        expect(level, hasLength(2));
        for (final BoxShadow shadow in level) {
          // #101014 at a few percent — never brand-tinted.
          expect(shadow.color.withAlpha(0xFF), const Color(0xFF101014));
          expect(shadow.color.a, lessThan(0.1));
        }
      }
    });

    test('grows with the level', () {
      expect(AppElevation.md.last.blurRadius,
          greaterThan(AppElevation.sm.last.blurRadius));
      expect(AppElevation.lg.last.blurRadius,
          greaterThan(AppElevation.md.last.blurRadius));
    });

    test('draws the focus ring as an outline, not a shadow', () {
      final BoxShadow ring = AppElevation.focusRing.single;

      expect(ring.blurRadius, 0);
      expect(ring.offset, Offset.zero);
      expect(ring.spreadRadius, greaterThan(0));
    });
  });
}
