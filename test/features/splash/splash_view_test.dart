import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/features/login/view/login_view.dart';
import 'package:eventor/features/splash/view/splash_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  /// Pumps the real app onto a window of [size] and stops on the splash.
  ///
  /// The splash is pumped through the app rather than on its own because it
  /// now owns a hand-over: it needs its view model, and it needs a navigator
  /// to hand over *to*.
  ///
  /// Every test that calls this must finish with [passSplash], or the
  /// still-pending hand-over timer fails the test at teardown.
  Future<void> pumpSplashAt(
    WidgetTester tester,
    Size size, {
    Locale? locale,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    // Unmount whatever was pumped before. `const SplashView()` is
    // canonicalised, so pumping it again over an existing tree reuses the
    // element and skips the rebuild — and the proportional sizes below, which
    // read a static cache rather than an inherited widget, would still be the
    // previous window's. See the note on ScreenMetrics in ui_helpers.dart.
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      await buildTestApp(hasSeenOnboarding: true, locale: locale),
    );
    await tester.pump();
  }

  /// The rendered width of the logo. The photograph is the other [Image].
  double logoWidth(WidgetTester tester) =>
      tester.getSize(find.byType(Image).last).width;

  group('SplashView', () {
    testWidgets('shows the logo, the tagline and the byline',
        (WidgetTester tester) async {
      await pumpSplashAt(tester, const Size(375, 812));
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.splashTagline), findsOneWidget);
      expect(find.text(strings.splashByline), findsOneWidget);
      // The photograph and the logo.
      expect(find.byType(Image), findsNWidgets(2));

      await passSplash(tester);
    });

    testWidgets('labels the logo for screen readers but not the photograph',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpSplashAt(tester, const Size(375, 812));

      // The logo carries the app's name; the background is decorative and
      // must not be announced.
      expect(find.bySemanticsLabel(l10n(tester).appName), findsOneWidget);

      await passSplash(tester);
      handle.dispose();
    });

    testWidgets('sizes the logo as a share of the window',
        (WidgetTester tester) async {
      // The whole point of `.w`: the same layout on a wider phone gives a
      // proportionally wider logo, rather than the design's 200px marooned in
      // the middle of a bigger screen.
      await pumpSplashAt(tester, const Size(375, 812));
      final double onDesignFrame = logoWidth(tester);

      // 200 of 375.
      expect(onDesignFrame, closeTo(200, 0.5));

      await pumpSplashAt(tester, const Size(430, 932));

      expect(logoWidth(tester), greaterThan(onDesignFrame));
      expect(logoWidth(tester), closeTo(430 * 200 / 375, 0.5));

      await passSplash(tester);
    });

    testWidgets('lays out without overflowing on a short screen',
        (WidgetTester tester) async {
      // The three blocks are spaced apart rather than scrolled, so a small
      // window is where this would break first.
      await pumpSplashAt(tester, const Size(320, 568));

      expect(tester.takeException(), isNull);

      await passSplash(tester);
    });

    testWidgets('draws the brand colour behind the photograph',
        (WidgetTester tester) async {
      await pumpSplashAt(tester, const Size(375, 812));

      final Scaffold scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashView),
          matching: find.byType(Scaffold),
        ),
      );

      expect(scaffold.backgroundColor, AppColors.bgBrand);

      await passSplash(tester);
    });

    testWidgets('replaces itself once it has decided where to go',
        (WidgetTester tester) async {
      await pumpSplashAt(tester, const Size(375, 812));
      expect(find.byType(SplashView), findsOneWidget);

      await passSplash(tester);

      expect(find.byType(SplashView), findsNothing);
      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('SplashView in Arabic', () {
    testWidgets('shows the Arabic copy and mirrors the layout',
        (WidgetTester tester) async {
      await pumpSplashAt(tester, const Size(375, 812), locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.splashTagline), findsOneWidget);
      expect(find.text(strings.splashByline), findsOneWidget);
      // Genuinely translated, not the English copy showing through.
      expect(
        find.text('Everything your event needs, in one place'),
        findsNothing,
      );
      expect(
        Directionality.of(tester.element(find.byType(SplashView))),
        TextDirection.rtl,
      );

      await passSplash(tester);
    });

    testWidgets('sets the Arabic copy in Cairo at the Arabic size',
        (WidgetTester tester) async {
      await pumpSplashAt(tester, const Size(375, 812), locale: arabicLocale);

      final Text tagline =
          tester.widget<Text>(find.text(l10n(tester).splashTagline));

      // AR/Body/L is 17pt in Cairo, where EN/Body/L is 16pt in Inter — the
      // two ramps are separate values, not one ramp in two fonts.
      expect(tagline.style?.fontSize, 17);
      expect(tagline.style?.fontFamily, AppFontFamilies.arabic);

      await passSplash(tester);
    });
  });
}
