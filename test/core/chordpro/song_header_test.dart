import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/chordpro/chordpro_parser.dart';
import 'package:libre_tab/core/chordpro/song_header.dart';

void main() {
  test('split takes title and artist out of the text', () {
    final header = SongHeader.split(
      '{title: Amazing Grace}\n{artist: John Newton}\n\n{key: G}\n[G]Words',
    );
    expect(header.title, 'Amazing Grace');
    expect(header.artist, 'John Newton');
    expect(header.content, '{key: G}\n[G]Words');
  });

  test('split understands short forms and any case', () {
    final header = SongHeader.split('{T: One}\n{a:Two}\nLa');
    expect(header.title, 'One');
    expect(header.artist, 'Two');
    expect(header.content, 'La');
  });

  test('split with no header keeps everything as content', () {
    final header = SongHeader.split('[G]Hello\n');
    expect(header.title, isEmpty);
    expect(header.artist, isEmpty);
    expect(header.content, '[G]Hello');
  });

  test('compose writes the header the parser reads back', () {
    const header = SongHeader(
      title: ' Oh! Susanna ',
      artist: 'Stephen Foster',
      content: '[C]I come from Alabama\n',
    );
    final body = header.compose();
    expect(
      body,
      '{title: Oh! Susanna}\n{artist: Stephen Foster}\n\n'
      '[C]I come from Alabama',
    );
    final song = ChordProParser.parse(body);
    expect(song.title, 'Oh! Susanna');
    expect(song.artist, 'Stephen Foster');
  });

  test('compose leaves out an empty artist and empty content', () {
    expect(const SongHeader(title: 'T').compose(), '{title: T}');
  });

  test('split then compose round-trips', () {
    const body = '{title: A}\n{artist: B}\n\n{key: G}\n[G]One\n\n[C]Two';
    expect(SongHeader.split(body).compose(), body);
  });
}
