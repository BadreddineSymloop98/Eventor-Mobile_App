import '../../catalog/models/json_read.dart';

/// Where an uploaded photo stands on the server — `PhotoDto.processingStatus`.
///
/// The server turns every upload into WebP variants in a background job, so
/// a photo is briefly `pending` (P8's "Processing" badge) before it is
/// `ready`; `failed` means the job gave up on the file.
enum PhotoProcessing {
  pending,
  ready,
  failed;

  static PhotoProcessing fromApi(String? value) => switch (value) {
        'pending' => pending,
        'failed' => failed,
        _ => ready,
      };
}

/// One photo of a provider's own service or pack, as the edit routes send it
/// — with its place in the gallery, which the catalog's [Photo] does not
/// carry.
class CatalogPhoto {
  const CatalogPhoto({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.position,
    required this.isCover,
    this.processing = PhotoProcessing.ready,
  });

  factory CatalogPhoto.fromJson(Map<String, Object?> json) => CatalogPhoto(
        id: json['id']! as String,
        url: readString(json, 'url'),
        // The variants lag behind a fresh upload; the full image is the
        // fallback until the thumb exists.
        thumbUrl: readStringOrNull(json, 'thumbUrl') ??
            readStringOrNull(json, 'mediumUrl') ??
            readString(json, 'url'),
        position: readInt(json, 'position'),
        isCover: readBool(json, 'isCover'),
        processing: PhotoProcessing.fromApi(json['processingStatus'] as String?),
      );

  final String id;
  final String url;

  /// 320 px — what a grid tile needs.
  final String thumbUrl;

  /// 0 is the cover.
  final int position;
  final bool isCover;
  final PhotoProcessing processing;
}

/// A gallery as the photo routes answer: the whole list, cover first — the
/// server's order is the order.
List<CatalogPhoto> readPhotos(Object? data) => <CatalogPhoto>[
      if (data is List<Object?>)
        for (final Map<String, Object?> row
            in data.whereType<Map<String, Object?>>())
          CatalogPhoto.fromJson(row),
    ];
