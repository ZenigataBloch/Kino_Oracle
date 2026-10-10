import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_state.dart';
import '../theme/kino_theme.dart';

/// Disegna solo griglia e linee: attori e film sono widget (vedi map_nodes.dart).
class MetroPainter extends CustomPainter {
  final BoardState s;
  final StyleSpec spec;
  final MapLayout lay;

  /// true = mappa verticale (catena dall'alto verso il basso), per i telefoni.
  final bool vertical;
  MetroPainter(this.s, this.spec, this.lay, {this.vertical = false});

  static Color lineColor(StyleSpec spec, int movieId) => spec.lines[movieId % spec.lines.length];

  @override
  void paint(Canvas c, Size size) {
    final pos = lay.pos;

    // Griglia leggera, come su una cartina.
    final grid = Paint()..color = spec.ink.withOpacity(.05)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Linee: un tratto dritto (orizzontale, o verticale) + uno a 45 gradi.
    for (final (p, m) in s.links) {
      final a = pos['p$p']!, b = pos['m$m']!;
      final Offset mid;
      if (vertical) {
        final dx = min((b.dx - a.dx).abs(), (b.dy - a.dy).abs()); // il 45 gradi non supera il tratto
        mid = Offset(a.dx, b.dy - (b.dy - a.dy).sign * dx);
      } else {
        final dy = (b.dy - a.dy).abs();
        mid = Offset(b.dx - (b.dx - a.dx).sign * dy, a.dy);
      }
      c.drawPath(
        Path()..moveTo(a.dx, a.dy)..lineTo(mid.dx, mid.dy)..lineTo(b.dx, b.dy),
        Paint()
          ..color = lineColor(spec, m)
          ..strokeWidth = vertical ? 12 : 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MetroPainter old) => true;
}
