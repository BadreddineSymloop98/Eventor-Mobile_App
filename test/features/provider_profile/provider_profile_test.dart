import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/organisms/detail_states.dart';
import 'package:eventor/features/provider_profile/view/provider_profile_view.dart';
import 'package:eventor/features/provider_profile/view_model/provider_profile_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

ProviderDetail providerWith(Map<String, Object?> changes) =>
    ProviderDetail.fromJson(<String, Object?>{
      ...fixtureData('provider_detail.json'),
      ...changes,
    });

void main() {
  group('ProviderProfileViewModel', () {
    test('loads the provider', () async {
      final ProviderProfileViewModel viewModel =
          ProviderProfileViewModel(id: 'p-1', catalog: FakeCatalogRepository());
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.provider, isNotNull);
    });

    test('knows a removed provider apart from an error', () async {
      final ProviderProfileViewModel viewModel = ProviderProfileViewModel(
        id: 'gone',
        catalog: FakeCatalogRepository()
          ..providerError = apiFailure(ApiErrorCode.providerNotFound, statusCode: 404),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.isGone, isTrue);
      expect(viewModel.hasError, isFalse);
    });

    test('shows only the checks that passed', () async {
      final ProviderProfileViewModel viewModel = ProviderProfileViewModel(
        id: 'p-1',
        catalog: FakeCatalogRepository()
          ..providerDetail = providerWith(<String, Object?>{
            'checks': <Object?>[
              <String, Object?>{'code': 'identity', 'title': 'Identity', 'detail': '', 'passed': true},
              <String, Object?>{'code': 'reply_time', 'title': 'Reply', 'detail': '', 'passed': false},
            ],
          }),
      );
      addTearDown(viewModel.dispose);
      await flushAsync();

      expect(viewModel.passedChecks.map((ProviderCheck c) => c.code), <String>['identity']);
    });
  });

  group('ProviderProfileView', () {
    Future<TestApp> openProfile(WidgetTester tester, FakeCatalogRepository catalog) async {
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        catalog: catalog,
      );
      await startApp(tester, app);
      app.services.router.push(AppRoutes.providerFor('p-1'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderProfileView), findsOneWidget);
      return app;
    }

    String location(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('offers a message, never a booking button', (WidgetTester tester) async {
      await openProfile(tester, FakeCatalogRepository());
      final AppLocalizations strings = l10n(tester);

      expect(button(strings.sendMessage), findsOneWidget);
      expect(button(strings.requestBooking), findsNothing);
    });

    testWidgets('shows the "not taking new bookings" state (13)', (WidgetTester tester) async {
      await openProfile(
        tester,
        FakeCatalogRepository()
          ..providerDetail = providerWith(<String, Object?>{'acceptingBookings': false}),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.notAcceptingTitle), findsOneWidget);
      expect(find.text(strings.notAcceptingBody), findsOneWidget);
      expect(button(strings.sendMessage), findsOneWidget);
    });

    testWidgets('says how fast they reply only when the API knows', (WidgetTester tester) async {
      await openProfile(
        tester,
        FakeCatalogRepository()
          ..providerDetail = providerWith(<String, Object?>{'replyTime': '2 h'}),
      );

      expect(find.text(l10n(tester).repliesIn('2 h')), findsOneWidget);
    });

    testWidgets('hides the years when there are none', (WidgetTester tester) async {
      await openProfile(
        tester,
        FakeCatalogRepository()..providerDetail = providerWith(<String, Object?>{'yearsActive': null}),
      );

      expect(find.textContaining('in business'), findsNothing);
    });

    testWidgets('offers "See all" only when some services are not listed',
        (WidgetTester tester) async {
      final ProviderDetail base = FakeCatalogRepository().providerDetail;
      await openProfile(
        tester,
        FakeCatalogRepository()
          ..providerDetail = providerWith(<String, Object?>{
            'servicesCount': base.services.length + 2,
          }),
      );

      expect(find.text(l10n(tester).seeAllCount(base.services.length + 2)), findsOneWidget);
    });

    testWidgets('opens one of their services', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final TestApp app = await openProfile(tester, catalog);
      final ServiceCard service = catalog.providerDetail.services.first;

      await tester.scrollUntilVisible(find.text(service.title.of('en')), 200);
      await tapAndSettle(tester, find.text(service.title.of('en')));

      expect(location(app), AppRoutes.serviceFor(service.id));
    });

    testWidgets('says a removed provider is gone', (WidgetTester tester) async {
      await openProfile(
        tester,
        FakeCatalogRepository()
          ..providerError = apiFailure(ApiErrorCode.providerNotFound, statusCode: 404),
      );

      expect(find.byType(DetailGoneView), findsOneWidget);
    });
  });
}
