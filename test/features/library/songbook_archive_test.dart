import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/features/library/data/songbook_archive.dart';

import '../../helpers/test_database.dart';

List<int> zipOf(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.add(ArchiveFile.bytes(key, utf8.encode(value)));
  }
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  test('export → import gives back the same songs', () {
    final songs = [
      (title: 'Amazing Grace', body: SampleSongs.amazingGrace),
      (title: 'Oh! Susanna', body: SampleSongs.ohSusanna),
      (title: 'Canción de cuna', body: SampleSongs.cancion),
    ];
    final zip = SongbookArchive.export(songs);

    final names = [for (final f in ZipDecoder().decodeBytes(zip)) f.name];
    expect(names, [
      'Amazing Grace.cho',
      'Oh! Susanna.cho',
      'Canción de cuna.cho',
    ]);

    final back = SongbookArchive.songsFrom('songs.zip', zip);
    expect(
      [for (final b in back) ChordProParser.parse(b).title],
      [
        'Amazing Grace',
        'Oh! Susanna',
        'Canción de cuna',
      ],
    );
    expect(back.first, contains('[G]mazing'));
  });

  test('songs with the same title get numbered file names', () {
    final zip = SongbookArchive.export([
      (title: 'Hymn', body: '{title: Hymn}'),
      (title: 'hymn', body: '{title: hymn}'),
      (title: 'A/B: C?', body: '{title: A/B: C?}'),
    ]);
    expect(
      [for (final f in ZipDecoder().decodeBytes(zip)) f.name],
      [
        'Hymn.cho',
        'hymn (2).cho',
        'AB C.cho',
      ],
    );
  });

  test('a zip import skips folders, macOS metadata and other files', () {
    final zip = zipOf({
      'songs/grace.cho': SampleSongs.amazingGrace,
      '__MACOSX/songs/._grace.cho': 'junk',
      'songs/._hidden.cho': 'junk',
      'songs/photo.jpg': 'not a song',
      'songs/campfire.txt': 'G       C\nHello campfire',
    });
    final songs = SongbookArchive.songsFrom('Export.ZIP', zip);
    expect(
      [for (final s in songs) ChordProParser.parse(s).title],
      [
        'Amazing Grace',
        'campfire',
      ],
    );
    expect(songs.last, contains('[G]Hello ca[C]mpfire'));
  });

  test('a single song file is one song; no title means the file name', () {
    final songs = SongbookArchive.songsFrom(
      'la_bamba-live.chopro',
      utf8.encode('[C]Para bailar la [F]bamba'),
    );
    expect(songs, hasLength(1));
    expect(ChordProParser.parse(songs.single).title, 'la bamba live');
  });

  test('anything else is a FormatException', () {
    expect(
      () => SongbookArchive.songsFrom('photo.jpg', [1, 2, 3]),
      throwsFormatException,
    );
    expect(
      () => SongbookArchive.songsFrom('broken.zip', [1, 2, 3]),
      throwsFormatException,
    );
  });
}
