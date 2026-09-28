import '../../catalog/models/json_read.dart';
import '../../catalog/models/price_type.dart';
import '../../models/account.dart';
import '../../provider/models/provider_home.dart';
import 'catalog_photo.dart';

export '../../provider/models/provider_home.dart'
    show ProviderServiceRow, ProviderServiceStatus;

/// One key of `ServiceDetailDto.publishMissing` — what a service still needs
/// before `POST …/publish` accepts it.
enum ServiceMissing {
  titleEn('titleEn'),
  titleAr('titleAr'),
  descriptionEn('descriptionEn'),
  descriptionAr('descriptionAr'),
  price('price'),
  photos('photos'),
  category('category'),
  wilayas('wilayas');

  const ServiceMissing(this.apiValue);

  final String apiValue;

  /// The known keys in [values]' order; an unknown one is dropped — a key the
  /// server adds later has no row on P9 to tick.
  static List<ServiceMissing> fromApi(Iterable<String> keys) => <ServiceMissing>[
        for (final ServiceMissing item in values)
          if (keys.contains(item.apiValue)) item,
      ];
}

/// The six rows of P9's checklist. Each row covers one or two
/// [ServiceMissing] keys — the title and description of a language share one.
enum ServiceChecklistItem {
  englishText(<ServiceMissing>[ServiceMissing.titleEn, ServiceMissing.descriptionEn]),
  arabicText(<ServiceMissing>[ServiceMissing.titleAr, ServiceMissing.descriptionAr]),
  price(<ServiceMissing>[ServiceMissing.price]),
  photos(<ServiceMissing>[ServiceMissing.photos]),
  category(<ServiceMissing>[ServiceMissing.category]),
  wilayas(<ServiceMissing>[ServiceMissing.wilayas]);

  const ServiceChecklistItem(this.keys);

  final List<ServiceMissing> keys;

  bool isMissingIn(List<ServiceMissing> missing) => keys.any(missing.contains);
}

/// Why a published service is not in front of clients —
/// `ServiceDetailDto.visibilityReasons`.
enum ServiceVisibilityReason {
  deleted('deleted'),
  notPublished('not_published'),
  providerBlocked('provider_blocked'),
  providerNotVerified('provider_not_verified'),
  providerDeleted('provider_deleted'),
  noOpenWilaya('no_open_wilaya');

  const ServiceVisibilityReason(this.apiValue);

  final String apiValue;

  static List<ServiceVisibilityReason> fromApi(Iterable<String> keys) =>
      <ServiceVisibilityReason>[
        for (final ServiceVisibilityReason reason in values)
          if (keys.contains(reason.apiValue)) reason,
      ];
}

/// Why an admin hid a service — `HiddenInfoDto`.
class HiddenInfo {
  const HiddenInfo({
    required this.reason,
    required this.allowResubmit,
    this.message,
    this.hiddenAt,
  });

  factory HiddenInfo.fromJson(Map<String, Object?> json) => HiddenInfo(
        reason: readString(json, 'reason'),
        message: readStringOrNull(json, 'message'),
        allowResubmit: readBool(json, 'allowResubmit'),
        hiddenAt: readDateOrNull(json, 'hiddenAt'),
      );

  /// A machine code — `misleading_content`. Not shown: [message] is the
  /// admin's own words.
  final String reason;
  final String? message;

  /// Whether the service can be reviewed again once fixed. There is no
  /// resubmit route yet, so the app can only say "contact support".
  final bool allowResubmit;
  final DateTime? hiddenAt;
}

/// A wilaya a service covers, and whether it is open for bookings today.
class CoveredWilaya {
  const CoveredWilaya({required this.wilaya, this.isOpen = true});

  factory CoveredWilaya.fromJson(Map<String, Object?> json) => CoveredWilaya(
        wilaya: Wilaya.fromJson(json),
        isOpen: json['isOpen'] as bool? ?? true,
      );

  final Wilaya wilaya;
  final bool isOpen;

  int get code => wilaya.code;
}

/// One "What is included" line — `ServiceFactDto`, which is snake_case on
/// the wire (unlike every other DTO). All four texts are required, even in a
/// draft.
class ServiceFact {
  const ServiceFact({
    required this.labelEn,
    required this.labelAr,
    required this.valueEn,
    required this.valueAr,
  });

  factory ServiceFact.fromJson(Map<String, Object?> json) => ServiceFact(
        labelEn: readString(json, 'label_en').ifEmpty(readString(json, 'labelEn')),
        labelAr: readString(json, 'label_ar').ifEmpty(readString(json, 'labelAr')),
        valueEn: readString(json, 'value_en').ifEmpty(readString(json, 'valueEn')),
        valueAr: readString(json, 'value_ar').ifEmpty(readString(json, 'valueAr')),
      );

