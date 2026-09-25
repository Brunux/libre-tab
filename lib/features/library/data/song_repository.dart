import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/database/database_provider.dart';
import 'package:libre_tab/core/database/search_index.dart';
import 'package:libre_tab/features/library/data/duplicates.dart';
import 'package:meta/meta.dart';

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

  /// The song was opened: for "Recently played" and "Played 12×". Not an
  /// edit, so its updated time stays.
  Future<void> recordOpened(int id) =>
      (_db.update(_db.songs)..where((s) => s.id.equals(id))).write(
        SongsCompanion.custom(
          lastOpenedAt: Variable(DateTime.now()),
          playCount: _db.songs.playCount + const Constant(1),
        ),
      );

  Stream<SongEntry?> watchSong(int id) => (_db.select(
    _db.songs,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  Future<SongEntry?> getSong(int id) =>
      (_db.select(_db.songs)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Every song, by title.
  Future<List<SongEntry>> allSongs() => (_db.select(
    _db.songs,
  )..orderBy([(s) => OrderingTerm.asc(s.title.collate(Collate.noCase))])).get();

  /// Saves [bodies] as new songs, skipping any whose text is already in the
  /// songbook (importing the same export twice adds nothing). Returns how
  /// many were added.
  Future<int> importSongs(Iterable<String> bodies) => _db.transaction(() async {
    final existing = {for (final song in await allSongs()) song.body.trim()};
    var added = 0;
    for (final body in bodies) {
      if (!existing.add(body.trim())) continue;
      await addSong(body);
      added++;
    }
    return added;
  });

  /// Saves a new song and returns its id. [body] must have a `{title}`.
  Future<int> addSong(String body) async {
    final meta = _SongMeta.fromBody(body);
    return await _db.transaction(() async {
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
    return await _db.transaction(() async {
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

  /// Deletes a song (and takes it out of its setlists). The result can be
  /// passed to [restore] to undo it.
  Future<DeletedSongs> deleteSong(int id) => deleteSongs([id]);

  /// Deletes every song. The result can be passed to [restore] to undo it.
  Future<DeletedSongs> deleteAllSongs() async =>
      await deleteSongs([for (final song in await allSongs()) song.id]);

  Future<DeletedSongs> deleteSongs(List<int> ids) => _db.transaction(() async {
    final songs = await (_db.select(
      _db.songs,
    )..where((s) => s.id.isIn(ids))).get();
    final placements = await (_db.select(
      _db.setlistSongs,
    )..where((e) => e.songId.isIn(ids))).get();
    // Setlist rows go with the songs (foreign keys cascade).
    await (_db.delete(_db.songs)..where((s) => s.id.isIn(ids))).go();
    for (final id in ids) {
      await SearchIndex.remove(_db, id);
    }
    return DeletedSongs(songs: songs, placements: placements);
  });

  /// Puts deleted songs back, with the same ids and in the same places in
  /// their setlists (setlists deleted since are skipped).
  Future<void> restore(DeletedSongs deleted) => _db.transaction(() async {
    for (final song in deleted.songs) {
      await _db.into(_db.songs).insert(song, mode: InsertMode.insertOrReplace);
      await _index(song.id, _SongMeta.fromBody(song.body));
    }
    final setlists = {
      for (final s in await _db.select(_db.setlists).get()) s.id,
    };
    await _db.batch(
      (batch) => batch.insertAll(_db.setlistSongs, [
        for (final placement in deleted.placements)
          if (setlists.contains(placement.setlistId)) placement,
      ], mode: InsertMode.insertOrIgnore),
    );
  });

  /// Songs with the same title and artist ([Duplicates.find]).
  Future<List<DuplicateGroup>> findDuplicates() async {
    final counts = <int, int>{};
    for (final row in await _db.select(_db.setlistSongs).get()) {
      counts[row.songId] = (counts[row.songId] ?? 0) + 1;
    }
    return Duplicates.find(await allSongs(), setlistCounts: counts);
  }

  /// Removes the copies in identical [groups], keeping each group's first
  /// song. Nothing is lost: the keeper becomes a favorite if any copy was,
  /// and takes the copies' places in setlists it wasn't in yet. Returns what
  /// [undoRemoveCopies] needs to put everything back as it was.
  Future<DeletedSongs> removeCopies(List<DuplicateGroup> groups) =>
      _db.transaction(() async {
        final identical = [
          for (final group in groups)
            if (group.identical) group,
        ];
        final before = await _snapshot([
          for (final group in identical) ...group.songs.map((s) => s.id),
        ]);
        for (final group in identical) {
          final keeper = group.keeper.id;
          final copies = [for (final copy in group.copies) copy.id];
          if (group.copies.any((s) => s.favorite)) {
            await setFavorite(keeper, favorite: true);
          }
          final keeperIn = {
            for (final p in before.placements)
              if (p.songId == keeper) p.setlistId,
          };
          for (final p in before.placements) {
            if (!copies.contains(p.songId) || !keeperIn.add(p.setlistId)) {
              continue;
            }
            await _db.into(_db.setlistSongs).insert(p.copyWith(songId: keeper));
          }
          await deleteSongs(copies);
        }
        return before;
      });

  /// Undoes [removeCopies]: the removed copies come back and the kept songs
  /// return to exactly how they were.
  Future<void> undoRemoveCopies(DeletedSongs before) =>
      _db.transaction(() async {
        await deleteSongs([for (final song in before.songs) song.id]);
        await restore(before);
      });

  Future<DeletedSongs> _snapshot(List<int> ids) async => DeletedSongs(
    songs: await (_db.select(_db.songs)..where((s) => s.id.isIn(ids))).get(),
    placements: await (_db.select(
      _db.setlistSongs,
    )..where((e) => e.songId.isIn(ids))).get(),
  );

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

/// Songs a delete took away, and where they sat in setlists, so the delete
/// can be undone with [SongRepository.restore].
@immutable
final class DeletedSongs {
  const DeletedSongs({required this.songs, required this.placements});

  final List<SongEntry> songs;
  final List<SetlistSongEntry> placements;

  int get count => songs.length;
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
      // The key the song view shows: {key}, else the first chord's.
      key: song.effectiveKey?.name,
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
