import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:libre_tab/core/database/search_index.dart';

part 'app_database.g.dart';

/// One row per song. [body] (ChordPro) is the source of truth; title,
/// artist, key and capo are copied out of it on save so the list doesn't
/// have to parse every song.
@DataClassName('SongEntry')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  TextColumn get songKey => text().nullable()();
  IntColumn get capo => integer().nullable()();
  TextColumn get body => text()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  /// Auto-scroll speed last used for this song (song view).
  IntColumn get scrollSpeed => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A named, ordered list of songs for a night ("Friday campfire").
@DataClassName('SetlistEntry')
class Setlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Which songs a setlist has, in [position] order (0, 1, 2…). Deleting a
/// setlist or a song removes its rows here.
@DataClassName('SetlistSongEntry')
class SetlistSongs extends Table {
  IntColumn get setlistId =>
      integer().references(Setlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId =>
      integer().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {setlistId, songId};
}

@DriftDatabase(tables: [Songs, Setlists, SetlistSongs])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'libre_tab'));

  /// 1: first release. 2: search index strips apostrophes (rebuilt).
  /// 3: setlists.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Full-text search over title, artist and lyrics. rowid = songs.id.
      // remove_diacritics lets "cancion" find "canción".
      await customStatement(
        'CREATE VIRTUAL TABLE songs_fts USING fts5(title, artist, lyrics, '
        "tokenize = 'unicode61 remove_diacritics 2')",
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await SearchIndex.rebuild(this);
      if (from < 3) {
        await m.createTable(setlists);
        await m.createTable(setlistSongs);
      }
    },
    // SQLite leaves foreign keys off unless asked, per connection.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
