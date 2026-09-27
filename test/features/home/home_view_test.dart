import 'dart:async';

import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/molecules/state_card.dart';
import 'package:eventor/features/home/view/home_view.dart';
import 'package:eventor/features/home/view/widgets/home_skeleton.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// A signed-in client on Home, with [catalog] behind it.
  Future<TestApp> startHome(
    WidgetTester tester, {
    FakeCatalogRepository? catalog,
    Locale? locale,
  }) async {
    final TestApp app = await buildTestApp(
      hasSeenOnboarding: true,
      locale: locale,
      auth: FakeAuthRepository()..restoredUser = testUser(),
      catalog: catalog,
    );
    await startApp(tester, app);
    return app;
  }

  HomeFeed feedWith(Map<String, Object?> changes) =>
      HomeFeed.fromJson(<String, Object?>{...fixtureData('home.json'), ...changes});

  String location(TestApp app) =>
      app.services.router.routerDelegate.currentConfiguration.uri.toString();

  group('HomeView', () {
    testWidgets('shows the skeleton, then the feed', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository()
        ..gate = Completer<void>();
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        catalog: catalog,
      );
      await launch(tester, app);
      await tester.pump();

      expect(find.byType(HomeSkeleton), findsOneWidget);

      catalog.gate!.complete();
      await tester.pumpAndSettle();

      final AppLocalizations strings = l10n(tester);
      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.text(strings.homeYourBookings), findsOneWidget);
      expect(find.text(strings.homeYourBudget), findsOneWidget);
      expect(find.text(strings.homeReadyPacks), findsOneWidget);
    });

    testWidgets('greets the client by name, with their city', (WidgetTester tester) async {
      await startHome(tester);

      expect(find.byType(HomeView), findsOneWidget);
      expect(find.text('Amina Benali'), findsOneWidget);
      expect(find.text('Alger'), findsWidgets);
    });

    testWidgets('asks for a city when none is set', (WidgetTester tester) async {
      await startHome(
        tester,
        catalog: FakeCatalogRepository()..homeFeed = feedWith(<String, Object?>{'wilaya': null}),
      );

      expect(find.text(l10n(tester).chooseCity), findsOneWidget);
    });

    testWidgets('leaves out the sections it has nothing for', (WidgetTester tester) async {
      await startHome(
        tester,
        catalog: FakeCatalogRepository()
          ..homeFeed = feedWith(<String, Object?>{
            'upcomingBookings': <Object?>[],
            'packs': <Object?>[],
          }),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.homeYourBookings), findsNothing);
      expect(find.text(strings.homeReadyPacks), findsNothing);
      // The budget card always shows.
      expect(find.text(strings.homeYourBudget), findsOneWidget);
    });

    testWidgets('invites a client with no budget to make one (11c)',
        (WidgetTester tester) async {
      await startHome(
        tester,
        catalog: FakeCatalogRepository()
          ..homeFeed = feedWith(<String, Object?>{
            'budget': <String, Object?>{'exists': false},
          }),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.budgetEmptyTitle), findsOneWidget);
      expect(button(strings.budgetCreate), findsOneWidget);
      expect(find.text(strings.budgetDetails), findsNothing);
    });

    testWidgets('offers a retry when the feed fails', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository()
        ..homeError = const NetworkFailure();
      await startHome(tester, catalog: catalog);

      expect(find.byType(StateCard), findsOneWidget);

      catalog.homeError = null;
      await tapAndSettle(tester, find.text(l10n(tester).stateRetry));

      expect(find.byType(StateCard), findsNothing);
      expect(find.text(l10n(tester).homeYourBudget), findsOneWidget);
    });

    testWidgets('opens a nearby service', (WidgetTester tester) async {
      final TestApp app = await startHome(tester);
      final ServiceCard service = app.catalog.homeFeed.nearbyServices.first;

      await tester.scrollUntilVisible(find.text(service.title.of('en')), 300);
      await tapAndSettle(tester, find.text(service.title.of('en')));

      expect(location(app), AppRoutes.serviceFor(service.id));
    });

    testWidgets('opens a category\'s results inside Home, and Back returns there',
        (WidgetTester tester) async {
      final TestApp app = await startHome(tester);
      final CategoryWithCount category = app.catalog.homeFeed.categories.first;

      await tapAndSettle(tester, find.text(category.name.of('en')));

      expect(
        location(app),
        AppRoutes.resultsFor(
          ServiceQuery(categoryIds: <String>{category.id}),
          base: AppRoutes.homeResults,
        ),
      );

      await tapAndSettle(tester, find.bySemanticsLabel(l10n(tester).backLabel));

      expect(location(app), AppRoutes.home);
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('opens the Search tab from the search field', (WidgetTester tester) async {
      final TestApp app = await startHome(tester);

      await tapAndSettle(tester, find.text(l10n(tester).homeSearchHint));

      expect(location(app), AppRoutes.search);
    });

    testWidgets('shows the dot only while something is unread',
        (WidgetTester tester) async {
      final TestApp app = await startHome(tester);

      expect(
        find.bySemanticsLabel(l10n(tester).homeNotificationsUnread),
        findsOneWidget,
      );

      app.services.badges.update(unreadNotifications: 0);
      await tester.pump();

      expect(
        find.bySemanticsLabel(l10n(tester).homeNotificationsUnread),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(l10n(tester).homeNotificationsLabel),
        findsOneWidget,
      );
    });

    testWidgets('the bell opens Notifications', (WidgetTester tester) async {
      // The screen itself arrives in a later task; until then the router
      // shows UnknownRouteView, so the location is what this asserts.
      final TestApp app = await startHome(tester);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel(l10n(tester).homeNotificationsUnread),
      );

      expect(
        app.services.router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.notifications,
      );
    });

    testWidgets('saves a new city and reloads', (WidgetTester tester) async {
      final TestApp app = await startHome(tester);
      final int loads = app.catalog.homeCalls;

      await tapAndSettle(tester, find.text('Alger').first);
      await tapAndSettle(tester, find.text('Blida'));

      expect(app.auth.wilayaUpdates, <int>[9]);
      expect(app.catalog.homeCalls, loads + 1);
    });

    testWidgets('keeps the budget amounts in order in Arabic', (WidgetTester tester) async {
      await startHome(tester, locale: arabicLocale);

      final Finder spent = find.text('180 000');
      expect(tester.widget<Text>(spent).textDirection, TextDirection.ltr);
      // The spent amount leads, on the right.
      expect(
        tester.getCenter(spent).dx,
        greaterThan(tester.getCenter(find.text('400 000')).dx),
      );
    });
  });
}
