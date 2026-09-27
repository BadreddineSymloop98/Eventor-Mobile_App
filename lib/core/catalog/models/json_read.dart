/// Small, forgiving readers for the API's JSON, shared by the catalog models.
///
/// Defensive in the same way as `account.dart`: a missing optional field
/// reads as its empty value rather than throwing, so one odd row cannot take
/// a whole list down. Required ids still throw — a row without one is not a
/// row the app can do anything with.
library;

String readString(Map<String, Object?> json, String key) =>
    json[key] as String? ?? '';

String? readStringOrNull(Map<String, Object?> json, String key) {
  final String? value = json[key] as String?;
  return value == null || value.isEmpty ? null : value;
}

int readInt(Map<String, Object?> json, String key) =>
    (json[key] as num?)?.toInt() ?? 0;

int? readIntOrNull(Map<String, Object?> json, String key) =>
    (json[key] as num?)?.toInt();

num readNum(Map<String, Object?> json, String key) => json[key] as num? ?? 0;

bool readBool(Map<String, Object?> json, String key) =>
    json[key] as bool? ?? false;

/// An ISO date or date-time, in local time. `2026-03-14` is local midnight.
DateTime readDate(Map<String, Object?> json, String key) =>
    readDateOrNull(json, key) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? readDateOrNull(Map<String, Object?> json, String key) {
  final String? value = json[key] as String?;
  return value == null ? null : DateTime.tryParse(value)?.toLocal();
}

Map<String, Object?>? readObject(Map<String, Object?> json, String key) =>
    json[key] as Map<String, Object?>?;

List<T> readList<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> item) parse,
) {
  final Object? value = json[key];
  if (value is! List<Object?>) return <T>[];
  return value.whereType<Map<String, Object?>>().map(parse).toList();
}

List<String> readStrings(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! List<Object?>) return <String>[];
  return value.whereType<String>().toList();
}

/// Text the API sends in both languages — `title`, `titleEn`, `titleAr`.
///
/// Both are kept and the app picks one, like `Wilaya.nameFor`: switching
/// language then needs no reload, and a blank Arabic value (live data has
/// some) falls back to English instead of an empty line.
class LocalizedText {
  const LocalizedText({required this.en, this.ar = ''});

  /// Reads `<key>En` / `<key>Ar`, falling back to the server-resolved `<key>`.
  factory LocalizedText.read(Map<String, Object?> json, String key) {
    final String resolved = readString(json, key);
    return LocalizedText(
      en: readStringOrNull(json, '${key}En') ?? resolved,
      ar: readStringOrNull(json, '${key}Ar') ?? '',
    );
  }

  /// `null` when the API sent nothing in either language.
  static LocalizedText? readOrNull(Map<String, Object?> json, String key) {
    final LocalizedText text = LocalizedText.read(json, key);
    return text.en.isEmpty && text.ar.isEmpty ? null : text;
  }

  final String en;
  final String ar;

  String of(String languageCode) =>
      languageCode == 'ar' && ar.isNotEmpty ? ar : en;

  /// Whether either language contains [query], ignoring case — the mock
  /// backend's search.
  bool contains(String query) {
    final String needle = query.toLowerCase();
    return en.toLowerCase().contains(needle) ||
        ar.toLowerCase().contains(needle);
  }
}
