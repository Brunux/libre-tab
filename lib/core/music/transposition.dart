import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/music_key.dart';

/// How a song is shown: moved by [semitones], played with a capo on [capo].
///
/// A song's chords are written as the shapes played with its own capo
/// ([writtenCapo], from `{capo}`); `{key}` is the key of those shapes. So
/// the song sounds `writtenCapo` semitones above what's written, and the
/// shapes to show shift by `writtenCapo + semitones - capo`
/// (docs/SONG_FORMAT.md § Transposing).
final class Transposition {
  const Transposition({this.semitones = 0, this.capo = 0, this.writtenCapo = 0})
    : assert(capo >= 0, 'capo fret cannot be negative'),
      assert(writtenCapo >= 0, 'capo fret cannot be negative');

  /// Starts showing the song exactly as written: capo where the song says.
  const Transposition.asWritten(int? songCapo)
    : this(capo: songCapo ?? 0, writtenCapo: songCapo ?? 0);

  final int semitones;
  final int capo;
  final int writtenCapo;

  int get shapeShift => writtenCapo + semitones - capo;

  /// The key the audience hears, for a song whose chords are in [written].
  MusicKey soundingKey(MusicKey written) =>
      written.transpose(writtenCapo + semitones);

  /// The key of the shapes the player fingers.
  MusicKey shapeKey(MusicKey written) => written.transpose(shapeShift);

  /// The chord to show for `symbol` in a song written in [written]. Symbols
  /// that aren't chords (`N.C.`) are returned unchanged, and so is
  /// everything when there's nothing to shift, keeping the author's spelling.
  String chord(String symbol, MusicKey written) {
    if (shapeShift % 12 == 0) return symbol;
    final parsed = Chord.tryParse(symbol);
    if (parsed == null) return symbol;
    final flats = shapeKey(written).prefersFlats;
    return parsed.transpose(shapeShift, flats: flats).toString();
  }

  Transposition copyWith({int? semitones, int? capo}) => Transposition(
    semitones: semitones ?? this.semitones,
    capo: capo ?? this.capo,
    writtenCapo: writtenCapo,
  );
}
