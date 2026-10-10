import 'dart:math';
import 'package:flutter/material.dart';
import '../game/board_state.dart';
import '../theme/kino_theme.dart';

class MetroPainter extends CustomPainter {
  final BoardState s;
  final StyleSpec spec;
  final MapLayout lay;

  /// true = mappa verticale (catena dall'alto verso il basso), per i telefoni.
  final bool vertical;
  MetroPainter(this.s, this.spec, this.lay, {this.vertical = false});

  // In verticale testi e stazioni sono piu grandi: sul telefono erano illeggibili.
  double get _k => vertical ? 1.3 : 1.0;

  Color _lineColor(int movieId) => spec.lines[movieId % spec.lines.length];

  @override
  void paint(Canvas c, Size size) {
    final k = _k;
    final pos = lay.pos; // gia nell'orientamento giusto (vedi BoardState.layout)

    // Griglia leggera, come su una cartina.
    final grid = Paint()..color = spec.ink.withOpacity(.05)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Linee: un tratto dritto (orizzontale, o verticale) + uno a 45 gradi.
    final degree = <int, int>{};
    for (final (p, m) in s.links) {
      degree[p] = (degree[p] ?? 0) + 1;
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
          ..color = _lineColor(m)
          ..strokeWidth = 9 * k
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Film: etichetta a pillola sulla linea.
    for (final m in s.movies.values) {
      final o = pos['m${m.id}']!;
      final tp = _text('${m.title}${m.year == null ? '' : ' (${m.year})'}', Colors.white, 12 * k,
          FontWeight.w700, vertical ? 180 : 200);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: tp.width + 22, height: tp.height + 14),
          const Radius.circular(20));
      c.drawRRect(r, Paint()..color = _lineColor(m.id));
      c.drawRRect(r, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
    }

    // Attori: stazioni; gli scambi (2+ film) hanno un doppio anello.
    for (final p in s.people.values) {
      final o = pos['p${p.id}']!;
      final isA = p.id == s.a.id, isB = p.id == s.b.id;
      final hub = (degree[p.id] ?? 0) >= 2;
      final r = ((isA || isB) ? 17.0 : (hub ? 13.0 : 10.0)) * (vertical ? 1.2 : 1.0);
      c.drawCircle(o, r, Paint()..color = spec.bg);
      c.drawCircle(o, r, Paint()..color = spec.ink..style = PaintingStyle.stroke..strokeWidth = hub || isA || isB ? 5 : 3.5);
      if (hub) {
        c.drawCircle(o, r + 6, Paint()..color = spec.ink..style = PaintingStyle.stroke..strokeWidth = 2);
      }
      if (isA || isB) {
        final l = _text(isA ? 'A' : 'B', spec.ink, 15 * (vertical ? 1.2 : 1.0), FontWeight.w900, 30);
        l.paint(c, o - Offset(l.width / 2, l.height / 2));
      }
      _chip(c, p.name, Offset(o.dx, o.dy - r - 22), bold: isA || isB);
    }
  }

  TextPainter _text(String t, Color col, double size, FontWeight w, double maxW) => TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: col, fontSize: size, fontWeight: w)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW);

  void _chip(Canvas c, String t, Offset center, {bool bold = false}) {
    final tp = _text(t, spec.ink, 13 * _k, bold ? FontWeight.w800 : FontWeight.w600, vertical ? 180 : 190);
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: tp.width + 14, height: tp.height + 6), const Radius.circular(6));
    c.drawRRect(r, Paint()..color = spec.bg.withOpacity(.92));
    c.drawRRect(r, Paint()..color = spec.ink.withOpacity(.25)..style = PaintingStyle.stroke);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant MetroPainter old) => true;
}
