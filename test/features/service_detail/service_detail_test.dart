import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/routing/app_routes.dart';
import 'package:eventor/core/widgets/organisms/detail_states.dart';
import 'package:eventor/core/widgets/organisms/sticky_action_bar.dart';
import 'package:eventor/features/service_detail/view/service_detail_view.dart';
import 'package:eventor/features/service_detail/view_model/service_detail_view_model.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

/// The live service detail with [changes] applied.
ServiceDetail serviceWith(Map<String, Object?> changes) =>
    ServiceDetail.fromJson(<String, Object?>{
      ...fixtureData('service_detail.json'),
      ...changes,
    });

/// The same, from a provider who paused bookings.
ServiceDetail pausedService() {
  final Map<String, Object?> json = fixtureData('service_detail.json');
  return ServiceDetail.fromJson(<String, Object?>{
    ...json,
    'provider': <String, Object?>{
      ...json['provider']! as Map<String, Object?>,
      'acceptingBookings': false,
    },
  });
}

void main() {
  final DateTime today = DateTime(2026, 3, 3);

  group('ServiceDetailViewModel', () {
    late FakeCatalogRepository catalog;

    setUp(
      () =>
          catalog = FakeCatalogRepository()
            ..firstBookable = DateTime(2026, 3, 5),
    );

    Future<ServiceDetailViewModel> build() async {
      final ServiceDetailViewModel viewModel = ServiceDetailViewModel(
        id: 's-1',
        catalog: catalog,
        messaging: FakeMessagingRepository(),
        today: () => today,
      );
      addTearDown(viewModel.dispose);
      await flushAsync();
      await flushAsync();
      return viewModel;
    }

    test('loads the service, then this month', () async {
      final ServiceDetailViewModel viewModel = await build();

      expect(viewModel.service, isNotNull);
      expect(viewModel.visibleMonth, DateTime(2026, 3));
      expect(viewModel.availability, isNotNull);
    });

    test('knows a removed service apart from an error', () async {
      catalog.serviceError = apiFailure(
        ApiErrorCode.serviceNotFound,
        statusCode: 404,
      );

      final ServiceDetailViewModel viewModel = await build();

      expect(viewModel.isGone, isTrue);
      expect(viewModel.hasError, isFalse);
    });

    test('reports any other failure as an error', () async {
      catalog.serviceError = const NetworkFailure();

      final ServiceDetailViewModel viewModel = await build();

      expect(viewModel.isGone, isFalse);
      expect(viewModel.hasError, isTrue);
    });

    test('fetches each month once', () async {
      final ServiceDetailViewModel viewModel = await build();

      await viewModel.showMonth(DateTime(2026, 4));
      await viewModel.showMonth(DateTime(2026, 3));
      await viewModel.showMonth(DateTime(2026, 4));

      expect(catalog.availabilityMonths, <DateTime>[
        DateTime(2026, 3),
        DateTime(2026, 4),
      ]);
    });

    test('cannot page before this month', () async {
      final ServiceDetailViewModel viewModel = await build();

      await viewModel.showMonth(DateTime(2026, 2));

      expect(viewModel.visibleMonth, DateTime(2026, 3));
    });

    test('picks an available day only', () async {
      final ServiceDetailViewModel viewModel = await build();

      viewModel.selectDate(DateTime(2026, 3, 10)); // busy
      viewModel.selectDate(DateTime(2026, 3, 20)); // blocked
      viewModel.selectDate(DateTime(2026, 3, 4)); // too soon
      expect(viewModel.selectedDate, isNull);

      viewModel.selectDate(DateTime(2026, 3, 14));
      expect(viewModel.selectedDate, DateTime(2026, 3, 14));
    });

    test('lets nothing be picked when the provider paused bookings', () async {
      catalog.serviceDetail = pausedService();
      final ServiceDetailViewModel viewModel = await build();

      viewModel.selectDate(DateTime(2026, 3, 14));

      expect(viewModel.canBook, isFalse);
      expect(viewModel.selectedDate, isNull);
    });

    test('offers a retry when a month fails', () async {
      final ServiceDetailViewModel viewModel = await build();
      catalog.availabilityError = const NetworkFailure();

      await viewModel.showMonth(DateTime(2026, 4));
      expect(viewModel.monthFailed, isTrue);

      catalog.availabilityError = null;
      await viewModel.retryMonth();
      expect(viewModel.monthFailed, isFalse);
      expect(viewModel.availability, isNotNull);
    });
  });

  group('ServiceDetailView', () {
    Future<TestApp> openService(
      WidgetTester tester,
      FakeCatalogRepository catalog,
    ) async {
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        catalog: catalog,
      );
      await startApp(tester, app);
      app.services.router.push(AppRoutes.serviceFor('s-1'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceDetailView), findsOneWidget);
      return app;
    }

    String location(TestApp app) =>
        app.services.router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('shows the service with the booking bar', (
      WidgetTester tester,
    ) async {
      await openService(tester, FakeCatalogRepository());
      final AppLocalizations strings = l10n(tester);

      expect(find.text('Wedding photo & video coverage'), findsOneWidget);
      expect(button(strings.requestBooking), findsOneWidget);
      expect(find.text(strings.notAcceptingTitle), findsNothing);
    });

    testWidgets('quotes the provider\'s own policy, and none when unset', (
      WidgetTester tester,
    ) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository()
        ..serviceDetail = serviceWith(<String, Object?>{
          'cancellationPolicy': null,
          'cancellationPolicyEn': null,
          'cancellationPolicyAr': null,
        });
      await openService(tester, catalog);

      expect(find.text(l10n(tester).serviceGoodToKnow), findsNothing);
    });

    testWidgets('says "On quote" for a quote-only service', (
      WidgetTester tester,
    ) async {
      await openService(
        tester,
        FakeCatalogRepository()
          ..serviceDetail = serviceWith(<String, Object?>{
            'priceType': 'on_quote',
          }),
      );

      expect(find.text(l10n(tester).priceOnQuote), findsOneWidget);
    });

    testWidgets('says "New" for an unrated service', (
      WidgetTester tester,
    ) async {
      await openService(
        tester,
        FakeCatalogRepository()
          ..serviceDetail = serviceWith(<String, Object?>{
            'avgRating': '0.00',
            'ratingCount': 0,
          }),
      );

      expect(find.text(l10n(tester).ratingNew), findsOneWidget);
      expect(find.text(l10n(tester).serviceNoReviews), findsOneWidget);
    });

    testWidgets('swaps the booking bar when bookings are paused', (
      WidgetTester tester,
    ) async {
      await openService(
        tester,
        FakeCatalogRepository()..serviceDetail = pausedService(),
      );
      final AppLocalizations strings = l10n(tester);

      expect(find.text(strings.notAcceptingTitle), findsOneWidget);
      expect(find.text(strings.notAcceptingBody), findsOneWidget);
      expect(button(strings.requestBooking), findsNothing);
      expect(button(strings.sendMessage), findsOneWidget);
    });

    testWidgets('requesting a booking is coming soon', (
      WidgetTester tester,
    ) async {
      await openService(tester, FakeCatalogRepository());

      await tester.tap(button(l10n(tester).requestBooking));
      await tester.pump();

      expect(find.text(l10n(tester).comingSoon), findsOneWidget);
    });

    testWidgets('opens the provider', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository();
      final TestApp app = await openService(tester, catalog);
      final ProviderSummary provider = catalog.serviceDetail.provider;

      await tester.scrollUntilVisible(find.text(provider.businessName), 200);
      await tapAndSettle(tester, find.text(provider.businessName));

      expect(location(app), AppRoutes.providerFor(provider.id));
    });

    testWidgets('says a removed service is gone', (WidgetTester tester) async {
      final FakeCatalogRepository catalog = FakeCatalogRepository()
        ..serviceError = apiFailure(
          ApiErrorCode.serviceNotFound,
          statusCode: 404,
        );
      final TestApp app = await buildTestApp(
        hasSeenOnboarding: true,
        auth: FakeAuthRepository()..restoredUser = testUser(),
        catalog: catalog,
      );
      await startApp(tester, app);
      app.services.router.push(AppRoutes.serviceFor('gone'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailGoneView), findsOneWidget);
      expect(find.text(l10n(tester).detailGoneTitle), findsOneWidget);
    });

    testWidgets('keeps the sticky bar in both languages', (
      WidgetTester tester,
    ) async {
      await openService(tester, FakeCatalogRepository());

      expect(find.byType(StickyActionBar), findsOneWidget);
    });
  });
}
