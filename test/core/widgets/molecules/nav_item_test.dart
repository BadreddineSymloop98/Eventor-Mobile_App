import 'package:eventor/core/constants/ui_helpers.dart';
import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/nav_ambient.dart';
import 'package:eventor/core/widgets/molecules/nav_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

const String _label = 'Bookings';

void main() {
  Future<List<int>> pumpItem(
    WidgetTester tester, {
    bool isActive = false,
    int badgeCount = 0,
    Locale locale = englishLocale,
    String label = _label,
  }) async {
    final List<int> taps = <int>[];
    await pumpAppWidget(
      tester,
      Center(
        child: NavItem(
          icon: AppIcons.calendar,
          label: label,
          isActive: isActive,
          badgeCount: badgeCount,
          onTap: () => taps.add(1),
        ),
      ),
      locale: locale,
    );
    return taps;
  }

  group('NavItem badge', () {
    testWidgets('is hidden at zero', (WidgetTester tester) async {
      await pumpItem(tester);

      expect(find.text('0'), findsNothing);
      expect(find.byType(Text), findsOneWidget); // The label only.
    });

    testWidgets('shows a small count as it is', (WidgetTester tester) async {
      await pumpItem(tester, badgeCount: 3);

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows nine as nine', (WidgetTester tester) async {
      await pumpItem(tester, badgeCount: 9);

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('caps anything above nine at 9+', (WidgetTester tester) async {
      // So the badge stays a circle rather than growing into a pill.
      await pumpItem(tester, badgeCount: 12);

      expect(find.text('9+'), findsOneWidget);
      expect(find.text('12'), findsNothing);
    });

    testWidgets('keeps 9+ reading left to right in Arabic',
        (WidgetTester tester) async {
      await pumpItem(tester, badgeCount: 40, locale: arabicLocale);

      expect(
        tester.widget<Text>(find.text('9+')).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('sits on the icon’s top-end corner, mirrored in Arabic',
        (WidgetTester tester) async {
      await pumpItem(tester, badgeCount: 2);
      final double englishOffset = tester.getCenter(find.text('2')).dx -
          tester.getCenter(find.byType(AppIcon)).dx;

      await pumpItem(tester, badgeCount: 2, locale: arabicLocale);
      final double arabicOffset = tester.getCenter(find.text('2')).dx -
          tester.getCenter(find.byType(AppIcon)).dx;

      expect(englishOffset, greaterThan(0));
      expect(arabicOffset, lessThan(0));
    });

    testWidgets('is read out with the label, as the real count',
        (WidgetTester tester) async {
      await pumpItem(tester, badgeCount: 12, isActive: true);

      expect(
        tester.getSemantics(find.byType(NavItem)),
        isSemantics(label: '$_label, 12', isButton: true, isSelected: true),
      );
    });
  });

  group('NavItem', () {
    testWidgets('is brand while active', (WidgetTester tester) async {
      await pumpItem(tester, isActive: true);

      expect(
        tester.widget<Text>(find.text(_label)).style?.color,
        AppColors.textBrand,
      );
      expect(
        tester.widget<AppIcon>(find.byType(AppIcon)).color,
        AppColors.iconBrand,
      );
    });

    testWidgets('is grey while not', (WidgetTester tester) async {
      await pumpItem(tester);

      expect(
        tester.widget<Text>(find.text(_label)).style?.color,
        AppColors.textSecondary,
      );
      expect(
        tester.widget<AppIcon>(find.byType(AppIcon)).color,
        AppColors.iconDefault,
      );
    });

    testWidgets('reports the tap', (WidgetTester tester) async {
      final List<int> taps = await pumpItem(tester);

      await tester.tap(find.byType(NavItem));

      expect(taps, hasLength(1));
    });

    testWidgets('announces just its label without a badge',
        (WidgetTester tester) async {
      await pumpItem(tester, label: 'الحجوزات', locale: arabicLocale);

      expect(
        tester.getSemantics(find.byType(NavItem)),
        isSemantics(label: 'الحجوزات', isButton: true, isSelected: false),
      );
    });
  });

  group('NavItem with a filled glyph', () {
    /// A [NavItem] whose `isActive` the test flips through [active], the way
    /// a bottom nav rebuilds it when the tab changes.
    Future<List<int>> pumpFlippable(
      WidgetTester tester,
      ValueNotifier<bool> active, {
      bool reduceMotion = false,
    }) async {
      final List<int> taps = <int>[];
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: active,
                builder: (_, bool isActive, _) => NavItem(
                  icon: AppIcons.calendar,
                  activeIcon: AppIcons.calendarFilled,
                  label: _label,
                  isActive: isActive,
                  onTap: () => taps.add(1),
                ),
              ),
            ),
          ),
        ),
      );
      return taps;
    }

    Finder glyph(AppIcons icon) => find.byWidgetPredicate(
          (Widget widget) => widget is AppIcon && widget.icon == icon,
        );

    double opacityOf(WidgetTester tester, AppIcons icon) => tester
        .widget<Opacity>(
          find.ancestor(of: glyph(icon), matching: find.byType(Opacity)).first,
        )
        .opacity;

    double scaleOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .ancestor(
                of: glyph(AppIcons.calendar),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();

    testWidgets('shows the outline while idle', (WidgetTester tester) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(false);
      addTearDown(active.dispose);
      await pumpFlippable(tester, active);

      expect(opacityOf(tester, AppIcons.calendar), 1);
      expect(opacityOf(tester, AppIcons.calendarFilled), 0);
    });

    testWidgets('fills in and pops when it becomes active', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(false);
      addTearDown(active.dispose);
      await pumpFlippable(tester, active);

      active.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mid-flight: both glyphs partly drawn, the icon past full size.
      expect(opacityOf(tester, AppIcons.calendarFilled), inExclusiveRange(0, 1));
      expect(scaleOf(tester), greaterThan(1));

      await tester.pumpAndSettle();

      expect(opacityOf(tester, AppIcons.calendarFilled), 1);
      expect(opacityOf(tester, AppIcons.calendar), 0);
      expect(scaleOf(tester), moreOrLessEquals(1));
      expect(
        tester.widget<AppIcon>(glyph(AppIcons.calendarFilled)).color,
        AppColors.iconBrand,
      );
    });

    testWidgets('fades back to the outline when left, without a pop', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpFlippable(tester, active);

      active.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(scaleOf(tester), moreOrLessEquals(1));

      await tester.pumpAndSettle();

      expect(opacityOf(tester, AppIcons.calendar), 1);
      expect(
        tester.widget<AppIcon>(glyph(AppIcons.calendar)).color,
        AppColors.iconDefault,
      );
    });

    testWidgets('switches at once when motion is reduced', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(false);
      addTearDown(active.dispose);
      await pumpFlippable(tester, active, reduceMotion: true);

      active.value = true;
      await tester.pump();

      expect(opacityOf(tester, AppIcons.calendarFilled), 1);
      expect(scaleOf(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('squashes under the finger', (WidgetTester tester) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(false);
      addTearDown(active.dispose);
      await pumpFlippable(tester, active);

      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(find.byType(NavItem)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scaleOf(tester), moreOrLessEquals(1));
    });

    group('haptics', () {
      late List<MethodCall> platformCalls;

      setUp(() {
        platformCalls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          platformCalls.add(call);
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      bool ticked() => platformCalls.any(
            (MethodCall call) =>
                call.method == 'HapticFeedback.vibrate' &&
                call.arguments == 'HapticFeedbackType.selectionClick',
          );

      testWidgets('ticks when an idle tab is chosen', (
        WidgetTester tester,
      ) async {
        final ValueNotifier<bool> active = ValueNotifier<bool>(false);
        addTearDown(active.dispose);
        final List<int> taps = await pumpFlippable(tester, active);

        await tester.tap(find.byType(NavItem));

        expect(taps, hasLength(1));
        expect(ticked(), isTrue);
      });

      testWidgets('stays quiet when the active tab is tapped again', (
        WidgetTester tester,
      ) async {
        final ValueNotifier<bool> active = ValueNotifier<bool>(true);
        addTearDown(active.dispose);
        final List<int> taps = await pumpFlippable(tester, active);

        await tester.tap(find.byType(NavItem));

        // Still reported, so a screen can scroll back to its top.
        expect(taps, hasLength(1));
        expect(ticked(), isFalse);
      });
    });
  });

  group('NavAmbient', () {
    test('gives each filled nav glyph its own signature', () {
      expect(NavAmbient.forGlyph(AppIcons.homeFilled), NavAmbient.doorGlow);
      expect(NavAmbient.forGlyph(AppIcons.searchFilled), NavAmbient.lensGlint);
      expect(
        NavAmbient.forGlyph(AppIcons.calendarFilled),
        NavAmbient.dateTwinkle,
      );
      expect(
        NavAmbient.forGlyph(AppIcons.messageFilled),
        NavAmbient.typingDots,
      );
      expect(NavAmbient.forGlyph(AppIcons.userFilled), NavAmbient.breath);
    });

    test('has none for an outline, or no active glyph at all', () {
      expect(NavAmbient.forGlyph(AppIcons.home), NavAmbient.none);
      expect(NavAmbient.forGlyph(null), NavAmbient.none);
    });

    test('only the breath scales the glyph, and only mid-cycle', () {
      expect(NavAmbient.breath.scaleAt(0.5), greaterThan(1));
      expect(NavAmbient.breath.scaleAt(0), 1);
      expect(NavAmbient.breath.scaleAt(1), 1);
      expect(NavAmbient.typingDots.scaleAt(0.5), 1);
    });
  });

  group('NavItem signature loop', () {
    // The timings the loop is built on: the first cycle waits for the
    // selection to settle, then each cycle is followed by a long rest.
    const Duration settle = Duration(milliseconds: 1000);
    const Duration halfCycle = Duration(milliseconds: 800);
    const Duration rest = Duration(milliseconds: 4400);

    Future<void> pumpSignature(
      WidgetTester tester,
      ValueNotifier<bool> active, {
      AppIcons icon = AppIcons.message,
      AppIcons activeIcon = AppIcons.messageFilled,
      bool reduceMotion = false,
      Locale locale = englishLocale,
    }) async {
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: active,
                builder: (_, bool isActive, _) => NavItem(
                  icon: icon,
                  activeIcon: activeIcon,
                  label: _label,
                  isActive: isActive,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
        locale: locale,
      );
    }

    NavAmbientPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is CustomPaint &&
                widget.foregroundPainter is NavAmbientPainter,
          ),
        )
        .foregroundPainter! as NavAmbientPainter;

    double progress(WidgetTester tester) => painter(tester).progress;

    testWidgets('waits for the selection to settle, then plays', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(false);
      addTearDown(active.dispose);
      await pumpSignature(tester, active);

      active.value = true;
      await tester.pumpAndSettle();
      expect(progress(tester), 0);

      await tester.pump(settle);
      await tester.pump(halfCycle);

      expect(progress(tester), inExclusiveRange(0, 1));
      expect(painter(tester).signature, NavAmbient.typingDots);
    });

    testWidgets('rests between cycles, asking for no frames, then plays again',
        (WidgetTester tester) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpSignature(tester, active);

      await tester.pump(settle);
      await tester.pump(halfCycle);
      await tester.pump(halfCycle);
      await tester.pump();

      expect(progress(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pump(rest);
      await tester.pump(halfCycle);

      expect(progress(tester), inExclusiveRange(0, 1));
    });

    testWidgets('stops the moment its tab is left', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpSignature(tester, active);
      await tester.pump(settle);
      await tester.pump(halfCycle);
      expect(progress(tester), greaterThan(0));

      active.value = false;
      await tester.pumpAndSettle();
      await tester.pump(rest * 3);

      expect(progress(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('never loops when motion is reduced', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpSignature(tester, active, reduceMotion: true);

      await tester.pump(rest * 3);

      expect(progress(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('lets the profile glyph breathe', (WidgetTester tester) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpSignature(
        tester,
        active,
        icon: AppIcons.user,
        activeIcon: AppIcons.userFilled,
      );

      await tester.pump(settle);
      await tester.pump(halfCycle);

      final double scale = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byWidgetPredicate(
                    (Widget widget) =>
                        widget is AppIcon && widget.icon == AppIcons.userFilled,
                  ),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getMaxScaleOnAxis();
      expect(scale, greaterThan(1));
    });

    testWidgets('runs its sequence in reading order in Arabic', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> active = ValueNotifier<bool>(true);
      addTearDown(active.dispose);
      await pumpSignature(tester, active, locale: arabicLocale);

      expect(painter(tester).textDirection, TextDirection.rtl);
    });
  });
}
