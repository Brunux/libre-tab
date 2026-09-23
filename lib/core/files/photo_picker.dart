import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Taking or choosing a photo of a song sheet. Behind a provider so tests
/// can fake it.
final photoPickerProvider = Provider<PhotoPicker>((ref) => const PhotoPicker());

enum PhotoSource { camera, library }

class PhotoPicker {
  const PhotoPicker();

  /// The largest side text recognition needs; bigger photos are scaled down
  /// (which also turns them upright).
  static const maxSide = 3000.0;

  /// The photo's file path, or null if the user cancelled. The library uses
  /// the system photo picker, which needs no permission and shares only the
  /// photo picked.
  Future<String?> pick(PhotoSource source) async {
    final photo = await ImagePicker().pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.library => ImageSource.gallery,
      },
      maxWidth: maxSide,
      maxHeight: maxSide,
      requestFullMetadata: false,
    );
    return photo?.path;
  }
}
