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
}
