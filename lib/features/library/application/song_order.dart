import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';

/// How the songbook lists songs (docs/DESIGN.md § Songbook).
enum SongSort { title, artist, recent, mostPlayed }

/// Sorting and grouping for the songbook list, apart from the widgets.
abstract final class SongOrder {
  /// [songs] in [sort] order. Titles and artists compare without case or
  /// accents, so "Ángel" sits with the A's; ties fall back to the title.
  static List<SongEntry> sort(Iterable<SongEntry> songs, SongSort sort) {
    int byTitle(SongEntry a, SongEntry b) =>
        _key(a.title).compareTo(_key(b.title));
    final list = [...songs];
    switch (sort) {
      case SongSort.title:
        list.sort(byTitle);
      case SongSort.artist:
        // Songs without an artist last.
        list.sort((a, b) {
          if (a.artist.isEmpty != b.artist.isEmpty) {
            return a.artist.isEmpty ? 1 : -1;
          }
          final c = _key(a.artist).compareTo(_key(b.artist));
          return c != 0 ? c : byTitle(a, b);
        });
      case SongSort.recent:
        // Never opened last, by title.
        list.sort((a, b) {
          final (x, y) = (a.lastOpenedAt, b.lastOpenedAt);
          if (x == null || y == null) {
            return x == y ? byTitle(a, b) : (x == null ? 1 : -1);
          }
          final c = y.compareTo(x);
          return c != 0 ? c : byTitle(a, b);
        });
      case SongSort.mostPlayed:
        list.sort((a, b) {
          final c = b.playCount.compareTo(a.playCount);
          return c != 0 ? c : byTitle(a, b);
        });
    }
    return list;
  }

  /// The songs opened most recently, newest first, at most [limit].
  static List<SongEntry> recent(Iterable<SongEntry> songs, {int limit = 10}) =>
      sort(
        songs.where((s) => s.lastOpenedAt != null),
        SongSort.recent,
      ).take(limit).toList();

  /// The letter a song files under in the A–Z index: the first letter of
  /// the title (or artist), accents dropped; "#" for anything else.
  static String letter(SongEntry song, SongSort sort) {
    final text = _key(sort == SongSort.artist ? song.artist : song.title);
    if (text.isEmpty) return '#';
    final first = text[0].toUpperCase();
    return _latin.hasMatch(first) ? first : '#';
  }

  static final _latin = RegExp(r'^[A-Z]$');
  static final _leadingMarks = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);

  /// A sorting key: lower case, no accents, leading punctuation dropped
  /// ("¡Ay!" sorts under A, "'Twas" under T).
  static String _key(String text) =>
      SetlistRepository.fold(text).replaceFirst(_leadingMarks, '');
}
