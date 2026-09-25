import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// A picked file with fixed contents.
final class _PickedFile extends PlatformFile {
  _PickedFile(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Uri get uri => Uri.parse('memory:///$name');
  @override
  XFile get xFile => XFile.fromData(bytes, name: name);
  @override
  int? lengthSync() => bytes.length;
  @override
  Future<int?> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

/// The system file picker, returning [file] (null = user cancelled).
class _FakePicker extends FilePickerPlatform {
  _FakePicker(this.file);

  final PlatformFile? file;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => file;
}

/// The system share sheet, remembering what it was given.
class _FakeShare extends SharePlatform {
  ShareParams? shared;

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared = params;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

Future<String?> pick(String name, List<int> bytes) {
  FilePickerPlatform.instance = _FakePicker(
    _PickedFile(name, Uint8List.fromList(bytes)),
  );
  return const SongFiles().pickSongText();
}

void main() {
  group('opening a song file', () {
    test('reads the text of every song file type', () async {
      for (final ext in ['cho', 'chopro', 'chordpro', 'crd', 'txt', 'CHO']) {
        final text = await pick('Song.$ext', utf8.encode('{title: Ñandú}'));
        expect(text, '{title: Ñandú}', reason: ext);
      }
    });

    test('returns null when the user cancels', () async {
      FilePickerPlatform.instance = _FakePicker(null);
      expect(await const SongFiles().pickSongText(), isNull);
    });

    test('refuses files that are not songs', () async {
      for (final name in ['photo.jpg', 'notes.pdf', 'no_extension']) {
        await expectLater(
          pick(name, [1, 2, 3]),
          throwsFormatException,
          reason: name,
        );
      }
    });

    test('survives text that is not valid UTF-8', () async {
      // A Latin-1 "ñ" (0xF1) is not valid UTF-8 on its own.
      final text = await pick('old.txt', [0x61, 0xF1, 0x62]);
      expect(text, startsWith('a'));
      expect(text, endsWith('b'));
    });
  });

  group('sharing a song', () {
    test('sends a .cho file named after the song, with its text', () async {
      final share = _FakeShare();
      SharePlatform.instance = share;

      await const SongFiles().share(
        title: 'Amazing Grace',
        body: '{title: Amazing Grace}\n[G]A-mazing',
      );

      final params = share.shared!;
      expect(params.subject, 'Amazing Grace');
      expect(params.fileNameOverrides, ['Amazing Grace.cho']);
      final file = params.files!.single;
      expect(file.mimeType, 'text/plain');
      expect(
        utf8.decode(await file.readAsBytes()),
        '{title: Amazing Grace}\n[G]A-mazing',
      );
    });

    test('file names drop characters file systems reject', () {
      expect(SongFiles.fileNameFor('AC/DC: "Hits"?'), 'ACDC Hits');
      expect(SongFiles.fileNameFor('Canción <de> cuna|*'), 'Canción de cuna');
      expect(SongFiles.fileNameFor(' ? '), 'song');
      // No way out of the folder the file is written to.
      expect(SongFiles.fileNameFor('../../etc/passwd'), '....etcpasswd');
      // Short enough for any file system (255 bytes), even in emoji.
      final long = SongFiles.fileNameFor('🎸' * 500);
      expect(long.runes.length, SongFiles.maxFileNameChars);
      expect(SongFiles.fileNameFor('Tab\there'), 'Tabhere');
    });
  });
}
