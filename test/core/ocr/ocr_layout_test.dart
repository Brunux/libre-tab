import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/ocr/ocr_layout.dart';

/// Widths of a proportional font, in pixels.
double widthOf(String char) => switch (char) {
  'i' || 'l' || 'j' || 't' || 'f' || '!' || ',' || '.' || "'" => 4,
  'm' || 'w' || 'M' || 'W' => 14,
  ' ' => 5,
  _ => 9,
};

/// A printed line: its words with boxes, starting at [x], height [size].
List<RecognizedWord> printed(
  String text, {
  required double y,
  double x = 40,
  double size = 20,
}) {
  final words = <RecognizedWord>[];
  var left = x;
  for (final word in text.split(' ')) {
    final width = word.split('').fold<double>(0, (w, c) => w + widthOf(c));
    words.add(
      RecognizedWord(
        word,
        left: left,
        top: y,
        right: left + width,
        bottom: y + size,
      ),
    );
    left += width + widthOf(' ');
  }
  return words;
}

/// The x where character [index] of [text] starts, printed from [x].
double xOf(String text, int index, {double x = 40}) =>
    x + text.substring(0, index).split('').fold(0.0, (w, c) => w + widthOf(c));

/// Chords printed above [lyric]: each chord starts over the character at
/// its index.
List<RecognizedWord> chordsOver(
  String lyric,
  Map<int, String> chords, {
  required double y,
}) => [
  for (final MapEntry(key: i, value: chord) in chords.entries)
    RecognizedWord(
      chord,
      left: xOf(lyric, i),
      top: y,
      right: xOf(lyric, i) + chord.length * 9,
      bottom: y + 18,
    ),
];

String sheet(List<RecognizedWord> words) => OcrLayout.read(words).text;

String chordPro(List<RecognizedWord> words) =>
    ChordSheetImporter.convert(sheet(words)).chordPro;

void main() {
  const grace = 'Amazing grace, how sweet the sound';

  test('chords land on the right syllable in a proportional font', () {
    final words = [
      ...chordsOver(grace, {2: 'G', 8: 'G7', 19: 'C', 29: 'G'}, y: 100),
      ...printed(grace, y: 122),
    ];
    expect(
      chordPro(words),
      'Am[G]azing [G7]grace, how [C]sweet the [G]sound',
    );
  });

  test("narrow and wide letters don't throw the columns off", () {
    // Counting characters would put D under "l" in "illillill"; the x
    // position puts it on "W".
    const lyric = 'illillill Wow Mmm';
    final words = [
      ...chordsOver(lyric, {0: 'A', 10: 'D', 14: 'E'}, y: 0),
      ...printed(lyric, y: 22),
    ];
    expect(chordPro(words), '[A]illillill [D]Wow [E]Mmm');
  });

  test('the order the engine returns words in does not matter', () {
    final words = [
      ...printed(grace, y: 122),
      ...chordsOver(grace, {8: 'G7', 2: 'G'}, y: 100),
    ].reversed.toList();
    expect(chordPro(words), 'Am[G]azing [G7]grace, how sweet the sound');
  });

  test('a slightly tilted photo still reads as whole lines', () {
    final words = [
      for (final (i, w) in printed(grace, y: 122).indexed)
        RecognizedWord(
          w.text,
          left: w.left,
          top: w.top + i * 2.5,
          right: w.right,
          bottom: w.bottom + i * 2.5,
        ),
    ];
    expect(sheet(words), grace);
  });

  test('a chord past the end of the lyric stays at the end', () {
    const lyric = 'Was blind';
    final words = [
      RecognizedWord(
        'D',
        left: xOf(lyric, 9) + 30,
        top: 0,
        right: xOf(lyric, 9) + 39,
        bottom: 18,
      ),
      ...printed(lyric, y: 22),
    ];
    expect(chordPro(words), matches(RegExp(r'^Was blind +\[D\]$')));
  });

  test('a bigger first line is the title; gaps split sections', () {
    final words = [
      ...printed('Amazing Grace', y: 0, size: 36),
      ...printed('Verse 1', y: 60),
      ...chordsOver(grace, {2: 'G'}, y: 90),
      ...printed(grace, y: 112),
      // A gap of two lines: a new section.
      ...printed('Chorus', y: 190),
      ...printed('G C D', y: 220),
    ];
    final scanned = OcrLayout.read(words);
    expect(scanned.title, 'Amazing Grace');
    expect(scanned.text, startsWith('Verse 1\n'));
    expect(scanned.text, contains('\n\nChorus\n'));
    final song = ChordSheetImporter.convert(scanned.text).chordPro;
    expect(song, contains('Am[G]azing grace'));
    expect(song, contains('{start_of_chorus}'));
  });

  test('a smaller line under the title is the artist', () {
    final words = [
      ...printed('Red River Valley', y: 0, size: 36),
      ...printed('Traditional', y: 44, size: 16),
      ...printed('VERSE 1', y: 90, size: 16),
      ...chordsOver(grace, {2: 'G'}, y: 120),
      ...printed(grace, y: 142),
    ];
    final scanned = OcrLayout.read(words);
    expect(scanned.title, 'Red River Valley');
    expect(scanned.artist, 'Traditional');
    expect(scanned.text, startsWith('VERSE 1\n'));
  });

  test('a section label under the title is not an artist', () {
    final words = [
      ...printed('Red River Valley', y: 0, size: 36),
      ...printed('VERSE 1', y: 50, size: 16),
      ...chordsOver(grace, {2: 'G'}, y: 80),
      ...printed(grace, y: 102),
    ];
    final scanned = OcrLayout.read(words);
    expect(scanned.artist, isNull);
    expect(scanned.text, startsWith('VERSE 1\n'));
  });

  test('no title when the first line is ordinary', () {
    expect(OcrLayout.read(printed(grace, y: 0)).title, isNull);
  });

  test('a chords-only line keeps its chords, spaced out', () {
    final words = [
      ...printed('Intro', y: 0),
      const RecognizedWord('G', left: 40, top: 30, right: 49, bottom: 48),
      const RecognizedWord('C', left: 120, top: 30, right: 129, bottom: 48),
      const RecognizedWord('D', left: 200, top: 30, right: 209, bottom: 48),
    ];
    final text = sheet(words);
    expect(text.split('\n').last, matches(RegExp(r'^G +C +D$')));
  });

  test('nothing found, nothing to import', () {
    expect(sheet([]), '');
    expect(
      sheet([
        const RecognizedWord(' ', left: 0, top: 0, right: 5, bottom: 5),
      ]),
      '',
    );
  });

  test('works the same in 0–1 units as in pixels', () {
    final pixels = [
      ...chordsOver(grace, {2: 'G', 19: 'C'}, y: 100),
      ...printed(grace, y: 122),
    ];
    final unit = [
      for (final w in pixels)
        RecognizedWord(
          w.text,
          left: w.left / 1000,
          top: w.top / 1000,
          right: w.right / 1000,
          bottom: w.bottom / 1000,
        ),
    ];
    expect(sheet(unit), sheet(pixels));
  });
}
