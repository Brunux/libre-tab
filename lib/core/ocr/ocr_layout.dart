import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/ocr/chord_repair.dart';
import 'package:meta/meta.dart';

/// One word found in a photo, with its box. Any unit works (pixels or 0–1)
/// as long as every word uses the same one; y grows downwards.
@immutable
final class RecognizedWord {
  const RecognizedWord(
    this.text, {
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;

  @override
  String toString() => 'RecognizedWord($text, $left, $top, $right, $bottom)';
}

/// What was read from a photo: a title if one stood out (a clearly bigger
/// first line), an artist if a smaller line sat right under it, and the rest
/// as chords-over-lyrics text.
@immutable
final class ScannedSheet {
  const ScannedSheet({required this.text, this.title, this.artist});

  final String? title;
  final String? artist;
  final String text;

  bool get isEmpty => text.isEmpty && title == null;
}

/// Turns the words text recognition found in a photo of a song sheet into
/// chords-over-lyrics text for [ChordSheetImporter] (docs/SONG_FORMAT.md
/// § Importing chords-over-lyrics).
///
/// Printed songbooks use proportional fonts, so counting characters can't
/// tell which syllable a chord sits over. Instead each chord's x position is
/// matched to the lyric character under it, and the chord line is written
/// with the chord at that character's column.
abstract final class OcrLayout {
  static ScannedSheet read(List<RecognizedWord> words) {
    final lines = _lines([
      for (final w in words)
        if (w.text.trim().isNotEmpty && w.width > 0 && w.height > 0) w,
    ]);
    if (lines.isEmpty) return const ScannedSheet(text: '');

    final lineHeight = _median([for (final l in lines) l.height]);
    final charWidth = _median([
      for (final l in lines)
        if (!l.isChords)
          for (final w in l.words) w.width / w.text.length,
    ], fallback: lineHeight * 0.5);

    final out = <String>[];
    // A clearly bigger first line is the title. Compared with lyric lines
    // only: section labels and a byline are often smaller.
    final lyricHeights = [
      for (final l in lines.skip(2))
        if (!l.isChords && !ChordSheetImporter.isSectionLabel(l.text)) l.height,
    ];
    // Not a {title} line: that would make the importer take the whole text
    // for finished ChordPro.
    String? title;
    String? artist;
    var start = 0;
    if (lines.length >= 3 &&
        !lines.first.isChords &&
        lyricHeights.isNotEmpty &&
        lines.first.height >= _median(lyricHeights) * 1.35) {
      title = lines.first.text;
      start = 1;
      // A smaller line right under the title, like "Traditional", is the
      // artist (not a section label such as "VERSE 1").
      final byline = lines[1];
      if (!byline.isChords &&
          !ChordSheetImporter.isSectionLabel(byline.text) &&
          byline.words.length <= 6 &&
          byline.height < _median(lyricHeights) * 0.95) {
        artist = byline.text;
        start = 2;
      }
    }

    // Spacing is measured center to center: engines differ in how much
    // room they leave around the ink (Tesseract's boxes are tight, Vision's
    // padded), so the gaps between boxes can't be compared with a height.
    final pitch = _median([
      for (var i = start + 1; i < lines.length; i++)
        lines[i].centerY - lines[i - 1].centerY,
    ], fallback: lineHeight * 1.5);
    bool farApart(_Line above, _Line below) =>
        below.centerY - above.centerY > pitch * 1.4;

    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      if (i > start &&
          farApart(lines[i - 1], line) &&
          !ChordSheetImporter.isSectionLabel(lines[i - 1].text)) {
        out.add(''); // a gap in the photo: a new section
      }
      final next = i + 1 < lines.length ? lines[i + 1] : null;
      final lyricBelow =
          next != null && !next.isChords && !farApart(line, next);
      if (line.isChords) {
        out.add(
          lyricBelow ? _chordsOver(line, next) : _chordsAlone(line, charWidth),
        );
      } else {
        out.add(line.text);
      }
    }
    return ScannedSheet(title: title, artist: artist, text: out.join('\n'));
  }

  /// The chord line written so each chord starts at the column of the lyric
  /// character under it.
  static String _chordsOver(_Line chords, _Line lyric) {
    final ends = _charEnds(lyric);
    final last = lyric.words.last;
    final lastCharWidth = last.width / last.text.length;
    final out = StringBuffer();
    for (final chord in chords.words) {
      // The character the chord starts over, measured a little into its
      // first letter: letters share a word's box evenly, so a chord right
      // over the letter after a narrow "-" or "i" can touch that one.
      final probe = chord.left + chord.width / chord.text.length * 0.3;
      var column = ends.indexWhere((end) => end > probe);
      if (column < 0) {
        final past = ((chord.left - last.right) / lastCharWidth).round();
        column = ends.length + past.clamp(1, 200);
      }
      final gap = column - out.length;
      out
        ..write(' ' * (out.isEmpty ? gap.clamp(0, 999) : gap.clamp(1, 999)))
        ..write(chord.text);
    }
    return out.toString();
  }

  /// Where each character of the lyric line (words joined with one space)
  /// ends, in photo units. Letters share their word's box evenly; a space
  /// ends where the next word starts.
  static List<double> _charEnds(_Line lyric) {
    final ends = <double>[];
    for (final (i, word) in lyric.words.indexed) {
      if (i > 0) ends.add(word.left);
      final n = word.text.length;
      for (var c = 1; c <= n; c++) {
        ends.add(word.left + word.width * c / n);
      }
    }
    return ends;
  }

  /// A chords-only line (no lyric under it): gaps kept roughly to scale.
  static String _chordsAlone(_Line chords, double charWidth) {
    final out = StringBuffer();
    final left = chords.words.first.left;
    for (final chord in chords.words) {
      final column = ((chord.left - left) / charWidth).round();
      final gap = column - out.length;
      out
        ..write(' ' * (out.isEmpty ? 0 : gap.clamp(1, 999)))
        ..write(chord.text);
    }
    return out.toString();
  }

  /// Groups words into lines by vertical overlap (tolerating a slightly
  /// tilted photo), top to bottom, each line left to right.
  static List<_Line> _lines(List<RecognizedWord> words) {
    final lines = <_Line>[];
    final byHeight = [...words]..sort((a, b) => a.centerY.compareTo(b.centerY));
    for (final word in byHeight) {
      _Line? best;
      var bestOverlap = 0.5;
      for (final line in lines) {
        final overlap = line.verticalOverlap(word);
        // A word sharing nearly all its height with a line is in it, even
        // if its box runs into a neighbour's (Tesseract boxes a "1" after
        // "VERSE" too wide).
        if (overlap > bestOverlap &&
            (overlap >= 0.9 || !line.overlapsHorizontally(word))) {
          best = line;
          bestOverlap = overlap;
        }
      }
      if (best == null) {
        best = _Line();
        lines.add(best);
      }
      best.add(word);
    }
    for (final line in lines) {
      line.words.sort((a, b) => a.left.compareTo(b.left));
      line.repairChords();
    }
    return lines..sort((a, b) => a.centerY.compareTo(b.centerY));
  }

  static double _median(List<double> values, {double fallback = 1}) {
    if (values.isEmpty) return fallback;
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }
}

class _Line {
  final words = <RecognizedWord>[];
  double _centerSum = 0;
  double _heightSum = 0;

