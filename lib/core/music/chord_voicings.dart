import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/note.dart';
import 'package:meta/meta.dart';

/// Where to put the fingers for a chord, low E string first.
@immutable
final class Voicing {
  const Voicing(this.frets, {this.barre});

  /// Six frets, low E → high e. -1 = don't play, 0 = open string.
  final List<int> frets;

  /// Fret held down across the strings by one finger, if any.
  final int? barre;

  static const muted = -1;

  /// The lowest fret the diagram needs to show (1 for open-position chords).
  int get baseFret {
    final pressed = frets.where((f) => f > 0);
    if (pressed.isEmpty) return 1;
    final highest = pressed.reduce((a, b) => a > b ? a : b);
    // Fits in the first four frets: draw from the nut.
    if (highest <= 4) return 1;
    return pressed.reduce((a, b) => a < b ? a : b);
  }

  @override
  bool operator ==(Object other) =>
      other is Voicing &&
      other.barre == barre &&
      other.frets.length == frets.length &&
      Iterable<int>.generate(frets.length).every(
        (i) => other.frets[i] == frets[i],
      );

  @override
  int get hashCode => Object.hash(Object.hashAll(frets), barre);

  @override
  String toString() =>
      frets.map((f) => f < 0 ? 'x' : '$f').join() +
      (barre == null ? '' : ' (barre $barre)');
}

/// Finds a guitar voicing for a chord symbol: a common open-position shape
/// when there is one, otherwise a movable E- or A-shape barre chord.
abstract final class ChordVoicings {
  static const int _x = Voicing.muted;

  /// Open-position shapes players learn first, by root and suffix.
  static const Map<String, List<int>> _open = {
    'C': [_x, 3, 2, 0, 1, 0],
    'C7': [_x, 3, 2, 3, 1, 0],
    'Cmaj7': [_x, 3, 2, 0, 0, 0],
    'Cadd9': [_x, 3, 2, 0, 3, 0],
    'D': [_x, _x, 0, 2, 3, 2],
    'Dm': [_x, _x, 0, 2, 3, 1],
    'D7': [_x, _x, 0, 2, 1, 2],
    'Dm7': [_x, _x, 0, 2, 1, 1],
    'Dmaj7': [_x, _x, 0, 2, 2, 2],
    'Dsus2': [_x, _x, 0, 2, 3, 0],
    'Dsus4': [_x, _x, 0, 2, 3, 3],
    'E': [0, 2, 2, 1, 0, 0],
    'Em': [0, 2, 2, 0, 0, 0],
    'E7': [0, 2, 0, 1, 0, 0],
    'Em7': [0, 2, 2, 0, 3, 0],
    'Emaj7': [0, 2, 1, 1, 0, 0],
    'Esus4': [0, 2, 2, 2, 0, 0],
    'Fmaj7': [_x, _x, 3, 2, 1, 0],
    'G': [3, 2, 0, 0, 0, 3],
    'G7': [3, 2, 0, 0, 0, 1],
    'Gmaj7': [3, 2, 0, 0, 0, 2],
    'A': [_x, 0, 2, 2, 2, 0],
    'Am': [_x, 0, 2, 2, 1, 0],
    'A7': [_x, 0, 2, 0, 2, 0],
    'Am7': [_x, 0, 2, 0, 1, 0],
    'Amaj7': [_x, 0, 2, 1, 2, 0],
    'Asus2': [_x, 0, 2, 2, 0, 0],
    'Asus4': [_x, 0, 2, 2, 3, 0],
    'B7': [_x, 2, 1, 2, 0, 2],
  };

  /// Movable shapes as open chords on E (root on the 6th string) and A
  /// (root on the 5th string). Moved up the neck with a barre.
  static const Map<String, List<int>> _eShape = {
    '': [0, 2, 2, 1, 0, 0],
    'm': [0, 2, 2, 0, 0, 0],
    '7': [0, 2, 0, 1, 0, 0],
    'm7': [0, 2, 0, 0, 0, 0],
    'maj7': [0, 2, 1, 1, 0, 0],
    'sus4': [0, 2, 2, 2, 0, 0],
  };
  static const Map<String, List<int>> _aShape = {
    '': [_x, 0, 2, 2, 2, 0],
    'm': [_x, 0, 2, 2, 1, 0],
    '7': [_x, 0, 2, 0, 2, 0],
    'm7': [_x, 0, 2, 0, 1, 0],
    'maj7': [_x, 0, 2, 1, 2, 0],
    'sus2': [_x, 0, 2, 2, 0, 0],
    'sus4': [_x, 0, 2, 2, 3, 0],
  };

  /// Suffixes written differently that mean the same chord.
  static const Map<String, String> _aliases = {
    'min': 'm',
    'M7': 'maj7',
    'min7': 'm7',
    'sus': 'sus4',
  };

  /// The voicing for [symbol], or null for chords without a diagram yet
  /// (e.g. `m7b5`, `dim`) and non-chords (`N.C.`). A bass note (`D/F#`)
  /// is ignored: the diagram shows the chord shape.
  static Voicing? forSymbol(String symbol) {
    final chord = Chord.tryParse(symbol);
    if (chord == null) return null;
    final suffix = _aliases[chord.suffix] ?? chord.suffix;
    final root = Note.pitchClass(chord.root)!;

    // Open shapes are stored by sharp/natural name; look up both spellings.
    for (final name in {
      Note.spell(root, flats: false),
      Note.spell(root, flats: true),
    }) {
      final open = _open['$name$suffix'];
      if (open != null) return Voicing(open);
    }

    final e = _eShape[suffix];
    final a = _aShape[suffix];
    final eFret = (root - 4) % 12; // fret of the root on the low E string
    final aFret = (root - 9) % 12; // fret of the root on the A string
    // Prefer the shape played lower on the neck.
    if (e != null && (a == null || eFret <= aFret)) return _moved(e, eFret);
    if (a != null) return _moved(a, aFret);
    return null;
  }

  static Voicing _moved(List<int> shape, int fret) => Voicing(
    [for (final f in shape) f < 0 ? f : f + fret],
    barre: fret == 0 ? null : fret,
  );
}
