import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opening and sharing song files. Behind a provider so tests can fake it.
final songFilesProvider = Provider<SongFiles>((ref) => const SongFiles());

class SongFiles {
  const SongFiles();

  /// Extensions accepted as songs (docs/SONG_FORMAT.md § Files).
  static const extensions = {'cho', 'chopro', 'chordpro', 'crd', 'txt'};

  /// Lets the user pick a song file and returns its text, or null if they
  /// cancelled. Throws [FormatException] for files that aren't songs.
  Future<String?> pickSongText() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if (!extensions.contains(file.extension?.toLowerCase())) {
      throw FormatException('Not a song file', file.name);
    }
    return utf8.decode(await file.xFile.readAsBytes(), allowMalformed: true);
  }

  /// Shares the song as a `.cho` file through the system share sheet.
  Future<void> share({required String title, required String body}) =>
      SharePlus.instance.share(
        ShareParams(
          subject: title,
          files: [XFile.fromData(utf8.encode(body), mimeType: 'text/plain')],
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
