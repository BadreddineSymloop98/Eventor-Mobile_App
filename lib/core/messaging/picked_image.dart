import 'dart:typed_data';

/// What is wrong with a [PickedImage] before it is uploaded.
enum ImageProblem { tooLarge, wrongType }

/// An image chosen from the gallery or camera, held in memory until it is
/// sent — the thread's attachment picker and the report sheet's evidence
/// upload both build one before calling the repository.
class PickedImage {
  const PickedImage({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  final String name;
  final Uint8List bytes;

  /// Lower-case, no dot — `'jpeg'`, not `'.JPG'`.
  final String extension;

  /// `null` when the image can be uploaded as-is. The type is checked
  /// first: a wrong type is worth saying even when the file is also too
  /// big, and there is no point weighing bytes the server would reject
  /// anyway.
  ImageProblem? validate({required int maxMb, required List<String> types}) {
    // 'jpg' is the same format as 'jpeg' to every camera roll and photo
    // picker; the allowed-types list only ever spells the latter.
    final String normalized =
        extension.toLowerCase() == 'jpg' ? 'jpeg' : extension.toLowerCase();
    final bool typeOk =
        types.map((String type) => type.toLowerCase()).contains(normalized);
    if (!typeOk) return ImageProblem.wrongType;

    final int maxBytes = maxMb * 1024 * 1024;
    if (bytes.length > maxBytes) return ImageProblem.tooLarge;

    return null;
  }
}
