import 'package:file_picker/file_picker.dart';

import '../messaging/picked_image.dart';

/// Opens the gallery for one photo; `null` if the user backed out.
///
/// A function, like [DocumentPicker], so the chat screen can be tested with
/// a fake one and no platform channel.
typedef PhotoPicker = Future<PickedImage?> Function();

/// The real picker: the gallery only, no camera (decision 3). The type and
/// size are checked afterwards against the server's limits, whatever the
/// platform filter let through.
Future<PickedImage?> pickChatPhoto() async {
  final PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
  if (file == null) return null;
  return PickedImage(
    name: file.name,
    bytes: await file.readAsBytes(),
    extension: file.extension?.toLowerCase() ?? '',
  );
}
