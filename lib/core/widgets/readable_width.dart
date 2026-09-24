import 'package:flutter/widgets.dart';

/// Keeps content to a comfortable width on big screens (iPad, landscape),
/// centered; on phones it changes nothing.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    required this.child,
    this.maxWidth = 760,
    this.fillHeight = true,
    super.key,
  });

  /// Lists and forms: 760. The song itself: wider. The tuner: narrower.
  final double maxWidth;

  /// Screen bodies fill the height they're given; bars (like the song
  /// view's dock) stay as tall as their content.
  final bool fillHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: fillHeight ? null : 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
