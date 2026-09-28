import 'package:eventor/core/catalog/models/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  group('LocalizedText', () {
    test('picks the language asked for', () {
      const LocalizedText text = LocalizedText(en: 'Venues', ar: 'قاعات');

      expect(text.of('en'), 'Venues');
      expect(text.of('ar'), 'قاعات');
    });

    test('falls back to English when the Arabic is blank', () {
      // Live: the Beauty category has an empty Arabic name.
      const LocalizedText text = LocalizedText(en: 'Beauty');

      expect(text.of('ar'), 'Beauty');
    });

    test('reads the resolved field when the pair is missing', () {
      final LocalizedText text =
          LocalizedText.read(<String, Object?>{'title': 'Salle'}, 'title');

      expect(text.of('en'), 'Salle');
    });
  });

  group('PriceType', () {
    test('reads every API value', () {
      expect(PriceType.fromApi('per_event'), PriceType.perEvent);
      expect(PriceType.fromApi('per_hour'), PriceType.perHour);
      expect(PriceType.fromApi('per_person'), PriceType.perPerson);
      expect(PriceType.fromApi('per_day'), PriceType.perDay);
      expect(PriceType.fromApi('on_quote'), PriceType.onQuote);
    });

    test('reads an unknown value as per event', () {
      expect(PriceType.fromApi('per_lunar_cycle'), PriceType.perEvent);
      expect(PriceType.fromApi(null), PriceType.perEvent);
    });
  });

  group('ServiceCard', () {
    test('parses a live list page', () {
      final List<ServiceCard> services = fixtureList('services_page.json')
          .map(ServiceCard.fromJson)
          .toList();

      expect(services, hasLength(3));
      expect(services.first.id, isNotEmpty);
      expect(services.first.title.of('en'), isNotEmpty);
      expect(services.first.title.of('ar'), isNotEmpty);
      expect(services.first.provider.businessName, isNotEmpty);
      expect(services.first.basePrice, matches(RegExp(r'^\d+\.\d{2}$')));
    });

    test('is unrated with no reviews, whatever the score says', () {
      final ServiceCard card = ServiceCard.fromJson(<String, Object?>{
        ...fixtureList('services_page.json').first,
        'avgRating': '0.00',
        'ratingCount': 0,
      });

      expect(card.isRated, isFalse);
    });
  });

  group('ServiceDetail', () {
    late ServiceDetail detail;

    setUp(() => detail = ServiceDetail.fromJson(fixtureData('service_detail.json')));

    test('parses the live detail', () {
      expect(detail.title.of('en'), 'Wedding photo & video coverage');
      expect(detail.title.of('ar'), 'تغطية زفاف بالصورة والفيديو');
      expect(detail.photos, isNotEmpty);
      expect(detail.facts, isNotEmpty);
      expect(detail.extras, isNotEmpty);
      expect(detail.ratingBreakdown, hasLength(5));
      expect(detail.provider.acceptingBookings, isTrue);
    });

    test('keeps the provider\'s own cancellation policy', () {
      expect(detail.cancellationPolicy, isNotNull);
      expect(detail.cancellationPolicy!.of('en'), startsWith('Free cancellation'));
    });

    test('has no policy when the provider set none', () {
      final ServiceDetail none = ServiceDetail.fromJson(<String, Object?>{
        ...fixtureData('service_detail.json'),
        'cancellationPolicy': null,
        'cancellationPolicyEn': null,
        'cancellationPolicyAr': null,
      });

      expect(none.cancellationPolicy, isNull);
    });
  });

  group('ProviderSummary', () {
    test('counts a missing accepting flag as accepting', () {
      final ProviderSummary provider = ProviderSummary.fromJson(
        const <String, Object?>{'id': 'p-1', 'businessName': 'Studio'},
      );

      expect(provider.acceptingBookings, isTrue);
    });

    test('reads a paused provider', () {
      final ProviderSummary provider = ProviderSummary.fromJson(
        const <String, Object?>{
          'id': 'p-1',
          'businessName': 'Studio',
          'acceptingBookings': false,
        },
      );

      expect(provider.acceptingBookings, isFalse);
    });
  });

  group('ProviderDetail', () {
    test('parses the live profile', () {
      final ProviderDetail detail =
          ProviderDetail.fromJson(fixtureData('provider_detail.json'));

      expect(detail.businessName, isNotEmpty);
      expect(detail.checks, isNotEmpty);
      expect(detail.services, isNotEmpty);
      expect(detail.services.length, lessThanOrEqualTo(10));
      expect(detail.wilayas, isNotEmpty);
    });

    test('knows when the profile does not list every service', () {
      final Map<String, Object?> json = fixtureData('provider_detail.json');
      final int listed = (json['services']! as List<Object?>).length;

      expect(
        ProviderDetail.fromJson(<String, Object?>{
          ...json,
          'servicesCount': listed + 2,
        }).hasMoreServices,
        isTrue,
      );
      expect(
        ProviderDetail.fromJson(<String, Object?>{
          ...json,
          'servicesCount': listed,
        }).hasMoreServices,
        isFalse,
      );
    });
  });

  group('PackCard', () {
    test('parses a live list page', () {
      final List<PackCard> packs =
          fixtureList('packs_page.json').map(PackCard.fromJson).toList();

      expect(packs, hasLength(3));
      expect(packs.first.wilaya.code, greaterThan(0));
      expect(packs.first.itemsCount, greaterThanOrEqualTo(2));
    });

    test('drops repeated category names, keeping their order', () {
      // Live: ["Photography", "Photography", "Photography"].
      final PackCard pack = PackCard.fromJson(<String, Object?>{
        ...fixtureList('packs_page.json').first,
        'categoryNames': <String>['Venues', 'Photography', 'Venues'],
      });

      expect(pack.categoryNames, <String>['Venues', 'Photography']);
    });

    test('reads an unknown event type as other', () {
      expect(EventType.fromApi('bar_mitzvah'), EventType.other);
    });

    test('leaves academic out of the browsable types', () {
      expect(EventType.browsable, isNot(contains(EventType.academic)));
      expect(EventType.browsable, hasLength(EventType.values.length - 1));
    });
  });

  group('PackDetail', () {
    test('parses the live detail', () {
      final PackDetail detail =
          PackDetail.fromJson(fixtureData('pack_detail.json'));

      expect(detail.items, isNotEmpty);
      expect(detail.name.of('en'), isNotEmpty);
    });

    test('orders its items by position', () {
      final Map<String, Object?> json = fixtureData('pack_detail.json');
      final List<Object?> items =
          List<Object?>.of(json['items']! as List<Object?>).reversed.toList();

      final PackDetail detail =
          PackDetail.fromJson(<String, Object?>{...json, 'items': items});

      final List<int> positions =
          detail.items.map((PackItem item) => item.position).toList();
      expect(positions, List<int>.of(positions)..sort());
    });
  });

  group('Availability', () {
    late Availability availability;

    setUp(() => availability = Availability.fromJson(fixtureData('availability.json')));

    test('knows the state of a listed day', () {
      final Map<String, Object?> first = (fixtureData('availability.json')['days']!
              as List<Object?>)
          .first! as Map<String, Object?>;
      final DateTime day = DateTime.parse(first['date']! as String);

      expect(availability.stateOf(day), DayState.fromApi(first['state'] as String?));
    });

    test('treats a day it does not list as blocked', () {
      expect(availability.stateOf(DateTime(1999, 1, 1)), DayState.blocked);
    });

    test('reads an unknown state as blocked', () {
      expect(DayState.fromApi('maybe'), DayState.blocked);
    });
  });

  group('Favourite', () {
    test('parses a page of services and packs', () {
      final List<Favourite> favourites = fixtureList('favourites_page.json')
          .map(Favourite.fromJson)
          .toList();

      expect(favourites.first.kind, FavouriteKind.service);
      expect(favourites.last.kind, FavouriteKind.pack);
      expect(favourites.last.available, isFalse);
    });

    test('names its target by kind and id', () {
      final Favourite favourite =
          Favourite.fromJson(fixtureList('favourites_page.json').last);

      expect(favourite.target, FavouriteTarget.pack(favourite.targetId));
    });

    test('compares targets by kind and id', () {
      expect(const FavouriteTarget.service('a'), const FavouriteTarget.service('a'));
      expect(const FavouriteTarget.service('a'), isNot(const FavouriteTarget.pack('a')));
    });
  });

  group('HomeFeed', () {
    test('parses every section', () {
      final HomeFeed feed = HomeFeed.fromJson(fixtureData('home.json'));

      expect(feed.fullName, 'Amina Benali');
      expect(feed.wilaya?.code, 16);
      expect(feed.unreadConversations, 3);
      expect(feed.upcomingBookings.single.status, 'accepted');
      expect(feed.budget.exists, isTrue);
      expect(feed.packs, hasLength(1));
      expect(feed.nearbyServices, hasLength(1));
    });

    test('has no city and no budget when the client set neither', () {
      final HomeFeed feed = HomeFeed.fromJson(<String, Object?>{
        ...fixtureData('home.json'),
        'wilaya': null,
        'budget': <String, Object?>{'exists': false},
      });

      expect(feed.wilaya, isNull);
      expect(feed.budget.exists, isFalse);
    });

    test('orders categories by position', () {
      final HomeFeed feed = HomeFeed.fromJson(fixtureData('home.json'));
      final List<int> positions = feed.categories
          .map((CategoryWithCount category) => category.position)
          .toList();

      expect(positions, List<int>.of(positions)..sort());
    });
  });
}
