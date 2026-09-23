import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

@DriftDatabase(tables: [Songs])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'libre_tab'));

  @override
  int get schemaVersion => 1;

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
  );
}
