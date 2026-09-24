import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/application/song_order.dart';

SongEntry song(
  int id,
  String title, {
  String artist = '',
  int played = 0,
  DateTime? opened,
}) => SongEntry(
  id: id,
  title: title,
  artist: artist,
  body: '{title: $title}',
  favorite: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  playCount: played,
  lastOpenedAt: opened,
);

List<String> titles(List<SongEntry> songs) => [for (final s in songs) s.title];

void main() {
  test('A–Z ignores case, accents and leading punctuation', () {
    final songs = [
      song(1, 'Zamba'),
      song(2, '¡Ay, Jalisco!'),
      song(3, 'Ángel'),
      song(4, "'Twas the night"),
      song(5, 'amazing grace'),
    ];
    expect(titles(SongOrder.sort(songs, SongSort.title)), [
      'amazing grace',
      'Ángel',
      '¡Ay, Jalisco!',
      "'Twas the night",
      'Zamba',
    ]);
  });

  test('by artist, then title; no artist last', () {
    final songs = [
      song(1, 'B', artist: 'Traditional'),
      song(2, 'A'),
      song(3, 'C', artist: 'Álvarez'),
      song(4, 'A', artist: 'Traditional'),
    ];
    expect(SongOrder.sort(songs, SongSort.artist).map((s) => s.id), [
      3,
      4,
      1,
      2,
    ]);
  });

  test('recent: newest first, never opened last', () {
    final songs = [
      song(1, 'Never'),
      song(2, 'Old', opened: DateTime(2026, 9, 2)),
      song(3, 'New', opened: DateTime(2026, 9, 20)),
    ];
    expect(titles(SongOrder.sort(songs, SongSort.recent)), [
      'New',
      'Old',
      'Never',
    ]);
    expect(titles(SongOrder.recent(songs)), ['New', 'Old']);
    expect(SongOrder.recent(songs, limit: 1), hasLength(1));
  });

  test('most played first, ties by title', () {
    final songs = [
      song(1, 'Beta', played: 2),
      song(2, 'Alpha', played: 2),
      song(3, 'Gamma', played: 7),
      song(4, 'Delta'),
    ];
    expect(titles(SongOrder.sort(songs, SongSort.mostPlayed)), [
      'Gamma',
      'Alpha',
      'Beta',
      'Delta',
    ]);
  });

  test('index letters', () {
    expect(SongOrder.letter(song(1, 'Ángel'), SongSort.title), 'A');
    expect(SongOrder.letter(song(1, '¡Ay!'), SongSort.title), 'A');
    expect(SongOrder.letter(song(1, '99 Luftballons'), SongSort.title), '#');
    expect(SongOrder.letter(song(1, 'Ñandú'), SongSort.title), 'N');
    expect(
      SongOrder.letter(song(1, 'Zamba', artist: 'Mercedes'), SongSort.artist),
      'M',
    );
    expect(SongOrder.letter(song(1, 'Zamba'), SongSort.artist), '#');
  });
}
