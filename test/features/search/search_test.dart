import 'dart:async';

import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/recent_searches.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/services/preferences_service.dart';
import 'package:eventor/core/widgets/organisms/service_result_card.dart';
import 'package:eventor/features/search/view/results_view.dart' show categoryNames;
import 'package:eventor/features/search/view_model/results_view_model.dart';
import 'package:eventor/features/search/view_model/search_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  late PreferencesService preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await PreferencesService.load();
  });

  group('RecentSearches', () {
    test('keeps the newest first', () async {
      final RecentSearches recents = RecentSearches(preferences);

      await recents.add('traiteur');
      await recents.add('photo');

      expect(recents.all, <String>['photo', 'traiteur']);
    });

    test('moves a repeat to the top instead of listing it twice', () async {
      final RecentSearches recents = RecentSearches(preferences);

      await recents.add('photo');
      await recents.add('salle');
      await recents.add('PHOTO');

      expect(recents.all, <String>['PHOTO', 'salle']);
    });

    test('keeps at most eight', () async {
      final RecentSearches recents = RecentSearches(preferences);

      for (int i = 0; i < 12; i++) {
        await recents.add('search $i');
      }

      expect(recents.all, hasLength(RecentSearches.limit));
      expect(recents.all.first, 'search 11');
    });

    test('ignores a blank search', () async {
      final RecentSearches recents = RecentSearches(preferences);

      await recents.add('   ');

      expect(recents.all, isEmpty);
    });

    test('removes one, or all', () async {
      final RecentSearches recents = RecentSearches(preferences);
      await recents.add('a');
      await recents.add('b');

      await recents.remove('a');
      expect(recents.all, <String>['b']);

      await recents.clear();
      expect(recents.all, isEmpty);
    });
  });

  group('SearchViewModel', () {
    test('loads the categories with their counts', () async {
      final SearchViewModel viewModel = SearchViewModel(
        catalog: FakeCatalogRepository(),
        recents: RecentSearches(preferences),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.categories, isNotEmpty);
      expect(viewModel.isLoadingCategories, isFalse);
    });

    test('turns a submitted search into results, and remembers it', () async {
      final SearchViewModel viewModel = SearchViewModel(
        catalog: FakeCatalogRepository(),
        recents: RecentSearches(preferences),
      );
      addTearDown(viewModel.dispose);

      final ServiceQuery? query = await viewModel.submit('  photo ');

      expect(query, const ServiceQuery(q: 'photo'));
      expect(viewModel.recents, <String>['photo']);
    });

    test('does nothing for a blank search', () async {
      final SearchViewModel viewModel = SearchViewModel(
        catalog: FakeCatalogRepository(),
        recents: RecentSearches(preferences),
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.submit('  '), isNull);
    });
  });

  group('ResultsViewModel', () {
    late FakeCatalogRepository catalog;

    setUp(() {
      catalog = FakeCatalogRepository()
        ..serviceItems = List<ServiceCard>.generate(
          45,
          (int i) => ServiceCard.fromJson(<String, Object?>{
            ...fixtureCard(),
            'id': 'svc-$i',
          }),
        );
    });

    Future<ResultsViewModel> build([ServiceQuery query = const ServiceQuery(q: 'photo')]) async {
      final ResultsViewModel viewModel = ResultsViewModel(query: query, catalog: catalog);
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('loads the first page', () async {
      final ResultsViewModel viewModel = await build();

      expect(viewModel.items, hasLength(20));
      expect(viewModel.total, 45);
      expect(viewModel.hasMore, isTrue);
    });

    test('adds the next pages, then stops', () async {
      final ResultsViewModel viewModel = await build();

      await viewModel.loadMore();
      await viewModel.loadMore();
      await viewModel.loadMore();

      expect(viewModel.items, hasLength(45));
      expect(viewModel.hasMore, isFalse);
      expect(
        catalog.servicePages.map((({ServiceQuery query, int page, int limit}) c) => c.page),
        <int>[1, 2, 3],
      );
    });

    test('asks for a page only once while one is loading', () async {
      final ResultsViewModel viewModel = await build();
      catalog.gate = Completer<void>();

      final Future<void> first = viewModel.loadMore();
      final Future<void> second = viewModel.loadMore();
      catalog.gate!.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(catalog.servicePages, hasLength(2));
    });

    test('keeps the list and offers a retry when a page fails', () async {
      final ResultsViewModel viewModel = await build();
      catalog.servicesError = const NetworkFailure();

      await viewModel.loadMore();

      expect(viewModel.items, hasLength(20));
      expect(viewModel.loadMoreFailed, isTrue);

      catalog.servicesError = null;
      await viewModel.loadMore();
      expect(viewModel.items, hasLength(40));
      expect(viewModel.loadMoreFailed, isFalse);
    });

    test('is empty when nothing matched', () async {
      catalog.serviceItems = <ServiceCard>[];

      final ResultsViewModel viewModel = await build();

      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.hasMore, isFalse);
    });

    test('names the active filters and removes them one by one', () async {
      final ResultsViewModel viewModel = await build(
        ServiceQuery(
          q: 'photo',
          categoryIds: const <String>{'cat-1'},
          wilayaCodes: const <int>{16},
          priceMax: 90000,
          minRating: 4,
          eventDate: DateTime(2026, 10, 20),
          favouritesOnly: true,
        ),
      );

      expect(viewModel.activeFilters, FilterChipKind.values);
      expect(viewModel.without(FilterChipKind.price).priceMax, isNull);
      expect(viewModel.without(FilterChipKind.wilaya).wilayaCodes, isEmpty);
      expect(viewModel.without(FilterChipKind.category).q, 'photo');
    });

    test('titles a category search with its name', () async {
      final String id = catalog.categoryList.first.id;

      final ResultsViewModel viewModel =
          await build(ServiceQuery(categoryIds: <String>{id}));

      expect(viewModel.categories.map((CategoryWithCount c) => c.id), <String>[id]);
    });

    test('names several categories in the catalog\'s order', () async {
      final List<CategoryWithCount> list = catalog.categoryList;
      // Picked in reverse; shown as the catalog orders them.
      final ResultsViewModel viewModel = await build(
        ServiceQuery(categoryIds: <String>{list[2].id, list[0].id}),
      );

      expect(viewModel.categories.map((CategoryWithCount c) => c.id), <String>[
        list[0].id,
        list[2].id,
      ]);
      expect(
        categoryNames(viewModel.categories, 'en'),
        '${list[0].name.of('en')} · ${list[2].name.of('en')}',
      );
    });

    test('takes every category off with the category chip', () async {
      final List<CategoryWithCount> list = catalog.categoryList;
      final ResultsViewModel viewModel = await build(
        ServiceQuery(categoryIds: <String>{list[0].id, list[1].id}),
      );

      expect(viewModel.without(FilterChipKind.category).categoryIds, isEmpty);
    });
  });

  group('Search screens', () {
    Future<TestApp> startOnSearch(WidgetTester tester) async {
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
      );
      await startApp(tester, app);
      await tapAndSettle(tester, find.text(l10n(tester).navSearch));
      return app;
    }

    String location(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('searching opens the results and remembers the search',
        (WidgetTester tester) async {
      final TestApp app = await startOnSearch(tester);

      await tester.enterText(find.byType(TextField), 'photo');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(location(app), AppRoutes.resultsFor(const ServiceQuery(q: 'photo')));
      expect(find.byType(ServiceResultCard), findsWidgets);
      expect(app.services.preferences.recentSearches, <String>['photo']);
    });

    testWidgets('a category opens its results (S2a)', (WidgetTester tester) async {
      final TestApp app = await startOnSearch(tester);
      final CategoryWithCount category = app.catalog.categoryList.first;

      await tapAndSettle(tester, find.text(category.name.of('en')));

      expect(location(app), AppRoutes.resultsFor(ServiceQuery(categoryIds: <String>{category.id})));
    });

    testWidgets('nothing found shows S2b with a way to clear the filters',
        (WidgetTester tester) async {
      final TestApp app = await startOnSearch(tester);
      app.catalog.serviceItems = <ServiceCard>[];

      app.services.router.go(
        AppRoutes.resultsFor(const ServiceQuery(q: 'drone', minRating: 4.5)),
      );
      await tester.pumpAndSettle();
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.resultsEmptyTitle), findsOneWidget);
      await tapAndSettle(tester, button(strings.resultsClearFilters));

      expect(location(app), AppRoutes.resultsFor(const ServiceQuery(q: 'drone')));
    });

    testWidgets('a result opens its service', (WidgetTester tester) async {
      final TestApp app = await startOnSearch(tester);
      app.services.router.go(AppRoutes.resultsFor(const ServiceQuery(q: 'photo')));
      await tester.pumpAndSettle();
      final ServiceCard first = app.catalog.serviceItems.first;

      await tapAndSettle(tester, find.text(first.title.of('en')));

      expect(location(app), AppRoutes.serviceFor(first.id));
    });
  });
}

/// One live service card, as JSON, to copy with a new id.
Map<String, Object?> fixtureCard() => fixtureList('services_page.json').first;
