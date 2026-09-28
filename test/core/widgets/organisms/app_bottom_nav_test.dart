import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/nav_item.dart';
import 'package:eventor/core/widgets/organisms/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  const List<String> english = <String>['Home', 'Bookings', 'Profile'];
  const List<String> arabic = <String>['الرئيسية', 'الحجوزات', 'الملف'];

  Future<List<int>> pumpNav(
    WidgetTester tester, {
    List<String> labels = english,
    int currentIndex = 0,
    Locale locale = englishLocale,
  }) async {
    final List<int> selected = <int>[];
    await pumpAppWidget(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: AppBottomNav(
          destinations: <AppNavDestination>[
            AppNavDestination(icon: AppIcons.home, label: labels[0]),
            AppNavDestination(
              icon: AppIcons.calendar,
              label: labels[1],
              badgeCount: 3,
            ),
            AppNavDestination(icon: AppIcons.user, label: labels[2]),
          ],
          currentIndex: currentIndex,
          onSelected: selected.add,
        ),
      ),
      locale: locale,
    );
    return selected;
  }

  /// The horizontal centres of [labels], in the order given.
  List<double> centresOf(WidgetTester tester, List<String> labels) => <double>[
        for (final String label in labels) tester.getCenter(find.text(label)).dx,
      ];

  group('AppBottomNav', () {
    testWidgets('lays the tabs out left to right in English',
        (WidgetTester tester) async {
      await pumpNav(tester);
      final List<double> x = centresOf(tester, english);

      expect(x[0], lessThan(x[1]));
      expect(x[1], lessThan(x[2]));
    });

    testWidgets('keeps the same order in Arabic', (WidgetTester tester) async {
      // The design's RTL rule for this component: a tab sits in the same
      // place in both languages; only its label translates.
      await pumpNav(tester, labels: arabic, locale: arabicLocale);
      final List<double> x = centresOf(tester, arabic);

      expect(x[0], lessThan(x[1]));
      expect(x[1], lessThan(x[2]));
    });

    testWidgets('lets each label follow the app direction',
        (WidgetTester tester) async {
      await pumpNav(tester, labels: arabic, locale: arabicLocale);

      expect(
        Directionality.of(tester.element(find.text(arabic[1]))),
        TextDirection.rtl,
      );
    });

    testWidgets('gives each tab an equal share of the width',
        (WidgetTester tester) async {
      await pumpNav(tester);
      final List<double> widths = <double>[
        for (final Element item in find.byType(NavItem).evaluate())
          item.size!.width,
      ];

      expect(widths.toSet(), hasLength(1));
    });

    testWidgets('marks the current tab active and no other',
        (WidgetTester tester) async {
      await pumpNav(tester, currentIndex: 1);
      final List<bool> active = tester
          .widgetList<NavItem>(find.byType(NavItem))
          .map((NavItem item) => item.isActive)
          .toList();

      expect(active, <bool>[false, true, false]);
    });

    testWidgets('reports which tab was tapped', (WidgetTester tester) async {
      final List<int> selected = await pumpNav(tester);

      await tester.tap(find.text('Profile'));
      await tester.tap(find.text('Home'));

      expect(selected, <int>[2, 0]);
    });

    testWidgets('reports the same index for the same place in Arabic',
        (WidgetTester tester) async {
      final List<int> selected =
          await pumpNav(tester, labels: arabic, locale: arabicLocale);

      await tester.tap(find.text(arabic[2]));

      expect(selected, <int>[2]);
    });

    testWidgets('passes the badge through to its tab',
        (WidgetTester tester) async {
      await pumpNav(tester);

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('puts the indicator under the current tab',
        (WidgetTester tester) async {
      await pumpNav(tester, labels: arabic, locale: arabicLocale, currentIndex: 2);
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.byKey(AppBottomNav.indicatorKey)).dx,
        moreOrLessEquals(tester.getCenter(find.byType(NavItem).at(2)).dx,
            epsilon: 0.5),
      );
    });

    testWidgets('hands each tab its filled glyph', (WidgetTester tester) async {
      await pumpAppWidget(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: AppBottomNav(
            destinations: const <AppNavDestination>[
              AppNavDestination(
                icon: AppIcons.home,
                activeIcon: AppIcons.homeFilled,
                label: 'Home',
              ),
              AppNavDestination(icon: AppIcons.user, label: 'Profile'),
            ],
            currentIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      expect(
        tester.widget<NavItem>(find.byType(NavItem).first).activeIcon,
        AppIcons.homeFilled,
      );
      expect(
        tester.widget<NavItem>(find.byType(NavItem).last).activeIcon,
        isNull,
      );
    });
  });

  group('AppBottomNav indicator', () {
    /// A nav that actually changes tab when one is tapped, like a real shell.
    Future<void> pumpLiveNav(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      int current = 0;
      await pumpAppWidget(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Align(
                alignment: Alignment.bottomCenter,
                child: AppBottomNav(
                  destinations: <AppNavDestination>[
                    for (final String label in english)
                      AppNavDestination(icon: AppIcons.home, label: label),
                  ],
                  currentIndex: current,
                  onSelected: (int i) => setState(() => current = i),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Rect indicator(WidgetTester tester) =>
        tester.getRect(find.byKey(AppBottomNav.indicatorKey));

    double tabCentre(WidgetTester tester, int index) =>
        tester.getCenter(find.byType(NavItem).at(index)).dx;

    testWidgets('stretches across the gap, then settles on the new tab', (
      WidgetTester tester,
    ) async {
      await pumpLiveNav(tester);
      final double restingWidth = indicator(tester).width;

      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // In flight: wider than at rest, reaching towards Profile.
      expect(indicator(tester).width, greaterThan(restingWidth));

      await tester.pumpAndSettle();

      expect(indicator(tester).width, moreOrLessEquals(restingWidth));
      expect(
        indicator(tester).center.dx,
        moreOrLessEquals(tabCentre(tester, 2), epsilon: 0.5),
      );
    });

    testWidgets('leads with the edge facing the new tab', (
      WidgetTester tester,
    ) async {
      await pumpLiveNav(tester);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      final Rect atProfile = indicator(tester);

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Heading left: the left edge has moved away, the right edge barely.
      final Rect inFlight = indicator(tester);
      expect(atProfile.left - inFlight.left,
          greaterThan(atProfile.right - inFlight.right));
    });

    testWidgets('jumps without stretching when motion is reduced', (
      WidgetTester tester,
    ) async {
      await pumpLiveNav(tester, reduceMotion: true);
      final double restingWidth = indicator(tester).width;

      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(indicator(tester).width, moreOrLessEquals(restingWidth));
      expect(
        indicator(tester).center.dx,
        moreOrLessEquals(tabCentre(tester, 2), epsilon: 0.5),
      );
    });
  });
}
