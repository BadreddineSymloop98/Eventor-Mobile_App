import 'package:eventor/core/widgets/molecules/main_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Helpers shared by the feature and app-flow widget tests.
///
/// Kept beside the tests rather than in `test/support` because they are about
/// driving screens, not about building the app on fakes.

/// Gives the test a phone-shaped window — 390×844, the size the design is
/// drawn for give or take — instead of the default 800×600 landscape one,
/// which squeezes the photo-sheet screens until their sheet has to scroll.
void usePhoneSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  addTearDown(tester.view.reset);
}

/// Pumps [app] and lets the splash hand over, like `launch` in
/// `test/support/test_app.dart`.
///
/// Startup is started *without* awaiting it and then pumped. `launch` awaits
/// `startup.run(floor: Duration.zero)` directly, but the floor is a
/// `Future.delayed`, i.e. a timer — and inside `testWidgets` timers only fire
/// when the fake clock is pumped, so awaiting it before any pump never
/// returns. Pumping first lets the zero-length floor elapse.
///
/// [deepLink], when given, is opened while the splash is still up — the way
/// an invite link arrives on a cold start.
Future<void> startApp(
  WidgetTester tester,
  TestApp app, {
  String? deepLink,
}) async {
  usePhoneSurface(tester);
  await tester.pumpWidget(app.widget);
  await tester.pump();
  if (deepLink != null) {
    app.services.router.go(deepLink);
    await tester.pump();
  }
  final Future<void> started = app.services.startup.run(floor: Duration.zero);
  await tester.pump(const Duration(milliseconds: 1));
  await started;
  await tester.pumpAndSettle();
}

/// Starts [app] and goes straight to [location], skipping the screens in
/// between — for testing one screen in the real router.
Future<void> startAt(
  WidgetTester tester,
  TestApp app,
  String location, {
  Object? extra,
}) async {
  await startApp(tester, app);
  app.services.router.go(location, extra: extra);
  await tester.pumpAndSettle();
}

/// The [MainButton] labelled [label].
Finder button(String label) => find.widgetWithText(MainButton, label);

/// Whether the [MainButton] labelled [label] would respond to a tap.
bool isTappable(WidgetTester tester, String label) {
  final MainButton widget = tester.widget<MainButton>(button(label));
  return widget.canBeTapped && widget.onPressed != null;
}

/// Scrolls [finder] into view, then taps it. Leaves pumping to the caller, so
/// a test can look at the busy state before it settles.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// [tapVisible], then lets everything settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tapVisible(tester, finder);
  await tester.pumpAndSettle();
}

/// Types [text] into [finder] after scrolling it into view.
Future<void> typeInto(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

/// Lets pending microtasks run, for view-model tests outside `testWidgets`
/// whose fakes answer asynchronously.
Future<void> flushAsync() => Future<void>.delayed(Duration.zero);
