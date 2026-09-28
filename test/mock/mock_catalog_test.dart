import 'package:eventor/core/catalog/catalog_repository.dart';
import 'package:eventor/core/catalog/favourites_repository.dart';
import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:eventor/core/catalog/service_query.dart';
import 'package:eventor/core/errors/failure.dart';
import 'package:eventor/core/network/api_page.dart';
import 'package:eventor/mock/mock_backend.dart';
import 'package:eventor/mock/mock_catalog.dart';
import 'package:eventor/mock/mock_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expects [call] to fail with the API [code].
Future<void> expectCode(Future<Object?> call, String code) async {
  await expectLater(
    call,
    throwsA(isA<ApiFailure>().having((ApiFailure f) => f.code, 'code', code)),
  );
}

void main() {
  // A fixed "today", so calendars and relative dates are stable.
  final DateTime today = DateTime(2026, 9, 24, 10);

  late MockBackend backend;
  late MockAuthRepository auth;
  late MockCatalogRepository catalog;
  late MockFavouritesRepository favourites;

  Future<void> start() async {
    backend = await MockBackend.load(
      prefs: await SharedPreferences.getInstance(),
      latency: Duration.zero,
      now: () => today,
    );
    auth = MockAuthRepository(backend);
    catalog = MockCatalogRepository(backend, languageCode: () => 'en');
    favourites = MockFavouritesRepository(backend);
  }

  Future<void> signInAsClient() => auth.login(
        email: 'client@eventor.test',
        password: MockBackend.seedPassword,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await start();
    await signInAsClient();
  });

  /// Every service, all pages.
  Future<List<ServiceCard>> all(ServiceQuery query) async {
    final List<ServiceCard> items = <ServiceCard>[];
    int page = 1;
    ApiPage<ServiceCard> result;
    do {
      result = await catalog.services(query, page: page++);
      items.addAll(result.items);
    } while (result.hasMore);
    return items;
  }

  int cents(String amount) {
    final List<String> parts = amount.split('.');
    return int.parse(parts.first) * 100 +
        (parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }

  group('MockCatalogRepository services', () {
    test('pages the whole catalog, 20 at a time', () async {
      final ApiPage<ServiceCard> first = await catalog.services(const ServiceQuery());

      expect(first.items, hasLength(20));
      expect(first.total, 49);
      expect(first.totalPages, 3);
      expect(first.hasMore, isTrue);
    });

    test('searches titles in both languages and provider names', () async {
      expect(await all(const ServiceQuery(q: 'photo')), isNotEmpty);
      // Kinder than live, which does not index Arabic titles yet.
      expect(await all(const ServiceQuery(q: 'تصوير')), isNotEmpty);
      expect(
        (await all(const ServiceQuery(q: 'lumière')))
            .every((ServiceCard s) => s.provider.businessName == 'Studio Lumière' ||
                s.title.contains('lumière')),
        isTrue,
      );
    });

    test('filters by category', () async {
      final List<ServiceCard> photography = await all(
        const ServiceQuery(categoryIds: <String>{'7d3855dd-4bd3-430a-9ffc-09d4f269eb4a'}),
      );

      expect(photography, isNotEmpty);
      expect(
        photography.every((ServiceCard s) => s.category?.slug == 'photographie'),
        isTrue,
      );
    });

    test('keeps services in any of several categories', () async {
      final List<ServiceCard> found = await all(
        const ServiceQuery(categoryIds: <String>{
          '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
          'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6',
        }),
      );

      expect(
        found.map((ServiceCard s) => s.category?.slug).toSet(),
        <String>{'photographie', 'salles-des-fetes'},
      );
    });

    test('keeps services covering any of the wilayas', () async {
      final List<ServiceCard> found =
          await all(const ServiceQuery(wilayaCodes: <int>{31, 25}));

      expect(found, isNotEmpty);
      expect(
        found.every((ServiceCard s) =>
            s.wilayas.any((Wilaya w) => w.code == 31 || w.code == 25)),
        isTrue,
      );
    });

    test('filters by budget and minimum rating', () async {
      final List<ServiceCard> found = await all(
        const ServiceQuery(priceMin: 20000, priceMax: 100000, minRating: 4.5),
      );

      expect(found, isNotEmpty);
      for (final ServiceCard s in found) {
        expect(cents(s.basePrice), inInclusiveRange(2000000, 10000000));
        expect(double.parse(s.avgRating), greaterThanOrEqualTo(4.5));
      }
    });

    test('sorts by price, both ways', () async {
      final List<int> up = (await all(const ServiceQuery(order: ServiceOrder.priceAsc)))
          .map((ServiceCard s) => cents(s.basePrice))
          .toList();
      final List<int> down = (await all(const ServiceQuery(order: ServiceOrder.priceDesc)))
          .map((ServiceCard s) => cents(s.basePrice))
          .toList();

      expect(up, List<int>.of(up)..sort());
      expect(down, List<int>.of(up).reversed.toList());
    });

    test('sorts the newest first', () async {
      final ApiPage<ServiceCard> page =
          await catalog.services(const ServiceQuery(order: ServiceOrder.newest));

      expect(page.items.first.id, 'mock-lumiere-8');
    });

    test('drops services not free on the event date', () async {
      final DateTime date = DateTime(2026, 10, 20);
      final List<ServiceCard> free = await all(ServiceQuery(eventDate: date));

      for (final ServiceCard s in free) {
        final Availability month = await catalog.serviceAvailability(s.id, date);
        expect(month.stateOf(date), DayState.available, reason: s.id);
      }
      expect(free.length, lessThan(49));
    });

    test('shows a paused provider\'s services, flagged', () async {
      final List<ServiceCard> paused = (await all(const ServiceQuery()))
          .where((ServiceCard s) => s.provider.businessName == 'Salle Les Oliviers')
          .toList();

      expect(paused, isNotEmpty);
      expect(paused.every((ServiceCard s) => !s.provider.acceptingBookings), isTrue);
    });
  });

  group('MockCatalogRepository details', () {
    test('opens a service with everything screen 12 shows', () async {
      final ServiceCard card = (await catalog.services(const ServiceQuery())).items.first;
      final ServiceDetail detail = await catalog.service(card.id);

      expect(detail.title.of('en'), card.title.of('en'));
      expect(detail.photos, isNotEmpty);
      expect(detail.photos.first.mediumUrl, startsWith('asset:'));
      expect(detail.facts, isNotEmpty);
      expect(detail.ratingBreakdown, hasLength(5));
    });

    test('has one service with no photos at all', () async {
      final ServiceDetail drone = await catalog.service('mock-lumiere-6');

      expect(drone.photos, isEmpty);
      expect(drone.coverUrl, isNull);
    });

    test('answers SERVICE_NOT_FOUND for an unknown id', () async {
      await expectCode(catalog.service('nope'), ApiErrorCode.serviceNotFound);
    });

    test('lists ten of Studio Lumière\'s twelve services', () async {
      final ServiceDetail any = await catalog.service('mock-lumiere-1');
      final ProviderDetail lumiere = await catalog.provider(any.provider.id);

      expect(lumiere.servicesCount, 12);
      expect(lumiere.services, hasLength(10));
      expect(lumiere.hasMoreServices, isTrue);
      expect(lumiere.replyTime, '2 h');
    });

    test('answers PROVIDER_NOT_FOUND for an unknown id', () async {
      await expectCode(catalog.provider('nope'), ApiErrorCode.providerNotFound);
    });

    test('blocks every day before tomorrow', () async {
      final ServiceCard card = (await catalog.services(const ServiceQuery())).items.first;
      final Availability month = await catalog.serviceAvailability(card.id, today);

      expect(month.stateOf(DateTime(2026, 9, 20)), DayState.blocked);
      expect(month.stateOf(DateTime(2026, 9, 24)), DayState.blocked);
      expect(month.firstBookableDate, DateTime(2026, 9, 25));
    });
  });

  group('MockCatalogRepository packs', () {
    test('lists best savings first by default', () async {
      final List<num> savings = (await catalog.packs()).items
          .map((PackCard p) => p.savingsPercent)
          .toList();

      expect(savings, List<num>.of(savings)..sort((num a, num b) => b.compareTo(a)));
    });

    test('filters by event type', () async {
      final ApiPage<PackCard> weddings =
          await catalog.packs(eventType: EventType.wedding);

      expect(weddings.items, isNotEmpty);
      expect(weddings.items.every((PackCard p) => p.eventType == EventType.wedding), isTrue);
    });

    test('opens a pack whose items add up', () async {
      final PackCard card = (await catalog.packs()).items.first;
      final PackDetail pack = await catalog.pack(card.id);

      expect(pack.items.length, inInclusiveRange(2, 6));
      expect(
        pack.items.fold<int>(0, (int sum, PackItem item) => sum + cents(item.price)),
        cents(pack.sumOfItems),
      );
      expect(cents(pack.price) + cents(pack.savings), cents(pack.sumOfItems));
    });

    test('only offers a day when every item is free', () async {
      final PackDetail pack = await catalog.pack((await catalog.packs()).items.first.id);
      final DateTime month = DateTime(2026, 11);
      final Availability packMonth = await catalog.packAvailability(pack.id, month);

      for (int day = 1; day <= 30; day++) {
        final DateTime date = DateTime(2026, 11, day);
        if (packMonth.stateOf(date) != DayState.available) continue;
        for (final PackItem item in pack.items) {
          final Availability itemMonth =
              await catalog.serviceAvailability(item.serviceId, month);
          expect(itemMonth.stateOf(date), DayState.available);
        }
      }
    });

    test('answers PACK_NOT_FOUND for an unknown id', () async {
      await expectCode(catalog.pack('nope'), ApiErrorCode.packNotFound);
    });
  });

  group('MockCatalogRepository home', () {
    test('is built around the client\'s city', () async {
      final HomeFeed feed = await catalog.home();

      expect(feed.fullName, 'Amina Benali');
      expect(feed.wilaya?.code, 16);
      expect(feed.nearbyServices, isNotEmpty);
      expect(
        feed.nearbyServices.every((ServiceCard s) => s.wilayas.any((Wilaya w) => w.code == 16)),
        isTrue,
      );
      expect(feed.budget.exists, isTrue);
      expect(feed.upcomingBookings, hasLength(2));
    });

    test('follows a new city', () async {
      await auth.updateWilaya(31);

      final HomeFeed feed = await catalog.home();

      expect(feed.wilaya?.code, 31);
      expect(
        feed.nearbyServices.every((ServiceCard s) => s.wilayas.any((Wilaya w) => w.code == 31)),
        isTrue,
      );
    });

    test('needs a session', () async {
      await auth.logout();

      await expectLater(catalog.home(), throwsA(isA<SessionExpiredFailure>()));
    });

    test('lists only the listed categories, with their counts', () async {
      final List<CategoryWithCount> categories = await catalog.categories();

      expect(categories.map((CategoryWithCount c) => c.slug), isNot(contains('transport')));
      expect(
        categories.firstWhere((CategoryWithCount c) => c.slug == 'photographie').servicesCount,
        greaterThanOrEqualTo(12),
      );
    });
  });

  group('MockFavouritesRepository', () {
    test('starts the seeded client with five, one no longer listed', () async {
      final ApiPage<Favourite> page = await favourites.list();

      expect(page.items, hasLength(5));
      expect(page.items.where((Favourite f) => !f.available), hasLength(1));
      expect(page.items.where((Favourite f) => f.kind == FavouriteKind.pack), hasLength(1));
    });

    test('lists one kind at a time', () async {
      final ApiPage<Favourite> packs = await favourites.list(kind: FavouriteKind.pack);

      expect(packs.items.single.kind, FavouriteKind.pack);
    });

    test('drops packs when filtering by category', () async {
      final ApiPage<Favourite> page = await favourites.list(
        categoryId: '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
      );

      expect(page.items.every((Favourite f) => f.kind == FavouriteKind.service), isTrue);
    });

    test('saves once, however often it is asked', () async {
      final Favourite first = await favourites.add(const FavouriteTarget.service('mock-lumiere-3'));
      final Favourite again = await favourites.add(const FavouriteTarget.service('mock-lumiere-3'));

      expect(again.id, first.id);
      expect((await favourites.list()).items, hasLength(6));
    });

    test('marks saved services on the cards', () async {
      await favourites.add(const FavouriteTarget.service('mock-lumiere-3'));

      final ServiceDetail detail = await catalog.service('mock-lumiere-3');

      expect(detail.isFavourite, isTrue);
    });

    test('removes by target and by row', () async {
      await favourites.remove(const FavouriteTarget.pack('nothing-saved'))
          .catchError((Object _) {});
      final Favourite row = (await favourites.list()).items.first;

      await favourites.removeById(row.id);
      await favourites.removeById(row.id); // Already gone — still fine.

      expect((await favourites.list()).items.map((Favourite f) => f.id), isNot(contains(row.id)));
    });

    test('refuses an unknown target', () async {
      await expectCode(
        favourites.add(const FavouriteTarget.service('nope')),
        ApiErrorCode.serviceNotFound,
      );
    });

    test('keeps saved items across a restart', () async {
      await favourites.add(const FavouriteTarget.service('mock-lumiere-3'));

      await start();

      expect((await favourites.list()).items, hasLength(6));
    });

    test('refuses a provider', () async {
      await auth.logout();
      await auth.login(
        email: 'verified.provider@eventor.test',
        password: MockBackend.seedPassword,
      );

      await expectCode(favourites.list(), ApiErrorCode.forbiddenRole);
    });
  });

  test('the repositories implement the app\'s interfaces', () {
    expect(catalog, isA<CatalogRepository>());
    expect(favourites, isA<FavouritesRepository>());
  });
}
