import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/ocr/chord_repair.dart';

List<String?>? repair(String line) => ChordRepair.line(line.split(' '));

void main() {
  test('misread chords are fixed', () {
    expect(repair('G Cc'), ['G', 'C']); // Tesseract, review sample
    expect(repair('G Arn D'), ['G', 'Am', 'D']); // "rn" for "m"
    expect(repair('C Ernaj7'), ['C', 'Emaj7']);
    expect(repair('C 6m'), ['C', 'Gm']); // "6" for "G"
    expect(repair('E 8b'), ['E', 'Bb']); // "8" for "B"
    expect(repair('A 0 E'), ['A', 'D', 'E']); // "0" for "D"
    expect(repair('G am'), ['G', 'Am']); // lower-case root
    expect(repair('G D C: (A,'), ['G', 'D', 'C', '(A']); // punctuation stuck on
    expect(repair('Gg7 C'), ['G7', 'C']);
  });

  test('a speck is dropped, marks are kept', () {
    expect(repair("G ' C"), ['G', null, 'C']);
    expect(repair('| G | C |'), ['|', 'G', '|', 'C', '|']);
    expect(repair('N.C. G Cc'), ['N.C.', 'G', 'C']);
  });

  test('real chords are left alone', () {
    expect(repair('Bb Ab F#m7'), ['Bb', 'Ab', 'F#m7']);
  });

  test('lyrics are never touched', () {
    expect(repair('A man was born'), isNull);
    expect(repair('Oh, Susanna'), isNull);
    expect(repair('C and a doe'), isNull); // "and" isn't a chord
    expect(repair('come on'), isNull); // no chord at all
  });

  test('a line mostly misread is left for the user', () {
    // Fewer than half are chords: not enough to tell it's a chord line.
    expect(repair('G Cc Arn'), isNull);
    expect(repair('Cc'), isNull);
    expect(repair(''), isNull);
  });
}
