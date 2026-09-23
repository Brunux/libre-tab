import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SongRepository repo;

  setUp(() {
    db = testDatabase();
    repo = SongRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> titles({String query = '', bool favorites = false}) =>
      repo
          .watchSongs(query: query, favoritesOnly: favorites)
          .first
          .then((songs) => songs.map((s) => s.title).toList());

  Future<void> addAll() async {
    await repo.addSong(SampleSongs.ohSusanna);
    await repo.addSong(SampleSongs.amazingGrace);
    await repo.addSong(SampleSongs.cancion);
  }

  group('adding', () {
    test('copies title, artist, key and capo out of the text', () async {
      final id = await repo.addSong(SampleSongs.ohSusanna);
      final song = (await repo.getSong(id))!;
      expect(song.title, 'Oh! Susanna');
      expect(song.artist, 'Stephen Foster');
      expect(song.songKey, 'C');
      expect(song.capo, 2);
      expect(song.body, SampleSongs.ohSusanna);
      expect(song.favorite, isFalse);
    });

    test('a song without {title} is refused and nothing is saved', () async {
      await expectLater(repo.addSong('[G]No title'), throwsArgumentError);
      await expectLater(repo.addSong('{title:   }\nLa'), throwsArgumentError);
      expect(await titles(), isEmpty);
    });

    test('missing artist and key are stored as empty / null', () async {
      final id = await repo.addSong('{title: Solo}\nLa la');
      final song = (await repo.getSong(id))!;
      expect(song.artist, '');
      expect(song.songKey, isNull);
      expect(song.capo, isNull);
    });
  });

  test('lists songs by title, ignoring case', () async {
    await addAll();
    await repo.addSong('{title: banjo blues}');
    expect(await titles(), [
      'Amazing Grace',
      'banjo blues',
      'Canción de cuna',
      'Oh! Susanna',
    ]);
  });

  test('favorites filter', () async {
    await addAll();
    final songs = await repo.watchSongs().first;
    final grace = songs.firstWhere((s) => s.title == 'Amazing Grace');
    await repo.setFavorite(grace.id, favorite: true);

    expect(await titles(favorites: true), ['Amazing Grace']);
    await repo.setFavorite(grace.id, favorite: false);
    expect(await titles(favorites: true), isEmpty);
  });

  group('search', () {
    setUp(addAll);

    test('by the start of a title word', () async {
      expect(await titles(query: 'amaz'), ['Amazing Grace']);
    });

    test('by artist', () async {
      expect(await titles(query: 'foster'), ['Oh! Susanna']);
    });

    test('by a word in the lyrics', () async {
      expect(await titles(query: 'wretch'), ['Amazing Grace']);
      expect(await titles(query: 'banjo'), ['Oh! Susanna']);
    });

    test('ignores accents both ways', () async {
      expect(await titles(query: 'cancion'), ['Canción de cuna']);
      expect(await titles(query: 'DUERMETE'), ['Canción de cuna']);
      expect(await titles(query: 'niño'), ['Canción de cuna']);
    });

    test('every word must match', () async {
      expect(await titles(query: 'grace sweet'), ['Amazing Grace']);
      expect(await titles(query: 'grace banjo'), isEmpty);
    });

    test('chords are not searchable', () async {
      expect(await titles(query: 'G7'), isEmpty);
    });

    test('title matches rank above lyric matches', () async {
      await repo.addSong('{title: Sweet Home}\nLa la');
      expect(await titles(query: 'sweet'), ['Sweet Home', 'Amazing Grace']);
    });

    test('blank or punctuation-only search lists everything', () async {
      expect(await titles(query: '  '), hasLength(3));
      expect(await titles(query: '!!! "'), hasLength(3));
    });

    test('combines with the favorites filter', () async {
      final grace = (await repo.watchSongs(query: 'grace').first).single;
      await repo.setFavorite(grace.id, favorite: true);
      expect(await titles(query: 'a', favorites: true), ['Amazing Grace']);
    });
  });

  test('update changes the text and the search index', () async {
    final id = await repo.addSong(SampleSongs.amazingGrace);
    final before = (await repo.getSong(id))!;

    await repo.updateSong(
      id,
      '{title: Graceful}\n{key: A}\n\n[A]New words entirely',
    );

    final after = (await repo.getSong(id))!;
    expect(after.title, 'Graceful');
    expect(after.artist, '');
    expect(after.songKey, 'A');
    expect(after.updatedAt.isBefore(before.createdAt), isFalse);
    expect(await titles(query: 'wretch'), isEmpty);
    expect(await titles(query: 'entirely'), ['Graceful']);
  });

  test('delete removes the song and its search entry', () async {
    final id = await repo.addSong(SampleSongs.amazingGrace);
    await repo.deleteSong(id);
    expect(await repo.getSong(id), isNull);
    expect(await titles(query: 'grace'), isEmpty);
    final leftover = await db
        .customSelect('SELECT count(*) AS n FROM songs_fts')
        .getSingle();
    expect(leftover.read<int>('n'), 0);
  });

  test('the list stream updates when songs change', () async {
    final stream = repo.watchSongs().map((l) => l.map((s) => s.title).toList());
    final expectation = expectLater(
      stream,
      emitsInOrder([
        isEmpty,
        ['Amazing Grace'],
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    await repo.addSong(SampleSongs.amazingGrace);
    await expectation;
  });

  test('watchSong emits null after delete', () async {
    final id = await repo.addSong(SampleSongs.amazingGrace);
    final expectation = expectLater(
      repo.watchSong(id).map((s) => s?.title),
      emitsInOrder(['Amazing Grace', isNull]),
    );
    await Future<void>.delayed(Duration.zero);
    await repo.deleteSong(id);
    await expectation;
  });

  group('ftsQuery', () {
    test('quotes each word as a prefix', () {
      expect(SongRepository.ftsQuery('Amazing  grace'), '"amazing"* "grace"*');
    });

    test('drops FTS syntax so input cannot break the query', () {
      expect(
        SongRepository.ftsQuery('AC/DC "x" -y *z'),
        '"ac"* "dc"* "x"* "y"* "z"*',
      );
      expect(SongRepository.ftsQuery('NOT OR'), '"not"* "or"*');
    });

    test('keeps letters with accents', () {
      expect(SongRepository.ftsQuery('Canción'), '"canción"*');
    });

    test('null when there is nothing to search', () {
      expect(SongRepository.ftsQuery(''), isNull);
      expect(SongRepository.ftsQuery(' ¡! '), isNull);
    });
  });
}
