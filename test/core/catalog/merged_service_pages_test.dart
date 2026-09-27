import 'package:eventor/core/catalog/merged_service_pages.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

/// A card with only what the merge reads changed.
ServiceCard card(String id, {String price = '1000.00', String rating = '0.00', int bookings = 0}) {
  final Map<String, Object?> json =
      Map<String, Object?>.of(fixtureList('services_page.json').first)
        ..['id'] = id
        ..['basePrice'] = price
        ..['avgRating'] = rating
        ..['bookingsCount'] = bookings;
  return ServiceCard.fromJson(json);
}

/// One category's results on the server, already in the query's order,
/// served [pageSize] at a time. Records every page asked for.
class FakeCategoryServer {
  FakeCategoryServer(this.lists);

  final Map<String, List<ServiceCard>> lists;
  final List<String> asked = <String>[];
  String? failOn;

  Future<ApiPage<ServiceCard>> fetch(String categoryId, int page, int pageSize) async {
    asked.add('$categoryId:$page');
    if (failOn == '$categoryId:$page') {
      throw const NetworkFailure();
    }
    final List<ServiceCard> all = lists[categoryId]!;
    final int start = (page - 1) * pageSize;
    return ApiPage<ServiceCard>(
      items: all.skip(start).take(pageSize).toList(),
      page: page,
      totalPages: (all.length / pageSize).ceil(),
      total: all.length,
    );
  }
}

MergedServicePages merged(
  FakeCategoryServer server,
  ServiceOrder order, {
  int pageSize = 2,
}) =>
    MergedServicePages(
      categoryIds: server.lists.keys.toList(),
      order: order,
      pageSize: pageSize,
      fetch: server.fetch,
    );

List<String> ids(ApiPage<ServiceCard> page) =>
    page.items.map((ServiceCard c) => c.id).toList();

void main() {
  group('MergedServicePages', () {
    test('merges cheapest first across categories, page after page', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[
          card('v1', price: '1000.00'),
          card('v2', price: '4000.00'),
          card('v3', price: '9000.00'),
        ],
        'photo': <ServiceCard>[
          card('p1', price: '2000.00'),
          card('p2', price: '3000.00'),
          card('p3', price: '5000.00'),
        ],
      });
      final MergedServicePages pages = merged(server, ServiceOrder.priceAsc);

      final ApiPage<ServiceCard> first = await pages.page(1);
      final ApiPage<ServiceCard> second = await pages.page(2);
      final ApiPage<ServiceCard> third = await pages.page(3);

      expect(ids(first), <String>['v1', 'p1']);
      expect(ids(second), <String>['p2', 'v2']);
      expect(ids(third), <String>['p3', 'v3']);
      expect(third.hasMore, isFalse);
    });

    test('adds up the totals of every category', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1'), card('v2'), card('v3')],
        'photo': <ServiceCard>[card('p1')],
      });

      final ApiPage<ServiceCard> first = await merged(server, ServiceOrder.priceAsc).page(1);

      expect(first.total, 4);
      expect(first.totalPages, 2);
      expect(first.hasMore, isTrue);
    });

    test('puts the most expensive first for price high to low', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1', price: '9000.00'), card('v2', price: '1000.00')],
        'photo': <ServiceCard>[card('p1', price: '5000.00')],
      });

      final ApiPage<ServiceCard> page =
          await merged(server, ServiceOrder.priceDesc, pageSize: 3).page(1);

      expect(ids(page), <String>['v1', 'p1', 'v2']);
    });

    test('puts the best rated first', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1', rating: '4.20'), card('v2', rating: '3.00')],
        'photo': <ServiceCard>[card('p1', rating: '4.90'), card('p2', rating: '4.00')],
      });

      final ApiPage<ServiceCard> page =
          await merged(server, ServiceOrder.rating, pageSize: 4).page(1);

      expect(ids(page), <String>['p1', 'v1', 'p2', 'v2']);
    });

    test('puts the most booked first for popular', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1', bookings: 3)],
        'photo': <ServiceCard>[card('p1', bookings: 12), card('p2', bookings: 1)],
      });

      final ApiPage<ServiceCard> page =
          await merged(server, ServiceOrder.popular, pageSize: 3).page(1);

      expect(ids(page), <String>['p1', 'v1', 'p2']);
    });

    test('takes one from each in turn when the order has no key to compare',
        () async {
      // Relevance and newest: the cards carry no score or date.
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1'), card('v2'), card('v3')],
        'photo': <ServiceCard>[card('p1')],
      });

      final ApiPage<ServiceCard> page =
          await merged(server, ServiceOrder.relevance, pageSize: 4).page(1);

      expect(ids(page), <String>['v1', 'p1', 'v2', 'v3']);
    });

    test('never changes the server\'s order within one category', () async {
      // The server may break ties in ways the card cannot show.
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1', rating: '4.00'), card('v2', rating: '4.00')],
        'photo': <ServiceCard>[card('p1', rating: '4.00')],
      });

      final ApiPage<ServiceCard> page =
          await merged(server, ServiceOrder.rating, pageSize: 3).page(1);

      expect(ids(page).indexOf('v1'), lessThan(ids(page).indexOf('v2')));
    });

    test('asks for a category\'s next page only when it runs out', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[
          card('v1', price: '1000.00'),
          card('v2', price: '2000.00'),
          card('v3', price: '3000.00'),
        ],
        'photo': <ServiceCard>[card('p1', price: '9000.00'), card('p2', price: '9500.00')],
      });

      await merged(server, ServiceOrder.priceAsc).page(1);

      // v1 and v2 fill the page from venue's first page; photo is not paged on.
      expect(server.asked, <String>['venue:1', 'photo:1']);
    });

    test('gives the same page again when it is asked for twice', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1'), card('v2'), card('v3')],
        'photo': <ServiceCard>[card('p1'), card('p2')],
      });
      final MergedServicePages pages = merged(server, ServiceOrder.relevance);

      final List<String> once = ids(await pages.page(1));
      await pages.page(2);

      expect(ids(await pages.page(1)), once);
    });

    test('carries on where it stopped after a failed page', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[card('v1'), card('v2'), card('v3'), card('v4')],
        'photo': <ServiceCard>[card('p1')],
      })
        ..failOn = 'venue:2';
      final MergedServicePages pages = merged(server, ServiceOrder.relevance);
      final List<String> first = ids(await pages.page(1));

      await expectLater(pages.page(2), throwsA(isA<Failure>()));
      server.failOn = null;
      final List<String> second = ids(await pages.page(2));
      final List<String> third = ids(await pages.page(3));

      final List<String> all = <String>[...first, ...second, ...third];
      expect(all.toSet().length, all.length, reason: 'nothing twice');
      expect(all.toSet(), <String>{'v1', 'v2', 'v3', 'v4', 'p1'});
    });

    test('is empty when no category has anything', () async {
      final FakeCategoryServer server = FakeCategoryServer(<String, List<ServiceCard>>{
        'venue': <ServiceCard>[],
        'photo': <ServiceCard>[],
      });

      final ApiPage<ServiceCard> page = await merged(server, ServiceOrder.priceAsc).page(1);

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });
  });
}
