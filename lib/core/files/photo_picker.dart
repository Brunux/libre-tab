import 'dart:io';

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

  /// Most photos read in one go (a song over several pages).
  static const maxPhotos = 10;

  /// The photos' file paths, in the order picked; empty if the user
  /// cancelled. The camera takes one; the library, which uses the system
  /// photo picker (no permission, shares only the photos picked), up to
  /// [maxPhotos].
  Future<List<String>> pick(PhotoSource source) async {
    switch (source) {
      case PhotoSource.camera:
        final photo = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: maxSide,
          maxHeight: maxSide,
          requestFullMetadata: false,
        );
        return [?photo?.path];
      case PhotoSource.library:
        final photos = await ImagePicker().pickMultiImage(
          maxWidth: maxSide,
          maxHeight: maxSide,
          limit: maxPhotos,
          requestFullMetadata: false,
        );
        return [for (final photo in photos) photo.path];
    }
  }

  /// Deletes the picker's copy of a photo once it's been read, so photos
  /// aren't kept (PRIVACY.md). It's always a copy, never the original.
  Future<void> discard(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
