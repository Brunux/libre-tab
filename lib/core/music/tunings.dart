import 'dart:math' as math;

import 'package:libre_tab/core/music/note.dart';
import 'package:meta/meta.dart';

/// One guitar string, as a MIDI note number (E2 = 40, A4 = 69).
@immutable
final class GuitarString {
  const GuitarString(this.midi, {this.flats = false});

  final int midi;

  /// Spell the note with a flat (E♭) rather than a sharp (D♯).
  final bool flats;

  String get name => Note.spell(midi % 12, flats: flats);
  int get octave => midi ~/ 12 - 1;

  /// Frequency in Hz for a given A4 reference.
  double frequency([double a4 = 440]) =>
      a4 * math.pow(2, (midi - 69) / 12).toDouble();

  @override
  bool operator ==(Object other) =>
      other is GuitarString && other.midi == midi && other.flats == flats;

  @override
  int get hashCode => Object.hash(midi, flats);

  @override
  String toString() => '$name$octave';
}

/// Tunings offered by the tuner, strings from low (6th) to high (1st).
enum Tuning {
  standard([40, 45, 50, 55, 59, 64]),
  halfStepDown([39, 44, 49, 54, 58, 63], flats: true),
  dropD([38, 45, 50, 55, 59, 64]),
  dadgad([38, 45, 50, 55, 57, 62]),
  openG([38, 43, 50, 55, 59, 62]),
  openD([38, 45, 50, 54, 57, 62]);

  const Tuning(this._midi, {this.flats = false});

  final List<int> _midi;
  final bool flats;

  List<GuitarString> get strings => [
    for (final m in _midi) GuitarString(m, flats: flats),
  ];

  /// "E A D G B E", "E♭ A♭ D♭ G♭ B♭ E♭", …
  String get notes => strings
      .map((s) => s.name.replaceAll('#', '♯').replaceAll('b', '♭'))
      .join(' ');
}
