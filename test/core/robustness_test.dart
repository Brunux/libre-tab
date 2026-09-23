import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song.dart';
import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/music_key.dart';
import 'package:libre_tab/core/music/note.dart';
import 'package:libre_tab/core/music/transposition.dart';

const roots = [
  'C',
  'C#',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B', //
];
const suffixes = ['', 'm', '7', 'm7', 'maj7', 'sus4', 'dim', 'm7b5', 'add9'];

/// Accidentals used in the note names of a chord (root and bass only;
/// suffixes like `m7b5` contain a `b` that isn't a flat).
Set<String> accidentals(Chord chord) => {
  for (final note in [chord.root, ?chord.bass])
    if (note.length == 2) note[1],
};

void main() {
  group('ChordPro parser never throws', () {
    test('on 2000 random documents', () {
      final random = Random(42);
      const alphabet = '[]{}:#\n\r abcGAm7/|-é🎸';
      for (var i = 0; i < 2000; i++) {
        final text = String.fromCharCodes(
          List.generate(
            random.nextInt(120),
            (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ),
        );
        expect(() => ChordProParser.parse(text), returnsNormally, reason: text);
      }
    });

    test('on half-written directives and brackets', () {
      for (final text in [
        '{',
        '}',
        '{}',
        '{:}',
        '{title',
        'title}',
        '[',
        ']',
        '[[G]]',
        '[G',
        '{start_of_tab}',
        '{eot}{eot}',
        '{soc}{soc}{eoc}{eoc}',
        '{capo: 999999999999999999999}',
      ]) {
        expect(() => ChordProParser.parse(text), returnsNormally, reason: text);
      }
    });
  });

  group('ChordPro parser details', () {
    test('directive names ignore case', () {
      final song = ChordProParser.parse('{Title: X}\n{START_OF_CHORUS}\nLa');
      expect(song.title, 'X');
      expect((song.blocks.single as SectionBlock).kind, SectionKind.chorus);
    });

    test('a colon inside a value is kept', () {
      expect(ChordProParser.parse('{title: Hey: Jude}').title, 'Hey: Jude');
    });

    test('spaces around the name and value are ignored', () {
      expect(ChordProParser.parse('{ title :  X  }').title, 'X');
    });

    test('braces inside a lyric line are just lyrics', () {
      final line = ChordProParser.parse('I said {hi} [G]there').blocks.single;
      final lyric = (line as SectionBlock).lines.single as LyricLine;
      expect(lyric.lyrics, 'I said {hi} there');
    });

    test('an unclosed tab keeps every line to the end', () {
      final song = ChordProParser.parse('{sot}\ne|-0-|\n{c: literal}');
      final tab = song.blocks.single as SectionBlock;
      expect(tab.kind, SectionKind.tab);
      expect(tab.lines, hasLength(2));
    });

    test('Spanish lyrics and emoji survive', () {
      final line = ChordProParser.parseLyricLine('Can[Am]ción del ñandú 🎸');
      expect(line.segments.map((s) => (s.chord, s.lyric)), [
        (null, 'Can'),
        ('Am', 'ción del ñandú 🎸'),
      ]);
    });

    test('a long songbook-sized song parses quickly', () {
      final text = List.filled(
        500,
        '{sov}\nA-[G]mazing [G7]grace, how [C]sweet the [G]sound\n{eov}',
      ).join('\n');
      final watch = Stopwatch()..start();
      final song = ChordProParser.parse(text);
      watch.stop();
      expect(song.blocks, hasLength(500));
      expect(watch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('transposing', () {
    test('up then down returns the same pitches for every chord', () {
      for (final root in roots) {
        for (final suffix in suffixes) {
          for (final bass in [null, 'E', 'Bb']) {
            final chord = Chord(root: root, suffix: suffix, bass: bass);
            for (var n = -11; n <= 11; n++) {
              final back = chord
                  .transpose(n, flats: n.isEven)
                  .transpose(-n, flats: false);
              expect(
                Note.pitchClass(back.root),
                Note.pitchClass(root),
                reason: '$chord by $n',
              );
              expect(back.suffix, suffix);
              if (bass != null) {
                expect(Note.pitchClass(back.bass!), Note.pitchClass(bass));
              }
            }
          }
        }
      }
    });

    test('shown chords never mix sharps and flats', () {
      for (var tonic = 0; tonic < 12; tonic++) {
        for (final minor in [false, true]) {
          final key = MusicKey(tonic, minor: minor);
          for (var semitones = -6; semitones <= 6; semitones++) {
            for (var capo = 0; capo <= 5; capo++) {
              final t = Transposition(semitones: semitones, capo: capo);
              if (t.shapeShift % 12 == 0) continue; // shown as written
              final wanted = t.shapeKey(key).prefersFlats ? 'b' : '#';
              for (final root in roots) {
                final shown = Chord.tryParse(t.chord('${root}m7/E', key))!;
                expect(
                  accidentals(shown).difference({wanted}),
                  isEmpty,
                  reason: '$root in $key, $semitones, capo $capo → $shown',
                );
              }
            }
          }
        }
      }
    });

    test('capo n and transpose n cancel out for the player', () {
      final g = MusicKey.tryParse('G')!;
      for (var n = 0; n <= 9; n++) {
        final t = Transposition(semitones: n, capo: n);
        expect(t.chord('D/F#', g), 'D/F#');
        expect(t.shapeKey(g), g);
      }
    });
  });

  group('value semantics', () {
    test('Chord equality and hashCode', () {
      final a = Chord.tryParse('D/F#')!;
      const b = Chord(root: 'D', bass: 'F#');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const Chord(root: 'D', bass: 'E')));
      expect({a, b}, hasLength(1));
    });

    test('MusicKey equality, hashCode and toString', () {
      final a = MusicKey.tryParse('Am')!;
      const b = MusicKey(9, minor: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const MusicKey(9)));
      expect('$a', 'Am');
    });
  });
}
