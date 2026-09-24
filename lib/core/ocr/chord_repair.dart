import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';

/// Fixes the ways text recognition commonly misreads chord symbols, such as
/// Tesseract reading "C" as "Cc" or "Am" as "Arn".
///
/// Only a line that is already mostly chords is touched, and only when every
/// word in it then reads as a chord, so lyrics are never "corrected".
abstract final class ChordRepair {
  /// The words of a line with misread chords fixed, one for each word (null
  /// where a speck is dropped); or null when the line isn't a chord line
  /// even after fixing (then it's left as it was).
  static List<String?>? line(List<String> words) {
    final symbols = [
      for (final w in words)
        if (!_isMark(w)) w,
    ];
    final chords = symbols.where(_isChord).length;
    if (chords == 0 || chords * 2 < symbols.length) return null;
    final fixed = <String?>[];
    for (final word in words) {
      if (_isChord(word) || _isMark(word)) {
        fixed.add(word);
        continue;
      }
      // A speck read as a mark: drop it.
      if (_noise.hasMatch(word)) {
        fixed.add(null);
        continue;
      }
      final guess = _guess(word);
      if (guess == null) return null;
      fixed.add(guess);
    }
    return fixed;
  }

  static bool _isChord(String word) => ChordSheetImporter.isChordLine(word);

  /// A mark a chord line may hold besides chords: `|`, `N.C.`, `x2`.
  static bool _isMark(String word) =>
      !_isChord(word) && ChordSheetImporter.isChordLine('C $word');

  /// Stray punctuation, alone.
  static final _noise = RegExp(r'''^[.,;:'"`´~_\-]+$''');
  static final _leading = RegExp('''^[.,;:'"`´]+''');
  static final _trailing = RegExp(r'''[.,;:'"`´]+$''');
  static final _lowerRoot = RegExp('^[a-g]');

  /// Look-alikes for a chord's root letter.
  static const _roots = {'6': 'G', '8': 'B', '0': 'D', 'O': 'D'};

  static String? _guess(String word) {
    var w = word
        // Punctuation stuck to a chord: "G," "(C." "D:".
        .replaceAll(_trailing, '')
        .replaceAll(_leading, '')
        // "rn" for "m": "Arn" → "Am", "Ernaj7" → "Emaj7".
        .replaceAll('rn', 'm');
    if (w.isEmpty) return null;
    // A digit or letter that looks like the root: "6m" → "Gm".
    final root = _roots[w[0]];
    if (root != null) w = '$root${w.substring(1)}';
    // A lowercase root: "am" → "Am".
    if (_lowerRoot.hasMatch(w)) w = w[0].toUpperCase() + w.substring(1);
    // The root doubled in lower case: "Cc" → "C", "Gg7" → "G7". ("Bb" is a
    // real chord and never gets here.)
    if (w.length >= 2 && w[1] == w[0].toLowerCase() && w[1] != 'b') {
      w = w[0] + w.substring(2);
    }
    return _isChord(w) ? w : null;
  }
}
