import 'catalog_ref.dart';
import 'json_read.dart';

/// What can be saved. Providers themselves cannot be.
enum FavouriteKind {
  service('service'),
  pack('pack');

  const FavouriteKind(this.apiValue);

  final String apiValue;

  static FavouriteKind fromApi(String? value) =>
      value == pack.apiValue ? pack : service;
}

/// A service or a pack, as something to save.
class FavouriteTarget {
  const FavouriteTarget.service(this.id) : kind = FavouriteKind.service;
  const FavouriteTarget.pack(this.id) : kind = FavouriteKind.pack;

  final FavouriteKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is FavouriteTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '${kind.apiValue}:$id';
}

/// One saved item — a row on screen 17.
class Favourite {
  const Favourite({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.title,
    required this.providerName,
    required this.fromPrice,
    required this.avgRating,
    required this.ratingCount,
    required this.available,
    required this.createdAt,
    this.category,
    this.coverUrl,
  });

  factory Favourite.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? category = readObject(json, 'category');
    return Favourite(
      id: json['id']! as String,
      kind: FavouriteKind.fromApi(json['kind'] as String?),
      targetId: json['targetId']! as String,
      title: LocalizedText.read(json, 'title'),
      providerName: readString(json, 'providerName'),
      category: category == null ? null : CategoryRef.fromJson(category),
      fromPrice: readString(json, 'fromPrice'),
      coverUrl: readStringOrNull(json, 'coverUrl'),
      avgRating: readDecimal(json, 'avgRating'),
      ratingCount: readInt(json, 'ratingCount'),
      available: json['available'] as bool? ?? true,
      createdAt: readDate(json, 'createdAt'),
    );
  }

  /// The favourite row's own id — what DELETE takes.
  final String id;
  final FavouriteKind kind;
  final String targetId;
  final LocalizedText title;
  final String providerName;
  final CategoryRef? category;
  final String fromPrice;

  /// 320 px.
  final String? coverUrl;
  final String avgRating;
  final int ratingCount;

  /// `false` once the service or pack stopped being listed. The row stays,
  /// greyed out, so the list never shrinks without a word.
  final bool available;
  final DateTime createdAt;

  FavouriteTarget get target => kind == FavouriteKind.pack
      ? FavouriteTarget.pack(targetId)
      : FavouriteTarget.service(targetId);
}
