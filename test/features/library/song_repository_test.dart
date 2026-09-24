import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
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

  test('opening a song counts it and stamps when, not as an edit', () async {
    final id = await repo.addSong(SampleSongs.amazingGrace);
    final before = (await repo.getSong(id))!;
    expect(before.playCount, 0);
    expect(before.lastOpenedAt, isNull);

    await repo.recordOpened(id);
    await repo.recordOpened(id);
    final after = (await repo.getSong(id))!;
    expect(after.playCount, 2);
    expect(after.lastOpenedAt, isNotNull);
    expect(after.updatedAt, before.updatedAt);
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

  test("apostrophes don't matter: dont, don't and don’t all match", () async {
    await repo.addSong(
      "{title: Oh! Susanna}\n[F]Oh! Susanna, oh don't you cry for me",
    );
    for (final query in ['dont', "don't", 'don’t', 'DONT CRY']) {
      expect(await titles(query: query), ['Oh! Susanna'], reason: query);
    }
  });

  test('a songbook of 1000 songs lists and searches quickly', () async {
    await db.transaction(() async {
      for (var i = 0; i < 1000; i++) {
        await repo.addSong(
          '{title: Song $i}\n{artist: Band ${i % 50}}\n'
          '[G]Words for song number $i, [C]sung around the fire',
        );
      }
    });

    Future<(int, int)> timed(String query) async {
      final watch = Stopwatch()..start();
      final songs = await repo.watchSongs(query: query).first;
      return (songs.length, watch.elapsedMilliseconds);
    }

    final (all, listTime) = await timed('');
    final (one, oneTime) = await timed('number 999');
    // Worst case: every song matches and has to be ranked.
    final (broad, broadTime) = await timed('fire');

    expect(all, 1000);
    expect(one, 1);
    expect(broad, 1000);
    expect(listTime, lessThan(300));
    expect(oneTime, lessThan(300));
    expect(broadTime, lessThan(300));
  });

  group('delete and undo', () {
    test('delete all, then restore: same ids, searchable, same setlist '
        'places', () async {
      await addAll(); // ids 1, 2, 3
      final setlists = SetlistRepository(db);
      final friday = await setlists.create('Friday');
      await setlists.setSongs(friday, [3, 1, 2]);
      await repo.setFavorite(2, favorite: true);

      final deleted = await repo.deleteAllSongs();
      expect(deleted.count, 3);
      expect(await repo.allSongs(), isEmpty);
      expect(await titles(query: 'wretch'), isEmpty);
      expect(await setlists.songIds(friday), isEmpty);

      await repo.restore(deleted);
      expect([for (final s in await repo.allSongs()) s.id], [2, 3, 1]);
      expect((await repo.getSong(2))!.favorite, isTrue);
      expect(await titles(query: 'wretch'), ['Amazing Grace']);
      expect(await setlists.songIds(friday), [3, 1, 2]);
    });

    test('restoring skips setlists deleted in the meantime', () async {
      await addAll();
      final setlists = SetlistRepository(db);
      final gone = await setlists.create('Gone');
      final kept = await setlists.create('Kept');
      await setlists.setSongs(gone, [1]);
      await setlists.setSongs(kept, [1]);

      final deleted = await repo.deleteSong(1);
      await setlists.delete(gone);
      await repo.restore(deleted);

      expect(await repo.getSong(1), isNotNull);
      expect(await setlists.songIds(kept), [1]);
    });

    test('deleting from an empty songbook is fine', () async {
      final deleted = await repo.deleteAllSongs();
      expect(deleted.count, 0);
      await repo.restore(deleted);
      expect(await repo.allSongs(), isEmpty);
    });
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
