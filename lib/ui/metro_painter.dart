import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_state.dart';
import '../theme/kino_theme.dart';

/// Disegna sfondo e collegamenti: attori e film sono widget (vedi map_nodes.dart).
/// Ogni stile ha il suo look:
///  - Metro: linee spesse con bordo, come una cartina della metropolitana
///  - Bacheca: sfondo di sughero e fili rossi tesi tra le puntine
///  - Cinema: insegna con lampadine lungo le linee
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
    switch (spec.label) {
      case 'Bacheca':
        _paintBoard(c, size);
      case 'Cinema':
        _paintCinema(c, size);
      default:
        _paintMetro(c, size);
    }
  }

  // ---------------------------------------------------------------- percorsi

  /// Punto di svolta: un tratto dritto (orizzontale, o verticale) + uno a 45 gradi.
  Offset _bend(Offset a, Offset b) {
    if (vertical) {
      final dx = min((b.dx - a.dx).abs(), (b.dy - a.dy).abs()); // il 45 gradi non supera il tratto
      return Offset(a.dx, b.dy - (b.dy - a.dy).sign * dx);
    }
    final dy = (b.dy - a.dy).abs();
    return Offset(b.dx - (b.dx - a.dx).sign * dy, a.dy);
  }

  Path _route(Offset a, Offset b) {
    final m = _bend(a, b);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(m.dx, m.dy)
      ..lineTo(b.dx, b.dy);
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ------------------------------------------------------------------- Metro

  void _paintMetro(Canvas c, Size size) {
    // Griglia leggera, come su una cartina.
    final grid = Paint()
      ..color = spec.ink.withValues(alpha: .05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Ogni linea ha un bordo del colore dello sfondo: dove due linee si incrociano
    // si vede chi passa sopra e chi sotto, come sulle mappe vere.
    final w = vertical ? 12.0 : 10.0;
    for (final (p, m) in s.links) {
      final path = _route(lay.pos['p$p']!, lay.pos['m$m']!);
      c.drawPath(path, _stroke(spec.bg, w + 6));
      c.drawPath(path, _stroke(lineColor(spec, m), w));
    }
  }

  // ----------------------------------------------------------------- Bacheca

  void _paintBoard(Canvas c, Size size) {
    // Sughero: puntini sparsi, sempre uguali (seme fisso).
    final rnd = Random(7);
    final dot = Paint()..color = spec.ink.withValues(alpha: .08);
    for (double y = 14; y < size.height; y += 26) {
      for (double x = 14; x < size.width; x += 26) {
        c.drawCircle(
          Offset(x + rnd.nextDouble() * 8 - 4, y + rnd.nextDouble() * 8 - 4),
          1.1 + rnd.nextDouble() * 1.3,
          dot,
        );
      }
    }

    // Fili rossi con un leggero cedimento, con l'ombra sul sughero.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .28)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (p, m) in s.links) {
      final a = lay.pos['p$p']!, b = lay.pos['m$m']!;
      final mid = Offset.lerp(a, b, .5)!;
      final sag = (b - a).distance * .07;
      final ctrl = mid + Offset(vertical ? sag * .5 : 0, sag);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(path.shift(const Offset(2, 4)), shadow);
      c.drawPath(path, _stroke(lineColor(spec, m), 3));
    }
  }

  // ------------------------------------------------------------------ Cinema

  void _paintCinema(Canvas c, Size size) {
    // Strisce verticali tenui, come un sipario.
    final stripe = Paint()..color = spec.ink.withValues(alpha: .035);
    for (double x = 0; x < size.width; x += 56) {
      c.drawRect(Rect.fromLTWH(x, 0, 28, size.height), stripe);
    }

    // Linee con alone e lampadine, come l'insegna di una sala.
    final bulb = Paint()..color = const Color(0xFFFFEFB8);
    final glow = Paint()..color = const Color(0xFFFFD36B).withValues(alpha: .35);
    for (final (p, m) in s.links) {
      final path = _route(lay.pos['p$p']!, lay.pos['m$m']!);
      final col = lineColor(spec, m);
      c.drawPath(path, _stroke(col.withValues(alpha: .3), 16));
      c.drawPath(path, _stroke(col, 7));
      for (final metric in path.computeMetrics()) {
        for (double d = 12; d < metric.length; d += 24) {
          final t = metric.getTangentForOffset(d);
          if (t == null) continue;
          c.drawCircle(t.position, 5.5, glow);
          c.drawCircle(t.position, 2.7, bulb);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MetroPainter old) => true;
}
