import 'package:eventor/core/catalog/service_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceQuery.toQuery', () {
    test('sends nothing for the defaults', () {
      expect(const ServiceQuery().toQuery(), isEmpty);
    });

    test('sends each filter under the API\'s own name', () {
      final ServiceQuery query = ServiceQuery(
        q: 'photo',
        categoryIds: const <String>{'cat-1'},
        wilayaCodes: const <int>{31, 16},
        priceMin: 30000,
        priceMax: 250000,
        minRating: 4.5,
        eventDate: DateTime(2026, 3, 14),
        favouritesOnly: true,
        order: ServiceOrder.priceAsc,
      );

      expect(query.toQuery(), <String, Object?>{
        'q': 'photo',
        'categoryId': 'cat-1',
        // Sorted, so the same filters always make the same request.
        'wilaya': <int>[16, 31],
        'priceMin': 30000,
        'priceMax': 250000,
        'rating': 4.5,
        'eventDate': '2026-03-14',
        'favourite': true,
        'order': 'price_asc',
      });
    });

    test('sends several categories as one repeated parameter, sorted', () {
      expect(
        const ServiceQuery(categoryIds: <String>{'cat-2', 'cat-1'}).toQuery(),
        <String, Object?>{'categoryId': <String>['cat-1', 'cat-2']},
      );
    });

    test('counts several categories as one filter', () {
      expect(
        const ServiceQuery(categoryIds: <String>{'cat-1', 'cat-2', 'cat-3'}).filterCount,
        1,
      );
    });

    test('leaves out a blank search', () {
      expect(const ServiceQuery(q: '   ').toQuery(), isEmpty);
    });

    test('treats the top of the budget range as no ceiling', () {
      // "500 000+" means anything above too.
      expect(
        const ServiceQuery(priceMax: ServiceQuery.priceCeiling).toQuery(),
        isEmpty,
      );
    });

    test('leaves out a zero floor', () {
      expect(const ServiceQuery(priceMin: 0).toQuery(), isEmpty);
    });

    test('names every order the API accepts', () {
      expect(
        ServiceOrder.values.map((ServiceOrder order) => order.apiValue),
        <String>['relevance', 'price_asc', 'price_desc', 'rating', 'popular', 'newest'],
      );
    });
  });

  group('ServiceQuery.filterCount', () {
    test('counts neither the search nor the order', () {
      expect(
        const ServiceQuery(q: 'photo', order: ServiceOrder.rating).filterCount,
        0,
      );
    });

    test('counts each kind of filter once', () {
      final ServiceQuery query = ServiceQuery(
        categoryIds: const <String>{'cat-1'},
        wilayaCodes: const <int>{16, 31, 9},
        priceMin: 10000,
        priceMax: 50000,
        minRating: 4,
        eventDate: DateTime(2026, 3, 14),
        favouritesOnly: true,
      );

      // Category, wilayas, budget, rating, date, favourites.
      expect(query.filterCount, 6);
    });
  });

  group('ServiceQuery editing', () {
    test('clears the filters but keeps the search and the order', () {
      final ServiceQuery query = ServiceQuery(
        q: 'photo',
        categoryIds: const <String>{'cat-1'},
        wilayaCodes: const <int>{16},
        order: ServiceOrder.rating,
        eventDate: DateTime(2026, 3, 14),
      ).clearFilters();

      expect(query.q, 'photo');
      expect(query.order, ServiceOrder.rating);
      expect(query.filterCount, 0);
    });

    test('can clear a single optional value', () {
      const ServiceQuery query = ServiceQuery(minRating: 4);

      expect(query.copyWith(minRating: () => null).minRating, isNull);
      expect(query.copyWith().minRating, 4);
    });

    test('keeps its categories unless given new ones', () {
      const ServiceQuery query = ServiceQuery(categoryIds: <String>{'cat-1', 'cat-2'});

      expect(query.copyWith().categoryIds, <String>{'cat-1', 'cat-2'});
      expect(query.copyWith(categoryIds: const <String>{}).categoryIds, isEmpty);
    });

    test('is equal whatever order its categories were picked in', () {
      expect(
        const ServiceQuery(categoryIds: <String>{'cat-1', 'cat-2'}),
        const ServiceQuery(categoryIds: <String>{'cat-2', 'cat-1'}),
      );
    });

    test('is equal to another with the same filters', () {
      expect(
        const ServiceQuery(q: 'a', wilayaCodes: <int>{16, 31}),
        const ServiceQuery(q: 'a', wilayaCodes: <int>{31, 16}),
      );
    });
  });

  group('ServiceQuery route parameters', () {
    test('survive the round trip', () {
      final ServiceQuery query = ServiceQuery(
        q: 'photo',
        categoryIds: const <String>{'cat-1'},
        wilayaCodes: const <int>{16, 31},
        priceMin: 30000,
        priceMax: 250000,
        minRating: 4.5,
        eventDate: DateTime(2026, 3, 14),
        favouritesOnly: true,
        order: ServiceOrder.newest,
      );

      final Uri uri = Uri(path: '/search/results', queryParameters: query.toRouteParams());

      expect(ServiceQuery.fromRouteParams(uri.queryParametersAll), query);
    });

    test('carry several categories', () {
      const ServiceQuery query = ServiceQuery(categoryIds: <String>{'cat-2', 'cat-1'});

      final Uri uri = Uri(path: '/search/results', queryParameters: query.toRouteParams());

      expect(uri.queryParametersAll['category'], <String>['cat-1', 'cat-2']);
      expect(ServiceQuery.fromRouteParams(uri.queryParametersAll), query);
    });

    test('ignore what they do not understand', () {
      final ServiceQuery query = ServiceQuery.fromRouteParams(
        const <String, List<String>>{
          'wilaya': <String>['16', 'x'],
          'rating': <String>['lots'],
          'order': <String>['sideways'],
        },
      );

      expect(query.wilayaCodes, <int>{16});
      expect(query.minRating, isNull);
      expect(query.order, ServiceOrder.relevance);
    });
  });
}
