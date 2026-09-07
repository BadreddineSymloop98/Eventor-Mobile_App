import 'package:file_picker/file_picker.dart';

import '../constants/input_rules.dart';

/// A file the user chose for a document field.
///
/// Deliberately not `PlatformFile`: the view model has no business knowing
/// which package opened the picker, and a plain value is something a test can
/// make without a platform channel.
class DocumentFile {
  const DocumentFile({
    required this.name,
    required this.sizeInBytes,
    required this.extension,
    this.path,
  });

  /// What the file is called, shown in the field once it is attached.
  final String name;

  final int sizeInBytes;

  /// Lower-case and without the dot — `pdf`, `jpg`. Empty when the platform
  /// did not report one, which is treated as an unacceptable type rather than
  /// waved through.
  final String extension;

  /// Where it sits on disk, or `null` on the platforms that hand back bytes
  /// instead. Nothing reads it yet; it is what the upload will need.
  final String? path;
}

/// Opens the platform's file picker and returns what was chosen, or `null` if
/// the user backed out.
///
/// A function rather than an interface because there is exactly one thing to
/// do, and injecting it is how [RegisterViewModel] stays testable without a
/// platform channel.
typedef DocumentPicker = Future<DocumentFile?> Function();

/// The real picker, backed by `file_picker`.
///
/// The extension filter is passed to the platform so the browser opens on the
/// right files, but it is *not* trusted: some platforms ignore it, and a file
/// can always be renamed. Whatever comes back is validated again — see
/// [InputRules.isAcceptableDocument].
Future<DocumentFile?> pickDocumentFile() async {
  // One document per field, so this is `pickFile` rather than `pickFiles`.
  final PlatformFile? file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: InputRules.documentExtensions,
  );
  if (file == null) return null;

  return DocumentFile(
    name: file.name,
    // Most pickers report the size for free; `length()` falls back to reading
    // the file only on the platforms that do not. The bytes themselves are
    // deliberately not loaded — nothing needs them until there is an upload.
    sizeInBytes: await file.length(),
    extension: file.extension?.toLowerCase() ?? '',
    path: file.path,
  );
}
