import 'package:flutter/material.dart';

/// A song's title that flies from its row in the songbook into the song
/// view's header (and back), changing size and font on the way instead of
/// stretching one of the two.
class SongTitleHero extends StatelessWidget {
  const SongTitleHero({
    required this.songId,
    required this.title,
    required this.style,
    required this.inSongView,
    this.maxLines = 1,
    super.key,
  });

  final int songId;
  final String title;
  final TextStyle? style;

  /// The header end of the flight (the list row is the other).
  final bool inSongView;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Hero(
    tag: 'song-title-$songId',
    flightShuttleBuilder: _shuttle,
    child: _text(style, maxLines),
  );

  Widget _text(TextStyle? style, int maxLines) => Material(
    type: MaterialType.transparency,
    child: Text(
      title,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );

  static Widget _shuttle(
    BuildContext flight,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext from,
    BuildContext to,
  ) {
    final fromHero = from.findAncestorWidgetOfExactType<SongTitleHero>()!;
    final toHero = to.findAncestorWidgetOfExactType<SongTitleHero>()!;
    // The animation runs toward the song view on the way in (push) and
    // back from it on the way out (pop): 1 is always the header's style.
    final (list, header) = fromHero.inSongView
        ? (toHero, fromHero)
        : (fromHero, toHero);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            list.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle.lerp(list.style, header.style, animation.value),
          ),
        ),
      ),
    );
  }
}
