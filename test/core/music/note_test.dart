import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/note.dart';

void main() {
  group('Note.pitchClass', () {
    const cases = {
      'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5, //
      'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10,
      'B': 11, 'E#': 5, 'Fb': 4, 'B#': 0, 'Cb': 11, 'F♯': 6, 'A♭': 8,
    };
    for (final MapEntry(key: name, value: pc) in cases.entries) {
      test('$name → $pc', () => expect(Note.pitchClass(name), pc));
    }

    for (final bad in ['', 'H', 'c', 'C##', 'Cx', 'Bbb']) {
      test('"$bad" is not a note', () => expect(Note.pitchClass(bad), isNull));
    }
  });

  group('Note.spell', () {
    test('uses sharps or flats as asked', () {
      expect(Note.spell(1, flats: false), 'C#');
      expect(Note.spell(1, flats: true), 'Db');
      expect(Note.spell(4, flats: true), 'E');
    });

    test('wraps around the octave in both directions', () {
      expect(Note.spell(-1, flats: false), 'B');
      expect(Note.spell(13, flats: true), 'Db');
      expect(Note.spell(-14, flats: true), 'Bb');
    });
  });
}
