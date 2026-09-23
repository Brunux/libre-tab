import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opening and sharing song files. Behind a provider so tests can fake it.
final songFilesProvider = Provider<SongFiles>((ref) => const SongFiles());

class SongFiles {
  const SongFiles();

  /// The biggest song file read. Real songs are a few KB; the limit keeps a
  /// huge or crafted file from freezing the app (docs/SONG_FORMAT.md § Files).
  static const int maxSongBytes = 256 * 1024;

  /// The biggest file Import songs reads (a songbook .zip).
  static const int maxImportBytes = 32 * 1024 * 1024;

  /// Extensions accepted as songs (docs/SONG_FORMAT.md § Files).
  static const extensions = {'cho', 'chopro', 'chordpro', 'crd', 'txt'};

  /// Lets the user pick a song file and returns its text, or null if they
  /// cancelled. Throws [FormatException] for files that aren't songs.
  Future<String?> pickSongText() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if (!isSongFile(file.name)) {
      throw FormatException('Not a song file', file.name);
    }
    if ((await file.length() ?? 0) > maxSongBytes) {
      throw FileTooBigException(file.name);
    }
    return decode(await file.xFile.readAsBytes());
  }

  /// Whether [fileName] has one of the song [extensions].
  static bool isSongFile(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot >= 0 &&
        extensions.contains(fileName.substring(dot + 1).toLowerCase());
  }

  /// A song file's text. Songs are UTF-8; stray bytes don't stop the import.
  static String decode(List<int> bytes) =>
      utf8.decode(bytes, allowMalformed: true);

  static Uint8List encode(String text) => utf8.encode(text);

  /// Lets the user pick any file (for Import songs); null if cancelled.
  Future<({String name, Uint8List bytes})?> pickFile() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if ((await file.length() ?? 0) > maxImportBytes) {
      throw FileTooBigException(file.name);
    }
    return (name: file.name, bytes: await file.xFile.readAsBytes());
  }

  /// Shares a songbook export ([zip]) through the system share sheet.
  Future<void> shareSongbook(Uint8List zip, {required String fileName}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(zip, mimeType: 'application/zip')],
          fileNameOverrides: [fileName],
        ),
      );

  /// Shares the song as a `.cho` file through the system share sheet.
  Future<void> share({required String title, required String body}) =>
      SharePlus.instance.share(
        ShareParams(
          subject: title,
          files: [XFile.fromData(encode(body), mimeType: 'text/plain')],
          fileNameOverrides: ['${fileNameFor(title)}.cho'],
        ),
      );

  /// A file name made from a song title: characters that file systems
  /// reject are removed.
  static String fileNameFor(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
        .trim();
    return cleaned.isEmpty ? 'song' : cleaned;
  }
}

/// A file over the size limits in [SongFiles].
class FileTooBigException implements Exception {
  const FileTooBigException(this.name);

  final String name;

  @override
  String toString() => 'FileTooBigException: $name';
}
