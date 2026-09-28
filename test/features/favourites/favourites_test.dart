import 'package:eventor/core/catalog/favourites_controller.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/organisms/favourite_tile.dart';
import 'package:eventor/features/favourites/view/favourites_view.dart';
import 'package:eventor/features/favourites/view_model/favourites_view_model.dart';
import 'package:eventor/features/shell/view/profile_tab_view.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  group('FavouritesViewModel', () {
    late FakeFavouritesRepository repository;
    late FavouritesController controller;

    setUp(() {
      repository = FakeFavouritesRepository();
      controller = FavouritesController(repository);
    });

    tearDown(() => controller.dispose());

    Future<FavouritesViewModel> build() async {
      final FavouritesViewModel viewModel = FavouritesViewModel(
        favourites: repository,
        catalog: FakeCatalogRepository(),
        controller: controller,
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      return viewModel;
    }

    test('starts on saved services', () async {
      final FavouritesViewModel viewModel = await build();

      expect(viewModel.kind, FavouriteKind.service);
      expect(viewModel.items.every((Favourite f) => f.kind == FavouriteKind.service), isTrue);
    });

    test('switches to packs, dropping the category', () async {
      final FavouritesViewModel viewModel = await build();
      viewModel.setCategory('cat-1');
      await flushAsync();

      viewModel.setKind(FavouriteKind.pack);
      await flushAsync();

      expect(repository.calls.last, 'list:pack:null:1');
    });

    test('filters services by category', () async {
      final FavouritesViewModel viewModel = await build();

      viewModel.setCategory('cat-1');
      await flushAsync();

      expect(repository.calls.last, 'list:service:cat-1:1');
    });

    test('takes a card off at once and puts it back on Undo, without a call',
        () async {
      final FavouritesViewModel viewModel = await build();
      final Favourite first = viewModel.items.first;
      final int callsBefore = repository.calls.length;

      final int index = viewModel.removeLocally(first);
      expect(viewModel.items, isNot(contains(first)));

      viewModel.undoRemove(first, index);
      expect(viewModel.items.first, first);
      expect(repository.calls.length, callsBefore);
    });

    test('tells the server once Undo has passed, without reloading itself',
        () async {
      final FavouritesViewModel viewModel = await build();
      final Favourite first = viewModel.items.first;
      final int index = viewModel.removeLocally(first);
      final int lists = repository.calls.where((String c) => c.startsWith('list')).length;

      final Failure? failure = await viewModel.commitRemove(first, index);
      await flushAsync();

      expect(failure, isNull);
      expect(repository.calls, contains('removeById:${first.id}'));
      expect(controller.isFavourite(first.target, fallback: true), isFalse);
      expect(repository.calls.where((String c) => c.startsWith('list')).length, lists);
    });

    test('puts the card back when the server refuses', () async {
      final FavouritesViewModel viewModel = await build();
      final Favourite first = viewModel.items.first;
      final int index = viewModel.removeLocally(first);
      repository.failNext = const NetworkFailure();

      final Failure? failure = await viewModel.commitRemove(first, index);

      expect(failure, isA<NetworkFailure>());
      expect(viewModel.items.first, first);
    });

    test('reloads when a heart changes on another screen', () async {
      await build();
      final int lists = repository.calls.where((String c) => c.startsWith('list')).length;

      await controller.toggle(const FavouriteTarget.service('elsewhere'), current: false);
      await flushAsync();

      expect(repository.calls.where((String c) => c.startsWith('list')).length, lists + 1);
    });
  });

  group('FavouritesView', () {
    Future<TestApp> openFavourites(WidgetTester tester, {FakeFavouritesRepository? favourites}) async {
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        favourites: favourites,
      );
      await startApp(tester, app);
      await tapAndSettle(tester, find.text(l10n(tester).navProfile));
      await tapAndSettle(tester, find.text(l10n(tester).profileFavourites));
      expect(find.byType(FavouritesView), findsOneWidget);
      return app;
    }

    String location(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('opens from the Profile tab', (WidgetTester tester) async {
      final TestApp app = await openFavourites(tester);

      expect(location(app), AppRoutes.favourites);
      expect(find.byType(FavouriteTile), findsWidgets);
    });

    testWidgets('opens a saved service', (WidgetTester tester) async {
      final TestApp app = await openFavourites(tester);
      final Favourite first = app.favouritesRepository.items.first;

      await tapAndSettle(tester, find.text(first.title.of('en')));

      expect(location(app), AppRoutes.serviceFor(first.targetId));
    });

    testWidgets('removes with Undo, and Undo keeps it', (WidgetTester tester) async {
      final TestApp app = await openFavourites(tester);
      final Favourite first = app.favouritesRepository.items.first;
      final AppLocalizations strings = l10n(tester);

      await tester.tap(find.bySemanticsLabel(strings.favouriteSaved).first);
      await tester.pump();
      expect(find.text(first.title.of('en')), findsNothing);

      await tester.tap(find.text(strings.undo));
      await tester.pumpAndSettle();

      expect(find.text(first.title.of('en')), findsOneWidget);
      expect(app.favouritesRepository.calls, isNot(contains('removeById:${first.id}')));
    });

    testWidgets('invites exploring when nothing is saved', (WidgetTester tester) async {
      final TestApp app = await openFavourites(
        tester,
        favourites: FakeFavouritesRepository()..items = <Favourite>[],
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.favouritesEmptyServices), findsOneWidget);
      await tapAndSettle(tester, find.text(strings.favouritesExplore));

      expect(location(app), AppRoutes.search);
    });

    testWidgets('leaves the Profile tab underneath', (WidgetTester tester) async {
      await openFavourites(tester);

      await tapAndSettle(tester, find.bySemanticsLabel(l10n(tester).backLabel));

      expect(find.byType(ProfileTabView), findsOneWidget);
    });
  });
}
