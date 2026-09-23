import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/chord.dart';

void main() {
  group('Chord.tryParse', () {
    final cases = <String, Chord>{
      'C': const Chord(root: 'C'),
      'Am7': const Chord(root: 'A', suffix: 'm7'),
      'D/F#': const Chord(root: 'D', bass: 'F#'),
      'F#m7b5': const Chord(root: 'F#', suffix: 'm7b5'),
      'Bbmaj7': const Chord(root: 'Bb', suffix: 'maj7'),
      'Dsus4': const Chord(root: 'D', suffix: 'sus4'),
      'Cadd9/E': const Chord(root: 'C', suffix: 'add9', bass: 'E'),
      'C♯m': const Chord(root: 'C#', suffix: 'm'),
      ' G ': const Chord(root: 'G'),
    };
    for (final MapEntry(key: text, value: chord) in cases.entries) {
      test('"$text"', () => expect(Chord.tryParse(text), chord));
    }

    for (final bad in ['', 'N.C.', 'x2', '|', 'H7', 'c', 'G/H', 'A B']) {
      test('"$bad" is not a chord', () => expect(Chord.tryParse(bad), isNull));
    }
  });

  test('isMinor', () {
    bool minor(String s) => Chord.tryParse(s)!.isMinor;
    expect(minor('Am'), isTrue);
    expect(minor('Dm7'), isTrue);
    expect(minor('Bbmin'), isTrue);
    expect(minor('F#m7b5'), isTrue);
    expect(minor('Cmaj7'), isFalse);
    expect(minor('Cdim'), isFalse);
    expect(minor('Dsus4'), isFalse);
    expect(minor('G'), isFalse);
  });

  group('transpose', () {
    String up(String s, int n, {bool flats = false}) =>
        Chord.tryParse(s)!.transpose(n, flats: flats).toString();

    test('moves root and bass, keeps the suffix', () {
      expect(up('D/F#', 2), 'E/G#');
      expect(up('Am7', 3), 'Cm7');
      expect(up('F#m7b5', -1), 'Fm7b5');
    });

    test('spells with sharps or flats as asked', () {
      expect(up('A', 1), 'A#');
      expect(up('A', 1, flats: true), 'Bb');
      expect(up('D/F#', 1, flats: true), 'Eb/G');
    });

    test('wraps around the octave', () {
      expect(up('C', -1), 'B');
      expect(up('B', 1), 'C');
      expect(up('Bb', 12, flats: true), 'Bb');
    });
  });

  test('toString round-trips', () {
    for (final s in ['C', 'Am7', 'D/F#', 'Bbmaj7', 'Cadd9/E']) {
      expect(Chord.tryParse(s).toString(), s);
    }
  });
}