  static const int maxLabelLength = 80;
  static const int maxValueLength = 160;

  final String labelEn;
  final String labelAr;
  final String valueEn;
  final String valueAr;

  String labelFor(String languageCode) =>
      languageCode == 'ar' && labelAr.isNotEmpty ? labelAr : labelEn;

  String valueFor(String languageCode) =>
      languageCode == 'ar' && valueAr.isNotEmpty ? valueAr : valueEn;

  Map<String, Object?> toJson() => <String, Object?>{
        'label_en': labelEn,
        'label_ar': labelAr,
        'value_en': valueEn,
        'value_ar': valueAr,
      };

  @override
  bool operator ==(Object other) =>
      other is ServiceFact &&
      other.labelEn == labelEn &&
      other.labelAr == labelAr &&
      other.valueEn == valueEn &&
      other.valueAr == valueAr;

  @override
  int get hashCode => Object.hash(labelEn, labelAr, valueEn, valueAr);
}

/// A paid option on top of the base price — `ServiceExtraDto`. The Arabic
/// name may be empty in a draft.
class ServiceExtra {
  const ServiceExtra({
    required this.nameEn,
    required this.nameAr,
    required this.price,
    this.id,
  });

  factory ServiceExtra.fromJson(Map<String, Object?> json) => ServiceExtra(
        id: readStringOrNull(json, 'id'),
        nameEn: readString(json, 'nameEn'),
        nameAr: readString(json, 'nameAr'),
        price: readString(json, 'price'),
      );

  static const int maxNameLength = 160;

  /// `null` until the server has stored it.
  final String? id;
  final String nameEn;
  final String nameAr;

  /// The API's money string.
  final String price;

  String nameFor(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  /// `ServiceExtraInputDto` — the set is replaced whole, in order, so the
  /// id is not sent.
  Map<String, Object?> toJson() => <String, Object?>{
        'nameEn': nameEn,
        'nameAr': nameAr,
        'price': price,
      };

  @override
  bool operator ==(Object other) =>
      other is ServiceExtra &&
      other.nameEn == nameEn &&
      other.nameAr == nameAr &&
      other.price == price;

  @override
  int get hashCode => Object.hash(nameEn, nameAr, price);
}

/// One card of P6 — `AppProviderServiceRowDto`.
class ProviderServiceSummary {
  const ProviderServiceSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.visibleInApp,
    required this.basePrice,
    required this.priceType,
    this.avgRating = '0.00',
    this.ratingCount = 0,
    this.bookingsCount = 0,
    this.photosCount = 0,
    this.coverUrl,
    this.wilayas = const <Wilaya>[],
    this.category,
  });

  factory ProviderServiceSummary.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return ProviderServiceSummary(
      id: json['id']! as String,
      title: LocalizedText.read(json, 'title'),
      status: ProviderServiceStatus.fromApi(json['status'] as String?),
      visibleInApp: readBool(json, 'visibleInApp'),
      basePrice: readString(json, 'basePrice'),
      priceType: PriceType.fromApi(json['priceType'] as String?),
      avgRating: readDecimal(json, 'avgRating'),
      ratingCount: readInt(json, 'ratingCount'),
      bookingsCount: readInt(json, 'bookingsCount'),
      photosCount: readInt(json, 'photosCount'),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      wilayas: readList(json, 'wilayas', Wilaya.fromJson),
      // Not in the documented row; read when a server version sends it.
      category: category == null ? null : ServiceCategory.fromJson(category),
    );
  }

  final String id;
  final LocalizedText title;
  final ProviderServiceStatus status;

  /// Clients can find it today: published, provider verified and active, and
  /// at least one open wilaya.
  final bool visibleInApp;
  final String basePrice;
  final PriceType priceType;
  final String avgRating;
  final int ratingCount;
  final int bookingsCount;
  final int photosCount;
  final String? coverUrl;
  final List<Wilaya> wilayas;
  final ServiceCategory? category;

  bool get isPublished => status == ProviderServiceStatus.published;
  bool get isHidden => status == ProviderServiceStatus.hidden;

  /// In front of clients right now — a live service has no note to explain.
  bool get isLive => isPublished && visibleInApp;

  bool covers(int wilayaCode) =>
      wilayas.any((Wilaya wilaya) => wilaya.code == wilayaCode);

  /// The home's and the availability picker's shape of it.
  ProviderServiceRow toRow() => ProviderServiceRow(
        id: id,
        title: title,
        status: status,
        basePrice: basePrice,
        coverUrl: coverUrl,
        priceType: priceType,
      );
}

