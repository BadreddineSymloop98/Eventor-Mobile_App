import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/reference/reference_repository.dart';
import 'package:eventor/features/filters/view/filters_drawer.dart';
import 'package:eventor/features/filters/view/wilaya_drill_in.dart';
import 'package:eventor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../feature_test_helpers.dart';

void main() {
  /// A button that opens the drawer and keeps what it returns.
  Future<List<ServiceQuery?>> pumpOpener(WidgetTester tester) async {
    final List<ServiceQuery?> results = <ServiceQuery?>[];
    await pumpAppWidget(
      tester,
      MultiProvider(
        providers: <Provider<Object>>[
          Provider<CatalogRepository>.value(value: FakeCatalogRepository()),
          Provider<ReferenceRepository>.value(value: FakeReferenceRepository()),
        ],
        child: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => results.add(
              await showFiltersDrawer(
                context,
                initial: const ServiceQuery(q: 'photo'),
                homeWilaya: 16,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tapAndSettle(tester, find.text('open'));
    return results;
  }

  group('Filters drawer', () {
    testWidgets('returns the query with the filters chosen', (WidgetTester tester) async {
      final List<ServiceQuery?> results = await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.sortPriceLow));
      await tapAndSettle(tester, find.text('4.5+'));
      await tester.tap(find.text(strings.filtersShowCount(3)));
      await tester.pumpAndSettle();

      final ServiceQuery query = results.single!;
      expect(query.q, 'photo');
      expect(query.order, ServiceOrder.priceAsc);
      expect(query.minRating, 4.5);
    });

    testWidgets('returns nothing when closed', (WidgetTester tester) async {
      final List<ServiceQuery?> results = await pumpOpener(tester);

      await tapAndSettle(tester, find.bySemanticsLabel(l10n(tester).filtersClose));

      expect(results.single, isNull);
    });

    testWidgets('drills into every wilaya and back, keeping the choice',
        (WidgetTester tester) async {
      final List<ServiceQuery?> results = await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.filtersAllWilayas));
      expect(find.byType(WilayaDrillIn), findsOneWidget);

      await tapAndSettle(tester, find.text('Blida'));
      await tapAndSettle(tester, find.text(strings.wilayaDoneCount(1)));
      expect(find.byType(WilayaDrillIn), findsNothing);

      await tester.tap(find.text(strings.filtersShowCount(3)));
      await tester.pumpAndSettle();
      expect(results.single!.wilayaCodes, <int>{9});
    });

    testWidgets('leaves the wilayas alone when the drill-in is backed out of',
        (WidgetTester tester) async {
      final List<ServiceQuery?> results = await pumpOpener(tester);
      final AppLocalizations strings = l10n(tester);

      await tapAndSettle(tester, find.text(strings.filtersAllWilayas));
      await tapAndSettle(tester, find.text('Blida'));
      await tapAndSettle(tester, find.bySemanticsLabel(strings.backLabel));

      await tester.tap(find.text(strings.filtersShowCount(3)));
      await tester.pumpAndSettle();
      expect(results.single!.wilayaCodes, isEmpty);
    });
  });
}
