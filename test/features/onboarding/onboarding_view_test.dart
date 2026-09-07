import 'package:eventor/core/widgets/language_switch.dart';
import 'package:eventor/core/widgets/photo_backdrop.dart';
import 'package:eventor/features/onboarding/view/onboarding_view.dart';
import 'package:eventor/features/onboarding/view_model/onboarding_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  Future<void> pumpOnboarding(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(await buildTestApp(locale: locale));
    await passSplash(tester);
    expect(find.byType(OnboardingView), findsOneWidget);
  }

  /// Swipes one section forward, in whichever direction the language runs.
  Future<void> swipeForward(WidgetTester tester) async {
    final bool isRtl =
        Directionality.of(tester.element(find.byType(PageView))) ==
            TextDirection.rtl;

    await tester.drag(find.byType(PageView), Offset(isRtl ? 500 : -500, 0));
    await tester.pumpAndSettle();
  }

  group('OnboardingView', () {
    testWidgets('shows one section at a time, over its photograph',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.onboardingServicesTitle), findsOneWidget);
      expect(find.text(strings.onboardingCompareTitle), findsNothing);

      // The photograph is the only thing that lives in the pager, so exactly
      // one is built for the visible page.
      expect(find.byType(PhotoBackdrop), findsOneWidget);
    });

    testWidgets('swiping moves to the next section',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      await swipeForward(tester);

      expect(find.text(strings.onboardingCompareTitle), findsOneWidget);
      expect(find.text(strings.onboardingServicesTitle), findsNothing);
    });

    testWidgets('each section shows its own photograph',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);

      String currentPhoto() =>
          tester.widget<PhotoBackdrop>(find.byType(PhotoBackdrop)).asset;

      final String first = currentPhoto();
      await swipeForward(tester);

      expect(currentPhoto(), isNot(first));
    });

    testWidgets('the button becomes Get Started on the last section',
        (WidgetTester tester) async {
      // The last step reads as an ending rather than as one more page.
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      for (int i = 0; i < OnboardingViewModel.sections.length - 1; i++) {
        expect(find.text(strings.next), findsOneWidget);
        expect(find.text(strings.getStarted), findsNothing);
        await swipeForward(tester);
      }

      expect(find.text(strings.next), findsNothing);
      expect(find.text(strings.getStarted), findsOneWidget);
    });

    testWidgets('the button advances the sections too',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      await tester.tap(find.text(strings.next));
      await tester.pumpAndSettle();

      expect(find.text(strings.onboardingCompareTitle), findsOneWidget);
    });

    testWidgets('announces the position to accessibility tools',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpOnboarding(tester);
      final AppLocalizations strings = l10n(tester);

      expect(
        find.bySemanticsLabel(strings.sectionProgress(1, 3)),
        findsOneWidget,
      );

      await swipeForward(tester);

      expect(
        find.bySemanticsLabel(strings.sectionProgress(2, 3)),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('OnboardingView language switch', () {
    testWidgets('is offered on the screen', (WidgetTester tester) async {
      await pumpOnboarding(tester);

      expect(find.byType(LanguageSwitch), findsOneWidget);
      // Each half labels itself in its own script, whatever the app is set to.
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('عربي'), findsOneWidget);
    });

    testWidgets('swaps sides with the language, like the rest of the screen',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);

      double skipX() => tester.getCenter(find.text(l10n(tester).skip)).dx;
      double switchX() => tester.getCenter(find.byType(LanguageSwitch)).dx;

      // Reading left to right, Skip is the near edge and the switch the far.
      expect(skipX(), lessThan(switchX()));

      await tester.tap(find.text('عربي'));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.rtl,
      );
      // Reading right to left, they trade places.
      expect(skipX(), greaterThan(switchX()));
    });

    testWidgets('switches the whole app to Arabic and back',
        (WidgetTester tester) async {
      await pumpOnboarding(tester);
      expect(
        find.text(l10n(tester).onboardingServicesTitle),
        findsOneWidget,
      );

      await tester.tap(find.text('عربي'));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.rtl,
      );
      // The copy is now the Arabic copy, resolved live rather than hardcoded.
      expect(
        find.text(l10n(tester).onboardingServicesTitle),
        findsOneWidget,
      );
      expect(find.text('Every service your event needs'), findsNothing);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(OnboardingView))),
        TextDirection.ltr,
      );
      expect(find.text('Every service your event needs'), findsOneWidget);
    });
  });

  group('OnboardingView in Arabic', () {
    testWidgets('runs right to left and still advances',
        (WidgetTester tester) async {
      await pumpOnboarding(tester, locale: arabicLocale);
      final AppLocalizations strings = l10n(tester);

      expect(
        Directionality.of(tester.element(find.byType(PageView))),
        TextDirection.rtl,
      );
      expect(find.text(strings.onboardingServicesTitle), findsOneWidget);

      await swipeForward(tester);

      expect(find.text(strings.onboardingCompareTitle), findsOneWidget);
    });
  });
}
