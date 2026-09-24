import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/database/search_index.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';

import '../../helpers/test_database.dart';

/// Makes [db] look like a songbook saved at [version]: what later versions
/// added is taken away, so opening it again runs the upgrades from there.
Future<void> downgradeTo(AppDatabase db, int version) async {
  if (version < 4) {
    await db.customStatement('ALTER TABLE songs DROP COLUMN last_opened_at');
    await db.customStatement('ALTER TABLE songs DROP COLUMN play_count');
  }
  if (version < 3) {
    await db.customStatement('DROP TABLE setlist_songs');
    await db.customStatement('DROP TABLE setlists');
  }
  await db.customStatement('PRAGMA user_version = $version');
}

void main() {
  test('normalize removes every kind of apostrophe', () {
    expect(
      SearchIndex.normalize("don't don’t don‘t don`t don´t"),
      'dont dont dont dont dont',
    );
  });

  test('queries are normalised like the index', () {
    expect(SearchIndex.query("Don't"), '"dont"*');
    expect(SearchIndex.query('don’t cry'), '"dont"* "cry"*');
  });

  group('upgrading an existing songbook to schema 2', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('libre_tab_db'));
    tearDown(() => dir.deleteSync(recursive: true));

    AppDatabase open(File file) => AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );

    test('rebuilds the search index and keeps every song', () async {
      final file = File('${dir.path}/songs.sqlite');

      // A songbook saved by the first release: schema 1, and a search index
      // that still has the apostrophe in "don't".
      var db = open(file);
      await SongRepository(db).addSong(
        "{title: Oh! Susanna}\n[F]Oh! Susanna, oh don't you cry for me",
      );
      await db.customStatement('DELETE FROM songs_fts');
      await db.customStatement(
        'INSERT INTO songs_fts(rowid, title, artist, lyrics) '
        "VALUES (1, 'Oh! Susanna', '', 'Oh! Susanna, oh don''t you cry')",
      );
      await downgradeTo(db, 1);
      await db.close();

      // Opening it again runs the 1 → 2 migration.
      db = open(file);
      final repo = SongRepository(db);
      final titles = await repo
          .watchSongs(query: 'dont')
          .first
          .then((s) => s.map((e) => e.title).toList());
      expect(titles, ['Oh! Susanna']);
      expect(await repo.getSong(1), isNotNull);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 4);
      await db.close();
    });
  });

  test('upgrading from schema 2 adds setlists and keeps songs', () async {
    final dir = Directory.systemTemp.createTempSync('libre_tab_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/songs.sqlite');
    AppDatabase open() => AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );

    // A songbook from before setlists: no setlist tables, schema 2.
    var db = open();
    await SongRepository(db).addSong(SampleSongs.amazingGrace);
    await downgradeTo(db, 2);
    await db.close();

    db = open();
    addTearDown(db.close);
    final setlists = SetlistRepository(db);
    final id = await setlists.create('Friday');
    await setlists.addSong(id, 1);
    expect(await setlists.songIds(id), [1]);
  });

  test('upgrading from schema 3 fills in missing keys, adds history', () async {
    final dir = Directory.systemTemp.createTempSync('libre_tab_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/songs.sqlite');
    AppDatabase open() => AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );

    // Before 4 only a {key} line's key was kept: a pasted song had none.
    var db = open();
    final repo = SongRepository(db);
    await repo.addSong('{title: Pasted}\n[Am]One [F]two [C]three');
    await repo.addSong('{title: Keyed}\n{key: D}\n[G]Four');
    await db.customStatement('UPDATE songs SET song_key = NULL WHERE id = 1');
    await downgradeTo(db, 3);
    await db.close();

    db = open();
    addTearDown(db.close);
    final songs = SongRepository(db);
    expect((await songs.getSong(1))!.songKey, 'Am'); // from the first chord
    expect((await songs.getSong(2))!.songKey, 'D'); // its {key}, kept
    expect((await songs.getSong(1))!.playCount, 0);
    expect((await songs.getSong(1))!.lastOpenedAt, isNull);
  });

  test("a song without a {key} line gets its first chord's key", () async {
    final db = testDatabase();
    addTearDown(db.close);
    final songs = SongRepository(db);
    final id = await songs.addSong('{title: Pasted}\n[G]Row [C]row');
    expect((await songs.getSong(id))!.songKey, 'G');
  });

  test('a new database starts at schema 4 with an empty index', () async {
    final db = testDatabase();
    addTearDown(db.close);
    expect(db.schemaVersion, 4);
    final count = await db
        .customSelect('SELECT count(*) AS n FROM songs_fts')
        .getSingle();
    expect(count.read<int>('n'), 0);
  });
}
