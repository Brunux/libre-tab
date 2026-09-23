import 'package:libre_tab/core/music/note.dart';
import 'package:meta/meta.dart';

/// A chord symbol split into root, suffix and optional bass note:
/// `F#m7/C#` → root `F#`, suffix `m7`, bass `C#`.
///
/// Parsing is lenient about the suffix (anything after the root that isn't
/// whitespace or `/`), because inside ChordPro brackets the author has
/// already said "this is a chord". Only the root and bass are transposed.
@immutable
final class Chord {
  const Chord({required this.root, this.suffix = '', this.bass});

  static final _pattern = RegExp(
    r'^([A-G][#b♯♭]?)([^/\s]*)(?:/([A-G][#b♯♭]?))?$',
  );

  final String root;
  final String suffix;
  final String? bass;

  /// Parses `symbol`, or returns null for things like `N.C.` or `x2`.
  static Chord? tryParse(String symbol) {
    final m = _pattern.firstMatch(symbol.trim());
    if (m == null) return null;
    return Chord(
      root: _normalize(m.group(1)!),
      suffix: m.group(2)!,
      bass: m.group(3) == null ? null : _normalize(m.group(3)!),
    );
  }

  /// True for minor chords (`Am`, `F#m7`, `Bbmin`), false for `Cmaj7`.
  bool get isMinor =>
      suffix.startsWith('m') && !suffix.startsWith('maj') ||
      suffix.startsWith('min');

  Chord transpose(int semitones, {required bool flats}) {
    String shift(String note) =>
        Note.spell(Note.pitchClass(note)! + semitones, flats: flats);
    return Chord(
      root: shift(root),
      suffix: suffix,
      bass: bass == null ? null : shift(bass!),
    );
  }

  @override
  String toString() => bass == null ? '$root$suffix' : '$root$suffix/$bass';

  @override
  bool operator ==(Object other) =>
      other is Chord &&
      other.root == root &&
      other.suffix == suffix &&
      other.bass == bass;

  @override
  int get hashCode => Object.hash(root, suffix, bass);

  static String _normalize(String note) =>
      note.replaceAll('♯', '#').replaceAll('♭', 'b');
}
