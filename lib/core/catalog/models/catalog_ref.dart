import 'json_read.dart';

/// A category as embedded in a service, pack or favourite.
class CategoryRef {
  const CategoryRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
  });

  factory CategoryRef.fromJson(Map<String, Object?> json) => CategoryRef(
        id: json['id']! as String,
        slug: readString(json, 'slug'),
        name: LocalizedText.read(json, 'name'),
        icon: readString(json, 'icon'),
      );

  final String id;
  final String slug;
  final LocalizedText name;

  /// The server's icon name — `camera`, `catering` — mapped to a glyph by
  /// the view.
  final String icon;

  @override
  bool operator ==(Object other) => other is CategoryRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A category as listed on its own — Home's rail, search's browse list.
class CategoryWithCount extends CategoryRef {
  const CategoryWithCount({
    required super.id,
    required super.slug,
    required super.name,
    required super.icon,
    required this.position,
    required this.servicesCount,
  });

  factory CategoryWithCount.fromJson(Map<String, Object?> json) {
    final CategoryRef ref = CategoryRef.fromJson(json);
    return CategoryWithCount(
      id: ref.id,
      slug: ref.slug,
      name: ref.name,
      icon: ref.icon,
      position: readInt(json, 'position'),
      servicesCount: readInt(json, 'servicesCount'),
    );
  }

  final int position;

  /// Visible services in the category — "Photography · 42 services".
  final int servicesCount;
}
