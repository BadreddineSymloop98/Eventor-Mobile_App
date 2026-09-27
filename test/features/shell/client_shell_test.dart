import 'package:eventor/core/widgets/atoms/app_icon.dart';
import 'package:eventor/core/widgets/molecules/nav_item.dart';
import 'package:eventor/features/shell/view/client_shell.dart';
import 'package:eventor/features/shell/view/placeholder_tab_view.dart';
import 'package:eventor/features/shell/view/profile_tab_view.dart';
import 'package:eventor/features/welcome/view/welcome_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// A client with a stored session, landed on the shell.
  Future<TestApp> startClient(WidgetTester tester) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      auth: FakeAuthRepository()..restoredUser = testUser(),
    );
    await startApp(tester, app);
    expect(find.byType(ClientShell), findsOneWidget);
    return app;
  }

  Finder tab(String label) =>
      find.widgetWithText(NavItem, label);

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(tab(label));
    await tester.pumpAndSettle();
  }

  group('ClientShell', () {
    testWidgets('offers the five tabs, Home first and active',
        (WidgetTester tester) async {
      await startClient(tester);
      final AppLocalizations strings = l10n(tester);

      for (final String label in <String>[
        strings.navHome,
        strings.navSearch,
        strings.navBookings,
        strings.navMessages,
        strings.navProfile,
      ]) {
        expect(tab(label), findsOneWidget, reason: label);
      }
      final NavItem home = tester.widget<NavItem>(tab(strings.navHome));
      expect(home.isActive, isTrue);
      expect(home.activeIcon, AppIcons.homeFilled);
    });

    testWidgets('moves to a tab and marks it active', (WidgetTester tester) async {
      await startClient(tester);
      final AppLocalizations strings = l10n(tester);

      await openTab(tester, strings.navBookings);

      expect(find.byType(PlaceholderTabView), findsOneWidget);
      expect(tester.widget<NavItem>(tab(strings.navBookings)).isActive, isTrue);
      expect(tester.widget<NavItem>(tab(strings.navHome)).isActive, isFalse);
    });

    testWidgets('says the unbuilt tabs are on their way', (WidgetTester tester) async {
      await startClient(tester);
      final AppLocalizations strings = l10n(tester);

      await openTab(tester, strings.navMessages);

      expect(find.text(strings.tabComingSoonTitle), findsOneWidget);
    });

    testWidgets('shows unread conversations on Messages', (WidgetTester tester) async {
      final TestApp app = await startClient(tester);

      app.services.badges.update(unreadConversations: 3);
      await tester.pump();

      expect(tester.widget<NavItem>(tab(l10n(tester).navMessages)).badgeCount, 3);
    });

    testWidgets('clears the badge on sign-out', (WidgetTester tester) async {
      final TestApp app = await startClient(tester);
      app.services.badges.update(unreadConversations: 3);

      await openTab(tester, l10n(tester).navProfile);
      await tapAndSettle(tester, button(l10n(tester).logOut));

      expect(app.services.badges.unreadConversations, 0);
    });
  });

  group('ProfileTabView', () {
    testWidgets('shows who is signed in, Favorites and Log out',
        (WidgetTester tester) async {
      await startClient(tester);
      final AppLocalizations strings = l10n(tester);

      await openTab(tester, strings.navProfile);

      expect(find.byType(ProfileTabView), findsOneWidget);
      expect(find.text('Amina Benali'), findsOneWidget);
      expect(find.text(strings.profileFavourites), findsOneWidget);
      expect(button(strings.logOut), findsOneWidget);
    });

    testWidgets('logs out to Welcome', (WidgetTester tester) async {
      final TestApp app = await startClient(tester);

      await openTab(tester, l10n(tester).navProfile);
      await tapAndSettle(tester, button(l10n(tester).logOut));

      expect(app.auth.logoutCalls, 1);
      expect(find.byType(WelcomeView), findsOneWidget);
    });
  });
}
