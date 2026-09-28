import '../../catalog/models/json_read.dart';
import '../../catalog/models/pack.dart' show EventType;
import '../../catalog/models/price_type.dart';
import '../../models/account.dart';
import '../../provider/models/provider_home.dart' show ProviderServiceStatus;
import 'catalog_photo.dart';

/// Where one of the provider's packs stands. Unlike a service, unpublishing
/// a pack moves it to [unpublished], not back to [draft].
enum PackStatus {
  draft,
  published,
  unpublished;

  static PackStatus fromApi(String? value) => switch (value) {
        'published' => published,
        'unpublished' => unpublished,
        _ => draft,
      };
}

/// One key of `PackDetailDto.publishMissing`.
enum PackMissing {
  nameEn('nameEn'),
  nameAr('nameAr'),
  items('items'),
  unpublishedItems('unpublishedItems'),
  providerBlocked('providerBlocked'),
  providerNotVerified('providerNotVerified'),
  priceNotBelowSum('priceNotBelowSum'),
  wilayaNotCovered('wilayaNotCovered');

  const PackMissing(this.apiValue);

  final String apiValue;

  static List<PackMissing> fromApi(Iterable<String> keys) => <PackMissing>[
        for (final PackMissing item in values)
          if (keys.contains(item.apiValue)) item,
      ];
}

/// The rows of P14's checklist. The design's "At least one photo" row is
/// left out: the API does not ask a pack for a photo to publish. The
/// profile row only shows while the account itself is what blocks it.
enum PackChecklistItem {
  englishName(<PackMissing>[PackMissing.nameEn]),
  arabicName(<PackMissing>[PackMissing.nameAr]),
  services(<PackMissing>[PackMissing.items, PackMissing.unpublishedItems]),
  price(<PackMissing>[PackMissing.priceNotBelowSum]),
  wilaya(<PackMissing>[PackMissing.wilayaNotCovered]),
  profile(<PackMissing>[PackMissing.providerNotVerified, PackMissing.providerBlocked]);

  const PackChecklistItem(this.keys);

  final List<PackMissing> keys;

  bool isMissingIn(List<PackMissing> missing) => keys.any(missing.contains);

  /// The rows P14 shows for [missing]: every row, but the profile one only
  /// when it is what fails.
  static List<PackChecklistItem> shownFor(List<PackMissing> missing) =>
      <PackChecklistItem>[
        for (final PackChecklistItem item in values)
          if (item != profile || item.isMissingIn(missing)) item,
      ];
}

/// Why a published pack cannot be booked — `AttentionReasonDto.code`.
enum PackAttentionCode {
  itemNotPublished('item_not_published'),
  itemDeleted('item_deleted'),
  providerBlocked('provider_blocked'),
  providerNotVerified('provider_not_verified'),
  providerDeleted('provider_deleted'),
  unknown('');

  const PackAttentionCode(this.apiValue);

  final String apiValue;

  static PackAttentionCode fromApi(String? value) {
    for (final PackAttentionCode code in values) {
      if (code.apiValue == value) return code;
    }
    return unknown;
  }
}

class PackAttention {
  const PackAttention({required this.code, this.serviceId});

  factory PackAttention.fromJson(Map<String, Object?> json) => PackAttention(
        code: PackAttentionCode.fromApi(json['code'] as String?),
        serviceId: readStringOrNull(json, 'serviceId'),
      );

  final PackAttentionCode code;

  /// The item to fix, for the item codes.
  final String? serviceId;
}

/// Whether an item can be sold inside its pack — `PackItemDto.availability`.
enum PackItemAvailability {
  available,
  notPublished,
  hidden,
  deleted;

  static PackItemAvailability fromApi(String? value) => switch (value) {
        'not_published' => notPublished,
        'hidden' => hidden,
        'deleted' => deleted,
        _ => available,
      };
}

/// One service inside a pack — `PackItemDto` with its `service`.
class ProviderPackItem {
  const ProviderPackItem({
    required this.serviceId,
    required this.title,
    required this.price,
    required this.status,
    required this.availability,
    this.priceType = PriceType.perEvent,
    this.category,
    this.coverUrl,
  });

