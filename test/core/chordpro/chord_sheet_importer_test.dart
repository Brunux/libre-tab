import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song.dart';

String convert(String text) => ChordSheetImporter.convert(text).chordPro;

/// Builds a chord line with each chord starting at an exact column, so
/// tests don't depend on hand-counted spaces.
String chordsAt(Map<int, String> columns) {
  final line = StringBuffer();
  for (final MapEntry(key: column, value: chord) in columns.entries) {
    line
      ..write(' ' * (column - line.length))
      ..write(chord);
  }
  return line.toString();
}

void main() {
  test('the example from docs/SONG_FORMAT.md', () {
    final sheet =
        '${chordsAt({2: 'G', 9: 'G7', 20: 'C', 30: 'G'})}\n'
        'A-mazing grace, how sweet the sound';
    expect(sheet.split('\n').first, '  G      G7         C         G');
    expect(convert(sheet), 'A-[G]mazing [G7]grace, how [C]sweet the [G]sound');
  });

  test('chords land on the character under them', () {
    expect(convert('C   G\nHello world'), '[C]Hell[G]o world');
    expect(convert('    Am\nThe night'), 'The [Am]night');
  });

  test('a chord past the end of the lyric is padded', () {
    expect(convert('C          G\nHi'), '[C]Hi${' ' * 9}[G]');
  });

  test('Oh! Susanna, with verse and chorus labels', () {
    final result = ChordSheetImporter.convert('''
Verse 1:
${chordsAt({0: 'C', 40: 'G'})}
I come from Alabama with my banjo on my knee

Chorus:
${chordsAt({0: 'F', 16: 'C', 34: 'G'})}
Oh! Susanna, oh don't you cry for me''');

    expect(result.alreadyChordPro, isFalse);
    expect(result.chordLines, 2);
    expect(result.sections, 2);
    expect(result.chordPro, '''
{start_of_verse: Verse 1}
[C]I come from Alabama with my banjo on my [G]knee
{end_of_verse}

{start_of_chorus}
[F]Oh! Susanna, oh [C]don't you cry for [G]me
{end_of_chorus}''');
  });

  group('section labels', () {
    for (final label in [
      'Verse 1:',
      '[Chorus]',
      'CHORUS',
      'Coro:',
      'Coro x2',
      '[Verse 2: soft]', //
      'Estrofa 2', 'Puente', 'Intro', 'Pre-chorus:', 'Introducción:',
    ]) {
      test('"$label" is a label', () {
        expect(ChordSheetImporter.isSectionLabel(label), isTrue);
      });
    }

    for (final lyric in [
      'Solo tú me haces feliz',
      'Final de la noche',
      'Verse after verse I sing', //
      'Chorus girls are dancing',
    ]) {
      test('"$lyric" is a lyric, not a label', () {
        expect(ChordSheetImporter.isSectionLabel(lyric), isFalse);
      });
    }

    test('pre-chorus is a verse-style section, chorus is a chorus', () {
      final out = convert('Pre-chorus:\nLa\n\nCoro:\nLa la');
      expect(out, contains('{start_of_verse: Pre-chorus}'));
      expect(out, contains('{start_of_chorus}'));
    });
  });

  group('chord lines', () {
    for (final line in [
      'G C D', '  Am7    Dsus4  G/B', 'F#m7b5 B7', 'Cmaj7 Cadd9 C°', //
      '| G | C | D |', 'G C (x2)', 'N.C.  G', '(G)  (C)',
    ]) {
      test('"$line" is a chord line', () {
        expect(ChordSheetImporter.isChordLine(line), isTrue);
      });
    }

    for (final line in [
      'Am I blue',
      'A day in the life',
      '',
      '   ',
      'x2',
      '|',
    ]) {
      test('"$line" is not a chord line', () {
        expect(ChordSheetImporter.isChordLine(line), isFalse);
      });
    }

    test('a chord line with no lyric under it stays a chords-only line', () {
      expect(convert('Intro:\nG  C  G  D\n\nG\nWords'), '''
{start_of_verse: Intro}
[G] [C] [G] [D]
{end_of_verse}

[G]Words''');
    });

    test('bar lines and repeats are kept as text', () {
      expect(convert('| G | C | (x2)'), '| [G] | [C] | (x2)');
    });

    test('parentheses around a chord are dropped inside brackets', () {
      expect(convert('(G)\nOh'), '[G]Oh');
    });
  });

  test('tab lines become a tab block, kept exactly', () {
    final out = convert('''
Intro
e|---0---|
B|---1---|
G
Then words''');
    expect(out, '''
{start_of_verse: Intro}
{end_of_verse}
{start_of_tab}
e|---0---|
B|---1---|
{end_of_tab}
[G]Then words''');
  });

  test('text that is already ChordPro is returned unchanged', () {
    const text = '{title: X}\n[G]Hello';
    final result = ChordSheetImporter.convert(text);
    expect(result.alreadyChordPro, isTrue);
    expect(result.chordPro, text);
    expect(ChordSheetImporter.convert('[Am]Hi').alreadyChordPro, isTrue);
    expect(ChordSheetImporter.convert('[Chorus]\nHi').alreadyChordPro, isFalse);
  });

  test('Windows and old Mac line endings', () {
    expect(convert('C\r\nHi\r\n'), '[C]Hi');
    expect(convert('C\rHi'), '[C]Hi');
  });

  test('plain lyrics without chords pass through', () {
    expect(convert('Just words\nMore words'), 'Just words\nMore words');
  });

  test('round-trip: the parser reads chords above the right syllables', () {
    final song = ChordProParser.parse(
      convert(
        '${chordsAt({5: 'G', 25: 'D'})}\n'
        'That saved a wretch like me',
      ),
    );
    final line = (song.blocks.single as SectionBlock).lines.single as LyricLine;
    expect(line.segments.map((s) => (s.chord, s.lyric)), [
      (null, 'That '),
      ('G', 'saved a wretch like '),
      ('D', 'me'),
    ]);
  });
}
