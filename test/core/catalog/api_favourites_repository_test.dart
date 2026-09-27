import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eventor/core/catalog/favourites_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
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
  late ApiFavouritesRepository favourites;

  /// A favourites API: POST answers with a row, DELETE with 204.
  Future<ResponseBody> server(RequestOptions request) async {
    if (request.method == 'GET') {
      return jsonResponse(fixture('favourites_page.json'));
    }
    if (request.method == 'POST') {
      return jsonResponse(
        <String, Object?>{'data': fixtureList('favourites_page.json').first},
        status: 201,
      );
    }
    return ResponseBody.fromString('', 204);
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'eventor.access_token': 'access-1',
      'eventor.refresh_token': 'refresh-1',
    });
    final TokenStore tokens = TokenStore();
    await tokens.load();
    adapter = ScriptedAdapter(server);
    favourites = ApiFavouritesRepository(scriptedClient(adapter, tokens));
  });

  Map<String, Object?> bodyOf(RequestOptions request) {
    final Object? data = request.data;
    return (data is String ? jsonDecode(data) : data)! as Map<String, Object?>;
  }

  group('ApiFavouritesRepository', () {
    test('lists one kind at a time, filtered by category', () async {
      final ApiPage<Favourite> page = await favourites.list(
        kind: FavouriteKind.service,
        categoryId: 'cat-1',
        page: 2,
      );

      expect(adapter.requests.single.path, '/app/me/favourites');
      expect(adapter.requests.single.uri.queryParameters, <String, String>{
        'kind': 'service',
        'categoryId': 'cat-1',
        'page': '2',
        'limit': '20',
      });
      expect(page.items, hasLength(2));
    });

    test('saves a service with exactly one id', () async {
      await favourites.add(const FavouriteTarget.service('s-1'));

      expect(bodyOf(adapter.requests.single), <String, Object?>{
        'serviceId': 's-1',
      });
    });

    test('saves a pack with exactly one id', () async {
      await favourites.add(const FavouriteTarget.pack('k-1'));

      expect(bodyOf(adapter.requests.single), <String, Object?>{
        'packId': 'k-1',
      });
    });

    test('removes a target by asking for its row, then deleting it', () async {
      // Cards carry no favourite id; saving again is idempotent and returns
      // the existing row, whose id the DELETE needs.
      await favourites.remove(const FavouriteTarget.service('s-1'));

      expect(
        adapter.requests.map((RequestOptions r) => r.method),
        <String>['POST', 'DELETE'],
      );
      expect(adapter.requests.last.path, '/app/me/favourites/fav-1');
    });

    test('removes a row by its id', () async {
      await favourites.removeById('fav-9');

      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/app/me/favourites/fav-9');
    });

    test('treats a row that is already gone as removed', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(404, ApiErrorCode.favouriteNotFound);

      await expectLater(favourites.removeById('fav-9'), completes);
    });

    test('passes other failures on', () async {
      adapter.respond = (RequestOptions request) async =>
          errorResponse(403, ApiErrorCode.forbiddenRole);

      await expectLater(
        favourites.add(const FavouriteTarget.service('s-1')),
        throwsA(isA<ApiFailure>()),
      );
    });
  });
}
