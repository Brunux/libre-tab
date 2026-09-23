/// Converts the common "chords on the line above the lyrics" text into
/// ChordPro (docs/SONG_FORMAT.md § Importing chords-over-lyrics).
///
/// ```text
///   G      G7         C         G
/// A-mazing grace, how sweet the sound
/// ```
/// becomes `A-[G]mazing [G7]grace, how [C]sweet the [G]sound`.
abstract final class ChordSheetImporter {
  /// A chord symbol as found on paper: `G`, `Am7`, `Cmaj7`, `F#m7b5`,
  /// `Dsus4`, `Cadd9`, `D/F#`, optionally in parentheses.
  static final RegExp _chord = RegExp(
    r'^\(?[A-G][#b♯♭]?(?:maj|min|m|dim|aug|sus|add|°|\+)?\d*'
    r'(?:(?:sus|add|maj|b|#|♭|♯)\d+)*(?:/[A-G][#b♯♭]?)?\)?$',
  );
  static final RegExp _extraToken = RegExp(r'^(?:\||N\.?C\.?|\(?x\d+\)?)$');

  static const _sectionNames =
      '(?:verse|chorus|bridge|intro|outro|interlude|solo|pre-?chorus|'
      'estrofa|verso|coro|estribillo|puente|introducci[oó]n|final)';

  /// A section label on its own line: `[Chorus]`, `[Verse 2: softly]`,
  /// `Verse 1:`, `CORO`, `Coro x2`. Lyrics that merely start with such a
  /// word ("Solo tú me haces feliz") are not labels.
  static final RegExp _label = RegExp(
    r'^\s*(?:\[\s*'
    '$_sectionNames'
    r'\b[^\]]*\]|'
    '$_sectionNames'
    r'(?:\s+\d+)?(?:\s*\(?x\d+\)?)?\s*:?)\s*$',
    caseSensitive: false,
  );

  /// A line of guitar tab: `e|--0--2--|`, `B|-1-----|`.
  static final RegExp _tabLine = RegExp(
    r'^\s*[A-Ga-g]?\s*\|[-0-9|hpbrx/\\~ ]*$',
  );

  static final RegExp _directiveLine = RegExp(
    r'^\s*\{[A-Za-z_]+(?::.*)?\}\s*$',
  );
  static final RegExp _inlineChord = RegExp(r'\[([^\]]+)\]');

  static bool isChordSymbol(String token) => _chord.hasMatch(token);

  /// A line where every word is a chord (or `|`, `N.C.`, `x2`), and at least
  /// one is a real chord.
  static bool isChordLine(String line) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    if (tokens.first.isEmpty) return false;
    return tokens.every((t) => isChordSymbol(t) || _extraToken.hasMatch(t)) &&
        tokens.any(isChordSymbol);
  }

  static bool isSectionLabel(String line) => _label.hasMatch(line);

  /// True when the text is already ChordPro: it has directive lines or
  /// `[Chord]` markup around real chords.
  static bool looksLikeChordPro(String text) =>
      text.split('\n').any(_directiveLine.hasMatch) ||
      _inlineChord.allMatches(text).any((m) => isChordSymbol(m.group(1)!));

  static ImportResult convert(String source) {
    final text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (looksLikeChordPro(text)) {
      return ImportResult(chordPro: text.trimRight(), alreadyChordPro: true);
    }
    return _Converter(text.split('\n')).run();
  }
}

final class ImportResult {
  const ImportResult({
    required this.chordPro,
    this.chordLines = 0,
    this.sections = 0,
    this.alreadyChordPro = false,
  });

  final String chordPro;

  /// How many chord lines were placed over lyrics or kept as chord rows.
  final int chordLines;

  /// How many section labels (`Verse 1:`, `[Chorus]`) were recognised.
  final int sections;

  /// The input was ChordPro already and was returned unchanged.
  final bool alreadyChordPro;
}

class _Converter {
  _Converter(this.lines);

  final List<String> lines;
  final _out = <String>[];
  String? _open; // 'chorus' | 'verse' | 'tab'
  var _chordLines = 0;
  var _sections = 0;

  ImportResult run() {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_isTab(line)) {
        if (_open != 'tab') {
          _close();
          _out.add('{start_of_tab}');
          _open = 'tab';
        }
        _out.add(line.trimRight());
        continue;
      }
      if (_open == 'tab') _close();

      if (ChordSheetImporter.isSectionLabel(line)) {
        _startSection(line);
        continue;
      }

      if (ChordSheetImporter.isChordLine(line)) {
        _chordLines++;
        final next = i + 1 < lines.length ? lines[i + 1] : null;
        if (next != null && _isLyric(next)) {
          _out.add(_merge(line, next));
          i++;
        } else {
          _out.add(_chordsOnly(line));
        }
        continue;
      }

      if (line.trim().isEmpty && _open != null) {
        _close();
        _out.add('');
        continue;
      }
      _out.add(line.trimRight());
    }
    _close();
    while (_out.isNotEmpty && _out.last.isEmpty) {
      _out.removeLast();
    }
    return ImportResult(
      chordPro: _out.join('\n'),
      chordLines: _chordLines,
      sections: _sections,
    );
  }

  static bool _isTab(String line) =>
      ChordSheetImporter._tabLine.hasMatch(line) && line.contains('-');

  static bool _isLyric(String line) =>
      line.trim().isNotEmpty &&
      !ChordSheetImporter.isChordLine(line) &&
      !ChordSheetImporter.isSectionLabel(line) &&
      !_isTab(line);

  void _startSection(String line) {
    _close();
    _sections++;
    final name = line
        .trim()
        .replaceAll(RegExp(r'^\[|\]$'), '')
        .replaceAll(RegExp(r':$'), '')
        .trim();
    final isChorus =
        RegExp('chorus|coro|estribillo', caseSensitive: false).hasMatch(name) &&
        !RegExp('pre', caseSensitive: false).hasMatch(name);
    if (isChorus) {
      _out.add('{start_of_chorus}');
      _open = 'chorus';
    } else {
      _out.add('{start_of_verse: $name}');
      _open = 'verse';
    }
  }

  void _close() {
    switch (_open) {
      case 'chorus':
        _out.add('{end_of_chorus}');
      case 'verse':
        _out.add('{end_of_verse}');
      case 'tab':
        _out.add('{end_of_tab}');
    }
    _open = null;
  }

  static String _bracket(String token) =>
      ChordSheetImporter.isChordSymbol(token)
      ? '[${token.replaceAll(RegExp(r'^\(|\)$'), '')}]'
      : token;

  /// Inserts each chord into the lyric at the column where it starts.
  static String _merge(String chordLine, String lyric) {
    final chords = RegExp(r'\S+').allMatches(chordLine).toList();
    var merged = lyric.trimRight();
    for (final m in chords.reversed) {
      final symbol = m.group(0)!;
      if (!ChordSheetImporter.isChordSymbol(symbol)) continue;
      merged = merged.padRight(m.start);
      merged =
          '${merged.substring(0, m.start)}${_bracket(symbol)}'
          '${merged.substring(m.start)}';
    }
    return merged.trimRight();
  }

  static String _chordsOnly(String line) =>
      line.trim().split(RegExp(r'\s+')).map(_bracket).join(' ');
}
