import 'package:eventor/core/widgets/layout/photo_backdrop.dart';
import 'package:eventor/features/onboarding/view/onboarding_view.dart';
import 'package:eventor/features/splash/view/splash_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  group('SplashView', () {
    testWidgets('shows the logo, tagline and byline over a photograph', (
      WidgetTester tester,
    ) async {
      usePhoneSurface(tester);
      await pumpAppWidget(tester, const SplashView());
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PhotoBackdrop), findsOneWidget);
      // The logo is the brand's name to a screen reader.
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Image && widget.semanticLabel == strings.appName,
        ),
        findsOneWidget,
      );
      expect(find.text(strings.splashTagline), findsOneWidget);
      expect(find.text(strings.splashByline), findsOneWidget);
    });

    testWidgets('reads in Arabic, right to left', (WidgetTester tester) async {
      usePhoneSurface(tester);
      await pumpAppWidget(tester, const SplashView(), locale: arabicLocale);

      expect(find.text(l10n(tester).splashTagline), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(SplashView))),
        TextDirection.rtl,
      );
    });

    testWidgets('holds the app until startup is ready, then hands over', (
      WidgetTester tester,
    ) async {
      usePhoneSurface(tester);
      final TestApp app = await buildTestApp();
      await tester.pumpWidget(app.widget);
      await tester.pump();

      // Startup has not run: every route waits here.
      expect(find.byType(SplashView), findsOneWidget);
      app.services.router.go('/welcome');
      await tester.pump();
      expect(find.byType(SplashView), findsOneWidget);

      final Future<void> started = app.services.startup.run(
        floor: Duration.zero,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await started;
      await tester.pumpAndSettle();

      // The splash navigates nowhere itself; the router takes a first launch
      // to onboarding. The link opened meanwhile is not honoured — only an
      // invite link is (see app_flow_test).
      expect(find.byType(SplashView), findsNothing);
      expect(find.byType(OnboardingView), findsOneWidget);
    });
  });
}
