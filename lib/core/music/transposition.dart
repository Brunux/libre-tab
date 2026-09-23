import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/music_key.dart';

/// How a song is shown: moved by [semitones], played with a capo on [capo].
///
/// With a capo the player fingers shapes [capo] semitones below what sounds,
/// so shown chords shift by `semitones - capo` (docs/SONG_FORMAT.md).
final class Transposition {
  const Transposition({this.semitones = 0, this.capo = 0})
    : assert(capo >= 0, 'capo fret cannot be negative');

  final int semitones;
  final int capo;

  int get shapeShift => semitones - capo;

  /// The key the audience hears.
  MusicKey soundingKey(MusicKey original) => original.transpose(semitones);

  /// The key of the shapes the player fingers.
  MusicKey shapeKey(MusicKey original) => original.transpose(shapeShift);

  /// The chord to show for `symbol` in a song in `original` key. Symbols
  /// that aren't chords (`N.C.`) are returned unchanged, and so is
  /// everything when there's nothing to shift, keeping the author's spelling.
  String chord(String symbol, MusicKey original) {
    if (shapeShift % 12 == 0) return symbol;
    final parsed = Chord.tryParse(symbol);
    if (parsed == null) return symbol;
    final flats = shapeKey(original).prefersFlats;
    return parsed.transpose(shapeShift, flats: flats).toString();
  }

  Transposition copyWith({int? semitones, int? capo}) => Transposition(
    semitones: semitones ?? this.semitones,
    capo: capo ?? this.capo,
  );
}
