import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/note.dart';
import 'package:meta/meta.dart';

/// A song key such as `G` or `F#m`. Decides whether chords in this key are
/// written with sharps or flats.
@immutable
final class MusicKey {
  const MusicKey(this.tonic, {this.minor = false})
    : assert(tonic >= 0 && tonic < 12, 'tonic is a pitch class 0–11');

  /// The key a chord most likely belongs to, for songs without `{key}`:
  /// its root, minor if the chord is minor.
  factory MusicKey.fromChord(Chord chord) =>
      MusicKey(Note.pitchClass(chord.root)!, minor: chord.isMinor);

  /// Conventional name for each tonic. Keys with six accidentals use the
  /// spelling guitarists meet most often (F# major, Ebm).
  static const _majorNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
  ];
  static const _minorNames = [
    'Cm',
    'C#m',
    'Dm',
    'Ebm',
    'Em',
    'Fm',
    'F#m',
    'Gm',
    'G#m',
    'Am',
    'Bbm',
    'Bm',
  ];

  /// Major keys written with flats: F, Bb, Eb, Ab, Db.
  static const _flatMajors = {5, 10, 3, 8, 1};

  /// Minor keys written with flats: Dm, Gm, Cm, Fm, Bbm, Ebm.
  static const _flatMinors = {2, 7, 0, 5, 10, 3};

  /// Pitch class of the tonic (C = 0).
  final int tonic;
  final bool minor;

  /// Parses `G`, `Am`, `F#m`, `Bb`, `Ebmin`; null if not a key.
  static MusicKey? tryParse(String text) {
    final chord = Chord.tryParse(text);
    if (chord == null || chord.bass != null) return null;
    final suffix = chord.suffix;
    if (suffix.isNotEmpty && suffix != 'm' && suffix != 'min') return null;
    return MusicKey(Note.pitchClass(chord.root)!, minor: suffix.isNotEmpty);
  }

  bool get prefersFlats => (minor ? _flatMinors : _flatMajors).contains(tonic);

  MusicKey transpose(int semitones) =>
      MusicKey((tonic + semitones) % 12, minor: minor);

  String get name => (minor ? _minorNames : _majorNames)[tonic];

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      other is MusicKey && other.tonic == tonic && other.minor == minor;

  @override
  int get hashCode => Object.hash(tonic, minor);
}
