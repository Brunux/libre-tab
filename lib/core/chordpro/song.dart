import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/music_key.dart';

/// A song parsed from ChordPro text (docs/SONG_FORMAT.md). The text is the
/// source of truth; this model is rebuilt from it and never stored.
final class Song {
  const Song({
    this.title,
    this.artist,
    this.key,
    this.capo,
    this.tempo,
    this.blocks = const [],
  });

  final String? title;
  final String? artist;

  /// From `{key}`; null if missing or not a valid key.
  final MusicKey? key;

  /// Suggested capo fret from `{capo}`.
  final int? capo;

  /// BPM from `{tempo}`.
  final int? tempo;

  final List<SongBlock> blocks;

  /// Every chord symbol in the song, in order.
  Iterable<String> get chords sync* {
    for (final block in blocks) {
      if (block is! SectionBlock) continue;
      for (final line in block.lines) {
        if (line is! LyricLine) continue;
        for (final segment in line.segments) {
          if (segment.chord case final chord?) yield chord;
        }
      }
    }
  }

  /// The `{key}`, or a guess from the first chord when there is none.
  MusicKey? get effectiveKey {
    if (key != null) return key;
    for (final symbol in chords) {
      final chord = Chord.tryParse(symbol);
      if (chord != null) return MusicKey.fromChord(chord);
    }
    return null;
  }

  /// Lyrics without chords, directives or tabs: one line per lyric line,
  /// a blank line between sections. Used for search.
  String get plainLyrics {
    final sections = <String>[];
    for (final block in blocks) {
      if (block is! SectionBlock || block.kind == SectionKind.tab) continue;
      final text = block.lines
          .whereType<LyricLine>()
          .map((line) => line.lyrics.trim())
          .where((line) => line.isNotEmpty)
          .join('\n');
      if (text.isNotEmpty) sections.add(text);
    }
    return sections.join('\n\n');
  }
}

enum SectionKind {
  verse,
  chorus,
  bridge,
  tab,

  /// Lines outside any `{start_of_…}` directive.
  none,
}

sealed class SongBlock {
  const SongBlock();
}

/// A stanza: an explicit `{start_of_…}` section, or a run of lines outside
/// one, ended by a blank line.
final class SectionBlock extends SongBlock {
  const SectionBlock({required this.kind, required this.lines, this.label});

  final SectionKind kind;

  /// From `{start_of_verse: Verse 2}`; null when not given.
  final String? label;

  final List<SongLine> lines;
}

/// `{chorus}`: repeat the most recent chorus here.
final class ChorusRepeat extends SongBlock {
  const ChorusRepeat({this.label});

  final String? label;
}

sealed class SongLine {
  const SongLine();
}

/// A lyric line with chords attached to the text right after them:
/// `A-[G]mazing` → `(null, "A-")`, `("G", "mazing")`.
final class LyricLine extends SongLine {
  const LyricLine(this.segments);

  final List<ChordSegment> segments;

  String get lyrics => segments.map((s) => s.lyric).join();

  /// A line of chords with no words, like an intro: `[G] [C] [D]`.
  bool get isChordsOnly =>
      segments.any((s) => s.chord != null) && lyrics.trim().isEmpty;
}

/// A line inside `{start_of_tab}`, kept exactly as written.
final class TabLine extends SongLine {
  const TabLine(this.text);

  final String text;
}

/// `{comment: Intro x2}`: a highlighted note.
final class CommentLine extends SongLine {
  const CommentLine(this.text);

  final String text;
}

/// A blank line inside an explicit section.
final class EmptyLine extends SongLine {
  const EmptyLine();
}

final class ChordSegment {
  const ChordSegment({this.chord, this.lyric = ''});

  /// The chord symbol exactly as written, e.g. `G7`, `N.C.`.
  final String? chord;

  /// The text sung from this chord until the next one.
  final String lyric;
}
