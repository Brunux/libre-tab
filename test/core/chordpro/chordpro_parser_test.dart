import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song.dart';

/// Segments as (chord, lyric) records, for readable expectations.
List<(String?, String)> segs(SongLine line) =>
    (line as LyricLine).segments.map((s) => (s.chord, s.lyric)).toList();

SectionBlock section(Song song, int index) =>
    song.blocks[index] as SectionBlock;

void main() {
  test('the example from docs/SONG_FORMAT.md', () {
    final song = ChordProParser.parse('''
{title: Amazing Grace}
{artist: John Newton}
{key: G}
{capo: 0}

{start_of_verse}
A-[G]mazing [G7]grace, how [C]sweet the [G]sound
That [G]saved a wretch like [D]me
{end_of_verse}
''');

    expect(song.title, 'Amazing Grace');
    expect(song.artist, 'John Newton');
    expect(song.key?.name, 'G');
    expect(song.capo, 0);
    expect(song.blocks, hasLength(1));

    final verse = section(song, 0);
    expect(verse.kind, SectionKind.verse);
    expect(verse.label, isNull);
    expect(segs(verse.lines[0]), [
      (null, 'A-'),
      ('G', 'mazing '),
      ('G7', 'grace, how '),
      ('C', 'sweet the '),
      ('G', 'sound'),
    ]);
    expect(segs(verse.lines[1]), [
      (null, 'That '),
      ('G', 'saved a wretch like '),
      ('D', 'me'),
    ]);
  });

  test('short directive forms and section labels', () {
    final song = ChordProParser.parse('''
{t: Title}
{a: Artist}
{sov: Verse 2}
[C]One
{eov}
{soc}
[F]Two
{eoc}
{sob}
[G]Three
{eob}
''');
    expect(song.title, 'Title');
    expect(song.artist, 'Artist');
    expect(song.blocks.map((b) => (b as SectionBlock).kind), [
      SectionKind.verse,
      SectionKind.chorus,
      SectionKind.bridge,
    ]);
    expect(section(song, 0).label, 'Verse 2');
    expect(section(song, 1).label, isNull);
  });

  test('{chorus} repeats the chorus', () {
    final song = ChordProParser.parse('''
{soc}
[F]Oh Su-[C]sanna
{eoc}
{sov}
[C]Verse
{eov}
{chorus}
{chorus: Last time}
''');
    expect(song.blocks[2], isA<ChorusRepeat>());
    expect((song.blocks[3] as ChorusRepeat).label, 'Last time');
  });

  test('tab blocks are kept literally, including blank lines', () {
    final song = ChordProParser.parse('''
{start_of_tab: Intro}
e|---0---|
[not a chord] {c: nor a comment}

B|---1---|
{end_of_tab}
[G]After
''');
    final tab = section(song, 0);
    expect(tab.kind, SectionKind.tab);
    expect(tab.label, 'Intro');
    expect(tab.lines.map((l) => (l as TabLine).text), [
      'e|---0---|',
      '[not a chord] {c: nor a comment}',
      '',
      'B|---1---|',
    ]);
    expect(segs(section(song, 1).lines.single), [('G', 'After')]);
  });

  test('comments: # lines are hidden, {comment} is shown', () {
    final song = ChordProParser.parse('''
# private note
{c: Intro x2}
{comment: }
[G] [C]
''');
    final lines = section(song, 0).lines;
    expect(lines, hasLength(2));
    expect((lines[0] as CommentLine).text, 'Intro x2');
  });

  test('unknown directives are ignored', () {
    final song = ChordProParser.parse('''
{new_page}
{x_custom: 1}
{subtitle: ignored for now}
Words
''');
    expect(song.blocks, hasLength(1));
    expect(segs(section(song, 0).lines.single), [(null, 'Words')]);
  });

  test('blank lines split loose stanzas but not explicit sections', () {
    final song = ChordProParser.parse('''
Line one

Line two
{sov}
A

B

{eov}
''');
    expect(song.blocks, hasLength(3));
    final verse = section(song, 2);
    expect(verse.lines, hasLength(3)); // A, empty, B (trailing blank trimmed)
    expect(verse.lines[1], isA<EmptyLine>());
  });

  test('an unclosed section ends at the next one or at the end', () {
    final song = ChordProParser.parse('''
{sov}
[C]Verse
{soc}
[F]Chorus
''');
    expect(song.blocks.map((b) => (b as SectionBlock).kind), [
      SectionKind.verse,
      SectionKind.chorus,
    ]);
  });

  group('lyric lines', () {
    test('chords-only line', () {
      final line = ChordProParser.parseLyricLine('[G] [C] [D]');
      expect(segs(line), [('G', ' '), ('C', ' '), ('D', '')]);
      expect(line.isChordsOnly, isTrue);
    });

    test('chord at the end of a line', () {
      final line = ChordProParser.parseLyricLine('Hello [G]');
      expect(segs(line), [(null, 'Hello '), ('G', '')]);
      expect(line.isChordsOnly, isFalse);
    });

    test('line without chords', () {
      expect(segs(ChordProParser.parseLyricLine('Just words')), [
        (null, 'Just words'),
      ]);
    });

    test('non-chord brackets are kept as written, empty ones dropped', () {
      expect(segs(ChordProParser.parseLyricLine('[N.C.]Stop [] now')), [
        ('N.C.', 'Stop '),
        (null, ' now'),
      ]);
    });
  });

  test('Windows line endings', () {
    final song = ChordProParser.parse('{t: T}\r\n[G]One\r\n\r\n[C]Two\r\n');
    expect(song.title, 'T');
    expect(song.blocks, hasLength(2));
  });

  test('invalid key and capo become null', () {
    final song = ChordProParser.parse('{key: H}\n{capo: two}\n{tempo: 90}');
    expect(song.key, isNull);
    expect(song.capo, isNull);
    expect(song.tempo, 90);
  });

  test('empty text gives an empty song', () {
    final song = ChordProParser.parse('');
    expect(song.title, isNull);
    expect(song.blocks, isEmpty);
    expect(song.effectiveKey, isNull);
  });

  test('chords and key guess when {key} is missing', () {
    final song = ChordProParser.parse('[N.C.]Hey [Am]hello [G]world');
    expect(song.chords, ['N.C.', 'Am', 'G']);
    expect(song.effectiveKey?.name, 'Am');
  });

  test('plainLyrics drops chords, comments and tabs', () {
    final song = ChordProParser.parse('''
{sov}
{c: Softly}
A-[G]mazing [G7]grace
{eov}
{sot}
e|--0--|
{eot}
{soc}
[C]Chorus line
{eoc}
''');
    expect(song.plainLyrics, 'A-mazing grace\n\nChorus line');
  });
}
