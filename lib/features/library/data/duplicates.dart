import 'package:libre_tab/core/database/app_database.dart';
import 'package:libre_tab/features/library/data/setlist_repository.dart';
import 'package:meta/meta.dart';

/// Songs with the same title and artist (docs/DESIGN.md § Settings).
@immutable
final class DuplicateGroup {
  const DuplicateGroup({required this.songs, required this.identical});

  /// [identical]: copies of one song, the one to keep first. Otherwise:
  /// different versions (one of each), for the user to compare.
  final List<SongEntry> songs;

  /// Whether the songs' text is the same once invisible differences are
  /// ignored, so all but the first can go.
  final bool identical;

  SongEntry get keeper => songs.first;
  List<SongEntry> get copies => songs.sublist(1);
}

/// Finds duplicate songs: same title and artist (ignoring case, accents,
/// spacing and punctuation), then the same text (ignoring line endings,
/// trailing spaces, blank-line runs and directive spelling).
abstract final class Duplicates {
  /// [setlistCounts]: how many setlists each song id is in, to pick which
  /// copy to keep.
  static List<DuplicateGroup> find(
    List<SongEntry> songs, {
    Map<int, int> setlistCounts = const {},
  }) {
    final byName = <String, List<SongEntry>>{};
    for (final song in songs) {
      final key = '${nameKey(song.title)}\u0000${nameKey(song.artist)}';
      (byName[key] ??= []).add(song);
    }

    // Keep the favorite, then the one in more setlists, then the oldest.
    int keepFirst(SongEntry a, SongEntry b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      final inSetlists = (setlistCounts[b.id] ?? 0).compareTo(
        setlistCounts[a.id] ?? 0,
      );
      if (inSetlists != 0) return inSetlists;
      final older = a.createdAt.compareTo(b.createdAt);
      return older != 0 ? older : a.id.compareTo(b.id);
    }

    final groups = <DuplicateGroup>[];
    for (final named in byName.values) {
      if (named.length < 2) continue;
      final byText = <String, List<SongEntry>>{};
      for (final song in named) {
        (byText[bodyKey(song.body)] ??= []).add(song);
      }
      final versions = <SongEntry>[];
      for (final same in byText.values) {
        same.sort(keepFirst);
        versions.add(same.first);
        if (same.length > 1) {
          groups.add(DuplicateGroup(songs: same, identical: true));
        }
      }
      if (versions.length > 1) {
        versions.sort(keepFirst);
        groups.add(DuplicateGroup(songs: versions, identical: false));
      }
    }
    groups.sort(
      (a, b) => nameKey(a.keeper.title).compareTo(nameKey(b.keeper.title)),
    );
    return groups;
  }

  /// A title or artist for matching: lower case, no accents, punctuation
  /// and runs of spaces become one space.
  static String nameKey(String text) =>
      SetlistRepository.fold(text).replaceAll(_notLetterOrDigit, ' ').trim();

  /// A song's text for matching: line endings, trailing spaces, runs of
  /// blank lines and directive spelling (`{Title:`, `{t:`) don't count.
  static String bodyKey(String body) {
    final lines = <String>[];
    final text = body.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (final raw in text.split('\n')) {
      final line = raw.trimRight().replaceFirstMapped(_directive, (m) {
        final name = m[1]!.toLowerCase();
        return '{${_longNames[name] ?? name}${m[2]}';
      });
      if (line.isEmpty && (lines.isEmpty || lines.last.isEmpty)) continue;
      lines.add(line);
    }
    return lines.join('\n').trim();
  }

  static final RegExp _notLetterOrDigit = RegExp(
    r'[^\p{L}\p{N}]+',
    unicode: true,
  );
  static final RegExp _directive = RegExp(r'^\s*\{\s*([A-Za-z_]+)\s*(:?)\s*');

  static const _longNames = {
    't': 'title',
    'st': 'subtitle',
    'c': 'comment',
    'soc': 'start_of_chorus',
    'eoc': 'end_of_chorus',
    'sov': 'start_of_verse',
    'eov': 'end_of_verse',
    'sob': 'start_of_bridge',
    'eob': 'end_of_bridge',
  };
}
