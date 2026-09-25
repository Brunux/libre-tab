import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/core/database/database_provider.dart';
import 'package:meta/meta.dart';

final setlistRepositoryProvider = Provider<SetlistRepository>(
  (ref) => SetlistRepository(ref.watch(appDatabaseProvider)),
);

/// A setlist as the list shows it.
@immutable
final class SetlistSummary {
  const SetlistSummary({
    required this.id,
    required this.name,
    required this.songCount,
  });

  final int id;
  final String name;
  final int songCount;

  @override
  bool operator ==(Object other) =>
      other is SetlistSummary &&
      other.id == id &&
      other.name == name &&
      other.songCount == songCount;

  @override
  int get hashCode => Object.hash(id, name, songCount);
}

/// Setlists: named, ordered lists of songs. Songs are shared with the
/// songbook; deleting a setlist never deletes songs.
class SetlistRepository {
  SetlistRepository(AppDatabase db) : _db = db;

  final AppDatabase _db;

  /// Every setlist, by name; only names containing [query] when given
  /// (ignoring case and accents).
  Stream<List<SetlistSummary>> watchSetlists({String query = ''}) {
    final wanted = fold(query.trim());
    return _db
        .customSelect(
          'SELECT s.id, s.name, '
          '(SELECT count(*) FROM setlist_songs WHERE setlist_id = s.id) '
          'AS song_count '
          'FROM setlists s ORDER BY s.name COLLATE NOCASE, s.id',
          readsFrom: {_db.setlists, _db.setlistSongs},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              if (fold(row.read<String>('name')).contains(wanted))
                SetlistSummary(
                  id: row.read<int>('id'),
                  name: row.read<String>('name'),
                  songCount: row.read<int>('song_count'),
                ),
          ],
        );
  }

  Stream<SetlistEntry?> watchSetlist(int id) => (_db.select(
    _db.setlists,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  /// The setlist's songs in playing order.
  Stream<List<SongEntry>> watchSongs(int setlistId) => _songsQuery(
    setlistId,
  ).watch().map((rows) => [for (final row in rows) row.readTable(_db.songs)]);

  Future<List<int>> songIds(int setlistId) => _songsQuery(
    setlistId,
  ).get().then((rows) => [for (final row in rows) row.readTable(_db.songs).id]);

  /// Ids of the setlists that have [songId].
  Stream<Set<int>> watchSetlistsWith(int songId) =>
      (_db.select(_db.setlistSongs)..where((e) => e.songId.equals(songId)))
          .watch()
          .map((rows) => {for (final row in rows) row.setlistId});

  /// Makes an empty setlist and returns its id.
  Future<int> create(String name) async => await _db
      .into(_db.setlists)
      .insert(SetlistsCompanion.insert(name: _checked(name)));

  Future<void> rename(int id, String name) async =>
      await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
        SetlistsCompanion(name: Value(_checked(name))),
      );

  Future<void> delete(int id) =>
      (_db.delete(_db.setlists)..where((s) => s.id.equals(id))).go();

  /// Makes [songIds] the setlist's songs, in that order.
  Future<void> setSongs(int setlistId, List<int> songIds) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.setlistSongs,
        )..where((e) => e.setlistId.equals(setlistId))).go();
        await _db.batch(
          (batch) => batch.insertAll(_db.setlistSongs, [
            for (final (i, songId) in songIds.toSet().indexed)
              SetlistSongsCompanion.insert(
                setlistId: setlistId,
                songId: songId,
                position: i,
              ),
          ]),
        );
      });

  /// Adds [songId] at the end, unless it's already there.
  Future<void> addSong(int setlistId, int songId) => _db.transaction(() async {
    final ids = await songIds(setlistId);
    if (!ids.contains(songId)) await setSongs(setlistId, [...ids, songId]);
  });

  Future<void> removeSong(int setlistId, int songId) =>
      _db.transaction(() async {
        final ids = await songIds(setlistId);
        await setSongs(setlistId, [...ids.where((id) => id != songId)]);
      });

  /// Moves the song at position [from] to position [to] (0-based, [to]
  /// counted after the song is taken out, as [List.insert] would).
  Future<void> moveSong(int setlistId, int from, int to) =>
      _db.transaction(() async {
        final ids = await songIds(setlistId);
        if (from < 0 || from >= ids.length) return;
        final id = ids.removeAt(from);
        ids.insert(to.clamp(0, ids.length), id);
        await setSongs(setlistId, ids);
      });

  JoinedSelectStatement<HasResultSet, dynamic> _songsQuery(int setlistId) =>
      _db.select(_db.setlistSongs).join([
          innerJoin(_db.songs, _db.songs.id.equalsExp(_db.setlistSongs.songId)),
        ])
        ..where(_db.setlistSongs.setlistId.equals(setlistId))
        ..orderBy([OrderingTerm.asc(_db.setlistSongs.position)]);

  static String _checked(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return trimmed;
  }

  /// Lower case without accents, for matching names: "fogata" finds
  /// "Fogáta".
  static String fold(String text) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final out = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final i = from.indexOf(char);
      out.write(i < 0 ? char : to[i]);
    }
    return out.toString();
  }
}
