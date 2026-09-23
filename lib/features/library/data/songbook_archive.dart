import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/core/files/song_files.dart';

/// The whole songbook as a `.zip` of `.cho` files, and reading songs back
/// from such a zip or a single song file (docs/SONG_FORMAT.md § Files).
abstract final class SongbookArchive {
  /// A zip with one `<title>.cho` per song. Same titles get " (2)", " (3)"…
  static Uint8List export(Iterable<({String title, String body})> songs) {
    final archive = Archive();
    final used = <String>{};
    for (final song in songs) {
      final base = SongFiles.fileNameFor(song.title);
      var name = '$base.cho';
      for (var n = 2; !used.add(name.toLowerCase()); n++) {
        name = '$base ($n).cho';
      }
      archive.add(ArchiveFile.bytes(name, SongFiles.encode(song.body)));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// Most songs read from one zip, and most text unpacked from it: generous
  /// for a real songbook, and a stop for "zip bombs" that unpack to gigabytes.
  static const int maxEntries = 5000;
  static const int maxUnpackedBytes = 64 * 1024 * 1024;

  /// The songs (ChordPro, ready to save) in a file named [name]: every song
  /// file inside a `.zip`, or the file itself. Throws [FormatException] for
  /// anything else, including a damaged zip, and [FileTooBigException] for
  /// files past the size limits. Songs in a zip over [SongFiles.maxSongBytes]
  /// are skipped; sizes are checked before anything is unpacked.
  static List<String> songsFrom(String name, List<int> bytes) {
    if (name.toLowerCase().endsWith('.zip')) {
      // Every zip starts with "PK"; the decoder takes garbage for an empty
      // archive otherwise.
      final Archive archive;
      try {
        if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
          throw const FormatException();
        }
        archive = ZipDecoder().decodeBytes(bytes);
      } on Object {
        throw FormatException('Not a readable zip', name);
      }
      final songs = [
        for (final file in archive)
          if (file.isFile &&
              _isSong(file.name) &&
              file.size <= SongFiles.maxSongBytes)
            file,
      ];
      final unpacked = songs.fold(0, (total, f) => total + f.size);
      if (songs.length > maxEntries || unpacked > maxUnpackedBytes) {
        throw FileTooBigException(name);
      }
      return [
        for (final file in songs)
          // The declared size can lie; check what actually came out too.
          if (file.content case final content
              when content.length <= SongFiles.maxSongBytes)
            bodyFrom(file.name, SongFiles.decode(content)),
      ];
    }
    if (!SongFiles.isSongFile(name)) {
      throw FormatException('Not a song file', name);
    }
    if (bytes.length > SongFiles.maxSongBytes) throw FileTooBigException(name);
    return [bodyFrom(name, SongFiles.decode(bytes))];
  }

  /// A song file's text as ChordPro. Chords-over-lyrics is converted, and a
  /// song without a `{title}` is named after its file.
  static String bodyFrom(String fileName, String text) {
    final header = SongHeader.split(ChordSheetImporter.convert(text).chordPro);
    if (header.title.isNotEmpty) return header.compose();
    return SongHeader(
      title: _titleFromFileName(fileName),
      artist: header.artist,
      content: header.content,
    ).compose();
  }

  /// Song files in a zip, leaving out the metadata macOS adds (`__MACOSX/`,
  /// `._name`).
  static bool _isSong(String path) {
    final name = path.split('/').last;
    return !path.startsWith('__MACOSX/') &&
        !name.startsWith('._') &&
        SongFiles.isSongFile(name);
  }

  static String _titleFromFileName(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    final title = (dot > 0 ? name.substring(0, dot) : name)
        .replaceAll(RegExp('[_-]+'), ' ')
        .trim();
    return title.isEmpty ? 'Song' : title;
  }
}
