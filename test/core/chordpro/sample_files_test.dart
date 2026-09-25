import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song.dart';

/// The hand-testing files in docs/samples/ import the way we expect.
String sample(String name) => File('docs/samples/$name').readAsStringSync();

List<(String?, String)> segs(SongLine line) =>
    (line as LyricLine).segments.map((s) => (s.chord, s.lyric)).toList();

void main() {
  test('amazing-grace.txt: labels, a tab intro and aligned chords', () {
    final result = ChordSheetImporter.convert(sample('amazing-grace.txt'));
    expect(result.alreadyChordPro, isFalse);
    expect(result.sections, 3); // Intro, Verse 1, Verse 2
    expect(result.chordLines, 8);

    final song = ChordProParser.parse(result.chordPro);
    final kinds = song.blocks.whereType<SectionBlock>().map((b) => b.kind);
    expect(kinds, contains(SectionKind.tab));
    final verse = song.blocks.whereType<SectionBlock>().firstWhere(
      (b) => b.label == 'Verse 1',
    );
    expect(segs(verse.lines.first), [
      (null, 'A-'),
      ('G', 'mazing '),
      ('G7', 'grace, how '),
      ('C', 'sweet the '),
      ('G', 'sound'),
    ]);
  });

  test('la-cucaracha.txt: Spanish labels and chords', () {
    final result = ChordSheetImporter.convert(sample('la-cucaracha.txt'));
    expect(result.sections, 2);
    final song = ChordProParser.parse(result.chordPro);
    final blocks = song.blocks.whereType<SectionBlock>().toList();
    expect(blocks.first.label, 'Estrofa 1');
    expect(blocks.last.kind, SectionKind.chorus);
    expect(segs(blocks.last.lines.first).first.$1, 'G');
    expect(song.chords.toSet(), {'G', 'D7'});
  });

  test('oh-susanna.cho: ChordPro with capo, chorus repeat and a comment', () {
    final text = sample('oh-susanna.cho');
    expect(ChordSheetImporter.convert(text).alreadyChordPro, isTrue);
    final song = ChordProParser.parse(text);
    expect(song.title, 'Oh! Susanna');
    expect(song.key?.name, 'C');
    expect(song.capo, 2);
    expect(song.blocks.whereType<ChorusRepeat>(), hasLength(1));
    expect(
      song.blocks
          .whereType<SectionBlock>()
          .expand((b) => b.lines)
          .whereType<CommentLine>()
          .single
          .text,
      'Softly, then everyone joins',
    );
  });
}
