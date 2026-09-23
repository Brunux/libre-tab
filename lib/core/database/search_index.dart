import 'package:drift/drift.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/database/app_database.dart';

/// The FTS5 index over song titles, artists and lyrics (`songs_fts`, rowid =
/// song id). Text is normalised the same way on the way in and in queries.
abstract final class SearchIndex {
  /// Apostrophes split words in FTS ("don't" → "don" + "t"), so they're
  /// removed: "dont", "don't" and "don’t" all find each other.
  static final RegExp _apostrophes = RegExp("['’‘`´]");

  static String normalize(String text) => text.replaceAll(_apostrophes, '');

  /// Turns what the user typed into an FTS5 query: every word must match
  /// the start of a word in the song. Returns null for an empty search.
  /// Punctuation is dropped, so user input can't break the query syntax.
  static String? query(String input) {
    final words = normalize(input)
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return null;
    return words.map((w) => '"$w"*').join(' ');
  }

  static Future<void> put(
    DatabaseConnectionUser db,
    int id, {
    required String title,
    required String artist,
    required String lyrics,
  }) async {
    await remove(db, id);
    await db.customStatement(
      'INSERT INTO songs_fts(rowid, title, artist, lyrics) VALUES (?, ?, ?, ?)',
      [id, normalize(title), normalize(artist), normalize(lyrics)],
    );
  }

  static Future<void> remove(DatabaseConnectionUser db, int id) =>
      db.customStatement('DELETE FROM songs_fts WHERE rowid = ?', [id]);

  /// Re-indexes every song from its stored ChordPro text.
  static Future<void> rebuild(AppDatabase db) async {
    await db.customStatement('DELETE FROM songs_fts');
    for (final song in await db.select(db.songs).get()) {
      await put(
        db,
        song.id,
        title: song.title,
        artist: song.artist,
        lyrics: ChordProParser.parse(song.body).plainLyrics,
      );
    }
  }
}
