import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/music/chord_voicings.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// A chord box: six strings, five frets, dots where fingers go, × for strings
/// not played and ○ for open strings. Fret numbers run down the left, and
/// under each string is the fret to press (0 = open), as chord charts write
/// it (C: × 3 2 0 1 0), to make shapes easier to learn.
class ChordDiagram extends StatelessWidget {
  const ChordDiagram({required this.voicing, this.width = 150, super.key});

  final Voicing voicing;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final frets = [
      for (final f in voicing.frets)
        if (f < 0) l10n.fretMuted else if (f == 0) l10n.fretOpen else '$f',
    ].join(', ');
    return Semantics(
      image: true,
      label: l10n.diagramFrets(frets),
      child: CustomPaint(
        size: Size(width, width * 1.42),
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
          fretStyle: TextStyle(
            fontSize: width * 0.11,
            fontWeight: FontWeight.w700,
            color: colors.chord,
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
    required this.fretStyle,
  });

  final Voicing voicing;
  final Color line;
  final Color dot;
  final Color muted;
  final TextStyle textStyle;
  final TextStyle fretStyle;

  static const _frets = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final base = voicing.baseFret;
    // Room on the left for fret numbers, on top for × and ○, and below for
    // each string's fret.
    final left = size.width * 0.25;
    final right = size.width * 0.06;
    final top = size.width * 0.16;
    final bottom = size.width * 0.16;
    final gridWidth = size.width - left - right;
    final stringGap = gridWidth / 5;
    final fretGap = (size.height - top - bottom) / _frets;
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
    }
    // Fret numbers down the left.
    for (var f = 0; f < _frets; f++) {
      _text(canvas, '${base + f}', Offset(left * 0.3, y(f) + fretGap / 2));
    }
    // The fret to press on each string, under it.
    for (var s = 0; s < 6; s++) {
      final fret = voicing.frets[s];
      _text(
        canvas,
        fret < 0 ? '×' : '$fret',
        Offset(x(s), y(_frets) + bottom / 2),
        style: fretStyle,
      );
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

  void _text(Canvas canvas, String text, Offset at, {TextStyle? style}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style ?? textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter old) =>
      old.voicing != voicing || old.line != line || old.dot != dot;
}