/// A pack a service sits in — `PackRefDto`.
class PackRef {
  const PackRef({required this.id, required this.name});

  factory PackRef.fromJson(Map<String, Object?> json) => PackRef(
        id: json['id']! as String,
        name: LocalizedText.read(json, 'name'),
      );

  final String id;
  final LocalizedText name;
}

/// P7a's source of truth — `ServiceDetailDto`, as the provider's own routes
/// (GET, PATCH, publish, unpublish) answer.
class ProviderServiceDetail {
  const ProviderServiceDetail({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.basePrice,
    required this.priceType,
    required this.status,
    required this.visibleInApp,
    this.category,
    this.cancellationPolicyEn,
    this.cancellationPolicyAr,
    this.coverUrl,
    this.facts = const <ServiceFact>[],
    this.extras = const <ServiceExtra>[],
    this.wilayas = const <CoveredWilaya>[],
    this.maxEventsPerDay = 1,
    this.maxGuests,
    this.photos = const <CatalogPhoto>[],
    this.hidden,
    this.visibilityReasons = const <ServiceVisibilityReason>[],
    this.publishMissing = const <ServiceMissing>[],
    this.rating = '0.00',
    this.ratingCount = 0,
    this.bookingsCount = 0,
    this.packs = const <PackRef>[],
  });

  factory ProviderServiceDetail.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    final Map<String, Object?>? hidden = readObject(json, 'hidden');
    final Map<String, Object?> stats =
        readObject(json, 'stats') ?? const <String, Object?>{};
    // `wilayaDetails` carries whether each is open; the plain `wilayas` is
    // the fallback for a response without it.
    List<CoveredWilaya> wilayas =
        readList(json, 'wilayaDetails', CoveredWilaya.fromJson);
    if (wilayas.isEmpty) {
      wilayas = readList(json, 'wilayas', CoveredWilaya.fromJson);
    }
    return ProviderServiceDetail(
      id: json['id']! as String,
      titleEn: readString(json, 'titleEn'),
      titleAr: readString(json, 'titleAr'),
      descriptionEn: readString(json, 'descriptionEn'),
      descriptionAr: readString(json, 'descriptionAr'),
      cancellationPolicyEn: readStringOrNull(json, 'cancellationPolicyEn'),
      cancellationPolicyAr: readStringOrNull(json, 'cancellationPolicyAr'),
      category: category == null ? null : ServiceCategory.fromJson(category),
      basePrice: readString(json, 'basePrice'),
      priceType: PriceType.fromApi(json['priceType'] as String?),
      status: ProviderServiceStatus.fromApi(json['status'] as String?),
      visibleInApp: readBool(json, 'visibleInApp'),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      facts: readList(json, 'facts', ServiceFact.fromJson),
      extras: readList(json, 'extras', ServiceExtra.fromJson),
      wilayas: wilayas,
      maxEventsPerDay: readIntOrNull(json, 'maxEventsPerDay') ?? 1,
      maxGuests: readIntOrNull(json, 'maxGuests'),
      photos: readPhotos(json['photos']),
      hidden: hidden == null ? null : HiddenInfo.fromJson(hidden),
      visibilityReasons:
          ServiceVisibilityReason.fromApi(readStrings(json, 'visibilityReasons')),
      publishMissing: ServiceMissing.fromApi(readStrings(json, 'publishMissing')),
      rating: readDecimal(json, 'rating'),
      ratingCount: readInt(json, 'ratingCount'),
      bookingsCount: readInt(json, 'bookingsCount'),
      packs: readList(stats, 'packs', PackRef.fromJson),
    );
  }

  static const int maxTitleLength = 160;
  static const int maxTextLength = 5000;
  static const int maxEventsPerDayLimit = 20;

  final String id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final String? cancellationPolicyEn;
  final String? cancellationPolicyAr;
  final ServiceCategory? category;
  final String basePrice;
  final PriceType priceType;
  final ProviderServiceStatus status;
  final bool visibleInApp;
  final String? coverUrl;
  final List<ServiceFact> facts;
  final List<ServiceExtra> extras;
  final List<CoveredWilaya> wilayas;
  final int maxEventsPerDay;
  final int? maxGuests;
  final List<CatalogPhoto> photos;

  /// Set while an admin keeps it hidden.
  final HiddenInfo? hidden;

  /// Empty when clients can see it.
  final List<ServiceVisibilityReason> visibilityReasons;

  /// Empty when it can be published.
  final List<ServiceMissing> publishMissing;
  final String rating;
  final int ratingCount;
  final int bookingsCount;

  /// The provider's packs it belongs to.
  final List<PackRef> packs;

  bool get isPublished => status == ProviderServiceStatus.published;
  bool get isHidden => status == ProviderServiceStatus.hidden;
  bool get isDraft => status == ProviderServiceStatus.draft;

  /// The wilayas it covers that are closed on Eventor right now.
  List<Wilaya> get closedWilayas => <Wilaya>[
        for (final CoveredWilaya covered in wilayas)
          if (!covered.isOpen) covered.wilaya,
      ];

  /// The same service with a gallery P8 changed — the form keeps its own
  /// edits and takes only the photos (and what they tick) from the server.
  ProviderServiceDetail withPhotosOf(ProviderServiceDetail fresh) =>
      ProviderServiceDetail(
        id: id,
        titleEn: titleEn,
        titleAr: titleAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        cancellationPolicyEn: cancellationPolicyEn,
        cancellationPolicyAr: cancellationPolicyAr,
        category: category,
        basePrice: basePrice,
        priceType: priceType,
        status: status,
        visibleInApp: visibleInApp,
        coverUrl: fresh.coverUrl,
        facts: facts,
        extras: extras,
        wilayas: wilayas,
        maxEventsPerDay: maxEventsPerDay,
        maxGuests: maxGuests,
        photos: fresh.photos,
        hidden: hidden,
        visibilityReasons: visibilityReasons,
        publishMissing: <ServiceMissing>[
          ...publishMissing.where((ServiceMissing m) => m != ServiceMissing.photos),
          if (fresh.publishMissing.contains(ServiceMissing.photos))
            ServiceMissing.photos,
        ],
        rating: rating,
        ratingCount: ratingCount,
        bookingsCount: bookingsCount,
        packs: packs,
      );
}

