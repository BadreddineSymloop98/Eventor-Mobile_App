import 'package:eventor/app/eventor_app.dart';
import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/localization/app_localizations_x.dart';
import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/core/theme/app_theme.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The locales the suite exercises.
const Locale englishLocale = Locale('en');
const Locale arabicLocale = Locale('ar');

/// Builds [EventorApp] on an in-memory preference store.
///
/// Pass `hasSeenOnboarding: true` to simulate a launch after the first one,
/// and [locale] to start the app in a particular language.
Future<EventorApp> buildTestApp({
  bool hasSeenOnboarding = false,
  Locale? locale,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'has_seen_onboarding': hasSeenOnboarding,
    if (locale != null) 'locale': locale.languageCode,
  });

  return EventorApp(preferences: await PreferencesService.load());
}

/// Pumps a single [widget] inside enough of the app to make it work: the
/// theme, the localisation delegates and a [Scaffold].
///
/// Use this instead of a bare [MaterialApp] so that anything reading
/// `context.l10n` — which is now most of the widget layer — has something to
/// read from, and so that a test can be re-run in Arabic by passing [locale].
Future<void> pumpAppWidget(
  WidgetTester tester,
  Widget widget, {
  Locale locale = englishLocale,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(locale),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: widget),
      builder: (BuildContext context, Widget? child) {
        // Mirrors what EventorApp does, so `.h` and `.w` resolve against the
        // test surface rather than against the design fallback.
        ScreenMetrics.update(MediaQuery.sizeOf(context));
        return child ?? const SizedBox.shrink();
      },
    ),
  );
}

/// Advances past the splash, which holds the brand briefly before handing over
/// to onboarding or login.
///
/// The hand-over is a timer rather than an animation, so `pumpAndSettle` alone
/// will not reach it — the clock has to be moved on explicitly, and the timer
/// has to be allowed to fire or the test fails on a pending timer at teardown.
Future<void> passSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

/// The strings currently in effect, read from the screen on show.
///
/// Lets a test assert against localised copy without hard-coding it, so the
/// same test passes in either language. Resolved from a [Scaffold] because the
/// context of the [MaterialApp] itself sits above the localisations it
/// installs.
AppLocalizations l10n(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).l10n;
