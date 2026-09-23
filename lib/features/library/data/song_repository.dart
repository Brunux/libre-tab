import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/database/database_provider.dart';
import 'package:libre_tab/core/database/search_index.dart';

final songRepositoryProvider = Provider<SongRepository>(
  (ref) => SongRepository(ref.watch(appDatabaseProvider)),
);

/// Stores songs as ChordPro and keeps the search index in step with them.
class SongRepository {
  SongRepository(AppDatabase db) : _db = db;

  final AppDatabase _db;

  /// Songs sorted by title, or by relevance when [query] is given
  /// (title matches first, then artist, then lyrics).
  Stream<List<SongEntry>> watchSongs({
    String query = '',
    bool favoritesOnly = false,
  }) {
    final match = ftsQuery(query);
    if (match == null) {
      final select = _db.select(_db.songs)
        ..orderBy([(s) => OrderingTerm.asc(s.title.collate(Collate.noCase))]);
      if (favoritesOnly) select.where((s) => s.favorite.equals(true));
      return select.watch();
    }
    return _db
        .customSelect(
          'SELECT songs.* FROM songs '
          'JOIN songs_fts ON songs_fts.rowid = songs.id '
          'WHERE songs_fts MATCH ?1 '
          '${favoritesOnly ? 'AND songs.favorite = 1 ' : ''}'
          'ORDER BY bm25(songs_fts, 10.0, 5.0, 1.0), '
          'songs.title COLLATE NOCASE',
          variables: [Variable.withString(match)],
          readsFrom: {_db.songs},
        )
        .watch()
        .map((rows) => [for (final row in rows) _db.songs.map(row.data)]);
  }

  Stream<SongEntry?> watchSong(int id) => (_db.select(
    _db.songs,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  Future<SongEntry?> getSong(int id) =>
      (_db.select(_db.songs)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Saves a new song and returns its id. [body] must have a `{title}`.
  Future<int> addSong(String body) async {
    final meta = _SongMeta.fromBody(body);
    return _db.transaction(() async {
      final id = await _db
          .into(_db.songs)
          .insert(
            SongsCompanion.insert(
              title: meta.title,
              artist: Value(meta.artist),
              songKey: Value(meta.key),
              capo: Value(meta.capo),
              body: body,
            ),
          );
      await _index(id, meta);
      return id;
    });
  }

  /// Replaces a song's text. [body] must have a `{title}`.
  Future<void> updateSong(int id, String body) async {
    final meta = _SongMeta.fromBody(body);
    return _db.transaction(() async {
      await (_db.update(_db.songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion(
          title: Value(meta.title),
          artist: Value(meta.artist),
          songKey: Value(meta.key),
          capo: Value(meta.capo),
          body: Value(body),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _index(id, meta);
    });
  }

  Future<void> deleteSong(int id) => _db.transaction(() async {
    await (_db.delete(_db.songs)..where((s) => s.id.equals(id))).go();
    await SearchIndex.remove(_db, id);
  });

  /// Remembers the auto-scroll speed last used for a song.
  Future<void> setScrollSpeed(int id, int speed) =>
      (_db.update(_db.songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion(scrollSpeed: Value(speed)),
      );

  Future<void> setFavorite(int id, {required bool favorite}) =>
      (_db.update(_db.songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion(favorite: Value(favorite)),
      );

  Future<void> _index(int id, _SongMeta meta) => SearchIndex.put(
    _db,
    id,
    title: meta.title,
    artist: meta.artist,
    lyrics: meta.lyrics,
  );

  /// The FTS5 query for what the user typed (see [SearchIndex.query]).
  static String? ftsQuery(String input) => SearchIndex.query(input);
}

/// What gets copied out of the ChordPro text on save.
class _SongMeta {
  _SongMeta({
    required this.title,
    required this.artist,
    required this.key,
    required this.capo,
    required this.lyrics,
  });

  factory _SongMeta.fromBody(String body) {
    final song = ChordProParser.parse(body);
    final title = song.title?.trim() ?? '';
    if (title.isEmpty) {
      throw ArgumentError.value(body, 'body', 'needs a {title}');
    }
    return _SongMeta(
      title: title,
      artist: song.artist?.trim() ?? '',
      key: song.key?.name,
      capo: song.capo,
      lyrics: song.plainLyrics,
    );
  }

  final String title;
  final String artist;
  final String? key;
  final int? capo;
  final String lyrics;
}
