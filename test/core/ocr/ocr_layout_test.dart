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

  test('a real Tesseract read of docs/store/review-sample.png', () {
    // Tesseract's boxes hug the ink: chord rows are shorter than lyric
    // rows, the gaps between boxes are wide, and the "1" of "VERSE 1" is
    // boxed too wide. Captured from the Android app.
    final words = [
      for (final (text, left, top, right, bottom) in _tesseractSample)
        RecognizedWord(
          text,
          left: left.toDouble(),
          top: top.toDouble(),
          right: right.toDouble(),
          bottom: bottom.toDouble(),
        ),
    ];
    final scanned = OcrLayout.read(words);
    expect(scanned.title, 'Red River Valley');
    expect(scanned.artist, 'Traditional');
    expect(scanned.text, startsWith('VERSE 1\n'));
    expect(scanned.text, contains('a-while\n\nCHORUS\n'));
    // One blank line only: before the chorus.
    expect('\n\n'.allMatches(scanned.text), hasLength(1));
    final song = ChordSheetImporter.convert(scanned.text).chordPro;
    expect(song, contains('From this [G]valley they say you are [D]going'));
    expect(
      song,
      contains('We will [G]miss your bright eyes and sweet [D]smile'),
    );
    expect(song, contains('For they [G]say you are taking the [C]sunshine'));
    expect(song, contains('That has [D7]brightened our pathway a-[G]while'));
    expect(song, contains('{start_of_chorus}'));
    expect(song, contains('Come and [G]sit by my side if you [D]love me'));
    expect(song, contains('Do not [G]hasten to bid me a-[D]dieu'));
  });
}

const _tesseractSample = [
  ('Red', 71, 69, 180, 111),
  ('River', 195, 69, 345, 111),
  ('Valley', 357, 69, 532, 122),
  ('Traditional', 70, 132, 198, 152),
  ('VERSE', 71, 218, 179, 236),
  ('1', 163, 214, 182, 246),
  ('G', 217, 271, 236, 292),
  ('D', 541, 272, 558, 292),
  ('From', 71, 310, 147, 333),
  ('this', 155, 308, 207, 333),
  ('valley', 216, 308, 298, 340),
  ('they', 305, 308, 367, 340),
  ('say', 375, 317, 420, 340),
  ('you', 427, 317, 478, 340),
  ('are', 488, 317, 531, 333),
  ('going', 539, 309, 617, 340),
  ('G', 185, 367, 204, 388),
  ('D', 641, 368, 659, 388),
  ('We', 70, 406, 116, 429),
  ('will', 124, 404, 175, 429),
  ('miss', 184, 405, 248, 429),
  ('your', 256, 413, 321, 436),
  ('bright', 328, 404, 415, 436),
  ('eyes', 424, 413, 482, 436),
  ('and', 492, 404, 544, 429),
  ('sweet', 553, 408, 631, 429),
  ('smile', 640, 404, 715, 429),
  ('G', 197, 463, 216, 484),
  ('Cc', 511, 463, 529, 484),
  ('For', 71, 502, 120, 525),
  ('they', 127, 500, 189, 532),
  ('say', 197, 509, 242, 532),
  ('you', 249, 509, 300, 532),
  ('are', 310, 509, 353, 525),
  ('taking', 361, 500, 449, 532),
  ('the', 457, 500, 502, 525),
  ('sunshine', 511, 500, 637, 525),
  ('D7', 202, 560, 235, 580),
  ('G', 575, 559, 594, 580),
  ('That', 70, 596, 135, 621),
  ('has', 143, 596, 191, 621),
  ('brightened', 199, 596, 354, 628),
  ('our', 363, 605, 411, 621),
  ('pathway', 419, 596, 539, 628),
  ('a-while', 547, 596, 649, 621),
  ('CHORUS', 71, 686, 183, 704),
  ('G', 221, 739, 240, 760),
  ('D', 509, 740, 526, 760),
  ('Come', 71, 778, 151, 801),
  ('and', 160, 776, 212, 801),
  ('sit', 221, 777, 254, 801),
  ('by', 262, 776, 297, 808),
  ('my', 305, 785, 348, 808),
  ('side', 356, 776, 412, 801),
  ('if', 421, 776, 442, 801),
  ('you', 447, 785, 498, 808),
  ('love', 507, 776, 564, 801),
  ('me', 573, 785, 615, 801),
  ('G', 175, 835, 194, 856),
  ('D', 446, 836, 464, 856),
  ('Do', 71, 874, 110, 897),
  ('not', 120, 876, 166, 897),
  ('hasten', 174, 872, 267, 897),
  ('to', 275, 876, 303, 897),
  ('bid', 311, 872, 357, 898),
  ('me', 366, 881, 408, 897),
  ('a-dieu', 417, 872, 505, 897),
];
