import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';

/// The needle: −50 cents on the left, +50 on the right, a green zone of
/// ±5 in the middle (docs/DESIGN.md § Tuner). Glides between readings.
class TunerGauge extends StatelessWidget {
  const TunerGauge({required this.cents, required this.inTune, super.key});

  /// How far off; null hides the needle (silence).
  final double? cents;
  final bool inTune;

  /// Degrees the needle swings either side of straight up at ±50 cents.
  static const sweep = 70.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = (cents ?? 0).clamp(-50.0, 50.0);
    final needle = inTune ? colors.good : colors.accent;
    return AspectRatio(
      aspectRatio: 1.8,
      // The needle eases between readings, and fades in and out with the
      // sound instead of popping.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: cents == null ? 0 : 1),
        duration: const Duration(milliseconds: 200),
        builder: (context, shown, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _GaugePainter(
              cents: value,
              showNeedle: shown > 0,
              needle: needle.withValues(alpha: needle.a * shown),
              tick: colors.line,
              major: colors.muted,
              zone: colors.good,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.cents,
    required this.showNeedle,
    required this.needle,
    required this.tick,
    required this.major,
    required this.zone,
  });

  final double cents;
  final bool showNeedle;
  final Color needle;
  final Color tick;
  final Color major;
  final Color zone;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * 0.92);
    final radius = math.min(size.width / 2, size.height * 0.85);

    for (var c = -50; c <= 50; c += 5) {
      final isMajor = c % 25 == 0;
      final inZone = c.abs() <= 5;
      final angle = _angle(c.toDouble());
      final outer = pivot + Offset(math.sin(angle), -math.cos(angle)) * radius;
      final inner =
          pivot +
          Offset(math.sin(angle), -math.cos(angle)) *
              (radius - (isMajor ? 22 : 12));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = inZone ? zone : (isMajor ? major : tick)
          ..strokeWidth = isMajor ? 3 : 2
          ..strokeCap = StrokeCap.round,
      );
    }

    if (!showNeedle) return;
    final angle = _angle(cents);
    final tip =
        pivot + Offset(math.sin(angle), -math.cos(angle)) * (radius - 30);
    final paint = Paint()
      ..color = needle
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(pivot, tip, paint)
      ..drawCircle(pivot, 9, Paint()..color = needle);
  }

  static double _angle(double cents) =>
      cents / 50 * TunerGauge.sweep * math.pi / 180;

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.cents != cents ||
      old.showNeedle != showNeedle ||
      old.needle != needle ||
      old.tick != tick;
}
