import 'package:eventor/core/widgets/atoms/page_dots.dart';
import 'package:eventor/core/widgets/molecules/language_switch.dart';
import 'package:eventor/features/onboarding/view/onboarding_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  Future<TestApp> pumpOnboarding(WidgetTester tester, {Locale? locale}) async {
    final TestApp app = await buildTestApp(locale: locale);
    await startApp(tester, app);
    expect(find.byType(OnboardingView), findsOneWidget);
    return app;
  }

  PageDots dots(WidgetTester tester) =>
      tester.widget<PageDots>(find.byType(PageDots));

  group('OnboardingView', () {
    testWidgets('opens on the first section with inverse dots', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.onboardingServicesTitle), findsOneWidget);
      expect(find.text(strings.onboardingServicesDescription), findsOneWidget);
      expect(dots(tester).count, 3);
      expect(dots(tester).currentIndex, 0);
      // On a photograph, so the light variant.
      expect(dots(tester).tone, PageDotsTone.inverse);
      expect(button(strings.next), findsOneWidget);
      expect(button(strings.skip), findsOneWidget);
      expect(find.byType(LanguageSwitch), findsOneWidget);
    });

    testWidgets('Next walks the sections and the last one says Get started', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.next));
      expect(dots(tester).currentIndex, 1);
      expect(find.text(strings.onboardingCompareTitle), findsOneWidget);

      await tapAndSettle(tester, button(strings.next));
      expect(dots(tester).currentIndex, 2);
      expect(find.text(strings.onboardingTrackTitle), findsOneWidget);
      expect(button(strings.getStarted), findsOneWidget);
      expect(button(strings.next), findsNothing);
    });

    testWidgets('Get started leaves for welcome and remembers it', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, button(strings.next));
      await tapAndSettle(tester, button(strings.next));
      await tapAndSettle(tester, button(strings.getStarted));

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(app.services.preferences.hasSeenOnboarding, isTrue);
      // Gone to, not pushed: there is no walking back into onboarding.
      expect(app.services.router.canPop(), isFalse);
    });

    testWidgets('Skip leaves from any section and remembers it', (
      WidgetTester tester,
    ) async {
      final TestApp app = await pumpOnboarding(tester);

      await tapAndSettle(tester, button(l10n(tester).skip));

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(app.services.preferences.hasSeenOnboarding, isTrue);
    });

    testWidgets('a swipe moves the dots too', (WidgetTester tester) async {
      await pumpOnboarding(tester);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(dots(tester).currentIndex, 1);
    });
  });

  group('OnboardingView in Arabic', () {
    testWidgets('reads right to left and swipes the other way', (
      WidgetTester tester,
    ) async {
      await pumpOnboarding(tester, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.rtl,
      );
      expect(find.text(l10n(tester).onboardingServicesTitle), findsOneWidget);

      // In a right-to-left pager the next section lies to the left, so it
      // is reached by dragging right.
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(dots(tester).currentIndex, 1);
    });
  });
}
