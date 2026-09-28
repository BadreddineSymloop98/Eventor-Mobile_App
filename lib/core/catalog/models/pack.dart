import '../../models/account.dart';
import 'catalog_ref.dart';
import 'json_read.dart';
import 'photo.dart';
import 'price_type.dart';
import 'provider.dart';
import 'review.dart';

/// What a pack is put together for — the chips on 19.
enum EventType {
  wedding('wedding'),
  engagement('engagement'),
  henna('henna'),
  birthday('birthday'),
  circumcision('circumcision'),
  graduation('graduation'),
  corporate('corporate'),
  conference('conference'),
  academic('academic'),
  other('other');

  const EventType(this.apiValue);

  final String apiValue;

  /// The types a client can filter by. `academic` exists in the API but
  /// academic events are not an app audience.
  static const List<EventType> browsable = <EventType>[
    wedding,
    engagement,
    henna,
    birthday,
    circumcision,
    graduation,
    corporate,
    conference,
    other,
  ];

  static EventType fromApi(String? value) {
    for (final EventType type in values) {
      if (type.apiValue == value) return type;
    }
    return other;
  }
}

/// A Ready Pack in a list — 2 to 6 of one provider's services at one price.
class PackCard {
  const PackCard({
    required this.id,
    required this.name,
    required this.eventType,
    required this.wilaya,
    required this.price,
    required this.sumOfItems,
    required this.savings,
    required this.savingsPercent,
    required this.itemsCount,
    required this.categoryNames,
    required this.avgRating,
    required this.ratingCount,
    required this.bookingsCount,
    required this.provider,
    required this.isFavourite,
    this.coverUrl,
  });

  factory PackCard.fromJson(Map<String, Object?> json) => PackCard(
        id: json['id']! as String,
        name: LocalizedText.read(json, 'name'),
        eventType: EventType.fromApi(json['eventType'] as String?),
        wilaya: Wilaya.fromJson(
          readObject(json, 'wilaya') ?? const <String, Object?>{'code': 0},
        ),
        price: readString(json, 'price'),
        sumOfItems: readString(json, 'sumOfItems'),
        savings: readString(json, 'savings'),
        savingsPercent: readNum(json, 'savingsPercent'),
        itemsCount: readInt(json, 'itemsCount'),
        // Live data repeats names — three photography items read
        // "Photography · Photography · Photography" otherwise.
        categoryNames: readStrings(json, 'categoryNames').toSet().toList(),
        coverUrl: readStringOrNull(json, 'coverUrl'),
        avgRating: readDecimal(json, 'avgRating'),
        ratingCount: readInt(json, 'ratingCount'),
        bookingsCount: readInt(json, 'bookingsCount'),
        provider: ProviderSummary.fromJson(
          readObject(json, 'provider') ?? const <String, Object?>{'id': ''},
        ),
        isFavourite: readBool(json, 'isFavourite'),
      );

  final String id;
  final LocalizedText name;
  final EventType eventType;

  /// The pack's home wilaya. Its items may cover a different set — see
  /// `PackDetail.wilayas`.
  final Wilaya wilaya;
  final String price;

  /// What the items cost booked one by one.
  final String sumOfItems;
  final String savings;

  /// `12` or `15.1`.
  final num savingsPercent;
  final int itemsCount;

  /// Server-translated, de-duplicated, in order.
  final List<String> categoryNames;
  final String? coverUrl;
  final String avgRating;
  final int ratingCount;
  final int bookingsCount;
  final ProviderSummary provider;
  final bool isFavourite;

  bool get isRated => ratingCount > 0;
}

/// One service inside a pack.
class PackItem {
  const PackItem({
    required this.serviceId,
    required this.title,
    required this.price,
    required this.priceType,
    required this.position,
    this.category,
    this.coverUrl,
  });

  factory PackItem.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return PackItem(
      serviceId: json['serviceId']! as String,
      title: LocalizedText.read(json, 'title'),
      category: category == null ? null : CategoryRef.fromJson(category),
      price: readString(json, 'price'),
      priceType: PriceType.fromApi(json['priceType'] as String?),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      position: readInt(json, 'position'),
    );
  }

  final String serviceId;
  final LocalizedText title;
  final CategoryRef? category;

  /// The service's own base price.
  final String price;
  final PriceType priceType;
  final String? coverUrl;
  final int position;
}

/// Screen 20.
class PackDetail extends PackCard {
  const PackDetail({
    required super.id,
    required super.name,
    required super.eventType,
    required super.wilaya,
    required super.price,
    required super.sumOfItems,
    required super.savings,
    required super.savingsPercent,
    required super.itemsCount,
    required super.categoryNames,
    required super.avgRating,
    required super.ratingCount,
    required super.bookingsCount,
    required super.provider,
    required super.isFavourite,
    required this.photos,
    required this.items,
    required this.wilayas,
    required this.recentReviews,
    super.coverUrl,
    this.description,
    this.maxGuests,
  });

  factory PackDetail.fromJson(Map<String, Object?> json) {
    final PackCard card = PackCard.fromJson(json);
    final List<PackItem> items = readList(json, 'items', PackItem.fromJson)
      ..sort((PackItem a, PackItem b) => a.position.compareTo(b.position));
    return PackDetail(
      id: card.id,
      name: card.name,
      eventType: card.eventType,
      wilaya: card.wilaya,
      price: card.price,
      sumOfItems: card.sumOfItems,
      savings: card.savings,
      savingsPercent: card.savingsPercent,
      itemsCount: card.itemsCount,
      categoryNames: card.categoryNames,
      coverUrl: card.coverUrl,
      avgRating: card.avgRating,
      ratingCount: card.ratingCount,
      bookingsCount: card.bookingsCount,
      provider: card.provider,
      isFavourite: card.isFavourite,
      description: LocalizedText.readOrNull(json, 'description'),
      maxGuests: readIntOrNull(json, 'maxGuests'),
      photos: readList(json, 'photos', Photo.fromJson),
      items: items,
      wilayas: readList(json, 'wilayas', Wilaya.fromJson),
      recentReviews: readList(json, 'recentReviews', Review.fromJson),
    );
  }

  final LocalizedText? description;
  final int? maxGuests;
  final List<Photo> photos;

  /// In the order the provider set.
  final List<PackItem> items;

  /// The wilayas every item covers.
  final List<Wilaya> wilayas;
  final List<Review> recentReviews;
}
