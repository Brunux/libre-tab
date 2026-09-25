import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/core/database/search_index.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/core/ocr/chord_repair.dart';
import 'package:libre_tab/core/ocr/ocr_layout.dart';
import 'package:libre_tab/features/library/data/duplicates.dart';

/// Crafted text that makes badly written patterns backtrack for ages (or
/// makes string building quadratic). Each is kept within the biggest song
/// file the app reads (SongFiles.maxSongBytes): anything bigger is refused
/// before it reaches a parser.
final hostile = <String, String>{
  'long chord-like run': 'A${'#7sus2add9' * 20000}/',
  'unclosed directive': '{title: ${'x' * 200000}',
  'directive with many colons': '{title:${':' * 200000}',
  'section label then spaces': 'Verse${' ' * 200000}x',
  'tab-like line': 'e|${'-0|' * 60000}z',
  'many brackets': '[' * 100000,
  'bracket soup': '[a]' * 60000,
  'spaces': ' ' * 200000,
  'section label-ish': '[Verse ${'1' * 200000}',
  'mixed': '${'Am ' * 20000}\n${'la ' * 20000}\n',
};

void main() {
  for (final MapEntry(key: name, value: text) in hostile.entries) {
    test('parsers stay fast on: $name', () {
      expect(
        utf8.encode(text).length,
        lessThanOrEqualTo(SongFiles.maxSongBytes),
        reason: 'hostile input must be a size the app accepts',
      );
      final watch = Stopwatch()..start();
      ChordSheetImporter.convert(text);
      ChordProParser.parse(text);
      SongHeader.split(text);
      Duplicates.bodyKey(text);
      Duplicates.nameKey(text);
      SearchIndex.query(text);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)), reason: name);
    });
  }

  // A photo of a busy page can hold thousands of words; the layout must not
  // grow with their square, and past OcrLayout.maxWords the rest is left out.
  final photos = <String, List<RecognizedWord>>{
    'one word per line': [
      for (var i = 0; i < 20000; i++)
        RecognizedWord(
          'G',
          left: 0,
          top: i * 30.0,
          right: 10,
          bottom: i * 30.0 + 20,
        ),
    ],
    'one long line': [
      for (var i = 0; i < 20000; i++)
        RecognizedWord(
          i.isEven ? 'G' : 'Cc',
          left: i * 20.0,
          top: 0,
          right: i * 20.0 + 15,
          bottom: 20,
        ),
    ],
    'everything on one spot': [
      for (var i = 0; i < 20000; i++)
        const RecognizedWord('Am', left: 0, top: 0, right: 10, bottom: 10),
    ],
  };
  for (final MapEntry(key: name, value: words) in photos.entries) {
    test('photo layout stays fast on: $name', () {
      final watch = Stopwatch()..start();
      final sheet = OcrLayout.read(words);
      ChordRepair.line([for (final w in words) w.text]);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)), reason: name);
      expect(
        '\n'.allMatches(sheet.text).length,
        lessThanOrEqualTo(OcrLayout.maxWords),
      );
    });
  }
}
