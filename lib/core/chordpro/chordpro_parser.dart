import 'package:libre_tab/core/chordpro/song.dart';
import 'package:libre_tab/core/music/music_key.dart';

/// Parses the ChordPro subset in docs/SONG_FORMAT.md. Never throws:
/// unknown directives are ignored and unclosed sections end at the next
/// section or the end of the song.
abstract final class ChordProParser {
  static final RegExp _directive = RegExp(
    r'^\{\s*([A-Za-z_]+)\s*(?::(.*))?\}$',
  );
  static final RegExp _chord = RegExp(r'\[([^\[\]]*)\]');

  static const Map<String, SectionKind> _sectionStarts = {
    'start_of_verse': SectionKind.verse,
    'sov': SectionKind.verse,
    'start_of_chorus': SectionKind.chorus,
    'soc': SectionKind.chorus,
    'start_of_bridge': SectionKind.bridge,
    'sob': SectionKind.bridge,
    'start_of_tab': SectionKind.tab,
    'sot': SectionKind.tab,
  };
  static const _sectionEnds = {
    'end_of_verse', 'eov', 'end_of_chorus', 'eoc', //
    'end_of_bridge', 'eob', 'end_of_tab', 'eot',
  };

  static Song parse(String source) => _SongBuilder().build(source);

  /// Splits a lyric line into chord/lyric segments.
  static LyricLine parseLyricLine(String line) {
    final segments = <ChordSegment>[];
    String? pending;
    var position = 0;
    for (final match in _chord.allMatches(line)) {
      final text = line.substring(position, match.start);
      if (pending != null || text.isNotEmpty) {
        segments.add(ChordSegment(chord: pending, lyric: text));
      }
      final symbol = match.group(1)!.trim();
      pending = symbol.isEmpty ? null : symbol;
      position = match.end;
    }
    final rest = line.substring(position);
    if (pending != null || rest.isNotEmpty || segments.isEmpty) {
      segments.add(ChordSegment(chord: pending, lyric: rest));
    }
    return LyricLine(segments);
  }
}

class _SongBuilder {
  String? _title;
  String? _artist;
  MusicKey? _key;
  int? _capo;
  int? _tempo;
  final _blocks = <SongBlock>[];

  // The section being filled. `_explicit` is false for loose lines.
  SectionKind _kind = SectionKind.none;
  String? _label;
  bool _explicit = false;
  var _lines = <SongLine>[];

  Song build(String source) {
    for (final raw in source.split(RegExp(r'\r?\n'))) {
      _line(raw.trimRight());
    }
    _flush();
    return Song(
      title: _title,
      artist: _artist,
      key: _key,
      capo: _capo,
      tempo: _tempo,
      blocks: List.unmodifiable(_blocks),
    );
  }

  void _line(String line) {
    final trimmed = line.trim();
    final directive = ChordProParser._directive.firstMatch(trimmed);
    final name = directive?.group(1)!.toLowerCase();

    // Inside a tab block everything is literal until {end_of_tab}.
    if (_explicit && _kind == SectionKind.tab) {
      if (name == 'end_of_tab' || name == 'eot') {
        _flush();
      } else {
        _lines.add(TabLine(line));
      }
      return;
    }

    if (trimmed.startsWith('#')) return;

    if (directive != null) {
      final value = directive.group(2)?.trim();
      _directive(name!, value == null || value.isEmpty ? null : value);
      return;
    }

    if (trimmed.isEmpty) {
      // A blank line ends a loose stanza; inside a section it's spacing.
      if (_explicit) {
        _lines.add(const EmptyLine());
      } else {
        _flush();
      }
      return;
    }

    _lines.add(ChordProParser.parseLyricLine(line));
  }

  void _directive(String name, String? value) {
    final start = ChordProParser._sectionStarts[name];
    if (start != null) {
      _flush();
      _kind = start;
      _label = value;
      _explicit = true;
      return;
    }
    if (ChordProParser._sectionEnds.contains(name)) {
      if (_explicit) _flush();
      return;
    }
    switch (name) {
      case 'title' || 't':
        _title = value;
      case 'artist' || 'a':
        _artist = value;
      case 'key':
        _key = value == null ? null : MusicKey.tryParse(value);
      case 'capo':
        _capo = int.tryParse(value ?? '');
      case 'tempo':
        _tempo = int.tryParse(value ?? '');
      case 'comment' || 'c':
        if (value != null) _lines.add(CommentLine(value));
      case 'chorus':
        _flush();
        _blocks.add(ChorusRepeat(label: value));
      default:
        // Unknown directive: stays in the stored text, ignored here.
        break;
    }
  }

  void _flush() {
    while (_lines.isNotEmpty && _lines.last is EmptyLine) {
      _lines.removeLast();
    }
    if (_lines.isNotEmpty) {
      _blocks.add(
        SectionBlock(
          kind: _kind,
          label: _label,
          lines: List.unmodifiable(_lines),
        ),
      );
    }
    _kind = SectionKind.none;
    _label = null;
    _explicit = false;
    _lines = [];
  }
}
