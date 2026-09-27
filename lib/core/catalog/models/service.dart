import '../../models/account.dart';
import 'catalog_ref.dart';
import 'json_read.dart';
import 'pack.dart';
import 'photo.dart';
import 'price_type.dart';
import 'provider.dart';
import 'review.dart';

/// A service in a list — Home, search results, a provider's profile.
class ServiceCard {
  const ServiceCard({
    required this.id,
    required this.title,
    required this.basePrice,
    required this.priceType,
    required this.avgRating,
    required this.ratingCount,
    required this.bookingsCount,
    required this.wilayas,
    required this.provider,
    required this.isFavourite,
    this.category,
    this.coverUrl,
  });

  factory ServiceCard.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return ServiceCard(
      id: json['id']! as String,
      title: LocalizedText.read(json, 'title'),
      category: category == null ? null : CategoryRef.fromJson(category),
      basePrice: readString(json, 'basePrice'),
      priceType: PriceType.fromApi(json['priceType'] as String?),
      avgRating: readString(json, 'avgRating'),
      ratingCount: readInt(json, 'ratingCount'),
      bookingsCount: readInt(json, 'bookingsCount'),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      wilayas: readList(json, 'wilayas', Wilaya.fromJson),
      provider: ProviderSummary.fromJson(
        readObject(json, 'provider') ?? const <String, Object?>{'id': ''},
      ),
      isFavourite: readBool(json, 'isFavourite'),
    );
  }

  final String id;
  final LocalizedText title;
  final CategoryRef? category;

  /// `"45000.00"`. Present even for [PriceType.onQuote], where it is not a
  /// price the provider promised and is not shown.
  final String basePrice;
  final PriceType priceType;
  final String avgRating;
  final int ratingCount;
  final int bookingsCount;
  final String? coverUrl;

  /// The open wilayas the service covers.
  final List<Wilaya> wilayas;
  final ProviderSummary provider;

  /// Always `false` for a caller without a session.
  final bool isFavourite;

  bool get isRated => ratingCount > 0;
}

/// One "Key facts" row.
class ServiceFact {
  const ServiceFact({required this.label, required this.value});

  factory ServiceFact.fromJson(Map<String, Object?> json) => ServiceFact(
        label: LocalizedText.read(json, 'label'),
        value: LocalizedText.read(json, 'value'),
      );

  final LocalizedText label;
  final LocalizedText value;
}

/// A paid add-on. Shown for information only; picking one belongs to the
/// booking request.
class ServiceExtra {
  const ServiceExtra({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ServiceExtra.fromJson(Map<String, Object?> json) => ServiceExtra(
        id: json['id']! as String,
        name: LocalizedText.read(json, 'name'),
        price: readString(json, 'price'),
      );

  final String id;
  final LocalizedText name;
  final String price;
}

/// Screen 12.
class ServiceDetail extends ServiceCard {
  const ServiceDetail({
    required super.id,
    required super.title,
    required super.basePrice,
    required super.priceType,
    required super.avgRating,
    required super.ratingCount,
    required super.bookingsCount,
    required super.wilayas,
    required super.provider,
    required super.isFavourite,
    required this.description,
    required this.facts,
    required this.extras,
    required this.photos,
    required this.maxEventsPerDay,
    required this.ratingBreakdown,
    required this.recentReviews,
    required this.providerPacks,
    super.category,
    super.coverUrl,
    this.cancellationPolicy,
    this.maxGuests,
  });

  factory ServiceDetail.fromJson(Map<String, Object?> json) {
    final ServiceCard card = ServiceCard.fromJson(json);
    return ServiceDetail(
      id: card.id,
      title: card.title,
      category: card.category,
      basePrice: card.basePrice,
      priceType: card.priceType,
      avgRating: card.avgRating,
      ratingCount: card.ratingCount,
      bookingsCount: card.bookingsCount,
      coverUrl: card.coverUrl,
      wilayas: card.wilayas,
      provider: card.provider,
      isFavourite: card.isFavourite,
      description: LocalizedText.read(json, 'description'),
      cancellationPolicy: LocalizedText.readOrNull(json, 'cancellationPolicy'),
      facts: readList(json, 'facts', ServiceFact.fromJson),
      extras: readList(json, 'extras', ServiceExtra.fromJson),
      photos: readList(json, 'photos', Photo.fromJson),
      maxGuests: readIntOrNull(json, 'maxGuests'),
      maxEventsPerDay: readInt(json, 'maxEventsPerDay'),
      ratingBreakdown: readList(json, 'ratingBreakdown', RatingBucket.fromJson),
      recentReviews: readList(json, 'recentReviews', Review.fromJson),
      providerPacks: readList(json, 'providerPacks', PackCard.fromJson),
    );
  }

  final LocalizedText description;

  /// The provider's own words. Shown only when set — the app never states a
  /// cancellation policy of its own.
  final LocalizedText? cancellationPolicy;
  final List<ServiceFact> facts;
  final List<ServiceExtra> extras;
  final List<Photo> photos;
  final int? maxGuests;
  final int maxEventsPerDay;
  final List<RatingBucket> ratingBreakdown;

  /// The three most recent.
  final List<Review> recentReviews;
  final List<PackCard> providerPacks;
}
