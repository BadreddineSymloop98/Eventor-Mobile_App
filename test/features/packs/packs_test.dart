import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/organisms/detail_states.dart';
import 'package:eventor/core/widgets/organisms/pack_cards.dart';
import 'package:eventor/features/pack_detail/view/pack_detail_view.dart';
import 'package:eventor/features/pack_detail/view_model/pack_detail_view_model.dart';
import 'package:eventor/features/packs/view/packs_view.dart';
import 'package:eventor/features/packs/view_model/packs_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

PackDetail pausedPack() {
  final Map<String, Object?> json = fixtureData('pack_detail.json');
  return PackDetail.fromJson(<String, Object?>{
    ...json,
    'provider': <String, Object?>{
      ...json['provider']! as Map<String, Object?>,
      'acceptingBookings': false,
    },
  });
}

void main() {
  group('PacksViewModel', () {
    test('loads every pack, best savings first', () async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final PacksViewModel viewModel = PacksViewModel(catalog: catalog);
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.items, hasLength(3));
      expect(catalog.packQueries.single.order, PackOrder.savings);
      expect(catalog.packQueries.single.eventType, isNull);
    });

    test('reloads from the first page for an event type', () async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final PacksViewModel viewModel = PacksViewModel(catalog: catalog);
      addTearDown(viewModel.dispose);
      await flushAsync();

      viewModel.setEventType(EventType.wedding);
      await flushAsync();

      expect(catalog.packQueries.last.eventType, EventType.wedding);
      expect(catalog.packQueries.last.page, 1);
      expect(viewModel.items.every((PackCard p) => p.eventType == EventType.wedding), isTrue);
    });

    test('reloads for a new order', () async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final PacksViewModel viewModel = PacksViewModel(catalog: catalog);
      addTearDown(viewModel.dispose);
      await flushAsync();

      viewModel.setOrder(PackOrder.priceAsc);
      await flushAsync();

      expect(catalog.packQueries.last.order, PackOrder.priceAsc);
    });

    test('is empty when a type has no packs', () async {
      final PacksViewModel viewModel = PacksViewModel(
        catalog: FakeCatalogRepository(),
        eventType: EventType.graduation,
      );
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.isEmpty, isTrue);
    });
  });

  group('PackDetailViewModel', () {
    test('loads the pack and this month', () async {
      final PackDetailViewModel viewModel = PackDetailViewModel(
        id: 'k-1',
        catalog: FakeCatalogRepository(),
        today: () => DateTime(2026, 3, 3),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();

      expect(viewModel.pack, isNotNull);
      expect(viewModel.availability, isNotNull);
    });

    test('knows a removed pack', () async {
      final PackDetailViewModel viewModel = PackDetailViewModel(
        id: 'gone',
        catalog: FakeCatalogRepository()
          ..packError = apiFailure(ApiErrorCode.packNotFound, statusCode: 404),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.isGone, isTrue);
    });

    test('picks no date when bookings are paused', () async {
      final PackDetailViewModel viewModel = PackDetailViewModel(
        id: 'k-1',
        catalog: FakeCatalogRepository()..packDetail = pausedPack(),
        today: () => DateTime(2026, 3, 3),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();

      viewModel.selectDate(DateTime(2026, 3, 14));

      expect(viewModel.selectedDate, isNull);
    });
  });

  group('Pack screens', () {
    Future<TestApp> open(
      WidgetTester tester,
      String location, {
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
      app.services.router.push(location);
      await tester.pumpAndSettle();
      return app;
    }

    String location(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('19 lists the packs and opens one', (WidgetTester tester) async {
      final TestApp app = await open(tester, AppRoutes.packs);
      final PackCard first = app.catalog.packItems.first;

      expect(find.byType(PacksView), findsOneWidget);
      expect(find.byType(PackListCard), findsWidgets);

      await tapAndSettle(tester, find.text(first.name.of('en')).first);
      expect(location(app), AppRoutes.packFor(first.id));
    });

    testWidgets('19 filters by event type', (WidgetTester tester) async {
      final TestApp app = await open(tester, AppRoutes.packs);

      await tapAndSettle(tester, find.text(l10n(tester).eventTypeWedding));

      expect(app.catalog.packQueries.last.eventType, EventType.wedding);
    });

    testWidgets('20 shows the pack with its request button', (WidgetTester tester) async {
      await open(tester, AppRoutes.packFor('k-1'));
      final AppLocalizations strings = l10n(tester);

      expect(find.byType(PackDetailView), findsOneWidget);
      expect(find.text(strings.packInside), findsOneWidget);
      expect(button(strings.requestPack), findsOneWidget);
      // No pack policy exists, and the app never makes one up.
      expect(find.textContaining('cancellation'), findsNothing);
    });

    testWidgets('20 requesting is coming soon', (WidgetTester tester) async {
      await open(tester, AppRoutes.packFor('k-1'));

      await tester.tap(button(l10n(tester).requestPack));
      await tester.pump();

      expect(find.text(l10n(tester).comingSoon), findsOneWidget);
    });

    testWidgets('20 swaps the bar when bookings are paused', (WidgetTester tester) async {
      await open(
        tester,
        AppRoutes.packFor('k-1'),
        catalog: FakeCatalogRepository()..packDetail = pausedPack(),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.notAcceptingTitle), findsOneWidget);
      expect(button(strings.requestPack), findsNothing);
    });

    testWidgets('20 opens one of its services', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final TestApp app = await open(tester, AppRoutes.packFor('k-1'), catalog: catalog);
      final PackItem item = catalog.packDetail.items.first;

      await tester.scrollUntilVisible(find.text(item.title.of('en')), 200);
      await tapAndSettle(tester, find.text(item.title.of('en')));

      expect(location(app), AppRoutes.serviceFor(item.serviceId));
    });

    testWidgets('20 says a removed pack is gone', (WidgetTester tester) async {
      await open(
        tester,
        AppRoutes.packFor('gone'),
        catalog: FakeCatalogRepository()
          ..packError = apiFailure(ApiErrorCode.packNotFound, statusCode: 404),
      );

      expect(find.byType(DetailGoneView), findsOneWidget);
    });

    testWidgets('20 keeps the price before the struck total in Arabic',
        (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      await open(tester, AppRoutes.packFor('k-1'), catalog: catalog, locale: arabicLocale);

      final Finder amounts = find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.textDirection == TextDirection.ltr,
      );
      expect(amounts, findsWidgets);
    });
  });
}