  factory ProviderPackItem.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> service =
        readObject(json, 'service') ?? const <String, Object?>{'id': ''};
    final Map<String, Object?>? category = readObject(service, 'category');
    return ProviderPackItem(
      serviceId: service['id']! as String,
      title: LocalizedText.read(service, 'title'),
      price: readString(json, 'price'),
      status: ProviderServiceStatus.fromApi(service['status'] as String?),
      availability: PackItemAvailability.fromApi(json['availability'] as String?),
      priceType: PriceType.fromApi(service['priceType'] as String?),
      category: category == null ? null : ServiceCategory.fromJson(category),
      coverUrl: readStringOrNull(service, 'coverUrl'),
    );
  }

  final String serviceId;
  final LocalizedText title;

  /// The service's base price, as the pack counts it.
  final String price;
  final ProviderServiceStatus status;
  final PackItemAvailability availability;
  final PriceType priceType;
  final ServiceCategory? category;
  final String? coverUrl;
}

/// One card of P10 — `PackRowDto`; [ProviderPackDetail] adds the rest.
class ProviderPackSummary {
  const ProviderPackSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.price,
    required this.sumOfItems,
    required this.savings,
    required this.eventType,
    required this.wilaya,
    this.savingsPercent = 0,
    this.itemsCount = 0,
    this.categoryNames = const <LocalizedText>[],
    this.coverUrl,
    this.rating = '0.00',
    this.ratingCount = 0,
    this.bookingsCount = 0,
    this.needsAttention = false,
    this.attention = const <PackAttention>[],
    this.visibleInApp = false,
  });

  factory ProviderPackSummary.fromJson(Map<String, Object?> json) =>
      ProviderPackSummary(
        id: json['id']! as String,
        name: LocalizedText.read(json, 'name'),
        status: PackStatus.fromApi(json['status'] as String?),
        price: readString(json, 'price'),
        sumOfItems: readString(json, 'sumOfItems'),
        savings: readString(json, 'savings'),
        savingsPercent: readNum(json, 'savingsPercent'),
        eventType: EventType.fromApi(json['eventType'] as String?),
        wilaya: _wilaya(json),
        itemsCount: readInt(json, 'itemsCount'),
        categoryNames: _categoryNames(json),
        coverUrl: readStringOrNull(json, 'coverUrl'),
        rating: readDecimal(json, 'rating'),
        ratingCount: readInt(json, 'ratingCount'),
        bookingsCount: readInt(json, 'bookingsCount'),
        needsAttention: readBool(json, 'needsAttention'),
        attention: readList(json, 'attentionReasons', PackAttention.fromJson),
        visibleInApp: readBool(json, 'visibleInApp'),
      );

  static Wilaya _wilaya(Map<String, Object?> json) => Wilaya.fromJson(
        readObject(json, 'wilaya') ?? const <String, Object?>{'code': 0},
      );

  /// The items' categories, de-duplicated — three photography items read
  /// "Photography", not "Photography · Photography · Photography".
  static List<LocalizedText> _categoryNames(Map<String, Object?> json) {
    final List<LocalizedText> names = <LocalizedText>[];
    for (final LocalizedText name
        in readList(json, 'itemsSummary', (Map<String, Object?> c) => LocalizedText.read(c, 'name'))) {
      if (!names.any((LocalizedText n) => n.en == name.en)) names.add(name);
    }
    return names;
  }

  final String id;
  final LocalizedText name;
  final PackStatus status;
  final String price;

  /// What the items cost booked one by one.
  final String sumOfItems;

  /// Negative when the pack costs more than its items.
  final String savings;
  final num savingsPercent;
  final EventType eventType;
  final Wilaya wilaya;
  final int itemsCount;
  final List<LocalizedText> categoryNames;
  final String? coverUrl;
  final String rating;
  final int ratingCount;
  final int bookingsCount;

  /// Published, but an item is no longer sellable — clients cannot book it.
  final bool needsAttention;
  final List<PackAttention> attention;
  final bool visibleInApp;

  bool get isPublished => status == PackStatus.published;
}

/// P12's source of truth — `PackDetailDto`.
class ProviderPackDetail extends ProviderPackSummary {
  const ProviderPackDetail({
    required super.id,
    required super.name,
    required super.status,
    required super.price,
    required super.sumOfItems,
    required super.savings,
    required super.eventType,
    required super.wilaya,
    super.savingsPercent,
    super.itemsCount,
    super.categoryNames,
    super.coverUrl,
    super.rating,
    super.ratingCount,
    super.bookingsCount,
    super.needsAttention,
    super.attention,
    super.visibleInApp,
    this.descriptionEn = '',
    this.descriptionAr = '',
    this.maxGuests,
    this.items = const <ProviderPackItem>[],
    this.photos = const <CatalogPhoto>[],
    this.publishMissing = const <PackMissing>[],
  });

