import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/music/chord_voicings.dart';

/// A chord box: six strings, five frets, dots where fingers go, × for strings
/// not played and ○ for open strings.
class ChordDiagram extends StatelessWidget {
  const ChordDiagram({required this.voicing, this.width = 150, super.key});

  final Voicing voicing;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      image: true,
      label: voicing.toString(),
      child: CustomPaint(
        size: Size(width, width * 1.25),
        painter: _ChordDiagramPainter(
          voicing: voicing,
          line: colors.text,
          dot: colors.chord,
          muted: colors.muted,
          textStyle: TextStyle(
            fontSize: width * 0.1,
            fontWeight: FontWeight.w700,
            color: colors.muted,
          ),
        ),
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({
    required this.voicing,
    required this.line,
    required this.dot,
    required this.muted,
    required this.textStyle,
  });

  final Voicing voicing;
  final Color line;
  final Color dot;
  final Color muted;
  final TextStyle textStyle;

  static const _frets = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final base = voicing.baseFret;
    // Room on the left for the "5fr" label, on top for × and ○.
    final left = size.width * 0.18;
    final right = size.width * 0.06;
    final top = size.width * 0.16;
    final gridWidth = size.width - left - right;
    final stringGap = gridWidth / 5;
    final fretGap = (size.height - top - 4) / _frets;
    double x(int string) => left + string * stringGap;
    double y(int fret) => top + fret * fretGap;

    final thin = Paint()
      ..color = line
      ..strokeWidth = 1.5;
    for (var s = 0; s < 6; s++) {
      canvas.drawLine(Offset(x(s), y(0)), Offset(x(s), y(_frets)), thin);
    }
    for (var f = 0; f <= _frets; f++) {
      canvas.drawLine(Offset(x(0), y(f)), Offset(x(5), y(f)), thin);
    }
    if (base == 1) {
      // The nut.
      canvas.drawRect(
        Rect.fromLTRB(x(0), y(0) - 4, x(5), y(0) + 1),
        Paint()..color = line,
      );
    } else {
      _text(canvas, '${base}fr', Offset(0, y(0) + fretGap / 2), center: false);
    }

    final radius = stringGap * 0.36;
    final fill = Paint()..color = dot;

    if (voicing.barre case final barre?) {
      final strings = [
        for (var s = 0; s < 6; s++)
          if (voicing.frets[s] >= barre) s,
      ];
      final row = y(barre - base) + fretGap / 2;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x(strings.first) - radius,
          row - radius,
          x(strings.last) + radius,
          row + radius,
          Radius.circular(radius),
        ),
        fill,
      );
    }

    for (var s = 0; s < 6; s++) {
      final fret = voicing.frets[s];
      if (fret < 0) {
        _text(canvas, '×', Offset(x(s), top / 2));
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(x(s), top / 2),
          radius * 0.7,
          Paint()
            ..color = muted
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        canvas.drawCircle(
          Offset(x(s), y(fret - base) + fretGap / 2),
          radius,
          fill,
        );
      }
    }
  }

  void _text(Canvas canvas, String text, Offset at, {bool center = true}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      at - Offset(center ? painter.width / 2 : 0, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter old) =>
      old.voicing != voicing || old.line != line || old.dot != dot;
}
