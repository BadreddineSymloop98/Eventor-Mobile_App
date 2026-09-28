import 'package:flutter/services.dart';

import '../errors/failure.dart';

/// A file the app saved where the user keeps their own files.
class SavedFile {
  const SavedFile({required this.name, this.uri});

  /// The name it was saved under — the platform may have numbered it,
  /// `INV-2026-0142 (1).pdf`, when one by that name was already there.
  final String name;

  /// What [DeviceFiles.open] hands to the viewer: a `content://` URI on
  /// Android, a `file://` URL on iOS. `null` when the platform could not
  /// say, and the file can then only be found in Downloads / Files.
  final String? uri;
}

/// The system notification posted once a file is saved (Android only; iOS
/// apps do not announce their own downloads). Already in the app's language.
class DownloadNotice {
  const DownloadNotice({required this.channelName, required this.text});

  /// The notification category the user sees in system settings.
  final String channelName;

  /// Under the file's name: "Download complete · Tap to open".
  final String text;
}

/// The user refused the storage permission (Android 9 and older only — later
/// versions need none to write into Downloads).
class SavePermissionDenied implements Exception {
  const SavePermissionDenied();
}

/// Saving a file onto the device, and opening it again.
///
/// An interface so a view model can be tested without a platform channel.
abstract interface class DeviceFiles {
  /// Saves [bytes] as a PDF called [fileName]: into the public Downloads
  /// folder on Android, into the app's folder in the Files app on iOS.
  ///
  /// With a [notice], Android also posts it in the notification shade; the
  /// file is returned without waiting for that.
  ///
  /// Throws [SavePermissionDenied] when the user refused, and a
  /// [StorageFailure] for anything else.
  Future<SavedFile> savePdf(Uint8List bytes, String fileName, {DownloadNotice? notice});

  /// Opens [file] in the device's PDF viewer. `false` when nothing on the
  /// device can show a PDF.
  Future<bool> open(SavedFile file);
}

/// [DeviceFiles] over the `eventor/downloads` channel, implemented in
/// `MainActivity.kt` (MediaStore) and `AppDelegate.swift` (Documents +
/// Quick Look).
class PlatformDeviceFiles implements DeviceFiles {
  const PlatformDeviceFiles();

  static const MethodChannel _channel = MethodChannel('eventor/downloads');

  @override
  Future<SavedFile> savePdf(Uint8List bytes, String fileName, {DownloadNotice? notice}) async {
    try {
      final Map<Object?, Object?>? saved = await _channel.invokeMapMethod<Object?, Object?>(
        'savePdf',
        <String, Object>{
          'bytes': bytes,
          'name': fileName,
          if (notice != null)
            'notice': <String, String>{'channel': notice.channelName, 'text': notice.text},
        },
      );
      return SavedFile(
        name: saved?['name'] as String? ?? fileName,
        uri: saved?['uri'] as String?,
      );
    } on PlatformException catch (error) {
      if (error.code == 'denied') throw const SavePermissionDenied();
      throw StorageFailure(cause: error);
    } on MissingPluginException catch (error) {
      throw StorageFailure(cause: error);
    }
  }

  @override
  Future<bool> open(SavedFile file) async {
    final String? uri = file.uri;
    if (uri == null) return false;
    try {
      return await _channel.invokeMethod<bool>('open', <String, String>{'uri': uri}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
