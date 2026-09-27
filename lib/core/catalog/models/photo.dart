import 'json_read.dart';

/// One photo, in the three sizes the server renders.
///
/// The URLs are signed and expire after 15 minutes; see `AppNetworkImage`
/// for how they stay cached anyway.
class Photo {
  const Photo({
    required this.id,
    required this.thumbUrl,
    required this.mediumUrl,
    required this.largeUrl,
    this.width,
    this.height,
  });

  factory Photo.fromJson(Map<String, Object?> json) => Photo(
        id: json['id']! as String,
        thumbUrl: readString(json, 'thumbUrl'),
        mediumUrl: readString(json, 'mediumUrl'),
        largeUrl: readString(json, 'largeUrl'),
        width: readIntOrNull(json, 'width'),
        height: readIntOrNull(json, 'height'),
      );

  final String id;

  /// 320 px.
  final String thumbUrl;

  /// 800 px — what a phone-width carousel needs.
  final String mediumUrl;

  final String largeUrl;
  final int? width;
  final int? height;
}
