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

  test('copyWith', () {
    const t = Transposition(semitones: 1, capo: 2);
    expect(t.copyWith(capo: 0).capo, 0);
    expect(t.copyWith(capo: 0).semitones, 1);
    expect(t.copyWith(semitones: 5).capo, 2);
  });
}
