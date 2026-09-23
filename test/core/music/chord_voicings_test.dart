import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/chord_voicings.dart';

/// Voicing in the usual tab notation, e.g. "x32010".
String? shape(String chord) => ChordVoicings.forSymbol(chord)?.toString();

void main() {
  group('open chords use the shapes players learn first', () {
    const expected = {
      'C': 'x32010',
      'G': '320003',
      'D': 'xx0232',
      'Em': '022000',
      'Am': 'x02210',
      'E7': '020100',
      'Dsus4': 'xx0233',
      'Cmaj7': 'x32000',
    };
    for (final MapEntry(key: chord, value: frets) in expected.entries) {
      test('$chord = $frets', () => expect(shape(chord), frets));
    }
  });

  group('other chords become E- or A-shape barre chords', () {
    const expected = {
      'F': '133211 (barre 1)',
      'Bb': 'x13331 (barre 1)',
      'A#': 'x13331 (barre 1)',
      'Bm': 'x24432 (barre 2)',
      'F#m': '244222 (barre 2)',
      'C#m': 'x46654 (barre 4)',
      'Cm': 'x35543 (barre 3)',
      'Ab': '466544 (barre 4)',
      'F7': '131211 (barre 1)',
      'Bsus4': 'x24452 (barre 2)',
    };
    for (final MapEntry(key: chord, value: frets) in expected.entries) {
      test('$chord = $frets', () => expect(shape(chord), frets));
    }
  });

  test('flat and sharp spellings give the same diagram', () {
    expect(shape('Db'), shape('C#'));
    expect(shape('Gbm'), shape('F#m'));
  });

  test('suffix spellings are understood', () {
    expect(shape('Amin'), shape('Am'));
    expect(shape('CM7'), shape('Cmaj7'));
    expect(shape('Dsus'), shape('Dsus4'));
  });

  test('a bass note is ignored: the chord shape is shown', () {
    expect(shape('D/F#'), shape('D'));
    expect(shape('G/B'), shape('G'));
  });

  test('chords without a diagram yet, and non-chords, give null', () {
    for (final chord in ['Cdim', 'Bm7b5', 'Caug', 'G13', 'N.C.', 'x2', '']) {
      expect(ChordVoicings.forSymbol(chord), isNull, reason: chord);
    }
  });

  group('baseFret: where the diagram starts', () {
    test('open and low chords start at the nut', () {
      expect(ChordVoicings.forSymbol('G')!.baseFret, 1);
      expect(ChordVoicings.forSymbol('F')!.baseFret, 1);
      expect(ChordVoicings.forSymbol('Bm')!.baseFret, 1);
    });

    test('chords higher up start at their lowest fret', () {
      expect(ChordVoicings.forSymbol('C#m')!.baseFret, 4);
      expect(ChordVoicings.forSymbol('Ab')!.baseFret, 4);
    });

    test('all-open strings', () {
      expect(const Voicing([0, 0, 0, 0, 0, 0]).baseFret, 1);
    });
  });

  test('every major and minor chord on every root has a diagram', () {
    for (final root in [
      'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
    ]) {
      for (final suffix in ['', 'm', '7', 'm7']) {
        final voicing = ChordVoicings.forSymbol('$root$suffix');
        expect(voicing, isNotNull, reason: '$root$suffix');
        expect(voicing!.frets, hasLength(6));
        final span = voicing.frets.where((f) => f > 0);
        if (span.isNotEmpty) {
          final width =
              span.reduce((a, b) => a > b ? a : b) -
              span.reduce((a, b) => a < b ? a : b);
          expect(width, lessThanOrEqualTo(3), reason: '$root$suffix playable');
        }
      }
    }
  });

  test('value equality', () {
    expect(ChordVoicings.forSymbol('C'), ChordVoicings.forSymbol('C'));
    expect(
      ChordVoicings.forSymbol('C').hashCode,
      ChordVoicings.forSymbol('C').hashCode,
    );
    expect(ChordVoicings.forSymbol('C'), isNot(ChordVoicings.forSymbol('G')));
  });
}
