/// The editor shows title and artist as fields and the rest of the song as
/// text. These helpers move `{title}` / `{artist}` between the two.
final class SongHeader {
  const SongHeader({this.title = '', this.artist = '', this.content = ''});

  /// Splits stored ChordPro into title, artist and everything else.
  factory SongHeader.split(String body) {
    var title = '';
    var artist = '';
    final rest = <String>[];
    for (final line in body.replaceAll('\r\n', '\n').split('\n')) {
      final m = _header.firstMatch(line);
      if (m == null) {
        rest.add(line);
        continue;
      }
      final value = m.group(2)!.trim();
      switch (m.group(1)!.toLowerCase()) {
        case 'title' || 't':
          title = value;
        default:
          artist = value;
      }
    }
    while (rest.isNotEmpty && rest.first.trim().isEmpty) {
      rest.removeAt(0);
    }
    return SongHeader(
      title: title,
      artist: artist,
      content: rest.join('\n').trimRight(),
    );
  }

  static final RegExp _header = RegExp(
    r'^\s*\{\s*(title|t|artist|a)\s*:(.*)\}\s*$',
    caseSensitive: false,
  );

  final String title;
  final String artist;
  final String content;

  /// Stored ChordPro: `{title}`, `{artist}` (if any), a blank line, content.
  String compose() {
    final head = [
      '{title: ${title.trim()}}',
      if (artist.trim().isNotEmpty) '{artist: ${artist.trim()}}',
    ];
    final body = content.trim();
    return body.isEmpty
        ? head.join('\n')
        : '${head.join('\n')}\n\n${content.trimRight()}';
  }
}
