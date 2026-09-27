import 'package:dio/dio.dart';
import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_client.dart';
import 'package:eventor/core/session/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../network/scripted_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late ApiCatalogRepository catalog;

  /// Answers each path with its fixture.
  Future<ResponseBody> server(RequestOptions request) async {
    final String path = request.path;
    if (path == '/app/home') return jsonResponse(fixture('home.json'));
    if (path == '/app/categories') return jsonResponse(fixture('categories.json'));
    if (path == '/app/services') return jsonResponse(fixture('services_page.json'));
    if (path == '/app/packs') return jsonResponse(fixture('packs_page.json'));
    if (path.endsWith('/availability')) {
      return jsonResponse(fixture('availability.json'));
    }
    if (path.startsWith('/app/services/')) {
      return jsonResponse(fixture('service_detail.json'));
    }
    if (path.startsWith('/app/providers/')) {
      return jsonResponse(fixture('provider_detail.json'));
    }
    if (path.startsWith('/app/packs/')) {
      return jsonResponse(fixture('pack_detail.json'));
    }
    return errorResponse(404, 'NOT_FOUND');
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'eventor.access_token': 'access-1',
      'eventor.refresh_token': 'refresh-1',
    });
    final TokenStore tokens = TokenStore();
    await tokens.load();
    adapter = ScriptedAdapter(server);
    catalog = ApiCatalogRepository(scriptedClient(adapter, tokens));
  });

  RequestOptions lastRequest() => adapter.requests.last;

  group('ApiCatalogRepository', () {
    test('loads Home in one call', () async {
      final HomeFeed feed = await catalog.home();

      expect(lastRequest().path, '/app/home');
      expect(feed.fullName, 'Amina Benali');
    });

    test('sends the token with catalog calls, so hearts come back filled',
        () async {
      // The catalog is public, but without a token every isFavourite is false.
      await catalog.services(const ServiceQuery());

      expect(lastRequest().headers['Authorization'], 'Bearer access-1');
    });

    test('searches with the query and the page', () async {
      final ApiPage<ServiceCard> page = await catalog.services(
        const ServiceQuery(q: 'photo', wilayaCodes: <int>{16, 31}),
        page: 2,
      );

      expect(lastRequest().path, '/app/services');
      expect(lastRequest().uri.queryParametersAll, <String, List<String>>{
        'q': <String>['photo'],
        'wilaya': <String>['16', '31'],
        'page': <String>['2'],
        'limit': <String>['20'],
      });
      expect(page.items, hasLength(3));
    });

    test('asks for several categories one at a time, then merges them', () async {
      // The live API rejects a second categoryId with 400 IS_UUID.
      final ApiPage<ServiceCard> page = await catalog.services(
        const ServiceQuery(categoryIds: <String>{'cat-2', 'cat-1'}),
      );

      final List<List<String>?> sent = adapter.requests
          .where((RequestOptions r) => r.path == '/app/services')
          .map((RequestOptions r) => r.uri.queryParametersAll['categoryId'])
          .toList();
      expect(sent, unorderedEquals(<List<String>>[
        <String>['cat-1'],
        <String>['cat-2'],
      ]));
      // The fixture answers both with the same page: 3 rows, a total of 41.
      expect(page.total, 82);
      expect(page.items, hasLength(6));
      // Both lists are spent, so there is nothing more to load.
      expect(page.hasMore, isFalse);
    });

    test('sends a single category as it is', () async {
      await catalog.services(const ServiceQuery(categoryIds: <String>{'cat-1'}));

      expect(lastRequest().uri.queryParametersAll['categoryId'], <String>['cat-1']);
    });

    test('asks for a single row when only counting', () async {
      await catalog.services(const ServiceQuery(), limit: 1);

      expect(lastRequest().uri.queryParameters['limit'], '1');
    });

    test('opens a service by id', () async {
      final ServiceDetail service = await catalog.service('s-1');

      expect(lastRequest().path, '/app/services/s-1');
      expect(service.title.of('en'), isNotEmpty);
    });

    test('asks for one month of a service\'s calendar', () async {
      await catalog.serviceAvailability('s-1', DateTime(2026, 3, 20));

      expect(lastRequest().path, '/app/services/s-1/availability');
      expect(lastRequest().uri.queryParameters['month'], '2026-03');
    });

    test('opens a provider by id', () async {
      final ProviderDetail provider = await catalog.provider('p-1');

      expect(lastRequest().path, '/app/providers/p-1');
      expect(provider.businessName, isNotEmpty);
    });

    test('lists packs by event type and order', () async {
      await catalog.packs(eventType: EventType.wedding, order: PackOrder.priceAsc);

      expect(lastRequest().path, '/app/packs');
      expect(lastRequest().uri.queryParameters, <String, String>{
        'eventType': 'wedding',
        'order': 'price_asc',
        'page': '1',
        'limit': '20',
      });
    });

    test('leaves the default pack order out', () async {
      await catalog.packs();

      expect(lastRequest().uri.queryParameters.containsKey('order'), isFalse);
    });

    test('opens a pack and its calendar', () async {
      await catalog.pack('k-1');
      expect(lastRequest().path, '/app/packs/k-1');

      await catalog.packAvailability('k-1', DateTime(2026, 11));
      expect(lastRequest().path, '/app/packs/k-1/availability');
      expect(lastRequest().uri.queryParameters['month'], '2026-11');
    });

    test('loads the categories once per run', () async {
      await catalog.categories();
      await catalog.categories();

      expect(adapter.requestsTo('/app/categories'), hasLength(1));
    });

    test('tries the categories again after a failure', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(500, 'INTERNAL_ERROR');
      await expectLater(catalog.categories(), throwsA(isA<ApiFailure>()));

      adapter.respond = server;
      expect(await catalog.categories(), isNotEmpty);
    });

    test('passes a missing service on as its code', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(404, ApiErrorCode.serviceNotFound);

      await expectLater(
        catalog.service('gone'),
        throwsA(isA<ApiFailure>().having(
          (ApiFailure f) => f.code,
          'code',
          ApiErrorCode.serviceNotFound,
        )),
      );
    });
  });
}
