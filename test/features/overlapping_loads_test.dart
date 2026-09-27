import 'dart:async';

import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/favourites_controller.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/features/favourites/view_model/favourites_view_model.dart';
import 'package:eventor/features/packs/view_model/packs_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import 'feature_test_helpers.dart';

/// Favourites whose answers are released by hand, in any order.
class _SlowFavourites extends FakeFavouritesRepository {
  final List<({FavouriteKind? kind, Completer<void> release})> pending =
      <({FavouriteKind? kind, Completer<void> release})>[];

  @override
  Future<ApiPage<Favourite>> list({
    FavouriteKind? kind,
    String? categoryId,
    int page = 1,
  }) async {
    final Completer<void> release = Completer<void>();
    pending.add((kind: kind, release: release));
    await release.future;
    return super.list(kind: kind, categoryId: categoryId, page: page);
  }
}

/// Packs whose answers are released by hand, in any order.
class _SlowCatalog extends FakeCatalogRepository {
  final List<Completer<void>> pending = <Completer<void>>[];

  @override
  Future<ApiPage<PackCard>> packs({
    EventType? eventType,
    PackOrder order = PackOrder.savings,
    int page = 1,
  }) async {
    final Completer<void> release = Completer<void>();
    pending.add(release);
    await release.future;
    return super.packs(eventType: eventType, order: order, page: page);
  }
}

void main() {
  test('17 shows only the tab asked for last, however the answers arrive',
      () async {
    final _SlowFavourites repository = _SlowFavourites();
    final FavouritesController controller = FavouritesController(repository);
    addTearDown(controller.dispose);
    final FavouritesViewModel viewModel = FavouritesViewModel(
      favourites: repository,
      catalog: FakeCatalogRepository(),
      controller: controller,
    );
    addTearDown(viewModel.dispose);

    // Services (start) → Packs → Services, each still loading.
    viewModel.setKind(FavouriteKind.pack);
    viewModel.setKind(FavouriteKind.service);
    // The answers land newest first, then the stale ones.
    for (final ({FavouriteKind? kind, Completer<void> release}) call
        in repository.pending.reversed.toList()) {
      call.release.complete();
      await flushAsync();
    }

    expect(viewModel.kind, FavouriteKind.service);
    expect(viewModel.items.every((Favourite f) => f.kind == FavouriteKind.service), isTrue);
    // No row twice.
    expect(viewModel.items.map((Favourite f) => f.id).toSet().length, viewModel.items.length);
    expect(viewModel.isFirstLoad, isFalse);
  });

  test('19 keeps the event type chosen last when an older answer lands late',
      () async {
    final _SlowCatalog catalog = _SlowCatalog();
    final PacksViewModel viewModel = PacksViewModel(catalog: catalog);
    addTearDown(viewModel.dispose);

    viewModel.setEventType(EventType.wedding);
    // The wedding answer first, then the stale "All" one.
    catalog.pending[1].complete();
    await flushAsync();
    catalog.pending[0].complete();
    await flushAsync();

    expect(viewModel.eventType, EventType.wedding);
    expect(viewModel.items.every((PackCard p) => p.eventType == EventType.wedding), isTrue);
  });

  test('19 stays loading until the answer it is waiting for arrives', () async {
    final _SlowCatalog catalog = _SlowCatalog();
    final PacksViewModel viewModel = PacksViewModel(catalog: catalog);
    addTearDown(viewModel.dispose);

    viewModel.setEventType(EventType.wedding);
    catalog.pending[0].complete(); // The stale one.
    await flushAsync();

    expect(viewModel.isFirstLoad, isTrue);

    catalog.pending[1].complete();
    await flushAsync();
    expect(viewModel.isFirstLoad, isFalse);
  });
}
