import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/app/widgets/app_logo.dart';
import 'package:libre_tab/core/widgets/motion.dart';

/// The campfire catching: two soft flickers, then still.
class _Flicker extends StatelessWidget {
  const _Flicker({required this.child});

  final Widget child;

  static final _flicker = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.04), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1), weight: 1.5),
  ]);

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: context.flourish(const Duration(milliseconds: 1100)),
    builder: (context, t, child) => Transform.scale(
      scale: t >= 1 ? 1 : _flicker.transform(t),
      alignment: Alignment.bottomCenter,
      child: child,
    ),
    child: child,
  );
}

/// Centered muted message for empty and error states, with an optional
/// [icon] above it and an [action] button under it.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({
    required this.message,
    this.icon,
    this.mark = false,
    this.action,
    super.key,
  });

  final String message;
  final IconData? icon;

  /// The flame mark instead of an icon (an empty songbook).
  final bool mark;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // Scrolls when it doesn't fit (a small phone with large text).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mark)
              const _Flicker(child: BrandMark(size: 96))
            else if (icon case final icon?)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surface2,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Icon(icon, size: 36, color: context.colors.accent),
                ),
              ),
            if (mark || icon != null) const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: context.colors.muted),
            ),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
