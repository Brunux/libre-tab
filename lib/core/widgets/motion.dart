import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/widgets/motion.dart';

/// Motion that follows the system's Reduce Motion (iOS) / Remove
/// animations (Android) setting: with it on, animations are instant
/// (docs/DESIGN.md § Motion).
extension MotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// [duration], or none under Reduce Motion.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;

  /// Decoration rather than information (a pop, sparks, a flicker): also
  /// still in Red night, which is used in the dark where movement pulls
  /// the eye.
  bool get calm => reduceMotion || colors == LibreColors.redNight;

  /// [duration] for a flourish, or none when [calm].
  Duration flourish(Duration duration) => calm ? Duration.zero : duration;
}

/// Grows and fades [child] in the first time it's built: a row that was
/// just added, or put back with Undo, arrives instead of popping in.
class Appearing extends StatefulWidget {
  const Appearing({
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 260),
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;

  /// Waits this long first (a cascade of rows).
  final Duration delay;

  /// False shows [child] at once (a row that was there all along).
  final bool enabled;
  final Duration duration;

  @override
  State<Appearing> createState() => _AppearingState();
}

class _AppearingState extends State<Appearing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.enabled ? 0 : 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.duration = context.motion(widget.duration);
      if (_controller.duration == Duration.zero) {
        _controller.value = 1;
      } else if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        _wait = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _curve,
    alignment: Alignment.topCenter,
    child: FadeTransition(opacity: _curve, child: widget.child),
  );
}

/// Wraps a row that can be taken out: [VanishingState.vanish] folds it
/// away, then calls back (to remove it for real).
class Vanishing extends StatefulWidget {
  const Vanishing({
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    super.key,
  });

  final Widget child;
  final Duration duration;

  static VanishingState? of(BuildContext context) =>
      context.findAncestorStateOfType<VanishingState>();

  @override
  State<Vanishing> createState() => VanishingState();
}

class VanishingState extends State<Vanishing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInCubic,
  );

  /// Folds the row away, then runs [then].
  Future<void> vanish(VoidCallback then) async {
    _controller.duration = context.motion(widget.duration);
    if (_controller.duration != Duration.zero) await _controller.reverse();
    then();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _curve,
    alignment: Alignment.topCenter,
    child: FadeTransition(opacity: _curve, child: widget.child),
  );
}
