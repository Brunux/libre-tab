import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chord_sheet_importer.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';
import 'package:libre_tab/core/database/search_index.dart';
import 'package:libre_tab/core/files/song_files.dart';
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
}
