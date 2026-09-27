import 'dart:async';

import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/features/filters/view_model/filters_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../feature_test_helpers.dart';

void main() {
  late FakeCatalogRepository catalog;

  setUp(() => catalog = FakeCatalogRepository());

  FiltersViewModel build({
    ServiceQuery initial = const ServiceQuery(q: 'photo'),
    int? homeWilaya = 16,
  }) {
    final FiltersViewModel viewModel = FiltersViewModel(
      initial: initial,
      catalog: catalog,
      reference: FakeReferenceRepository(),
      homeWilaya: homeWilaya,
      debounce: const Duration(milliseconds: 300),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  /// The queries counted so far, by the single-row requests they sent.
  List<ServiceQuery> counted() => <ServiceQuery>[
        for (final ({ServiceQuery query, int page, int limit}) call
            in catalog.servicePages)
          if (call.limit == 1) call.query,
      ];

  group('FiltersViewModel counting', () {
    test('counts the starting query at once', () async {
      final FiltersViewModel viewModel = build();
      await flushAsync();

      expect(counted(), <ServiceQuery>[const ServiceQuery(q: 'photo')]);
      expect(viewModel.resultCount, catalog.serviceItems.length);
    });

    test('waits for changes to settle before counting again', () async {
      final FiltersViewModel viewModel = build();
      await flushAsync();

      viewModel.setMinRating(4);
      viewModel.setOrder(ServiceOrder.rating);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(counted(), hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 250));
      await flushAsync();
      // One request for both changes, carrying both.
      expect(counted(), hasLength(2));
      expect(counted().last.minRating, 4);
      expect(counted().last.order, ServiceOrder.rating);
    });

    test('drops a count that a newer change overtook', () async {
      final FiltersViewModel viewModel = build(
        initial: const ServiceQuery(),
      );
      await flushAsync();

      // The next count hangs until released; a newer one runs meanwhile.
      catalog.gate = Completer<void>();
      viewModel.setMinRating(4);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      catalog.serviceItems = catalog.serviceItems.take(1).toList();
      viewModel.setMinRating(4.5);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      catalog.gate!.complete();
      await flushAsync();

      expect(viewModel.resultCount, 1);
      expect(viewModel.isCounting, isFalse);
    });
  });

  group('FiltersViewModel choices', () {
    test('picks several categories, and a second tap takes one off', () {
      final FiltersViewModel viewModel = build();

      viewModel.toggleCategory('cat-1');
      expect(viewModel.query.categoryIds, <String>{'cat-1'});

      viewModel.toggleCategory('cat-2');
      expect(viewModel.query.categoryIds, <String>{'cat-1', 'cat-2'});

      viewModel.toggleCategory('cat-1');
      expect(viewModel.query.categoryIds, <String>{'cat-2'});

      viewModel.toggleCategory('cat-2');
      expect(viewModel.query.categoryIds, isEmpty);
    });

    test('counts several categories as one filter', () {
      final FiltersViewModel viewModel = build();

      viewModel
        ..toggleCategory('cat-1')
        ..toggleCategory('cat-2');

      expect(viewModel.query.filterCount, 1);
    });

    test('toggles wilayas', () {
      final FiltersViewModel viewModel = build();

      viewModel.toggleWilaya(9);
      viewModel.toggleWilaya(42);
      viewModel.toggleWilaya(9);

      expect(viewModel.query.wilayaCodes, <int>{42});
    });

    test('shows the client\'s city first, then the selected ones', () async {
      final FiltersViewModel viewModel = build();
      await flushAsync();

      viewModel.setWilayas(<int>{42, 9});

      expect(
        viewModel.wilayaChips.map((Wilaya w) => w.code),
        <int>[16, 9, 42],
      );
    });

    test('reads the ends of the budget slider as no limit', () {
      final FiltersViewModel viewModel = build();

      viewModel.setPrice(0, ServiceQuery.priceCeiling.toDouble());
      expect(viewModel.query.priceMin, isNull);
      expect(viewModel.query.priceMax, isNull);

      viewModel.setPrice(30000, 250000);
      expect(viewModel.query.priceMin, 30000);
      expect(viewModel.query.priceMax, 250000);
    });

    test('clears every filter but keeps the search', () {
      final FiltersViewModel viewModel = build();
      viewModel
        ..toggleCategory('cat-1')
        ..toggleWilaya(9)
        ..setMinRating(4)
        ..setEventDate(DateTime(2026, 10, 20))
        ..setFavouritesOnly(true);

      viewModel.clearAll();

      expect(viewModel.query.filterCount, 0);
      expect(viewModel.query.q, 'photo');
    });

    test('loads the categories and wilayas to choose from', () async {
      final FiltersViewModel viewModel = build();
      await flushAsync();

      expect(viewModel.categories, isNotEmpty);
      expect(viewModel.allWilayas, FakeReferenceRepository.sampleWilayas);
    });
  });
}