  void add(RecognizedWord word) {
    words.add(word);
    _centerSum += word.centerY;
    _heightSum += word.height;
  }

  double get centerY => _centerSum / words.length;
  double get height => _heightSum / words.length;
  double get top => centerY - height / 2;
  double get bottom => centerY + height / 2;
  String get text => [for (final w in words) w.text].join(' ');

  /// Fixes misread chords ("Cc" for "C") in what is clearly a chord line.
  void repairChords() {
    final fixed = ChordRepair.line([for (final w in words) w.text]);
    if (fixed == null) return;
    final repaired = [
      for (final (i, w) in words.indexed)
        if (fixed[i] case final text?)
          RecognizedWord(
            text,
            left: w.left,
            top: w.top,
            right: w.right,
            bottom: w.bottom,
          ),
    ];
    words.clear();
    _centerSum = 0;
    _heightSum = 0;
    repaired.forEach(add);
  }

  bool get isChords => ChordSheetImporter.isChordLine(text);

  /// How much of the smaller height the word and the line share (0–1).
  double verticalOverlap(RecognizedWord word) {
    final shared =
        (word.bottom < bottom ? word.bottom : bottom) -
        (word.top > top ? word.top : top);
    final smaller = word.height < height ? word.height : height;
    return shared <= 0 ? 0 : shared / smaller;
  }

  /// Whether [word] sits on top of a word already in the line (then it
  /// belongs to another line). A sliver of overlap, as recognition boxes
  /// often have, doesn't count.
  bool overlapsHorizontally(RecognizedWord word) => words.any((w) {
    final slack = 0.2 * (w.width < word.width ? w.width : word.width);
    return word.left < w.right - slack && w.left < word.right - slack;
  });
}