/// What P7/P7a sends — `AppCreateServiceDto` / `AppUpdateServiceDto`.
///
/// Every field is optional so an edit sends only what changed (the PATCH is
/// partial). A cancellation policy of `''` clears it; [clearMaxGuests]
/// removes the cap.
class ServiceInput {
  const ServiceInput({
    this.categoryId,
    this.titleEn,
    this.titleAr,
    this.descriptionEn,
    this.descriptionAr,
    this.cancellationPolicyEn,
    this.cancellationPolicyAr,
    this.basePrice,
    this.priceType,
    this.maxEventsPerDay,
    this.maxGuests,
    this.clearMaxGuests = false,
    this.facts,
    this.extras,
    this.wilayaCodes,
  });

  final String? categoryId;
  final String? titleEn;
  final String? titleAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? cancellationPolicyEn;
  final String? cancellationPolicyAr;
  final String? basePrice;
  final PriceType? priceType;
  final int? maxEventsPerDay;
  final int? maxGuests;
  final bool clearMaxGuests;
  final List<ServiceFact>? facts;
  final List<ServiceExtra>? extras;
  final List<int>? wilayaCodes;

  bool get isEmpty => toJson().isEmpty;

  Map<String, Object?> toJson() {
    String? policy(String? text) => text == null || text.isEmpty ? null : text;
    return <String, Object?>{
      if (categoryId != null) 'categoryId': categoryId,
      if (titleEn != null) 'titleEn': titleEn,
      if (titleAr != null) 'titleAr': titleAr,
      if (descriptionEn != null) 'descriptionEn': descriptionEn,
      if (descriptionAr != null) 'descriptionAr': descriptionAr,
      if (cancellationPolicyEn != null)
        'cancellationPolicyEn': policy(cancellationPolicyEn),
      if (cancellationPolicyAr != null)
        'cancellationPolicyAr': policy(cancellationPolicyAr),
      if (basePrice != null) 'basePrice': basePrice,
      if (priceType != null) 'priceType': priceType!.apiValue,
      if (maxEventsPerDay != null) 'maxEventsPerDay': maxEventsPerDay,
      if (maxGuests != null || clearMaxGuests) 'maxGuests': maxGuests,
      if (facts != null)
        'facts': <Map<String, Object?>>[
          for (final ServiceFact fact in facts!) fact.toJson(),
        ],
      if (extras != null)
        'extras': <Map<String, Object?>>[
          for (final ServiceExtra extra in extras!) extra.toJson(),
        ],
      if (wilayaCodes != null) 'wilayaCodes': wilayaCodes,
    };
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