  factory ProviderPackDetail.fromJson(Map<String, Object?> json) {
    final ProviderPackSummary row = ProviderPackSummary.fromJson(json);
    return ProviderPackDetail(
      id: row.id,
      name: row.name,
      status: row.status,
      price: row.price,
      sumOfItems: row.sumOfItems,
      savings: row.savings,
      savingsPercent: row.savingsPercent,
      eventType: row.eventType,
      wilaya: row.wilaya,
      itemsCount: row.itemsCount,
      categoryNames: row.categoryNames,
      coverUrl: row.coverUrl,
      rating: row.rating,
      ratingCount: row.ratingCount,
      bookingsCount: row.bookingsCount,
      needsAttention: row.needsAttention,
      attention: row.attention,
      visibleInApp: row.visibleInApp,
      descriptionEn: readString(json, 'descriptionEn'),
      descriptionAr: readString(json, 'descriptionAr'),
      maxGuests: readIntOrNull(json, 'maxGuests'),
      items: readList(json, 'items', ProviderPackItem.fromJson),
      photos: readPhotos(json['photos']),
      publishMissing: PackMissing.fromApi(readStrings(json, 'publishMissing')),
    );
  }

  static const int maxNameLength = 160;
  static const int maxDescriptionLength = 5000;
  static const int minItems = 2;
  static const int maxItems = 6;

  final String descriptionEn;
  final String descriptionAr;
  final int? maxGuests;

  /// In the pack's order.
  final List<ProviderPackItem> items;
  final List<CatalogPhoto> photos;

  /// Empty when it can be published.
  final List<PackMissing> publishMissing;

  List<String> get serviceIds => <String>[
        for (final ProviderPackItem item in items) item.serviceId,
      ];

  /// The same pack with the gallery P13 changed — the form keeps its edits.
  ProviderPackDetail withPhotosOf(ProviderPackDetail fresh) => ProviderPackDetail(
        id: id,
        name: name,
        status: status,
        price: price,
        sumOfItems: sumOfItems,
        savings: savings,
        savingsPercent: savingsPercent,
        eventType: eventType,
        wilaya: wilaya,
        itemsCount: itemsCount,
        categoryNames: categoryNames,
        coverUrl: fresh.coverUrl,
        rating: rating,
        ratingCount: ratingCount,
        bookingsCount: bookingsCount,
        needsAttention: needsAttention,
        attention: attention,
        visibleInApp: visibleInApp,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        maxGuests: maxGuests,
        items: items,
        photos: fresh.photos,
        publishMissing: publishMissing,
      );
}

/// What P11/P12 sends — `AppCreatePackDto` / `AppUpdatePackDto`. Only the
/// fields that are set are sent; a description of `''` clears it and
/// [clearMaxGuests] removes the cap.
class PackInput {
  const PackInput({
    this.nameEn,
    this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.eventType,
    this.wilayaCode,
    this.price,
    this.maxGuests,
    this.clearMaxGuests = false,
    this.serviceIds,
  });

  final String? nameEn;
  final String? nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final EventType? eventType;
  final int? wilayaCode;
  final String? price;
  final int? maxGuests;
  final bool clearMaxGuests;

  /// Ordered; replaces the items.
  final List<String>? serviceIds;

  bool get isEmpty => toJson().isEmpty;

  Map<String, Object?> toJson() {
    String? text(String? value) => value == null || value.isEmpty ? null : value;
    return <String, Object?>{
      if (nameEn != null) 'nameEn': nameEn,
      if (nameAr != null) 'nameAr': nameAr,
      if (descriptionEn != null) 'descriptionEn': text(descriptionEn),
      if (descriptionAr != null) 'descriptionAr': text(descriptionAr),
      if (eventType != null) 'eventType': eventType!.apiValue,
      if (wilayaCode != null) 'wilayaCode': wilayaCode,
      if (price != null) 'price': price,
      if (maxGuests != null || clearMaxGuests) 'maxGuests': maxGuests,
      if (serviceIds != null) 'serviceIds': serviceIds,
    };
  }
}
