import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/music_key.dart';
import 'package:libre_tab/core/music/transposition.dart';

void main() {
  final g = MusicKey.tryParse('G')!;
  final f = MusicKey.tryParse('F')!;
  const songChords = ['G', 'G7', 'C', 'D', 'Em', 'D/F#'];

  List<String> show(Transposition t, MusicKey key) =>
      songChords.map((c) => t.chord(c, key)).toList();

  test('no change leaves chords exactly as written', () {
    const t = Transposition();
    expect(show(t, g), songChords);
    expect(t.chord('A#', g), 'A#'); // author's spelling kept
  });

  test('up 2 in G → A, with sharps', () {
    const t = Transposition(semitones: 2);
    expect(t.soundingKey(g).name, 'A');
    expect(show(t, g), ['A', 'A7', 'D', 'E', 'F#m', 'E/G#']);
  });

  test('up 1 in G → Ab, with flats', () {
    const t = Transposition(semitones: 1);
    expect(t.soundingKey(g).name, 'Ab');
    expect(show(t, g), ['Ab', 'Ab7', 'Db', 'Eb', 'Fm', 'Eb/G']);
  });

  test('down 1 in G → F#, with sharps', () {
    const t = Transposition(semitones: -1);
    expect(show(t, g), ['F#', 'F#7', 'B', 'C#', 'D#m', 'C#/F']);
  });

  test('capo equal to the transpose keeps the original shapes', () {
    const t = Transposition(semitones: 2, capo: 2);
    expect(t.soundingKey(g).name, 'A');
    expect(t.shapeKey(g).name, 'G');
    expect(show(t, g), songChords);
  });

  test('capo 3 in G → play E shapes, still sounds in G', () {
    const t = Transposition(capo: 3);
    expect(t.soundingKey(g).name, 'G');
    expect(t.shapeKey(g).name, 'E');
    expect(show(t, g), ['E', 'E7', 'A', 'B', 'C#m', 'B/D#']);
  });

  test('capo 1 in F → play E shapes (avoids the F barre)', () {
    const t = Transposition(capo: 1);
    final shown = ['F', 'Bb', 'C', 'Dm'].map((c) => t.chord(c, f));
    expect(shown, ['E', 'A', 'B', 'C#m']);
  });

  test('non-chords are never transposed', () {
    const t = Transposition(semitones: 3);
    expect(t.chord('N.C.', g), 'N.C.');
    expect(t.chord('x2', g), 'x2');
  });

  test('a full octave keeps the original spelling', () {
    const t = Transposition(semitones: 12);
    expect(t.chord('A#', g), 'A#');
  });

  group('songs written for a capo ({capo: 2})', () {
    final c = MusicKey.tryParse('C')!;

    test('opening as written shows the written shapes', () {
      const t = Transposition.asWritten(2);
      expect(t.capo, 2);
      expect(t.chord('C', c), 'C');
      expect(t.chord('G7', c), 'G7');
    });

    test('the song sounds two semitones above the written key', () {
      const t = Transposition.asWritten(2);
      expect(t.soundingKey(c).name, 'D');
      expect(t.shapeKey(c).name, 'C');
    });

    test('taking the capo off shows the sounding chords', () {
      final t = const Transposition.asWritten(2).copyWith(capo: 0);
      expect(t.soundingKey(c).name, 'D');
      expect(['C', 'F', 'G7'].map((x) => t.chord(x, c)), ['D', 'G', 'A7']);
    });

    test('moving the capo keeps the song in the same key', () {
      final t = const Transposition.asWritten(2).copyWith(capo: 4);
      expect(t.soundingKey(c).name, 'D');
      expect(t.shapeKey(c).name, 'Bb');
      expect(t.chord('G', c), 'F');
    });

    test('no {capo} behaves like capo 0', () {
      const t = Transposition.asWritten(null);
      expect(t.capo, 0);
      expect(t.writtenCapo, 0);
      expect(t.chord('C', c), 'C');
    });
  });

  test('copyWith', () {
    const t = Transposition(semitones: 1, capo: 2);
    expect(t.copyWith(capo: 0).capo, 0);
    expect(t.copyWith(capo: 0).semitones, 1);
    expect(t.copyWith(semitones: 5).capo, 2);
  });
}
