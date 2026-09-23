import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/duplicates.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  group('matching', () {
    test(
      'titles and artists ignore case, accents, spacing and punctuation',
      () {
        expect(
          Duplicates.nameKey('  Cielito  Lindo. '),
          Duplicates.nameKey('cielito lindo'),
        );
        expect(Duplicates.nameKey('Canción'), Duplicates.nameKey('CANCION'));
        expect(
          Duplicates.nameKey('Oh! Susanna'),
          isNot(Duplicates.nameKey('Oh Susannah')),
        );
      },
    );

    test('text ignores line endings, trailing spaces, blank lines and '
        'directive spelling', () {
      const a = '{title: Grace}\n\n[G]Amazing grace\n\n\n[C]how sweet';
      const b = '{T:Grace}  \r\n\r\n[G]Amazing grace   \r\n\r\n[C]how sweet\n';
      expect(Duplicates.bodyKey(a), Duplicates.bodyKey(b));
    });

    test('a different chord or word is a different text', () {
      const a = '{title: Grace}\n[G]Amazing grace';
      expect(
        Duplicates.bodyKey(a),
        isNot(Duplicates.bodyKey('{title: Grace}\n[A]Amazing grace')),
      );
      expect(
        Duplicates.bodyKey(a),
        isNot(Duplicates.bodyKey('{title: Grace}\n[G]Amazing  grace')),
      );
    });
  });

  group('in the songbook', () {
    late AppDatabase db;
    late SongRepository songs;
    late SetlistRepository setlists;

    setUp(() {
      db = testDatabase();
      songs = SongRepository(db);
      setlists = SetlistRepository(db);
    });
    tearDown(() => db.close());

    const grace = SampleSongs.amazingGrace;
    // Same song, typed a little differently.
    final graceCopy = '${grace.replaceAll('\n', '\r\n')}\n\n';
    // Same title and artist, another arrangement.
    final graceInA = grace.replaceAll('[G]', '[A]');

    test('finds exact copies and different versions', () async {
      await songs.addSong(grace); // 1
      await songs.addSong(graceCopy); // 2
      await songs.addSong(graceInA); // 3
      await songs.addSong(SampleSongs.ohSusanna); // 4

      final groups = await songs.findDuplicates();
      final copies = groups.singleWhere((g) => g.identical);
      final versions = groups.singleWhere((g) => !g.identical);
      expect([for (final s in copies.songs) s.id], [1, 2]);
      expect([for (final s in versions.songs) s.id], [1, 3]);
    });

    test('no duplicates, no groups', () async {
      await songs.addSong(grace);
      await songs.addSong(SampleSongs.ohSusanna);
      expect(await songs.findDuplicates(), isEmpty);
    });

    test(
      'keeps the favorite, then the one in setlists, then the oldest',
      () async {
        await songs.addSong(grace); // 1
        await songs.addSong(graceCopy); // 2
        await songs.addSong(graceCopy); // 3
        expect((await songs.findDuplicates()).single.keeper.id, 1);

        final friday = await setlists.create('Friday');
        await setlists.addSong(friday, 3);
        expect((await songs.findDuplicates()).single.keeper.id, 3);

        await songs.setFavorite(2, favorite: true);
        expect((await songs.findDuplicates()).single.keeper.id, 2);
      },
    );

    test('removing copies keeps their favorite and setlist places', () async {
      await songs.addSong(grace); // 1, kept (oldest)
      await songs.addSong(graceCopy); // 2
      await songs.addSong(graceInA); // 3, another version: untouched
      final friday = await setlists.create('Friday');
      await setlists.setSongs(friday, [2]);
      await songs.setFavorite(2, favorite: true);
      // Now 2 is the favorite, so it's the one kept.
      var groups = await songs.findDuplicates();
      expect(groups.firstWhere((g) => g.identical).keeper.id, 2);

      await songs.setFavorite(2, favorite: false);
      final saturday = await setlists.create('Saturday');
      await setlists.setSongs(saturday, [1, 2]);
      await setlists.setSongs(friday, [2]);
      await songs.setFavorite(1, favorite: true);
      groups = await songs.findDuplicates();
      final before = await songs.removeCopies(groups);

      final left = [for (final s in await songs.allSongs()) s.id]..sort();
      expect(left, [1, 3]);
      expect((await songs.getSong(1))!.favorite, isTrue);
      expect(await setlists.songIds(friday), [1]); // took 2's place
      expect(await setlists.songIds(saturday), [1]); // no double entry

      await songs.undoRemoveCopies(before);
      final back = [for (final s in await songs.allSongs()) s.id]..sort();
      expect(back, [1, 2, 3]);
      expect(await setlists.songIds(friday), [2]);
      expect(await setlists.songIds(saturday), [1, 2]);
    });

    test('different versions are never removed', () async {
      await songs.addSong(grace);
      await songs.addSong(graceInA);
      final groups = await songs.findDuplicates();
      await songs.removeCopies(groups);
      expect(await songs.allSongs(), hasLength(2));
    });
  });
}
